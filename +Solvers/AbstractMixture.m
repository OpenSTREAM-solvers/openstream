classdef (Abstract) AbstractMixture < Solvers.AbstractField
    %ABSTRACTFIELD defines all methods shared by all field class definitions across all
    %solvers
    %
    %   TODO: Detailed explanations

    properties (Abstract, SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                                                % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                                                % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                                                % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % Saved detailed pressure drops
        DPSUM        (1,1) struct                                                                 % Saved detailed cumulative pressure drops
        ACC          (1,1) struct                                                                 % Saved detailed acceleration terms

        % Phases
        liquid
        vapor
    end
    
    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
        
        % Iteration properties
        ITR
    end

    properties (Abstract, Access=protected)
        
        mflux        (:,1) double  {mustBeNumeric}                                              % [kg/m^2-s] Mass flux
        xeq          (:,1) double  {mustBeNumeric}                                              % [-] Equilibrium quality
        x            (:,1) double  {mustBeNumeric}                                              % [-] Vapor quality
        vf           (:,1) double  {mustBeNumeric}                                              % [-] Void fraction
        chf          (:,:) double  {mustBeNumeric}                                              % [-] Critical Heat Flux
        cbt          (:,:) logical                                                              % [-] Critical Boiling Transition flag
        rho          (:,1) double  {mustBeNumeric}                                              % [kg/m^3] Mixture density
        oafidx_const       double  {mustBeNumeric}                                              % [-] Solved index for onset of annular flow
        sigm_const   (:,1) double  {mustBeNumeric}                                              % [-] Solved sigmoid fnc value    
    end

    properties (Abstract, SetAccess=?Solvers.AbstractSolver, GetAccess={?Solvers.AbstractField, ?Solvers.AbstractPhase})
        
        DZ           (1,1) double  {mustBeNumeric}                                              % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
    end


    %% Methods
    methods

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
        %CBT Critical Boiling Transition flag [-], wall dependant
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
    
    methods (Access = protected)
        
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
            idxcbt = mix.CBT(zIdx);
            hwall(idxcbt) = hwallcbt(idxcbt);                              % [W/m^2/K] Post-CBT
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
            idxcbt = mix.CBT(zIdx);
            twall(idxcbt) = twallcbt(idxcbt);                              % [K]
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
            
            vf = mix.VF(zIdx);
            mix.rho(zIdx) = vf.*mix.fluid.RHOV(mix.vapor.H(zIdx)) + ...
                (1-vf).*mix.fluid.RHOL(mix.liquid.H(zIdx));    
        end

    end

    methods (Abstract, Access = protected)

        VF_CALC(obj, zIdx)

    end

end

