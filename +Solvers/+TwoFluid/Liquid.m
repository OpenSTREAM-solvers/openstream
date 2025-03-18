classdef Liquid < Solvers.AbstractField
    %LIQUID Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            (:,1) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy

        % Iteration properties
        ITR

        % Mixture
        mix          (1,1)        {isa(mix, 'Solvers.Mixture.Mixture')}   = NaN

     end

     properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
     end
    
     
    
    methods
        function liquid = Liquid(inputSet, fluid)
            %liquid Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin > 0
                % Store inputSet as object property
                liquid.inputSet = inputSet;
                liquid.fluid  = fluid;
            end

            % Overload copyable properties
            %liquid.flowProperties = {'W','U','H'};
        end
        
        function x = X(liquid,zIdx)
        %X Liquid mass fraction
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            x = liquid.W(zIdx)./liquid.mix.W(zIdx);                        % [-]
        end
        
        function jl = JL(liquid,zIdx)
        %JL Liquid superficial velocity
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            AREA = liquid.inputSet.geometry.AREA;                          % [m^2]
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3]
            
            jl = liquid.W(zIdx)./RHOL./AREA;                               % [m/s]
        end
        
        function s = S(liquid,vapor,zIdx)
        %S Phase slip ratio
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            s = vapor.U(zIdx)./liquid.U(zIdx);                             % [-]
        end
        
        function vf = VF(liquid,vapor,zIdx)
        %VF Volumetric liquid fraction
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3]
            RHOV = liquid.fluid.RHOV(vapor.H(zIdx));                       % [kg/m^3]
            
            vf = 1 - max(0,vapor.W(zIdx)./(liquid.S(vapor,zIdx).*liquid.W(zIdx).*RHOV./RHOL+vapor.W(zIdx)));
        end
        
        function area = AREA(liquid,vapor,zIdx)
        %AREA liquid cross-section area
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            AREA = liquid.inputSet.geometry.AREA;                          % [m^2] Area
            
            area = liquid.VF(vapor,zIdx).*AREA;                            % [m^2]
        end
        
        function rho = RHO2FLUID(liquid,vapor,zIdx)
        %RHOMIX Two-phase density
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            RHOV = liquid.fluid.RHOV(vapor.H(zIdx));
            VF   = 1-liquid.VF(vapor,zIdx);
            
            rho = (1-VF).*RHOL + VF.*RHOV;                                 % [-]
        end
        
        function u = USLIP(liquid,vapor,zIdx)
        %VELOCITY Liquid velocity based on input phase slip
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
           
            AREA = liquid.inputSet.geometry.AREA;                          % [m^2] Area
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            RHOV = liquid.fluid.RHOV(vapor.H(zIdx));
            %VF   = 1-liquid.VF(vapor,zIdx);
            S    = liquid.inputSet.model.SLIP;
            VF   = max(0,vapor.W(zIdx)./(S.*liquid.W(zIdx).*RHOV./RHOL+vapor.W(zIdx))); % [-] Void fraction based on phase slip model
            
            %u = liquid.W(zIdx)./RHOL./liquid.AREA(vapor,zIdx);
            u = liquid.W2FLUID(vapor,zIdx)./AREA./(RHOL.*(1-VF)+RHOV.*VF.*S); % [m/s] (Most robust option)
            %u = liquid.W(zIdx)./RHOL./AREA./(1-VF);
        end
        
        function re = RE(liquid,zIdx)
        %RE Reynolds number [-]
            
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;                        % [m] Perimeter
            MUL = liquid.fluid.MUL(liquid.H(zIdx));                        % [Pa.s]
            
            re = 4.*abs(liquid.W(zIdx))./MUL./PERIM;                       % [-]
        end
        
        function rev = REV(liquid,vapor,zIdx)
        %REG Dispersed vapor Reynolds number
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            MUL  = liquid.fluid.MUL(liquid.H(zIdx));
            %MU  = MUL./(liquid.VF(vapor,zIdx));               % mixture viscosity
            %VR = liquid.VF(vapor,zIdx).*liquid.VR(vapor,zIdx);
            VR = liquid.VR(vapor,zIdx);
            
            rev = RHOL.*abs(VR).*liquid.L(zIdx)./MUL; % [-]
        end

        function rel = REL(liquid,vapor,zIdx)
        %REL Dispersed liquid Reynolds number
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            RHOV = liquid.fluid.RHOV(liquid.H(zIdx));
            MUV  = liquid.fluid.MUV(liquid.H(zIdx));  

            VR = liquid.VR(vapor,zIdx);
            
            rel = RHOV.*abs(VR).*liquid.L(zIdx)./MUV; % [-]
        end

        function visc = VISCV(liquid,zIdx)
        %VISC viscosity number dispersed gas
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            RHOV = liquid.fluid.RHOV(liquid.H(zIdx));
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            MUL  = liquid.fluid.MUL(liquid.H(zIdx));
            SIGMA = liquid.fluid.SIGMA;  
            G = liquid.inputSet.model.G;
            Diff_RHO = abs(RHOL-RHOV);
            
            visc = MUL./sqrt(RHOL.*SIGMA.*sqrt(G.*SIGMA./(Diff_RHO))); % [-]
        end

        function visc = VISCL(liquid,zIdx)
        %VISC viscosity number dispersed liquid
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            RHOV = liquid.fluid.RHOV(liquid.H(zIdx));
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            MUV  = liquid.fluid.MUV(liquid.H(zIdx));
            SIGMA = liquid.fluid.SIGMA;  
            G = liquid.inputSet.model.G;
            Diff_RHO = abs(RHOL-RHOV);
            
            visc = MUV./sqrt(RHOV.*SIGMA.*sqrt(G.*SIGMA./(Diff_RHO))); % [-]
        end
        
         function t = T(liquid,zIdx)
            %T Liquid temperature
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            t = liquid.fluid.T(liquid.H(zIdx));                            % [K]
        end
        
        function xtr_scb = XTR_SCB(liquid)
            %XTR_SCB Quality at onset of subcooled boiling transition 
            % TODO: Very simplistic transition criteria for now, more realistic models to be implemented later
            
            xtr_scb = -0.1;%-0.2 
        end
        
        function xtr_scb = XTR_SAT(liquid)
            %XTR_SAT Quality at end of subcooled boiling transition 
            
            xtr_scb = 0.0;
        end
        
        function xtr_itm = XTR_ITM(liquid)
            %XTR_ITM Quality at onset of intermediate region 
            % TODO: Very simplistic transition criteria for now, more realistic models to be implemented later
            
            xtr_itm = 0.1;
        end
        
        function xtr_ann = XTR_ANN(liquid)
            %XTR_ANN Quality at onset of annular flow region 
            % TODO: Very simplistic transition criteria for now, more realistic models to be implemented later (e.g. Wallis model)
            
            xtr_ann = 0.1;% set to a quality close to where liquid and vapor void fractions are equal, was previously se to 0.3;
        end
        
        function xtr_cbt = XTR_CBT(liquid)
            %XTR_CBT Quality at CBT 
            % TODO: Very simplistic transition criteria for now, more realistic models to be implemented later
            
            xtr_cbt = 0.88;%0.7
        end
        
        function flowregime = FLOWREGIME(liquid,zIdx)
        %FLOWREGIME Categorical two-phase flow regimes
        % Note: Very slow! Calls to this method should be limited
            
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            XEQ = liquid.mix.XEQ(zIdx);                                    % [-]
            
            import Solvers.TwoFluid.REGIMES;

            id = zeros(liquid.NZ,1);                       % Liquid (initialization)
            id(XEQ > liquid.XTR_SCB) = 1;           % bubbly_subcooled
            id(XEQ > liquid.XTR_SAT) = 2;           % bubbly_saturated
            %id(XEQ > liquid.XTR_ITM) = 3;               % intermediate
            %id(XEQ > liquid.XTR_ANN) = 4;                    % annular
            %id(XEQ > liquid.XTR_CBT) = 5; 
            
            flowregime = REGIMES(id);

            % id = repmat(REGIMES.LIQUID,liquid.NZ,1);                       % Liquid (initialization)
            % id(XEQ > liquid.XTR_SCB) = REGIMES.BUBBLY_SUBCOOLED;           % bubbly_subcooled
            % id(XEQ > liquid.XTR_SAT) = REGIMES.BUBBLY_SATURATED;           % bubbly_saturated
            % id(XEQ > liquid.XTR_ITM) = REGIMES.INTERMEDIATE;               % intermediate
            % id(XEQ > liquid.XTR_ANN) = REGIMES.ANNULAR;                    % annular
            % id(XEQ > liquid.XTR_CBT) = REGIMES.DFFB; 
            % 
            % flowregime = id;

            % id = zeros(liquid.NZ,1);                                       % Liquid (initialization)
            % id(XEQ > liquid.XTR_SCB) = 1;                                  % bubbly_subcooled
            % id(XEQ > liquid.XTR_SAT) = 2;                                  % bubbly_saturated
            % id(XEQ > liquid.XTR_ITM) = 3;                                  % intermediate
            % id(XEQ > liquid.XTR_ANN) = 4;                                  % annular
            % id(XEQ > liquid.XTR_CBT) = 5;                                 
            % 
            % flowregime = categorical(id,[0 1 2 3 4 5],{'liquid','bubbly_subcooled','bubbly_saturated','intermediate','annular','dffb'});  
        end
        
        function l = L(liquid,zIdx)
        %L Interfacial length scale (e.g. bubble or drop diameter)
        % TODO: Simplistic model for now
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            model = liquid.inputSet.model;
            
            switch model.INTLENGTH
                case 'CONSTANT'
                    l = model.INTLENGTHCST.*ones(size(zIdx));              % [m]
            end
        end

        function area = PAREA(liquid,zIdx)
        %PAREA Projected area of typical particle (e.g. bubble or drop)
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            model = liquid.inputSet.model;
            
            switch model.INTLENGTH
                case 'CONSTANT'
                    l = model.INTLENGTHCST.*ones(size(zIdx));              % [m]
                    area = pi*l.^2/4;                                      % [m^2]
            end
        end

        function vol = PVOL(liquid,zIdx)
        %PVOL Volume of typical particle (e.g. bubble or drop)
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            model = liquid.inputSet.model;
            
            switch model.INTLENGTH
                case 'CONSTANT'
                    l = model.INTLENGTHCST.*ones(size(zIdx));              % [m]
                    vol = pi*l.^3/6;                                       % [m^3]
            end
        end
                
        function ai = AI(liquid,vapor,zIdx)
        %AI Volumetric interfacial area
        % TODO: Simplistic model for now, more realistic models to be implemented later, including a transport equation (i.e., AI will become a primary parameter since resolved by the solver)
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            import Solvers.TwoFluid.REGIMES
            
            flowregime = liquid.FLOWREGIME(zIdx);
            model = liquid.inputSet.model;

            switch model.INTAREA
                case 'DISPGAS2DISPLIQ'
                    
                    % Dispersed gas
                    %Idv = ismember(flowregime,{'liquid','bubbly_subcooled','bubbly_saturated','intermediate'});
                    aiv = 6*vapor.VF(liquid,zIdx)./liquid.L(zIdx);                 % [m^-1] Dispersed gas
                    ai  = aiv;                                                     % [m^-1]
                    
                    %Dispersed liquid
                    %Idl = ismember(flowregime,{'annular','dffb'});
                    Idl = ismember(flowregime,[REGIMES.ANNULAR,REGIMES.DFFB]);
                    ail = 6*liquid.VF(vapor,zIdx)./liquid.L(zIdx);                 % [m^-1] Dispersed liquid
                    ai(Idl) = ail(Idl);                                            % [m^-1]
                        
            end
            ai = max(0,ai);                                                % [m^-1]

        end
        
        function k_LIQ = WALLQCOEF(liquid,zIdx)
        %WALLQCOEF Wall heat input to liquid partitioning
            
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ = liquid.mix.XEQ;                                          % [-]
            
            % Liquid/gas wall heat partitioning
            k_LIQ = [1; diff(min(liquid.XTR_CBT,XEQ))./diff(XEQ)];         % [-] Wall heat input to liquid below XTR_CBT, to gas above XTR_CPT
            k_LIQ = k_LIQ(zIdx);                                           % [-]
        end
        
        function k_BOIL = WALLBOILCOEF(liquid,zIdx)
        %WALLBOILCOEF  Wall heat input to liquid boiling
        %TODO: Decide on which options to select or create model options
            
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ = liquid.mix.XEQ;                                          % [-]
            
            % Liquid/boiling wall heat partitioning
            k_BOIL = [0; diff(max(liquid.XTR_SCB,XEQ))./diff(XEQ)];        % [-] Liquid below XTR_SCB, boiling above XTR_SCB
            x = linspace(liquid.XTR_SCB,liquid.XTR_SAT,10);                % [-]

            model = liquid.inputSet.model;
            
            switch model.BOILCOEF
                case 'LINEAR'
                    k_BOIL = max(min(interp1(x,linspace(0,1,10),XEQ,'linear','extrap'),k_BOIL),0);                                 % [-] Linear      interpolation between XTR_SCB and XTR_SCB
                case 'QUADRATIC'
                    k_BOIL = max(min(interp1(x,linspace(0,1,10).^2,XEQ,'linear','extrap'),k_BOIL),0);                                % [-] Quadratic   interpolation between XTR_SCB and XTR_SCB
                case 'EXPONENTIAL'
                    k_BOIL = max(min(interp1(x,exp((liquid.XTR_SAT-x)./(liquid.XTR_SCB-1E-6-x)),XEQ,'linear','extrap'),k_BOIL),0); % [-] Exponential interpolation between XTR_SCB and XTR_SCB
            end

            k_BOIL = k_BOIL(zIdx);                                         % [-]
        end
        
        function intnu = INTNUV(liquid,vapor,zIdx)
        %INTNUV Interfacial Nusselt number for dispersed gas
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            model = liquid.inputSet.model;
            
            switch model.INTNU
                case 'CONSTANT'
                    intnu = model.INTNUVCST.*ones(size(zIdx));             % [-]
                case 'RANZMARSHALL'
                    Re = liquid.REV(vapor,zIdx);                           % [-]
                    Pr = liquid.fluid.PRANDTLL(liquid.H(zIdx));            % [-]
                    
                    coef = model.RANZMARSHALLVCST;                         % [-] Ranz-Marshall coefficients
                    intnu = coef(1) + coef(2).*Re.^coef(3).*Pr.^coef(4);   % [-]
                case 'RELAXATION'
                    % TODO: Calculate equivalent interfacial Nusselt number (for display only)
            end
        end
        
        function hflux = HFLUX(liquid,zIdx)
        %HFLUX Wall heat flux to liquid phase
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            hflux = liquid.WALLQCOEF(zIdx).*liquid.mix.HFLUX(zIdx);        % [W/m^2] 
        end

        function wallmflux = WALLMFLUX(liquid,vapor,zIdx)
        %WALLMFLUX Wall evaporation mass flux
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            k_EVAP = liquid.WALLBOILCOEF(zIdx);                            % [-] Liquid mass evaporation split
            
            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    wallmflux = -k_EVAP.*liquid.HFLUX(zIdx)./(vapor.H(zIdx)-liquid.H(zIdx));   % [kg/s/m^2]
                case 'SATURATED'
                    wallmflux = -k_EVAP.*liquid.HFLUX(zIdx)./(liquid.fluid.HG-liquid.H(zIdx)); % [kg/s/m^2] Heat flux warms up liquid first (if subcooled) before evaporation
            end
        end
        
        function [inthflux_evap, inthflux_cond] = INTHFLUX(liquid,vapor,zIdx)
        %INTHFLUX Interfacial heat flux (> 0 to liquid phase)
        %TODO: simple models for now, should be improved
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            import Solvers.TwoFluid.REGIMES

            flowregime  = liquid.FLOWREGIME(zIdx);
            L   = liquid.L(zIdx);                                          % [m] Interfacial length scale

            % Dispersed gas
            %Idg = ismember(flowregime,{'liquid','bubbly_subcooled','bubbly_saturated','intermediate'});
            INTNUV = liquid.INTNUV(vapor,zIdx);                            % [-] Interfacial Nusselt number
            KL = liquid.fluid.KL(liquid.H(zIdx));                          % [W/m/K] Liquid conductivity <- assume vapor phase is dispersed
            hv   = INTNUV.*KL./L; hv(L <= 1E-6) = 0;                       % [W/m^2/K] Interfacial heat transfer coefficient
            h = hv;                                                        % [W/m^2/K]
            
            % Dispersed liquid
            Idl = ismember(flowregime,[REGIMES.ANNULAR,REGIMES.DFFB]);
            INTNUL = vapor.INTNUL(liquid,zIdx);                            % [-] Interfacial Nusselt number
            KV = vapor.fluid.KV(vapor.H(zIdx));                            % [W/m/K] Vapor conductivity  <- assume liquid phase is dispersed
            hl   = INTNUL.*KV./L; hl(L <= 1E-6) = 0;                       % [W/m^2/K] Interfacial heat transfer coefficient
            h(Idl) = hl(Idl);                                              % [W/m^2/K]
            %h(liquid.VF(vapor,zIdx)<0.5) = hl(liquid.VF(vapor,zIdx)<0.5);                                              % [W/m^2/K]
            h = max(0,h);                                                  % [W/m^2/K]
            
            TSAT  = liquid.fluid.TSAT;                                     % [K] Saturated fluid temperature
            inthflux_evap = h.*(vapor.T(zIdx)-TSAT);                       % [W/m^2] Evaporation heat flux
            inthflux_cond = h.*(TSAT-liquid.T(zIdx));                      % [W/m^2] Condensation heat flux
        end

        function [Mcond, Mevap] = INTMFLOW(liquid,vapor,zIdx)
        %INTMMFLOW interfacial condensation and evaporation mass flow
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            model = liquid.inputSet.model;
            
            switch model.INTNU
                case {'CONSTANT','RANZMARSHALL'}
                    
                    [inthflux_evap, inthflux_cond] = liquid.INTHFLUX(vapor,zIdx);  % [W/m^2] Interfacial heat flux
                    
                    switch liquid.inputSet.model.INTTRANSH
                        case 'BULK'
                            Mcond_flux = inthflux_cond./(vapor.H(zIdx)-liquid.H(zIdx));   % [kg/s/m^2] Condensation mass flux
                            Mevap_flux = inthflux_evap./(vapor.H(zIdx)-liquid.H(zIdx));   % [kg/s/m^2] Evaporation mass flux
                        case 'SATURATED'
                            Mcond_flux = inthflux_cond./(liquid.fluid.HG-liquid.H(zIdx)); % [kg/s/m^2] Condensation mass flux
                            Mevap_flux = inthflux_evap./(vapor.H(zIdx)-liquid.fluid.HF);  % [kg/s/m^2] Evaporation mass flux
                    end
                    
                    AREA = liquid.inputSet.geometry.AREA;                  % [m^2] Cross-section area
                    Mcond =  AREA.*liquid.AI(vapor,zIdx).*Mcond_flux;      % [kg/s/m] Condensation mass transfer
                    Mevap = -AREA.*liquid.AI(vapor,zIdx).*Mevap_flux;      % [kg/s/m] Evaporation mass transfer
                    
                case 'RELAXATION'
                    %TODO: call equilibrium velocity model when available
                    %UEQ = liquid.mix.liquid.U(zIdx);                       % [m/s] Equilibrium velocity
                    UEQ = liquid.U(zIdx);                                  % [m/s] Approximation
                    WEQ = liquid.mix.W(zIdx).*(1-max(0,liquid.mix.XEQ(zIdx))); % [kg/s] Equilibrium liquid mass flow rate
                    
                    Mcond = max(0,(WEQ./UEQ-liquid.W(zIdx)./liquid.U(zIdx)))/model.RELAXTCOND; % [kg/m/s] Condensation mass transfer
                    Mevap = min(0,(WEQ./UEQ-liquid.W(zIdx)./liquid.U(zIdx)))/model.RELAXTEVAP; % [kg/m/s] Evaporation mass transfer
            end
            
            % Restrict to reasonable upper bounds
            Mcond =  min( Mcond,vapor.W(zIdx)./liquid.DZ);                 % [kg/s/m]
            Mevap = -min(-Mevap,liquid.W(zIdx)./liquid.DZ);                % [kg/s/m]
        end
        
        function [Hintcond, Hintevap] = INTHFLOW(liquid,vapor,zIdx)
        %INTHFLOW Interfacial energy transfers
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hintcond = liquid.MINTCOND(vapor,zIdx).*(vapor.H(zIdx)-liquid.H(zIdx));  % [W/m]
                    %Hintevap = liquid.MINTEVAP(vapor,zIdx).*(liquid.H(zIdx)-liquid.H(zIdx));  % [W/m]
                    Hintevap = zeros(length(zIdx),1);
                case 'SATURATED'
                    Hintcond = liquid.MINTCOND(vapor,zIdx).*(liquid.fluid.HG-liquid.H(zIdx)); % [W/m]
                    Hintevap = liquid.MINTEVAP(vapor,zIdx).*(liquid.fluid.HF-liquid.H(zIdx)); % [W/m]
            end
        end
        
        function Mwall = MWALL(liquid,vapor,zIdx)
        %MWALL Wall evaporation mass transfer
        %No condensation considered at the wall
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;
            
            Mwall = sum(PERIM.*liquid.WALLMFLUX(vapor,zIdx),2);            % [kg/s/m]
        end

        function Mintcond = MINTCOND(liquid,vapor,zIdx)
        %MINTCOND Interfacial condensation mass transfer
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            [Mintcond, ~] = liquid.INTMFLOW(vapor,zIdx);                   % [kg/s/m]
        end

        function Mintevap = MINTEVAP(liquid,vapor,zIdx)
        %MINTEVAP Interfacial evaporation mass transfer
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            [~, Mintevap] = liquid.INTMFLOW(vapor,zIdx);                   % [kg/s/m]
        end
        
        function Mtot = MTOT(liquid,vapor,zIdx)
        %MTOT Total mass transfer
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            %Mtot  = liquid.MWALL(vapor,zIdx) + liquid.MINTCOND(vapor,zIdx) + liquid.MINTEVAP(vapor,zIdx); % [kg/s/m]
            % Better for speed:
            [Mintcond,Mintevap] = liquid.INTMFLOW(vapor,zIdx);             % [kg/s/m]
            Mtot  = liquid.MWALL(vapor,zIdx) + Mintcond + Mintevap;        % [kg/s/m]
        end
        
        function W2fluid = W2FLUID(liquid,vapor,zIdx)
        %W2FLUID Total mass
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
        
            W2fluid = liquid.W(zIdx)+vapor.W(zIdx);                        % [kg/s]
        end
        
        
        function Hwallhflow = HWALLHFLOW(liquid,zIdx)
        %HWALLHFLOW wall energy transfer from wall heat flux

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;

            Hwallhflow = sum(PERIM.*liquid.HFLUX(zIdx),2);                % [W/m]
        end
        
        function Hwall = HWALL(liquid,vapor,zIdx)
        %HWALL wall energy transfer from wall mass transfer
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hwall = liquid.MWALL(vapor,zIdx).*(vapor.H(zIdx)-liquid.H(zIdx));   % [W/m]
                case 'SATURATED'
                    Hwall = liquid.MWALL(vapor,zIdx).*(liquid.fluid.HG-liquid.H(zIdx)); % [W/m]
            end
        end
        
        function Hintcond = HINTCOND(liquid,vapor,zIdx)
        %HINTCOND Interfacial energy transfer from condensation
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            [Hintcond,~] = liquid.INTHFLOW(vapor,zIdx);                    % [W/m]
        end
        
        function Hintevap = HINTEVAP(liquid,vapor,zIdx)
        %HINTEVAP Interfacial energy transfer from evaporation
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            [~,Hintevap] = liquid.INTHFLOW(vapor,zIdx);                    % [W/m]
        end
        
        function Htot = HTOT(liquid,vapor,zIdx)
        %HTOT Total energy transfer
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            %Htot  = liquid.HWALLHFLOW(zIdx) + liquid.HWALL(vapor,zIdx) + liquid.HINTCOND(vapor,zIdx) + liquid.HINTEVAP(vapor,zIdx); % [W/m]
            % Better for speed:
            [Hintcond,Hintevap] = liquid.INTHFLOW(vapor,zIdx);                 % [W/m]
            Htot = liquid.HWALLHFLOW(zIdx) + liquid.HWALL(vapor,zIdx) + Hintcond + Hintevap; % [W/m]
        end
        
        function H2fluid = H2FLUID(liquid,vapor,zIdx)
        %H2FLUID Total enthalpy
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
        
            H2fluid = (liquid.W(zIdx).*liquid.H(zIdx)+vapor.W(zIdx).*vapor.H(zIdx))./liquid.W2FLUID(vapor,zIdx); % [J/kg]
        end
        
        function vr = VR(liquid,vapor,zIdx)
        %VR Local relative velocity
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            import Solvers.TwoFluid.REGIMES

            switch liquid.inputSet.model.LOCRELVEL
                case 'AREAMEAN'
                    vr = vapor.U(zIdx) - liquid.U(zIdx);
                case 'SCALED'
                    mult = liquid.inputSet.model.RELVELCST.*ones(size(zIdx));
                    vr = mult.*(vapor.U(zIdx) - liquid.U(zIdx));
                case 'DRIFT'
                    vr = vapor.VF(liquid,zIdx).*(vapor.U(zIdx) - liquid.U(zIdx));
                    vrl = liquid.VF(vapor,zIdx).*(vapor.U(zIdx) - liquid.U(zIdx));
                    vr(liquid.VF(vapor,zIdx)<0.5)=vrl(liquid.VF(vapor,zIdx)<0.5);
                case 'FLOWREGIME'
                    flowregime = liquid.FLOWREGIME(zIdx);
                    % bubbly, slug, churn (assume also for dffb)
                    RHOV = liquid.fluid.RHOV(vapor.H(zIdx));
                    RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
                    C = 1.2 - 0.2.*sqrt(RHOV./RHOL);
                    vr = (1-C.*(vapor.VF(liquid,zIdx)))./(liquid.VF(vapor,zIdx)).*vapor.U(zIdx) - C.*liquid.U(zIdx);
        
                    % annular (instead contribution from interfacial shear)
                    Idann = ismember(flowregime,[REGIMES.ANNULAR]);
                    vr_ann = zeros(size(zIdx));
                    vr(Idann) = vr_ann(Idann);
        
                    % dffb (dispersed liquid)
                    Iddffb = ismember(flowregime,[REGIMES.DFFB]);
                    vr_dffb = (1-C.*(liquid.VF(vapor,zIdx)))./(vapor.VF(liquid,zIdx)).*vapor.U(zIdx) - C.*liquid.U(zIdx);
                    vr(Iddffb) = vr_dffb(Iddffb);
            end   
        end

        function Fgrav = FGRAV(liquid,vapor,zIdx)
        %FGRAV gravitational force
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            model = liquid.inputSet.model;
            AREA = liquid.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));

            Fgrav = -model.G*cos(model.ANGLE*pi/180)*RHOL.*liquid.VF(vapor,zIdx).*AREA; % [N/m]
        end

        function Fbuoy = FBUOY(liquid,vapor,zIdx)
        %FBUOY Liquid buoyancy
       
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            AREA = liquid.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            DPDZ = liquid.mix.DP.Tot(zIdx)/liquid.DZ;                      % [Pa/m] pressure gradient
            
            Fbuoy  = AREA*liquid.VF(vapor,zIdx).*DPDZ;                     % [N/m]
        end

        function fw = FW(liquid, zIdx)
        %FW Liquid wall friction factor [-]
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            model = liquid.inputSet.model;
            fw = (model.FRICTION(1).*liquid.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3));
        end

        function tauwl = TAUWL(liquid,zIdx)
        %TAUWL liquid-wall shear stress
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            
            MULT  = 0.5.*(liquid.FW(zIdx)./4.).*RHOL;
            tauwl  = MULT.*liquid.U(zIdx).*abs(liquid.U(zIdx));             % [Pa]     wall shear stress
        end

        function Fshear = FSHEAR(liquid,vapor,zIdx)
        %FSHEAR wall and interfacial shear force
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            import Solvers.TwoFluid.REGIMES

            switch liquid.inputSet.model.INTAREA
                case 'DISPGAS2DISPLIQ'
                    flowregime = liquid.FLOWREGIME(zIdx);
                    PERIM = liquid.inputSet.geometry.PERIM;                        % [m]  perimeter
                    TAUWL  = liquid.TAUWL(zIdx);                                   % [Pa] liquid wall shear
                    TAUWV  = vapor.TAUWV(zIdx);                                    % [Pa] vapor wall shear   

                    % Dispersed gas
                    Fshear  = -liquid.VF(vapor,zIdx).*PERIM.*TAUWL;               % [N/m]

                    % Dispersed liquid
                    Idl = ismember(flowregime,[REGIMES.ANNULAR, REGIMES.DFFB]);
                    Fwshearl = -liquid.VF(vapor,zIdx).*PERIM.*TAUWV;               % [N/m]
                    Fshear(Idl)=Fwshearl(Idl);
            end
        end

        function cd = CDG(liquid,vapor,zIdx)
        %CD Drag coefficient for dispersed gas
        % TODO: Distorted fluid particle correlation is more reasonable,
        % but predicts too high drag forces, possibly due to the AREAMEAN
        % assumption in the relative velocity calculation

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            % Stokes
            cd = 24./(liquid.REV(vapor,zIdx).^(1)); 
            cd(liquid.REV(vapor,zIdx) <= 1E-3) = 0;                        % [-] Avoid division by 0 

            % Viscous
            %REV = liquid.REV(vapor,zIdx);
            %cd = 24./(REV).*(1+0.1.*REV.^(0.75)); 
            %cd(liquid.REV(vapor,zIdx) <= 1E-3) = 0;                        % [-] Avoid division by 0

            % Distorted fluid particle (bubbly flow n=1)
            %mult = sqrt(2)/3.*((1+17.67.*(liquid.VF(vapor,zIdx)).^(1.3))./(18.67.*(liquid.VF(vapor,zIdx)).^(1.5))).^2;
            %mult = sqrt(2)/3.*(liquid.VF(vapor,zIdx)).^2;
            %cd = liquid.VISCV(zIdx).*liquid.REV(vapor,zIdx).*mult;
            %cd(liquid.VF(vapor,zIdx)<0.5)=0;
            %cd = min(cd,0.45);

            % Churn
            %cd = 8/3.*(liquid.VF(vapor,zIdx)).^3;
        end

        function cd = CDL(liquid,vapor,zIdx)
        %CD Drag coefficient for dispersed liquid

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            %Stokes region
            %cd = 24./(liquid.REL(vapor,zIdx).^(1)); 
            %cd(liquid.REL(vapor,zIdx) <= 1E-3) = 0;                        % [-] Avoid division by 0

            % Viscous
            REL = liquid.REL(vapor,zIdx);
            cd = 24./(REL).*(1+0.15.*REL.^(0.687)); 
            cd(liquid.REL(vapor,zIdx) <= 1E-3) = 0;                        % [-] Avoid division by 0
            cd(liquid.VF(vapor,zIdx)>0.5)=0;

            % Distorted fluid particle (bubbly flow n=2.5)
            %mult = sqrt(2)/3.*((1+17.67.*(1-liquid.VF(vapor,zIdx)).^(2.6))./(18.67.* (1-liquid.VF(vapor,zIdx)).^3)).^2;
            %mult = sqrt(2)/3.*(1-liquid.VF(vapor,zIdx)).^2;
            %cd = liquid.VISCL(zIdx).*liquid.REL(vapor,zIdx).*mult;
            %cd(liquid.VF(vapor,zIdx)>0.5)=0;
            %cd = min(cd,1);

            % Churn
            %cd = 8/3.*(1-liquid.VF(vapor,zIdx)).^3;
        end

        function Fdrag = FDRAG(liquid,vapor,zIdx)
        % FDRAG liquid drag

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            import Solvers.TwoFluid.REGIMES

            switch liquid.inputSet.model.INTAREA
                case 'DISPGAS2DISPLIQ'
                    flowregime = liquid.FLOWREGIME(zIdx);
                    AREA = liquid.inputSet.geometry.AREA;                % [m2] area
                    RHOV = liquid.fluid.RHOV(vapor.H(zIdx));             % [kg/m^3] vapor density
                    RHOL = liquid.fluid.RHOL(liquid.H(zIdx));            % [kg/m^3] liquid density

                    % Dispersed gas
                    vr = liquid.VR(vapor,zIdx);
                    mult = liquid.PAREA(zIdx)./liquid.PVOL(zIdx);        % [1/m]
                    Fdrag = AREA.*0.5.*mult.*liquid.CDG(vapor,zIdx).*vapor.VF(liquid,zIdx).*RHOL.*vr.*abs(vr); % [N/m]          

                    % Dispersed liquid
                    Idl = ismember(flowregime,[REGIMES.ANNULAR, REGIMES.DFFB]);       % [1/m]
                    Fdragl = AREA.*0.5.*mult.*liquid.CDL(vapor,zIdx).*liquid.VF(liquid,zIdx).*RHOV.*vr.*abs(vr); % [N/m] 
                    Fdrag(Idl) = Fdragl(Idl);
            end
        end

        function Fmass = FMASS(liquid,vapor,zIdx)
        % FMASS momentum exchange through mass exchange  
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            Fmass = liquid.MINTCOND(vapor,zIdx).*(vapor.U(zIdx)-liquid.U(zIdx)); % [N/m] 

        end

        function Ftot = FTOT(liquid,vapor,zIdx)
        %FTOT Total force 
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            grav = liquid.FGRAV(vapor,zIdx);
            buoy = liquid.FBUOY(vapor,zIdx);
            int_drag = liquid.FDRAG(vapor,zIdx);
            shear = liquid.FSHEAR(vapor,zIdx);
            mass = liquid.FMASS(vapor,zIdx);

            % turn on force terms
            Ftot= grav + buoy + shear + int_drag + mass;%  % [N/m] 

            % turn off force terms
            % Ftot=zeros(size(zIdx));% [N/m]  
        end

        function U2fluid = U2FLUID(liquid,vapor,zIdx)
        %U2FLUID Total velocity
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            RHOV = liquid.fluid.RHOV(vapor.H(zIdx));             % [kg/m^3] vapor density
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));            % [kg/m^3] liquid density

            U2fluid = (liquid.VF(vapor,zIdx).*RHOL.*liquid.U(zIdx) + vapor.VF(liquid,zIdx).*RHOV.*vapor.U(zIdx))./(liquid.VF(vapor,zIdx).*RHOL+ vapor.VF(liquid,zIdx).*RHOV);
        
            %U2fluid = (liquid.W(zIdx).*liquid.U(zIdx)+vapor.W(zIdx).*vapor.U(zIdx))./liquid.W2FLUID(vapor,zIdx); % [m/s]
        end
        
    end
end

