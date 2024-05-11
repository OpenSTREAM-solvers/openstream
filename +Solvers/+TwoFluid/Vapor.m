classdef Vapor < Solvers.AbstractField
    %VAPOR Summary of this class goes here
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
        function vapor = Vapor(inputSet, fluid)
            %VAPOR Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin > 0
                % Store inputSet as object property
                vapor.inputSet = inputSet;
                vapor.fluid  = fluid;
            end

            % Overload copyable properties
            %vapor.flowProperties = {'W','U','H'};
        end
        
        function x = X(vapor,zIdx)
        %X Vapor mass fraction
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            x = vapor.W(zIdx)./vapor.mix.W(zIdx);                          % [-]
        end
        
        function jg = JG(vapor,zIdx)
        %JG Vapor superficial velocity
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            AREA = vapor.inputSet.geometry.AREA;                           % [m^2]
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                        % [kg/m^3]
            
            jg = vapor.W(zIdx)./RHOV./AREA;                                % [m/s]
        end
        
        function s = S(vapor,liquid,zIdx)
        %S Phase slip ratio
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            s = liquid.S(zIdx);                                            % [-]
        end
        
        function vf = VF(vapor,liquid,zIdx)
        %VF Volumetric vapor fraction
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            vf = 1 - liquid.VF(vapor,zIdx);                                % [-]
        end
        
        function re = RE(vapor,zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            PERIM = vapor.inputSet.geometry.PERIM;                         % [m] Perimeter
            MUV = vapor.fluid.MUV(vapor.H(zIdx));                          % [Pa.s]
            
            re = 4.*vapor.W(zIdx)./MUV./PERIM;                             % [-]
        end
        
        function rel = REL(vapor,liquid,zIdx)
        %REL Dispersed liquid Reynolds number
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));
            MUV  = vapor.fluid.MUV(vapor.H(zIdx));
            
            rel = RHOV.*abs(liquid.U(zIdx)-vapor.U(zIdx)).*vapor.L(liquid,zIdx)./MUV; % [-]
        end
        
        function t = T(vapor,zIdx)
        %T Vapor temperature
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            t = vapor.fluid.T(vapor.H(zIdx));                              % [K]
        end
        
        function xtr_scb = XTR_SCB(vapor,liquid)
            %XTR_SCB Quality at onset of subcooled boiling transition 
            
            xtr_scb = liquid.XTR_SCB();
        end
        
        function xtr_scb = XTR_SAT(vapor,liquid)
            %XTR_SAT Quality at end of subcooled boiling transition 
            
            xtr_scb = liquid.XTR_SAT();
        end
        
        function xtr_itm = XTR_ITM(vapor,liquid)
            %XTR_ITM Quality at onset of intermediate region 
            
            xtr_itm = liquid.XTR_ITM();
        end
        
        function xtr_ann = XTR_ANN(vapor,liquid)
            %XTR_ANN Quality at onset of annular flow region 
            
            xtr_ann = liquid.XTR_ANN();
        end
        
        function xtr_cbt = XTR_CBT(vapor,liquid)
            %XTR_CBT Quality at CBT 
            
            xtr_cbt = liquid.XTR_CBT();
        end
        
        function flowregime = FLOWREGIME(vapor,liquid,zIdx)
            %FLOWREGIME Categorical two-phase flow regimes
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            flowregime = liquid.FLOWREGIME(liquid,zIdx);
        end
        
        function l = L(vapor,liquid,zIdx)
        %L Interfacial length scale (e.g. bubble of drop diameter)
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            l = liquid.L(zIdx);                                            % [m]
        end
        
        function ai = AI(vapor,liquid,zIdx)
        %AI Volumetric interfacial area
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            ai = liquid.AI(vapor,zIdx);                                    % [m^2/m^3]
        end
        
        function k_VAP = WALLQCOEF(vapor,liquid,zIdx)
        %WALLQCOEF Wall heat input to vapor partitioning
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            k_VAP = 1-liquid.WALLQCOEF(zIdx);
        end
        
        function k_BOIL = WALLBOILCOEF(vapor,liquid,zIdx)
        %WALLBOILCOEF  Wall heat input to liquid boiling
            
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            
            k_BOIL = liquid.WALLBOILCOEF(zIdx);
        end

        function wallf = WALLF(vapor,liquid,zIdx)
        %WALLF Void area fraction
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            wallf = 1-liquid.WALLF(zIdx);
        end
        
        function intnu = INTNUL(vapor,liquid,zIdx)
        %INTNUL Interfacial Nusselt number for dispersed liquid
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            model = vapor.inputSet.model;
            
            switch model.INTNU
                case 'CONSTANT'
                    intnu = model.INTNULCST.*ones(size(zIdx));             % [-]
                case 'RANZMARSHALL'
                    Re = vapor.REL(liquid,zIdx);                           % [-]
                    Pr = vapor.fluid.PRANDTLV(vapor.H(zIdx));              % [-]
                    
                    coef = model.RANZMARSHALLLCST;                         % [-] Ranz-Marshall coefficients
                    intnu = coef(1) + coef(2).*Re.^coef(3).*Pr.^coef(4);   % [-]
                case 'RELAXATION'
                    % TODO: Calculate equivalent interfacial Nusselt number (for display only)
            end
        end
        
        function hflux = HFLUX(vapor,liquid,zIdx)
        %HFLUX Wall heat flux to vapor phase
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            HFLUX = vapor.mix.HFLUX;
            
            hflux = HFLUX(zIdx,:)-liquid.HFLUX(zIdx);                      % [W/m^2] 
        end
        
        function wallmflux = WALLMFLUX(vapor,liquid,zIdx)
        %MWEVAP Wall evaporation mass flux
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            wallmflux = -liquid.WALLMFLUX(vapor,zIdx);                     % [kg/s/m^2]
        end
        
        function [inthflux_evap, inthflux_cond] = INTHFLUX(vapor,liquid,zIdx)
        %INTHFLUX Interfacial heat flux (> 0 to liquid phase)
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            [inthflux_evap, inthflux_cond] = liquid.INTHFLUX(vapor,zIdx);  % [W/m^2]
        end
        
        function [Mcond, Mevap] = INTMFLOW(vapor,liquid,zIdx)
        %INTMMFLOW condensation and evaporation mass flow
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            [Mcond, Mevap] = liquid.INTMFLOW(vapor,zIdx);                  % [kg/s/m]
        end
        
        function [Hintcond,Hintevap] = INTHFLOW(vapor,liquid,zIdx)
        %INTHFLOW Interfacial energy transfers
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    %Hcond = vapor.MINTCOND(liquid,zIdx).*(vapor.H(zIdx)-vapor.H(zIdx));  % [W/s/m]
                    Hintcond = zeros(length(zIdx),1);
                    Hintevap = vapor.MINTEVAP(liquid,zIdx).*(liquid.H(zIdx)-vapor.H(zIdx)); % [W/s/m]
                case 'SATURATED'
                    Hintcond = vapor.MINTCOND(liquid,zIdx).*(vapor.fluid.HG-vapor.H(zIdx)); % [W/s/m]
                    Hintevap = vapor.MINTEVAP(liquid,zIdx).*(vapor.fluid.HF-vapor.H(zIdx)); % [W/s/m]
            end
        end

        function Mwall = MWALL(vapor,liquid,zIdx)
        %MWALL Wall evaporation mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mwall  = -liquid.MWALL(vapor,zIdx);                            % [kg/s/m]
        end
        
        function Mintcond = MINTCOND(vapor,liquid,zIdx)
        %MINTCOND Interfacial condensation mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mintcond = -liquid.MINTCOND(vapor,zIdx);                       % [kg/s/m]
        end
        
        function Mintevap = MINTEVAP(vapor,liquid,zIdx)
        %MINTEVAP Interfacial evaporation mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mintevap = -liquid.MINTEVAP(vapor,zIdx);                       % [kg/s/m]
        end

        function Mtot = MTOT(vapor,liquid,zIdx)
        %MTOT Total mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            %Mtot  = vapor.MWALL(liquid,zIdx) + vapor.MINTCOND(liquid,zIdx) + vapor.MINTEVAP(liquid,zIdx); % [kg/s/m]
            % Better for speed:
            [Mintcond,Mintevap] = liquid.INTMFLOW(vapor,zIdx);             % [kg/s/m]
            Mtot  = vapor.MWALL(liquid,zIdx) - Mintcond - Mintevap;        % [kg/s/m]
        end
        
        function W2fluid = W2FLUID(vapor,liquid,zIdx)
        %W2FLUID Total mass
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
        
            W2fluid = liquid.W2FLUID(zIdx);                                % [kg/s]
        end
        
        
        function Hwallhflow = HWALLHFLOW(vapor,liquid,zIdx)
        %HWALLHFLOW wall energy transfer from wall heat flux

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            PERIM = vapor.inputSet.geometry.PERIM;

            Hwallhflow = sum(PERIM.*vapor.HFLUX(liquid,zIdx),2);           % [W/m]
        end
        
        function Hwall = HWALL(vapor,liquid,zIdx)
        %HWALL wall energy transfer from mass transfer
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    %Hwall = vapor.MWALL(liquid,zIdx).*(vapor.H(zIdx)-vapor.H(zIdx));  % [W/s/m]
                    Hwall = zeros(length(zIdx),1);
                case 'SATURATED'
                    Hwall = vapor.MWALL(liquid,zIdx).*(vapor.fluid.HG-vapor.H(zIdx)); % [W/s/m]
            end
        end
        
        function Hintcond = HINTCOND(vapor,liquid,zIdx)
        %HINTCOND Interfacial energy transfer from condensation
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            [Hintcond,~] = vapor.INTHFLOW(liquid,zIdx);                    % [W/m]
        end
        
        function Hintevap = HINTEVAP(vapor,liquid,zIdx)
        %HINTEVAP Interfacial energy transfer from evaporation
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            [~,Hintevap] = vapor.INTHFLOW(liquid,zIdx);                    % [W/m]
        end
        
        function Htot = HTOT(vapor,liquid,zIdx)
        %HTOT Total energy transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            %Htot  = vapor.HWALLHFLOW(liquid,zIdx) + vapor.HWALL(liquid,zIdx) + vapor.HINTCOND(liquid,zIdx) + vapor.HINTEVAP(liquid,zIdx) ; % [W/m]
            % Better for speed:
            [Hintcond,Hintevap] = vapor.INTHFLOW(liquid,zIdx);             % [W/m]
            Htot = vapor.HWALLHFLOW(liquid,zIdx) + vapor.HWALL(liquid,zIdx) + Hintcond + Hintevap; % [W/m]
        end
        
        function H2fluid = H2FLUID(vapor,liquid,zIdx)
        %H2FLUID Total enthalpy
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
        
            H2fluid = liquid.H2FLUID(vapor,zIdx);                          % [J/kg]
        end
        
        
        function Fgrav = FGRAV(vapor,liquid,zIdx)
        %FGRAV gravitational force
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            model = vapor.inputSet.model;
            AREA = vapor.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                            % [kg/m^3]

            Fgrav = -model.G*cos(model.ANGLE*pi/180)*RHOV.*vapor.VF(zIdx).*AREA; % [N/m]
        end

        function Fpres = FPRES(vapor,liquid,zIdx)
        %FPRES pressure gradient
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            AREA = vapor.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            DPDZ = vapor.mix.DP.Tot(zIdx);                                % [Pa/m] pressure gradient
            
            Fpres  = AREA*vapor.VF(liquid,zIdx).*DPDZ;                         % [N/m]
        end

        

        function Fric = FRIC(vapor,zIdx)
        %FRIC Fanning friction factor
        %TODO add more options, e.g. Haaland formula
            
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            % Blasius for now
            Fric = 0.0791./vapor.RE(zIdx).^0.25;                           % [-] 
            Fric(vapor.RE(zIdx) <= 1E-3) = 0;                              % [-] Avoid division by 0    
            % Constant for now
            %Fric = 0.005;
        end
        
        function Fwshear = FWSHEAR(vapor,liquid,zIdx)
        %FWSHEAR wall shear force
        %TODO implement FRIC
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            PERIM = vapor.inputSet.geometry.PERIM;                         % [m]      perimeter
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                            % [kg/m^3]
            
            MULT  = 0.5*vapor.WALLF(liquid,zIdx).*vapor.FRIC(zIdx).*RHOV;
            TAUW  = MULT.*vapor.U(zIdx).*vapor.U(zIdx);                    % [Pa]     wall shear stress

            Fwshear  = -PERIM.*TAUW;                                % [N/m]
        end

        function Fishear = FISHEAR(vapor,liquid,zIdx)
        %FISHEAR interfacial shear force
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Fishear  = -liquid.FISHEAR(vapor,zIdx);                                % [N/m]
        end

        function Fmwall = FMWALL(vapor,liquid,zIdx)
        % FMWALL momentum exchange through wall mass exchange  
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            PERIM = liquid.inputSet.geometry.PERIM;                        % [m]      perimeter
            Fmwall = -PERIM.*liquid.MWEVAP(vapor,zIdx).*(vapor.U(zIdx)-liquid.U(zIdx));  % [N/m]   (MWEVAP is negative)
        end
        
        function Ftot = FTOT(vapor,liquid,zIdx)
        %FTOT Total force 
        %TODO Add interfacial mass exchange terms
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            % turn on force terms
            %Ftot  = vapor.FPRES(liquid,zIdx) + vapor.FWSHEAR(liquid,zIdx)+vapor.FGRAV(liquid,zIdx) +vapor.FISHEAR(liquid,zIdx) +vapor.FMWALL(liquid,zIdx);% [N/m] 
            
            % turn off force terms
            Ftot=zeros(size(zIdx));% [N/m]  
        end

    end
end

