classdef Mixture < matlab.mixin.Copyable
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=?Solvers.Mixture.MixtureSolver)
        
        NZ           (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of time steps
        TIME         (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time step size
        TIDX         (1,1) double  {mustBeNumeric}                         = 1                    % [-] Time step index
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux

        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                         = 7E6                  % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % [-] Detailed pressure drops
        ITR          (1,1) struct 

        inputSet    {isa(inputSet,'Inputs.InputSet')}
        fluid       {isa(fluid,'Inputs.FluidProperties')}

        % Phases
        liquid
        vapor
    end
    
    

    methods
        function mix = Mixture(inputSet, fluid)
            %MIXTURE Creates a Mixture solver mix
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                mix.inputSet = inputSet;
                mix.fluid  = fluid;
            end

        end
        
        function mflux = MFLUX(mix, zIdx)
        %MFLUX Mass flux [kg/m^2-s]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end

            mflux = mix.W(zIdx)./mix.inputSet.geometry.AREA;
        end

        function xeq = XEQ(mix, zIdx)
        %XEQ Equilibrium quality [-]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
        
            xeq = (mix.H(zIdx)-mix.fluid.HF) ./ mix.fluid.HFG;
        end

        function x = X(mix, zIdx)
        %X Vapor quality [-]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
        
            switch mix.inputSet.model.SCBOIL
                case 'NONE'
                    x=min(max(mix.XEQ(zIdx),0),1);
            end
        end

        function vf =VF(mix, zIdx)
        %VF Void fraction [-]
        %   
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            model = mix.inputSet.model;
            geom = mix.inputSet.geometry;

            switch model.VOID
                case 'HOMOGENEOUS'
                    % [-] Homogeneous void model
                    vf = vfslip(mix.X(zIdx),1);
                case 'SLIP'
                    % [-] Slip void model
                    vf = vfslip(mix.X(zIdx),model.SLIP);
                case 'BESTION'
                    % [-] Bestion drift flux model
                    C0 = 1.;                                               % [-] Distribution parameter
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(mix.fluid.RHOF-mix.fluid.RHOG)./mix.fluid.RHOG); % [m/s] Drift velocity
                    vf = vfdrift(C0,ugj);            
            end
            
            
            function vf = vfslip(x,S)
            %VFSLIP Void fraction based on slip model
                vf = x.*mix.fluid.RHOF./(x.*mix.fluid.RHOF+S.*(1-x).*mix.fluid.RHOG);
            end
            
            function vf = vfdrift(C0,ugj)
            %VFDRIFT Void fraction based on drift flux model
            % C0    [-]     Distribution parameter
            % ugj   [m/s]   Drift velocity
                vf  = mix.JG(zIdx)./(C0.*(mix.JG(zIdx)+mix.JL(zIdx))+ugj);
            end
            
        end

        function rho = RHO(mix, zIdx)
        %RHO Density [kg/m^3]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            rho = mix.VF(zIdx).*mix.fluid.RHOV(mix.H(zIdx))+ ...
                    (1-mix.VF(zIdx)).*mix.fluid.RHOL(mix.H(zIdx));
        end

        function mu = MU(mix, zIdx)
        %MU Dynamic viscosity [Pa-s]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            mu = mix.X(zIdx).*mix.fluid.MUV(mix.H(zIdx)) + ...
                    (1-mix.X(zIdx)).*mix.fluid.MUL(mix.H(zIdx));
        end

        function u = U(mix, zIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            u = mix.W(zIdx)./mix.RHO(zIdx)./mix.inputSet.geometry.AREA; 
        end

        function jl = JL(mix, zIdx)
        %JL Superfacial liquid velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            jl = (1-mix.X(zIdx)).*mix.MFLUX(zIdx)./mix.fluid.RHOL(mix.H(zIdx));
        end

        function jg = JG(mix, zIdx)
        %JG Superfacial vapor velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            jg = (1-mix.X(zIdx)).*mix.MFLUX(zIdx)./mix.fluid.RHOV(mix.H(zIdx));
        end

        function re = RE(mix, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            re = 4.*mix.W(zIdx)./mix.MU(zIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function rel = REL(mix, zIdx)
        %REL Liquid-equivalent Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            re = 4.*mix.W(zIdx)./mix.MUL(zIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function fw = FW(mix, zIdx)
        %FW Wall friction factor [-]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            model = mix.inputSet.model;
            fw = model.FRICTION(1).*mix.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end

        function tauw = TAUW(mix, zIdx)
        %TAUW wall shear stress [Pa]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            tauw = 0.5.*(mix.FW(zIdx)./4)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function kloss = KLOSS(mix, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                 % [-] Initialize local loss coefficient array to 0
            [~,ind]=min(abs(mix.Z-model.KLOC));                             % Find local loss elevation indexes (closest node)
            kloss(ind)=model.KLOSS;                                         % [-] Apply loss
            kloss = kloss(zIdx).';                                            % [-] Restrict to selected nodes
            
        end

        function dpk = DPK(mix, zIdx)
        %DPK Local pressure loss [Pa]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            dpk = 0.5.*mix.KLOSS(zIdx)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function t = T(mix, zIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            t = mix.fluid.T(mix.H(zIdx));
        end
        
        function interpOut = timeInterpolate(mix, y)
            interpOut = interp1([mix.inputSet.bc.TIME], ...
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

    methods(Access = protected)
    
    
        function cpObj = copyElement(obj)
        %COPYELEMENT Override copyElement method to create correct references
        %with properties liquid and vapor 
            
            import Solvers.Mixture.*

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            
            % Update liquid and vapor 'mix' property
            cpObj.liquid = Liquid(cpObj);
            cpObj.vapor = Vapor(cpObj);
        end
    end

end

