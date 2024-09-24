classdef Drop < Solvers.ThreeField.Drop
    %DROP Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % % Solver properties
        % NZ                                                                 = 0                    % [-] Number of axial steps
        % NTIME                                                              = 0                    % [-] Number of time steps
        % TIME                                                               = 0                    % [s] Time series
        % DT                                                                 = 0                    % [s] Time step size
        % TIDX                                                               = 1                    % [-] Time step index
        % Z                                                                  = 1.                   % [m] Elevation
        % 
        % % Flow properties
        % W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        % U            (:,1) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        % H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        % 
        % % Iteration properties
        % ITR

     end

     properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)
        
        % DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        % inputSet                   {isa(inputSet,'Inputs.InputSet')}
        % fluid                      {isa(fluid,'Inputs.FluidProperties')}
     end
    
    

    methods
        
        % Inherit from Solvers.ThreeField.Drop
        % Add modifications here
    end

end

