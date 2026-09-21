classdef Liquid < Solvers.AbstractField
    %LIQUID Class for modeling liquid field in two-fluid solver
    %
    % This class encapsulates the physical and numerical properties of the liquid phase,
    % including flow variables, phase interactions, heat transfer,and relaxation models.
    % It supports multiple solver models and provides methods for computing derived
    % quantities and handling flow regime transitions.

    properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})

        % Solver state

        NZ                                                                 = 0                    % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
        NTIME                                                              = 0                    % Number of time steps [-]
        TIME                                                               = 0                    % Time series [s]
        DT                                                                 = 0                    % Time step size [s] from :attr:`Inputs.Options.TSTEP`
        TIDX                                                               = 1                    % Time step index [-]
        Z                                                                  = 1.                   % Elevation [m]

        % Flow variables

        W            (:,1) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        U            (:,1) double  {mustBeNumeric}                         = 1.                   % Velocity [m/s]
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]

        % Iteration tracking

        ITR                                                                                       % Iteration tracking

        % Mixture object

        mix         (1,1)          {isa(mix, 'Solvers.TwoFluid.Mixture')}  = NaN                  % :class:`Solvers.TwoFluid.Mixture` object

    end

    properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})

        DZ          (1,1) double   {mustBeNumeric}                         = 0                    % Axial step size [m]
        inputSet                   {isa(inputSet,'Inputs.InputSet')}                              % :class:`Inputs.InputSet` object
        fluid                      {isa(fluid,'Inputs.FluidProperties')}                          % :class:`Inputs.FluidProperties` object

    end

    %% Constructor method
    methods

        function liquid = Liquid(inputSet, fluid)
            %LIQUID Constructor for Liquid class
            %
            % Initializes the liquid field object with input configuration
            % and fluid properties.
            %
            % Inputs:
            %
            % - inputSet — :class:`Inputs.InputSet` object containing model, geometry, and boundary conditions
            % - fluid    — :class:`Inputs.FluidProperties` object containing thermophysical fluid data

            if nargin > 0
                % Store inputSet as object property
                liquid.inputSet = inputSet;
                liquid.fluid  = fluid;
            end
        end

    end

    %% Liquid transport methods
    methods

        function x = X(liquid,zIdx)
            %X Liquid mass fraction [-]
            %
            % Computes the liquid mass fraction relative to the mixture flow.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            x = liquid.W(zIdx)./liquid.mix.W(zIdx);                        % [-]
        end

        function vf = VF(liquid,vapor,zIdx)
            %VF Liquid volumetric fraction [-]
            %
            % Computes the liquid volumetric fraction as the complement of vapor VF.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            vf = 1 - vapor.VF(liquid,zIdx);                                % [-]
        end

        function j = J(liquid,zIdx)
            %J Liquid superficial velocity [m/s]
            %
            % Computes the superficial velocity of the liquid phase.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            AREA = liquid.inputSet.geometry.AREA;                          % [m^2]
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3]

            j = liquid.W(zIdx)./RHOL./AREA;                                % [m/s]
        end

        function s = S(liquid,vapor,zIdx)
            %S Phase vapor/liquid slip ratio [-]
            %
            % Computes the slip ratio between vapor and liquid velocities.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            s = vapor.U(zIdx)./liquid.U(zIdx);                             % [-]
        end

        function area = AREA(liquid,vapor,zIdx)
            %AREA Liquid cross-section area [m^2]
            %
            % Computes the effective cross-sectional area occupied by the liquid phase.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            AREA = liquid.inputSet.geometry.AREA;                          % [m^2] Area

            area = liquid.VF(vapor,zIdx).*AREA;                            % [m^2]
        end

        function u = USLIP(liquid,vapor,zIdx)
            %USLIP Liquid velocity based on input phase slip [m/s]
            %
            % Computes the liquid velocity using a slip-based void fraction model.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            AREA = liquid.inputSet.geometry.AREA;                          % [m^2] Area
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3]
            RHOV = liquid.fluid.RHOV(vapor.H(zIdx));                       % [kg/m^3]
            S    = liquid.inputSet.model.SLIP;                             % [-]
            VF   = max(0,vapor.W(zIdx)./(S.*liquid.W(zIdx).*RHOV./RHOL+vapor.W(zIdx))); % [-] Void fraction based on phase slip model

            %u = liquid.W(zIdx)./RHOL./liquid.AREA(vapor,zIdx);
            u = liquid.mix.W(zIdx)./AREA./(RHOL.*(1-VF)+RHOV.*VF.*S); % [m/s] (Most robust option)
            %u = liquid.W(zIdx)./RHOL./AREA./(1-VF);
        end

        function vr = VR(liquid,vapor,zIdx)
            %VR Local relative velocity [m/s]
            %
            % Computes the relative velocity between vapor and liquid phases using
            % various models (AREAMEAN, SCALED, DRIFT, FLOWREGIME) based on
            % :attr:`Inputs.Model.LOCRELVEL` model.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end
            import Solvers.TwoFluid.REGIMES

            switch liquid.inputSet.model.LOCRELVEL
                case 'AREAMEAN'
                    vr = vapor.U(zIdx) - liquid.U(zIdx);
                case 'SCALED'
                    mult = liquid.inputSet.model.RELVELCST.*ones(size(zIdx));
                    vr = mult.*(vapor.U(zIdx) - liquid.U(zIdx));
                case 'DRIFT'
                    vr = vapor.VF(liquid,zIdx).*(vapor.U(zIdx) - liquid.U(zIdx));
                    vrl = liquid.VF(vapor,zIdx).*(vapor.U(zIdx) - liquid.U(zIdx));
                    vr(liquid.VF(vapor,zIdx)<0.5)=vrl(liquid.VF(vapor,zIdx)<0.5);
                case 'FLOWREGIME'
                    flowregime = liquid.FLOWREGIME(zIdx);
                    % bubbly, slug, churn (assume also for dffb)
                    RHOV = liquid.fluid.RHOV(vapor.H(zIdx));
                    RHOL = liquid.fluid.RHOL(liquid.H(zIdx));
                    C = 1.2 - 0.2.*sqrt(RHOV./RHOL);
                    vr = (1-C.*(vapor.VF(liquid,zIdx)))./(liquid.VF(vapor,zIdx)).*vapor.U(zIdx) - C.*liquid.U(zIdx);

                    % annular (instead contribution from interfacial shear)
                    Idann = ismember(flowregime,[REGIMES.ANNULAR]);
                    vr_ann = zeros(size(zIdx));
                    vr(Idann) = vr_ann(Idann);

                    % dffb (dispersed liquid)
                    Iddffb = ismember(flowregime,[REGIMES.DFFB]);
                    vr_dffb = (1-C.*(liquid.VF(vapor,zIdx)))./(vapor.VF(liquid,zIdx)).*vapor.U(zIdx) - C.*liquid.U(zIdx);
                    vr(Iddffb) = vr_dffb(Iddffb);
            end
        end

        function re = RE(liquid,zIdx)
            %RE Liquid Reynolds number [-]
            %
            % Computes the liquid-phase Reynolds number based on flow rate and viscosity.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            PERIM = sum(liquid.inputSet.geometry.PERIM);                   % [m] Perimeter
            MUL = liquid.fluid.MUL(liquid.H(zIdx));                        % [Pa.s]

            re = 4.*abs(liquid.W(zIdx))./MUL./PERIM;                       % [-]
        end

        function rev = REV(liquid,vapor,zIdx)
            %REV Dispersed liquid Reynolds number [-]
            %
            % Computes the Reynolds number for dispersed liquid using vapor properties
            % and relative velocity.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            RHOV = liquid.fluid.RHOV(liquid.H(zIdx));                      % [kg/m^3]
            MUV  = liquid.fluid.MUV(liquid.H(zIdx));                       % [Pa.s]
            VR = liquid.VR(vapor,zIdx);                                    % [m/s]

            rev = RHOV.*abs(VR).*liquid.L(zIdx)./MUV;                      % [-]
        end

        function t = T(liquid,zIdx)
            %T Liquid temperature [K]
            %
            % Computes the temperature of the liquid phase from enthalpy.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            t = liquid.fluid.T(liquid.H(zIdx));                            % [K]
        end

        function visc = VISC(liquid,vapor,zIdx)
            %VISC Viscosity number for dispersed liquid [-]
            %
            % Computes the dimensionless viscosity number using vapor properties and
            % interfacial tension.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            RHOV = liquid.fluid.RHOV(vapor.H(zIdx));                       % [kg/m^3]
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3]
            MUV  = liquid.fluid.MUV(vapor.H(zIdx));                        % [Pa.s]
            SIGMA = liquid.fluid.SIGMA;                                    % [N/m]
            G = liquid.inputSet.model.G;                                   % [m/s^2]
            Diff_RHO = abs(RHOL-RHOV);                                     % [kg/m^3]

            visc = MUV./sqrt(RHOV.*SIGMA.*sqrt(G.*SIGMA./(Diff_RHO)));     % [-]
        end

    end

    %% Flow regime and interfacial topology methods
    methods

        function xtr_sub = XTR_SUB(liquid)
            %XTR_SUB Quality at subcooled boiling transition [-]
            %
            % Returns the equilibrium quality threshold for the onset of subcooled boiling.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object

            % TODO: Very simplistic transition criteria for now, add more realistic transition criteria

            model = liquid.inputSet.model;

            xtr_sub = model.WBOILINGXSUB;
        end

        function xtr_sat = XTR_SAT(liquid)
            %XTR_SAT Quality at saturated boiling transition [-]
            %
            % Returns the equilibrium quality threshold for the onset of saturated boiling.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object

            % TODO: Very simplistic transition criteria for now, add more realistic transition criteria

            model = liquid.inputSet.model;

            xtr_sat = model.WBOILINGXSAT;
        end

        function xtr_itm = XTR_ITM(liquid)
            %XTR_ITM Quality at onset of intermediate region [-]
            %
            % Returns the equilibrium quality threshold for the onset of the intermediate flow regime.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object

            % TODO: Very simplistic transition criteria for now, add more realistic transition criteria

            xtr_itm = 0.1;
        end

        function xtr_ann = XTR_ANN(liquid)
            %XTR_ANN Quality at onset of annular flow region [-]
            %
            % Returns the equilibrium quality threshold for the onset of annular flow.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            %
            % Notes:
            %
            % - Uses minimum value from mix.OAFX

            % TODO: Very simplistic transition criteria for now, add more realistic transition criteria

            xtr_ann = min(liquid.mix.OAFX);
        end

        function [flowregime, id] = FLOWREGIME(liquid,zIdx)
            %FLOWREGIME Categorical two-phase flow regimes
            %
            % Classifies flow regime based on equilibrium quality and boiling transition flags.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - flowregime — Categorical flow regime (from :class:`Solvers.TwoFluid.REGIMES`)
            % - id         — Integer regime ID

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            geom = liquid.inputSet.geometry;

            XEQ = liquid.mix.XEQ(zIdx);                                    % [-] Equilibrium quality
            XEQ = repmat(XEQ,1,geom.NWALL);
            CBT = liquid.mix.CBT(zIdx);                                    % [-] Critical Boiling Transition flag

            import Solvers.TwoFluid.REGIMES;

            id = zeros(liquid.NZ,geom.NWALL);                              % Liquid (initialization)
            id(XEQ > liquid.XTR_SUB) = 1;                                  % bubbly_subcooled
            id(XEQ > liquid.XTR_SAT) = 2;                                  % bubbly_saturated
            id(XEQ > liquid.XTR_ITM) = 3;                                  % intermediate
            id(XEQ > liquid.XTR_ANN) = 4;                                  % annular
            id(CBT)                  = 5;                                  % dffb

            flowregime = REGIMES(id);
        end

        function id = FLOWID(liquid,zIdx)
            %FLOWID Two-phase flow regime ID
            %
            % Returns the integer ID corresponding to the flow regime classification.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            [~, id] = FLOWREGIME(liquid,zIdx);
        end

        function l = L(liquid,zIdx)
            %L Dispersed liquid interfacial length scale [m]
            %
            % Returns the characteristic length scale for dispersed liquid
            % (e.g., drop Sauter mean diameter).
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Currently uses a constant model

            % TODO: Simplistic model for now. Implement more realistic models

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            model = liquid.inputSet.model;

            switch model.INTLENGTH
                case 'CONSTANT'
                    l = model.INTLENGTHLCST.*ones(size(zIdx));             % [m]
            end
        end

        function intarea = INTAREA(liquid,vapor,zIdx)
            %INTAREA Volumetric interfacial area [m^-1]
            %
            % Computes the interfacial area concentration based on flow regime and phase topology.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Uses a smooth transition between dispersed gas and dispersed liquid models

            % TODO: Simplistic model for now, more realistic models to be implemented as needed, e.g. a transport equation for INTAREA as a primary variable

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            import Solvers.TwoFluid.REGIMES

            model = liquid.inputSet.model;
            flowregime = liquid.FLOWREGIME(zIdx);

            switch model.INTAREA
                case 'DISPGAS2DISPLIQ'

                    aiv = 6*vapor.VF(liquid,zIdx)./vapor.L(zIdx);          % [m^-1] Dispersed gas
                    ail = 6*liquid.VF(vapor,zIdx)./liquid.L(zIdx);         % [m^-1] Dispersed liquid

                    %ai  = aiv;                                             % [m^-1] Initialize with dispersed gas
                    %Idl = ismember(flowregime,[REGIMES.ANNULAR,REGIMES.DFFB]);
                    %ai(Idl) = ail(Idl);                                   % [m^-1] Change to dispersed liquid for selected regimes
                    intarea = liquid.mix.AFDISTR(aiv,ail,zIdx);            % [m^-1] Smooth transition at onset of annular flow
            end
            intarea = max(0,intarea);                                      % [m^-1]
        end

    end

    %% Wall heat flux and wall heat transfer methods
    methods

        function hfluxwalevap = HFLUXWALEVAP(liquid,zIdx)
            %HFLUXWALEVAP Wall evaporation (boiling) heat flux [W/m^2]
            %
            % Computes the portion of wall heat flux attributed to evaporation (e.g., boiling),
            % based on the wall evaporation mass ratio.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            k_EVAP = liquid.WALEVAPRATIO(zIdx);                            % [-] Wall evaporation mass ratio
            hfluxwalevap = -k_EVAP.*liquid.mix.HFLUX(zIdx);                % [W/m^2]
        end

        function hflux = HFLUX(liquid,zIdx)
            %HFLUX Wall heat flux to liquid phase [W/m^2]
            %
            % Computes the net wall heat flux transferred to the liquid phase, combining
            % direct wall heating and boiling contributions.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Combines :attr:`Solvers.TwoFluid.Liquid.HWALHEAT` and :attr:`Solvers.TwoFluid.Liquid.HFLUXWALEVAP`
            % - Uses wall perimeter from geometry

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            geom = liquid.inputSet.geometry;
            hflux = liquid.HWALHEAT(zIdx)./geom.PERIM + liquid.HFLUXWALEVAP(zIdx); % [W/m^2]
        end

    end

    %% Mass transfer methods
    methods

        function [Mcond, Mevap] = MINT(liquid,vapor,zIdx)
            %MINT Linear interfacial mass transfer rates [kg/s/m]
            %
            % Computes condensation and evaporation mass transfer rates using either
            % heat flux-based or relaxation-based models.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - Mcond — Condensation mass transfer rate [kg/s/m]
            % - Mevap — Evaporation mass transfer rate [kg/s/m]
            %
            % Notes:
            %
            % - Supports 'CONSTANT', 'RANZMARSHALL', and 'RELAXATION' models based on :attr:`Inputs.Model.INTNU` model
            % - Applies wall-wise distribution

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            model = liquid.inputSet.model;

            switch model.INTNU
                case {'CONSTANT','RANZMARSHALL'}

                    [inthflux_evap, inthflux_cond] = liquid.INTHFLUX(vapor,zIdx);  % [W/m^2] Interfacial heat flux
                    HL = liquid.H(zIdx);
                    HV = vapor.H(zIdx);

                    switch liquid.inputSet.model.INTTRANSH
                        case 'BULK'
                            Mcond_flux = inthflux_cond./(HV-HL);           % [kg/s/m^2] Condensation mass flux
                            Mevap_flux = inthflux_evap./(HV-HL);           % [kg/s/m^2] Evaporation mass flux
                        case 'SATURATED'
                            Mcond_flux = inthflux_cond./(liquid.fluid.HG-HL);  % [kg/s/m^2] Condensation mass flux
                            Mevap_flux = inthflux_evap./(HV-liquid.fluid.HF);  % [kg/s/m^2] Evaporation mass flux
                    end

                    AREA = liquid.inputSet.geometry.AREA;                  % [m^2] Cross-section area
                    Mcond =  AREA.*liquid.INTAREA(vapor,zIdx).*Mcond_flux; % [kg/s/m] Condensation mass transfer
                    Mevap = -AREA.*liquid.INTAREA(vapor,zIdx).*Mevap_flux; % [kg/s/m] Evaporation mass transfer

                case 'RELAXATION'

                    mix = liquid.mix;

                    UVeq = vapor.U(zIdx);                                  % [m/s] Approximated equilibrium vapor velocity
                    %WVeq = mix.W(zIdx).*max(0,mix.XEQ(zIdx));              % [kg/s] Equilibrium vapor mass flow rate
                    WVeq = mix.W(zIdx).*mix.XEQ(zIdx);                     % [kg/s] Equilibrium vapor mass flow rate
                    Wint = -(WVeq-vapor.W(zIdx));                          % [kg/s] Vapor mass deviation from equilibrium

                    Mcond = max(0,Wint./UVeq./mix.RELAXTCOND(zIdx));       % [kg/s/m] Condensation mass transfer (<0)
                    Mevap = min(0,Wint./UVeq./mix.RELAXTEVAP(zIdx));       % [kg/s/m] Evaporation  mass transfer (>0)
            end

            % Restrict to reasonable bounds
            %TODO: Find a more physical bound
            Mcond =  min( Mcond,vapor.W(zIdx)./liquid.DZ);                 % [kg/s/m] Condensation mass transfer (>0)
            Mevap = -min(-Mevap,liquid.W(zIdx)./liquid.DZ);                % [kg/s/m] Evaporation  mass transfer (<0)

            % Split on all wall
            PERIM = liquid.inputSet.geometry.PERIM;
            Mcond = Mcond.*PERIM./sum(PERIM);
            Mevap = Mevap.*PERIM./sum(PERIM);
        end

        function Mintevap = MINTEVAP(liquid,vapor,zIdx)
            %MINTEVAP Linear interfacial evaporation mass transfer [kg/s/m]
            %
            % Extracts the evaporation component from :attr:`Solvers.TwoFluid.Liquid.MINT`.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            [~, Mintevap] = liquid.MINT(vapor,zIdx);                       % [kg/s/m]
        end

        function Mintcond = MINTCOND(liquid,vapor,zIdx)
            %MINTCOND Linear interfacial condensation mass transfer [kg/s/m]
            %
            % Extracts the condensation component from :attr:`Solvers.TwoFluid.Liquid.MINT`.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            Mintcond = liquid.MINT(vapor,zIdx);                            % [kg/s/m]
        end

        function walevapratio = WALEVAPRATIO(liquid,zIdx)
            %WALEVAPRATIO Wall evaporation mass ratio [-]
            %
            % Returns the fraction of liquid mass undergoing wall boiling.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            walevapratio = liquid.mix.WALEVAPRATIO(zIdx);                  % [-]
        end

        function Mwalevap = MWALEVAP(liquid, vapor, zIdx)
            %MWALEVAP Linear wall mass evaporation rate [kg/s/m]
            %
            % Computes the wall boiling mass transfer rate using latent heat
            % (based on :attr:`Inputs.Model.INTTRANSH` model) and wall heat
            % flux.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            model = liquid.inputSet.model;
            geom  = liquid.inputSet.geometry;

            switch model.INTTRANSH
                case 'BULK'
                    HFG = vapor.H(zIdx)   - liquid.H(zIdx);                % [J/kg] Vapor is generated at bulk enthalpy
                case 'SATURATED'
                    HFG = liquid.fluid.HG - liquid.H(zIdx);                % [J/kg] Vapor is generated at saturation
            end

            Mwalevap = geom.PERIM.*liquid.HFLUXWALEVAP(zIdx)./HFG;         % [kg/s/m]
        end

        function Mtot = MTOT(liquid,vapor,zIdx)
            %MTOT Total linear mass transfer [kg/s/m]
            %
            % Computes the total vapor mass transfer rate by summing interfacial
            % condensation, evaporation, and wall boiling contributions.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            [Mcond,Mevap] = liquid.MINT(vapor,zIdx);                       % [kg/s/m]
            Mtot  = Mcond + Mevap + liquid.MWALEVAP(vapor,zIdx);           % [kg/s/m]
        end

    end

    %% Energy transfer methods
    methods

        function intnu = INTNU(liquid,vapor,zIdx)
            %INTNU Interfacial Nusselt number for dispersed liquid [-]
            %
            % Computes the interfacial Nusselt number based on
            % :attr:`Inputs.Model.INTNU` model.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            model = liquid.inputSet.model;

            switch model.INTNU
                case 'CONSTANT'
                    intnu = model.INTNULCST.*ones(size(zIdx));             % [-]
                case 'RANZMARSHALL'
                    Re = liquid.REV(vapor,zIdx);                           % [-]
                    Pr = liquid.fluid.PRANDTLV(liquid.H(zIdx));            % [-]

                    coef = model.RANZMARSHALLLCST;                         % [-] Ranz-Marshall coefficients
                    intnu = coef(1) + coef(2).*Re.^coef(3).*Pr.^coef(4);   % [-]
                case 'RELAXATION'
                    intnu = nan(size(zIdx));
            end
        end

        function [inthflux_evap, inthflux_cond] = INTHFLUX(liquid,vapor,zIdx)
            %INTHFLUX Interfacial heat flux [W/m^2]
            %
            % Computes the interfacial heat flux due to evaporation and
            % condensation based on :attr:`Inputs.Model.INTAREA` interfacial
            % area model.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - inthflux_evap — Evaporation heat flux [W/m^2]
            % - inthflux_cond — Condensation heat flux [W/m^2]
            %
            % Notes:
            %
            % - Uses interfacial Nusselt number and length scale
            % - Driven by deviation from saturated temperature

            % TODO: Simple models for now, should be improved

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            import Solvers.TwoFluid.REGIMES

            model = liquid.inputSet.model;
            %flowregime = liquid.FLOWREGIME(zIdx);

            switch model.INTAREA
                case 'DISPGAS2DISPLIQ'

                    % Dispersed gas
                    L = vapor.L(zIdx);                                     % [m] Interfacial length scale
                    INTNUV = vapor.INTNU(liquid,zIdx);                     % [-] Interfacial Nusselt number
                    KL = liquid.fluid.KL(liquid.H(zIdx));                  % [W/m/K] Liquid conductivity <- assume vapor phase is dispersed
                    hv = INTNUV.*KL./L; hv(L <= 1E-6) = 0;                 % [W/m^2/K] Interfacial heat transfer coefficient

                    % Dispersed liquid
                    L = liquid.L(zIdx);                                    % [m] Interfacial length scale
                    INTNUL = liquid.INTNU(vapor,zIdx);                     % [-] Interfacial Nusselt number
                    KV = vapor.fluid.KV(vapor.H(zIdx));                    % [W/m/K] Vapor conductivity  <- assume liquid phase is dispersed
                    hl = INTNUL.*KV./L; hl(L <= 1E-6) = 0;                 % [W/m^2/K] Interfacial heat transfer coefficient

                    %h = hv;                                                % [W/m^2/K]
                    %Idl = ismember(flowregime,[REGIMES.ANNULAR,REGIMES.DFFB]);
                    %h(Idl) = hl(Idl);                                      % [W/m^2/K]
                    h = liquid.mix.AFDISTR(hv,hl,zIdx);                    % [m^-1] Smooth transition at onset of annular flow
            end
            h = max(0,h);                                                  % [W/m^2/K]

            TSAT  = liquid.fluid.TSAT;                                     % [K] Saturated fluid temperature
            inthflux_evap = max(0,h.*(vapor.T(zIdx)-TSAT));                % [W/m^2] Evaporation heat flux
            inthflux_cond = max(0,h.*(TSAT-liquid.T(zIdx)));               % [W/m^2] Condensation heat flux
        end

        function [Hcond, Hevap] = HINT(liquid,vapor,zIdx)
            %HINT Linear interfacial heat transfer rate [W/m]
            %
            % Computes the interfacial heat transfer rate using mass transfer
            % and enthalpy difference (based on :attr:`Inputs.Model.INTTRANSH`
            % model).
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - Hcond — Condensation heat transfer rate [W/m]
            % - Hevap — Evaporation heat transfer rate [W/m]

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            geom = liquid.inputSet.geometry;

            [Mcond, Mevap] = liquid.MINT(vapor,zIdx);                      % [kg/s/m] Interfacial mass flows
            HL = liquid.H(zIdx);                                           % [J/kg] Liquid enthalpy

            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hcond = Mcond.*(vapor.H(zIdx)-HL);                     % [W/m]
                    Hevap = zeros(length(zIdx),geom.NWALL);                % [W/m]
                case 'SATURATED'
                    Hcond = Mcond.*(liquid.fluid.HG-HL);                   % [W/m]
                    Hevap = Mevap.*(liquid.fluid.HF-HL);                   % [W/m]
            end
        end

        function Hintevap = HINTEVAP(liquid,vapor,zIdx)
            %HINTEVAP Linear interfacial heat evaporation rate [W/m]
            %
            % Extracts the evaporation component from
            % :attr:`Solvers.TwoFluid.Liquid.HINT`.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            [~,Hintevap] = liquid.HINT(vapor,zIdx);                        % [W/m]
        end

        function Hintcond = HINTCOND(liquid,vapor,zIdx)
            %HINTCOND Linear interfacial heat condensation rate [W/m]
            %
            % Extracts the condensation component from
            % :attr:`Solvers.TwoFluid.Liquid.HINT`.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            Hintcond = liquid.HINT(vapor,zIdx);                            % [W/m]
        end

        function Hwalevap = HWALEVAP(liquid,vapor,zIdx)
            %HWALEVAP Linear wall heat evaporation (boiling) rate [W/m]
            %
            % Computes the wall boiling heat transfer rate using latent heat
            % (based on :attr:`Inputs.Model.INTTRANSH` model) and wall mass
            % evaporation.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            Mwalevap = liquid.MWALEVAP(vapor,zIdx);                        % [kg/s] Linear mass wall boiling rate
            HL = liquid.H(zIdx);

            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hwalevap = Mwalevap.*(vapor.H(zIdx)-HL);               % [W/m]
                case 'SATURATED'
                    Hwalevap = Mwalevap.*(liquid.fluid.HG-HL);             % [W/m]
            end
        end

        function Hwalheat = HWALHEAT(liquid,zIdx)
            %HWALHEAT Linear wall heat to liquid rate [W/m]
            %
            % Returns the wall heat generation rate transferred to the liquid phase.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Set to zero beyond CBT

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            cbt = liquid.mix.CBT(zIdx);                                    % CBT flag
            Hwalheat = double(~cbt).*liquid.mix.LHGR(zIdx);                % [W/m]
        end

        function Htot = HTOT(liquid,vapor,zIdx)
            %HTOT Total linear vapor heat rate [W/m]
            %
            % Computes the total heat transfer to the vapor phase, including
            % interfacial and wall contributions.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            [Hintcond,Hintevap] = liquid.HINT(vapor,zIdx);                 % [W/m]
            Htot = Hintcond + Hintevap + liquid.HWALEVAP(vapor,zIdx) + liquid.HWALHEAT(zIdx); % [W/m]
        end

    end

    %% Momentum transfer methods
    methods

        function Fgrav = FGRAV(liquid,vapor,zIdx)
            %FGRAV Liquid gravity force [N/m]
            %
            % Computes the gravitational force acting on the liquid phase.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            geom = liquid.inputSet.geometry;
            model = liquid.inputSet.model;
            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3] Liquid density

            Fgrav = -(model.G*cos(geom.ANGLE*pi/180)*RHOL).*liquid.VF(vapor,zIdx).*geom.AREA; % [N/m]
        end

        function Fbuoy = FBUOY(liquid,vapor,zIdx)
            %FBUOY Liquid buoyancy force [N/m]
            %
            % Computes the buoyancy force acting on the liquid phase due to pressure gradient.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - The pressure gradient from the mixture solver is used

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            AREA = liquid.inputSet.geometry.AREA;                          % [m^2] Cross-section area
            DPDZ = liquid.mix.DPDZ(zIdx);                                  % [Pa/m] Pressure gradient

            Fbuoy = AREA*liquid.VF(vapor,zIdx).*DPDZ;                      % [N/m]
        end

        %         function fw = FW(liquid, zIdx)
        %         %FW Liquid wall friction factor [-]
        %
        %             if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
        %
        %             model = liquid.inputSet.model;
        %             fw = (model.FRICTION(1).*liquid.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3));
        %         end

        function tauw = TAUW(liquid,zIdx)
            %TAUW Liquid wall shear stress [N/m^2]
            %
            % Returns the wall shear stress acting on the liquid phase.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
           
            %TODO: Model consistent with mixture approach for now

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end

            %RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3] Liquid density
            %MULT  = 0.5.*(liquid.FW(zIdx)./4.).*RHOL;
            %tauw  = MULT.*liquid.U(zIdx).*abs(liquid.U(zIdx));             % [N/m^2]

            tauw = liquid.mix.TAUW(zIdx);                                  % [N/m^2]
        end

        function Fwall = FWALL(liquid,vapor,zIdx)
            %FWALL Liquid wall shear force [N/m]
            %
            % Computes the wall shear force acting on the liquid phase, weighted by void fraction.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            geom  = liquid.inputSet.geometry;
            Fwall = -liquid.VF(vapor,zIdx).*liquid.TAUW(zIdx).*sum(geom.PERIM); % [N/m]
        end

        function cd = CD(liquid,vapor,zIdx)
            %CD Drag coefficient for dispersed liquid [-]
            %
            % Computes the drag coefficient for dispersed liquid based on
            % :attr:`Inputs.Model.DROPDRAG` model.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Values are clamped to a maximum of 1

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            Re = liquid.REV(vapor,zIdx);
            Re(Re <= 1E-3) = 1E-3;                                         % [-] Avoid division by 0

            model = liquid.inputSet.model;

            switch model.DROPDRAG
                case InputEnums.DROPDRAG.CONSTANT
                    % Constant drag model
                    cd = repmat(model.DROPDRAGCOEF,length(zIdx),1);        % [-]

                case InputEnums.DROPDRAG.STOKES
                    % Stokes model
                    cd = 24./Re;                                           % [-]

                case InputEnums.DROPDRAG.VISCOUS
                    % Viscous model
                    cd = 24./Re.*(1+0.15.*Re.^0.687);                      % [-]

                case InputEnums.DROPDRAG.DISTORDED
                    % Distorted fluid particle (bubbly flow n=2.5)
                    %mult = sqrt(2)/3.*((1+17.67.*(1-liquid.VF(vapor,zIdx)).^(2.6))./(18.67.* (1-liquid.VF(vapor,zIdx)).^3)).^2;
                    mult = sqrt(2)/3.*(1-liquid.VF(vapor,zIdx)).^2;
                    cd = liquid.VISC(vapor,zIdx).*Re.*mult;                % [-]
            end

            % Churn
            %cd = 8/3.*(1-liquid.VF(vapor,zIdx)).^3;

            cd = min(cd,1);
        end

        function Fdrag = FDRAG(liquid,vapor,zIdx)
            %FDRAG Interfacial drag force [N/m]
            %
            % Computes the interfacial drag force acting on the liquid phase.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Uses smooth transition between dispersed gas and liquid drag based on :attr:`Inputs.Model.DISPGAS2DISPLIQ` model.

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            import Solvers.TwoFluid.REGIMES

            geom  = liquid.inputSet.geometry;
            fluid = liquid.fluid;
            %flowregime = liquid.FLOWREGIME(zIdx);

            switch liquid.inputSet.model.INTAREA
                case 'DISPGAS2DISPLIQ'

                    AREA = geom.AREA;                                      % [m^2] area
                    RHOV = fluid.RHOV(vapor.H(zIdx));                      % [kg/m^3] vapor density
                    RHOL = fluid.RHOL(liquid.H(zIdx));                     % [kg/m^3] liquid density
                    VR = liquid.VR(vapor,zIdx);                            % [m/s] Relative velocity between phases
                    %VR = min(VR,10);

                    % Dispersed gas
                    INTAREA = liquid.INTAREA(vapor,zIdx);                  % [1/m]
                    Fdragv = AREA.*INTAREA.*0.5.*vapor.CD(liquid,zIdx).*RHOL.*VR.*abs(VR); % [N/m]

                    % Dispersed liquid
                    Fdragl = AREA.*INTAREA.*0.5.*liquid.CD(vapor,zIdx).*RHOV.*VR.*abs(VR); % [N/m]

                    %Fdrag = Fdragv;                                        % [N/m]
                    %Idl = ismember(flowregime,[REGIMES.ANNULAR, REGIMES.DFFB]);
                    %Fdrag(Idl) = Fdragl(Idl);                              % [N/m]
                    Fdrag = liquid.mix.AFDISTR(Fdragv,Fdragl,zIdx);        % [N/m] Smooth transition at onset of annular flow
            end
        end

        function Fintcond = FINTCOND(liquid,vapor,zIdx)
            %FINTCOND Momentum exchange through interfacial condensation [N/m]
            %
            % Computes the momentum exchange due to interfacial condensation.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            deltaU = vapor.U(zIdx)-liquid.U(zIdx);                         % [m/s]
            Fintcond = sum(liquid.MINTCOND(vapor,zIdx),2).*deltaU;         % [N/m]
        end

        function Ftot = FTOT(liquid,vapor,zIdx)
            %FTOT Total force [N/m]
            %
            % Computes the total force acting on the liquid phase, including gravity,
            % buoyancy, wall shear, drag, and interfacial condensation.
            %
            % Inputs:
            %
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            Fgrav    = liquid.FGRAV(vapor,zIdx);
            Fbuoy    = liquid.FBUOY(vapor,zIdx);
            Fdrag    = liquid.FDRAG(vapor,zIdx);
            Fwall    = liquid.FWALL(vapor,zIdx);
            Fintcond = liquid.FINTCOND(vapor,zIdx);

            Ftot= Fgrav + Fbuoy + Fwall + Fdrag + Fintcond;                % [N/m]
        end

    end

end
