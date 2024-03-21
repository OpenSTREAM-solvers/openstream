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
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Liquid wall heat flux
        MEVAP        (:,:) double  {mustBeNumeric,mustBeNonpositive}       =-1.                   % [kg/s/m^2] Wall evaporation mass flux    
        
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

        function Mtot = MTOT(liquid,zIdx)
        %MTOT Total
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            %TODO: add interfacial mass terms later
            geom = liquid.inputSet.geometry;
            Mtot  = sum(geom.PERIM.*liquid.MEVAP(zIdx,:),2);
        end
        
        function Htot = HTOT(liquid,zIdx)
        %HTOT Total
        %
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            %TODO: add interfacial mass terms later
            %TODO: add non-equilibrium terms later
            geom  = liquid.inputSet.geometry;
            props = liquid.fluid;
            Htot  = sum(geom.PERIM.*liquid.HFLUX(zIdx,:),2)+sum(geom.PERIM.*liquid.MEVAP(zIdx,:),2).*(props.HG-props.HF);
        end
        
        
        
        
        
        
        
    end
end

