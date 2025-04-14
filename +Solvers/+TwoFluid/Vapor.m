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
        
        function area = AREA(vapor,liquid,zIdx)
        %AREA gas cross-section area
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            AREA = vapor.inputSet.geometry.AREA;                           % [m^2] Area
            
            area = vapor.VF(liquid,zIdx).*AREA;                            % [m^2]
        end
        
        function rho = RHO2FLUID(vapor,liquid,zIdx)
        %RHOMIX Two-phase density
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            rho = liquid.RHO2FLUID(vapor,zIdx);                            % [-]
        end
        
        function u = USLIP(vapor,liquid,zIdx)
        %VELOCITY Gas velocity based on input phase slip
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            S = vapor.inputSet.model.SLIP;
            
            u = liquid.USLIP(vapor,zIdx).*S;                               % [m/s]
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
            
            flowregime = liquid.FLOWREGIME(zIdx);
        end
        
        function l = L(vapor,liquid,zIdx)
        %L Interfacial length scale (e.g. bubble of drop diameter)
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            l = liquid.L(zIdx);                                            % [m]
        end

        function area = PAREA(vapor,liquid,zIdx)
        %PAREA Projected area of typical particle (e.g. bubble or drop)
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            model = vapor.inputSet.model;
            
            switch model.INTLENGTH
                case 'CONSTANT'
                    l = model.INTLENGTHCST.*ones(size(zIdx));              % [m]
                    area = pi*l.^2/4;                                      % [m^2]
            end
        end

        function vol = PVOL(vapor,liquid,zIdx)
        %PVOL Volume of typical particle (e.g. bubble or drop)
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            model = vapor.inputSet.model;
            
            switch model.INTLENGTH
                case 'CONSTANT'
                    l = model.INTLENGTHCST.*ones(size(zIdx));              % [m]
                    vol = pi*l.^3/6;                                       % [m^3]
            end
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
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                       % [kg/m^3]

            Fgrav = -model.G*cos(model.ANGLE*pi/180)*RHOV.*vapor.VF(liquid,zIdx).*AREA; % [N/m]
        end

        function Fbuoy = FBUOY(vapor,liquid,zIdx)
        %FBUOY Vapor buoyancy
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            AREA = vapor.inputSet.geometry.AREA;                           % [m^2]    cross-section area
            DPDZ = vapor.mix.DP.Tot(zIdx)/vapor.DZ;                        % [Pa/m] pressure gradient
            
            Fbuoy = AREA*vapor.VF(liquid,zIdx).*DPDZ;                      % [N/m]
        end

        function fw = FW(vapor, zIdx)
        %FW Wall friction factor [-]
        %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            model = vapor.inputSet.model;
            fw = model.FRICTION(1).*vapor.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
            fw(vapor.RE(zIdx) <= 1E-3) = 0;                                % [-] Avoid division by 0    

        end

        function tauwv = TAUWV(vapor,zIdx)
        %TAUWV vapor-wall shear stress
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                        % [kg/m^3]
            
            MULT  = 0.5.*(vapor.FW(zIdx)./4.).*RHOV;
            tauwv  = MULT.*vapor.U(zIdx).*abs(vapor.U(zIdx));               % [Pa]     wall shear stress
           
        end
        
        function Fshear = FSHEAR(vapor,liquid,zIdx)
        %FSHEAR wall and interfacial shear force
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            switch vapor.inputSet.model.INTAREA
                case 'DISPGAS2DISPLIQ'

                    flowregime = vapor.FLOWREGIME(liquid,zIdx);
                    PERIM = vapor.inputSet.geometry.PERIM;                         % [m]      perimeter
                    TAUWL  = liquid.TAUWL(zIdx);
                    TAUWV  = vapor.TAUWV(zIdx);
                
                    % Dispersed gas
                    Fshear  = -vapor.VF(liquid,zIdx).*PERIM.*TAUWL;               % [N/m]
       
                    % Dispersed liquid
                    Idl = ismember(flowregime,{'intermediate','annular','dffb'});
                    Fwshearl = -vapor.VF(liquid,zIdx).*PERIM.*TAUWV;               % [N/m]
                    Fshear(Idl)=Fwshearl(Idl);

                case 'SMOOTHSPHERICAL'
                    flowregime = vapor.FLOWREGIME(liquid,zIdx);
                    PERIM = vapor.inputSet.geometry.PERIM;                         % [m]      perimeter
                    TAUWL  = liquid.TAUWL(zIdx);
                    TAUWV  = vapor.TAUWV(zIdx);
                
                    % Dispersed gas
                    Fshear  = -vapor.VF(liquid,zIdx).*PERIM.*TAUWL;               % [N/m]

                    % Dispersed liquid
                    Idl = ismember(flowregime,{'annular','dffb'});
                    Fwshearl = -vapor.VF(liquid,zIdx).*PERIM.*TAUWV;               % [N/m]
                    Fshear(Idl)=Fwshearl(Idl);
            end
        end

        function Fdrag = FDRAG(vapor,liquid,zIdx)
        %FDRAG interfacial shear force
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Fdrag = -liquid.FDRAG(vapor,zIdx);
        end

        function Fmass = FMASS(vapor,liquid,zIdx)
        % FMASS momentum exchange through mass exchange  
            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            mflux = vapor.MWALL(liquid,zIdx) + vapor.MINTEVAP(liquid,zIdx);
            Fmass = mflux.*(liquid.U(zIdx)-vapor.U(zIdx));                 % [N/m]   check!
        end
        
        function Ftot = FTOT(vapor,liquid,zIdx)
        %FTOT Total force 
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            grav = vapor.FGRAV(liquid,zIdx);
            buoy = vapor.FBUOY(liquid,zIdx);
            int_drag = vapor.FDRAG(liquid,zIdx);                            % interfacial generalized particle drag
            shear = vapor.FSHEAR(liquid,zIdx);                             % wall and interfacial shear
            mass = vapor.FMASS(liquid,zIdx);

            % turn on force terms
            Ftot  = grav + buoy + shear + int_drag + mass;%  % [N/m] 
            
            % turn off force terms
            %Ftot=zeros(size(zIdx));% [N/m]  
        end

    end
end

