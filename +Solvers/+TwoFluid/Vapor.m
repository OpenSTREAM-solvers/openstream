classdef Vapor < Solvers.AbstractField
    %VAPOR Class for modeling vapor field in two-fluid solver
    %
    % This class encapsulates the physical and numerical properties of the vapor phase,
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

        % Flow properties

        W            (:,1) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        U            (:,1) double  {mustBeNumeric}                         = 1.                   % Velocity [m/s]
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]

        % Iteration properties

        ITR                                                                                       % Iteration properties

        % Mixture object

        mix          (1,1)         {isa(mix, 'Solvers.TwoFluid.Mixture')}  = NaN                  % :class:`Solvers.TwoFluid.Mixture` object

    end

    properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})

        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % Axial step size [m]
        % inputSet                   {isa(inputSet,'Inputs.InputSet')}                              % :class:`Inputs.InputSet` object
        fluid                      {isa(fluid,'Inputs.FluidProperties')}                          % :class:`Inputs.FluidProperties` object

    end

    %% Constructor method
    methods

        function vapor = Vapor(inputSet, fluid)
            %VAPOR Constructor for Vapor class
            %
            % Initializes the vapor field object with input configuration
            % and fluid properties.
            %
            % Inputs:
            %
            % - inputSet — :class:`Inputs.InputSet` object containing model, geometry, and boundary conditions
            % - fluid    — :class:`Inputs.FluidProperties` object containing thermophysical fluid data

            if nargin > 0
                % Store inputSet as object property
                vapor.inputSet = inputSet;
                vapor.fluid  = fluid;
            end
        end

    end

    %% Vapor transport methods
    methods

        function x = X(vapor,zIdx)
            %X Vapor mass fraction [-]
            %
            % Computes the vapor mass fraction relative to the mixture flow.
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            x = vapor.W(zIdx)./vapor.mix.W(zIdx);                          % [-]
        end

        function vf = VF(vapor,liquid,zIdx)
            %VF Vapor volumetric fraction [-]
            %
            % Computes the vapor volumetric (i.e., void) fraction using slip
            % ratio and densities.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            RHOL = liquid.fluid.RHOL(liquid.H(zIdx));                      % [kg/m^3]
            RHOV = liquid.fluid.RHOV(vapor.H(zIdx));                       % [kg/m^3]

            vf = max(0,vapor.W(zIdx)./(liquid.S(vapor,zIdx).*liquid.W(zIdx).*RHOV./RHOL+vapor.W(zIdx))); %  [-]
        end

        function j = J(vapor,zIdx)
            %J Vapor superficial velocity [m/s]
            %
            % Computes the superficial velocity of the vapor phase.
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            AREA = vapor.inputSet.geometry.AREA;                           % [m^2]
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                        % [kg/m^3]

            j = vapor.W(zIdx)./RHOV./AREA;                                 % [m/s]
        end

        function s = S(vapor,liquid,zIdx)
            %S Phase slip ratio [-]
            %
            % Returns the slip ratio between vapor and liquid phases.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            s = liquid.S(zIdx);                                            % [-]
        end

        function area = AREA(vapor,liquid,zIdx)
            %AREA Vapor cross-section area [m^2]
            %
            % Computes the effective cross-sectional area occupied by the vapor phase.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            AREA = vapor.inputSet.geometry.AREA;                           % [m^2] Area

            area = vapor.VF(liquid,zIdx).*AREA;                            % [m^2]
        end

        function u = USLIP(vapor,liquid,zIdx)
            %USLIP Vapor velocity based on input phase slip [m/s]
            %
            % Computes the vapor velocity using slip ratio and liquid velocity.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            S = vapor.inputSet.model.SLIP;

            u = liquid.USLIP(vapor,zIdx).*S;                               % [m/s]
        end

        function re = RE(vapor,zIdx)
            %RE Vapor Reynolds number [-]
            %
            % Computes the vapor-phase Reynolds number based on flow rate and viscosity.
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            PERIM = sum(vapor.inputSet.geometry.PERIM);                    % [m] Perimeter
            MUV = vapor.fluid.MUV(vapor.H(zIdx));                          % [Pa.s]

            re = 4.*vapor.W(zIdx)./MUV./PERIM;                             % [-]
        end

        function rel = REL(vapor,liquid,zIdx)
            %REL Dispersed vapor Reynolds number [-]
            %
            % Computes the Reynolds number for dispersed vapor using liquid properties
            % and relative velocity.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            RHOL = vapor.fluid.RHOL(vapor.H(zIdx));
            MUL  = vapor.fluid.MUL(vapor.H(zIdx));
            VR = liquid.VR(vapor,zIdx);

            rel = RHOL.*abs(VR).*vapor.L(zIdx)./MUL;                       % [-]
        end

        function t = T(vapor,zIdx)
            %T Vapor temperature [K]
            %
            % Computes the vapor temperature from enthalpy.
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            t = vapor.fluid.T(vapor.H(zIdx));                              % [K]
        end

        function visc = VISC(vapor,liquid,zIdx)
            %VISC Viscosity number for dispersed gas [-]
            %
            % Computes the dimensionless viscosity number using liquid and vapor properties.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));
            RHOL = vapor.fluid.RHOL(liquid.H(zIdx));
            MUL  = vapor.fluid.MUL(liquid.H(zIdx));
            SIGMA = vapor.fluid.SIGMA;
            G = vapor.inputSet.model.G;
            Diff_RHO = abs(RHOL-RHOV);

            visc = MUL./sqrt(RHOL.*SIGMA.*sqrt(G.*SIGMA./(Diff_RHO)));     % [-]
        end

    end

    %% Flow regime and interfacial topology methods
    methods

        function xtr_sub = XTR_SUB(vapor,liquid)
            %XTR_SUB Quality at onset of subcooled boiling transition [-]
            %
            % Returns the equilibrium quality threshold for the onset of subcooled boiling.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object

            xtr_sub = liquid.XTR_SUB();
        end

        function xtr_sat = XTR_SAT(vapor,liquid)
            %XTR_SAT Quality at end of subcooled boiling transition [-]
            %
            % Returns the equilibrium quality threshold for the onset of saturated boiling.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object

            xtr_sat = liquid.XTR_SAT();
        end

        function xtr_itm = XTR_ITM(vapor,liquid)
            %XTR_ITM Quality at onset of intermediate region [-]
            %
            % Returns the equilibrium quality threshold for the onset of the intermediate flow regime.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object

            xtr_itm = liquid.XTR_ITM();
        end

        function xtr_ann = XTR_ANN(vapor,liquid)
            %XTR_ANN Quality at onset of annular flow region

            xtr_ann = liquid.XTR_ANN();
        end

        function xtr_cbt = XTR_CBT(vapor,liquid)
            %XTR_CBT Quality at Critical Boiling Transition [-]
            %
            % Returns the equilibrium quality threshold for the onset of critical boiling transition.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object

            xtr_cbt = liquid.XTR_CBT();
        end

        function flowregime = FLOWREGIME(vapor,liquid,zIdx)
            %FLOWREGIME Categorical two-phase flow regimes
            %
            % Returns the flow regime classification based on liquid-phase criteria
            % (:meth:`Solvers.TwoFluid.Liquid.FLOWREGIME)`.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - flowregime — Flow regime category (from :class:`Solvers.TwoFluid.REGIMES`)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            flowregime = liquid.FLOWREGIME(zIdx);
        end

        function l = L(vapor,zIdx)
            %L Dispersed vapor interfacial length scale [m]
            %
            % Returns the characteristic length scale for dispersed vapor
            % (e.g., bubble diameter).
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Currently uses a constant model
   
            % TODO: Simplistic model for now. Implement more realistic models

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            model = vapor.inputSet.model;

            switch model.INTLENGTH
                case 'CONSTANT'
                    l = model.INTLENGTHVCST.*ones(size(zIdx));             % [m]
            end
        end

        function intarea = INTAREA(vapor,liquid,zIdx)
            %INTAREA Volumetric interfacial area [m^-1]
            %
            % Computes the interfacial area concentration using liquid-phase logic
            % (from :meth:`Solvers.TwoFluid.Liquid.INTAREA)`.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            intarea = liquid.INTAREA(vapor,zIdx);                          % [m^-1]
        end

    end

    %% Wall heat flux and wall heat transfer methods
    methods

        function hfluxwalevap = HFLUXWALEVAP(vapor,liquid,zIdx)
            %HFLUXWALEVAP Wall boiling heat flux [W/m^2]
            %
            % Computes the portion of wall heat flux attributed to boiling (evaporation)
            % for the vapor phase, based on liquid-phase calculations
            % (:meth:`Solvers.TwoFluid.Liquid.HFLUXWALEVAP`).
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
 
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            hfluxwalevap = -liquid.HFLUXWALEVAP(zIdx);                     % [W/m^2]
        end

        function hflux = HFLUX(vapor,zIdx)
            %HFLUX Wall heat flux to vapor phase [W/m^2]
            %
            % Computes the net wall heat flux transferred to the vapor phase.
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Uses :meth:`Solvers.TwoFluid.Vapor.HWALHEAT` divided by wall perimeter

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            geom = vapor.inputSet.geometry;
            hflux = vapor.HWALHEAT(zIdx)./geom.PERIM;                      % [W/m^2]
        end

    end

    %% Mass transfer methods
    methods

        function [Mcond, Mevap] = MINT(vapor,liquid,zIdx)
            %MINT Linear interfacial mass transfer rates [kg/s/m]
            %
            % Computes condensation and evaporation mass transfer rates for the vapor
            % phase by reversing the sign of liquid-phase values (:meth:`Solvers.TwoFluid.Liquid.MINT`).
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - Mcond — Condensation mass transfer rate [kg/s/m]
            % - Mevap — Evaporation mass transfer rate [kg/s/m]

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            [Mcond, Mevap] = liquid.MINT(vapor,zIdx);                      % [kg/s/m]
            Mcond = -Mcond; Mevap = -Mevap;
        end

        function Mintevap = MINTEVAP(vapor,liquid,zIdx)
            %MINTEVAP Linear interfacial evaporation mass transfer [kg/s/m]
            %
            % Extracts the evaporation component from :meth:`Solvers.TwoFluid.Vapor.MINT`.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            [~,Mintevap] = vapor.MINT(liquid,zIdx);                        % [kg/s/m]
        end

        function Mintcond = MINTCOND(vapor,liquid,zIdx)
            %MINTCOND Linear interfacial condensation mass transfer [kg/s/m]
            %
            % Extracts the condensation component from :meth:`Solvers.TwoFluid.Vapor.MINT`.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
  
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Mintcond = vapor.MINT(liquid,zIdx);                            % [kg/s/m]
        end

        function walevapratio = WALEVAPRATIO(vapor,liquid,zIdx)
            %WALEVAPRATIO Wall evaporation mass ratio [-]
            %
            % Returns the fraction of liquid mass undergoing wall boiling.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - walevapratio — Wall boiling mass ratio [-]

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            walevapratio = liquid.WALEVAPRATIO(zIdx);                      % [-]
        end

        function Mwalevap = MWALEVAP(vapor,liquid,zIdx)
            %MWALEVAP Linear wall mass evaporation rate [kg/s/m]
            %
            % Computes the wall boiling mass transfer rate for vapor by reversing the sign
            % of the liquid-phase value (:meth:`Solvers.TwoFluid.Liquid.MWALEVAP`).
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Mwalevap  = -liquid.MWALEVAP(vapor,zIdx);                      % [kg/s/m]
        end

        function Mtot = MTOT(vapor,liquid,zIdx)
            %MTOT Total linear mass transfer [kg/s/m]
            %
            % Computes the total vapor mass transfer rate by reversing the sign of
            % the liquid-phase total (:meth:`Solvers.TwoFluid.Liquid.MTOT`).
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Mtot  = -liquid.MTOT(vapor,zIdx);                              % [kg/s/m]
        end

    end

    %% Energy transfer methods
    methods

        function intnu = INTNU(vapor,liquid,zIdx)
            %INTNU Interfacial Nusselt number for dispersed vapor [-]
            %
            % Computes the interfacial Nusselt number based on
            % :attr:`Inputs.Model.INTNU` model.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            model = vapor.inputSet.model;

            switch model.INTNU
                case 'CONSTANT'
                    intnu = model.INTNUVCST.*ones(size(zIdx));             % [-]
                case 'RANZMARSHALL'
                    Re = vapor.REL(liquid,zIdx);                           % [-]
                    Pr = vapor.fluid.PRANDTLL(vapor.H(zIdx));              % [-]

                    coef = model.RANZMARSHALLVCST;                         % [-] Ranz-Marshall coefficients
                    intnu = coef(1) + coef(2).*Re.^coef(3).*Pr.^coef(4);   % [-]
                case 'RELAXATION'
                    % TODO: Calculate equivalent interfacial Nusselt number (for display only)
                    intnu = nan(size(zIdx));
            end
        end

        function [inthflux_evap, inthflux_cond] = INTHFLUX(vapor,liquid,zIdx)
            %INTHFLUX Interfacial heat flux [W/m^2]
            %
            % Computes the interfacial heat flux due to evaporation and condensation
            % (delegated to liquid-phase calculation in :meth:`Solvers.TwoFluid.Liquid.INTHFLUX`).
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - inthflux_evap — Evaporation heat flux [W/m^2]
            % - inthflux_cond — Condensation heat flux [W/m^2]
            %
            % Notes:
            %
            % - Positive toward liquid phase
            
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            [inthflux_evap, inthflux_cond] = liquid.INTHFLUX(vapor,zIdx);  % [W/m^2]
        end

        function [Hcond,Hevap] = HINT(vapor,liquid,zIdx)
            %HINT Linear interfacial heat transfer rate [W/m]
            %
            % Computes the interfacial heat transfer rate for the vapor phase based on
            % mass transfer and enthalpy difference (based on :attr:`Inputs.Model.INTTRANSH`
            % model).
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - Hcond — Condensation heat transfer rate [W/m]
            % - Hevap — Evaporation heat transfer rate [W/m]

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            geom = vapor.inputSet.geometry;

            [Mcond, Mevap] = vapor.MINT(liquid,zIdx);                      % [kg/s/m] Interfacial mass flows
            HV = vapor.H(zIdx);                                            % [J/kg] Vapor enthalpy

            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hcond = zeros(length(zIdx),geom.NWALL);
                    Hevap = Mevap.*(liquid.H(zIdx)-HV);                    % [W/m]
                case 'SATURATED'
                    Hcond = Mcond.*(vapor.fluid.HG-HV);                    % [W/m]
                    Hevap = Mevap.*(vapor.fluid.HF-HV);                    % [W/m]
            end
        end

        function Hintevap = HINTEVAP(vapor,liquid,zIdx)
            %HINTEVAP Linear interfacial heat evaporation rate [W/m]
            %
            % Extracts the evaporation component from :meth:`Solvers.TwoFluid.Vapor.HINT`.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            [~,Hintevap] = vapor.HINT(liquid,zIdx);                        % [W/m]
        end

        function Hintcond = HINTCOND(vapor,liquid,zIdx)
            %HINTCOND Linear interfacial heat condensation rate [W/m]
            %
            % Extracts the condensation component from :meth:`Solvers.TwoFluid.Vapor.HINT`.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
    
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Hintcond = vapor.HINT(liquid,zIdx);                            % [W/m]
        end

        function Hwalevap = HWALEVAP(vapor,liquid,zIdx)
            %HWALEVAP Linear wall heat evaporation (boiling) rate [W/m]
            %
            % Computes the wall boiling heat transfer rate using latent heat
            % (based on :attr:`Inputs.Model.INTTRANSH` model) and wall mass
            % evaporation.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            geom = vapor.inputSet.geometry;

            switch liquid.inputSet.model.INTTRANSH
                case 'BULK'
                    Hwalevap = zeros(length(zIdx),geom.NWALL);             % [W/m]
                case 'SATURATED'
                    Mwalevap = vapor.MWALEVAP(liquid,zIdx);                % [kg/s/m] Linear mass wall boiling rate
                    HV = vapor.H(zIdx);                                    % [J/kg]
                    Hwalevap = Mwalevap.*(vapor.fluid.HG-HV);              % [W/m]
            end
        end

        function Hwalheat = HWALHEAT(vapor,zIdx)
            %HWALHEAT Linear wall heat to vapor rate [W/m]
            %
            % Returns the wall heat generation rate transferred to the vapor phase.
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Set to zero before CBT

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            cbt = vapor.mix.CBT(zIdx);                                     % CBT flag
            Hwalheat = double(cbt).*vapor.mix.LHGR(zIdx);                  % [W/m]
        end

        function Htot = HTOT(vapor,liquid,zIdx)
            %HTOT Total linear vapor heat rate [W/m]
            %
            % Computes the total heat transfer to the vapor phase, including
            % interfacial and wall contributions.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            [Hcond,Hevap] = vapor.HINT(liquid,zIdx);                       % [W/m]
            Htot = Hcond + Hevap + vapor.HWALEVAP(liquid,zIdx) + vapor.HWALHEAT(zIdx); % [W/m]
        end

    end

    %% Momentum transfer methods
    methods

        function Fgrav = FGRAV(vapor,liquid,zIdx)
            %FGRAV Vapor gravity force [N/m]
            %
            % Computes the gravitational force acting on the vapor phase.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            geom = vapor.inputSet.geometry;
            model = vapor.inputSet.model;
            RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                        % [kg/m^3] Vapor density

            Fgrav = -model.G*cos(geom.ANGLE*pi/180)*RHOV.*vapor.VF(liquid,zIdx).*geom.AREA; % [N/m]
        end

        function Fbuoy = FBUOY(vapor,liquid,zIdx)
            %FBUOY Vapor buoyancy force [N/m]
            %
            % Computes the buoyancy force acting on the vapor phase due to pressure gradient.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - The pressure gradient from the mixture solver is used
 
            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            AREA = vapor.inputSet.geometry.AREA;                           % [m^2] Cross-section area
            DPDZ = vapor.mix.DPDZ(zIdx);                                   % [Pa/m] Pressure gradient

            Fbuoy = AREA*vapor.VF(liquid,zIdx).*DPDZ;                      % [N/m]
        end

        %         function fw = FW(vapor, zIdx)
        %         %FW Wall friction factor [-]
        %         %
        %             if nargin < 2, zIdx = (1:vapor(1).NZ).'; end
        %
        %             model = vapor.inputSet.model;
        %             fw = model.FRICTION(1).*vapor.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
        %             fw(vapor.RE(zIdx) <= 1E-3) = 0;                                % [-] Avoid division by 0
        %         end

        function tauw = TAUW(vapor,zIdx)
            %TAUW Wall shear stress [N/m^2]
            %
            % Returns the wall shear stress acting on the vapor phase.
            %
            % Inputs:
            %
            % - vapor — :class:`Solvers.TwoFluid.Vapor` object
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Uses mixture-level shear stress for consistency

            %TODO: Model consistent with mixture approach for now

            if nargin < 2, zIdx = (1:vapor(1).NZ).'; end

            %RHOV = vapor.fluid.RHOV(vapor.H(zIdx));                        % [kg/m^3]
            %MULT  = 0.5.*(vapor.FW(zIdx)./4.).*RHOV;
            %tauw  = MULT.*vapor.U(zIdx).*abs(vapor.U(zIdx));               % [N/m^2]

            tauw = vapor.mix.TAUW(zIdx);                                   % [N/m^2]
        end

        function Fwall = FWALL(vapor,liquid,zIdx)
            %FWALL Wall shear force [N/m]
            %
            % Computes the wall shear force acting on the vapor phase, weighted by void fraction.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            geom  = vapor.inputSet.geometry;
            Fwall = -vapor.VF(liquid,zIdx).*vapor.TAUW(zIdx).*sum(geom.PERIM); % [N/m]
        end

        function cd = CD(vapor,liquid,zIdx)
            %CD Drag coefficient for dispersed gas [-]
            %
            % Computes the drag coefficient for dispersed vapor based on
            % :attr:`Inputs.Model.DROPDRAG` model.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Values are clamped to a maximum of 1

            % TODO: STOKES model used for now due to solver convergence issue
            % Results in too low interfacial drag
            % Viscous and distorted models are more reasonable,
            % but predicts too high drag forces, possibly due to the AREAMEAN
            % assumption in the relative velocity calculation

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Re = vapor.REL(liquid,zIdx);
            Re(Re <= 1E-3) = 1E-3;                                         % [-] Avoid division by 0

            model = vapor.inputSet.model;

            switch model.BUBBLEDRAG
                case InputEnums.BUBBLEDRAG.CONSTANT
                    % Constant drag model
                    cd = repmat(model.BUBBLEDRAGCOEF,length(zIdx),1);      % [-]

                case InputEnums.BUBBLEDRAG.STOKES
                    % Stokes
                    cd = 24./Re;

                case InputEnums.BUBBLEDRAG.VISCOUS
                    % Viscous model
                    %cd = 24./Re.*(1+0.1.*Re.^(0.75));
                    cd = 24./Re.*(1+0.15.*Re.^(0.687));

                case InputEnums.BUBBLEDRAG.DISTORDED
                    % Distorted fluid particle (bubbly flow n=1)
                    %mult = sqrt(2)/3.*((1+17.67.*(liquid.VF(vapor,zIdx)).^(1.3))./(18.67.*(liquid.VF(vapor,zIdx)).^(1.5))).^2;
                    mult = sqrt(2)/3.*(liquid.VF(vapor,zIdx)).^2;
                    cd = vapor.VISC(liquid,zIdx).*Re.*mult;
            end

            % Churn
            %cd = 8/3.*(liquid.VF(vapor,zIdx)).^3;

            %cd = ones(size(zIdx)).*0.45;

            cd = min(cd,1);
        end

        function Fdrag = FDRAG(vapor,liquid,zIdx)
            %FDRAG Interfacial drag force [N/m]
            %
            % Computes the interfacial drag force acting on the vapor phase by reversing
            % the sign of the liquid-phase drag (:meth:`Solvers.TwoFluid.Liquid.FDRAG`).
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Fdrag = -liquid.FDRAG(vapor,zIdx);
        end

        function Fintevap = FINTEVAP(vapor,liquid,zIdx)
            %FINTEVAP Momentum exchange through interfacial evaporation [N/m]
            %
            % Computes the momentum exchange due to interfacial evaporation.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            deltaU = liquid.U(zIdx)-vapor.U(zIdx);                         % [m/s]
            Fintevap = sum(vapor.MINTEVAP(liquid,zIdx),2).*deltaU;         % [N/m]
        end

        function Fwalevap = FWALEVAP(vapor,liquid,zIdx)
            %FWALEVAP Momentum exchange through wall evaporation [N/m]
            %
            % Computes the momentum exchange due to wall boiling evaporation.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:liquid(1).NZ).'; end

            deltaU = liquid.U(zIdx)-vapor.U(zIdx);                         % [m/s]
            Fwalevap = sum(vapor.MWALEVAP(liquid,zIdx),2).*deltaU;         % [N/m]
        end

        function Ftot = FTOT(vapor,liquid,zIdx)
            %FTOT Total force [N/m]
            %
            % Computes the total force acting on the vapor phase, including gravity,
            % buoyancy, wall shear, drag, and interfacial momentum exchanges.
            %
            % Inputs:
            %
            % - vapor  — :class:`Solvers.TwoFluid.Vapor` object
            % - liquid — :class:`Solvers.TwoFluid.Liquid` object
            % - zIdx   — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:vapor(1).NZ).'; end

            Fgrav    = vapor.FGRAV(liquid,zIdx);
            Fbuoy    = vapor.FBUOY(liquid,zIdx);
            Fdrag    = vapor.FDRAG(liquid,zIdx);
            Fwall    = vapor.FWALL(liquid,zIdx);
            Fintevap = vapor.FINTEVAP(liquid,zIdx);
            Fwalevap = vapor.FWALEVAP(liquid,zIdx);

            Ftot  = Fgrav + Fbuoy + Fwall + Fdrag + Fintevap + Fwalevap;   % [N/m]
        end

    end

end
