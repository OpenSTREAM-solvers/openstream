classdef Mixture < Solvers.AbstractSolver
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=private)
        
        NZ           (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of time steps
        TIME         (:,1) double  {mustBeNumeric}                         = 0                    % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time step size
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        HFLUX        (:,:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
     end

    properties
        W            (:,:) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        P            (:,:) double  {mustBeNumeric}                         = 7E6                  % [Pa] Pressure
        H            (:,:) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % [-] Detailed pressure drops
        ITR          (1,1) struct 

        inputSet    {isa(inputSet,'Inputs.InputSet')}
        boundaryConditions
    end
    
    methods
        solve(obj, opts)
    end

    methods
        function obj = Mixture(inputSet)
            %MIXTURE Creates a Mixture solver obj
            %   Detailed explanation goes here
            arguments
                inputSet {isa(inputSet,'Inputs.InputSet')}
            end

            import Inputs.*

            % Store inputSet as object property
            obj.inputSet = inputSet;
            
            % Calculate time steps
            obj.NZ = obj.inputSet.model.NNODES+1;                           % Total number of axial nodes (add one for inlet conditions)
            obj.DT = obj.inputSet.options.TSTEP;                            % [s] Time interval
            obj.TIME = colon(obj.inputSet.bc.TIME(1), ...
                             obj.DT, ...
                             obj.inputSet.bc.TIME(end));                    % [s] Computational time array
            obj.NTIME = length(obj.TIME);

            % Calculate axial steps
            obj.DZ = obj.inputSet.geometry.LENGTH/obj.inputSet.model.NNODES;    % [m] Uniform node length
            obj.Z = (0:obj.DZ:obj.inputSet.geometry.LENGTH)';                   % [m] Node elevations

            % Interpolate BCs in time and space (z)
            obj.interpBoundaryConditions();

            % Setup fluid property object
            obj.inputSet.fluid = FluidProperties( ...
                                    obj.boundaryConditions.PRESSURE, ...
                                    obj.inputSet.model);
            % Setup HFLUX heat flux [W/m^2]
            obj.HFLUX = obj.boundaryConditions.HFLUX;
            % Setup W mass flow rate [kg/s]
            obj.W = repmat(obj.boundaryConditions.MFLOW,1,obj.NZ);
            % Setup P, pressure [Pa]
            obj.P = repmat(obj.boundaryConditions.PRESSURE,1,obj.NZ);
            % Setup H enthalpy [J/kg]
            obj.H = repmat(obj.boundaryConditions.HIN,1,obj.NZ);
            
            % Setup DP and ITR
            % Grav:     [Pa] Gravitational pressure drop
            % Wall:     [Pa] Wall friction pressure drop
            % Acc_z:    [pa] Spatial acceleration pressure drop
            % Acc_t:    [Pa] Temporal acceleration pressure drop
            % K:        [Pa] Local pressure drop
            % Tot:      [Pa] Total pressure drop
            DPFields =  ["Grav","Wall","Acc_z","Acc_t","K","Tot"];          % Fieldnames for DP struct
            DPCell = cell(numel(DPFields),1);                               % Cell structure to convert into struct
            DPCell(:) = {zeros(obj.NTIME,obj.NZ)};                          % Initialize with zeros
            obj.DP = cell2struct(DPCell, DPFields, 1);                      % Convert cell to struct with fieldnames
            
            % Setup inner iteration value struct
            ITRFields = ["N","DW","DP","DH"];
            ITRCell = cell(numel(ITRFields),1);                             % Cell structure to convert into struct
            ITRCell(:) = {zeros(obj.NTIME,obj.NZ)};                         % Initialize with zeros
            obj.ITR = cell2struct(ITRCell, ITRFields, 1);                   % Convert cell to struct with fieldnames
            
        end
        
        function obj = interpBoundaryConditions(obj)
            %INTERPBOUNDARYCONDITIONS Expand specified boundary conditions
            %to every node and timestep defined by the model and geometry.
            %   Detailed explanation goes here
            
            % Retrieve list of boundary condition properties
            bcFields = obj.inputSet.bc.listInputProperties();

            % Interpolate bc properties in time
            params = checkParams({'TIME','PRESSURE','HIN','MFLOW','POWER'});
            obj.boundaryConditions = cell2struct( ...
                                        arrayfun( ...
                                            @(idx) obj.timeInterpolate(obj.inputSet.bc.(params(idx))), ...
                                            1:length(params), ...
                                            'UniformOutput',false),...
                                        params,...
                                        2);

            % Interpolate wall power in time
            WPOWERT = obj.timeInterpolate(obj.inputSet.bc.WPOWER);
            obj.boundaryConditions.WPOWER = zeros(obj.NTIME,obj.NZ,obj.inputSet.geometry.NWALL);
            
            % Interpolate wall power in axial space 
            %   Index order: (NTIME, NZ, NWALL)
            % NOTE: only the 1st row of WMESH is used
            obj.boundaryConditions.WPOWER = ...
                pagetranspose( ...
                    obj.axialInterpolate(cumsum(obj.inputSet.bc.WMESH(1,:).'), ...
                                     pagetranspose(WPOWERT)...
                                     ) ...
                );

            % Calculate wall heat flux at each node in space & time
            % NOTE: This is very covoluted
            obj.boundaryConditions.HFLUX = ...
                obj.boundaryConditions.WPOWER .* obj.boundaryConditions.POWER ...
                ./ sum(reshape(obj.inputSet.geometry.PERIM .* obj.DZ,1,1,3).*obj.boundaryConditions.WPOWER,[2,3]);

            function validParams = checkParams(params)
            %CHECKPARAMS Ensure interpolation parameters are valid
            %parameters of the boundaryCondition obj.
                
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

        function mflux = MFLUX(obj, tIdx, zIdx)
        %MFLUX Mass flux [kg/m^2-s]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end

            mflux = obj.W(tIdx,zIdx)./obj.inputSet.geometry.AREA;
        end

        function xeq = XEQ(obj, tIdx, zIdx)
        %XEQ Equilibrium quality [-]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
        
            xeq = (obj.H(tIdx,zIdx)-obj.inputSet.fluid.HF(tIdx)) ./ obj.inputSet.fluid.HFG(tIdx);
        end

        function x = X(obj, tIdx, zIdx)
        %XEQ Vapor quality [-]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
        
            switch obj.inputSet.model.SCBOIL
                case 'NONE'
                    x=min(max(obj.XEQ(tIdx,zIdx),0),1);
            end
        end

        function vf =VF(obj, tIdx, zIdx)
        %VF Void fraction [-]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            fluid = obj.inputSet.fluid;
            model = obj.inputSet.model;
            geom = obj.inputSet.geometry;

            switch model.VOID
                case 'HOMOGENEOUS'
                    % [-] Homogeneous void model
                    vf = vfslip(obj.X(tIdx, zIdx),1);
                case 'SLIP'
                    % [-] Slip void model
                    vf = vfslip(obj.X(tIdx, zIdx),model.SLIP);
                case 'BESTION'
                    % [-] Bestion drift flux model
                    C0 = 1.;                                               % [-] Distribution parameter
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(fluid.RHOF(tIdx)-fluid.RHOG(tIdx))./fluid.RHOG(tIdx)); % [m/s] Drift velocity
                    vf = vfdrift(C0,ugj);            
            end
            
            
            function vf = vfslip(x,S)
            %VFSLIP Void fraction based on slip model
                vf = x.*fluid.RHOF(tIdx)./(x.*fluid.RHOF(tIdx)+S.*(1-x).*fluid.RHOG(tIdx));
            end
            
            function vf = vfdrift(C0,ugj)
            %VFDRIFT Void fraction based on drift flux model
            % C0    [-]     Distribution parameter
            % ugj   [m/s]   Drift velocity
                vf  = obj.JG(tIdx, zIdx)./(C0.*(obj.JG(tIdx, zIdx)+obj.JL(tIdx, zIdx))+ugj);
            end
            
        end

        function rho = RHO(obj, tIdx, zIdx)
        %RHO Density [kg/m^3]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            fluid = obj.inputSet.fluid;
            rho = obj.VF(tIdx, zIdx).*fluid.RHOV(obj.H(tIdx, zIdx), tIdx)+ ...
                    (1-obj.VF(tIdx, zIdx)).*fluid.RHOL(obj.H(tIdx, zIdx), tIdx);
        end

        function mu = MU(obj, tIdx, zIdx)
        %MU Dynamic viscosity [Pa-s]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            fluid = obj.inputSet.fluid;
            mu = obj.X(tIdx, zIdx).*fluid.MUV(obj.H(tIdx, zIdx), tIdx) + ...
                    (1-obj.X(tIdx, zIdx)).*fluid.MUL(obj.H(tIdx, zIdx), tIdx);
        end

        function u = U(obj, tIdx, zIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            u = obj.W(tIdx, zIdx)./obj.RHO(tIdx, zIdx)./obj.inputSet.geometry.AREA; 
        end

        function jl = JL(obj, tIdx, zIdx)
        %JL Superfacial liquid velocity [m/s]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            fluid = obj.inputSet.fluid;
            jl = (1-obj.X(tIdx, zIdx)).*obj.MFLUX(tIdx, zIdx)./fluid.RHOL(obj.H(tIdx, zIdx), tIdx);
        end

        function jg = JG(obj, tIdx, zIdx)
        %JG Superfacial vapor velocity [m/s]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            fluid = obj.inputSet.fluid;
            jg = (1-obj.X(tIdx, zIdx)).*obj.MFLUX(tIdx, zIdx)./fluid.RHOV(obj.H(tIdx, zIdx), tIdx);
        end

        function re = RE(obj, tIdx, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            re = 4.*obj.W(tIdx, zIdx)./obj.MU(tIdx, zIdx)./sum(obj.inputSet.geometry.PERIM);
        end

        function rel = REL(obj, tIdx, zIdx)
        %REL Liquid-equivalent Reynolds number [-]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            re = 4.*obj.W(tIdx, zIdx)./obj.MUL(tIdx, zIdx)./sum(obj.inputSet.geometry.PERIM);
        end

        function fw = FW(obj, tIdx, zIdx)
        %FW Wall friction factor [-]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            model = obj.inputSet.model;
            fw = model.FRICTION(1).*obj.RE(tIdx, zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end

        function tauw = TAUW(obj, tIdx, zIdx)
        %TAUW wall shear stress [Pa]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            tauw = 0.5.*(obj.FW(tIdx, zIdx)./4)./obj.RHO(tIdx, zIdx).*(obj.W(tIdx, zIdx)./obj.inputSet.geometry.AREA).^2;
        end

        function kloss = KLOSS(obj, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = 1:obj.NZ; end
            
            model = obj.inputSet.model;

            kloss = zeros(length(obj.Z),1);                                 % [-] Initialize local loss coefficient array to 0
            [~,ind]=min(abs(obj.Z-model.KLOC));                             % Find local loss elevation indexes (closest node)
            kloss(ind)=model.KLOSS;                                         % [-] Apply loss
            kloss = kloss(zIdx).';                                            % [-] Restrict to selected nodes
            
        end

        function dpk = DPK(obj, tIdx, zIdx)
        %DPK Local pressure loss [Pa]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            dpk = 0.5.*obj.KLOSS(zIdx)./obj.RHO(tIdx, zIdx).*(obj.W(tIdx, zIdx)./obj.inputSet.geometry.AREA).^2;
        end

        function t = T(obj, tIdx, zIdx)
        %T Temperature [K]
        %
            if nargin < 2, tIdx = 1:obj.NTIME; end
            if nargin < 3, zIdx = 1:obj.NZ; end
            
            t = obj.inputSet.fluid.T(obj.H(tIdx, zIdx), tIdx);
        end
        
        function plotz
        %PLOTZ
        %

        end
    
        function interpOut = timeInterpolate(obj, y)
            interpOut = interp1(obj.inputSet.bc.TIME, ...
                                y, ...
                                obj.TIME, ...
                                obj.inputSet.options.TIMEINTERP);
        end

        function interpOut = axialInterpolate(obj, x, y)
            interpOut = interp1(x, ...
                                y, ...
                                obj.Z, ...
                                obj.inputSet.options.AXIALINTERP, ...
                                "extrap");
        end
    end
end

