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
            
            x = liquid.W(zIdx)./liquid.mix.W(zIdx);                          % [-]
        end
        
        function t = T(liquid,zIdx)
        %T Liquid temperature
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            P  = liquid.fluid.PRESSURE;
            
            t = liquid.fluid.coolpropH.temperature('P',P,'H',liquid.H(zIdx)); % [K]
        end
        
        function hflux = HFLUX(liquid,zIdx)
        %HFLUX Wall heat flux to liquid phase
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ   = liquid.mix.XEQ;
            HFLUX = liquid.mix.HFLUX;
            
            % Heat flux to liquid phase up to XEQ = XCBT
            XCBT = 0.8;                                                    % XCBT set to XEQ = 0.8 for now
            k = [1; diff(min(XCBT,XEQ))./diff(XEQ)];                       % [-] Pre-CBT ratio
            hflux = k(zIdx).*HFLUX(zIdx,:);                                % [W/m^2] 
        end
        
        function Mwevap = MWEVAP(liquid,zIdx)
        %MWEVAP Wall evaporation mass flux
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ = liquid.mix.XEQ;
            HG  = liquid.fluid.HG;
            HF  = liquid.fluid.HF;
            
            % Mass evaporation starts from XEQ = XOSV
            XOSV = -0.1;                                                   % XOSV set to XEQ = -0.1 for now
            k = [0; diff(max(XOSV,XEQ))./diff(XEQ)];                       % [-] Post-OSV ratio
            %Mwevap = -k(zIdx).*liquid.HFLUX(zIdx)./(HG-HF);                % [kg/s/m^2] Heat flux is only used for evaporation (probably wrong)
            Mwevap = -k(zIdx).*liquid.HFLUX(zIdx)./(HG-liquid.H(zIdx));    % [kg/s/m^2] Heat flux warms up liquid first (if subcooled) before evaporation
        end
        
        function Mwall = MWALL(liquid,zIdx)
        %MWALL Wall evaporation mass transfer
        %No condensation considered at the wall
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;
            
            Mwall = sum(PERIM.*liquid.MWEVAP(zIdx),2);                     % [kg/s/m]
        end

        function Mtot = MTOT(liquid,zIdx)
        %MTOT Total mass transfer
        %TODO: add interfacial mass terms later
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            Mtot  = liquid.MWALL(zIdx);                                    % [kg/s/m]
        end
        
        
        
        function Hwhf = HWHF(liquid,zIdx)
        %HWHF wall energy transfer from wall heat flux

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;

            Hwhf = sum(PERIM.*liquid.HFLUX(zIdx),2);                      % [W/s/m]
        end
        
        function Hwall = HWALL(liquid,zIdx)
        %HWALL wall energy transfer from mass transfer

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            HG = liquid.fluid.HG;

            Hwall = liquid.MWALL(zIdx).*(HG-liquid.H(zIdx));               % [W/s/m]
        end
        
        function Htot = HTOT(liquid,zIdx)
        %HTOT Total energy transfer
        %TODO: add interfacial mass terms later
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            Htot  = liquid.HWHF(zIdx) + liquid.HWALL(zIdx);                % [W/s/m]
        end
        
    end
end

