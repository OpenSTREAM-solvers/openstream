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
            RHOV = liquid.fluid.RHOV(liquid.H(zIdx));                      % [kg/m^3]
            
            vf = 1 - max(0,vapor.W(zIdx)./(liquid.S(vapor,zIdx).*liquid.W(zIdx).*RHOV./RHOL+vapor.W(zIdx)));
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
            
            rev = RHOL.*abs(vapor.U(zIdx)-liquid.U(zIdx)).*liquid.L(zIdx)./MUL; % [-]
        end
        
         function t = T(liquid,zIdx)
        %T Liquid temperature
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            t = liquid.fluid.T(liquid.H(zIdx));                            % [K]
        end
        
        function xtr_scb = XTR_SCB(liquid)
            %XTR_SCB Quality at onset of subcooled boiling transition 
            % TODO: Very simplistic transition criteria for now, more realistic models to be implemented later
            
            xtr_scb = -0.2;
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
            
            xtr_ann = 0.3;
        end
        
        function xtr_cbt = XTR_CBT(liquid)
            %XTR_CBT Quality at CBT 
            % TODO: Very simplistic transition criteria for now, more realistic models to be implemented later
            
            xtr_cbt = 0.7;
        end
        
        function flowregime = FLOWREGIME(liquid,zIdx)
        %FLOWREGIME Categorical two-phase flow regimes
        % Note: Very slow! Calls to this method should be limited
            
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ = liquid.mix.XEQ(zIdx);                                    % [-]
            
            id = zeros(liquid.NZ,1);                                       % Liquid (initilization)
            id(XEQ > liquid.XTR_SCB) = 1;                                  % bubbly_subcooled
            id(XEQ > liquid.XTR_SAT) = 2;                                  % bubbly_saturated
            id(XEQ > liquid.XTR_ITM) = 3;                                  % intermediate
            id(XEQ > liquid.XTR_ANN) = 4;                                  % annular
            id(XEQ > liquid.XTR_CBT) = 5;                                  % dffb
            
            flowregime = categorical(id,[0 1 2 3 4 5],{'liquid','bubbly_subcooled','bubbly_saturated','intermediate','annular','dffb'});
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
                
        function ai = AI(liquid,vapor,zIdx)
        %AI Volumetric interfacial area
        % TODO: Simplistic model for now, more realistic models to be implemented later, including a transport equation (i.e., AI will become a primary parameter since resolved by the solver)
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            flowregime = liquid.FLOWREGIME(zIdx);
            
            % Dispersed gas
            %Idv = ismember(flowregime,{'liquid','bubbly_subcooled','bubbly_saturated','intermediate'});
            aiv = 6*vapor.VF(liquid,zIdx)./liquid.L(zIdx);                 % [m^-1] Dispersed gas
            ai      = aiv;                                                 % [m^-1]
            
            %Dispersed liquid
            Idl = ismember(flowregime,{'annular','dffb'});
            ail = 6*liquid.VF(vapor,zIdx)./liquid.L(zIdx);                 % [m^-1] Dispersed liquid
            ai(Idl) = ail(Idl);                                            % [m^-1]
            
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
            %k_EVAP = max(min(interp1(x,linspace(0,1,10),XEQ,'linear','extrap'),k_EVAP),0);                                 % [-] Linear      interpolation between XTR_SCB and XTR_SCB
            k_BOIL = max(min(interp1(x,linspace(0,1,10).^2,XEQ,'linear','extrap'),k_BOIL),0);                                % [-] Quadratic   interpolation between XTR_SCB and XTR_SCB
            %k_EVAP = max(min(interp1(x,exp((liquid.XTR_SAT-x)./(liquid.XTR_SCB-1E-6-x)),XEQ,'linear','extrap'),k_EVAP),0); % [-] Exponential interpolation between XTR_SCB and XTR_SCB
            k_BOIL = k_BOIL(zIdx);                                         % [-]
        end

        function wallf = WALLF(liquid,zIdx)
        %WALLF Wetted area fraction
        %TODO fill in reasonable correlation
            
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            % Make it constant for now
            wallf = ones(size(zIdx));
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

            flowregime  = liquid.FLOWREGIME(zIdx);
            L   = liquid.L(zIdx);                                          % [m] Interfacial length scale

            % Dispersed gas
            %Idg = ismember(flowregime,{'liquid','bubbly_subcooled','bubbly_saturated','intermediate'});
            INTNUV = liquid.INTNUV(vapor,zIdx);                            % [-] Interfacial Nusselt number
            KL = liquid.fluid.KL(liquid.H(zIdx));                          % [W/m/K] Liquid conductivity <- assume vapor phase is dispersed
            hv   = INTNUV.*KL./L; hv(L <= 1E-6) = 0;                       % [W/m^2/K] Interfacial heat transfer coefficient
            h = hv;                                                        % [W/m^2/K]
            
            % Dispersed liquid
            Idl = ismember(flowregime,{'annular','dffb'});
            INTNUL = vapor.INTNUL(liquid,zIdx);                            % [-] Interfacial Nusselt number
            KV = vapor.fluid.KV(vapor.H(zIdx));                            % [W/m/K] Vapor conductivity  <- assume liquid phase is dispersed
            hl   = INTNUL.*KV./L; hl(L <= 1E-6) = 0;                       % [W/m^2/K] Interfacial heat transfer coefficient
            h(Idl) = hl(Idl);                                              % [W/m^2/K]
            %h = max(0,h);                                                  % [W/m^2/K]
            
            TSAT  = liquid.fluid.TSAT;                                     % [K] Saturated fluid temperature
            inthflux_evap = h.*(vapor.T(zIdx)-TSAT);                       % [W/m^2] Evaporation heat flux
            inthflux_cond = h.*(TSAT-liquid.T(zIdx));                      % [W/m^2] Condensation heat flux
        end

        function [Mcond, Mevap] = INTMFLOW(liquid,vapor,zIdx)
        %INTMMFLOW condensation and evaporation mass flow
            
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
        

        function Fgrav = FGRAV(liquid,zIdx)
        %FGRAV gravitational force
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            model = liquid.inputSet.model;
            AREA = liquid.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));

            Fgrav = -model.G*cos(model.ANGLE*pi/180)*RHOL.*liquid.VF(zIdx).*AREA; % [N/m]
        end

        function Fpres = FPRES(liquid,zIdx)
        %FPRES pressure gradient
       
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            AREA = liquid.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            DPDZ = liquid.mix.DP.Tot(zIdx);                                % [Pa/m] pressure gradient
            
            Fpres  = AREA*liquid.VF(zIdx).*DPDZ;                           % [N/m]
        end

 


        function Fric = FRIC(liquid,zIdx)
        %FRIC Fanning friction factor
        %TODO add more options, e.g. Haaland formula
            
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            % Blasius for now
            Fric = 0.0791./liquid.RE(zIdx).^0.25;                          % [-] 
            Fric(liquid.RE(zIdx) <= 1E-3) = 0;                             % [-] Avoid division by 0  
            % Constant for now
            %Fric = 0.005;
        end


        function Fwshear = FWSHEAR(liquid,zIdx)
        %FWSHEAR wall shear force
        %TODO find issue that stops convergence and remove division by 10
        %in the last line
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            PERIM = liquid.inputSet.geometry.PERIM;                        % [m]      perimeter
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
            
            MULT  = 0.5*liquid.WALLF(zIdx).*liquid.FRIC(zIdx).*RHOL;
            TAUW  = MULT.*liquid.U(zIdx).*liquid.U(zIdx);                  % [Pa]     wall shear stress

            Fwshear  = -PERIM.*TAUW./100;                                  % [N/m]
        end

        function Fishear = FISHEAR(liquid,vapor,zIdx)
        %FISHEAR interfacial shear force
        %TODO replace multiplication factor MULT with proper correlation
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            AREA = liquid.inputSet.geometry.AREA;                          % [m2]      area
            PERIM = liquid.inputSet.geometry.PERIM;                        % [m]      perimeter

            MULT = 1;
            
            TAUI  = MULT.*(vapor.U(zIdx)-liquid.U(zIdx)).*abs(vapor.U(zIdx)-liquid.U(zIdx));  % [Pa]     interfacial shear stress

            Fishear  = PERIM.*TAUI;                                % [N/m] AREA.*liquid.AI(zIdx)
        end

        function Fmwall = FMWALL(liquid,zIdx)
        % FMWALL momentum exchange through wall mass exchange  
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            %PERIM = liquid.inputSet.geometry.PERIM;                        % [m]      perimeter
            %Fmwall = PERIM.*liquid.MWEVAP(zIdx).*(interface.U(zIdx)-liquid.U(zIdx));            % [N/m]   (MWEVAP is negative)
            % assuming at velocity at liquid interphase is the same as in
            % the bulk (full-slip), this terms becomes zero
            Fmwall = zeros(size(zIdx));

        end

        function Ftot = FTOT(liquid,vapor,zIdx)
        %FTOT Total force 
        %TODO Add interfacial mass exchange terms
        
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            % turn on force terms
            %Ftot=liquid.FPRES(zIdx)+liquid.FGRAV(zIdx)  +liquid.FWSHEAR(zIdx) + liquid.FISHEAR(vapor,zIdx)  +liquid.FMWALL(zIdx);% [N/m] 

            % turn off force terms
            Ftot=zeros(size(zIdx));% [N/m]  
        end
        
    end
end

