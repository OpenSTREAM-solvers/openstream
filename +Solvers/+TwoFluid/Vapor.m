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

            %Hevap = vapor.MEVAP(liquid,zIdx).*(HF-vapor.H(zIdx));          % [W/s/m]
            Hevap = vapor.MEVAP(liquid,zIdx).*(liquid.H(zIdx)-vapor.H(zIdx));  % [W/s/m]
        end
        
%         function Hcond = HCOND(vapor,liquid,zIdx)
%         %HCOND Interfacial energy transfer from condensation
% 
%             if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
%             
%             HG = vapor.fluid.HG;
% 
%             Hcond = vapor.MCOND(liquid,zIdx).*(HG-vapor.H(zIdx));          % [W/s/m]
%         end
        
        function Htot = HTOT(vapor,liquid,zIdx)
        %HTOT Total energy transfer
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Htot  = vapor.HWHF(liquid,zIdx) + vapor.HWALL(liquid,zIdx);    % [W/m]
            %Htot  = vapor.HWHF(liquid,zIdx) + vapor.HWALL(liquid,zIdx) + vapor.HEVAP(liquid,zIdx); % [W/m]
        end
        
    end
end

