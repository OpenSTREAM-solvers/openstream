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
            
            P  = vapor.fluid.PRESSURE;
            
            t = vapor.fluid.coolpropH.temperature('P',P,'H',vapor.H(zIdx)); % [K]
        end
        
        function hflux = HFLUX(vapor,zIdx)
        %HFLUX Wall heat flux to vapor phase
        
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            XEQ   = vapor.mix.XEQ;
            HFLUX = vapor.mix.HFLUX;
            
            % Heat flux to liquid phase up to XEQ = 1
            k = [1; diff(min(1,XEQ))./diff(XEQ)];                          % [-] Subcooled / saturation ratio
            hflux = (1-k(zIdx)).*HFLUX(zIdx,:);                            % [W/m^2] 
        end
        
        function Mwevap = MWEVAP(vapor,liquid,zIdx)
        %MWEVAP Wall evaporation mass flux
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mwevap = -liquid.MWEVAP(zIdx);                                 % [kg/s/m^2]
        end
        
        function Mwall = MWALL(vapor,liquid,zIdx)
        %MWALL Wall evaporation mass transfer
        %No condensation considered at the wall
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            PERIM = vapor.inputSet.geometry.PERIM;
            
            Mwall  = sum(PERIM.*vapor.MWEVAP(liquid,zIdx),2);               % [kg/s/m]
        end

        function Mtot = MTOT(vapor,liquid,zIdx)
        %MTOT Total mass transfer
        %TODO: add interfacial mass terms later
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Mtot  = vapor.MWALL(liquid,zIdx);                              % [kg/s/m]
        end
        
        
        function Hwhf = HWHF(vapor,zIdx)
        %HWALL wall energy transfer from wall heat flux

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            PERIM = vapor.inputSet.geometry.PERIM;

            Hwhf = sum(PERIM.*vapor.HFLUX(zIdx),2);                        % [W/m]
        end
        
        function Hwall = HWALL(vapor,liquid,zIdx)
        %HWALL wall energy transfer from mass transfer

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            HG = vapor.fluid.HG;

            Hwall = vapor.MWALL(liquid,zIdx).*(HG-vapor.H(zIdx));          % [W/m]
        end
        
        function Htot = HTOT(vapor,liquid,zIdx)
        %HTOT Total energy transfer
        %TODO: add interfacial mass terms later
        
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end
            
            Htot  = vapor.HWHF(zIdx) + vapor.HWALL(liquid,zIdx);           % [W/m]
        end
        
    end
end

