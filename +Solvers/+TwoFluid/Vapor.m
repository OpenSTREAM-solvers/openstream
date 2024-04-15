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
        
        function t = T(vapor,zIdx)
        %T Vapor temperature
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            t = vapor.fluid.T(vapor.H(zIdx));                              % [K]
        end

        function rhov = RHOV(vapor,zIdx)
        %RHOV Vapor density
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            rhov = vapor.fluid.RHOV(vapor.H(zIdx));                            % [kg/m^3]
        end

        function muv = MUV(vapor,zIdx)
        %MUV Vapor dynamic viscosity
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            muv = vapor.fluid.MUV(vapor.H(zIdx));                            % [Pa.s]
        end
        
        function vf = VF(vapor,liquid,zIdx)
        %VF Volumetric fraction
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            %AREA = vapor.inputSet.geometry.AREA;
            %RHOV = vapor.fluid.RHOV(vapor.H(zIdx));
            
            %vf = vapor.W(zIdx)./vapor.U(zIdx)./RHOV./AREA;                 % [-]
            vf = 1 - liquid.VF(zIdx);                                      % [-]
        end
        
        function ai = AI(vapor,liquid,zIdx)
        %AI Volumetric interfacial area
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            ai = liquid.AI(zIdx);                                          % [m^2/m^3]
        end
        
        function l = L(vapor,liquid,zIdx)
        %L Interfacial length scale (e.g. bubble of drop diameter)
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            l = liquid.L(zIdx);                                            % [m]
        end

        function vaf = VAF(vapor,liquid,zIdx)
        %VAF Void area fraction
        %
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            vaf = 1-liquid.WAF(zIdx);
        end
        
        function hflux = HFLUX(vapor,liquid,zIdx)
        %HFLUX Wall heat flux to vapor phase
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            HFLUX = vapor.mix.HFLUX;
            
            hflux = HFLUX(zIdx,:)-liquid.HFLUX(zIdx);                      % [W/m^2] 
        end
        
        function inthflux = INTHFLUX(vapor,liquid,zIdx)
        %INTHFLUX Interfacial heat flux to vapor phase
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            inthflux = -liquid.INTHFLUX(vapor,zIdx);                       % [W/m^2]
        end
        
        
        function Mwevap = MWEVAP(vapor,liquid,zIdx)
        %MWEVAP Wall evaporation mass flux
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mwevap = -liquid.MWEVAP(zIdx);                                 % [kg/s/m^2]
        end
        
        function Miexch = MIEXCH(vapor,liquid,zIdx)
        %MWEVAP interfacial mass flux
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Miexch = -liquid.MIEXCH(vapor,zIdx);                           % [W/m];
        end
        
        function Mwall = MWALL(vapor,liquid,zIdx)
        %MWALL Wall evaporation mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mwall  = -liquid.MWALL(zIdx);                                  % [kg/s/m]
        end
        
        function Mevap = MEVAP(vapor,liquid,zIdx)
        %MEVAP Interfacial evaporation mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mevap = -liquid.MEVAP(vapor,zIdx);                             % [kg/s/m]
        end
        
        function Mcond = MCOND(vapor,liquid,zIdx)
        %MCOND Interfacial condensation mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mcond = -liquid.MCOND(vapor,zIdx);                             % [kg/s/m]
        end
        

        function Mtot = MTOT(vapor,liquid,zIdx)
        %MTOT Total mass transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mtot  = vapor.MWALL(liquid,zIdx);                              % [kg/s/m]
            %Mtot  = vapor.MWALL(liquid,zIdx) + vapor.MEVAP(liquid,zIdx) + vapor.MCOND(liquid,zIdx); % [kg/s/m]
        end
        
        
        function Hwhf = HWHF(vapor,liquid,zIdx)
        %HWALL wall energy transfer from wall heat flux

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            PERIM = vapor.inputSet.geometry.PERIM;

            Hwhf = sum(PERIM.*vapor.HFLUX(liquid,zIdx),2);                        % [W/m]
        end
        
        function Hwall = HWALL(vapor,liquid,zIdx)
        %HWALL wall energy transfer from mass transfer

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            HG = vapor.fluid.HG;

            Hwall = vapor.MWALL(liquid,zIdx).*(HG-vapor.H(zIdx));          % [W/m]
        end
        
        function Hevap = HEVAP(vapor,liquid,zIdx)
        %HEVAP Interfacial energy transfer from evaporation

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            HF = vapor.fluid.HF;
            HG = vapor.fluid.HG;

            Hevap = vapor.MEVAP(liquid,zIdx).*(HG-vapor.H(zIdx));          % [W/s/m]
            %Hevap = vapor.MEVAP(liquid,zIdx).*(liquid.H(zIdx)-vapor.H(zIdx));  % [W/s/m]
        end
        
        function Hcond = HCOND(vapor,liquid,zIdx)
        %HCOND Interfacial energy transfer from condensation

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            HG = vapor.fluid.HG;

            Hcond = vapor.MCOND(liquid,zIdx).*(HG-vapor.H(zIdx));          % [W/s/m]
        end
        
        function Htot = HTOT(vapor,liquid,zIdx)
        %HTOT Total energy transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Htot  = vapor.HWHF(liquid,zIdx) + vapor.HWALL(liquid,zIdx);    % [W/m]
            %Htot  = vapor.HWHF(liquid,zIdx) + vapor.HWALL(liquid,zIdx) + vapor.HEVAP(liquid,zIdx) + vapor.HCOND(liquid,zIdx); % [W/m]
        end
        
        function Fgrav = FGRAV(vapor,liquid,zIdx)
        %FGRAV gravitational force
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            ANGLE = vapor.inputSet.geometry.ANGLE;                        % [rad]    polar angle
            AREA = vapor.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            g = 9.81;                                                      % [m/s^2]  gravitational acceleration constant

            Fgrav  = -cos(ANGLE)*g*vapor.RHOV(zIdx).*vapor.VF(liquid,zIdx).*AREA;  % [N/m]
        end

        function Fpres = FPRES(vapor,liquid,zIdx)
        %FPRES pressure gradient
        %TODO fix indexing when calling function outside of solver with 
        % zIdx = 1
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            AREA = vapor.inputSet.geometry.AREA;                          % [m^2]    cross-section area
            PRES = vapor.mix.P(zIdx);                                     % [Pa] mixture pressure
            %DIFF = diff(PRES);                                            % [Pa] pressure differences
            DIFF = PRES - vapor.mix.P(zIdx-1);                            % [Pa] pressure differences
            %DIFF(length(zIdx))=DIFF(length(zIdx)-1);                      % add one more element of same value

            DPDZ = DIFF/vapor.DZ;                                         % [Pa/m] pressure gradient
            
            Fpres  = - AREA*vapor.VF(liquid,zIdx).*DPDZ;                         % [N/m]
        end

        function re = RE(vapor, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            PERIM = vapor.inputSet.geometry.PERIM;                        % [m] Perimeter
            
            re = 4.*vapor.W(zIdx)./vapor.MUV(zIdx)./PERIM;               % [-]
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
            MULT  = 0.5*vapor.VAF(liquid,zIdx).*vapor.FRIC(zIdx).*vapor.RHOV(zIdx);
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

            Fmwall = -liquid.FMWALL(zIdx);            % [N/m]   (should be positive)

        end
        
        function Ftot = FTOT(vapor,liquid,zIdx)
        %FTOT Total force 
        %TODO Add interfacial mass exchange terms
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            % turn on force terms
            Ftot  = vapor.FPRES(liquid,zIdx) + vapor.FWSHEAR(liquid,zIdx)+vapor.FGRAV(liquid,zIdx) +vapor.FISHEAR(liquid,zIdx)+vapor.FMWALL(liquid,zIdx);% [N/m]
            
            % turn off force terms
            %Ftot=zeros(size(zIdx));% [N/m]  
        end

    end
end

