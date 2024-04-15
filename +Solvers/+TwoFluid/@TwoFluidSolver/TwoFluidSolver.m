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
        
        liquidInit
        vaporInit
        fluidInit
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
            mixArr = twfSolver.mixSolver.mixture;                           % Mixture solution
            %model  = twfSolver.inputSet.model;                              % Models
            %geom   = twfSolver.inputSet.geometry;                           % Geometry

            % Setup inner iteration value struct
            ITRFields = ["N","DW","DU","DH"];
            ITRl = twfSolver.CreateITR(twfSolver.NZ, ITRFields);
            ITRFields = ["N","DW","DU","DH"];
            ITRv = twfSolver.CreateITR(twfSolver.NZ, ITRFields);

            % Create liquid and vapor arrays (by timestep)
            liqArr(twfSolver.NTIME) = Liquid();
            vapArr(twfSolver.NTIME) = Vapor();
            props = {'NZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid', 'mix'};  % liquid and vapor properties
            
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
                % Note: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                liq.W = mix.liquid.W;                                      % [kg/s] Mixture model liquid mass flow rate
                vap.W = mix.vapor.W;                                       % [kg/s] Mixture model vapor mass flow rate
                
                % Initialize velocity [m/s]
                liq.U = mix.liquid.U;                                      % [m/s] Mixture model liquid velocity
                vap.U = mix.vapor.U;                                       % [m/s] Mixture model vapor velocity
               
                % Initialize enthalpy [J/kg]
                liq.H = min(mix.H,fluid.HF);                               % [J/kg] Mixture model enthalpy, up to liquid saturation
                vap.H = max(mix.H,fluid.HG);                               % [J/kg] Mixture model enthalpy, down to vapor saturation
                
                % ITR
                liq.ITR = ITRl;
                vap.ITR = ITRv;

            end

            % Store transient mixture array
            twfSolver.liquid = liqArr;
            twfSolver.vapor  = vapArr;

            % Create steady state mixture array
            twfSolver.liquidInit = copy( ...
                repmat(liqArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.vaporInit  = copy( ...
                repmat(vapArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.fluidInit  = FluidProperties( ...
                                    repmat( ...
                                        twfSolver.boundaryConditions.PRESSURE(1), ...
                                        1, ...
                                        twfSolver.inputSet.options.SSMAXITER), ...
                                    twfSolver.inputSet.model);

            % Update liquidInit and vaporInit times and timesteps
            initTIMEDT = twfSolver.inputSet.options.SSTSTEP;
            initNTIME  = length(twfSolver.liquidInit);
            initTIME   = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX   = 1:length(twfSolver.liquidInit);

            for i = 1:length(twfSolver.liquidInit)
                twfSolver.liquidInit(i).TIME  = initTIME(i);
                twfSolver.liquidInit(i).DT    = initTIMEDT;
                twfSolver.liquidInit(i).NTIME = initNTIME;
                twfSolver.liquidInit(i).TIDX  = initTIDX(i);

                twfSolver.liquidInit(i).mix       = copy(twfSolver.mixSolver.mixtureInit(end));
                twfSolver.liquidInit(i).mix.TIME  = initTIME(i);
                twfSolver.liquidInit(i).mix.DT    = initTIMEDT;
                twfSolver.liquidInit(i).mix.NTIME = initNTIME;
                twfSolver.liquidInit(i).mix.TIDX  = initTIDX(i);

                twfSolver.vaporInit(i).mix    = twfSolver.liquidInit(i).mix;

                twfSolver.vaporInit(i).TIME   = initTIME(i);
                twfSolver.vaporInit(i).DT     = initTIMEDT;
                twfSolver.vaporInit(i).NTIME  = initNTIME;
                twfSolver.vaporInit(i).TIDX   = initTIDX(i);
            end

            % set STATE to UNSOLVED
            twfSolver.STATE = SolverState.UNSOLVED;

        end

        % adjust plot functions

        function plotz(twfSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
            arguments
                twfSolver
                tIdx    (1,1) double
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    liq = twfSolver.liquid(tIdx);
                    vap = twfSolver.vapor(tIdx);
                case 'STEADY'
                    liq = twfSolver.liquidInit(tIdx);
                    vap = twfSolver.vaporInit(tIdx);
            end
            
            bc  = twfSolver.boundaryConditions;
            mix = twfSolver.mixSolver.mixture(tIdx);
            z   = twfSolver.Z;
            NWALL = twfSolver.inputSet.geometry.NWALL();
            
            figure('name',['Axial distributions of two-fluid parameters at ' num2str(mix.TIME) ' [s]'])
            
            nexttile; hold all; grid on; title('Wall heat flux')
            bcHFLUX = bc.HFLUX(:,:,tIdx);
            liqHFLUX = liq.HFLUX;
            vapHFLUX = vap.HFLUX(liq);
            for i = 1:NWALL-1
                plot(z,bcHFLUX(:,i),'s-','handleVisibility','off')
                plot(z,liqHFLUX(:,i),'.-','handleVisibility','off')
                plot(z,vapHFLUX(:,i),'.-','handleVisibility','off')
                set(gca,'ColorOrderIndex',1)
            end
            i = NWALL;
            plot(z,bcHFLUX(:,i),'s-','displayName','Boundary conditions')
            plot(z,liqHFLUX(:,i),'.-','displayName','Liquid')
            plot(z,vapHFLUX(:,i),'.-','displayName','Gas')
            xlabel('Axial position [m]'); xlim([0 z(end)]);
            ylabel('Wall heat flux [W/m^2]')
            legend('show','location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Phase mass flow rates')
            plot(mix.Z,mix.W,'.-')  
            plot(z,liq.W,'.-')
            plot(z,vap.W,'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Phase mass flowrates [kg/s]')
            legend({'Mixture','Liquid','Gas'},'location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Vapor fraction and mass quality')
            plot(mix.Z,mix.XEQ,'.-','displayName','Equilibrium quality')  
            plot(z,vap.X,'.-','displayName','Vapor mass quality')
            plot(z,vap.VF(liq),'.-','displayName','Void fraction')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Quality [-]')
            legend('show','location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Volumetric interfacial area')
            plot(z,liq.AI,'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Volumetric interfacial area [m^-^1]')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Phase velocities')
            plot(z,mix.U,'.-')
            plot(z,liq.U,'.-')
            plot(z,vap.U,'.-')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Phase velocity [m/s]')
            legend({'Mixture','Liquid','Gas'},'location','best')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Phase enthalpies')
            plot(z,mix.H,'.-')
            plot(z,liq.H,'.-')
            plot(z,vap.H,'.-')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Phase enthalpies [J/kg]')
            legend({'Mixture Liquid','Liquid','Gas'},'location','best')
            set(gca,'fontSize',14)
            
        %    nexttile; hold all; grid on; title('Phase temperatures')
        %    plot(z,repmat(twfSolver.fluid.TSAT,length(z),1)-273.15,'.-')
        %    plot(z,liq.T-273.15,'.-')
        %    plot(z,vap.T-273.15,'.-')
        %    xlabel('Axial position [m]'); xlim(z([1 end]));
        %    ylabel('Phase temperatures [C]')
        %    legend({'Saturation','Liquid','Gas'},'location','best')
        %    set(gca,'fontSize',14)
            
        %    nexttile; hold all; grid on; title('Liquid mass exchanges')
        %    plot(z,liq.MWALL,'.-','displayName','Wall evaporation')
        %    plot(z,liq.MEVAP(vap),'.-','displayName','Interfacial evaporation')
        %    plot(z,liq.MCOND(vap),'.-','displayName','Interfacial condensation')
        %    plot(z,liq.MTOT(vap),'k--','displayName','Total')
        %    xlabel('Axial position [m]'); xlim(z([1 end]));
        %    ylabel('Mass exchange [kg/s/m]')
        %    legend('show','location','best')
        %    set(gca,'fontSize',14)
        %    
        %    nexttile; hold all; grid on; title('Vapor mass exchanges')
        %    plot(z,vap.MWALL(liq),'.-','displayName','Wall evaporation')
        %    plot(z,vap.MEVAP(liq),'.-','displayName','Interfacial evaporation')
        %    plot(z,vap.MCOND(liq),'.-','displayName','Interfacial condensation')
        %    plot(z,vap.MTOT(liq),'k--','displayName','Total')
        %    xlabel('Axial position [m]'); xlim(z([1 end]));
        %    ylabel('Mass exchange [kg/s/m]')
        %    legend('show','location','best')
        %    set(gca,'fontSize',14)

            nexttile; hold all; grid on; title('Mass exchanges')
            plot(z,liq.MTOT(vap),'.-','displayName','Liquid total mass exchange')
            plot(z,vap.MTOT(liq),'.-','displayName','Vapor total mass exchange')
            plot(z,liq.MTOT(vap)+vap.MTOT(liq),'.-','displayName','Sum of mass exchange')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Mass exchange [kg/s/m]')
            legend('show','location','best')
            set(gca,'fontSize',14)

            nexttile; hold all; grid on; title('Energy exchanges')
            plot(z,liq.HTOT(vap),'.-','displayName','Liquid total energy exchange')
            plot(z,vap.HTOT(liq),'.-','displayName','Vapor total energy exchange')
            plot(z,liq.HTOT(vap)+vap.HTOT(liq),'.-','displayName','Sum of energy exchange')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Energy exchange [W/s/m]')
            legend('show','location','best')
            set(gca,'fontSize',14)

            nexttile; hold all; grid on; title('Evaporation mass exchanges')
            plot(z,liq.MEVAP(vap),'.-','displayName','Liquid total mass exchange')
            plot(z,vap.MEVAP(liq),'.-','displayName','Vapor total mass exchange')
            plot(z,liq.MEVAP(vap)+vap.MEVAP(liq),'.-','displayName','Sum of mass exchange')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Mass exchange [kg/s/m]')
            legend('show','location','best')
            set(gca,'fontSize',14)

            nexttile; hold all; grid on; title('Condensation mass exchanges')
            plot(z,liq.MCOND(vap),'.-','displayName','Liquid total mass exchange')
            plot(z,vap.MCOND(liq),'.-','displayName','Vapor total mass exchange')
            plot(z,liq.MCOND(vap)+vap.MCOND(liq),'.-','displayName','Sum of mass exchange')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Mass exchange [kg/s/m]')
            legend('show','location','best')
            set(gca,'fontSize',14)


            nexttile; hold all; grid on; title('Evaporation energy exchanges')
            plot(z,liq.HEVAP(vap),'.-','displayName','Liquid total energy exchange')
            plot(z,vap.HEVAP(liq),'.-','displayName','Vapor total energy exchange')
            plot(z,liq.HEVAP(vap)+vap.HEVAP(liq),'.-','displayName','Sum of energy exchange')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Energy exchange [W/s/m]')
            legend('show','location','best')
            set(gca,'fontSize',14)

            nexttile; hold all; grid on; title('Condensation energy exchanges')
            plot(z,liq.HCOND(vap),'.-','displayName','Liquid total energy exchange')
            plot(z,vap.HCOND(liq),'.-','displayName','Vapor total energy exchange')
            plot(z,liq.HCOND(vap)+vap.HCOND(liq),'.-','displayName','Sum of energy exchange')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Energy exchange [W/s/m]')
            legend('show','location','best')
            set(gca,'fontSize',14)
            
         %   nexttile; hold all; grid on; title('Liquid energy exchanges')
         %   plot(z,liq.HWHF,'.-','displayName','Wall heat flux')
         %   plot(z,liq.HWALL,'.-','displayName','Wall mass exch')
         %   %plot(z,liq.HEVAP(vap),'.-','displayName','Interfacial evaporation')
         %   plot(z,liq.HCOND(vap),'.-','displayName','Interfacial condensation')
         %   plot(z,liq.HTOT(vap),'k--','displayName','Total')
         %   xlabel('Axial position [m]'); xlim(z([1 end]));
         %   ylabel('Energy exchange [W/m]')
         %   legend('show','location','best')
         %   set(gca,'fontSize',14)
         %   
         %   nexttile; hold all; grid on; title('Vapor energy exchanges')
         %   plot(z,vap.HWHF(liq),'.-','displayName','Wall heat flux')
         %   plot(z,vap.HWALL(liq),'.-','displayName','Wall mass exch')
         %   plot(z,vap.HEVAP(liq),'.-','displayName','Interfacial evaporation')
         %   %plot(z,vap.HCOND(liq),'.-','displayName','Interfacial condensation')
         %   plot(z,vap.HTOT(liq),'k--','displayName','Total')
         %   xlabel('Axial position [m]'); xlim(z([1 end]));
         %   ylabel('Energy Exchange [W/m]')
         %   legend('show','location','best')
         %   set(gca,'fontSize',14)

        end
    
        function plott(twfSolver, zIdx, opt)
            %PLOTT 
            % TODO: Method to be checked
            % 
            arguments
                twfSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    liq = twfSolver.liquid;
                    vap = twfSolver.vapor;
                case 'STEADY'
                    liq = twfSolver.liquidInit;
                    vap = twfSolver.vaporINit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(liq);
            end

            % Cannot plot time series of one time step
            if isscalar(liq) || isscalar(opt.tIdx)
                twfSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
            end

            % Time vector
            plotTimeVector = [liq(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time series of two-fluid parameters at ' num2str(twfSolver.Z(zIdx(1))) ' [m]']);
            
            timeplot('W','Mass flowrates [kg/s]')
            timeplot('U','Velocity [m/s]')
            timeplot('H','Enthalpy [J/kg]')
            
            function timeplot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(liq,param)
                    paramData = arrayfun( ...
                                    @(i) liq(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [liq.(param)];
                end
                
                plot(plotTimeVector, paramData(zIdx,opt.tIdx),'.-');

                legendStr = num2str(twfSolver.Z(zIdx),'z=%0.4f m');
                legend(legendStr,'Location','southeast');
                
                xlabel('Time [s]'); xlim(plotTimeVector([1 end]));
                ylabel(ylabelText)
                set(gca,'fontSize',14)
            
            end

        end

        function plotzt(twfSolver, zIdx, opt)
        %PLOTZT: 2d plot, position z on horizontal and time t on vertical axis
        % TODO: Method to be checked
        % Updated - To be extended later
            arguments
                twfSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end

            
            switch opt.solveMode
                case 'TRANSIENT'
                    liq = twfSolver.liquid;
                    vap = twfSolver.vapor;
                case 'STEADY'
                    liq = twfSolver.liquidInit;
                    vap = twfSolver.vaporINit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(liq);
            end

            % Cannot plot time series of one time step
            if isscalar(liq) || isscalar(opt.tIdx)
                twfSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
            end

            % Time vector
            plotTimeVector = [liq(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time and axial distribution of liquid parameters']);
            
            zt_plot_liquid('W','Mass flowrates [kg/s]')
            zt_plot_liquid('U','Velocity [m/s]')
            zt_plot_liquid('H','Enthalpy [J/kg]')

            function zt_plot_liquid(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(liq,param)
                    paramData = arrayfun( ...
                                    @(i) liq(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [liq.(param)];
                end
                
                [t_mesh,z_mesh] = meshgrid(plotTimeVector,twfSolver.Z);

                surf(z_mesh,t_mesh,paramData);
                shading interp 
                xlabel('Position z [m]') 
                ylabel('Time t [s]') 
                view(2);
                cb = colorbar(); 
                ylabel(cb,ylabelText,'FontSize',12,'Rotation',270)
            
            end

            figure('name',['Time and axial distribution of vapor parameters']);
            
            zt_plot_vapor('W','Mass flowrates [kg/s]')
            zt_plot_vapor('U','Velocity [m/s]')
            zt_plot_vapor('H','Enthalpy [J/kg]')
            
            function zt_plot_vapor(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(vap,param)
                    paramData = arrayfun( ...
                                    @(i) vap(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [vap.(param)];
                end
                
                [t_mesh,z_mesh] = meshgrid(plotTimeVector,twfSolver.Z);

                surf(z_mesh,t_mesh,paramData);
                shading interp 
                xlabel('Position z [m]') 
                ylabel('Time t [s]') 
                view(2);
                cb = colorbar(); 
                ylabel(cb,ylabelText,'FontSize',12,'Rotation',270)
            
            end


        end

        
        function saveResults(twfSolver, opts)
        %SAVERESULTS
        %
        arguments
            twfSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = twfSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', twfSolver.Z, ...
                                'TIME', twfSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', twfSolver.boundaryConditions, ...
                                'liquidInit', struct(twfSolver.liquidInit), ...
                                'vaporInit', struct(twfSolver.vaporInit), ...
                                'liquid', struct(twfSolver.liquid), ...
                                'vapor', struct(twfSolver.vapor));

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

