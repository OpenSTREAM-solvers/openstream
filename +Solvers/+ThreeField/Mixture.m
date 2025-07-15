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
        vapor                                                                                   % A TF-specific vapor can be implemented
    end

    properties (Access=protected) % TODO: is this the best access setting?
        
        film    Solvers.ThreeField.Film
        drop    Solvers.ThreeField.Drop

    end
    
    % Concrete class properties
    properties (Access=protected)
        
        mflux                                                              = 1.                 % [kg/m^2-s] Mass flux
        xeq                                                                = 1.                 % [-] Equilibrium quality
        x                                                                  = 1.                 % [-] Vapor quality
        vf                                                                 = 1.                 % [-] Void fraction
        chf                                                                                     % [-] Critical Heat Flux
        cbt                                                                                     % [-] Critical Boiling Transition flag
        rho                                                                = 1.                 % [kg/m^3] Mixture density
        oafidx_const                                                       = []                 % [-] Solved index for onset of annular flow
        sigm_const                                                         = []                 % [-] Solved sigmoid fnc value
        relaxtevap                                                                              % [-] Time relaxation for interfacial evaporation
        relaxtcond                                                                              % [-] Time relaxation for interfacal condensation
    
    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess={?Solvers.AbstractField, ?Solvers.AbstractPhase})
        
        DZ                                                                 = 0                    % [m] Axial step size
        inputSet                   
        fluid                      
    end

    %% Constructor method
    methods
        
        function mix = Mixture(mixSolver_mix, liquid)
            %MIXTURE Creates a Mixture, mix
            %   Detailed explanation goes here
            
            % arguments
            %     mixSolver_mix   Solvers.Mixture.Mixture            
            %     liquid          Solvers.ThreeField.Liquid 
            % end

            % Overload copyable properties (order is important due to the setter functions)
            mix.flowProperties = {'TRELAX','W','P','H','DP','DPSUM','ACC','ITR'};

            if nargin > 0

                % Initialize the mixture
                mix.initialize(mixSolver_mix, liquid);

                % Update properties using mix.liquid and mix.vapor
                mix.updateProperties();
                mix.copyFlowProperties();

            end

        end

        function initialize(mix, mixSolver_mix, liquid)

            % Store inputSet as object property
            mix.inputSet = mixSolver_mix(1).inputSet;
            mix.fluid  = mixSolver_mix(1).fluid;

            %TODO: loop through multiple mix and liquids?

            % Store mixSolver_mix and liquid
            mix.mixSolver_mix = mixSolver_mix;
            mix.liquid = liquid;
            mix.vapor = mixSolver_mix.vapor;

            % Copy setup from mixSolver_mix
            mix.copySetup();

            % Copy flow properties from mixSolver_mix
            mix.copyFlowProperties();

        end

        function updateProperties(mix)
            
            % Calculate combined W, P, H
            mix.W_CALC();
            % mix.P_CALC();
            % mix.H_CALC();

        end

        function copySetup(mix)
            
            props = {'NZ','DZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid'};
            for p = props
                mix.(p{:}) = mix.mixSolver_mix.(p{:});
            end
        end


        function copyFlowProperties(mix)

            % Copy flow properties
            % TODO: only copy a subset of the mix.flowProperties
            % NOTE: maybe the full set can be copied directly?
            mix.mixSolver_mix.copyFlowProperties(mix, propNames={'P', 'H', 'TRELAX','DP','DPSUM','ACC','ITR', 'HFLUX'}, all=true);
            props = {'mflux', 'xeq', 'x', 'vf', 'chf', 'cbt', 'rho', 'relaxtevap', 'relaxtcond'};
            for p=props
                mix.(p{:}) = mix.mixSolver_mix.(upper(p{:}));
            end
        end

        
    end

    %% Helper methods
    methods
        
        function W_CALC(mix)

            % While initializing ThreeFieldSolver, length of liquid.W may be
            % 1. Use value from mixsolver_mix
            if length(mix.liquid.W) == 1
                mix.W = mix.mixSolver_mix.W;
            else
                mix.W = mix.liquid.W + mix.vapor.W;
            end
        end

        % function H_CALC(mix)
        %     % TODO:
        %     % something to do with the liquid (film, drop) quality and
        %     % enthalpy
        %     %
        %     %   mix.liquid.X;
        %     %   mix.liquid.H;
        %     %
        %     % and vapor quality and enthalpy
        %     %   
        %     %   mix.vapor.X;
        %     %   mix.vapor.H;
        %     %
        %     % But also consider superheat/subcool conditions...
        % end
       
    end

end

