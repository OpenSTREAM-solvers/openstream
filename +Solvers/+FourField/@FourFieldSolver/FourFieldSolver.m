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
                
                % Entrained ratio at onset of annular flow
                switch model.OAFENTRAINED
                    case InputEnums.OAFENTRAINED.RATIO
                        e0 = model.OAFDROPRATIO;
                    case InputEnums.OAFENTRAINED.EQUILIBRIUM
                        % TODO: this does not work yet.
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
        
        function e0 = EQUIL(tfSolver,flm,drp,mix,zIdx)
        %EQUIL find entrained ratio at film/drop equilibrium state (ent = dep)
        %
            if nargin < 5, zIdx = (1:tfSolver.NZ); end
            zIdx = zIdx(:);
            
            nwall = tfSolver.inputSet.geometry.NWALL;                      % Number of walls
            perim = tfSolver.inputSet.geometry.PERIM;                      % [m] Perimeter
            W = mix.liquid.W(zIdx);                                        % [kg/s] Liquid flow rate
            
            for k = 1:100
                if k == 1
                    Wd(1) = 0.5.*W;                                        % [kg/s] 50% of liquid mass in droplet field
                elseif k == 2
                    Wd(k) = max(min(drp.W(zIdx).*(1-10*delta(k-1)),W),0);  % [kg/s] Next guess
                else
                    Wd(k) = interp1(delta,Wd,0,'spline','extrap');         % [kg/s] Next guess
                end
                drp.W(zIdx) = Wd(k);                                       % [kg/s] Update droplet ass flowrate
                flm.W(zIdx,1:nwall) = (W-drp.W(zIdx)).*perim./sum(perim);  % [kg/s] Corresponding film flow distribution (considered uniform)
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
            figure('name',sprintf('Axial distributions of four-field parameters at %0.3f [s] - %s', flm.TIME, opt.solveMode))
            
            nexttile; hold all; grid on; title('Wall heat flux')
            plot(z,bc.HFLUX(:,:,tIdx),'s-')
            plot(z,flm.HFLUX,'.--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim([0 z(end)]);
            ylabel('Wall heat flux [W/m^2]')
            set(gca,'fontSize',14)
                
            nexttile; hold all; grid on; title('Mass flow rates')
            plot(z,mix.liquid.W,'s')
            plot(z,sum([drp.W flm.W],2),'r+-')
            plot(z,drp.W,'o-')
            plot(z,flm.W,'.-')
            plot(z,flm.base.W,'.--')
            plot(z,flm.wave.W,'s--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Field mass flowrate [kg/s]')
            legend({'Mixture Liquid','Drop + Film','Drop','Film','Base','Wave'},'location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Film mass flow rates per unit perimeter')
            plot(z,flm.WL,'.-')
            plot(z,flm.base.WL,'.--')
            plot(z,flm.wave.WL,'s--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Film mass flowrate [kg/s/m]')
            legend({'Film','Base','Wave'},'location','best')
            set(gca,'fontSize',14)
            
            fields = {'base','wave'};
            names = cellfun(@(x) [upper(x(1)) x(2:end)],fields,'uni',0);
            wrapN = @(x) (1 + mod(x-1, length(fields)));
            for i = 1:length(fields)
                
                ax(i) = nexttile; hold all; grid on; title([names{i} ' film mass exchanges'])
                plot(z,flm.(fields{i}).ETA.*drp.MDEP(),'.-', 'DisplayName',[names{i} ' drop deposition'])
                plot(z,flm.(fields{i}).MENT(),'.-', 'DisplayName',[names{i} ' film entrainment'])
                plot(z,flm.(fields{i}).MEVAP(),'.-', 'DisplayName',[names{i} ' film evaporation'])
                plot(z,flm.(fields{i}).(['M' upper(fields{wrapN(i+1)})])(drp),'.-', 'DisplayName',['Exchange from ' names{wrapN(i+1)}])
                h0 = scatter(z,flm.(fields{i}).MTOT(drp),5,'k+', 'DisplayName','Total'); h0.MarkerEdgeAlpha=0.5;
%                 set(gca,'ColorOrderIndex',1)
%                 h1 = plot(z,drp.MDEP(),'--', 'DisplayName','Drop deposition'); h1.Color(4) = 0.3;
%                 h2 = plot(z,flm.MENT(),'--', 'DisplayName','Film entrainment'); h2.Color(4) = 0.3;
%                 h3 = plot(z,flm.MEVAP(),'--', 'DisplayName','Film evaporation'); h3.Color(4) = 0.3;
%                 h4 = plot(z,flm.MTOT(drp),'k--', 'DisplayName','Total'); h4.Color(4) = 0.3;
                plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off');
                xlabel('Axial position [m]'); xlim(z([1 end]));
                ylabel('Mass flux [kg/s/m^2]')
                legend('show','location','best')
                set(gca,'fontSize',14)
                
            end
            linkaxes(ax);
            
            nexttile; hold all; grid on; title('Wave frequencies')
            plot(z,flm.wave.FREQ(),'o-', 'DisplayName', 'Non-equilibrium')
            plot(z,flm.wave.EQFREQ(),'.-', 'DisplayName', 'Equilibrium')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Frequency [Hz]')
            legend('show','location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Film thicknesses')
            plot(z,flm.THICK,'.-', 'DisplayName', 'Film')
            plot(z,flm.base.THICK,'.--', 'DisplayName', 'Base')
            plot(z,flm.wave.THICK,'s--', 'DisplayName', 'Wave')
            plot(z,flm.base.EQTHICK(),'.--', 'DisplayName', 'Base Eq')
            plot(z,flm.wave.AMP(),'s--', 'DisplayName', 'Wave Amp')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Film thickness [m]'); ylim([0 1E-3]);
            legend('show','location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Wave axial lengths')
            plot(z,flm.wave.SPACING(),'o-', 'DisplayName', 'Spacing')
            plot(z,flm.wave.WIDTH(),'.-', 'DisplayName', 'Width')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Axial length [m]')
            legend('show','location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Base film fractions')
            plot(z,flm.base.BETA(),'.-', 'DisplayName', 'Interfacial')
            plot(z,flm.base.EPSILON(),'.-', 'DisplayName', 'Mass')
            plot(z,flm.base.BETAP(),'o-', 'DisplayName', 'Heat flux')
            plot(z,flm.base.ETA(),'.-', 'DisplayName', 'Deposition')
            
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Fraction [-]')
            legend('show','location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Wave fractions')
            plot(z,flm.wave.BETA(),'.-', 'DisplayName', 'Interfacial')
            plot(z,flm.wave.EPSILON(),'.-', 'DisplayName', 'Mass')
            plot(z,flm.wave.BETAP(),'o-', 'DisplayName', 'Heat flux')
            plot(z,flm.wave.ETA(),'.-', 'DisplayName', 'Deposition')
            plot(z,flm.wave.SHAPEFACTOR(),'.-', 'DisplayName', 'Shape factor')
            
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Fraction [-]'); ylim([0 1]);
            legend('show','location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Field velocities')
            plot(z,mix.liquid.U,'s')
            plot(z,drp.U,'o-')
            plot(z,flm.U,'.-')
            plot(z,flm.base.U,'.--')
            plot(z,flm.wave.U,'s--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Field velocity [m/s]')
            legend({'Mixture Liquid','Drop','Film','Base','Wave'},'location','best')
            set(gca,'fontSize',14)
                        
            nexttile; hold all; grid on; title('Film momentum exchanges')
            plot(z,flm.FDEP(drp),'o-')
            plot(z,flm.FWALL(),'.-')
            plot(z,flm.FVAPOR(),'.-')
            plot(z,flm.FBUOY(),'.-')
            plot(z,flm.FGRAV(),'.-')
            plot(z,flm.FTOT(drp),'k--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Shear stress [N/m^2]')
            legend({'Drop deposition','Wall','Vapor','Buoyancy','Gravity','Total'},'location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Drop momentum exchanges')
            plot(z,drp.FENT(flm),'o-')
            plot(z,drp.FDRAG(),'.-')
            plot(z,drp.FBUOY(),'.-')
            plot(z,drp.FGRAV(),'.-')
            plot(z,drp.FTOT(flm),'k--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Force density [N/m^3]')
            legend({'Film entrainment','Drag','Buoyancy','Gravity','Total'},'location','best')
            set(gca,'fontSize',14)
% 
%             nexttile; hold all; grid on; title('Base momentum exchanges')
%             plot(z,flm.base.FDEP(mix,drp),'o-')
%             plot(z,flm.base.FWALL(mix),'.-')
%             plot(z,flm.base.FVAPOR(mix),'.-')
%             plot(z,flm.base.FBUOY(mix),'.-')
%             plot(z,flm.base.FGRAV(mix),'.-')
%             plot(z,flm.base.FTOT(mix,drp),'k--')
%             plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
%             xlabel('Axial position [m]'); xlim(z([1 end]));
%             ylabel('Shear stress [N/m^2]')
%             legend({'Drop deposition','Wall','Vapor','Buoyancy','Gravity','Total'},'location','northEast')
%             set(gca,'fontSize',14)
            
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
                set(gca,'fontSize',14)
            
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

