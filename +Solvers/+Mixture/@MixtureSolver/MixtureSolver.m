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

        DP           (1,1) struct                                                                 % [-] Detailed pressure drops
        ITR          (1,1) struct 

        inputSet    {isa(inputSet,'Inputs.InputSet')}
        boundaryConditions
        mix
        liquid
        vapor
        
        SOLVED      (1,1) logical                                          = true                 % Flag to indicate solved

    end
    
    methods
        solve(mix, opts)
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

            % Calculate time steps
            mixSolver.NZ = mixSolver.inputSet.model.NNODES+1;                           % Total number of axial nodes (add one for inlet conditions)
            mixSolver.DT = mixSolver.inputSet.options.TSTEP;                            % [s] Time interval
            mixSolver.TIME = colon(mixSolver.inputSet.bc(1).TIME, ...
                             mixSolver.DT, ...
                             mixSolver.inputSet.bc(end).TIME);                    % [s] Computational time array
            mixSolver.NTIME = length(mixSolver.TIME);

            % Calculate axial steps
            mixSolver.DZ = mixSolver.inputSet.geometry.LENGTH/mixSolver.inputSet.model.NNODES;    % [m] Uniform node length
            mixSolver.Z = (0:mixSolver.DZ:mixSolver.inputSet.geometry.LENGTH)';                   % [m] Node elevations
            
            % Interpolate BCs in time and space (z)
            mixSolver.interpBoundaryConditions();
            

            mixSolver.mixArray(1:length([mixSolver.TIME])) = Mixture(mixSolver.inputSet);

            for tIdx = 1:length(mixArray)
                mixArray(tIdx).NZ = mixSolver.inputSet.model.NNODES+1;
                mixArray(tIdx).DT = mixSolver.inputSet.options.TSTEP;
%                 mixArray(tIdx).TIME = mix.



            end
            
            % Setup fluid property object
            mixSolver.inputSet.fluid = FluidProperties( ...
                                    mixSolver.boundaryConditions.PRESSURE, ...
                                    mixSolver.inputSet.model);
            % Setup HFLUX heat flux [W/m^2]
            mixSolver.HFLUX = mixSolver.boundaryConditions.HFLUX;
            % Setup W mass flow rate [kg/s]
            mixSolver.W = repmat(mixSolver.boundaryConditions.MFLOW,mixSolver.NZ,1);
            % Setup P, pressure [Pa]
            mixSolver.P = repmat(mixSolver.boundaryConditions.PRESSURE,mixSolver.NZ,1);
            % Setup H enthalpy [J/kg]
            mixSolver.H = repmat(mixSolver.boundaryConditions.HIN,mixSolver.NZ,1);
            
            % Setup DP and ITR
            % Grav:     [Pa] Gravitational pressure drop
            % Wall:     [Pa] Wall friction pressure drop
            % Acc_z:    [pa] Spatial acceleration pressure drop
            % Acc_t:    [Pa] Temporal acceleration pressure drop
            % K:        [Pa] Local pressure drop
            % Tot:      [Pa] Total pressure drop
            DPFields =  ["Grav","Wall","Acc_z","Acc_t","K","Tot"];          % Fieldnames for DP struct
            DPCell = cell(numel(DPFields),1);                               % Cell structure to convert into struct
            DPCell(:) = {zeros(mixSolver.NZ,mixSolver.NTIME)};                          % Initialize with zeros
            mixSolver.DP = cell2struct(DPCell, DPFields, 1);                      % Convert cell to struct with fieldnames
            
            % Setup inner iteration value struct
            ITRFields = ["N","DW","DP","DH"];
            ITRCell = cell(numel(ITRFields),1);                             % Cell structure to convert into struct
            ITRCell(:) = {zeros(mixSolver.NZ,mixSolver.NTIME)};                         % Initialize with zeros
            mixSolver.ITR = cell2struct(ITRCell, ITRFields, 1);                   % Convert cell to struct with fieldnames

            % set SOLVED flag to false
            mixSolver.SOLVED = false;

            % set phases
            mixSolver.liquid = Liquid(mixSolver);
            mixSolver.vapor  = Vapor(mixSolver);

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

        function mflux = MFLUX(mix, zIdx, tIdx)
        %MFLUX Mass flux [kg/m^2-s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end

            mflux = mix.W(zIdx, tIdx)./mix.inputSet.geometry.AREA;
        end

        function xeq = XEQ(mix, zIdx, tIdx)
        %XEQ Equilibrium quality [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
        
            xeq = (mix.H(zIdx, tIdx)-mix.inputSet.fluid.HF(tIdx).') ./ mix.inputSet.fluid.HFG(tIdx).';
        end

        function x = X(mix, zIdx, tIdx)
        %X Vapor quality [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
        
            switch mix.inputSet.model.SCBOIL
                case 'NONE'
                    x=min(max(mix.XEQ(zIdx, tIdx),0),1);
            end
        end

        function vf =VF(mix, zIdx, tIdx)
        %VF Void fraction [-]
        %   
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            model = mix.inputSet.model;
            geom = mix.inputSet.geometry;

            switch model.VOID
                case 'HOMOGENEOUS'
                    % [-] Homogeneous void model
                    vf = vfslip(mix.X(zIdx, tIdx),1);
                case 'SLIP'
                    % [-] Slip void model
                    vf = vfslip(mix.X(zIdx, tIdx),model.SLIP);
                case 'BESTION'
                    % [-] Bestion drift flux model
                    C0 = 1.;                                               % [-] Distribution parameter
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(fluid.RHOF(tIdx)-fluid.RHOG(tIdx))./fluid.RHOG(tIdx)); % [m/s] Drift velocity
                    vf = vfdrift(C0,ugj);            
            end
            
            
            function vf = vfslip(x,S)
            %VFSLIP Void fraction based on slip model
                vf = x.*fluid.RHOF(tIdx).'./(x.*fluid.RHOF(tIdx).'+S.*(1-x).*fluid.RHOG(tIdx).');
            end
            
            function vf = vfdrift(C0,ugj)
            %VFDRIFT Void fraction based on drift flux model
            % C0    [-]     Distribution parameter
            % ugj   [m/s]   Drift velocity
                vf  = mix.JG(zIdx, tIdx)./(C0.*(mix.JG(zIdx, tIdx)+mix.JL(zIdx, tIdx))+ugj);
            end
            
        end

        function rho = RHO(mix, zIdx, tIdx)
        %RHO Density [kg/m^3]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            rho = mix.VF(zIdx, tIdx).*fluid.RHOV(mix.H(zIdx, tIdx), tIdx)+ ...
                    (1-mix.VF(zIdx, tIdx)).*fluid.RHOL(mix.H(zIdx, tIdx), tIdx);
        end

        function mu = MU(mix, zIdx, tIdx)
        %MU Dynamic viscosity [Pa-s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            mu = mix.X(zIdx, tIdx).*fluid.MUV(mix.H(zIdx, tIdx), tIdx) + ...
                    (1-mix.X(zIdx, tIdx)).*fluid.MUL(mix.H(zIdx, tIdx), tIdx);
        end

        function u = U(mix, zIdx, tIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            u = mix.W(zIdx, tIdx)./mix.RHO(zIdx, tIdx)./mix.inputSet.geometry.AREA; 
        end

        function jl = JL(mix, zIdx, tIdx)
        %JL Superfacial liquid velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            jl = (1-mix.X(zIdx, tIdx)).*mix.MFLUX(zIdx, tIdx)./fluid.RHOL(mix.H(zIdx, tIdx), tIdx);
        end

        function jg = JG(mix, zIdx, tIdx)
        %JG Superfacial vapor velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            jg = (1-mix.X(zIdx, tIdx)).*mix.MFLUX(zIdx, tIdx)./fluid.RHOV(mix.H(zIdx, tIdx), tIdx);
        end

        function re = RE(mix, zIdx, tIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            re = 4.*mix.W(zIdx, tIdx)./mix.MU(zIdx, tIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function rel = REL(mix, zIdx, tIdx)
        %REL Liquid-equivalent Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            re = 4.*mix.W(zIdx, tIdx)./mix.MUL(zIdx, tIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function fw = FW(mix, zIdx, tIdx)
        %FW Wall friction factor [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            model = mix.inputSet.model;
            fw = model.FRICTION(1).*mix.RE(zIdx, tIdx).^model.FRICTION(2)+model.FRICTION(3);
        end

        function tauw = TAUW(mix, zIdx, tIdx)
        %TAUW wall shear stress [Pa]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            tauw = 0.5.*(mix.FW(zIdx, tIdx)./4)./mix.RHO(zIdx, tIdx).*(mix.W(zIdx, tIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function kloss = KLOSS(mix, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = 1:mix.NZ; end
            
            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                 % [-] Initialize local loss coefficient array to 0
            [~,ind]=min(abs(mix.Z-model.KLOC));                             % Find local loss elevation indexes (closest node)
            kloss(ind)=model.KLOSS;                                         % [-] Apply loss
            kloss = kloss(zIdx).';                                            % [-] Restrict to selected nodes
            
        end

        function dpk = DPK(mix, zIdx, tIdx)
        %DPK Local pressure loss [Pa]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            dpk = 0.5.*mix.KLOSS(zIdx)./mix.RHO(zIdx, tIdx).*(mix.W(zIdx, tIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function t = T(mix, zIdx, tIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            t = mix.inputSet.fluid.T(mix.H(zIdx, tIdx), tIdx);
        end
        
        function plotz(mix, tIdx)
        %PLOTZ
        %
        arguments
            mix
            tIdx (1,1) double
        end
            figure('name',['Axial distributions of mixture parameters at ' num2str(mix.TIME(tIdx)) ' [s]'])
                
            nexttile; hold all; grid on;
            plot(mix.Z,mix.W(:, tIdx),'.-')
            plot(mix.liquid.Z,mix.liquid.W(:, tIdx),'.-')
            plot(mix.vapor.Z,mix.vapor.W(:, tIdx),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Mass flowrates [kg/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(mix.Z,cumsum(mix.DP.Tot(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Grav(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Wall(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_z(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_t(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.K(:,tIdx)),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Pressure drop [Pa]')
            legend({'Total','Gravitational','Wall','Acc z','Acc t','Local'},'location','northWest');
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(mix.Z,mix.XEQ(1:mix.NZ,tIdx),'.-')
            plot(mix.Z,mix.X(1:mix.NZ,tIdx),'.-')
            plot(mix.Z,mix.VF(1:mix.NZ,tIdx),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Quality / Void fraction [-]')
            legend({'Equilibrium quality','Vapor mass quality','Void fraction'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(mix.Z,mix.U(1:mix.NZ,tIdx),'.-')
            plot(mix.liquid.Z,mix.liquid.U(1:mix.NZ,tIdx),'.-')
            plot(mix.vapor.Z,mix.vapor.U(1:mix.NZ,tIdx),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Velocities [m/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)

        end
    
        function plott(mix, zIdx)
            %PLOTT 
            %
            arguments
                mix
                zIdx (:,1) double
            end

            figure('name',['Time series of mixture parameters at ' num2str(mix.Z(zIdx(1))) ' [m]']);
            
            timeplot('W','Mass flowrates [kg/s]')
            timeplot('P','Pressure [Pa]')
            timeplot('XEQ','Equilibrium quality [-]')
            timeplot('X','Steam mass quality [-]')
            timeplot('VF','Void fraction [-]')
            timeplot('U','Velocity [m/s]')

            function timeplot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(mix,param)
                    plot(mix.TIME,mix.(param)(zIdx),'.-');
                else
                    plot(mix.TIME,mix.(param)(zIdx,:),'.-');
                end
                legendStr = num2str(mix.Z(zIdx),'z=%0.4f m');
                legend(legendStr,'Location','southeast');
                
                xlabel('Time [s]'); xlim([mix.TIME([1 end])]);
                ylabel(ylabelText)
                set(gca,'fontSize',14)
            
            end

        end
        
        function interpOut = timeInterpolate(mix, y)
            interpOut = interp1([mix.inputSet.bc.TIME].', ...
                                y, ...
                                mix.TIME, ...
                                mix.inputSet.options.TIMEINTERP);
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

