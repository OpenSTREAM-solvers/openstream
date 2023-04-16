classdef MixtureSolver < Solvers.AbstractSolver
    %MIXTURESOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=private)
        
        NZ           (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of time steps
        TIME         (:,1) double  {mustBeNumeric}                         = 0                    % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time step size
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size

        inputSet    {isa(inputSet,'Inputs.InputSet')}
        fluid       {isa(fluid,'Inputs.FluidProperties')}
        boundaryConditions
        
        mixtureInit
        mixture
        
        STATE                                                              = Solvers.SolverState.UNSOLVED

    end
    
    methods
        solve(mixSolver, opts)
    end

    methods
        function mixSolver = MixtureSolver(inputSet)
            %MIXTURESOLVER Creates a Mixture solver mix
            %   Detailed explanation goes here
            arguments
                inputSet {isa(inputSet,'Inputs.InputSet')}
            end

            % Store inputSet as object property
            mixSolver.inputSet = inputSet;
            
            % Initialize solver parameters
            mixSolver.initializeSolver();

        end
        
        function initializeSolver(mixSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.Mixture.*
            import Solvers.*

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

            % Setup DP and ITR
            % Grav:     [Pa] Gravitational pressure drop
            % Wall:     [Pa] Wall friction pressure drop
            % Acc_z:    [pa] Spatial acceleration pressure drop
            % Acc_t:    [Pa] Temporal acceleration pressure drop
            % K:        [Pa] Local pressure drop
            % Tot:      [Pa] Total pressure drop
            DPFields =  ["Grav","Wall","Acc_z","Acc_t","K","Tot"];          % Fieldnames for DP struct
            DPCell = cell(numel(DPFields),1);                               % Cell structure to convert into struct
            DPCell(:) = {zeros(mixSolver.NZ,1)};                            % Initialize with zeros
            DP = cell2struct(DPCell, DPFields, 1);                          % Convert cell to struct with fieldnames

            % Setup inner iteration value struct
            ITRFields = ["N","DW","DP","DH"];
            ITRCell = cell(numel(ITRFields),1);                             % Cell structure to convert into struct
            ITRCell(:) = {zeros(mixSolver.NZ,1)};                           % Initialize with zeros
            ITR = cell2struct(ITRCell, ITRFields, 1);             % Convert cell to struct with fieldnames


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
                
                % Mass flow ratep [kg/s], pressure [Pa], enthalpy [J/kg]
                mixArr(tIdx).W     = repmat(mixSolver.boundaryConditions.MFLOW(tIdx),mixSolver.NZ,1);
                mixArr(tIdx).P     = repmat(mixSolver.boundaryConditions.PRESSURE(tIdx),mixSolver.NZ,1);
                mixArr(tIdx).H     = repmat(mixSolver.boundaryConditions.HIN(tIdx),mixSolver.NZ,1);
                
                % DP, ITR
                mixArr(tIdx).DP = DP;
                mixArr(tIdx).ITR = ITR;

                % Phases
                mixArr(tIdx).liquid = Liquid(mixArr(tIdx));
                mixArr(tIdx).vapor = Vapor(mixArr(tIdx));
                

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

        function plotz(mixSolver, tIdx)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
        arguments
            mixSolver
            tIdx    (1,1) double
        end
            mix = mixSolver.mixture(tIdx);
            figure('name',['Axial distributions of mixture parameters at ' num2str(mix.TIME) ' [s]'])
                
            nexttile; hold all; grid on;
            plot(mix.Z,mix.W,'.-')
            plot(mix.liquid.Z,mix.liquid.W,'.-')
            plot(mix.vapor.Z,mix.vapor.W,'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Mass flowrates [kg/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
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
            
            nexttile; hold all; grid on;
            plot(mix.Z,mix.XEQ(1:mix.NZ),'.-')
            plot(mix.Z,mix.X(1:mix.NZ),'.-')
            plot(mix.Z,mix.VF(1:mix.NZ),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Quality / Void fraction [-]')
            legend({'Equilibrium quality','Vapor mass quality','Void fraction'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
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
            % TODO: paramData for methods may be a matrix instead of a vector
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
                throw( ...
                    MException( ...
                        'MixtureSolverPlottError:ScalarTimestepError', ...
                        'Non-scalar time index required to plot time series'))
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
            interpOut = interp1(x, ...
                                y, ...
                                mix.Z, ...
                                mix.inputSet.options.AXIALINTERP, ...
                                "extrap");
        end
    end
end

