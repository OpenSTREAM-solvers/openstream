classdef FourFieldSolver < Solvers.ThreeField.ThreeFieldSolver
    %FOURFIELDSOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=protected)
        
        % NZ           (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of axial steps
        % NTIME        (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of time steps
        % TIME         (:,1) double  {mustBeNumeric}                          = 0         % [s] Time series
        % DT           (1,1) double  {mustBeNumeric}                          = 0         % [s] Time step size
        % Z            (:,1) double  {mustBeNumeric}                          = 1.        % [m] Elevation
        % DZ           (1,1) double  {mustBeNumeric}                          = 0         % [m] Axial step size
        % 
        % fluid       {isa(fluid,'Inputs.FluidProperties')}
        % boundaryConditions
        % 
        % filmInit
        % dropInit
        % fluidInit
        % film
        % drop

     end

     properties (SetAccess = protected)
        % mixSolver
        % inputSet
        % STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(tfSolver)
    end

    methods
        function ffSolver = FourFieldSolver(inputSet,mixSolver)
            %FOURFIELDSOLVER Creates a FourField solver
            %   Detailed explanation goes here
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            ffSolver = ffSolver@Solvers.ThreeField.ThreeFieldSolver(inputSet,mixSolver);
            
            % % Store mixSolver handle
            % ffSolver.mixSolver = mixSolver;
            % 
            % % Attempt to solve mixSolver if it is unsolved
            % if ffSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
            %     ffSolver.mixSolver.solve();
            % end
            % 
            % % Initialize solver parameters
            % ffSolver.initializeSolver();

        end
        
        function initializeSolver(ffSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.FourField.*
            import Solvers.SolverState
            
            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                ffSolver.(p{:}) = ffSolver.mixSolver.(p{:});
            end
            
            % Local parameters
            mixArr = ffSolver.mixSolver.mixture;                            % Mixture solution
            model  = ffSolver.inputSet.model;                               % Models
            geom   = ffSolver.inputSet.geometry;                            % Geometry
            
            % Setup inner iteration value struct
            ITRf = ffSolver.CreateITR(ffSolver.NZ, ["N","DWL","DU"]);
            ITRd = ffSolver.CreateITR(ffSolver.NZ, ["N","DU"]);

            % Create film and drop arrays (by timestep)
            flmArr(ffSolver.NTIME) = Film();
            drpArr(ffSolver.NTIME) = Drop();
            props = {'NZ','Z','DZ','NTIME','DT','TIME','TIDX','inputSet','fluid', 'mix'};                 % film and drop properties
            
            for tIdx = 1:ffSolver.NTIME

                % Convenience variables (handles)
                flm         = flmArr(tIdx);
                drp         = drpArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = ffSolver.fluid(tIdx);
                
                % Inputset and fluid
                flm.inputSet = ffSolver.inputSet;
                flm.fluid    = fluid;

                % Corresponding Mixture
                flm.mix = mix;
                
                % Axial step sizes             
                flm.NZ = ffSolver.NZ;
                flm.DZ = ffSolver.DZ;
                flm.Z  = ffSolver.Z;
                
                % Time step
                flm.NTIME = ffSolver.NTIME;
                flm.DT    = ffSolver.DT;
                flm.TIME  = ffSolver.TIME(tIdx);
                flm.TIDX  = tIdx;
                
                % Copy properties to drop
                for p = props
                    drp.(p{:}) = flm.(p{:});
                end

                % ITR
                drp.ITR = ITRd;
                   
                % Wall evaporation heat flux
                HFLUX = mix.HFLUX;                                         % [W/m^2] Wall heat flux
                avgHFLUX = sum(HFLUX.*geom.PERIM,2)./sum(geom.PERIM);      % [W/m^2] Average heat flux
                avgHFLUX = repmat(avgHFLUX,1,geom.NWALL);                  % [W/m^2] ... distributed to all walls
                
                evapFn = double(mix.XEQ > 0);                              % Saturated evaporation function
                Nbo = find(evapFn > 0,1);                                  % Boiling transition node
                if Nbo >1
                    % Adjust evaporation function in transition node 
                    % (part toward subcooled liquid, part toward evaporation)
                    evapFn(Nbo) = mix.XEQ(Nbo)/diff(mix.XEQ(Nbo-1:Nbo)); 
                end
                
                flm.HFLUX = mix.AFDISTR(evapFn.*avgHFLUX,HFLUX);           % [W/m^2] Film evaporation heat flux
                    
                % Film evaporation (thermal equilibrium assumption)
                flm.MEVAP = -flm.HFLUX./(fluid.HG-fluid.HF);               % [kg/m^2/s] Evaporation mass flux

                % Initialize base and wave
                flm.initializeBaseAndWave();
                
                % Entrained ratio at onset of annular flow
                switch model.OAFENTRAINED
                    case InputEnums.OAFENTRAINED.RATIO
                        e0 = model.OAFDROPRATIO;
                    case InputEnums.OAFENTRAINED.EQUILIBRIUM
                        e0 = ffSolver.EQUIL(flm,drp,mix,mix.OAFIDX);
                end

                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note 1: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                % Note 2: other, maybe better, initialization states could be investigated
                drp.W = repmat(e0.*mix.OAFWL,ffSolver.NZ,1);               % [kg/s] % Set drop mass flow to onset of annular flow conditions everywhere

                % Transient mass gradient in drop field
                drp.W = drp.W+mix.W-mix.W(mix.OAFIDX);
                
                % Transient mass gradient in film.base and film.wave
                % and recalculate drop mass flow rate
                flm.initializeBaseAndWave( ...
                                mix.liquid.W(1)-drp.W(1), ...              % Inlet flow rate (all walls)
                                ITRf ...                                   % Iteration struct
                             );
                drp.W = mix.liquid.W-sum(flm.W,2);                         % [kg/s] Recalculate consistent drop flow rate
                
                % Initialize velocity [m/s]
                %drp.U = mix.liquid.U;                                      % [m/s] Drop velocity
                drp.U = drp.USLIP();                                        % [m/s] Drop velocity
                
                %flm.U = repmat(mix.liquid.U,1,geom.NWALL); % [m/s]
                                                
                % Initialize enthalpy [J/kg] by number of spatial nodes, NZ
                drp.H = repmat(fluid.HF,ffSolver.NZ,1);                

            end

            % Store transient mixture array
            ffSolver.film = flmArr;
            ffSolver.drop = drpArr;

            % Create steady state arrays
            ffSolver.filmInit = copy( ...
                repmat(flmArr(1),1,ffSolver.inputSet.options.SSMAXITER));
            ffSolver.dropInit = copy( ...
                repmat(drpArr(1),1,ffSolver.inputSet.options.SSMAXITER));
            
            % Steady state fluidProperties
            ffSolver.fluidInit = FluidProperties( ...
                                    repmat( ...
                                        ffSolver.boundaryConditions.PRESSURE(1), ...
                                        1, ...
                                        ffSolver.inputSet.options.SSMAXITER), ...
                                    ffSolver.inputSet.model);

            % Update filmInit and dropInit times and timesteps
            initTIMEDT = ffSolver.inputSet.options.SSTSTEP;
            initNTIME = length(ffSolver.filmInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(ffSolver.filmInit);

            for i = 1:length(ffSolver.filmInit)

                ffSolver.filmInit(i).TIME = initTIME(i);
                ffSolver.filmInit(i).DT = initTIMEDT;
                ffSolver.filmInit(i).NTIME = initNTIME;
                ffSolver.filmInit(i).TIDX = initTIDX(i);

                % Make copy of last mixtureInit
                ffSolver.filmInit(i).mix       = copy(ffSolver.mixSolver.mixtureInit(end));
                ffSolver.filmInit(i).mix.TIME  = initTIME(i);
                ffSolver.filmInit(i).mix.DT    = initTIMEDT;
                ffSolver.filmInit(i).mix.NTIME = initNTIME;
                ffSolver.filmInit(i).mix.TIDX  = initTIDX(i);

                % Initialize base and wave in each film
                ffSolver.filmInit(i).initializeBaseAndWave();

                ffSolver.dropInit(i).mix    = ffSolver.filmInit(i).mix;
                ffSolver.dropInit(i).TIME   = initTIME(i);
                ffSolver.dropInit(i).DT     = initTIMEDT;
                ffSolver.dropInit(i).NTIME  = initNTIME;
                ffSolver.dropInit(i).TIDX   = initTIDX(i);
                
            end

            % set STATE to UNSOLVED
            ffSolver.STATE = SolverState.UNSOLVED;
            
        end
        
        function e0 = EQUIL(ffSolver,flm,drp,mix,zIdx)
        %EQUIL find entrained ratio at film/drop equilibrium state (ent = dep)
        %
            if nargin < 5, zIdx = (1:ffSolver.NZ); end
            zIdx = zIdx(:);
            
            nwall = ffSolver.inputSet.geometry.NWALL;                      % Number of walls
            perim = ffSolver.inputSet.geometry.PERIM;                      % [m] Perimeter
            W = mix.liquid.W(zIdx);                                        % [kg/s] Liquid flow rate
            
            for k = 1:100
                if k == 1
                    Wd(1) = 0.5.*W;                                        % [kg/s] 50% of liquid mass in droplet field
                elseif k == 2
                    Wd(k) = max(min(drp.W(zIdx).*(1-10*delta(k-1)),W),0);  % [kg/s] Next guess
                else
                    Wd(k) = interp1(delta,Wd,0,'linear','extrap');         % [kg/s] Next guess
                end
                drp.W(zIdx) = Wd(k);                                       % [kg/s] Update droplet mass flowrate
                flm.distributeOAFW((W-drp.W(zIdx)).*perim./sum(perim), zIdx);
                %flm.W(zIdx,1:nwall) = (W-drp.W(zIdx)).*perim./sum(perim);  % [kg/s] Corresponding film flow distribution (considered uniform)
                delta(k) = drp.MDEP(zIdx).*sum(perim)+sum(flm.MENT(zIdx).*perim,2); % [kg/s/m] Linear deposition - entraiment mass flow rate
                err = abs(delta(k));
                if err < 1E-4, break; end
            end
            if err > 1E-4
                disp('Film equilibrium state : not converged')
            end
            
            e0 = drp.W(zIdx)./W;                                           % [-] Entrained ratio
            
        end

        function plotz(ffSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
            arguments
                ffSolver
                tIdx    (1,1) double
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
            end
        
            switch opt.solveMode
                case 'TRANSIENT'
                    flm = ffSolver.film(tIdx);
                    drp = ffSolver.drop(tIdx);
                case 'STEADY'
                    flm = ffSolver.filmInit(tIdx);
                    drp = ffSolver.dropInit(tIdx);
                    tIdx = 1;
            end
            
            bc  = ffSolver.boundaryConditions;
            mix = flm.mix;
            z   = ffSolver.Z;
            oafZ = repmat(mix.OAFZ,1,2);

            NWALL = ffSolver.inputSet.geometry.NWALL();

            plotters = Solvers.SolverPlotter( ...
                                sprintf('Axial distributions of four-field parameters at %0.3f [s] - %s', flm.TIME, opt.solveMode), ...
                                1:NWALL);
            plotters.setZs(z);

            % Wall heat flux
            plotters.newTile( ...
                "tileTitle", 'Wall heat flux', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Wall heat flux [W/m^2]');
            plotters.plotz(bc.HFLUX(:,:,tIdx), 'BC', 'DisplayName', 'Boundary Condition');
            plotters.plotz(flm.HFLUX, 'FILM', 'DisplayName', 'Film');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Mass flow rates
            plotters.newTile( ...
                "tileTitle", 'Mass flow rate', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Field mass flow rate [kg/s]');
            plotters.plotz(mix.liquid.W, 'MIXLIQ', 'DisplayName', 'Mixture Liquid');
            plotters.plotz(sum([drp.W flm.W],2), 'DROP+FILM', 'DisplayName', 'Drop + Film');
            plotters.plotz(drp.W, 'Drop');
            plotters.plotz(flm.W, 'Film');
            plotters.plotz(flm.base.W, 'Base');
            plotters.plotz(flm.wave.W,'Wave');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Film WL
            plotters.newTile( ...
                "tileTitle", 'Film mass flow rate per unit perimeter', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Film mass flow rate [kg/s-m]');
            plotters.plotz(flm.WL, 'Film')
            plotters.plotz(flm.base.WL, 'Base')
            plotters.plotz(flm.wave.WL,'Wave')
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Base-Wave Exchange
            ah_base = plotters.newTile( ...
                        "tileTitle", 'Base film mass exchange', ...
                        'xlabel', 'Axial position [m]', ...
                        'ylabel', 'Mass flux [kg/s/m^2]');
            plotters.plotz(flm.base.ETA.*drp.MDEP(), 'DEPOSITION', 'DisplayName', 'Drop deposition');
            plotters.plotz(flm.base.MENT(), 'Entrainment');
            plotters.plotz(flm.base.MEVAP(), 'Evaporation');
            plotters.plotz(flm.base.MWAVE(drp), 'Wave', 'DisplayName', 'Exchange from wave');
            plotters.plotz(flm.base.MTOT(drp), 'Total');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Wave-Base Exchange
            ah_wave = plotters.newTile( ...
                        "tileTitle", 'Wave mass exchange', ...
                        'xlabel', 'Axial position [m]', ...
                        'ylabel', 'Mass flux [kg/s/m^2]');
            plotters.plotz(flm.wave.ETA.*drp.MDEP(), 'DEPOSITION', 'DisplayName', 'Drop deposition');
            plotters.plotz(flm.wave.MENT(), 'Entrainment');
            plotters.plotz(flm.wave.MEVAP(), 'Evaporation');
            plotters.plotz(flm.wave.MBASE(drp), 'Base', 'DisplayName', 'Exchange from base');
            plotters.plotz(flm.wave.MTOT(drp), 'Total');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Link exchange axes 
            % TODO: this can be a plotter method
            for wallIdx = 1:length(ah_base)
                linkaxes([ah_base(wallIdx), ah_wave(wallIdx)]);
            end

            % Wave frequencies
            plotters.newTile( ...
                "tileTitle", 'Wave frequency', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Frequency [Hz]');
            plotters.plotz(flm.wave.FREQUENCY(), 'Non-Equilibrium');
            plotters.plotz(flm.wave.EQFREQUENCY(), 'Equilibrium');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Film thickness
            plotters.newTile( ...
                "tileTitle", 'Film thickness', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Film thickness [m]');
            plotters.plotz(flm.THICK, 'Film');
            plotters.plotz(flm.base.THICK, 'Base');
            plotters.plotz(flm.wave.THICK, 'Wave');
            plotters.plotz(flm.base.EQTHICK(), 'Base Eq');
            plotters.plotz(flm.wave.AMP(), 'Wave Amp');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);
            plotters.ylim([0 1E-3]);

            % Wave axial lengths
            plotters.newTile( ...
                "tileTitle", 'Wave axial length', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Axial length [m]');
            plotters.plotz(flm.wave.SPACING(), 'Spacing');
            plotters.plotz(flm.wave.WIDTH(), 'Width');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Base film fractions
            plotters.newTile( ...
                "tileTitle", 'Base film fractions', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Fraction [-]');
            plotters.plotz(flm.base.BETA(), 'Interfacial');
            plotters.plotz(flm.base.EPSILON(), 'Mass');
            plotters.plotz(flm.base.BETAP(), 'Heat flux');
            plotters.plotz(flm.base.ETA(), 'Deposition');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);
            plotters.ylim([0 1]);

            % Wave fractions
            plotters.newTile( ...
                "tileTitle", 'Wave fractions', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Fraction [-]');
            plotters.plotz(flm.wave.BETA(), 'Interfacial');
            plotters.plotz(flm.wave.EPSILON(), 'Mass');
            plotters.plotz(flm.wave.BETAP(), 'Heat flux');
            plotters.plotz(flm.wave.ETA(), 'Deposition');
            plotters.plotz(flm.wave.SHAPEFACTOR(), 'Shape factor');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);
            plotters.ylim([0 1]);

            % Field velocities
            plotters.newTile( ...
                "tileTitle", 'Field velocities', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Field velocities [m/s]');
            plotters.plotz(mix.liquid.U, 'Mixture');
            plotters.plotz(drp.U, 'Drop');
            plotters.plotz(flm.U, 'Film');
            plotters.plotz(flm.base.U, 'Base');
            plotters.plotz(flm.wave.U, 'Wave');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);
            
            % Film momentum exchanges
            plotters.newTile( ...
                "tileTitle", 'Film momentum exchanges', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Shear stress [N/m^2]');
            plotters.plotz(flm.FDEP(drp), 'Drop deposition');
            plotters.plotz(flm.FWALL(),  'Wall');
            plotters.plotz(flm.FVAPOR(),  'Vapor');
            plotters.plotz(flm.FBUOY(),   'Buoyancy');
            plotters.plotz(flm.FGRAV(),   'Gravity');
            plotters.plotz(flm.FTOT(drp), 'Total');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Drop momentum exchanges
            plotters.newTile( ...
                "tileTitle", 'Drop momentum exchanges', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Shear stress [N/m^2]');
            plotters.plotz(drp.FENT(flm),  'Film entrainment');
            plotters.plotz(drp.FDRAG(),    'Drag');
            plotters.plotz(drp.FBUOY(),   'Buoyancy');
            plotters.plotz(drp.FGRAV(),   'Gravity');
            plotters.plotz(drp.FTOT(flm), 'Total');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);
            
 
            % Reynolds number
            plotters.newTile( ...
                "tileTitle", 'Reynolds number', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', {'Vapor Re [-]', 'Liquid Re [-]'});
            plotters.plotz(mix.vapor.RE(), 'Vapor', 'yyaxis', 'left');
            plotters.plotz(flm.base.RE(),  'Base', 'yyaxis', 'left');
            plotters.plotz(flm.wave.RE(),  'Wave', 'yyaxis', 'right');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            
            
        end
    
        function plott(tfSolver, zIdx, opt)
            %PLOTT 
            % 
            arguments
                tfSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    flm = tfSolver.film;
                    drp = tfSolver.drop;
                case 'STEADY'
                    flm = tfSolver.filmInit;
                    drp = tfSolver.dropInit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(flm);
            end

            % Cannot plot time series of one time step
            if isscalar(flm) || isscalar(opt.tIdx)
                tfSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
%                 throw( ...
%                     MException( ...
%                         'MixtureSolverPlottError:ScalarTimestepError', ...
%                         'Non-scalar time index required to plot time series'))
            end

            % Time vector
            plotTimeVector = [flm(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time series of mixture parameters at ' num2str(tfSolver.Z(zIdx(1))) ' [m]']);
            
            timeplot('W','Mass flowrates [kg/s]')
            timeplot('U','Velocity [m/s]')

            function timeplot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(flm,param)
                    paramData = arrayfun( ...
                                    @(i) flm(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [flm.(param)];
                end
                
                plot(plotTimeVector, paramData(zIdx,opt.tIdx),'.-');

                legendStr = num2str(tfSolver.Z(zIdx),'z=%0.4f m');
                legend(legendStr,'Location','southeast');
                
                xlabel('Time [s]'); xlim(plotTimeVector([1 end]));
                ylabel(ylabelText)
                set(gca,'fontsize',10)
            
            end

        end
        
        function saveResults(ffSolver, opts)
        %SAVERESULTS
        %
        arguments
            ffSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = ffSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', ffSolver.Z, ...
                                'TIME', ffSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', ffSolver.boundaryConditions, ...
                                'filmInit', struct(ffSolver.filmInit), ...
                                'dropInit', struct(ffSolver.dropInit), ...
                                'film', struct(ffSolver.film), ...
                                'base', struct([ffSolver.film.base]), ...
                                'wave', struct([ffSolver.film.wave]), ...
                                'drop', struct(ffSolver.drop));
                    
                    if isfolder(session.directory)
                        save( ...
                            fullfile( ...
                                session.directory, strcat(session.name,'.mat')), ...
                            '-struct', ...
                            "results", ...
                            "-mat" ...
                        );
                    else
                        error('%s does not exist. Check Session.log.LOGMODE. Try session.makeSessionDirectory()');
                    end
            end


        end

    end
end

