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
        DP           (1,1) struct                                                                 % Saved detailed pressure drops
        DPSUM        (1,1) struct                                                                 % Saved detailed cumulative pressure drops
        MDER         (1,1) struct                                                                 % Saved detailed material derivative terms
        TRELAX       (1,1) struct                                                                 % Time relaxation terms
        NEARWALL     (1,1) struct                                                                 % Near-wall terms
        
        % Iteration properties
        ITR

        % Phases
        liquid
        vapor
    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)
        
        DZ             (1,1) double  {mustBeNumeric}                       = 0                    % [m] Axial step size
        inputSet                     {isa(inputSet,'Inputs.InputSet')}
        fluid                        {isa(fluid,'Inputs.FluidProperties')}
    end

    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField}, GetAccess=?Solvers.AbstractField)

        % Wall heat transfer transition flags
        cbt            (:,:) logical                                       = false                % [-] Critical Boiling Transition flag
        mfbt           (:,:) logical                                       = false                % [-] Minimum Film  Boiling Transition flag
    end

    properties (Access=private)
        
        % Flow properties
        mflux          (:,1) double  {mustBeNumeric}                       = 1.                   % [kg/m^2-s] Mass flux
        xeq            (:,1) double  {mustBeNumeric}                       = 1.                   % [-] Equilibrium quality
        x              (:,1) double  {mustBeNumeric}                       = 1.                   % [-] Vapor quality
        vf             (:,1) double  {mustBeNumeric}                       = 1.                   % [-] Void fraction
        chf            (:,:) double  {mustBeNumeric}                                              % [-] Critical Heat Flux
        rho            (:,1) double  {mustBeNumeric}                       = 1.                   % [kg/m^3] Mixture density

        % Onset of annular flow
        oafidx_const         double  {mustBeNumeric}                       = []                   % [-] Solved index for onset of annular flow
        sigm_const     (:,1) double  {mustBeNumeric}                       = []                   % [-] Solved sigmoid fnc value

        % Time relaxations
        relaxtevap     (:,:) double  {mustBeNumeric}                                              % [-] Time relaxation for interfacial evaporation
        relaxtcond     (:,:) double  {mustBeNumeric}                                              % [-] Time relaxation for interfacal condensation
        nearwalltrelax (:,:) double  {mustBeNumeric}                                              % [-] Time relaxation for near-wall energy transfer
    end       
    
    %% Constructor method
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
            mix.flowProperties = {'TRELAX','W','P','H','DP','DPSUM','MDER','ITR','NEARWALL','cbt','mfbt'};
        end
        
    end
    
    %% Setter methods
    methods
        
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
        %   are calculated via mix.CBT_CALC()
        %    
            if nargin < 2
                chf = mix.chf; 
            else
                chf = mix.chf(zIdx,:); 
            end
        end
        
        function cbt =CBT(mix, zIdx)
        %CBT Critical Boiling Transition flag [-], wall dependant
        %   This function only retrieves the mix.cbt values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.CBT_CALC()
        %    
            if nargin < 2
                cbt = mix.cbt; 
            else
                cbt = mix.cbt(zIdx,:); 
            end
        end

        function mfbt =MFBT(mix, zIdx)
        %MFBT Minimum Film Boiling Trnasition flag [-], wall dependant
        %   This function only retrieves the mix.mfbt values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.MFBT_CALC()
        %
            if nargin < 2
                mfbt = mix.mfbt;
            else
                mfbt = mix.mfbt(zIdx,:);
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
        
        function t = RELAXTEVAP(mix, zIdx)
        %RELAXTEVAP Time relaxation for interfacial evaporation [s]
        %   This function only retrieves the mix.relaxtevap values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.RELAXTEVAP_CALC()
        %
            if nargin < 2
                t = mix.relaxtevap; 
            else
                t = mix.relaxtevap(zIdx); 
            end
        end
        
        function t = RELAXTCOND(mix, zIdx)
        %RELAXTCOND Time relaxation for interfacial evaporation [s]
        %   This function only retrieves the mix.relaxtevap values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.RELAXTCOND_CALC()
        %
            if nargin < 2
                t = mix.relaxtcond; 
            else
                t = mix.relaxtcond(zIdx); 
            end
        end

    end
    
    %% Fluid transport methods
    methods
        
        function lhgr = LHGR(mix, zIdx)
        %LHGR Linear heat generation rate
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            geom = mix.inputSet.geometry;
            lhgr = geom.PERIM.*mix.HFLUX(zIdx,:);                          % [W/m] Linear heat generation rate
        end

        function mu = MU(mix, zIdx)
        %MU Dynamic viscosity [Pa.s]
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
        
        function t = T(mix, zIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            t = mix.fluid.T(mix.H(zIdx));
        end
        
        function kdist = KDIST(mix,zIdx)
        %KDIST Distance from upstream spacer (or from inlet)
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            dz = arrayfun(@(k) mix.Z(k)-[0 model.KLOC],zIdx,'uni',0);
            kdist = cellfun(@(dz) min(dz(dz>=0)),dz);                      % [m]
        end
        
    end
    
    %% Momentum transfer methods
    methods
        
        function fw = FW(mix, zIdx)
        %FW Fanning wall friction factor [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            fw = model.FRICTION(1).*mix.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end
        
        function fwl = FWL(mix, zIdx)
        %FWL Liquid-equivalent Fanning wall friction factor [-]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            fwl = model.FRICTION(1).*mix.REL(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        end
        
        function phi2f = PHI2F(mix, zIdx)
        %PHI2F Two-phase wall friction multiplier [-]   
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
            
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
        %TAUW wall shear stress [N/m^2]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            tauw = 0.5.*(mix.FWL(zIdx)./4)./RHOL.*mix.MFLUX(zIdx).^2.*mix.PHI2F(zIdx); % [N/m^2]
        end

        function kloss = KLOSS(mix, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                % [-] Initialize local loss coefficient array to 0
            [~,ind] = min(abs(mix.Z-model.KLOC));                          % Find local loss elevation indexes (closest node)
            kloss(ind) = model.KLOSS;                                      % [-] Apply loss
            kloss = kloss(zIdx);                                           % [-] Restrict to selected input nodes
        end

        function phi2k = PHI2K(mix, zIdx)
        %PHI2F Two-phase local pressure drop multiplier [-]
        % TODO: NEED TO BE VERIFIED
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
            
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
            
            deltaU = diff([[mix.U(1);mix.U(1:end-1)] mix.U],[],2);         % [m/s] Calculate velocity difference
            dpAcc_z = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*deltaU(zIdx);
        end

        function dpAcc_t = DPACCT(mix, Uold, zIdx)
        %DPACCT Temporal acceleration pressure drop [Pa]
        %
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            U     = mix.U(zIdx);                                           % [m/s] Calculate velocity 
            dpAcc_t = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*(1-Uold./U).*mix.DZ./mix.DT;
        end

        function dpk = DPK(mix, zIdx)
        %DPK Local pressure loss [Pa]
        % TODO: NEED TO BE VERIFIED
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            dpk = -0.5.*mix.KLOSS(zIdx)./RHOL.*mix.MFLUX(zIdx).^2.*mix.PHI2K(zIdx); 
        end

        function dptot = DPTOT(mix, Uold, zIdx)
        %DPTOT Total pressure loss [Pa]
        %
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            dptot = mix.DPGRAV(zIdx) + mix.DPWALL(zIdx) + mix.DPACCZ(zIdx) + mix.DPACCT(Uold, zIdx) + mix.DPK(zIdx);
        end

        function dpparts = DPPARTS(mix, Uold, zIdx)
        %DPPARTS All pressure loss components[Pa]
        %
            if nargin < 3, zIdx = (1:mix(1).NZ).'; end
            
            dpparts.GRAV = mix.DPGRAV(zIdx);
            dpparts.WALL = mix.DPWALL(zIdx);
            dpparts.ACCZ = mix.DPACCZ(zIdx);
            dpparts.ACCT = mix.DPACCT(Uold, zIdx);
            dpparts.K    = mix.DPK(zIdx);
            dpparts.TOT  = mix.DPTOT(Uold, zIdx);
        end
      
    end
    
    %% Wall heat transfer methods
    methods
        
        function nu = NU(mix, zIdx)
        %NU Wall Nusselt number [-]
        %TODO: It is not clear how the liquid and vapor Reynolds number should be defined for two-phase applications
        %TODO: Add other options
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            NWALL = mix.inputSet.geometry.NWALL;
            
            % Pre-CHF
            Re = mix.liquid.RE(zIdx);                                      % [-] Liquid-equivalent Reynolds number
            Pr = mix.fluid.PRANDTLL(mix.liquid.H(zIdx));                   % [-] Liquid Prandtl number
            Re = repmat(Re,1,NWALL); Pr = repmat(Pr,1,NWALL);              % Extent to all walls
            
            % Post-CHF
            Recbt = mix.vapor.RE(zIdx);                                    % [-] Vapor Reynolds number
            Prcbt = mix.fluid.PRANDTLV(mix.vapor.H(zIdx));                 % [-] Vapor Prandtl number
            Recbt = repmat(Recbt,1,NWALL); Prcbt = repmat(Prcbt,1,NWALL);  % Extent to all walls
            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);
            Re(idxbt) = Recbt(idxbt);                                      % [-]
            Pr(idxbt) = Prcbt(idxbt);                                      % [-]
            
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
        %HWALLVAP Single-phase vapor wall heat transfer coefficient [W/m^2/K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
           
            k = mix.fluid.KV(mix.vapor.H(zIdx));                           % [W/m/K] Fluid thermal conductivity based on vapor phase
            HDIAM = mix.inputSet.geometry.HDIAM;                           % [m] Hydraulic diameter
            hwallvap = mix.NU(zIdx).*k./HDIAM;                             % [W/m^2/K]
        end
        
        function hwall = HWALL(mix, zIdx)
        %HWALL Wall heat transfer coefficient [W/m^2/K]
        %TODO: Create wall heat transfer model options
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            % Pre-CBT
            hsp = mix.HWALLLIQ(zIdx);                                      % [W/m^2/K] Single-phase liquid
            htp = mix.HWALLTHOM(zIdx);                                     % [W/m^2/K] Two-phase
            hwall = max(hsp,htp);                                          % [W/m^2/K]
            
            % Post CBT
            hwallcbt = mix.HWALLVAP(zIdx);                                 % [W/m^2/K] Single-phase vapor
            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);
            hwall(idxbt) = hwallcbt(idxbt);                                % [W/m^2/K] Post-CBT
        end
        
        function twall = TWALL(mix, zIdx)
        %TWALL Wall temperature [K]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            q = mix.HFLUX(zIdx,:);                                         % [W/m^2]
            hwall = mix.HWALL(zIdx);                                       % [W/m^2/K]
            
            % Pre-CBT
            Tb    = mix.liquid.T(zIdx);                                    % [K] Fluid bulk temperature based on liquid phase
            twall = Tb + q./hwall;                                         % [K]
            
            % Post-CBT
            Tb       = mix.vapor.T(zIdx);                                  % [K] Fluid bulk temperature based on vapor phase
            twallcbt = Tb + q./hwall;                                      % [K]
            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);
            twall(idxbt) = twallcbt(idxbt);                                % [K]
        end
        
    end
    
    %% Vapor transport methods
    methods    
        
        function w = WWALL(mix, zIdx)
        %WWALL Mixture mass flow distribution per wall, based on wall perimeter ratio [kg/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            geom  = mix.inputSet.geometry;
            w = geom.RWALL.*mix.W(zIdx);                                   % [kg/s]
        end

        function ktrelax = KTRELAX(mix, zIdx)
        %KTRELAX Local relaxation time [s]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;

            ktrelax = nan(length(mix.Z),1);                                % [s] Initialize local relaxation time array to 0
            [~,ind] = min(abs(mix.Z-model.KLOC));                          % Find local loss elevation indexes (closest node)
            ktrelax(ind) = model.KTRELAX;                                  % [s] Apply relaxation time
            ktrelax = ktrelax(zIdx);                                       % [s] Restrict to selected input nodes
        end
        
        function [Mcond, Mevap] = MINT(mix, zIdx)
        %MINT Linear interfacial mass transfer rates based on time relaxation [kg/s/m]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            UVeq = mix.vapor.U(zIdx);                                      % [m/s] Approximated equilibrium vapor velocity
            %WVeq = mix.WWALL(zIdx).*min(1,max(0,mix.XEQ(zIdx)));           % [kg/s] Equilibrium vapor mass flow rate per wall (option not used)
            WVeq = mix.WWALL(zIdx).*mix.XEQ(zIdx);                         % [kg/s] Equilibrium vapor mass flow rate per wall
            Wint = WVeq-mix.TRELAX.WV(zIdx,:);                             % [kg/s] Vapor mass deviation from equilibrium

            % NOT USED FOR NOW: transerval transfer across wall regions
            %Wint = sum(Wint,2).*mix.WWALL(zIdx)./mix.W(zIdx);              % [kg/s] Lumped approach required if used with separate transversal transfer (MTRANSV)
            
            Mcond = min(0,Wint./UVeq./mix.RELAXTCOND(zIdx));               % [kg/s/m] Condensation (<0)
            Mevap = max(0,Wint./UVeq./mix.RELAXTEVAP(zIdx));               % [kg/s/m] Evaporation  (>0)
            
            % Restrict to reasonable bounds
            %TODO: Find a more physical bound
            %Mcond = -min(-Mcond,mix.TRELAX.WV(zIdx,:)./mix.DZ);            % [kg/s/m] Condensation (<0)
            %Mevap =  min( Mevap,mix.liquid.W(zIdx)./mix.DZ);               % [kg/s/m] Evaporation  (>0)
            
            %Mcond = -min(-Mcond,mix.TRELAX.WV(zIdx,:)./UVeq./0.03);        % [kg/s/m] Condensation (<0)
            %Mevap =  min( Mevap,mix.liquid.W(zIdx)./UVeq./0.03);           % [kg/s/m] Evaporation  (>0)
        end
        
        function Mintevap = MINTEVAP(mix, zIdx)
        %MINTEVAP Linear interfacial evaporation rates based on time relaxation [kg/s/m]
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            [~, Mintevap] = mix.MINT(zIdx);                                % [kg/s/m]
        end
        
        function Mintcond = MINTCOND(mix, zIdx)
        %MINTCOND Linear interfacial condensation rates based on time relaxation [kg/s/m]
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            Mintcond = mix.MINT(zIdx);                                     % [kg/s/m]
        end
        
        function Mtrans = MTRANSV(mix, zIdx)
        %MTRANSV Linear transversal mass exchange
        % NOT USED FOR NOW
        % Model transverse exchange between wall regions with time relaxation model
        % TODO: Implement also enthalpy exchange and include in total mass/energy echange terms
            
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            UVeq   = mix.vapor.U(zIdx);                                    % [m/s] Approximated equilibrium vapor velocity
            WVeq   = sum(mix.TRELAX.WV(zIdx,:),2).*(mix.WWALL(zIdx)./mix.W(zIdx));                   
            Wtrans = WVeq-mix.TRELAX.WV(zIdx,:);  
            RELAXT = 0.01; % [s]
            
            Mtrans = Wtrans./UVeq./RELAXT;                                 % [kg/s/m]
        end
        
        function walevapratio = WALEVAPRATIO(mix, zIdx)
        %WALEVAPRATIO Wall mass evaporation ratio [-]
        %Liquid mass boiling ratio driven by wall heat flux
        %Set to 0 upstream subcooled boiling, 1 downstream saturated boiling and 0 at CBT
        %TODO: Implement models for the onsets of subcooled and saturated wall boiling, as needed.
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            xsub = model.WBOILINGXSUB;                                     % Equilibrium quality at onset of subcooled wall boiling [-]
            xsat = model.WBOILINGXSAT;                                     % Equilibrium quality at onset of saturated wall boiling [-]
            n    = model.WBOILINGN;                                        % Exponent of wall boiling function [-]
            
            xeq = mix.XEQ(zIdx);                                           % [-]
            walevapratio = min(1,max(0,((xeq-xsub)./(xsat-xsub)).^n));     % [-]
            
            %cbt = mix.CBT(zIdx);                                           % CBT flag
            cbt = mix.CBT(zIdx) | mix.MFBT(zIdx);
            walevapratio = walevapratio.*double(~cbt);                     % [-]
            
            % Correction for transition nodes
            %xeq0 = mix.XEQ(zIdx-1);
            %r = min(1,max(0,(xeq-xsat)./(xeq-xeq0)));
            %wboilingratio = r.*wboilingratio;
        end
        
        function Mwalevap = MWALEVAP(mix, zIdx)
        %MWALEVAP Linear wall mass evaporation (i.e., boiling) rate [kg/s/m]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            
            switch model.INTTRANSH
                case 'BULK'
                    %HFG = mix.vapor.H(zIdx) - mix.liquid.H(zIdx);          % [J/kg] Vapor is generated at bulk enthalpy
                    HFG = mix.TRELAX.HV(zIdx,:) - mix.liquid.H(zIdx);      % [J/kg] Vapor is generated at bulk enthalpy
                case 'SATURATED'
                    HFG = mix.fluid.HG - mix.liquid.H(zIdx);                % [J/kg] Vapor is generated at saturation
            end
            
            Mwall = mix.LHGR(zIdx)./HFG;                                   % [kg/s/m]
            Mwalevap = mix.WALEVAPRATIO(zIdx).*Mwall;                      % [kg/s/m] 
        end
        
        function Mtot = MTOT(mix, zIdx)
        %MTOT Total linear vapor mass transfer rate [kg/s/m]
        %    
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            [Mcond, Mevap] = mix.MINT(zIdx);                               % [kg/s/m]
            Mtot = Mcond + Mevap + mix.MWALEVAP(zIdx);                     % [kg/s/m]
        end
        
        function [Hcond, Hevap] = HINT(mix, zIdx)
        %HINT Linear interfacial heat transfer rate [W/m]
        %    
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            geom = mix.inputSet.geometry;
            
            [Mcond, Mevap] = mix.MINT(zIdx);                               % [kg/s] Interfacial mass flows
            HV = mix.TRELAX.HV(zIdx,:);                                    % [J/kg] Vapor enthalpy
            %HV = repmat(mix.vapor.H(zIdx),1,geom.NWALL);                   % [J/kg] Vapor enthalpy
            
            switch mix.inputSet.model.INTTRANSH
                case 'BULK'
                    Hcond = zeros(length(zIdx),geom.NWALL);                % [W/m]
                    Hevap = Mevap.*(mix.liquid.H(zIdx)-HV);                % [W/m]
                case 'SATURATED'
                    Hcond = Mcond.*(mix.fluid.HG-HV);                      % [W/m]
                    Hevap = Mevap.*(mix.fluid.HF-HV);                      % [W/m]
            end
        end
        
        function Hintevap = HINTEVAP(mix, zIdx)
        %HINTEVAP Linear interfacial heat evaporation rate [W/m]
            
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            [~, Hintevap] = mix.HINT(zIdx);                                % [W/m]
        end
        
        function Hintcond = HINTCOND(mix, zIdx)
        %HINTCOND Linear interfacial heat condensation rate [W/m]
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            Hintcond = mix.HINT(zIdx);                                     % [W/m]
        end
        
        function Hwalevap = HWALEVAP(mix, zIdx)
        %HWALEVAP Linear wall heat evaporation (i.e., boiling)) rate [W/m]
            
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            geom = mix.inputSet.geometry;
            
            switch mix.inputSet.model.INTTRANSH
                case 'BULK'
                    Hwalevap = zeros(length(zIdx),geom.NWALL);             % [W/m]
                case 'SATURATED'
                    Mwalevap = mix.MWALEVAP(zIdx);                         % [kg/s] Linear mass wall boiling rate
                    HV = mix.TRELAX.HV(zIdx,:);                            % [J/kg] Vapor enthalpy
                    Hwalevap = Mwalevap.*(mix.fluid.HG-HV);                % [W/m]
            end
        end
        
        function Hwalheat = HWALHEAT(mix, zIdx)
        %HWALHEAT Linear wall heat to vapor rate [W/m]
        %Set to LHGR beyond CBT
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            %cbt = mix.CBT(zIdx);                                           % CBT flag
            cbt = mix.CBT(zIdx) | mix.MFBT(zIdx);
            Hwalheat = double(cbt).*mix.LHGR(zIdx);                        % [W/m]
        end
        
        function Htot = HTOT(mix, zIdx)
        %HTOT Total linear vapor heat rate [W/m]
        %    
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            [Hcond, Hevap] = mix.HINT(zIdx);
            Htot = Hcond + Hevap + mix.HWALEVAP(zIdx) + mix.HWALHEAT(zIdx); % [W/m]
        end
        
        function Hvtot = HVTOT(mix, zIdx)
        %HVTOT Total linear vapor specific enthalpy transfer [J/kg/m]
        % This term represents the additional energy input to the vapor per unit vapor mass
        % Only the wall lump approach (i.e. same vapor heat input to all walls) is working correctly for now
        % Otherwise, the liquid can become subcooled in post CHF calculations
        % TODO: Fix issue and allow wall specific approach. This can be useful for DNB -> inverted film boiling
        
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            WV   = mix.TRELAX.WV(zIdx,:);                                  % [kg/s] Vapor mass flow rate
            Htot = mix.HTOT(zIdx);                                         % [W/m] Total linear vapor heat rate
            WV   = sum(WV,2); Htot = sum(Htot,2);                          % [kg/s,W/m] Wall lump approach
            
            Hvtot = Htot./WV;                                              % [J/kg/m]
            Hvtot(WV <= 1E-8) = 0;
        end
        
    end
    
    %% Near-wall methods
    methods (Hidden = true)

        function t = NEARWALLTRELAX(mix, zIdx)
        %NEARWALLTRELAX Time relaxation for near-wall energy transfer [s]
        %   This function only retrieves the mix.nearwalltrelax values pre-calculated
        %   when mix.H is set. This is to eliminate the redundant
        %   calculation as a result of frequent function calls. The values
        %   are calculated via mix.NEARWALLTRELAX_CALC()
        %
            if nargin < 2
                t = mix.nearwalltrelax; 
            else
                t = mix.nearwalltrelax(zIdx); 
            end
        end

        function lambda = NEARWALLRATIO(mix)
        %NEARWALLRATIO Near-wall mass flow distribution ratio [-]
        % Should be less than 1 (otherwise NEARWALL.XEQ and XEQ would be equal for azymuthal equal heat flux)
            
            model = mix.inputSet.model;

            lambda = model.NEARWALLRATIO;
        end
        
        function w = WNEARWALL(mix, zIdx)
        %WNEARWALL Near-wall mass flow rate per wall [kg/s]
        %

        if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            w = mix.WWALL(zIdx).*mix.NEARWALLRATIO;
        end

        function area = ANEARWALL(mix)
        %ANEARWALL Near-wall flow area [m^2]
        %

            geom = mix.inputSet.geometry;

            area = mix.NEARWALLRATIO.*geom.RWALL.*geom.AREA;
        end
        
    end
    
    %% Onset of annular flow methods
    methods
        
        function oafx = OAFX(mix, zIdx)
            %OAFX Onset of annular flow equilibrium quality
            %
            
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            HDIAM = mix.inputSet.geometry.HDIAM;
            MFLUX = mix.MFLUX(zIdx);
            
            % Densities
            RHOF = mix.fluid.RHOF;
            RHOG = mix.fluid.RHOG;
            DELTARHO = RHOF-RHOG;
            
            switch model.OAF
                case InputEnums.OAF.WALLIS
                    % Wallis model
                    oafx = (0.6+0.4.*sqrt(model.G*HDIAM*(DELTARHO)*RHOF)./MFLUX)./(0.6+sqrt(RHOF/RHOG)); % [-] Quality at onset of annular flow
                case InputEnums.OAF.WALLIS_SIMP
                    % Simplified Wallis model
                    oafx = sqrt(model.G*HDIAM*(DELTARHO)*RHOG)./MFLUX;
            end
        end
        
        function oafIdx = OAFIDX(mix)
            %OAFIDX Onset of annular flow node
            %

            % Use saved value if it has been calculated already
            if ~isempty(mix.oafidx_const)
                oafIdx = mix.oafidx_const;
                return
            end
            
            oafIdx = find(mix.XEQ <= mix.OAFX, 1, 'last');                 % Find node corresponding to the onset of annular flow
            if isempty(oafIdx), oafIdx = 1; end                            % Most upstream node (1) when pre-annular flow region is not found

            % Save value
            mix.oafidx_const = oafIdx;
        end
        
        function oafz = OAFZ(mix)
        %OAFZ Onset of annular flow elevation
        %
            oafz = mix.Z(mix.OAFIDX);                                      % [m]
        end
        
        function oafwl = OAFWL(mix)
        %OAFWL Liquid mass flow rate at onset of annular flow
        %
            oafwl = mix.liquid.W(mix.OAFIDX);                              % [kg/s]
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
    
    methods (Access = private)
        
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
    
    %% Helper functions
    methods(Access = protected, Hidden = true)

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
                    
                case 'RELAXATION'
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
        
        function CBT_CALC(mix, zIdx)
        %CBT_CALC Helper function to calculate Critical Heat Flux [W/m^2] and CBT flag    
        %TODO: Implement additional CHF correlations
            
            %fld   = mix.fluid;
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;
            
            % CHF
            Pr  = mix.P(end);                                              % [Pa] System pressure
            G   = mix.MFLUX(1:mix(1).NZ);                                  % [kg/m^2/s] Mass flux
            XEQ = mix.XEQ(1:mix(1).NZ);                                    % [-] Equilibrium quality
            D   = geom.HDIAM;                                              % [m] Diameter
            
            switch model.CBT
                case {InputEnums.CBT.NONE,InputEnums.CBT.ELEVATION}
                    chf = nan(mix(1).NZ,geom.NWALL);                       % Skip CHF calculation
                    
                case InputEnums.CBT.BIASI
                    % Biasi correlation
                    % BIASI, L . et al.: A new correlation for round ducts and uniform
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
            
            chf = model.CBTMULT(mix.Z).*chf;                               % Apply user input multiplier
            mix.chf(zIdx,:) = chf(zIdx,:);                                 % [W/m^2] Critical heat flux

            % CBT flag
            switch model.CBT
                case InputEnums.CBT.ELEVATION
                    cbt = mix.Z >= model.CBTELEVATION;                     % CBT indicator based on input elevation

                otherwise
                    cbt = mix.HFLUX(1:mix.NZ,:) > chf;                     % CBT indicator based on CHF value
            end

            %cbt(mix.XEQ>=1,:) = true;                                      % Set cbt to 1 for Xeq >= 1
            
            mix.cbt(zIdx,:) = cbt(zIdx,:);                                 % [-] CBT flag
        end

        function MFBT_CALC(mix, zIdx)

            fld   = mix.fluid;
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            switch model.MFBT
                case InputEnums.MFBT.NONE
                    mfbt = false(length(zIdx),geom.NWALL);
                case InputEnums.MFBT.CONSTANT
                    mfbt = mix.TWALL(zIdx) > fld.TSAT+model.DTMFB;
            end

            mix.mfbt(zIdx,:) = mfbt;
        end
        
        function RHO_CALC(mix, zIdx)
        %RHO_CALC Helper function to calculate density [kg/m^3]
        %
            % Call VF and CHF first
            mix.VF_CALC(zIdx);
            
            vf = mix.VF(zIdx);
            mix.rho(zIdx) = vf.*mix.fluid.RHOV(mix.vapor.H(zIdx)) + ...
                (1-vf).*mix.fluid.RHOL(mix.liquid.H(zIdx));

            mix.CBT_CALC(zIdx);
            mix.MFBT_CALC(zIdx);
            mix.RELAXTEVAP_CALC(zIdx);
            mix.RELAXTCOND_CALC(zIdx);
            mix.NEARWALLTRELAX_CALC(zIdx);
        end
        
        function RELAXTCOND_CALC(mix, zIdx)
        %RELAXTCOND Relaxation time model for wall dependant interfacial condensation
        %TODO: Investigate of this parameter should be walld dependant or not
        %    
        if nargin < 2, zIdx = (1:mix(1).NZ).'; end

        model = mix.inputSet.model;

        switch model.THERMALRELAX
            case InputEnums.THERMALRELAX.QUALITY
                X = model.RELAXX;                                          % [-] Equilibrium quality array
                T = model.RELAXTCOND(1:length(model.RELAXX));              % [-] Corresponding time relaxation

                t = interp1(X,T,mix.XEQ(zIdx),'linear','extrap');          % [s] Interpolated time relaxation
                t(mix.XEQ(zIdx)<X(1))   = T(1);                            % [s] Lower bound limit
                t(mix.XEQ(zIdx)>X(end)) = T(end);                          % [s] Upper bound limit

            case InputEnums.THERMALRELAX.VOID
                d0     = model.RELAXCONDCOEF(1);                           % [m] Reference fluid particle Sauter mean diameter
                n      = model.RELAXCONDCOEF(2);                           % [-] Exponent of phase volumetric ratio
                dvf    = model.RELAXCONDCOEF(3);                           % [-] Small phase volumetric ratio bias to avoid singularity
                ALPHAL = mix.fluid.ALPHAL(mix.liquid.H(zIdx));
                t = d0.^2./ALPHAL./(mix.vapor.VF(zIdx)+dvf).^n;            % [s] Time relaxation
        end

            %geom  = mix.inputSet.geometry;
            %t = repmat(t,1,geom.NWALL);                                    % Expand to all wall
            
            idx = mix.KTRELAX(zIdx)>0;                                     % Index of local perturbations
            t(idx,:) = mix.KTRELAX(zIdx(idx));                             % [s] Time relaxation at local perturbations
            t = max(1E-6,t);
            mix.relaxtcond(zIdx,:) = t;
        end
        
        function t = RELAXTEVAP_CALC(mix, zIdx)
        %RELAXTEVAP Relaxation time model for wall dependant interfacial evaporation
        %TODO: Investigate of this parameter should be walld dependant or not
        %
        if nargin < 2, zIdx = (1:mix(1).NZ).'; end

        model = mix.inputSet.model;

        switch model.THERMALRELAX
            case InputEnums.THERMALRELAX.QUALITY
                X = model.RELAXX;                                          % [-] Equilibrium quality array
                T = model.RELAXTEVAP(1:length(model.RELAXX));              % [-] Corresponding time relaxation

                t = interp1(X,T,mix.XEQ(zIdx),'linear','extrap');          % [s] Interpolated time relaxation
                t(mix.XEQ(zIdx)<X(1))   = T(1);                            % [s] Lower bound limit
                t(mix.XEQ(zIdx)>X(end)) = T(end);                          % [s] Upper bound limit

            case InputEnums.THERMALRELAX.VOID
                d0     = model.RELAXEVAPCOEF(1);                           % [m] Reference fluid particle Sauter mean diameter
                n      = model.RELAXEVAPCOEF(2);                           % [-] Exponent of phase volumetric ratio
                dvf    = model.RELAXEVAPCOEF(3);                           % [-] Small phase volumetric ratio bias to avoid singularity
                ALPHAV = mix.fluid.ALPHAV(mix.vapor.H(zIdx));
                t = d0.^2./ALPHAV./(mix.liquid.VF(zIdx)+dvf).^n;           % [s] Time relaxation
        end

            idx = mix.KTRELAX(zIdx)>0;                                     % Index of local perturbations
            t(idx,:) = mix.KTRELAX(zIdx(idx));                             % [s] Time relaxation at local perturbations
            t = max(1E-6,t);
            mix.relaxtevap(zIdx,:) = t;
        end

        function NEARWALLTRELAX_CALC(mix, zIdx)
        %NEARWALLTRELAX Relaxation time model for wall dependant near-wall equilibrium quality
        %    
        if nargin < 2, zIdx = (1:mix(1).NZ).'; end

        model = mix.inputSet.model;

        switch model.NEARWALLRELAX
            case InputEnums.NEARWALLRELAX.QUALITY
                X = model.NEARWALLRELAXX;                                  % [-] Equilibrium quality array
                T = model.NEARWALLRELAXT(1:length(model.NEARWALLRELAXX));  % [-] Corresponding time relaxation

                t = interp1(X,T,mix.XEQ(zIdx),'linear','extrap');          % [s] Interpolated time relaxation
                t(mix.XEQ(zIdx)<X(1))   = T(1);                            % [s] Lower bound limit
                t(mix.XEQ(zIdx)>X(end)) = T(end);                          % [s] Upper bound limit

            case InputEnums.NEARWALLRELAX.VOID
                d0     = model.NEARWALLRELAXCOEF(1);                       % [m] Reference fluid particle Sauter mean diameter
                n      = model.NEARWALLRELAXCOEF(2);                       % [-] Exponent of phase volumetric ratio
                dvf    = model.NEARWALLRELAXCOEF(3);                       % [-] Small phase volumetric ratio bias to avoid singularity
                ALPHAL = mix.fluid.ALPHAL(mix.liquid.H(zIdx));
                t = d0.^2./ALPHAL./(mix.vapor.VF(zIdx)+dvf).^n;            % [s] Time relaxation
        end
            
            idx = mix.KTRELAX(zIdx)>0;                                     % Index of local perturbations
            t(idx,:) = mix.KTRELAX(zIdx(idx));                             % [s] Time relaxation at local perturbations
            t = max(1E-6,t);
            mix.nearwalltrelax(zIdx,:) = t;
        end
        
    end
    
     %% Other methods
    methods(Access = protected, Hidden = true)

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
        
    end
    
end

