classdef Vapor < Solvers.AbstractPhase
    %VAPOR Represents the vapor phase in a mixture solver simulation.
    %
    % The Vapor class provides access to vapor-specific properties and
    % calculations derived from the mixture solution. It encapsulates
    % methods for computing flow, thermodynamic, and transport properties
    % of the vapor phase at each axial node.
    %
    % Responsibilities:
    %
    % - Compute vapor mass fraction and void fraction
    % - Calculate vapor velocity, enthalpy, and temperature
    % - Evaluate wall heat flux and wall evaporation contributions
    % - Support derived quantities such as Reynolds number and mass flux
    %
    % Inherits from:
    %
    % - :class:`Solvers.AbstractPhase`
    %
    % Notes:
    %
    % - All methods assume access to a valid :class:`Solvers.MixtureSolver.Mixture` object
    % - Axial indexing is optional; defaults to full axial domain
    % - Enthalpy calculations adapt to thermal non-equilibrium models
    % - Velocity and enthalpy calculations include fallback logic to handle single-phase liquid regions and numerical stability

    properties (SetAccess=private, GetAccess=private)
        mix                                                                % :class:`Solvers.MixtureSolver.Mixture` object
        NZ                                                                 % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
    end

    methods
        function vapor = Vapor(mix)
            %VAPOR Constructor of the Vapor class
            %
            % Initializes the Vapor object from one or more instances of the
            % :class:`Solvers.MixtureSolver.Mixture` class. Each Vapor instance
            % stores a reference to its corresponding Mixture object and the
            % number of axial nodes (NZ).
            %
            % Input:
            %
            % - mix — Array of :class:`Solvers.MixtureSolver.Mixture` objects representing the simulation state
            %
            % Notes:
            %
            % - Supports vectorized initialization for transient simulations
            % - Assumes each :class:`Solvers.MixtureSolver.Mixture` object is fully initialized

            arguments
                mix {mustBeA(mix, 'Solvers.Mixture.Mixture')}
            end

            vapor(1:length(mix)) = vapor;
            for i = 1:length(mix)
                vapor(i).mix = mix(i);
                vapor(i).NZ = mix(i).NZ;
            end
        end

        function time = TIME(vapor)
            %TIME Time series [s]

            time = vapor.mix.TIME;
        end

        function z = Z(vapor, zIdx)
            %Z Axial nodes [m]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            z = vapor.mix.Z(zIdx);
        end

        function x = X(vapor, zIdx)
            %X Vapor mass fraction [-]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            x = vapor.mix.X(zIdx);
        end

        function vf = VF(vapor, zIdx)
            %VF Void fraction [-]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            vf = vapor.mix.VF(zIdx);
        end

        function w = W(vapor, zIdx)
            %W Vapor mass flow rate [kg/s]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            w = vapor.X(zIdx) .* vapor.mix.W(zIdx);
        end

        function u = U(vapor, zIdx)
            %U Vapor velocity [m/s]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            u = vapor.MFLUX(zIdx)./vapor.VF(zIdx)./vapor.mix.fluid.RHOV(vapor.H(zIdx));

            % Set to the mixture velocity in the single-phase liquid region
            mixU           = vapor.mix.U(zIdx);
            singlePhaseIdx = isnan(u);
            u(singlePhaseIdx) = mixU(singlePhaseIdx);
        end

        function h = H(vapor, zIdx)
            %H Vapor enthalpy [J/kg]
            %
            %Calculation depends on non equilibrium model

            %TODO: Find a better way to prevent division by small X

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            model = vapor.mix.inputSet.model;

            switch model.THERMALNONEQ

                case 'RELAXATION'
                    WV = vapor.mix.TRELAX.WV(zIdx,:);
                    h = sum(vapor.mix.TRELAX.HV(zIdx,:).*WV,2)./sum(WV,2);
                    h(isnan(h)) = vapor.mix.fluid.HG;

                otherwise
                    X = min(vapor.mix.X(zIdx),vapor.mix.XEQ(zIdx));        % Account for potential superheated vapor
                    h = (vapor.mix.H(zIdx)-(1-X).*vapor.mix.fluid.HF)./X;
                    %h = max(h,vapor.mix.fluid.HG);                         % No subcooled vapor
                    fluid = vapor.mix.fluid;
                    h(isnan(h) | isinf(h)) = fluid.HG;
            end
        end

        function mflux = MFLUX(vapor, zIdx)
            %MFLUX Vapor mass flux [kg/m^2-s]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            mflux = vapor.W(zIdx)./vapor.mix.inputSet.geometry.AREA;
        end

        function re = RE(vapor, zIdx)
            %RE Vapor Reynolds number [-]

            %TODO: Check definition

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            %re = 4.*vapor.W(zIdx)./vapor.mix.fluid.MUV(vapor.H(zIdx))...
            %        ./sum(vapor.mix.inputSet.geometry.PERIM);

            geom  = vapor.mix.inputSet.geometry;
            fluid = vapor.mix.fluid;
            re = fluid.RHOV(vapor.H(zIdx)).*vapor.U(zIdx).*geom.HDIAM./fluid.MUV(vapor.H(zIdx));
        end

        function hfluxwalevap = HFLUXWALEVAP(vapor, zIdx)
            %HFLUX Wall evaporation heat flux [W/m^2]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            hfluxwalevap = vapor.mix.WALEVAPRATIO(zIdx).*vapor.mix.HFLUX(zIdx,:);
        end

        function hfluxwalheat = HFLUX(vapor, zIdx)
            %HFLUX Wall heat flux to vapor [W/m^2]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            geom  = vapor.mix.inputSet.geometry;
            hfluxwalheat = vapor.mix.HWALHEAT(zIdx)./geom.PERIM;
        end

        function t = T(vapor, zIdx)
            %T Vapor temperature [K]

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
            t = vapor.mix.fluid.T(vapor.H(zIdx));
        end

    end

end