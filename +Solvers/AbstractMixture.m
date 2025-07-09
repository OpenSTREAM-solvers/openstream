classdef (Abstract) AbstractMixture < Solvers.AbstractField
    %ABSTRACTFIELD defines all methods shared by all field class definitions across all
    %solvers
    %
    %   TODO: Detailed explanations
    
    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
        
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                         = 7E6                  % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % Saved detailed pressure drops
        DPSUM        (1,1) struct                                                                 % Saved detailed cumulative pressure drops
        ACC          (1,1) struct                                                                 % Saved detailed acceleration terms
        TRELAX       (1,1) struct                                                                 % Time relaxation terms
        
        % Iteration properties
        ITR

        % Phases
        liquid
        vapor
    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
    end


    %% Setter methods
    methods
        
        function set.W(mix, val)
        %SET.W Setter for W, mass flow rate [kg/s]
        %  mix.mflux is calculated upon setting mix.W

            % Identify indexes to be updated
            zIdx = find(mix.W~=val);
            if isempty(zIdx), zIdx = (1:mix(1).NZ).'; end
        
            % Set mix.W value
            mix.W = val;

            % Calculate mix.mflux
            mix.MFLUX_CALC(zIdx);
        end
        
        function set.H(mix, val)
        %SET.H Setter for H, enthalpy [J/kg]
        %  mix.rho, mix.x and mix.xeq are calculated upon setting mix.H
            
            % Identify indexes to be updated
            zIdx = find(mix.H~=val);
            if isempty(zIdx), zIdx = (1:mix(1).NZ).'; end
            
            % Set mix.H value
            mix.H = val;

            % Calculate mix.rho (mix.rho calls mix.vf, which calls mix.x, which calls mix.xeq)
            mix.RHO_CALC(zIdx);
        end
    end
end

