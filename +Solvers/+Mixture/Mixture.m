classdef Mixture < Solvers.AbstractMixture
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    % Inherited properties
    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % Flow properties
        W                                                                  = 1.                   % [kg/s] Mass flow rate
        P                                                                  = 7E6                  % [Pa] Pressure
        H                                                                  = 1E6                  % [J/kg] Enthalpy
        DP                                                                                        % Saved detailed pressure drops
        DPSUM                                                                                     % Saved detailed cumulative pressure drops
        ACC                                                                                       % Saved detailed acceleration terms
        
        TRELAX       (1,1) struct                                                                 % Time relaxation terms                                                                                    % Time relaxation terms

        % Phases
        liquid
        vapor
    end

    % Concrete class properties
    properties (Access=protected)
        
        mflux                                                              = 1.                 % [kg/m^2-s] Mass flux
        xeq                                                                = 1.                 % [-] Equilibrium quality
        x                                                                  = 1.                 % [-] Vapor quality
        vf                                                                 = 1.                 % [-] Void fraction
        chf                                                                                     % [-] Critical Heat Flux
        cbt                                                                                     % [-] Critical Boiling Transition flag
        rho                                                                = 1.                 % [kg/m^3] Mixture density
        oafidx_const                                                       = []                 % [-] Solved index for onset of annular flow
        sigm_const                                                         = []                 % [-] Solved sigmoid fnc value
        
        relaxtevap   (:,:) double  {mustBeNumeric}                                              % [-] Time relaxation for interfacial evaporation
        relaxtcond   (:,:) double  {mustBeNumeric}                                              % [-] Time relaxation for interfacal condensation
    
    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess={?Solvers.AbstractField, ?Solvers.AbstractPhase})
        
        DZ                                                                 = 0                    % [m] Axial step size
        inputSet                   
        fluid                      
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
            mix.flowProperties = {'TRELAX','W','P','H','DP','DPSUM','ACC','ITR'};
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
        
        
    end
    
    
    
    %% Near-wall methods
    methods (Hidden = true)
        
        function w = WNEARWALL(mix, zIdx)
        %WNEARWALL Near-wall mass flow distribution per wall [kg/s]
        %TODO: WNEARWALL should correspond to a near wall region (otherwise TRELAX.XEQ and XEQ would be equal for azymuthal equal heat flux)
        %      Arbitrary division by 2 for now

        if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            w = mix.WWALL(zIdx)./1;                                        % [kg/s]
        end
        
        function wvth = WVTH(mix, zIdx, WVTHold, Uold)
        %WVTH Near-eall time relaxed modified (thermodynamic) vapor mass flow rate [kg/s]
        %Use for direct substitution scheme in solver
        %Time relaxation based on condensation for simplicity, since mainly targeted for pre-CBT applications 
        %Part of the heat input (to the liquid) is currently missing leading to heat inptu oncinsistentcy below boiling
        %TODO: Implement implicit scheme to allow different time relaxation for condensation and evaporation
        %TODO: Change to an (equivalent) energy equation instead, is the near wall approach necessary?
 
            WNW      = mix.WNEARWALL(zIdx);                                % [kg/s] Mass flow distribution per wall
            UV       = mix.vapor.U(zIdx);                                  % [m/s] Vapor velocity
            MWALEVAP = mix.MWALEVAP(zIdx);                                 % [kg/s/m] Linear mass wall evaporation rate
            TRELAXL  = mix.RELAXTCOND(zIdx);                               % [s] Time relaxation model
            
            wvth = (mix.TRELAX.WVTH(zIdx-1,:) + (WVTHold./Uold./mix.DT ...
                + mix.XEQ(zIdx).*WNW./UV./TRELAXL + MWALEVAP).*mix.DZ) ...
                ./(1 + mix.DZ./UV.*(1/mix.DT + 1./TRELAXL));               % [kg/s] Update relaxed modified vapor mass flow
        end
        
    end

    %% Relaxation methods
    methods
        
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
    
    %% Vapor transport methods
    methods
        
        function w = WWALL(mix, zIdx)
        %WWALL Mixture mass flow distribution per wall, based on wall perimeter ratio [kg/s]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            geom  = mix.inputSet.geometry;
            w = geom.RWALL.*mix.W(zIdx);                                   % [kg/s]
        end
        
        function [Mcond, Mevap] = MINT(mix, zIdx)
        %MINT Linear interfacial mass transfer rates based on time relaxation [kg/s/m]
        %
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            UVeq = mix.vapor.U(zIdx);                                      % [m/s] Approximated equilibrium vapor velocity
            %WVeq = mix.WWALL(zIdx).*max(0,mix.XEQ(zIdx));                  % [kg/s] Equilibrium vapor mass flow rate per wall
            WVeq = mix.WWALL(zIdx).*mix.XEQ(zIdx);                         % [kg/s] Equilibrium vapor mass flow rate per wall
            Wint = WVeq-mix.TRELAX.WV(zIdx,:);                             % [kg/s] Vapor mass deviation from equilibrium

            Wint = sum(Wint,2).*mix.WWALL(zIdx)./mix.W(zIdx);              % [kg/s] Lumped approach required when no transversal transfer is considered
            
            Mcond = min(0,Wint./UVeq./mix.RELAXTCOND(zIdx));               % [kg/s/m] Condensation (<0)
            Mevap = max(0,Wint./UVeq./mix.RELAXTEVAP(zIdx));               % [kg/s/m] Evaporation  (>0)
            
            % Restrict to reasonable bounds
            %TODO: Find a more physical bound
            Mcond = -min(-Mcond,mix.TRELAX.WV(zIdx,:)./mix.DZ);            % [kg/s/m] Condensation (<0)
            Mevap =  min( Mevap,mix.liquid.W(zIdx)./mix.DZ);               % [kg/s/m] Evaporation  (>0)
            
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
        % Model transverse exchange between wall regions with time relaxation model
        % TODO: Note used for now, implement also enthalpy exchange and include in total mass/energy echange terms
            
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
            
            cbt = mix.CBT(zIdx);                                           % CBT flag
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
                    HFG = mix.fluid.HG - mix.liquid.H(zIdx);               % [J/kg] Vapor is generated at saturation
            end
            
            Mwalevap = mix.WALEVAPRATIO(zIdx).*mix.LHGR(zIdx)./HFG;        % [kg/s/m] 
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




    end
    
    %% Helper functions
    methods(Access = protected, Hidden = true)

        % function MFLUX_CALC(mix, zIdx)
        % %MFLUX_CALC Helper function to calculate mass flux [kg/m^2-s]
        % %
        % 
        %     mix.mflux(zIdx) = mix.W(zIdx)./mix.inputSet.geometry.AREA;
        % end
        % 
        % function XEQ_CALC(mix, zIdx)
        % %XEQ_CALC Helper function to calculate equilibrium quality [-]
        % %  
        %     mix.xeq(zIdx) = (mix.H(zIdx)-mix.fluid.HF)./ mix.fluid.HFG;
        % end

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
        
        function CHF_CALC(mix, zIdx)
        %CHF_CALC Helper function to calculate Critical Heat Flux [W/m^2] and CBT flag    
        %TODO: Implement additional CHF correlations
        %      Investigate potential rewetting after CBT, this would require access to CBT and Twall at previous time step
            
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
            
            chf = model.CBTMULT(mix.Z).*chf;                               % Apply user input multiplier
            
            % CBT flag
            cbt = mix.HFLUX(1:mix.NZ,:) > chf;                             % CBT indicator
            
            %TODO: Rewetting model and behavior downstream
            %cbt = cumsum(cbt,1) >= 1;                                      % No rewetting downstream CBT
            %cbt(mix.XEQ>=1,:) = true;                                      % Set cbt to 1 for Xeq >= 1
            
            mix.chf(zIdx,:) = chf(zIdx,:);                                 % [W/m^2] Critical heat flux
            mix.cbt(zIdx,:) = cbt(zIdx,:);                                 % [-] CBT flag
        end
        
        function RHO_CALC(mix, zIdx)
        %RHO_CALC Helper function to calculate density [kg/m^3]
        %
            % Call VF and CHF first
            mix.VF_CALC(zIdx);
            mix.CHF_CALC(zIdx);
            mix.RELAXTEVAP_CALC(zIdx);
            mix.RELAXTCOND_CALC(zIdx);
            
            vf = mix.VF(zIdx);
            mix.rho(zIdx) = vf.*mix.fluid.RHOV(mix.vapor.H(zIdx)) + ...
                (1-vf).*mix.fluid.RHOL(mix.liquid.H(zIdx));    
        end
        
        function RELAXTCOND_CALC(mix, zIdx)
        %RELAXTCOND Relaxation time model for wall dependant interfacial condensation
        %TODO: Investigate of this parameter should be walld dependant or not
        %TODO: interp1 takes time, should be treated like the void fraction, etc...
        %    
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            X = model.RELAXX;                                              % [-] Equilibrium quality array
            T = model.RELAXTCOND(1:length(model.RELAXX));                  % [-] Corresponding time relaxation

            t = interp1(X,T,mix.XEQ(zIdx),'linear','extrap');              % [s] Interpolated time relaxation
            t(mix.XEQ(zIdx)<X(1))   = T(1);                                % [s] Lower bound limit
            t(mix.XEQ(zIdx)>X(end)) = T(end);                              % [s] Upper bound limit
            
            %geom  = mix.inputSet.geometry;
            %t = repmat(t,1,geom.NWALL);                                    % Expand to all wall
            
            t(mix.KLOSS(zIdx)>0,:) = model.RELAXTCOND(end);                % [s] Time relaxation ot local perturbations
            t = max(1E-6,t);
            mix.relaxtcond(zIdx,:) = t;
        end
        
        function t = RELAXTEVAP_CALC(mix, zIdx)
        %RELAXTEVAP Relaxation time model for wall dependant interfacial evaporation
        %TODO: Investigate of this parameter should be walld dependant or not
        %TODO: interp1 takes time, should be treated like the void fraction, etc...
        %    
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            
            model = mix.inputSet.model;
            X = model.RELAXX;                                              % [-] Equilibrium quality array
            T = model.RELAXTEVAP(1:length(model.RELAXX));                  % [-] Corresponding time relaxation

            t = interp1(X,T,mix.XEQ(zIdx),'linear','extrap');              % [s] Interpolated time relaxation
            t(mix.XEQ(zIdx)<X(1))   = T(1);                                % [s] Lower bound limit
            t(mix.XEQ(zIdx)>X(end)) = T(end);                              % [s] Upper bound limit
           
            t(mix.KLOSS(zIdx)>0,:) = model.RELAXTEVAP(end);                % [s] Time relaxation ot local perturbations
            t = max(1E-6,t);
            mix.relaxtevap(zIdx,:) = t;
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

