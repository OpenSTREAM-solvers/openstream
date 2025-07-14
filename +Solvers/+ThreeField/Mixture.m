classdef Mixture < Solvers.AbstractMixture
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    % Inherited properties
    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % Flow properties
        W                                                                  = 1.                   % [kg/s] Mass flow rate
        P                                                                  = 7E6                  % [Pa] Pressure
        H                                                                  = 1E6                  % [J/kg] Enthalpy
        DP                                                                                        % Saved detailed pressure drops
        DPSUM                                                                                     % Saved detailed cumulative pressure drops
        ACC                                                                                       % Saved detailed acceleration terms
        TRELAX                                                                                    % Time relaxation terms

        % Phases
        mixSolver_mix (:,1) Solvers.Mixture.Mixture                                             % Mixture handles from MixtureSolver
        liquid                                                                                  % Liquid handle from ThreeFieldSolver
        vapor                                                                                   % A TF-specific vapor can be imp.
    end

    properties (Access=protected) % TODO: is this the best access setting?
        
        film    Solvers.ThreeField.Film
        drop    Solvers.ThreeField.Drop

    end
    
    properties (Access=private)
        
        
        mflux         (:,1) double  {mustBeNumeric}                        = 1.                 % [kg/m^2-s] Mass flux
        xeq           (:,1) double  {mustBeNumeric}                        = 1.                 % [-] Equilibrium quality
        x             (:,1) double  {mustBeNumeric}                        = 1.                 % [-] Vapor quality
        vf            (:,1) double  {mustBeNumeric}                        = 1.                 % [-] Void fraction
        chf           (:,:) double  {mustBeNumeric}                                             % [-] Critical Heat Flux
        cbt           (:,:) logical                                                             % [-] Critical Boiling Transition flag
        rho           (:,1) double  {mustBeNumeric}                        = 1.                 % [kg/m^3] Mixture density
        oafidx_const        double  {mustBeNumeric}                        = []                 % [-] Solved index for onset of annular flow
        sigm_const    (:,1) double  {mustBeNumeric}                        = []                 % [-] Solved sigmoid fnc value
        relaxtevap    (:,:) double  {mustBeNumeric}                                              % [-] Time relaxation for interfacial evaporation
        relaxtcond    (:,:) double  {mustBeNumeric}                                              % [-] Time relaxation for interfacal condensation
    
    end 

    %% Constructor method
    methods
        
        function mix = Mixture(mixSolver_mix, liquid)
            %MIXTURE Creates a Mixture, mix
            %   Detailed explanation goes here
            arguments
                mixSolver_mix   Solvers.Mixture.MixtureSolver
                liquid          Solvers.ThreeField.Liquid
            end

            if nargin > 0

                % Store inputSet as object property
                mix.inputSet = mixSolver_mix(1).inputSet;
                mix.fluid  = mixSolver_mix(1).fluid;

                % Overload copyable properties (order is important due to the setter functions)
                mix.flowProperties = {'TRELAX','W','P','H','DP','DPSUM','ACC','ITR'};

                %TODO: loop through multiple mix and liquids?

                % Store mixSolver_mix and liquid
                mix.mixSolver_mix = mixSolver_mix;
                mix.liquid = liquid;
                mix.vapor = mixSolver_mix.vapor;

                % Calculate combined W, P, H
                mix.W_CALC();
                mix.P_CALC();
                mix.H_CALC();

                % Copy flow properties
                % TODO: only copy a subset of the mix.flowProperties
                mixSolver_mix.copyFlowProperties(mix, propNames={'TRELAX','DP','DPSUM','ACC','ITR'}, all=true);

            end

        end

        
    end

    %% Helper methods
    methods
        
        function W_CALC(mix)
            mix.W = mix.liquid.W + mix.vapor.W;
        end

        function P_CALC(mix)
            % TODO: check if there are edge cases here...
            mix.P = mix.vapor.P;
        end

        function H_CALC(mix)
            % TODO:
            % something to do with the liquid (film, drop) quality and
            % enthalpy
            %
            %   mix.liquid.X;
            %   mix.liquid.H;
            %
            % and vapor quality and enthalpy
            %   
            %   mix.vapor.X;
            %   mix.vapor.H;
            %
            % But also consider superheat/subcool conditions...
        end

        function DP_CALC(mix)
            mix.DP = mix.mixSolver_mix.DP;
        end
    end

end

