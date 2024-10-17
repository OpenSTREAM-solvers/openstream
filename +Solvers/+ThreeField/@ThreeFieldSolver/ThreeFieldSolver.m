classdef ThreeFieldSolver < Solvers.AbstractSolver
    %THREEFIELDSOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=protected)
        
        NZ           (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of time steps
        TIME         (:,1) double  {mustBeNumeric}                          = 0         % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                          = 0         % [s] Time step size
        Z            (:,1) double  {mustBeNumeric}                          = 1.        % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                          = 0         % [m] Axial step size

        fluid       {isa(fluid,'Inputs.FluidProperties')}
        boundaryConditions
        
        filmInit
        dropInit
        fluidInit
        film
        drop

     end

     properties (SetAccess = protected)
        mixSolver
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
        SOLVERMODE
        previousSolution                                                   
     end


    methods
        solve(tfSolver)
    end

    methods
        function tfSolver = ThreeFieldSolver(inputSet,mixSolver, opts)
            %THREEFIELDSOLVER Creates a ThreeField solver
            %   Detailed explanation goes here
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
                opts.solverMode     (1,1)   Solvers.SolverMode              = Solvers.SolverMode.NEW
                opts.initSolver     (1,1)   logical                         = true
                opts.prevSolution   {mustBeScalarOrEmpty}                   = []
            end

            % Call abstract class constructor
            tfSolver = tfSolver@Solvers.AbstractSolver(inputSet);
            
            % State -> CREATED
            tfSolver.STATE = Solvers.SolverState.CREATED;

            % Store mixSolver handle
            tfSolver.mixSolver = mixSolver;

            % Check and store solver mode
            if opts.solverMode == Solvers.SolverMode.CONTINUE
                % opts.prevSolution is needed to continue
                if ~isempty(opts.prevSolution)
                    
                    % Store previous solution
                    tfSolver.previousSolution = opts.prevSolution;

                else
                    % TODO: reorganize errors
                    error("THREEFIELDSOLER:InputArgumentsError", "The previous solution was not provided");
                end
            elseif opts.solverMode == Solvers.SolverMode.NEW
                % TODO: Do something here?
            end

            % Store solver mode
            tfSolver.SOLVERMODE = opts.solverMode;

            % Attempt to solve mixSolver if it is unsolved
            if tfSolver.mixSolver.STATE ~= Solvers.SolverState.SOLVEDCONVERGED && tfSolver.mixSolver.STATE ~= Solvers.SolverState.SOLVEDNOTCONVERGED
                tfSolver.mixSolver.solve();
            end
            
            if opts.initSolver
                % Initialize solver parameters
                tfSolver.initializeSolver();
            end

        end
        
        function initializeSolver(tfSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.ThreeField.*
            import Solvers.*
            
            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                tfSolver.(p{:}) = tfSolver.mixSolver.(p{:});
            end
            
            % Local parameters
            mixArr = tfSolver.mixSolver.mixture;                            % Mixture solution
            model  = tfSolver.inputSet.model;                               % Models
            geom   = tfSolver.inputSet.geometry;                            % Geometry
            
            % Setup inner iteration value struct
            ITRFields = ["N","DWL","DU"];
            ITRf = tfSolver.CreateITR(tfSolver.NZ, ITRFields);
            ITRFields = ["N","DU"];
            ITRd = tfSolver.CreateITR(tfSolver.NZ, ITRFields);

            % Create film and drop arrays (by timestep)
            flmArr(tfSolver.NTIME) = Film();
            drpArr(tfSolver.NTIME) = Drop();
            props = {'NZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid', 'mix'};                 % film and drop properties

            for tIdx = 1:tfSolver.NTIME
    
                % Convenience variables (handles)
                flm         = flmArr(tIdx);
                drp         = drpArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = tfSolver.fluid(tIdx);
                
                % Inputset, fluid                
                flm.inputSet = tfSolver.inputSet;
                flm.fluid    = fluid;
                flm.mix      = mix;
                
                % Axial Steps
                drp.DZ = tfSolver.DZ;
                
                flm.NZ = tfSolver.NZ;
                flm.DZ = tfSolver.DZ;
                flm.Z  = tfSolver.Z;
                
                % Time step
                flm.NTIME = tfSolver.NTIME;
                flm.DT    = tfSolver.DT;
                flm.TIME  = tfSolver.TIME(tIdx);
                flm.TIDX  = tIdx;
                
                % Copy properties to drop
                for p = props
                    drp.(p{:}) = flm.(p{:});
                end
                    
                % Wall evaporation heat flux
                HFLUX = mix.HFLUX;                                      % [W/m^2] Wall heat flux
                avgHFLUX = sum(HFLUX.*geom.PERIM,2)./sum(geom.PERIM);   % [W/m^2] Average heat flux
                avgHFLUX = repmat(avgHFLUX,1,geom.NWALL);               % [W/m^2] ... distributed to all walls
                
                evapFn = double(mix.XEQ > 0);                        % Saturated evaporation function
                Nbo = find(evapFn > 0,1);                                  % Boiling transition node
                if Nbo >1
                    % Adjust evaporation function in transition node 
                    % (part toward subcooled liquid, part toward evaporation)
                    evapFn(Nbo) = mix.XEQ(Nbo)/diff(mix.XEQ(Nbo-1:Nbo)); 
                end
                
                flm.HFLUX = mix.AFDISTR(evapFn.*avgHFLUX,HFLUX); % [W/m^2] Film evaporation heat flux
                    
                % Film evaporation (thermal equilibrium assumption)
                flm.MEVAP = -flm.HFLUX./(fluid.HG-fluid.HF); % [kg/m^2/s] Evaporation mass flux
                
                % Entrained ratio at onset of annular flow
                switch model.OAFENTRAINED
                    case InputEnums.OAFENTRAINED.RATIO
                        e0 = model.OAFDROPRATIO;
                    case InputEnums.OAFENTRAINED.EQUILIBRIUM
                        e0 = tfSolver.EQUIL(flm,drp,mix,mix.OAFIDX);
                end
                
                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note 1: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                % Note 2: other, maybe better, initialization states could be investigated
                drpArr(tIdx).W = repmat(e0.*mixArr(tIdx).OAFWL,tfSolver.NZ,1); % [kg/s] % Set drop mass flow to onset of annular flow conditions everywhere
                
                % Transient mass gradient in film field
                %flmArr(tIdx).W = (mix(tIdx).W-drpArr(tIdx).W).*geom.PERIM./sum(geom.PERIM);           % [kg/s] Distribute film at inlet uniformly on all walls
                %flmArr(tIdx).W = flmArr(tIdx).W+cumsum(flmArr(tIdx).MEVAP).*geom.PERIM.*tfSolver.DZ;  % [kg/s] Apply simple mass conservation
                
                % For new solutions
                if tfSolver.SOLVERMODE == SolverMode.NEW
                    % ... or transient mass gradient in drop field
                    drp.W = drp.W+mix.W-mix.W(mix.OAFIDX);                                % 
                end

                flm.W(1,1:geom.NWALL) = (mix.liquid.W(1)-drp.W(1)).*geom.PERIM./sum(geom.PERIM);  % [kg/s] Distribute film at inlet uniformly on all walls
                flm.W = flm.W(1,:)+cumsum(flm.MEVAP).*geom.PERIM.*tfSolver.DZ;                 % [kg/s] Apply simple mass conservation
                
                % Limit film flow rate minimum to 0
                flm.W = max(0,flm.W);
                drp.W = mix.liquid.W-sum(flm.W,2); % [kg/s] Recalculate consistent drop flow rate
                    
                % Initialize velocity [m/s]
                %drp.U = mix.liquid.U;                                      % [m/s] Drop velocity
                drp.U = drp.USLIP();                                        % [m/s] Drop velocity
                
                %flm.U = repmat(mix.liquid.U,1,geom.NWALL); % [m/s]
                flm.U = flm.UALGEBR();                                      % [m/s] Film velocity
                                
                % Initialize enthalpy [J/kg] by number of spatial nodes, NZ
                % TODO: repmat by NWALL as well?
                drp.H = repmat(fluid.HF,tfSolver.NZ,1);
                flm.H = repmat(fluid.HF,tfSolver.NZ,1);
                
                % ITR
                flm.ITR = ITRf;
                drp.ITR = ITRd;
    
            end

            % Store transient film and drop array
            tfSolver.film = flmArr;
            tfSolver.drop = drpArr;

            if tfSolver.SOLVERMODE == SolverMode.CONTINUE
                
                % TODO: Check prevSolution has same timestep as current
                
                % Copy threefield properties from last node in prevSolution
                % for each time step to first node in this solution
                for tIdx = 1:length(tfSolver.previousSolution.TIME)

                    % Copy properties
                    tfSolver.previousSolution.drop(tIdx).copyFlowProperties(tfSolver.drop(tIdx),"copyMode","continue");
                    tfSolver.previousSolution.film(tIdx).copyFlowProperties(tfSolver.film(tIdx),"copyMode","continue");
                    
                    % TODO: copy these properties to all spatial nodes for
                    % faster convergence?
                    %tfSolver.drop(tIdx).copyFlowProperties()

                end

            end

             % Create steady state film and drop arrays
                tfSolver.filmInit = copy( ...
                    repmat(flmArr(1),1,tfSolver.inputSet.options.SSMAXITER));
                tfSolver.dropInit = copy( ...
                    repmat(drpArr(1),1,tfSolver.inputSet.options.SSMAXITER));
                tfSolver.fluidInit = FluidProperties( ...
                                        repmat( ...
                                            tfSolver.boundaryConditions.PRESSURE(1), ...
                                            1, ...
                                            tfSolver.inputSet.options.SSMAXITER), ...
                                        tfSolver.inputSet.model);
    
                % Update filmInit and dropInit times and timesteps
                initTIMEDT = tfSolver.inputSet.options.SSTSTEP;
                initNTIME = length(tfSolver.filmInit);
                initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
                initTIDX = 1:length(tfSolver.filmInit);
    
                for i = 1:length(tfSolver.filmInit)
    
                    tfSolver.filmInit(i).TIME = initTIME(i);
                    tfSolver.filmInit(i).DT = initTIMEDT;
                    tfSolver.filmInit(i).NTIME = initNTIME;
                    tfSolver.filmInit(i).TIDX = initTIDX(i);
    
                    tfSolver.filmInit(i).mix       = copy(tfSolver.mixSolver.mixtureInit(end));
                    tfSolver.filmInit(i).mix.TIME  = initTIME(i);
                    tfSolver.filmInit(i).mix.DT    = initTIMEDT;
                    tfSolver.filmInit(i).mix.NTIME = initNTIME;
                    tfSolver.filmInit(i).mix.TIDX  = initTIDX(i);
    
                    tfSolver.dropInit(i).mix    = tfSolver.filmInit(i).mix;
    
                    tfSolver.dropInit(i).TIME = initTIME(i);
                    tfSolver.dropInit(i).DT = initTIMEDT;
                    tfSolver.dropInit(i).NTIME = initNTIME;
                    tfSolver.dropInit(i).TIDX = initTIDX(i);
                end
    
                % set STATE to INITIALIZED
                tfSolver.STATE = SolverState.INITIALIZED;
            
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
                    Wd(k) = interp1(delta,Wd,0,'linear','extrap');         % [kg/s] Next guess
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

        function plotters = plotz(tfSolver, tIdx, opts)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
            arguments
                tfSolver
                tIdx    (1,1) double
                opts.solveMode {mustBeMember(opts.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opts.plotter = []
            end
        
            switch opts.solveMode
                case 'TRANSIENT'
                    flm = tfSolver.film(tIdx);
                    drp = tfSolver.drop(tIdx);
                case 'STEADY'
                    flm = tfSolver.filmInit(tIdx);
                    drp = tfSolver.dropInit(tIdx);
                    tIdx = 1;
            end
            
            bc  = tfSolver.boundaryConditions;
            mix = tfSolver.mixSolver.mixture(tIdx);
            z   = tfSolver.Z;
            oafZ = repmat(mix.OAFZ, 1, 2);

            NWALL = tfSolver.inputSet.geometry.NWALL;

             % Reuse plotter if provided
            if length(opts.plotter) == NWALL
                plotters = opts.plotter;
            else
                plotters = Solvers.SolverPlotter( ...
                                    sprintf('Axial distributions of three-field parameters at %0.3f [s] - %s', flm.TIME, opts.solveMode), ...
                                    1:NWALL);
            end
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
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);
                
            % Film WL
            plotters.newTile( ...
                "tileTitle", 'Film mass flow rate per unit perimeter', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Film mass flow rate [kg/s-m]');
            plotters.plotz(flm.WL, 'Film')
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            
            % Field velocities
            plotters.newTile( ...
                "tileTitle", 'Field velocities', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Field velocities [m/s]');
            plotters.plotz(mix.liquid.U, 'Mixture');
            plotters.plotz(drp.U, 'Drop');
            plotters.plotz(flm.U, 'Film');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Film thickness
            plotters.newTile( ...
                "tileTitle", 'Film thickness', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Film thickness [m]');
            plotters.plotz(flm.THICK, 'Film');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

            % Base-Wave Exchange
            ah_base = plotters.newTile( ...
                        "tileTitle", 'Film mass exchange', ...
                        'xlabel', 'Axial position [m]', ...
                        'ylabel', 'Mass flux [kg/s/m^2]');
            plotters.plotz(drp.MDEP(), 'DEPOSITION', 'DisplayName', 'Drop deposition');
            plotters.plotz(flm.MENT(), 'Entrainment');
            plotters.plotz(flm.MEVAP(), 'Evaporation');
            plotters.legend("show", 'Location', 'best');
            plotters.plotOAF(oafZ);

             % Base momentum exchanges
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
        
        function saveResults(tfSolver, opts)
        %SAVERESULTS
        %
        arguments
            tfSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = tfSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', tfSolver.Z, ...
                                'TIME', tfSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', tfSolver.boundaryConditions, ...
                                'filmInit', struct(tfSolver.filmInit), ...
                                'dropInit', struct(tfSolver.dropInit), ...
                                'film', struct(tfSolver.film), ...
                                'drop', struct(tfSolver.drop));
                    
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

