classdef Film < Solvers.AbstractFilm
    %FILM Class for modeling liquid film in three-field solver
    %
    % This class encapsulates the physical and numerical properties of the film field,
    % including flow variables and phase interactions.
    
     properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})
        
        % Solver state

        NZ                                                                 = 0                    % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
        NTIME                                                              = 0                    % Number of time steps [-]
        TIME                                                               = 0                    % Time series [s]
        DT                                                                 = 0                    % Time step size [s] from :attr:`Inputs.Options.TSTEP`
        TIDX                                                               = 1                    % Time step index [-]
        Z                                                                  = 1.                   % Elevation [m]
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % Film heat flux [W/m^2]
        %MEVAP        (:,:) double  {mustBeNumeric,mustBeNonpositive}       =-1.                   % Evaporation mass flux   [kg/s/m^2]    
        
        % Flow properties

        W            (:,:) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        U            (:,:) double  {mustBeNumeric}                         = 1.                   % Velocity [m/s]
        H            (:,:) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]

        % Iteration properties
        
        ITR                                                                                       % Iteration tracking

     end

end
