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
        mflux        (:,1) double  {mustBeNumeric}                         = 1.                 % [kg/m^2-s] Mass flux
        xeq          (:,1) double  {mustBeNumeric}                         = 1.                 % [-] Equilibrium quality
        x            (:,1) double  {mustBeNumeric}                         = 1.                 % [-] Vapor quality
        vf           (:,1) double  {mustBeNumeric}                         = 1.                 % [-] Void fraction
        chf          (:,:) double  {mustBeNumeric}                                              % [-] Critical Heat Flux
        cbt          (:,:) logical                                                              % [-] Critical Boiling Transition flag
        rho          (:,1) double  {mustBeNumeric}                         = 1.                 % [kg/m^3] Mixture density
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

            % Identify indexes to be updated
            zIdx = find(mix.W~=val);
            if isempty(zIdx), zIdx = (1:mix(1).NZ).'; end
        
            % Set mix.W value
            mix.W = val;

            % Calculate mix.mflux
            mix.MFLUX_CALC(zIdx);

        end
        
        function set.H(mix, val)
        %SET.H Setter for H, enthalpy [J/kg]
        %  mix.rho, mix.x and mix.xeq are calculated upon setting mix.H
            
            % Identify indexes to be updated
            zIdx = find(mix.H~=val);
            if isempty(zIdx), zIdx = (1:mix(1).NZ).'; end
            
            % Set mix.H value
            mix.H = val;

            % Calculate mix.rho (mix.rho calls mix.vf, which calls mix.x, which calls mix.xeq)
            mix.RHO_CALC(zIdx);
    
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
        %   This function only retrieves the mix.vf values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.VF_CALC()
        %
            if nargin < 2
                vf = mix.vf; 
            else
                vf = mix.vf(zIdx); 
            end
            
        end
        
        function chf =CHF(mix, zIdx)
        %CHF Critical Heat Flux [W/m^2], wall dependant
        %   This function only retrieves the mix.chf values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.CHF_CALC()
        %    
            if nargin < 2
                chf = mix.chf; 
            else
                chf = mix.chf(zIdx,:); 
            end
            
        end
        
        function cbt =CBT(mix, zIdx)
        %CHF Critical Heat Flux [W/m^2], wall dependant
        %   This function only retrieves the mix.cbt values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.CHF_CALC()
        %    
            if nargin < 2
                cbt = mix.cbt; 
            else
                cbt = mix.cbt(zIdx,:); 
            end
            
        end
        
        function rho = RHO(mix, zIdx)
        %RHO Density [kg/m^3]
        %   This function only retrieves the mix.rho values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.RHO_CALC()
        %
            if nargin < 2
                rho = mix.rho; 
            else
                rho = mix.rho(zIdx); 
            end
            
        end
        
        function lhgr = LHGR(mix, zIdx)
        %LHGR Linear heat generation rate
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            geom = mix.inputSet.geometry;
            lhgr = geom.PERIM.*mix.HFLUX(zIdx,:);                          % [W/m] Linear heat generation rate
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
            
            rel = 4.*mix.W(zIdx)./mix.fluid.MUL(mix.liquid.H(zIdx))./sum(mix.inputSet.geometry.PERIM);
        end
        
        function fwl = FWL(mix, zIdx)
        %FWL Liquid wall friction factor [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            fwl = model.FRICTION(1).*mix.REL(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end
        
        function fw = FW(mix, zIdx)
        %FW Mixture wall Fanning friction factor [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            fw = model.FRICTION(1).*mix.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end
        
        function phi2f = PHI2F(mix, zIdx)
        %PHI2F Two-phase wall friction multiplier [-]   
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            RHOV = mix.fluid.RHOV(mix.liquid.H(zIdx));
            
            switch model.TPFM
                case 'HOMOGENEOUS'
                    phi2f = (1+mix.X(zIdx).*(RHOL./RHOV-1)).*(mix.FW(zIdx)./mix.FWL(zIdx));
                case 'SLIP'
                    phi2f = (RHOL./mix.RHO(zIdx)).*(mix.FW(zIdx)./mix.FWL(zIdx));    
                case 'EPRI'
                    Pcrit = mix.fluid.PCRIT;                               % [Pa]
                    Press = mix.fluid.PRESSURE;                            % [Pa]
                    G = mix.MFLUX(zIdx).*737.3381E-6;                      % [Mlb/hr/ft^2]
                    
                    XCF = 1.02.*mix.X(zIdx).^0.825.*G.^-0.45;              % [-]
                    if Press < 4.137E6
                        XCF = XCF./1.02.*0.357.*(1+10*Press/Pcrit);        % [-]
                    end
                    phi2f = 1 + (RHOL./RHOV-1).*XCF;                       % [-]
            end
            
        end

        function tauw = TAUW(mix, zIdx)
        %TAUW wall shear stress [Pa]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            %tauw = 0.5.*(mix.FW(zIdx)./4)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
            
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            tauw = 0.5.*(mix.FWL(zIdx)./4)./RHOL.*mix.MFLUX(zIdx).^2.*mix.PHI2F(zIdx);
        end

        function kloss = KLOSS(mix, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                % [-] Initialize local loss coefficient array to 0
            [~,ind]=min(abs(mix.Z-model.KLOC));                            % Find local loss elevation indexes (closest node)
            kloss(ind)=model.KLOSS;                                        % [-] Apply loss
            kloss = kloss(zIdx).';                                         % [-] Restrict to selected nodes
            
        end
        
        function phi2k = PHI2K(mix, zIdx)
        %PHI2F Two-phase local pressure drop multiplier [-]
        % TODO: NEED TO BE VERIFIED
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            RHOV = mix.fluid.RHOV(mix.liquid.H(zIdx));
            
            switch model.TPKM
                case 'HOMOGENEOUS'
                    phi2k = 1+mix.X(zIdx).*(RHOL./RHOV-1);
                case 'SLIP'
                    phi2k = RHOL./mix.RHO(zIdx);
                case 'ROMIE'
                    phi2k = mix.X(zIdx).^2./max(1E-6,mix.VF(zIdx)).*(RHOL./RHOV)+(1-mix.X(zIdx)).^2./max(1E-6,1-mix.VF(zIdx));
            end
            
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
        % TODO: NEED TO BE VERIFIED
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            %dpk = -0.5.*mix.KLOSS(zIdx)./mix.RHO(zIdx).*(mix.W(zIdx)./mix.inputSet.geometry.AREA).^2;
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            dpk = -0.5.*mix.KLOSS(zIdx)./RHOL.*mix.MFLUX(zIdx).^2.*mix.PHI2K(zIdx); 
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
        
        function nu = NU(mix, zIdx)
        %NU Nusselt number [-]
        %TODO: It is not clear how the liquid and vapor Reynolds number should be defined for two-phase applications
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            NWALL = mix.inputSet.geometry.NWALL;
            
            % Pre-CHF
            Re = mix.liquid.RE(zIdx);                                      % [-] Reynolds number based on liquid phase
            Pr = mix.fluid.PRANDTLL(mix.liquid.H(zIdx));                   % [-] Prandtl number based on liquid phase
            Re = repmat(Re,1,NWALL); Pr = repmat(Pr,1,NWALL);
            
            % Post-CHF
            Recbt = mix.vapor.RE(zIdx);                                    % [-] Reynolds number based on vapor phase
            Prcbt = mix.fluid.PRANDTLV(mix.vapor.H(zIdx));                 % [-] Prandtl number based on vapor phase
            Recbt = repmat(Recbt,1,NWALL); Prcbt = repmat(Prcbt,1,NWALL);
            idxcbt = mix.CBT(zIdx);
            Re(idxcbt) = Recbt(idxcbt);                                    % [-]
            Pr(idxcbt) = Prcbt(idxcbt);                                    % [-]
            
            %
            nu = 0.023.*Re.^0.8.*Pr.^0.4;                                  % [-]
        end
        
        function hwallliq = HWALLLIQ(mix, zIdx)
        %HWALLLIQ Single-phase liquid wall heat transfer coefficient [W/m^2/K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            k = mix.fluid.KL(mix.liquid.H(zIdx));                          % [W/m/K] Fluid thermal conductivity based on liquid phase
            HDIAM = mix.inputSet.geometry.HDIAM;                           % [m] Hydraulic diameter
            hwallliq = mix.NU(zIdx).*k./HDIAM;                             % [W/m^2/K] Single phase
        end
        
        function hwallthom = HWALLTHOM(mix, zIdx)
        %HWALLTHOM Two-phase wall heat transfer coefficient [W/m^2/K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            % Thom
            q  = mix.HFLUX(zIdx,:);                                        % [W/m^2]
            Tb = mix.liquid.T(zIdx);                                       % [K]
            hwallthom = q./(mix.fluid.TSAT-Tb+22.5.*(q./1E6).^0.5.*exp(-mix.P(zIdx)./1E6/8.7)); % [W/m^2/K]
        end
        
        function hwallvap = HWALLVAP(mix, zIdx)
        %HWALLVAP Single-phase vaporv wall heat transfer coefficient [W/m^2/K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
           
            k = mix.fluid.KV(mix.vapor.H(zIdx));                           % [W/m/K] Fluid thermal conductivity based on vapor phase
            HDIAM = mix.inputSet.geometry.HDIAM;                           % [m] Hydraulic diameter
            hwallvap = mix.NU(zIdx).*k./HDIAM;                             % [W/m^2/K]
        end
        
        function hwall = HWALL(mix, zIdx)
        %HWALL Wall heat transfer coefficient [W/m^2/K]
        %TODO: Create wallheat transfer model options
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            hsp = mix.HWALLLIQ(zIdx);                                      % [W/m^2/K] Single-phase liquid
            
            htp = mix.HWALLTHOM(zIdx);                                     % [W/m^2/K] Two-phase
            hwall = max(hsp,htp);                                          % [W/m^2/K]
            
            hwallcbt = mix.HWALLVAP(zIdx);                                 % [W/m^2/K] Single-phase vapor
            idxcbt = mix.CBT(zIdx);
            hwall(idxcbt) = hwallcbt(idxcbt);                              % [W/m^2/K] Post-CBT
        end
        
        function twall = TWALL(mix, zIdx)
        %TWALL Wall temperature [K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            q = mix.HFLUX(zIdx,:);                                         % [W/m^2]
            hwall = mix.HWALL(zIdx);                                       % [W/m^2/K]
            
            % pre-CBT
            Tb    = mix.liquid.T(zIdx);                                    % [K] Fluid bulk temperature based on liquid phase
            twall = Tb + q./hwall;                                         % [K]
            
            % Post-CBT
            Tb       = mix.vapor.T(zIdx);                                  % [K] Fluid bulk temperature based on vapor phase
            twallcbt = Tb + q./hwall;                                      % [K]
            idxcbt = mix.CBT(zIdx);
            twall(idxcbt) = twallcbt(idxcbt);                              % [K]
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
            oafIdx = find(mix.XEQ <= xoaf, 1, 'last');                     % Find node corresponding to the onset of annular flow
            if isempty(oafIdx), oafIdx = 1; end                            % Most upstream node (1) when pre-annular flow region is not found

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
            oafwl = mix.liquid.W(mix.OAFIDX);                              % [kg/s] Mixture liquid mass flow rate
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

        function MFLUX_CALC(mix, zIdx)
        %MFLUX_CALC Helper function to calculate mass flux [kg/m^2-s]
        %
        
            mix.mflux(zIdx) = mix.W(zIdx)./mix.inputSet.geometry.AREA;
        end

        function XEQ_CALC(mix, zIdx)
        %XEQ_CALC Helper function to calculate equilibrium quality [-]
        %  
        
            mix.xeq(zIdx) = (mix.H(zIdx)-mix.fluid.HF)./ mix.fluid.HFG;
        end

        function X_CALC(mix, zIdx)
        %X_CALC Helper function to calculate vapor quality [-]
        %  
            
            % Call XEQ first
            mix.XEQ_CALC(zIdx);                                            % Use mix.xeq to calculate x
            
            % First initilization
            % Needed since some parameters in EPRI model require the phase enthalpy (and hence X) to be calculated first
            if length(mix.X) <= 1
                mix.x(zIdx) = max(mix.xeq(zIdx),0);
                return
            end
            
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;
            
            switch model.THERMALNONEQ
                case 'EQUILIBRIUM'
                    % [-] Thermal equilibrium model
                    mix.x(zIdx) = max(mix.xeq(zIdx),0);
                    
                case 'SAHAZUBER'
                    % [-] Saha-Zuber model
                    % Saha P. and Zuber N. "Point of net vapor generation and vapor void fraction in subcooled boiling", Heat transfer, 4, 1974
                    % Saturated properties, averaged heat flux and hydraulic diameter are used
                    % Point of net vapor generation is bounded by [xin 0]
                    % TODO: Validate and potentially modify model for applications to channels with walls of different heat fluxes (e.g. unheated wall)
                    mix.x(zIdx) = max(mix.xeq(zIdx),0);
                    
                    HDIAM = geom.HDIAM;                                    % [m] Diameter
                    HFG = mix.fluid.HFG;                                   % [J/kg] 
                    KF = mix.fluid.KF;                                     % [W/m/K] Saturated liquid thermal conductivity
                    CPL = mix.fluid.CPF;                                   % [J/kg/K] Saturated liquid constant pressure specific heat
                    MFLUX = mix.MFLUX(zIdx);                               % [kg/m^2/s] Mass flux
                    HEATFLUX = sum(geom.PERIM.*mix.HFLUX(zIdx,:),2)./sum(geom.PERIM,2); % [W/m^2] Averaged wall heat flux
                    
                    Pe = MFLUX.*(HDIAM*CPL/KF);                            % [-] Peclet number
                    Bo = HEATFLUX./MFLUX./HFG;                             % [-] Boiling number
                    xb = -0.0022.*min(7E4,Pe).*Bo;                         % [-] Thermodynamic quality at point B
                    xb = max(xb,min(mix.XEQ(1),-1E-6));                    % [-] Bound by inlet quality (up to 0)
                    
                    idx = mix.xeq(zIdx) > xb;
                    zIdx = zIdx(idx);
                    mix.x(zIdx) = mix.xeq(zIdx)-xb(idx).*exp(mix.xeq(zIdx)./xb(idx)-1);
                    mix.x(zIdx) = mix.x(zIdx)./(1-xb(idx).*exp(mix.xeq(zIdx)./xb(idx)-1));
                    
                case 'EPRI'
                    % [-] EPRI model
                    % G. S. Lellouche and B. A. Zolotar, A Mechanistic Model for Predicting Two-Phase Void Fraction for Water in Vertical tubes, Channels and Rod Bundles,
                    % Palo A1to, California: Electric Power Research Institute, February, 1982. EPRI NP-2246-SR.
                    % https://www.nrc.gov/docs/ML2001/ML20010E663.pdf
                    
                    HDIAM    = mix.inputSet.geometry.HDIAM;                % [m] Hydraulic diameter
                    
                    % Find quality at bubble departure point
                    %TODO: Array calculations performed at each call, can be optimized 
                    HFG      = mix.fluid.HFG;                              % [J/kg]
                    CPL      = mix.fluid.CPL(mix.liquid.H);                % [J/kg/K]
                    KL       = mix.fluid.KL(mix.liquid.H);                 % [W/m/K] Liquid thermal conductivity
                    PRANDTLL = mix.fluid.PRANDTLL(mix.liquid.H);           % [-] Liquid Prandtl number
%                     CPL      = mix.fluid.CPF;                % [J/kg/K]
%                     KL       = mix.fluid.KF;                 % [W/m/K] Liquid thermal conductivity
%                     PRANDTLL = mix.fluid.PRANDTLF;           % [-] Liquid Prandtl number
                    
                    REL      = mix.liquid.RE;                              % [-] Reynolds number based on liquid phase

                    qWD  = mix.HFLUX;                                      % [W/m^2]
                    HDB  = mix.HWALLLIQ;                                   % [W/m^2/K] Dittus-Boelter correaltion
                    HB   = 193.*exp(-mix.P./4.344E6);                      % [Btu/hr/ft^2/F] Modified (?) Thom correlation
                    HB   = HB.*0.29307107./0.3048^2./(5/9);                % [W/m^2/K]
                    CHN  = 0.2;                                            % [-] Hancox and Nicoll coefficient (0.2 for channels and tubes)
                    NUHN = CHN.*REL.^0.662.*PRANDTLL;                      % [-] Hancox and Nicoll Nusselt
                    HHN  = NUHN.*KL./HDIAM;                                % [W/m^2/K]
                    
                    qWD = qWD.*3.41.*0.3048^2;                             % [Btu/hr/ft^2}
                    HDB = HDB./(0.29307107./0.3048^2./(5/9));              % [Btu/hr/ft^2/F]
                    HB  = HB./(0.29307107./0.3048^2./(5/9));               % [Btu/hr/ft^2/F]
                    HHN = HHN./(0.29307107./0.3048^2./(5/9));              % [Btu/hr/ft^2/F]
                    
                    A = 4.*HB.*(HDB+HHN).^2;
                    B = 2.*HDB.^2.*(HHN+0.5.*HDB)+8.*qWD.*HB.*(HHN+HDB);
                    C = 4.*HB.*qWD.^2+qWD.*HDB.^2;
                    
                    Z = (B-sqrt(B.^2-4.*A.*C))./(2.*A);                    % [F] Bulk subcooling at bubble departure point
                    Z = Z.*(5/9);                                          % [K] Bulk subcooling at bubble departure point
                    xd = -CPL.*Z./HFG;                                     % [-] Quality at bubble departure point (array)
                    
                    dIdx = find(mix.XEQ-xd>0,1);
                    xd = xd(dIdx);                                         % [-] Quality at bubble departure point
                    
                    % Vapor quality distribution
                    if isempty(xd)
                        mix.x(zIdx) = max(mix.xeq(zIdx),0);                % [-]
                    else
                        xdmod = xd.*(1-tanh(1-mix.xeq(zIdx)./xd));         % [-]
                        x     = (mix.xeq(zIdx)-xdmod)./(1-xdmod);          % [-]
                        mix.x(zIdx) = max(x,0);                            % [-]
                    end
                    
                case 'TRELAX'
                    % [-] Time relaxation model
                    % New proposed model based on interfacial phase change time relaxation approach (main calculations in solve.m)
                    % Physical approach to geometrical and thermal inhomogeneities
                    % TODO: Document and validate model
                    
                    mix.x(zIdx) = sum(mix.TRELAX.WV(zIdx,:),2)./mix.W(zIdx);
            end
            mix.x(zIdx) = min(mix.x(zIdx),1);
        end
        
        function VF_CALC(mix, zIdx)
        %VF_CALC Helper function to calculate void fraction [-]
        %
            
            % Call X first
            mix.X_CALC(zIdx);
            
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            switch model.VOID
                case InputEnums.VOID.HOMOGENEOUS
                    % [-] Homogeneous void model
                    mix.vf(zIdx) = vfslip(mix.X(zIdx),1); 
                    
                case InputEnums.VOID.SLIP
                    % [-] Slip void model
                    mix.vf(zIdx) = vfslip(mix.X(zIdx),model.SLIP); 
                    
                case InputEnums.VOID.BESTION
                    % [-] Bestion drift flux model
                    C0 = 1.;                                               % [-] Distribution parameter
                    RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
                    RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(RHOL-RHOV)./RHOV); % [m/s] Drift velocity
                    mix.vf(zIdx) = vfdrift(C0,ugj);
                    
                case InputEnums.VOID.EPRI
                    % [-] EPRI drift flux model
                    % G. S. Lellouche and B. A. Zolotar, A Mechanistic Model for Predicting Two-Phase Void Fraction for Water in Vertical tubes, Channels and Rod Bundles,
                    % Palo A1to, California: Electric Power Research Institute, February, 1982. EPRI NP-2246-SR.
                    % https://www.nrc.gov/docs/ML2001/ML20010E663.pdf
                    
                    RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
                    RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
                    SIG  = mix.fluid.SIGMA;                                % [N/m]
                    Pcrit = mix.fluid.PCRIT;                               % [Pa]
                    Press = mix.fluid.PRESSURE;                            % [Pa}
                    
                    C1 = 4/(Press/Pcrit-(Press/Pcrit)^2);                  % [-]
                    K1 = min(0.8,1./(1+exp(-mix.liquid.RE(1)/1E5)));       % [-]
                    
                    r = (1+1.57.*RHOV./RHOL)./(1-K1);                      % [-]
                    K0 = K1 + (1-K1).*(RHOV./RHOL).^(1/4);                 % [-]
                    L = @(vf) (1-exp(-C1.*vf))./(1-exp(-C1));              % [-]
                    
                    C0  = @(vf) L(vf)./(K0+(1-K0).*vf.^r);                 % [-] Distribution parameter
                    ugj = @(vf) 1.41.*((RHOL-RHOV).*SIG.*model.G./RHOL.^2).^(1/4).*((1-vf)./(1+vf)).^(1/2).*cos(model.ANGLE/180*pi); % [m/s] Drift velocity
                    
                    vf = vfslip(mix.X(zIdx),1);                            % [-] Initialize void fraction
                    MaxIter = 100;                                         % Maximum number fo iterations
                    MaxErr  = 0.001;                                       % [-] Maximum void fraction error
                    for i = 1:MaxIter
                        mix.vf(zIdx) = vfdrift(C0(vf),ugj(vf));
                        err = max(abs(mix.vf(zIdx)-vf));
                        if err < MaxErr, break; end
                        vf = mix.vf(zIdx);
                    end
                    if i == MaxIter, fprintf('%s EPRI void model : not converged -> err=%0.4f\n',class(mix), err); end
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
        
        function CHF_CALC(mix, zIdx)
        %CHF_CALC Helper function to calculate Critical Heat Flux [W/m^2]    
        %TODO: Implement additional CHF correlations
        %      Investigate potential rewetting after CBT, this would require access to CBT and Twall at previous time step!
            
            model = mix.inputSet.model;
            geom = mix.inputSet.geometry;
            
            Pr  = mix.P(end);                                              % [Pa] System pressure
            G   = mix.MFLUX(1:mix(1).NZ);                                  % [kg/m^2/s] Mass flux
            XEQ = mix.XEQ(1:mix(1).NZ);                                    % [-] Equilibrium quality
            D   = geom.HDIAM;                                              % [m] Diameter
            
            switch model.CBT
                case InputEnums.CBT.NONE
                    chf = nan(mix(1).NZ,geom.NWALL);
                    
                case InputEnums.CBT.BIASI
                    % Biasi correlation
                    % BIAS!, L . et al.: A new correlation for round ducts and uniform
                    % heating and its comparison with world data, EURAEC report 1874, 1967.
                    
                    Pr = Pr/1.01235E5;                                     % [ata] System pressure    
                    G  = G./10;                                            % [g/cm^2/s] Mass flux
                    D  = D*1E2;                                            % [cm] Diameter

                    n = 0.6 - 0.2*double(D>=1);
                    
                    HP = -1.159+0.149*Pr*exp(-0.019*Pr)+8.99*Pr/(10+Pr^2);
                    YP = 0.7249+0.099*Pr*exp(-0.032*Pr);
                    
                    q1 = (3.780E3/D^n)./G.^0.6.*HP.*(1-XEQ);               % [W/cm^2] High quality
                    q2 = (1.883E3/D^n)./G.^(1/6).*(YP./G.^(1/6)-XEQ);      % [W/cm^2] Low quality
                    
                    chf = repmat(max(q1,q2),1,geom.NWALL).*1E4;            % [W/m^2]
            end
            
            chf = 0.6.*chf;                                                % Correction for Bennett post-do cases
            %chf = linspace(1.35,0.25,mix(1).NZ)'.*chf;                     % Correction for HPCHF case
            %chf = linspace(1.36,0.25,mix(1).NZ)'.*chf; 
            
            cbt = mix.HFLUX(1:mix(1).NZ,:) > chf;                          % CBT indicator
            %cbt = cumsum(cbt) > 1;                                         % No rewetting downstream CBT
            %Set cbt to 1 for Xeq >= 1?
            
            mix.chf(zIdx,:) = chf(zIdx,:);
            mix.cbt(zIdx,:) = cbt(zIdx,:);
            
        end
        
        function RHO_CALC(mix, zIdx)
        %RHO_CALC Helper function to calculate density [kg/m^3]
        %
        
            % Call VF and CHF first
            mix.VF_CALC(zIdx);
            mix.CHF_CALC(zIdx);
            
            vf = mix.VF(zIdx);
            mix.rho(zIdx) = vf.*mix.fluid.RHOV(mix.vapor.H(zIdx)) + ...
                (1-vf).*mix.fluid.RHOL(mix.liquid.H(zIdx));    
        end

    end
    
    methods (Hidden=true)    
        
        function w = WWALL(mix, zIdx)
        %WWALL Mass flow distribution per wall
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            geom  = mix.inputSet.geometry;
            w = geom.RWALL.*mix.W(zIdx);                                   % [kg/s]
        end
        
        function w = WNEARWALL(mix, zIdx)
        %WNEARWALL Near-wall mass flow distribution per wall
        %TODO: WNEARWALL should correspond to a near wall region (otherwise TRELAX.XEQ and XEQ would be equal for azymuthal equal heat flux)
        %       Arbitrary division by 2 for now
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            w = mix.WWALL(zIdx)./2;                                        % [kg/s]
        end
        
        function t = RELAXTIME(mix, zIdx)
        %RELAXTIME Relaxation time model for wall dependant interfacial transfer
        %TODO: Investigate of this parameter should be walld dependant or not
        %    
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            %geom  = mix.inputSet.geometry;
            N = length(model.RELAXX);
            cbt = mix.CBT(zIdx);

            t = interp1(model.RELAXX,model.RELAXT(1:N),mix.XEQ(zIdx),'linear','extrap'); % Pre-CBT time relaxation model
            %t = repmat(t,1,geom.NWALL);                                    % Expand to all wall
            %t(cbt)                 = model.RELAXT(N+1);                    % CBT and Post-CBT time relaxation (wall dependant)
            t(any(cbt,2))          = model.RELAXT(N+1);                    % CBT and Post-CBT time relaxation (Wall lumped approach)
            t(mix.KLOSS(zIdx)>0,:) = model.RELAXT(N+2);                    % Grid time relaxation
            t = max(1E-6,t);
        end
        
        function mint = MINT(mix, UV, zIdx)
        %MINT Linear interfacial mass transfer rate
        %Drives the system towards thermal equalibirum
        %
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            WW = mix.WWALL(zIdx);                                          % [kg/s] Mass flow distribution per wall
            TRELAXL = mix.RELAXTIME(zIdx);                                 % [s] Time relaxation model
            wint = mix.XEQ(zIdx).*WW-mix.TRELAX.WV(zIdx,:);                % [kg/s]
            mint = wint./UV./TRELAXL;                                      % [kg/s/m]
        end
        
        function wbmratio = WBMRATIO(mix, zIdx)
        %WBMRATIO Wall boiling mass ratio
        %Ratio of liquid mass boiling due to wall heat flux
        %Set to 1 beyond saturation
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            x0 = model.WBOILINGX0;                                         % Quality at onset of wall boiling evaporation [-]
            n  = model.WBOILINGN;                                          % Exponent of wall boiling function [-]
            wbmratio = min(1,max(0,1-(mix.XEQ(zIdx)/x0).^n));              % [-]
        end
        
        function mwbr = MWBR(mix, zIdx)
        %MWBR Linear mass wall boiling rate
        %Liquid assumed to fully boil regardless of subcooling
        %Set to 0 beyond CBT
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            cbt = mix.CBT(zIdx);                                           % CBT flag
            LHGR = mix.LHGR(zIdx);                                         % [W/m] Linear heat generation rate
            HFG  = mix.fluid.HG-mix.liquid.H(zIdx);                        % [J/kg] Vapor is generated at saturation
            mwbr = mix.WBMRATIO(zIdx).*double(~cbt).*LHGR./HFG;            % [kg/s/m] 
        end
        
        function mvtot = MVTOT(mix, UV, zIdx)
        %MVTOT Total linear vapor mass transfer rate
        %    
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            mvtot = mix.MINT(UV,zIdx) + mix.MWBR(zIdx);                    % [kg/s/m]
        end
        
        function lher = LHER(mix, UV, zIdx)
        %LHBR Linear interfacial heat evaporation rate
        %    
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            ME = max(0,mix.MINT(UV,zIdx));                                 % [kg/s] Interfacial evaporation mass flow driver
            HV = mix.TRELAX.HV(zIdx,:);                                    % [J/kg] Vapor enthalpy
            %HV = (mix.TRELAX.HV(zIdx-1,:)+HV)./2;  % This can help by taking the average of HV over zIdx-1 to zIdx
            lher = ME.*(mix.liquid.H(zIdx)-HV);                            % [W/m]
        end
        
        function lhbr = LHBR(mix, zIdx)
        %LHBR Linear boiling heat rate
            
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            MWBR = mix.MWBR(zIdx);                                         % [kg/s] Linear mass wall boiling rate 
            HV = mix.TRELAX.HV(zIdx,:);                                    % [J/kg] Vapor enthalpy
            %HV = (mix.TRELAX.HV(zIdx-1,:)+HV)./2;
            lhbr = MWBR.*(mix.fluid.HG-HV);                                % [W/m]
        end
        
        function lhvr = LHVR(mix, zIdx)
        %LHVR Linear heat to vapor rate
        %Set to LHGR beyond CBT
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            cbt = mix.CBT(zIdx);                                           % CBT flag
            LHGR = mix.LHGR(zIdx);                                         % [W/m] Linear heat generation rate
            lhvr = double(cbt).*LHGR;                                      % [W/m]
        end
        
        function lhtot = LHTOT(mix, UV, zIdx)
        %LHTOT Total linear vapor heat rate
        %    
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            lhtot = mix.LHER(UV,zIdx) + mix.LHBR(zIdx) + mix.LHVR(zIdx);   % [W/m]
        end
        
        function hvtot = HVTOT(mix, UV, zIdx)
        %HVTOT Total linear vapor energy transfer rate
        %    
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            WV = mix.TRELAX.WV(zIdx,:);                                    % [kg/s] Vapor mass flow rate
            lhtot = mix.LHTOT(UV,zIdx);                                    % [W/m] Total linear vapor heat rate
            
            WV = sum(WV,2);lhtot = sum(lhtot,2);                           % [J/kg/s] !!! Wall lump approach
            
            hvtot = lhtot./WV;                                             % [J/kg/s]
            hvtot(WV <= 1E-8) = 0;
        end
        
        function wv = WV(mix, zIdx, UV, WVold, Uold)
        %WV Time relaxed vapor mass flow rate
        %Used for alternative direct substitution scheme in solver
            
            WW      = mix.WWALL(zIdx);                                     % [kg/s] Mass flow distribution per wall
            MWBR    = mix.MWBR(zIdx);                                      % [kg/s/m] Linear mass wall boiling rate
            TRELAXL = mix.RELAXTIME(zIdx);                                 % [s] Time relaxation model
            
            Wnew = (mix.TRELAX.WV(zIdx-1,:) + (WVold./Uold./mix.DT ...
                + mix.XEQ(zIdx).*WW./UV./TRELAXL + MWBR).*mix.DZ) ...     
                ./(1 + mix.DZ./UV.*(1/mix.DT + 1./TRELAXL));               % [kg/s] Update relaxed vapor mass flow
            wv = max(0,Wnew);                                              % [kg/s] Relaxed vapor mass flow
        end
        
        function wvth = WVTH(mix, zIdx, UV, WVTHold, Uold)
        %WVTH Time relaxed modified (thermodynamic) vapor mass flow rate
        %Alternative direct substitution scheme in solver
        %TODO: Time relaxation same as for vapor mass flow rate for now, could be different
        %    
            WNW     = mix.WNEARWALL(zIdx);                                 % [kg/s] Mass flow distribution per wall
            MWBR    = mix.MWBR(zIdx);                                      % [kg/s/m] Linear mass wall boiling rate
            TRELAXL = mix.RELAXTIME(zIdx);                                 % [s] Time relaxation model
            
            wvth = (mix.TRELAX.WVTH(zIdx-1,:) + (WVTHold./Uold./mix.DT ...
                 + mix.XEQ(zIdx).*WNW./UV./TRELAXL + MWBR).*mix.DZ) ...
                ./(1 + mix.DZ./UV.*(1/mix.DT + 1./TRELAXL));               % [kg/s] Update relaxed modified vapor mass flow
        end
        
        function hv = HV(mix, zIdx, UV, HVold)
        %HV Time relaxed vapor enthalpy
        %Alternative direct substitution scheme in solver
        %t
            
            WV   = mix.TRELAX.WV(zIdx,:);                                  % [kg/s] Relaxed vapor mass flow rate
            MWBR = mix.MWBR(zIdx);                                         % [kg/s/m] Linear mass wall boiling rate
            LHVR = mix.LHVR(zIdx);                                         % [W/m] Linear heat to vapor rate
            ME   = max(0,mix.MINT(UV,zIdx));                               % [kg/s] Interfacial evaporation mass flow driver
            
            WV = sum(WV,2); MWBR = sum(MWBR,2); LHVR = sum(LHVR,2); ME = sum(ME,2); % !!! Wall lump approach
            
            G = (ME.*mix.liquid.H(zIdx) + LHVR + MWBR.*mix.fluid.HG)./WV;
            J = (ME + MWBR)./WV;
            G(WV <= 1E-8) = 0; J(WV <= 1E-8) = 0;
            hnew = (mix.TRELAX.HV(zIdx-1,:) + (HVold./UV./mix.DT + G).*mix.DZ) ...
                ./(1 + mix.DZ./UV.*(1/mix.DT) + J.*mix.DZ);                % [kg/s] Update relaxed vapor enthalpy   
            hv = max(mix.fluid.HG,hnew);                                   % No subcooled vapor
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

