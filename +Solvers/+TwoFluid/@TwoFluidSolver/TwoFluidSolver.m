classdef TwoFluidSolver < Solvers.AbstractSolver
    %TWOFLUIDSOLVER Summary of this class goes here
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
        
        mixtureInit
        mixture
        liquidInit
        vaporInit
        liquid
        vapor

     end

     properties (SetAccess = protected)
        mixSolver
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(twfSolver)
    end

    methods
        function twfSolver = TwoFluidSolver(inputSet,mixSolver)
            %TWOFLUIDSOLVER Creates a TwoFluid solver
            %   Detailed explanation goes here
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            twfSolver = twfSolver@Solvers.AbstractSolver(inputSet);
            
            % Store mixSolver handle
            twfSolver.mixSolver = mixSolver;

            % Attempt to solve mixSolver if it is unsolved
            if twfSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
                twfSolver.mixSolver.solve();
            end
            
            % Initialize solver parameters
            twfSolver.initializeSolver();

        end
        
        function initializeSolver(twfSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.TwoFluid.*
            import Solvers.*

            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                twfSolver.(p{:}) = twfSolver.mixSolver.(p{:});
            end


            % Local parameters
            mixArr = twfSolver.mixSolver.mixture;                            % Mixture solution
            %model  = twfSolver.inputSet.model;                               % Models
            %geom   = twfSolver.inputSet.geometry;

            % Setup inner iteration value struct
            ITRFields = ["N","DWL","DUL"];
            ITRl = twfSolver.CreateITR(twfSolver.NZ, ITRFields);
            ITRFields = ["N","DWV","DUV"];
            ITRv = twfSolver.CreateITR(twfSolver.NZ, ITRFields);

            % Create liquid and vapor arrays (by timestep)
            liqArr(twfSolver.NTIME) = Liquid(mixArr);
            vapArr(twfSolver.NTIME) = Vapor(mixArr);
            props = {'NZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid', 'mix'};                 % film and drop properties
            
            for tIdx = 1:twfSolver.NTIME

                % Convenience variables (handles)
                liq         = liqArr(tIdx);
                vap         = vapArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = twfSolver.fluid(tIdx);
                
                % Inputset, fluid                
                liq.inputSet = twfSolver.inputSet;
                liq.fluid    = fluid;
                liq.mix      = mix;
                
                % Axial Steps
                vap.DZ = twfSolver.DZ;
                liq.NZ = twfSolver.NZ;
                liq.DZ = twfSolver.DZ;
                liq.Z  = twfSolver.Z;
                
                % Time step
                liq.NTIME = twfSolver.NTIME;
                liq.DT    = twfSolver.DT;
                liq.TIME  = twfSolver.TIME(tIdx);
                liq.TIDX  = tIdx;
                
                % Copy properties to vapor
                for p = props
                    vap.(p{:}) = liq.(p{:});
                end
                
                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note 1: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                % Note 2: other, maybe better, initialization states could be investigated
                vapArr(tIdx).W = mix(tIdx).W.*mix(tIdx).X; % [kg/s] % Set vapor mass flow to mixture model mass flow rate times quality
                
                % Transient mass gradient in film field
                liqArr(tIdx).W = mix(tIdx).W.*(1-mix(tIdx).X); % [kg/s] % Set liquid mass flow to mixture model mass flow rate times quality
                
                % ... or transient mass gradient in drop field
                %vap.W = drp.W+mix.W-mix.W(mix.OAFIDX);                                % 
                %liq.W(1,1:geom.NWALL) = (mix.liquid.W(1)-drp.W(1)).*geom.PERIM./sum(geom.PERIM);  % [kg/s] Distribute film at inlet uniformly on all walls
                
                % Limit flow rate minimum to 0
                liq.W = max(0,liq.W);
                vap.W = max(0,vap.W);                
                
                % Initialize velocity [m/s]
                vap.U = mix.vapor.U;                                      % [m/s] Drop velocity
                liq.U = mix.liquid.U;                                         % [m/s] Drop velocity
               
                                
                % Initialize enthalpy [J/kg]
                vap.H = mix.vapor.H;
                liq.H = mix.liquid.H;
                
                % ITR
                liq.ITR = ITRl;
                vap.ITR = ITRv;

            end

            % Store transient mixture array
            twfSolver.liquid = liqArr;
            twfSolver.vapor = vapArr;


            % Create steady state mixture array
            twfSolver.liquidInit = copy( ...
                repmat(liqArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.vaporInit = copy( ...
                repmat(vapArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.fluidInit = FluidProperties( ...
                                    repmat( ...
                                        twfSolver.boundaryConditions.PRESSURE(1), ...
                                        1, ...
                                        twfSolver.inputSet.options.SSMAXITER), ...
                                    twfSolver.inputSet.model);

            % Update liquidInit and vaporInit times and timesteps
            initTIMEDT = twfSolver.inputSet.options.SSTSTEP;
            initNTIME = length(twfSolver.liquidInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(twfSolver.liquidInit);

            for i = 1:length(twfSolver.liquidInit)
                twfSolver.liquidInit(i).TIME = initTIME(i);
                twfSolver.liquidInit(i).DT = initTIMEDT;
                twfSolver.liquidInit(i).NTIME = initNTIME;
                twfSolver.liquidInit(i).TIDX = initTIDX(i);

                twfSolver.liquidInit(i).mix       = copy(twfSolver.mixSolver.mixtureInit(end));
                twfSolver.liquidInit(i).mix.TIME  = initTIME(i);
                twfSolver.liquidInit(i).mix.DT    = initTIMEDT;
                twfSolver.liquidInit(i).mix.NTIME = initNTIME;
                twfSolver.liquidInit(i).mix.TIDX  = initTIDX(i);

                twfSolver.vaporInit(i).mix    = twfSolver.liquidInit(i).mix;

                twfSolver.vaporInit(i).TIME = initTIME(i);
                twfSolver.vaporInit(i).DT = initTIMEDT;
                twfSolver.vaporInit(i).NTIME = initNTIME;
                twfSolver.vaporInit(i).TIDX = initTIDX(i);
            end

            % set STATE to UNSOLVED
            twfSolver.STATE = SolverState.UNSOLVED;

        end

        % adjust plot functions

        function plotz(mixSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
            arguments
                mixSolver
                tIdx    (1,1) double
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture(tIdx);
                case 'STEADY'
                    mix = mixSolver.mixtureInit(tIdx);
            end
            
            figure('name',['Axial distributions of mixture parameters at ' num2str(mix.TIME) ' [s]'])
                
            nexttile; hold all; grid on; title('Mass flow rates')
            plot(mix.Z,mix.W,'.-')  
            plot(mix.liquid.Z,mix.liquid.W,'.-')
            plot(mix.vapor.Z,mix.vapor.W,'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Mass flowrates [kg/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Pressure drop')
            plot(mix.Z,cumsum(mix.DP.Tot),'.-') 
            plot(mix.Z,cumsum(mix.DP.Grav),'.-')
            plot(mix.Z,cumsum(mix.DP.Wall),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_z),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_t),'.-')
            plot(mix.Z,cumsum(mix.DP.K),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Pressure drop [Pa]')
            legend({'Total','Gravitational','Wall','Acc z','Acc t','Local'},'location','northWest');
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Void fraction and quality')
            plot(mix.Z,mix.XEQ(1:mix.NZ),'.-')  
            plot(mix.Z,mix.X(1:mix.NZ),'.-')
            plot(mix.Z,mix.VF(1:mix.NZ),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Quality / Void fraction [-]')
            legend({'Equilibrium quality','Vapor mass quality','Void fraction'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Field velocity')
            plot(mix.Z,mix.U(1:mix.NZ),'.-')  
            plot(mix.liquid.Z,mix.liquid.U(1:mix.NZ),'.-')
            plot(mix.vapor.Z,mix.vapor.U(1:mix.NZ),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Velocities [m/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)

        end
    
        function plott(mixSolver, zIdx, opt)
            %PLOTT 
            % 
            arguments
                mixSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture;
                case 'STEADY'
                    mix = mixSolver.mixtureInit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(mix);
            end

            % Cannot plot time series of one time step
            if isscalar(mix) || isscalar(opt.tIdx)
                mixSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
            end

            % Time vector
            plotTimeVector = [mix(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time series of mixture parameters at ' num2str(mixSolver.Z(zIdx(1))) ' [m]']);
            
            timeplot('W','Mass flowrates [kg/s]')
            timeplot('P','Pressure [Pa]')
            timeplot('XEQ','Equilibrium quality [-]')
            timeplot('X','Steam mass quality [-]')
            timeplot('VF','Void fraction [-]')
            timeplot('U','Velocity [m/s]')

            function timeplot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(mix,param)
                    paramData = arrayfun( ...
                                    @(i) mix(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [mix.(param)];
                end
                
                plot(plotTimeVector, paramData(zIdx,opt.tIdx),'.-');

                legendStr = num2str(mixSolver.Z(zIdx),'z=%0.4f m');
                legend(legendStr,'Location','southeast');
                
                xlabel('Time [s]'); xlim(plotTimeVector([1 end]));
                ylabel(ylabelText)
                set(gca,'fontSize',14)
            
            end

        end

        function plotzt(mixSolver, zIdx, opt)
        % 2d plot, position z on horizontal and time t on vertical axis
            arguments
                mixSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end

            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture;
                case 'STEADY'
                    mix = mixSolver.mixtureInit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(mix);
            end

            % Cannot plot time series of one time step
            if isscalar(mix) || isscalar(opt.tIdx)
                mixSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
            end

            % Time vector
            plotTimeVector = [mix(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time series of mixture parameters at ' num2str(mixSolver.Z(zIdx(1))) ' [m]']);
            
            zt_plot('W','Mass flowrates [kg/s]')
            zt_plot('P','Pressure [Pa]')
            zt_plot('XEQ','Equilibrium quality [-]')
            zt_plot('X','Steam mass quality [-]')
            zt_plot('VF','Void fraction [-]')
            zt_plot('U','Velocity [m/s]')

            function zt_plot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(mix,param)
                    paramData = arrayfun( ...
                                    @(i) mix(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [mix.(param)];
                end
                
                [t_mesh,z_mesh] = meshgrid(plotTimeVector,mixSolver.Z);

                surf(z_mesh,t_mesh,paramData);
                shading interp 
                xlabel('Position z [m]') 
                ylabel('Time t [s]') 
                view(2);
                cb = colorbar(); 
                ylabel(cb,ylabelText,'FontSize',12,'Rotation',270)
            
            end

        end

        
        function saveResults(mixSolver, opts)
        %SAVERESULTS
        %
        arguments
            mixSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = mixSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', mixSolver.Z, ...
                                'TIME', mixSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', mixSolver.boundaryConditions, ...
                                'mixtureInit', struct(mixSolver.mixtureInit), ...
                                'mixture', struct(mixSolver.mixture));

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

