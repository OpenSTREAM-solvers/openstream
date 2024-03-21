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
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Vapor wall heat flux
        MEVAP        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [kg/s/m^2] Wall evaporation mass flux    
        
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

        function Mtot = MTOT(vapor,zIdx)
        %MTOT Total
        %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            %TODO: add interfacial mass terms later
            geom = vapor.inputSet.geometry;
            Mtot  = sum(geom.PERIM.*vapor.MEVAP(zIdx,:),2);
        end
        
        function Htot = HTOT(vapor,zIdx)
        %HTOT Total
        %
            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            
            %TODO: add interfacial mass terms later
            %TODO: add non-equilibrium terms later
            geom = vapor.inputSet.geometry;
            Htot  = sum(geom.PERIM.*vapor.HFLUX(zIdx,:),2);
        end
        
        
        
        
        
        
        
        
       
    end
end

