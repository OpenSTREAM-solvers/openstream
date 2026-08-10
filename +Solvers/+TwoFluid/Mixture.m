classdef Mixture < Solvers.AbstractPhase
    %MIXTURE Class for two-fluid mixture properties in thermal-hydraulic solver
    %
    % Represents combined properties of liquid and vapor phases in a two-fluid
    % solver. Provides methods to compute mixture-level quantities such as
    % mass flow, density, velocity, heat flux, and thermodynamic quality.
    %
    % Responsibilities:
    %
    %   - Aggregate liquid and vapor properties into mixture-level results
    %   - Compute derived quantities (void fraction, equilibrium quality, CHF)
    %   - Provide access to geometry and fluid properties for calculations
    %
    % Key features:
    %
    %   - Supports axial indexing for spatially resolved calculations
    %   - Interfaces with liquid and vapor sub-objects for phase-specific data

    properties (SetAccess=private, GetAccess=private)

        mixture                                                                                   % :class:`Solvers.Mixture.Mixture` object
        liquid                                                                                    % :class:`Solvers.TwoFluid.Liquid` object
        vapor                                                                                     % :class:`Solvers.TwoFluid.Vapor` object
        inputSet       {isa(inputSet,'Inputs.InputSet')}                                          % :class:`Inputs.InputSet` object
        fluid          {isa(fluid,'Inputs.FluidProperties')}                                      % :class:`Inputs.FluidProperties` object
        NZ                                                                                        % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`

    end

    methods

        function mix = Mixture(mixture,liquid,vapor)
            %MIXTURE Constructor for Mixture class
            %
            % Initializes the mixture object by linking liquid and vapor phase objects
            % and copying solver configuration and fluid properties.
            %
            % Inputs:
            %   mixture — :class:`Solvers.Mixture.Mixture` object
            %   liquid  — :class:`Solvers.TwoFluid.Liquid` object
            %   vapor   — :class:`Solvers.TwoFluid.Vapor` object

            arguments
                mixture {mustBeA(mixture,'Solvers.Mixture.Mixture')}
                liquid  {mustBeA(liquid ,'Solvers.TwoFluid.Liquid')}
                vapor   {mustBeA(vapor  ,'Solvers.TwoFluid.Vapor') }
            end

            mix(1:length(liquid)) = mix;
            for i = 1:length(mix)
                mix(i).mixture  = mixture(i);
                mix(i).liquid   = liquid(i);
                mix(i).vapor    = vapor(i);
                mix(i).fluid    = liquid(i).fluid;
                mix(i).inputSet = liquid(i).inputSet;
                mix(i).NZ       = liquid(i).NZ;
            end
        end

        function time = TIME(mix)
            %TIME Time series [s]
            %
            % Returns the time array from the mixture object.
            %
            % Inputs:
            %   mix — :class:`Solvers.TwoFluid.Mixture` object

            time = mix.mixture.TIME;
        end

        function z = Z(mix, zIdx)
            %Z Axial nodes [m]
            %
            % Returns the axial positions for the mixture domain.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end
            z = mix.mixture.Z(zIdx);
        end

        function hflux = HFLUX(mix,zIdx)
            %HFLUX Wall heat flux [W/m^2]
            %
            % Returns the wall heat flux distribution along the axial domain.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Maybe different from mixture HFLUX once a heater model is implemented

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            hflux = mix.mixture.HFLUX(zIdx,:);                             % [W/m^2]
        end

        function lhgr = LHGR(mix,zIdx)
            %LHGR Linear heat generation rate [W/m]
            %
            % Computes the linear heat generation rate from wall heat flux and perimeter.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;
            lhgr = mix.HFLUX(zIdx).*geom.PERIM;                            % [W/m]
        end

        function walevapratio = WALEVAPRATIO(mix, zIdx)
            %WALEVAPRATIO Wall mass evaporation ratio [-]
            %
            % Returns the ratio of wall heat flux converted to evaporation.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            walevapratio = mix.mixture.WALEVAPRATIO(zIdx);                 % [-]
        end

        function w = W(mix, zIdx)
            %W Mixture mass flow rate [kg/s]
            %
            % Computes the total mass flow rate as the sum of liquid and vapor flows.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            w = mix.liquid.W(zIdx) + mix.vapor.W(zIdx);                    % [kg/s]
        end

        function mflux = MFLUX(mix, zIdx)
            %MFLUX Mixture mass flux [kg/m^2/s]
            %
            % Calculates the mixture mass flux using total flow and channel area.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;
            mflux = mix.W(zIdx)./geom.AREA;                                % [kg/s/m^2]
        end

        function rho = RHO(mix,zIdx)
            %RHO Mixture density [kg/m^3]
            %
            % Computes the mixture density based on void fraction and phase densities.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));                      % [kg/m^3] vapor density
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));                     % [kg/m^3] liquid density
            VF   = mix.vapor.VF(mix.liquid,zIdx);                          % [-] Void fraction

            rho = (1-VF).*RHOL + VF.*RHOV;                                 % [kg/m^3]
        end

        function u = U(mix,zIdx)
            %U Mixture velocity [m/s]
            %
            % Calculates the mixture velocity as a mass-weighted average of phase velocities.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));                      % [kg/m^3] vapor density
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));                     % [kg/m^3] liquid density
            VF   = mix.vapor.VF(mix.liquid,zIdx);                          % [-] Void fraction

            u = ((1-VF).*RHOL.*mix.liquid.U(zIdx) + VF.*RHOV.*mix.vapor.U(zIdx))./((1-VF).*RHOL+ VF.*RHOV); % [m/s]
            %u = (mix.liquid.W(zIdx).*mix.liquid.U(zIdx)+mix.vapor.W(zIdx).*mix.vapor.U(zIdx))./mix.W(zIdx); % [m/s]
        end

        function tauw = TAUW(mix, zIdx)
            %TAUW Wall shear stress [N/m^2]
            %
            % Returns the wall shear stress from the mixture object.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            tauw = mix.mixture.TAUW(zIdx);                                 % [Pa/m]
        end

        function dpdz = DPDZ(mix, zIdx)
            %DPDZ Pressure gradient [Pa/m]
            %
            % Computes the axial pressure gradient from mixture pressure drop.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            dpdz = mix.mixture.DP.Tot(zIdx)/mix.mixture.DZ;                % [Pa/m]
        end

        function h = H(mix,zIdx)
            %H Mixture enthalpy [J/kg]
            %
            % Calculates the mixture enthalpy as a mass-weighted average of phase enthalpies.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            h = (mix.liquid.W(zIdx).*mix.liquid.H(zIdx)+mix.vapor.W(zIdx).*mix.vapor.H(zIdx))./mix.W(zIdx); % [J/kg]
        end

        function xeq = XEQ(mix,zIdx)
            %XEQ Equilibrium thermodynamic quality [-]
            %
            % Returns the equilibrium quality from the mixture object.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            xeq = mix.mixture.XEQ(zIdx);                                   % [-]

            %h = mix.H(zIdx);
            %xeq = (h-mix.fluid.HF)./(mix.fluid.HG-mix.fluid.HF); % [-]
        end

        function vf = VF(mix,zIdx)
            %VF Void fraction [-]
            %
            % Computes the vapor volume fraction in the mixture.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            vf = mix.vapor.VF(mix.liquid,zIdx);                            % [-]
        end

        function oafx = OAFX(mix, zIdx)
            %OAFX Onset of annular flow equilibrium quality [-]
            %
            % Returns the OAF quality from the mixture object.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            oafx = mix.mixture.OAFX(zIdx);                                 % [-]
        end

        function afDistr = AFDISTR(mix, param1, param2, zIdx)
            %AFDISTR Annular flow distribution function [-]
            %
            % Computes the annular flow distribution function for given parameters.
            %
            % Inputs:
            %   mix     — :class:`Solvers.TwoFluid.Mixture` object
            %   param1  — First parameter for distribution function
            %   param2  — Second parameter for distribution function
            %   zIdx    — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 4, zIdx = (1:mix(1).NZ).'; end

            afDistr = mix.mixture.AFDISTR(param1,param2,zIdx);             % [-]
        end

        function chf = CHF(mix, zIdx)
            %CHF Critical Heat Flux [W/m^2]
            %
            % Returns the CHF value for each axial location.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            chf = mix.mixture.CHF(zIdx);                                   % [-]
        end

        function cbt = CBT(mix, zIdx)
            %CBT Critical Boiling Transition flag [-]
            %
            % Returns the CBT flag for each axial location.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            cbt = mix.mixture.CBT(zIdx);                                   % [-]
        end

        function t = RELAXTCOND(mix, zIdx)
            %RELAXTCOND Time relaxation for interfacial condensation [s]
            %
            % Returns the relaxation time applied to interfacial condensation processes
            % in the two-fluid mixture model.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            t = mix.mixture.RELAXTCOND(zIdx);                              % [-]
        end

        function t = RELAXTEVAP(mix, zIdx)
            %RELAXTEVAP Time relaxation for interfacial evaporation [s]
            %
            % Returns the relaxation time applied to interfacial evaporation processes
            % in the two-fluid mixture model.
            %
            % Inputs:
            %   mix  — :class:`Solvers.TwoFluid.Mixture` object
            %   zIdx — Axial indices to evaluate (optional)

            %TODO: Results should be updated based on mixture inputs from two-fluid simulation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            t = mix.mixture.RELAXTEVAP(zIdx);                              % [-]
        end

    end

end
