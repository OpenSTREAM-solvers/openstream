classdef Mixture < Solvers.AbstractField
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
        
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                         = 7E6                  % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % Detailed pressure drops
        ACC          (1,1) struct                                                                 % Detailed acceleration terms
        TRELAX       (1,1) struct                                                                 % Time relaxation terms
        
        % Iteration properties
        ITR

        % Phases
        liquid
        vapor
    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
    end

    properties (Access=private)
        mflux        (:,1) double  {mustBeNumeric}                         = 1                  % [kg/m^2-s] Mass flux
        xeq          (:,1) double  {mustBeNumeric}                         = 1                  % [-] Equilibrium quality
        x            (:,1) double  {mustBeNumeric}                         = 1                  % [-] Vapor quality
        oafidx_const       double  {mustBeNumeric}                         = []                 % [-] Solved index for onset of annular flow
        sigm_const   (:,1) double  {mustBeNumeric}                         = []                 % [-] Solved sigmoid fnc value
    end       
    
    methods
        function mix = Mixture(inputSet, fluid)
            %MIXTURE Creates a Mixture, mix
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                mix.inputSet = inputSet;
                mix.fluid  = fluid;
            end

            % Overload copyable properties (order is important due to the setter functions)
            mix.flowProperties = {'TRELAX','W','P','H','DP','ACC'};

        end
        
        function set.W(mix, val)
        %SET.W Setter for W, mass flow rate [kg/s]
        %  mix.mflux is calculated upon setting mix.W

        
            % Set mix.W value
            mix.W = val;

            % Calculate mix.mflux
            mix.MFLUX_CALC();

        end
        
        function set.H(mix, val)
        %SET.H Setter for H, enthalpy [J/kg]
        %  mix.x and mix.xeq are calculated upon setting mix.H
            
            % Set mix.H value
            mix.H = val;

            % Calculate mix.x (mix.x calls mix.xeq internally)
            mix.X_CALC();
    
        end
        
        function mflux = MFLUX(mix, zIdx)
        %MFLUX Mass flux [kg/m^2/s]
        %   This function only retrieves the mix.mflux values pre-calculated
        %   when mix.W is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.MFLUX_CALC()
        %
            if nargin < 2
                mflux = mix.mflux; 
            else
                mflux = mix.mflux(zIdx);
            end
            
        end

        function xeq = XEQ(mix, zIdx)
        %XEQ Equilibrium quality [-]
        %   This function only retrieves the mix.xeq values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.XEQ_CALC()
        %
            if nargin < 2
                xeq = mix.xeq; 
            else
                xeq = mix.xeq(zIdx);
            end

        end

        function x = X(mix, zIdx)
        %X Vapor quality [-]
        %   This function only retrieves the mix.x values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.X_CALC()
        %
            if nargin < 2
                x = mix.x; 
            else
                x = mix.x(zIdx); 
            end
            
        end
        
        function vf =VF(mix, zIdx)
        %VF Void fraction [-]
        %TODO: Can take time to compute, would benefit from pre-calculation such as for XEQ and X
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            geom = mix.inputSet.geometry;

            switch model.VOID
                case InputEnums.VOID.HOMOGENEOUS
                    % [-] Homogeneous void model
                    vf = vfslip(mix.X(zIdx),1); 
                    
                case InputEnums.VOID.SLIP
                    % [-] Slip void model
                    vf = vfslip(mix.X(zIdx),model.SLIP); 
                    
                case InputEnums.VOID.BESTION
                    % [-] Bestion drift flux model
                    C0 = 1.;                                               % [-] Distribution parameter
                    RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
                    RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(RHOL-RHOV)./RHOV); % [m/s] Drift velocity
                    vf = vfdrift(C0,ugj);            
            end
            
            
            function vf = vfslip(x,S)
            %VFSLIP Void fraction based on slip model
                RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
                RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
                vf = x.*RHOL./(x.*RHOL+S.*(1-x).*RHOV);
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
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            vf = mix.VF(zIdx);
            rho = vf.*mix.fluid.RHOV(mix.vapor.H(zIdx))+ ...
                    (1-vf).*mix.fluid.RHOL(mix.liquid.H(zIdx));    
        end

        function mu = MU(mix, zIdx)
        %MU Dynamic viscosity [Pa-s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            mu = mix.X(zIdx).*mix.fluid.MUV(mix.vapor.H(zIdx)) + ...
                    (1-mix.X(zIdx)).*mix.fluid.MUL(mix.liquid.H(zIdx));
        end

        function u = U(mix, zIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            u = mix.W(zIdx)./mix.RHO(zIdx)./mix.inputSet.geometry.AREA; 
        end

        function jl = JL(mix, zIdx)
        %JL Superfacial liquid velocity [m/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            jl = (1-mix.X(zIdx)).*mix.MFLUX(zIdx)./mix.fluid.RHOL(mix.liquid.H(zIdx));
        end

        function jg = JG(mix, zIdx)
        %JG Superfacial vapor velocity [m/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            jg = mix.X(zIdx).*mix.MFLUX(zIdx)./mix.fluid.RHOV(mix.vapor.H(zIdx));
        end

        function re = RE(mix, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            re = 4.*mix.W(zIdx)./mix.MU(zIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function rel = REL(mix, zIdx)
        %REL Liquid-equivalent Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            rel = 4.*mix.W(zIdx)./mix.MUL(zIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function fw = FW(mix, zIdx)
        %FW Wall friction factor [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            fw = model.FRICTION(1).*mix.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end

        function tauw = TAUW(mix, zIdx)
        %TAUW wall shear stress [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            tauw = 0.5.*(mix.FW(zIdx)./4)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function kloss = KLOSS(mix, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                 % [-] Initialize local loss coefficient array to 0
            [~,ind]=min(abs(mix.Z-model.KLOC));                             % Find local loss elevation indexes (closest node)
            kloss(ind)=model.KLOSS;                                         % [-] Apply loss
            kloss = kloss(zIdx).';                                          % [-] Restrict to selected nodes
            
        end
        
        function dpGrav = DPGRAV(mix, zIdx)
        %DPK Gravitational pressure loss [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpGrav  = -mix.inputSet.model.G*cos(mix.inputSet.model.ANGLE*pi/180)*mix.RHO(zIdx)*mix.DZ;
        end

        function dpWall = DPWALL(mix, zIdx)
        %DPWALL Wall friction pressure drop [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpWall  = -sum(mix.inputSet.geometry.PERIM)*mix.TAUW(zIdx)./mix.inputSet.geometry.AREA.*mix.DZ;                
        end

        function dpAcc_z = DPACCZ(mix, zIdx)
        %DPACCZ Spatial acceleration pressure drop [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            VEL   = mix.U([zIdx-1 zIdx]);                                  % [m/s] Calculate velocity array
            U     = VEL(2); 
            Uups  = VEL(1);

            dpAcc_z = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*(U-Uups);
        end

        function dpAcc_t = DPACCT(mix, Uold, zIdx)
        %DPACCT Temporal acceleration pressure drop [Pa]
        %
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            U     = mix.U(zIdx);                                           % [m/s] Calculate velocity 

            dpAcc_t = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*(1-Uold/U).*mix.DZ./mix.DT;
        end

        function dpk = DPK(mix, zIdx)
        %DPK Local pressure loss [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpk = 0.5.*mix.KLOSS(zIdx)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function dptot = DPTOT(mix, Uold, zIdx)
        %DPTOT Total pressure loss [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dptot = mix.DPGRAV(zIdx) + mix.DPWALL(zIdx) + mix.DPACCZ(zIdx) + mix.DPACCT(Uold, zIdx) + mix.DPK(zIdx);
        end

        function dpparts = DPPARTS(mix, Uold, zIdx)
        %DPPARTS Pressure loss components[Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            dpparts.GRAV = mix.DPGRAV(zIdx);
            dpparts.WALL = mix.DPWALL(zIdx);
            dpparts.ACCZ = mix.DPACCZ(zIdx);
            dpparts.ACCT = mix.DPACCT(Uold, zIdx);
            dpparts.K    = mix.DPK(zIdx);
            dpparts.TOT  = dpparts.GRAV + dpparts.WALL + dpparts.ACCZ + dpparts.ACCT + dpparts.K;
            
        end

        function t = T(mix, zIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            t = mix.fluid.T(mix.H(zIdx));
        end      
        
        function oafIdx = OAFIDX(mix)
            %OAFIDX Onset of annular flow node
            %

            % Use saved value if it has been calculated already
            if ~isempty(mix.oafidx_const)
                oafIdx = mix.oafidx_const;
                return
            end
            
            model = mix.inputSet.model;
            HDIAM  = mix.inputSet.geometry.HDIAM;
            MFLUX  = mix.MFLUX;
            
            % Densities
            RHOF = mix.fluid.RHOF;
            RHOG = mix.fluid.RHOG;
            DELTARHO = RHOF-RHOG;
            
            switch model.OAF
                case InputEnums.OAF.WALLIS
                    % Wallis model
                    xoaf = (0.6+0.4.*sqrt(model.G*HDIAM*(DELTARHO)*RHOF)./MFLUX)./(0.6+sqrt(RHOF/RHOG)); % [-] Quality at onset of annular flow
                case InputEnums.OAF.WALLIS_SIMP
                    % Simplified Wallis model
                    xoaf = sqrt(model.G*HDIAM*(DELTARHO)*RHOG)./MFLUX;
            end
            oafIdx = find(mix.X>=xoaf, 1, 'first');                        % Find node corresponding to the onset of annular flow
            if isempty(oafIdx), oafIdx = mix.NZ; end                       % Most donstream node (NZ) when annular flow region is not found

            % Save value
            mix.oafidx_const = oafIdx;
        end
        
        function oafz = OAFZ(mix)
        %OAFZ Onset of annular flow elevation
        %
            oafz = mix.Z(mix.OAFIDX);                                      % [m] Elevation at onset of annular flow
        end
        
        function oafwl = OAFWL(mix)
        %OAFWL Liquid mass flow rate at onset of annular flow
        %
            oafwl = mix.liquid.W(mix.OAFIDX);                    % [kg/s] Mixture liquid mass flow rate
        end
        
        function afFnc = AFFNC(mix, zIdx)
        %AFFNC Annular flow function
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            p = model.OAFTRANSITION;                                       % Sigmoid function parameters 
            p = p.*(model.NNODES/geom.LENGTH);                             % ... in node length
            afFnc = mix.sigm(zIdx,[p(1), mix.OAFIDX()+p(2)]);
        end
        
        function afDistr = AFDISTR(mix,param1,param2,zIdx)
        %AFDISTR Annular flow distribution function
        %
            if nargin < 4, zIdx = (1:mix(1).NZ).'; end
            
            affnc = mix.AFFNC(zIdx);
            afDistr = (1-affnc).*param1 + affnc.*param2;
        end
    
    end

    methods(Access = protected)
    

        function cpObj = copyElement(obj)
        %COPYELEMENT Override copyElement method to create correct references
        % with properties liquid and vapor 
            
            import Solvers.Mixture.*

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            
            % Update liquid and vapor 'mix' property
            cpObj.liquid = Liquid(cpObj);
            cpObj.vapor = Vapor(cpObj);
        end


        function interpOut = timeInterpolate(mix, y)
        %TIMEINTERPOLATE Interpolate vector y in TIME
        %
            interpOut = interp1([mix.inputSet.bc.TIME], ...
                                y, ...
                                mix.TIME, ...
                                mix.inputSet.options.TIMEINTERP);
        end

        function interpOut = axialInterpolate(mix, x, y)
        %AXIALINTERPOLATE Interpolate vector y in x
        %
            interpOut = interp1(x, ...
                                y, ...
                                mix.Z, ...
                                mix.inputSet.options.AXIALINTERP, ...
                                "extrap");
        end

        function MFLUX_CALC(mix)
        %MFLUX_CALC Helper function to calculate mass flux [kg/m^2-s]
            mix.mflux = mix.W./mix.inputSet.geometry.AREA;
        end

        function XEQ_CALC(mix)
        %XEQ_CALC Helper function to calculate equilibrium quality [-]
        %  
            mix.xeq = (mix.H-mix.fluid.HF) ./ mix.fluid.HFG;
        end

        function X_CALC(mix)
        %X_CALC Helper function to calculate vapor quality [-]
        %  
            
            % Call XEQ first
            mix.XEQ_CALC();                                                % Use mix.xeq to calculate x
            
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;
            
            switch model.SCBOIL
                case 'NONE'
                    % Thermal equilibrium model
                    mix.x = min(max(mix.xeq,0),1);
                case 'SAHAZUBER'
                    % Saha-Zuber model
                    % Saha P. and Zuber N. "Point of net vapor generation and vapor void fraction in subcooled boiling", Heat transfer, 4, 1974
                    % Saturated properties, averaged heat flux and hydraulic diameter are used
                    % Point of net vapor generation is bounded by [xin 0]
                    % TODO: Validate and potentially modify model for applications to channels with walls of different heat fluxes (e.g. unheated wall)
                    mix.x = min(max(mix.xeq,0),1);
                    
                    HDIAM = geom.HDIAM;                                    % [m] Diameter
                    HFG = mix.fluid.HFG;                                   % [J/kg] 
                    KF = mix.fluid.KF;                                     % [W/m/K] Saturated liquid thermal conductivity
                    CPF = mix.fluid.CPF;                                   % [J/kg/K] Saturated liquid constant pressure specific heat
                    HEATFLUX = sum(geom.PERIM.*mix.HFLUX,2)./sum(geom.PERIM,2); % [W/m^2] Averaged wall heat flux
                    
                    Pe = mix.MFLUX.*(HDIAM*CPF/KF);                        % [-] Peclet number
                    Bo = HEATFLUX./mix.MFLUX./HFG;                         % [-] Boiling number
                    xb = -0.0022.*min(7E4,Pe).*Bo;                         % [-] Thermodynamic quality at point B
                    xb = max(xb,min(mix.XEQ(1),-1E-6));                    % [-] Bound by inlet quality (up to 0)
                    
                    idx = mix.xeq > xb;
                    mix.x(idx) = mix.xeq(idx)-xb(idx).*exp(mix.xeq(idx)./xb(idx)-1);
                    mix.x(idx) = mix.x(idx)./(1-xb(idx).*exp(mix.xeq(idx)./xb(idx)-1));
                case 'TRELAX'
                    % Time relaxation model
                    % New proposed model based on interfacial phase change time relaxation approach (main calculations in solve.m)
                    % Physical approach to geometrical and thermal inhomogeneities
                    % TODO: Document and validate model
                    mix.x = sum(geom.PERIM.*mix.TRELAX.X,2)./sum(geom.PERIM,2); % [-] Averaged based on wall contributions
            end
        end

    end

    methods (Access=private)
        function s = sigm(mix, zIdx, pCoefs)
            
            % Calculate sigmoid function once
            % NOTE: changing pCoefs after first call will not result in
            % update of this function values.
            if isempty(mix.sigm_const)
                zIdxs = (1:mix(1).NZ).';
                mix.sigm_const = 1./(1+exp(-pCoefs(1).*(zIdxs-pCoefs(2)))); % Define sigmoid function
            end
            s = mix.sigm_const(zIdx);
        end
    end

end

