classdef Liquid < Solvers.AbstractPhase
    %LIQUID Represents the liquid phase in a mixture solver simulation.
    %
    % The Liquid class provides access to liquid-specific properties and
    % calculations derived from the mixture solution. It encapsulates
    % methods for computing flow, thermodynamic, and transport properties
    % of the liquid phase at each axial node.
    %
    % Responsibilities:
    %
    % - Compute liquid mass fraction and volumetric fraction
    % - Calculate liquid velocity, enthalpy, and temperature
    % - Evaluate wall heat flux contributions to the liquid phase
    % - Support derived quantities such as Reynolds number and mass flux
    %
    % Notes:
    %
    % - All methods assume access to a valid :class:`Solvers.Mixture.Mixture` object
    % - Axial indexing is optional; defaults to full axial domain
    % - Velocity and enthalpy calculations include fallback logic to handle single-phase vapor regions and numerical stability

    properties (SetAccess=private, GetAccess=private)

        mix                                                                % :class:`Solvers.Mixture.Mixture` object
        NZ                                                                 % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
    
    end

    methods
        
        function liquid = Liquid(mix)
            %LIQUID Constructor
            %
            % Initializes the Liquid object from one or more instances of the
            % :class:`Solvers.Mixture.Mixture` class. Each Liquid instance
            % stores a reference to its corresponding Mixture object and the
            % number of axial nodes (NZ).
            %
            % Input:
            %
            % - mix — Array of :class:`Solvers.Mixture.Mixture` objects representing the simulation state
            %
            % Notes:
            %
            % - Supports vectorized initialization for transient simulations
            % - Assumes each :class:`Solvers.Mixture.Mixture` object is fully initialized

            arguments
                mix {mustBeA(mix, 'Solvers.Mixture.Mixture')}
            end

            liquid(1:length(mix)) = liquid;
            for i = 1:length(mix)
                liquid(i).mix = mix(i);
                liquid(i).NZ = mix(i).NZ;
            end
        end

        function time = TIME(liquid)
            %TIME Time series [s]

            time = liquid.mix.TIME;
        end

        function z = Z(liquid, zIdx)
            %Z Axial node positions [m]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            z = liquid.mix.Z(zIdx);
        end

        function x = X(liquid, zIdx)
            %X Liquid mass fraction [-]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            x = 1-liquid.mix.X(zIdx);
        end

        function vf = VF(liquid, zIdx)
            %VF Liquid volumetric fraction [-]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            vf = 1-liquid.mix.VF(zIdx);
        end

        function w = W(liquid, zIdx)
            %W Liquid mass flow rate [kg/s]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            w = liquid.X(zIdx) .* liquid.mix.W(zIdx);
        end

        function u = U(liquid, zIdx)
            %U Liquid velocity [m/s]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            u = liquid.MFLUX(zIdx)./liquid.VF(zIdx)./liquid.mix.fluid.RHOL(liquid.H(zIdx));

            % Set to the mixture velocity in the single-phase vapor region
            mixU           = liquid.mix.U(zIdx);
            singlePhaseIdx = isnan(u);
            u(singlePhaseIdx) = mixU(singlePhaseIdx);
        end

        function h = H(liquid, zIdx)
            %H Liquid enthalpy [J/kg]
            %
            % Calculated based on mixture and vapor enthalpies, and vapor
            % quality.

            % TODO: Find a better way to prevent division by small 1-X and negative h

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            % X = max(liquid.mix.X(zIdx),liquid.mix.XEQ(zIdx));             % Account for potential subcooled liquid
            % h = (liquid.mix.H(zIdx)-X.*liquid.mix.fluid.HG)./(1-X);

            X = liquid.mix.X(zIdx);
            h = (liquid.mix.H(zIdx)-X.*liquid.mix.vapor.H(zIdx))./(1-X);

            fluid = liquid.mix.fluid;
            h(isnan(h) | isinf(h)) = fluid.HF;
            h = min(h,liquid.mix.fluid.HF);                                % Constrain solution so that Hl > Hf (no superheated liquid)
        end

        function mflux = MFLUX(liquid, zIdx)
            %MFLUX Liquid mass flux [kg/m^2/s]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            mflux = liquid.W(zIdx)./liquid.mix.inputSet.geometry.AREA;
        end

        function re = RE(liquid, zIdx)
            %RE Liquid Reynolds number [-]
            
            %TODO: It is not clear how the liquid and vapor Reynolds number should be defined for two-phase applications

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            re = 4.*liquid.W(zIdx)./liquid.mix.fluid.MUL(liquid.H(zIdx))...
                ./sum(liquid.mix.inputSet.geometry.PERIM);
        end

        function hfluxwalheat = HFLUX(liquid, zIdx)
            %HFLUX Wall heat flux to liquid phase [W/m^2]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            hfluxwalheat = liquid.mix.HFLUX(zIdx,:)-liquid.mix.vapor.HFLUX(zIdx)-liquid.mix.vapor.HFLUXWALEVAP(zIdx);
        end

        function t = T(liquid, zIdx)
            %T Liquid temperature [K]

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            t = liquid.mix.fluid.T(liquid.H(zIdx));
        end

        function nu = NU(liquid, zIdx)
            %NU Liquid wall Nusselt number [-]
            %
            % Computes the Nusselt number for wall heat transfer to liquid
            % based on :attr:`Inputs.Model.SPHTM` model.

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            model = liquid.mix.inputSet.model;
            geom  = liquid.mix.inputSet.geometry;
            fluid = liquid.mix.fluid;

            Re = liquid.RE(zIdx);                                          % [-] Reynolds number
            Pr = fluid.PRANDTLL(liquid.H(zIdx));                           % [-] Prandtl number

            % Calculate Nusselt number
            switch model.SPHTM
                case 'DITTUSBOELTER'
                    nu = 0.023.*Re.^0.8.*Pr.^0.4;                          % [-]
                case 'DITTUSBOELTERGEN' 
                    c = model.DITTUSBOELTERCOEF;
                    nu = c(1).*Re.^c(2)*Pr.^c(3);                          % [-]
            end
            nu = repmat(nu,1,geom.NWALL);                                  % Expand to all walls
        end

        function hwall = HWALL(liquid, zIdx)
            %HWALLLIQ Single-phase liquid wall heat transfer coefficient [W/m^2/K]
            %
            % Computes the wall heat transfer coefficient using liquid thermal
            % conductivity and Nusselt number.
  
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            geom  = liquid.mix.inputSet.geometry;
            fluid = liquid.mix.fluid;

            k = fluid.KL(liquid.H(zIdx));                                  % [W/m/K] Fluid thermal conductivity based on liquid phase
            HDIAM = geom.HDIAM;                                            % [m] Hydraulic diameter
            hwall = liquid.NU(zIdx).*k./HDIAM;                             % [W/m^2/K] Single phase
        end

    end

end