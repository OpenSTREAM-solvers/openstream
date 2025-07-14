classdef (Abstract) AbstractMixture < Solvers.AbstractField
    %ABSTRACTFIELD defines all methods shared by all field class definitions across all
    %solvers
    %
    %   TODO: Detailed explanations

    properties (Abstract,  SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                                                % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                                                % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                                                % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % Saved detailed pressure drops
        DPSUM        (1,1) struct                                                                 % Saved detailed cumulative pressure drops
        ACC          (1,1) struct                                                                 % Saved detailed acceleration terms
        TRELAX       (1,1) struct                                                                 % Time relaxation terms

        % Phases
        liquid
        vapor
    end
    
    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
        
        % Iteration properties
        ITR
 
    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
    end


    %% Methods
    methods
        
        
    end


    %% Helper functions
    methods(Access = protected, Hidden = true)

        function MFLUX_CALC(mix, zIdx)
        %MFLUX_CALC Helper function to calculate mass flux [kg/m^2-s]
        %
        
            mix.mflux(zIdx) = mix.W(zIdx)./mix.inputSet.geometry.AREA;
        end

        function XEQ_CALC(mix, zIdx)
        %XEQ_CALC Helper function to calculate equilibrium quality [-]
        %  
            mix.xeq(zIdx) = (mix.H(zIdx)-mix.fluid.HF)./ mix.fluid.HFG;
        end
    end
end

