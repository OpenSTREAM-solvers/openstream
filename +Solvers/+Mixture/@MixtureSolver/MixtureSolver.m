classdef MixtureSolver < Solvers.AbstractSolver
    %MIXTURESOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=private)
        
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

     end

     properties (SetAccess = protected)
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(mixSolver)
    end

    methods
        function mixSolver = MixtureSolver(inputSet)
            %MIXTURESOLVER Creates a Mixture solver
            %   Detailed explanation goes here
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
            end

            % Call abstract class constructor
            mixSolver = mixSolver@Solvers.AbstractSolver(inputSet);
            
            % Initialize solver parameters
            mixSolver.initializeSolver();

        end
        
        function initializeSolver(mixSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.Mixture.*
            import Solvers.*
            
            NWALL = mixSolver.inputSet.geometry.NWALL;

            % Calculate time steps
            mixSolver.DT = mixSolver.inputSet.options.TSTEP;                            % [s] Time interval
            mixSolver.TIME = colon(mixSolver.inputSet.bc(1).TIME, ...
                             mixSolver.DT, ...
                             mixSolver.inputSet.bc(end).TIME);                    % [s] Computational time array
            mixSolver.NTIME = length(mixSolver.TIME);

            % Calculate axial steps
            mixSolver.DZ = mixSolver.inputSet.geometry.LENGTH/mixSolver.inputSet.model.NNODES;    % [m] Uniform node length
            mixSolver.Z = (0:mixSolver.DZ:mixSolver.inputSet.geometry.LENGTH)';                   % [m] Node elevations
            mixSolver.NZ = length(mixSolver.Z);                                                   % Total number of axial nodes (add one for inlet conditions)
            
            % Interpolate BCs in time and space (z)
            mixSolver.interpBoundaryConditions();
            
            %
            % Create mixture array (by timestep)

            % Setup DP structure
            % Grav:     [Pa] Gravitational pressure drop
            % Wall:     [Pa] Wall friction pressure drop
            % Acc_z:    [pa] Spatial acceleration pressure drop
            % Acc_t:    [Pa] Temporal acceleration pressure drop
            % K:        [Pa] Local pressure drop
            % Tot:      [Pa] Total pressure drop
            DPFields =  ["Grav","Wall","Acc_z","Acc_t","K","Tot"];         % Fieldnames for DP struct
            DPCell = cell(numel(DPFields),1);                              % Cell structure to convert into struct
            DPCell(:) = {zeros(mixSolver.NZ,1)};                           % Initialize with zeros
            DP = cell2struct(DPCell, DPFields, 1);                         % Convert cell to struct with fieldnames

            % Setup ACC structure
            % U_z:    [m/s^2] Spatial  hydrodynamic acceleration
            % U_t:    [m/s^2] Temporal hydrodynamic acceleration
            % U  :    [m/s^2] Total    hydrodynamic acceleration
            % H_z:    [m/s^2] Spatial  thermal acceleration
            % H_t:    [m/s^2] Temporal thermal acceleration
            % H  :    [m/s^2] Total    thermal acceleration
            ACCFields =  ["U_z","U_t","U","H_z","H_t","H"];                % Fieldnames for ACC struct
            ACCCell = cell(numel(ACCFields),1);                            % Cell structure to convert into struct
            ACCCell(:) = {zeros(mixSolver.NZ,1)};                          % Initialize with zeros
            ACC = cell2struct(ACCCell, ACCFields, 1);                      % Convert cell to struct with fieldnames
            
            % Setup TRELAX structure
            % WV  :  [kg/s] Vapor mass flow rate
            % WVTH:  [J/kg] Thermodynamic vapor mass flow rate
            % X   :  [-] Vapor mass quality
            % XTH :  [-] Thermodynamic mass quality
            TRELAXFields =  ["TIME","WV","WVTH","X","XTH"];                % Fieldnames for TRELAX struct
            TRELAXCell = cell(numel(TRELAXFields),1);                      % Cell structure to convert into struct
            TRELAXCell(:) = {zeros(mixSolver.NZ,mixSolver.inputSet.geometry.NWALL)}; % Initialize with zeros
            TRELAX = cell2struct(TRELAXCell, TRELAXFields, 1);             % Convert cell to struct with fieldnames
            
            % Setup inner iteration value struct
            ITRFields = ["N","DW","DP","DH"];
            ITR = mixSolver.CreateITR(mixSolver.NZ, ITRFields);

            % Setup fluid property object
            mixSolver.fluid = FluidProperties( ...
                                    mixSolver.boundaryConditions.PRESSURE, ...
                                    mixSolver.inputSet.model);

            mixArr = Mixture.empty(0,mixSolver.NTIME);
            for tIdx = 1:mixSolver.NTIME
                
                % Inputset
                mixArr(tIdx).inputSet = mixSolver.inputSet;
                mixArr(tIdx).fluid = mixSolver.fluid(tIdx);
                
                % Axial Steps
                mixArr(tIdx).NZ = mixSolver.NZ;
                mixArr(tIdx).DZ = mixSolver.DZ;
                mixArr(tIdx).Z = mixSolver.Z;
                
                % Time step
                mixArr(tIdx).NTIME = mixSolver.NTIME;
                mixArr(tIdx).DT = mixSolver.DT;
                mixArr(tIdx).TIME = mixSolver.TIME(tIdx);
                mixArr(tIdx).TIDX = tIdx;

                % Wall heat flux
                mixArr(tIdx).HFLUX = ...
                    reshape( ...
                        mixSolver.boundaryConditions.HFLUX(:,:,tIdx), ...
                        mixSolver.NZ,...
                        [] ...
                        );
                
                % DP, ACC, TRELAX, ITR
                mixArr(tIdx).DP  = DP;
                mixArr(tIdx).ACC = ACC;
                mixArr(tIdx).TRELAX  = TRELAX;
                mixArr(tIdx).ITR = ITR;
                
                % Phases
                mixArr(tIdx).liquid = Liquid(mixArr(tIdx));
                mixArr(tIdx).vapor  = Vapor(mixArr(tIdx));
                
                % Mass flow rate [kg/s], pressure [Pa], enthalpy [J/kg]
                mixArr(tIdx).W = repmat(mixSolver.boundaryConditions.MFLOW(tIdx),mixSolver.NZ,1);
                mixArr(tIdx).P = repmat(mixSolver.boundaryConditions.PRESSURE(tIdx),mixSolver.NZ,1);
                mixArr(tIdx).H = repmat(mixSolver.boundaryConditions.HIN(tIdx),mixSolver.NZ,1);
                
                % Initialize TRELAX after H to get correct XEQ
                mixArr(tIdx).TRELAX.WV   = max(0,mixArr(tIdx).XEQ).*mixArr(tIdx).WWALL;
                mixArr(tIdx).TRELAX.WVTH = mixArr(tIdx).XEQ.*mixArr(tIdx).WNEARWALL;
                mixArr(tIdx).TRELAX.X    = repmat(max(0,mixArr(tIdx).XEQ),1,NWALL);
                mixArr(tIdx).TRELAX.XTH  = repmat(mixArr(tIdx).XEQ,1,NWALL);

            end

            % Store transient mixture array
            mixSolver.mixture = mixArr;

            % Create steady state mixture array
            mixSolver.mixtureInit = copy( ...
                repmat(mixArr(1),1,mixSolver.inputSet.options.SSMAXITER));

            % Update mixtureInit times and timesteps
            initTIMEDT = mixSolver.inputSet.options.SSTSTEP;
            initNTIME = length(mixSolver.mixtureInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(mixSolver.mixtureInit);

            for i = 1:length(mixSolver.mixtureInit)
                mixSolver.mixtureInit(i).TIME = initTIME(i);
                mixSolver.mixtureInit(i).DT = initTIMEDT;
                mixSolver.mixtureInit(i).NTIME = initNTIME;
                mixSolver.mixtureInit(i).TIDX = initTIDX(i);
            end

            % set STATE to UNSOLVED
            mixSolver.STATE = SolverState.UNSOLVED;

        end

        function mixSolver = interpBoundaryConditions(mixSolver)
            %INTERPBOUNDARYCONDITIONS Expand specified boundary conditions
            %to every node and timestep defined by the model and geometry.
            %   Detailed explanation goes here
            
            % Retrieve list of boundary condition properties
            bcFields = mixSolver.inputSet.bc.listInputProperties();

            % Interpolate bc properties in time
            params = checkParams({'TIME','PRESSURE','HIN','MFLOW','POWER'});
            mixSolver.boundaryConditions = cell2struct( ...
                                        arrayfun( ...
                                            @(idx) mixSolver.timeInterpolate([mixSolver.inputSet.bc.(params(idx))]), ...
                                            1:length(params), ...
                                            'UniformOutput',false),...
                                        params,...
                                        2);

            % Interpolate wall power in space
            WPOWERZ = arrayfun( ...
                        @(bc)mixSolver.axialInterpolate( ...
                                        cumsum(bc.WMESH), ...
                                        bc.WPOWER ...
                                        ), ...
                        mixSolver.inputSet.bc, ...
                        'UniformOutput',false ...
                        );
            % Combine WPOWERZ to NZ x NWALL x N_bc
            WPOWERZ = reshape( ...
                            cell2mat(WPOWERZ), ...
                            mixSolver.NZ, ...
                            mixSolver.inputSet.geometry.NWALL, ...
                            []);
            
            % Interpolate wall power in time
            WPOWERT = arrayfun( ...
                        @(wallIdx) mixSolver.timeInterpolate( ...
                                    reshape(WPOWERZ(:,wallIdx,:), ...
                                        mixSolver.NZ, ...
                                        [] ...
                                   ).').', ...
                                   1:mixSolver.inputSet.geometry.NWALL, ...
                                   'UniformOutput',false);
            % Reorganize WPOWERT to NZ x NWall x NTIME
            WPOWERT = permute( ...
                        reshape( ...
                            cell2mat(WPOWERT), ...
                            mixSolver.NZ, ...
                            mixSolver.NTIME, ...
                            [] ...
                        ), [1 3 2]);
            
            mixSolver.boundaryConditions.WPOWER = WPOWERT;
            
            
            % Calculate wall heat flux at each node in space & time
            % NOTE: This is very convoluted
            mixSolver.boundaryConditions.HFLUX = ...
                mixSolver.boundaryConditions.WPOWER .* reshape(mixSolver.boundaryConditions.POWER,1,1,[]) ...
                ./ sum(reshape( ...
                        mixSolver.inputSet.geometry.PERIM .* mixSolver.DZ,1,mixSolver.inputSet.geometry.NWALL,1 ...
                        ).* ...
                       mixSolver.boundaryConditions.WPOWER,[1,2] ...
                      );

            function validParams = checkParams(params)
            %CHECKPARAMS Ensure interpolation parameters are valid
            %parameters of the boundaryCondition mix.
                
                validParams = string().empty();
                for idx = 1:length(params)
                    if find(bcFields==params(idx))
                        validParams(end+1) = params(idx);
                    else
                        throw( ...
                            MException( ...
                                'MixtureError:InvalidInterpolationParameter', ...
                                'Parameter %s is not a valid boundary condition parameter', ...
                                params{idx} ...
                                ) ...
                        );
                    end
                end

            end

        end

        function plotter = plotz(mixSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeStep
            arguments
                mixSolver
                tIdx     (1,1) double
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.wall (1,:) double = 1:mixSolver.inputSet.geometry.NWALL()
            end
            
            bc  = mixSolver.boundaryConditions;
            z   = mixSolver.Z;
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture(tIdx);
                    bcHFLUX = bc.HFLUX(:,:,tIdx);
                case 'STEADY'
                    mix = mixSolver.mixtureInit(tIdx);
                    bcHFLUX = bc.HFLUX(:,:,1);
            end

            oafZ = repmat(mix.OAFZ,1,2);

            plotter = Solvers.SolverPlotter( ...
                                sprintf('Axial distributions of mixture parameters at %0.3f [s] - %s', mix.TIME, opt.solveMode), ...
                                opt.wall);
            plotter.setZs(z);
            
            % Wall heat flux
            plotter.newTile( ...
                "tileTitle", 'Wall heat flux', ...
                'xlabel', 'Axial position [m]', ...
                'ylabel', 'Wall heat flux [W/m^2]');
            plotter.plotz(bcHFLUX, 'BC', 'DisplayName', 'Boundary Condition');
            plotter.plotz(mix.HFLUX, 'MIX', 'DisplayName', 'Mixture');
            plotter.plotz(mix.CHF, 'Liquid', 'DisplayName', 'CHF');
            plotter.legend("show", 'Location', 'best');
            plotter.plotOAF(oafZ);

            % Mass flow rates
            plotter.newTile( ...
                "tileTitle", "Mass flow rates", ...
                "xlabel","Axial position [m]", ...
                "ylabel","Mass flow rate [kg/s]");
            
            plotter.plotz(mix.W,"Mixture","DisplayName","Mixture");
            plotter.plotz(mix.liquid.W,"Liquid","DisplayName","Liquid");
            plotter.plotz(mix.vapor.W,"Vapor","DisplayName","Vapor");
            plotter.legend("show", "Location", 'best');
            plotter.plotOAF(oafZ);

            % Pressure drops
             plotter.newTile( ...
                "tileTitle", "Pressure drops", ...
                "xlabel","Axial position [m]", ...
                "ylabel","Pressure drop [Pa]");
            plotter.plotz(cumsum(mix.DP.Tot),'Total') 
            plotter.plotz(cumsum(mix.DP.Grav),'Gravitational')
            plotter.plotz(cumsum(mix.DP.Wall),'Wall')
            plotter.plotz(cumsum(mix.DP.Acc_z),'Z','DisplayName','Acc Z')
            plotter.plotz(cumsum(mix.DP.Acc_t),'T','DisplayName','Acc t')
            plotter.plotz(cumsum(mix.DP.K),'Local')
            plotter.legend("show", "Location", 'best');
            plotter.plotOAF(oafZ);
            
            % Enthalpies
            plotter.newTile( ...
                "tileTitle", "Enthalpies", ...
                "xlabel","Axial position [m]", ...
                "ylabel","Enthalpy [J/kg]");
            
            plotter.plotz(mix.H,"Mixture","DisplayName","Mixture");
            plotter.plotz(mix.liquid.H,"Liquid","DisplayName","Liquid");
            plotter.plotz(mix.vapor.H,"Vapor","DisplayName","Vapor");
            plotter.legend("show", "Location", 'best');
            plotter.plotOAF(oafZ);
            
            % Velocities
            plotter.newTile( ...
                "tileTitle", "Field velocities", ...
                "xlabel","Axial position [m]", ...
                "ylabel","Velocity [m/s]");
            plotter.plotz(mix.U,'Mixture')  
            plotter.plotz(mix.liquid.U,'Liquid')
            plotter.plotz(mix.vapor.U,'Vapor')
            plotter.legend("show", "Location", 'best');
            plotter.plotOAF(oafZ);
            
            % Void fraction and qualities
            plotter.newTile( ...
                "tileTitle", "Void fractions and qualities", ...
                "xlabel","Axial position [m]", ...
                "ylabel","Quality / Void fraction [-]");
            plotter.plotz(mix.XEQ,'Equil','DisplayName','Equilibrium quality')  
            plotter.plotz(mix.X,'Vapor','DisplayName','Vapor mass quality')
            plotter.plotz(mix.VF,'VF','DisplayName','Void faction')
            plotter.legend("show", "Location", 'best');
            plotter.plotOAF(oafZ);
            
            % Temperatures
            plotter.newTile( ...
                "tileTitle", "Temperature", ...
                "xlabel","Axial position [m]", ...
                "ylabel","Temperature [K]");
            
            plotter.plotz(mix.T,"Mixture","DisplayName","Mixture");
            plotter.plotz(mix.liquid.T,"Liquid","DisplayName","Liquid");
            plotter.plotz(mix.vapor.T,"Vapor","DisplayName","Vapor");
            plotter.legend("show", "Location", 'best');
            plotter.plotOAF(oafZ);
            
            % Qualities and relaxed qualities
            plotter.newTile( ...
                "tileTitle", "Qualities and relaxed qualities", ...
                "xlabel","Axial position [m]", ...
                "ylabel","Quality [-]");
            plotter.plotz(mix.XEQ,'Equil','DisplayName','Equilibrium thermo. quality')  
            plotter.plotz(mix.X,'Vapor','DisplayName','Vapor mass quality')
            plotter.plotz(mix.TRELAX.XTH,'RelaxEquil','DisplayName','Relaxed thermo. X')
            plotter.plotz(mix.TRELAX.X,'RelaxVapor','DisplayName','Relaxed vapor X')
            plotter.legend("show", "Location", 'best');
            plotter.plotOAF(oafZ);

        end
        
        function plotter = plott(mixSolver, zIdx, opt)
        %PLOTT
        %   NOTE: currently supports only single elevation
            arguments
                mixSolver
                zIdx     (1,1) double
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.wall (1,:) double = 1:mixSolver.inputSet.geometry.NWALL()
            end
            
            bc    = mixSolver.boundaryConditions;
            z     = mixSolver.Z;
            time  = mixSolver.TIME;
            NWALL = mixSolver.inputSet.geometry.NWALL();
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture();
                    bcHFLUX = reshape(bc.HFLUX(zIdx,:,:),NWALL,[])';
                case 'STEADY'
                    mix = mixSolver.mixtureInit();
                    bcHFLUX = repmat(bc.HFLUX(zIdx,:,1),mixSolver.NTIME,1);
            end

            plotter = Solvers.SolverPlotter( ...
                                sprintf('Time distributions of mixture parameters at %0.3f [m] - %s', z(zIdx), opt.solveMode), ...
                                opt.wall);
            plotter.setZs(time);
            
            % Wall heat flux
            plotter.newTile( ...
                "tileTitle", 'Wall heat flux', ...
                'xlabel', 'Time [s]', ...
                'ylabel', 'Wall heat flux [W/m^2]');
            plotter.plotz(bcHFLUX, 'BC', 'DisplayName', 'Boundary Condition');
            plotter.plotz(cell2mat(arrayfun(@(x) x.HFLUX(zIdx,:)',mix,'uni',0))', 'MIX', 'DisplayName', 'Mixture');
            plotter.legend("show", 'Location', 'best');

            % Mass flow rates
            plotter.newTile( ...
                "tileTitle", "Mass flow rates", ...
                "xlabel","Time [s]", ...
                "ylabel","Mass flow rate [kg/s]");
            plotter.plotz(arrayfun(@(x) x.W(zIdx),mix),"Mixture","DisplayName","Mixture");
            plotter.plotz(arrayfun(@(x) x.liquid.W(zIdx),mix),"Liquid","DisplayName","Liquid");
            plotter.plotz(arrayfun(@(x) x.vapor.W(zIdx),mix),"Vapor","DisplayName","Vapor");
            plotter.legend("show", "Location", 'best');

            % Pressure drops
             plotter.newTile( ...
                "tileTitle", "Pressure drops", ...
                "xlabel","Time [s]", ...
                "ylabel","Pressure drop [Pa]");
            plotter.plotz(arrayfun(@(x) sum(x.DP.Tot(1:zIdx)),mix),'Total') 
            plotter.plotz(arrayfun(@(x) sum(x.DP.Grav(1:zIdx)),mix),'Gravitational')
            plotter.plotz(arrayfun(@(x) sum(x.DP.Wall(1:zIdx)),mix),'Wall')
            plotter.plotz(arrayfun(@(x) sum(x.DP.Acc_z(1:zIdx)),mix),'Z','DisplayName','Acc Z')
            plotter.plotz(arrayfun(@(x) sum(x.DP.Acc_t(1:zIdx)),mix),'T','DisplayName','Acc t')
            plotter.plotz(arrayfun(@(x) sum(x.DP.K(1:zIdx)),mix),'Local')
            plotter.legend("show", "Location", 'best');
            
            % Enthalpies
            plotter.newTile( ...
                "tileTitle", "Enthalpies", ...
                "xlabel","Time [s]", ...
                "ylabel","Enthalpy [J/kg]");
            plotter.plotz(arrayfun(@(x) x.H(zIdx),mix),'Mixture')  
            plotter.plotz(arrayfun(@(x) x.liquid.H(zIdx),mix),'Liquid')
            plotter.plotz(arrayfun(@(x) x.vapor.H(zIdx),mix),'Vapor')
            plotter.legend("show", "Location", 'best');
            
            % Velocities
            plotter.newTile( ...
                "tileTitle", "Field velocities", ...
                "xlabel","Time [s]", ...
                "ylabel","Velocity [m/s]");
            plotter.plotz(arrayfun(@(x) x.U(zIdx),mix),'Mixture')  
            plotter.plotz(arrayfun(@(x) x.liquid.U(zIdx),mix),'Liquid')
            plotter.plotz(arrayfun(@(x) x.vapor.U(zIdx),mix),'Vapor')
            plotter.legend("show", "Location", 'best');
            
            % Void fraction and qualities
            plotter.newTile( ...
                "tileTitle", "Void fraction and qualities", ...
                "xlabel","Time [s]", ...
                "ylabel","Quality / Void fraction [-]");
            plotter.plotz(arrayfun(@(x) x.XEQ(zIdx),mix),'Equil','DisplayName','Equilibrium quality')  
            plotter.plotz(arrayfun(@(x) x.X(zIdx),mix),'Vapor','DisplayName','Vapor mass quality')
            plotter.plotz(arrayfun(@(x) x.VF(zIdx),mix),'VF','DisplayName','Void faction')
            plotter.legend("show", "Location", 'best');
            
            % Temperatures
            plotter.newTile( ...
                "tileTitle", "Temperatures", ...
                "xlabel","Time [s]", ...
                "ylabel","Temperature [K]");
            plotter.plotz(arrayfun(@(x) x.T(zIdx),mix),'Mixture')  
            plotter.plotz(arrayfun(@(x) x.liquid.T(zIdx),mix),'Liquid')
            plotter.plotz(arrayfun(@(x) x.vapor.T(zIdx),mix),'Vapor')
            plotter.legend("show", "Location", 'best');
            
            % Qualities and relaxed qualities
            plotter.newTile( ...
                "tileTitle", "Qualities and relaxed qualities", ...
                "xlabel","Time [s]", ...
                "ylabel","Quality / Void fraction [-]");
            plotter.plotz(arrayfun(@(x) x.XEQ(zIdx),mix),'Equil','DisplayName','Equilibrium thermo. quality')  
            plotter.plotz(arrayfun(@(x) x.X(zIdx),mix),'Vapor','DisplayName','Vapor mass quality')
            plotter.plotz(arrayfun(@(x) x.TRELAX.XTH(zIdx),mix),'RelaxEquil','DisplayName','Relaxed thermo. X')  
            plotter.plotz(arrayfun(@(x) x.TRELAX.X(zIdx),mix),'RelaxVapor','DisplayName','Relaxed vapor X')
            plotter.legend("show", "Location", 'best');
            
        end

        function fh = plotzt(mixSolver, opt)
            %PLOTZT
            % 2d plot, position z on horizontal and time t on vertical axis
            arguments
                mixSolver
                opt.tIdx (:,1) double = 1:mixSolver.NTIME
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.wall (1,:) double = 1:mixSolver.inputSet.geometry.NWALL()
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture;
                case 'STEADY'
                    mix = mixSolver.mixtureInit;
            end

            % Cannot plot time series of one time step
            if isscalar(mix) || isscalar(opt.tIdx)
                mixSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
            end
            
            for k = opt.wall
                
                fh = figure('name',['Time/axial distributions of mixture parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                
                zt_plot('HFLUX','Wall heat flux','W/m^2',k)
                zt_plot('W','Mass flow rate','kg/s',1)
                zt_plot('DP.Tot','Pressure drop','Pa',1)
                zt_plot('XEQ','Equilibrium quality','-',1)
                zt_plot('X','Steam mass quality','-',1)
                zt_plot('VF','Void fraction','-',1)
                zt_plot('U','Velocity','m/s',1)
                zt_plot('vapor.T','Vapor temperature','K',1)
                
            end

            function zt_plot(param,ylabelText,ylabelUnit,k)
                
                NWALL = mixSolver.inputSet.geometry.NWALL();
                plotTimeVector = [mix(opt.tIdx).TIME];
                
                nexttile; hold all; grid on; title(ylabelText)
                
                s = split(param,'.');
                if length(s) < 2
                    mixfield = mix;
                else
                    mixfield = [mix.(s{1})];
                    param = s{2};
                end
                
                if ismember(s{1},'DP')
                    paramData = cell2mat(arrayfun(@(x) cumsum(x.(param)),mixfield(opt.tIdx),'uni',0));
                else
                    paramData = cell2mat(arrayfun(@(x) x.(param),mixfield(opt.tIdx),'uni',0));
                end
                if size(mixfield(1).(param),2) > 1
                    paramData = paramData(:,k:NWALL:end);
                end
                [t_mesh,z_mesh] = meshgrid(plotTimeVector,mixSolver.Z);
                surf(z_mesh,t_mesh,paramData,'edgeColor','none');
                shading interp 
                xlabel('Axial position [m]') 
                ylabel('Time [s]') 
                cb = colorbar(); cb.Label.String = [ylabelText ' [' ylabelUnit ']']; cb.Label.FontSize = 14;
                set(gca,'fontSize',14)
                view(2);
                
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

        function interpOut = timeInterpolate(mix, y)
            if isscalar([mix.inputSet.bc.TIME])
                interpOut = y;
            else
                interpOut = interp1([mix.inputSet.bc.TIME].', ...
                                    y, ...
                                    mix.TIME, ...
                                    mix.inputSet.options.TIMEINTERP);
            end
        end

        function interpOut = axialInterpolate(mix, x, y)
        %AXIALINTERPOLATE
        % Linear extrapolation is used for cases where interpolation returns NaN (for instance, point slightly outside allowed tolerance when 'next' interpolation methos is selected)
            interpOut = interp1(x, ...
                                y, ...
                                mix.Z, ...
                                mix.inputSet.options.AXIALINTERP, ...
                                "extrap");
            interpOut(isnan(interpOut)) = interp1(x, ...
                                y, ...
                                mix.Z(isnan(interpOut)), ...
                                'linear', ...
                                "extrap");               
        end
    end
end

