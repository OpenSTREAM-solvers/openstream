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
        mix          (1,1)         {isa(mix, 'Solvers.TwoFluid.Mixture')}  = NaN

     end

     properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
     end
    
    %% Constructor method
    methods
        function vapor = Vapor(inputSet, fluid)
            %VAPOR Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin > 0
                % Store inputSet as object property
                vapor.inputSet = inputSet;
                vapor.fluid  = fluid;
            end
        end
        
    end
    
    %% Vapor transport methods
    methods
        
        function x = X(vapor,zIdx)
        %X Mass fraction
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            x = vapor.W(zIdx)./vapor.mix.W(zIdx);                         % [-]
        end
        
        function vf = VF(vapor,liquid,zIdx)
        %VF Volumetric fraction
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            vf = 1 - liquid.VF(vapor,zIdx);                                % [-]
        end
        
        function jg = JG(vapor,zIdx)
        %JG Superficial velocity
        
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
        
        function area = AREA(vapor,liquid,zIdx)
        %AREA gas cross-section area
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            AREA = vapor.inputSet.geometry.AREA;                           % [m^2] Area
            
            area = vapor.VF(liquid,zIdx).*AREA;                            % [m^2]
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
            
            PERIM = sum(vapor.inputSet.geometry.PERIM);                    % [m] Perimeter
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
        
    end
    
    %% Flow regime and interfacial topology methods
    methods
        
        function xtr_sub = XTR_SUB(vapor,liquid)
            %XTR_SUB Quality at onset of subcooled boiling transition 
            
            xtr_sub = liquid.XTR_SUB();
        end
        
        function xtr_sat = XTR_SAT(vapor,liquid)
            %XTR_SAT Quality at end of subcooled boiling transition 
            
            xtr_sat = liquid.XTR_SAT();
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
        
        end
    
    %% Wall heat flux and wall heat transfer methods
    methods
        
        function hfluxwalevap = HFLUXWALEVAP(vapor,liquid,zIdx)
        %HFLUXWALWVAP Wall boiling heat flux
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            hfluxwalevap = -liquid.HFLUXWALEVAP(zIdx);                     % [W/m^2]
        end
        
        function hflux = HFLUX(vapor,zIdx)
        %HFLUX Wall heat flux to vapor phase
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            geom = vapor.inputSet.geometry;
            hflux = vapor.HWALHEAT(zIdx)./geom.PERIM;                      % [W/m^2]
        end
        
    end
    
    %% Mass transfer methods
    methods
        
        function [Mcond, Mevap] = MINT(vapor,liquid,zIdx)
        %MINT Linear interfacial mass transfer rates [kg/s/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            [Mcond, Mevap] = liquid.MINT(vapor,zIdx);                      % [kg/s/m]
            Mcond = -Mcond; Mevap = -Mevap;
        end
        
        function Mintevap = MINTEVAP(vapor,liquid,zIdx)
        %MINTEVAP Linear interfacial evaporation mass transfer [kg/s/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            [~,Mintevap] = vapor.MINT(liquid,zIdx);                        % [kg/s/m]
        end
        
        function Mintcond = MINTCOND(vapor,liquid,zIdx)
        %MINTCOND Linear interfacial condensation mass transfer [kg/s/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mintcond = vapor.MINT(liquid,zIdx);                            % [kg/s/m]
        end
        
        function walevapratio = WALEVAPRATIO(vapor,liquid,zIdx)
        %WALEVAPRATIO Wall evaporation mass ratio [-]
        %Ratio of liquid mass boiling due to wall heat flux
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            walevapratio = liquid.WALEVAPRATIO(zIdx);                      % [-]
        end
       
        function Mwalevap = MWALEVAP(vapor,liquid,zIdx)
        %MWALEVAP Linear wall mass evaporation (i.e., boiling) rate [kg/s/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mwalevap  = -liquid.MWALEVAP(vapor,zIdx);                      % [kg/s/m]
        end

        function Mtot = MTOT(vapor,liquid,zIdx)
        %MTOT Total linear mass transfer [kg/s/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mtot  = -liquid.MTOT(vapor,zIdx);                              % [kg/s/m]
        end
        
    end
    
    %% Energy transfer methods
    methods
        
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
        
         function [inthflux_evap, inthflux_cond] = INTHFLUX(vapor,liquid,zIdx)
        %INTHFLUX Interfacial heat flux (> 0 to liquid phase)
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            [inthflux_evap, inthflux_cond] = liquid.INTHFLUX(vapor,zIdx);  % [W/m^2]
        end
        
        function [Hcond,Hevap] = HINT(vapor,liquid,zIdx)
        %HINT Linear interfacial heat transfer rate [W/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            geom = vapor.inputSet.geometry;
            
            [Mcond, Mevap] = vapor.MINT(liquid,zIdx);                      % [kg/s/m] Interfacial mass flows
            HV = vapor.H(zIdx);                                            % [J/kg] Vapor enthalpy
            
            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hcond = zeros(length(zIdx),geom.NWALL);
                    Hevap = Mevap.*(liquid.H(zIdx)-HV);                    % [W/m]
                case 'SATURATED'
                    Hcond = Mcond.*(vapor.fluid.HG-HV);                    % [W/m]
                    Hevap = Mevap.*(vapor.fluid.HF-HV);                    % [W/m]
            end
        end
        
        function Hintevap = HINTEVAP(vapor,liquid,zIdx)
        %HINTEVAP Linear interfacial heat evaporation rate [W/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            [~,Hintevap] = vapor.HINT(liquid,zIdx);                        % [W/m]
        end
        
        function Hintcond = HINTCOND(vapor,liquid,zIdx)
        %HINTCOND Linear interfacial heat condensation rate [W/m]   
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Hintcond = vapor.HINT(liquid,zIdx);                            % [W/m]
        end
        
        function Hwalevap = HWALEVAP(vapor,liquid,zIdx)
        %HWALEVAP Linear wall heat evaporation (i.e., boiling)) rate [W/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            geom = vapor.inputSet.geometry;
            
            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hwalevap = zeros(length(zIdx),geom.NWALL);             % [W/m]
                case 'SATURATED'
                    Mwalevap = vapor.MWALEVAP(liquid,zIdx);                % [kg/s/m] Linear mass wall boiling rate
                    HV = vapor.H(zIdx);                                    % [J/kg]
                    Hwalevap = Mwalevap.*(vapor.fluid.HG-HV);              % [W/m]
            end
        end
        
        function Hwalheat = HWALHEAT(vapor,zIdx)
        %HWALHEAT Linear wall heat to vapor rate [W/m]
        %Set to 0 before CBT

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            cbt = vapor.mix.CBT(zIdx);                                     % CBT flag
            Hwalheat = double(cbt).*vapor.mix.LHGR(zIdx);                  % [W/m]
        end
        
        function Htot = HTOT(vapor,liquid,zIdx)
        %HTOT Total linear vapor heat rate [W/m]
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            [Hcond,Hevap] = vapor.HINT(liquid,zIdx);                       % [W/m]
            Htot = Hcond + Hevap + vapor.HWALEVAP(liquid,zIdx) + vapor.HWALHEAT(zIdx); % [W/m]
        end
        
    end
    
    %% Momentum transfer methods
    methods
        
        function Fgrav = FGRAV(vapor,liquid,zIdx)
        %FGRAV gravitational force
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            model = vapor.inputSet.model;
            AREA = vapor.inputSet.geometry.AREA;                           % [m^2]    cross-section area
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                        % [kg/m^3]

            Fgrav = -model.G*cos(model.ANGLE*pi/180)*RHOV.*vapor.VF(liquid,zIdx).*AREA; % [N/m]
        end

        function Fbuoy = FBUOY(vapor,liquid,zIdx)
        %FBUOY Vapor buoyancy
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            AREA = vapor.inputSet.geometry.AREA;                           % [m^2]    cross-section area
            DPDZ = vapor.mix.DPDZ(zIdx);                                   % [Pa/m] pressure gradient
            
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
            tauwv  = MULT.*vapor.U(zIdx).*abs(vapor.U(zIdx));              % [Pa]     wall shear stress
           
        end
        
        function Fshear = FSHEAR(vapor,liquid,zIdx)
        %FSHEAR wall and interfacial shear force
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            switch vapor.inputSet.model.INTAREA
                case 'DISPGAS2DISPLIQ'

                    flowregime = vapor.FLOWREGIME(liquid,zIdx);
                    PERIM = vapor.inputSet.geometry.PERIM;                 % [m]      perimeter
                    TAUWL  = liquid.TAUWL(zIdx);
                    TAUWV  = vapor.TAUWV(zIdx);
                
                    % Dispersed gas
                    Fshear  = -vapor.VF(liquid,zIdx).*PERIM.*TAUWL;        % [N/m]
       
                    % Dispersed liquid
                    Idl = ismember(flowregime,{'intermediate','annular','dffb'});
                    Fwshearl = -vapor.VF(liquid,zIdx).*PERIM.*TAUWV;       % [N/m]
                    Fshear(Idl)=Fwshearl(Idl);

                case 'SMOOTHSPHERICAL'
                    flowregime = vapor.FLOWREGIME(liquid,zIdx);
                    PERIM = vapor.inputSet.geometry.PERIM;                 % [m]      perimeter
                    TAUWL  = liquid.TAUWL(zIdx);
                    TAUWV  = vapor.TAUWV(zIdx);
                
                    % Dispersed gas
                    Fshear  = -vapor.VF(liquid,zIdx).*PERIM.*TAUWL;        % [N/m]

                    % Dispersed liquid
                    Idl = ismember(flowregime,{'annular','dffb'});
                    Fwshearl = -vapor.VF(liquid,zIdx).*PERIM.*TAUWV;       % [N/m]
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

            mflux = vapor.MWALEVAP(liquid,zIdx) + vapor.MINTEVAP(liquid,zIdx);
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

