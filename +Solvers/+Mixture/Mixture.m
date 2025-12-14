classdef Mixture < Solvers.AbstractField
    %MIXTURE Class for modeling two-phase mixture field in mixture solver
    %
    % This class encapsulates the physical and numerical properties of a fluid mixture,
    % including flow variables, phase interactions, pressure losses, heat transfer,
    % and relaxation models. It supports multiple solver models and provides methods
    % for computing derived quantities and handling transitions such as boiling and annular flow.

    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})

        % Solver state

        NZ                                                                 = 0                    % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
        NTIME                                                              = 0                    % Number of time steps [-]
        TIME                                                               = 0                    % Time series [s]
        DT                                                                 = 0                    % Time step size [s] from :attr:`Inputs.options.TSTEP`
        TIDX                                                               = 1                    % Time step index [-]
        Z                                                                  = 1.                   % Elevation [m]

        % Wall heat flux

        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % Wall heat flux [W/m^2]

        % Flow variables

        W            (:,1) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        P            (:,1) double  {mustBeNumeric}                         = 7E6                  % Pressure [Pa]
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]

        % Detailed flow data (pressure drop, derivative terms, time relaxations)

        DP           (1,1) struct                                                                 % Saved detailed pressure drops [Pa]
        DPSUM        (1,1) struct                                                                 % Saved detailed cumulative pressure drops [Pa]
        MDER         (1,1) struct                                                                 % Saved detailed material derivative terms
        HRM          (1,1) struct                                                                 % Homogeneous relaxation terms
        NEARWALL     (1,1) struct                                                                 % Near-wall terms

        % Iteration tracking

        ITR                                                                                       % Iteration tracking

        % Phase objects

        liquid                                                                                    % Liquid phase object
        vapor                                                                                     % Vapor phase object

    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)

        DZ             (1,1) double  {mustBeNumeric}                       = 0                    % Axial step size [m]
        inputSet                     {isa(inputSet,'Inputs.InputSet')}                            % :class:`Inputs.InputSet` object
        fluid                        {isa(fluid,'Inputs.FluidProperties')}                        % :class:`Inputs.FluidProperties` object

    end

    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField}, GetAccess=?Solvers.AbstractField)

        % Wall heat transfer transition flags

        cbt            (:,:) logical                                       = false                % Critical Boiling Transition flag [-]
        mfbt           (:,:) logical                                       = false                % Minimum Film Boiling Transition flag [-]
    
    end

    properties (Access=private)

        % Derived flow properties

        mflux          (:,1) double  {mustBeNumeric}                       = 1.                   % Mass flux [kg/m^2-s]
        xeq            (:,1) double  {mustBeNumeric}                       = 1.                   % Equilibrium quality [-]
        x              (:,1) double  {mustBeNumeric}                       = 1.                   % Vapor quality [-]
        vf             (:,1) double  {mustBeNumeric}                       = 1.                   % Void fraction [-]
        chf            (:,:) double  {mustBeNumeric}                                              % Critical Heat Flux [W/m^2]
        rho            (:,1) double  {mustBeNumeric}                       = 1.                   % Mixture density [kg/m^3]

        % Onset of annular flow properties

        oafidx_const         double  {mustBeNumeric}                       = []                   % Solved index for onset of annular flow [-]
        sigm_const     (:,1) double  {mustBeNumeric}                       = []                   % Solved sigmoid function value [-]

        % Time relaxation arrays

        relaxtevap     (:,:) double  {mustBeNumeric}                                              % Time relaxation for interfacial evaporation [-]
        relaxtcond     (:,:) double  {mustBeNumeric}                                              % Time relaxation for interfacial condensation [-]
        nearwalltrelax (:,:) double  {mustBeNumeric}                                              % Time relaxation for near-wall energy transfer [-]
    
    end

    %% --- Constructor method ---

    methods

        function mix = Mixture(inputSet, fluid)
            %MIXTURE Constructor for Mixture class
            %
            % Initializes the mixture object with input configuration and
            % fluid properties. Sets up flow property tracking for simulation.
            %
            % Inputs:
            %
            % - inputSet — :class:`Inputs.InputSet` object containing model, geometry, and boundary conditions
            % - fluid    — :class:`Inputs.FluidProperties` object containing thermophysical fluid data

            if nargin > 0
                % Store inputSet as object property
                mix.inputSet = inputSet;
                mix.fluid  = fluid;
            end

            % Overload copyable properties (order is important due to the setter functions)
            mix.flowProperties = {'HRM','W','P','H','DP','DPSUM','MDER','ITR','NEARWALL','cbt','mfbt'};
        end

    end

    %% --- Setters and derived property accessors ---
    % These methods update internal state and trigger recalculation of dependent properties.
    % For example, setting enthalpy triggers recalculation of density, quality, and void fraction.

    methods

        function set.W(mix, val)
            %SET.W Setter for W, mass flow rate [kg/s]
            %
            % Updates the internal mass flow rate and triggers recalculation of
            % mass flux via :attr:`Solvers.Mixture.Mixture.MFLUX_CALC`.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object
            % - val — New mass flow rate [kg/s]

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
            %
            % Updates the internal enthalpy and triggers recalculation of dependent
            % properties: density, vapor quality, equilibrium quality, and
            % void fraction via :attr:`Solvers.Mixture.Mixture.RHO_CALC`.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object
            % - val — New enthalpy [J/kg]

            % Identify indexes to be updated
            zIdx = find(mix.H~=val);
            if isempty(zIdx), zIdx = (1:mix(1).NZ).'; end

            % Set mix.H value
            mix.H = val;

            % Calculate mix.rho (mix.rho calls mix.vf, which calls mix.x, which calls mix.xeq)
            mix.RHO_CALC(zIdx);
        end

        function mflux = MFLUX(mix, zIdx)
            %MFLUX Mass flux [kg/m^2/s]
            %
            % Retrieves precomputed mass flux values by
            % :attr:`Solvers.Mixture.Mixture.MFLUX_CALC`,
            % updated when mix.W is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                mflux = mix.mflux;
            else
                mflux = mix.mflux(zIdx);
            end
        end

        function xeq = XEQ(mix, zIdx)
            %XEQ Equilibrium quality [-]
            %
            % Retrieves precomputed equilibrium quality values by
            % :attr:`Solvers.Mixture.Mixture.XEQ_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                xeq = mix.xeq;
            else
                xeq = mix.xeq(zIdx);
            end
        end

        function x = X(mix, zIdx)
            %X Vapor quality [-]
            %
            % Retrieves precomputed vapor quality values by
            % :attr:`Solvers.Mixture.Mixture.X_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                x = mix.x;
            else
                x = mix.x(zIdx);
            end
        end

        function vf = VF(mix, zIdx)
            %VF Void fraction [-]
            %
            % Retrieves precomputed void fraction values by
            % :attr:`Solvers.Mixture.Mixture.VF_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                vf = mix.vf;
            else
                vf = mix.vf(zIdx);
            end
        end

        function chf =CHF(mix, zIdx)
            %CHF Critical Heat Flux [W/m^2], wall dependent
            %
            % Retrieves precomputed CHF values by
            % :attr:`Solvers.Mixture.Mixture.CBT_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                chf = mix.chf;
            else
                chf = mix.chf(zIdx,:);
            end
        end

        function cbt =CBT(mix, zIdx)
            %CBT Critical Boiling Transition flag [-], wall dependent
            %
            % Retrieves precomputed CBT flags by
            % :attr:`Solvers.Mixture.Mixture.CBT_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                cbt = mix.cbt;
            else
                cbt = mix.cbt(zIdx,:);
            end
        end

        function mfbt =MFBT(mix, zIdx)
            %MFBT Minimum Film Boiling Transition flag [-], wall dependent
            %
            % Retrieves precomputed MFBT flags by
            % :attr:`Solvers.Mixture.Mixture.MFBT_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                mfbt = mix.mfbt;
            else
                mfbt = mix.mfbt(zIdx,:);
            end
        end

        function rho = RHO(mix, zIdx)
            %RHO Density [kg/m^3]
            %
            % Retrieves precomputed mixture density values by
            % :attr:`Solvers.Mixture.Mixture.RHO_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                rho = mix.rho;
            else
                rho = mix.rho(zIdx);
            end
        end

        function t = RELAXTEVAP(mix, zIdx)
            %RELAXTEVAP Time relaxation for interfacial evaporation [s]
            %
            % Retrieves precomputed time relaxation values for evaporation by
            % :attr:`Solvers.Mixture.Mixture.RELAXTEVAP_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                t = mix.relaxtevap;
            else
                t = mix.relaxtevap(zIdx);
            end
        end

        function t = RELAXTCOND(mix, zIdx)
            %RELAXTCOND Time relaxation for interfacial evaporation [s]
            %
            % Retrieves precomputed time relaxation values for condensation by
            % :attr:`Solvers.Mixture.Mixture.RELAXTCOND_CALC`,
            % updated when mix.H is set.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to retrieve (optional)

            if nargin < 2
                t = mix.relaxtcond;
            else
                t = mix.relaxtcond(zIdx);
            end
        end

    end

    %% --- Fluid transport and thermodynamic calculations ---
    % T: Returns fluid temperature from enthalpy
    % U: Computes velocity from mass flow and density
    % X, XEQ: Returns vapor and equilibrium quality
    % VF: Computes void fraction
    % RHO: Computes mixture density

    methods

        function lhgr = LHGR(mix, zIdx)
            %LHGR Linear heat generation rate [W/m]
            %
            % Computes the linear heat generation rate by multiplying wall perimeter
            % with local heat flux.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with geometry and heat flux data
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;
            lhgr = geom.PERIM.*mix.HFLUX(zIdx,:);
        end

        function mu = MU(mix, zIdx)
            %MU Dynamic viscosity [Pa·s]
            %
            % Computes the mixture dynamic viscosity using vapor and liquid phase
            % contributions weighted by vapor quality.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with fluid properties
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            mu = mix.X(zIdx).*mix.fluid.MUV(mix.vapor.H(zIdx)) + ...
                (1-mix.X(zIdx)).*mix.fluid.MUL(mix.liquid.H(zIdx));
        end

        function u = U(mix, zIdx)
            %U Velocity [m/s]
            %
            % Computes the mixture velocity from mass flow rate and density.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            u = mix.W(zIdx)./mix.RHO(zIdx)./mix.inputSet.geometry.AREA;
        end

        function jl = JL(mix, zIdx)
            %JL Superficial liquid velocity [m/s]
            %
            % Computes the superficial velocity of the liquid phase.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
  
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            jl = (1-mix.X(zIdx)).*mix.MFLUX(zIdx)./mix.fluid.RHOL(mix.liquid.H(zIdx));
        end

        function jg = JG(mix, zIdx)
            %JG Superficial vapor velocity [m/s]
            %
            % Computes the superficial velocity of the vapor phase.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            jg = mix.X(zIdx).*mix.MFLUX(zIdx)./mix.fluid.RHOV(mix.vapor.H(zIdx));
        end

        function t = T(mix, zIdx)
            %T Temperature [K]
            %
            % Returns the fluid temperature corresponding to the local enthalpy.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with enthalpy data
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            t = mix.fluid.T(mix.H(zIdx));
        end

        function kdist = KDIST(mix,zIdx)
            %KDIST Distance from upstream obstruction [m]
            %
            % Computes the axial distance from the nearest upstream obstruction
            % or inlet, based on :attr:`Inputs.Model.KLOC`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with axial grid and obstruction location
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            dz = arrayfun(@(k) mix.Z(k)-[0 model.KLOC],zIdx,'uni',0);
            kdist = cellfun(@(dz) min(dz(dz>=0)),dz);                      % [m]
        end

        function kidx = KIDX(mix,zIdx)
            %KIDX Obstruction index
            %
            % Returns the axial node index of the obstruction closest to
            % :attr:`Inputs.Model.KLOC`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with axial grid
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            [~,ind] = min(abs(mix.Z-model.KLOC));                          % Find local loss elevation indexes (closest node)
            kidx = ind(ismember(ind,zIdx)).';
        end

        function klocz = KLOCZ(mix,zIdx)
            %KLOCZ Obstruction positions [m]
            %
            % Returns the axial position of the obstruction closest to
            % :attr:`Inputs.Model.KLOC`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with axial grid
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            ind = mix.KIDX(zIdx);
            klocz = mix.Z(ind);
        end

    end

    %% --- Momentum transfer and pressure drop models ---
    % RE, REL: Computes Reynolds numbers
    % FW, FWL: Computes friction factors
    % PHI2F, PHI2K: Computes multipliers for two-phase flow
    % DPGRAV, DPWALL, DPACCZ, DPACCT, DPK: Computes pressure loss components
    % DPTOT, DPPARTS: Computes total and decomposed pressure losses

    methods

        function re = RE(mix, zIdx)
            %RE Reynolds number [-]
            %
            % Computes the Reynolds number based on total mass flow rate and mixture
            % viscosity.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
 
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            re = 4.*mix.W(zIdx)./mix.MU(zIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function rel = REL(mix, zIdx)
            %REL Liquid-equivalent Reynolds number [-]
            %
            % Computes the Reynolds number using liquid viscosity and total mass flow.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            rel = 4.*mix.W(zIdx)./mix.fluid.MUL(mix.liquid.H(zIdx))./sum(mix.inputSet.geometry.PERIM);
        end

        function fw = FW(mix, zIdx)
            %FW Fanning wall friction factor [-]
            %
            % Computes the Fanning wall friction factor based on
            % :attr:`Inputs.Model.SPMTM` model.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Supported models
            %
            % - BLASIUS: Blasius model (:math:`f = C(1) Re^{C(2)} + C(3)`) using user-defined :attr:`Inputs.Model.FRICTION` coefficients

            % TODO: Implement additional wall friction factor as needed.

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            switch model.SPMTM
                case 'BLASIUS'
                    fw = model.FRICTION(1).*mix.RE(zIdx).^model.FRICTION(2)+model.FRICTION(3);
            end
        end

        function fwl = FWL(mix, zIdx)
            %FWL Liquid-equivalent Fanning wall friction factor [-]
            %
            % Computes the Fanning friction factor, using liquid-equivalent
            % Reynolds number, based on :attr:`Inputs.Model.SPMTM` model.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Supported models
            %
            % - BLASIUS: Blasius model (:math:`f = C(1) Re^{C(2)}`) using user-defined :attr:`Inputs.Model.FRICTION` coefficients

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            switch model.SPMTM
                case 'BLASIUS'
                    fwl = model.FRICTION(1).*mix.REL(zIdx).^model.FRICTION(2)+model.FRICTION(3);
            end
        end

        function phi2f = PHI2F(mix, zIdx)
            %PHI2F Two-phase wall friction multiplier [-]
            %
            % Computes the two-phase wall friction multiplier using
            % selected :attr:`Inputs.Model.TPFM` model.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Supported models
            %
            % - HOMOGENEOUS: Homogeneous model
            % - SLIP: Constant velocity slip ratio
            % - EPRI: EPRI multiplier

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));

            switch model.TPFM
                case 'HOMOGENEOUS'
                    phi2f = (1+mix.X(zIdx).*(RHOL./RHOV-1)).*(mix.FW(zIdx)./mix.FWL(zIdx));
                case 'SLIP'
                    phi2f = (RHOL./mix.RHO(zIdx)).*(mix.FW(zIdx)./mix.FWL(zIdx));
                case 'EPRI'
                    Pcrit = mix.fluid.PCRIT;                               % [Pa]
                    Press = mix.fluid.PRESSURE;                            % [Pa]
                    G = mix.MFLUX(zIdx).*737.3381E-6;                      % [Mlb/hr/ft^2]

                    XCF = 1.02.*mix.X(zIdx).^0.825.*G.^-0.45;              % [-]
                    if Press < 4.137E6
                        XCF = XCF./1.02.*0.357.*(1+10*Press/Pcrit);        % [-]
                    end
                    phi2f = 1 + (RHOL./RHOV-1).*XCF;                       % [-]
            end
        end

        function tauw = TAUW(mix, zIdx)
            %TAUW Wall shear stress [N/m^2], wall dependent
            %
            % Computes the wall shear stress for each wall segment using the 
            % friction factor, mass flux and two-phase multiplier. Supports 
            % multiple walls and adjusts for boiling transition conditions
            % using :attr:`Inputs.Model.BTMTM` model.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object containing flow and geometry data
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Supported boiling transition models
            %
            % - TPFM: Two-phase friction multiplier
            % - VAPOR: Shear stress to vapor phase

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;

            % Pre-CBT
            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));                     % [kg/m^3]
            tauw = 0.5.*(mix.FWL(zIdx)./4)./RHOL.*mix.MFLUX(zIdx).^2.*mix.PHI2F(zIdx); % [N/m^2]
            tauw = repmat(tauw,1,geom.NWALL);                              % [N/m^2] Expand to all walls (assumes same value for each wall)

            % Post-BT
            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);                        % Boiling transition flag
            if any(idxbt(:))
                model = mix.inputSet.model;

                switch model.BTMTM
                    case 'TPFM'
                        taubt = tauw;                                      % [N/m^2]
                    case 'VAPOR'
                        taubt  = mix.vapor.TAUW(zIdx);                     % [N/m^2]
                end

                % Replace tauw values at BT locations with corrected values
                tauw(idxbt) = taubt(idxbt);
            end
        end

        function kloss = KLOSS(mix, zIdx)
            %KLOSS Local pressure loss coefficient [-]
            %
            % Returns the pressure loss coefficient at the elevation closest to
            % :attr:`Inputs.Model.KLOC`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                % [-] Initialize local loss coefficient array to 0
            [~,ind] = min(abs(mix.Z-model.KLOC));                          % Find local loss elevation indexes (closest node)
            kloss(ind) = model.KLOSS;                                      % [-] Apply loss
            kloss = kloss(zIdx);                                           % [-] Restrict to selected input nodes
        end

        function phi2k = PHI2K(mix, zIdx)
            %PHI2K Two-phase local pressure drop multiplier [-]
            %
            % Computes the multiplier for local pressure drop in two-phase flow using
            % selected :attr:`Inputs.Model.TPKM` model.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Supported models
            %
            % - HOMOGENEOUS: Homogeneous model
            % - SLIP: Constant velocity slip ratio
            % - ROMIE: Romie multiplier

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));

            switch model.TPKM
                case 'HOMOGENEOUS'
                    phi2k = 1+mix.X(zIdx).*(RHOL./RHOV-1);
                case 'SLIP'
                    phi2k = RHOL./mix.RHO(zIdx);
                case 'ROMIE'
                    phi2k = mix.X(zIdx).^2./max(1E-6,mix.VF(zIdx)).*(RHOL./RHOV)+(1-mix.X(zIdx)).^2./max(1E-6,1-mix.VF(zIdx));
            end
        end

        function dpGrav = DPGRAV(mix, zIdx)
            %DPGRAV Gravitational pressure loss [Pa]
            %
            % Computes the pressure loss due to gravity along the axial direction.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            dpGrav  = -mix.inputSet.model.G*cos(mix.inputSet.model.ANGLE*pi/180)*mix.RHO(zIdx)*mix.DZ;
        end

        function dpWall = DPWALL(mix, zIdx)
            %DPWALL Wall friction pressure drop [Pa]
            %
            % Computes the pressure drop due to wall friction.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;

            dpWall  = -sum(geom.PERIM.*mix.TAUW(zIdx),2)./mix.inputSet.geometry.AREA.*mix.DZ;
        end

        function dpAcc_z = DPACCZ(mix, zIdx)
            %DPACCZ Spatial acceleration pressure drop [Pa]
            %
            % Computes the pressure drop due to spatial acceleration of the flow.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            deltaU = diff([[mix.U(1);mix.U(1:end-1)] mix.U],[],2);         % [m/s] Calculate velocity difference
            dpAcc_z = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*deltaU(zIdx);
        end

        function dpAcc_t = DPACCT(mix, Uold, zIdx)
            %DPACCT Temporal acceleration pressure drop [Pa]
            %
            % Computes the pressure drop due to temporal acceleration between time steps.
            %
            % Inputs:
            %
            % - mix   — :class:`Solvers.Mixture.Mixture` object
            % - Uold  — Previous axial velocity [m/s]
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:mix(1).NZ).'; end

            U     = mix.U(zIdx);                                           % [m/s] Calculate velocity
            dpAcc_t = -mix.W(zIdx)./mix.inputSet.geometry.AREA.*(1-Uold./U).*mix.DZ./mix.DT;
        end

        function dpk = DPK(mix, zIdx)
            %DPK Local pressure loss [Pa]
            %
            % Computes the pressure loss due to localized effects (e.g., flow mixers).
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
            dpk = -0.5.*mix.KLOSS(zIdx)./RHOL.*mix.MFLUX(zIdx).^2.*mix.PHI2K(zIdx);
        end

        function dptot = DPTOT(mix, Uold, zIdx)
            %DPTOT Total pressure loss [Pa]
            %
            % Computes the total pressure loss by summing all contributing components.
            %
            % Inputs:
            %
            % - mix   — :class:`Solvers.Mixture.Mixture` object
            % - Uold  — Previous axial velocity [m/s]
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:mix(1).NZ).'; end

            dptot = mix.DPGRAV(zIdx) + mix.DPWALL(zIdx) + mix.DPACCZ(zIdx) + mix.DPACCT(Uold, zIdx) + mix.DPK(zIdx);
        end

        function dpparts = DPPARTS(mix, Uold, zIdx)
            %DPPARTS All pressure loss components [Pa]
            %
            % Returns a structure containing all individual pressure loss components.
            %
            % Inputs:
            %
            % - mix   — :class:`Solvers.Mixture.Mixture` object
            % - Uold  — Previous axial velocity [m/s]
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Returns:
            %
            % - dpparts — Struct with fields:
            %
            %   - GRAV : Gravitational loss [Pa]
            %   - WALL : Wall friction loss [Pa]
            %   - ACCZ : Spatial acceleration loss [Pa]
            %   - ACCT : Temporal acceleration loss [Pa]
            %   - K    : Local loss [Pa]
            %   - TOT  : Total pressure loss [Pa]

            if nargin < 3, zIdx = (1:mix(1).NZ).'; end

            dpparts.GRAV = mix.DPGRAV(zIdx);
            dpparts.WALL = mix.DPWALL(zIdx);
            dpparts.ACCZ = mix.DPACCZ(zIdx);
            dpparts.ACCT = mix.DPACCT(Uold, zIdx);
            dpparts.K    = mix.DPK(zIdx);
            dpparts.TOT  = mix.DPTOT(Uold, zIdx);
        end

    end

    %% --- Wall heat transfer and boiling transition models ---
    % HWALLTHOM, HWALL: Computes heat transfer coefficients
    % TWALL: Computes wall temperature
    % CBT, MFBT: Returns boiling transition flags
    % CHF: Computes critical heat flux

    methods

         function hwallboil = HWALLBOIL(mix, zIdx)
            %HWALLBOIL Boiling wall heat transfer coefficient [W/m^2/K]
            %
            % Computes the boiling wall heat transfer coefficient using
            % selected :attr:`Inputs.Model.TPHTM` model.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Supported models
            %
            % - THOM: Thom's correlation

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            switch model.TPHTM
                case 'THOM'
                    % Thom's correlation, modified in term of heat transfer coefficient.
                    q  = mix.HFLUX(zIdx,:)+1E-6;                           % [W/m^2]
                    Tb = mix.liquid.T(zIdx);                               % [K]
                    hwallboil = q./(mix.fluid.TSAT-Tb+22.5.*(q./1E6).^0.5.*exp(-mix.P(zIdx)./1E6/8.7)); % [W/m^2/K]
            end

            hwallboil = max(0,hwallboil);
         end

         function hwall = HWALL(mix, zIdx)
            %HWALL Wall heat transfer coefficient [W/m^2/K]
            %
            % Computes the effective wall heat transfer coefficient by
            % combining single-phase and boiling models. Supports  multiple
            % walls and adjusts for boiling transition conditions using
            % :attr:`Inputs.Model.BTHTM` model.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Supported boiling transition models
            %
            % - VAPOR: Heat transfer to vapor phase

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            % Pre-CBT
            hsp = mix.liquid.HWALL(zIdx);                                  % [W/m^2/K] Single-phase liquid
            hboil = mix.HWALLBOIL(zIdx);                                   % [W/m^2/K] Boiling
            hwall = max(hsp,hboil);                                        % [W/m^2/K]

            % Post-CBT
            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);                        % Boiling transition flag

            if any(idxbt(:))
                model = mix.inputSet.model;

                switch model.BTHTM
                    case 'VAPOR'
                        hwallbt = mix.vapor.HWALL(zIdx);                   % [W/m^2/K] Single-phase vapor
                end

                % Replace hwall values at BT locations with corrected values
                hwall(idxbt) = hwallbt(idxbt);
            end
        end

        function twall = TWALL(mix, zIdx)
            %TWALL Wall temperature [K]
            %
            % Computes the wall temperature based on heat flux and wall heat transfer
            % coefficient. Uses liquid bulk temperature pre-CBT and vapor bulk
            % temperature post-CBT.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            q = mix.HFLUX(zIdx,:);                                         % [W/m^2]
            hwall = mix.HWALL(zIdx);                                       % [W/m^2/K]

            % Pre-CBT
            Tb    = mix.liquid.T(zIdx);                                    % [K] Fluid bulk temperature based on liquid phase
            twall = Tb + q./hwall;                                         % [K]

            % Post-CBT
            Tb       = mix.vapor.T(zIdx);                                  % [K] Fluid bulk temperature based on vapor phase
            twallcbt = Tb + q./hwall;                                      % [K]
            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);                        % Boiling transition flag
            twall(idxbt) = twallcbt(idxbt);                                % [K]
        end

    end

    %% --- Interfacial and wall mass and energy exchange ---
    % MINT, MINTEVAP, MINTCOND: Computes interfacial mass transfer
    % HINT, HINTEVAP, HINTCOND: Computes interfacial heat transfer
    % WALEVAPRATIO, MWALEVAP, HWALEVAP, HWALHEAT: Models wall boiling
    % MTOT, HTOT, HVTOT: Computes total mass and energy transfer

    methods

        function w = WWALL(mix, zIdx)
            %WWALL Mixture mass flow distribution per wall [kg/s]
            %
            % Computes the wall-distributed mass flow rate by scaling the total flow
            % with the wall perimeter ratio.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with geometry and flow data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial range)            

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom  = mix.inputSet.geometry;
            w = geom.RWALL.*mix.W(zIdx);                                   % [kg/s]
        end

        function ktrelax = KTRELAX(mix, zIdx)
            %KTRELAX Local relaxation time [s]
            %
            % Returns the relaxation time at the elevation closest to :attr:`Inputs.Model.KLOC`.
            % All other axial positions are set to NaN.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with axial grid and model parameters
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial range)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            ktrelax = nan(length(mix.Z),1);                                % [s] Initialize local relaxation time array to 0
            [~,ind] = min(abs(mix.Z-model.KLOC));                          % Find local loss elevation indexes (closest node)
            ktrelax(ind) = model.KTRELAX;                                  % [s] Apply relaxation time
            ktrelax = ktrelax(zIdx);                                       % [s] Restrict to selected input nodes
        end

        function [Mcond, Mevap] = MINT(mix, zIdx)
            %MINT Linear interfacial mass transfer rates [kg/s/m]
            %
            % Computes condensation and evaporation mass transfer rates based on
            % deviation from equilibrium vapor flow and time relaxation.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with flow and relaxation data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial range)
            %
            % Notes:
            %
            % - Uses mix.HRM.WV for equilibrium deviation
            % - UVeq is the approximated vapor velocity

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            UVeq = mix.vapor.U(zIdx);                                      % [m/s] Approximated equilibrium vapor velocity
            %WVeq = mix.WWALL(zIdx).*min(1,max(0,mix.XEQ(zIdx)));           % [kg/s] Equilibrium vapor mass flow rate per wall (option not used)
            WVeq = mix.WWALL(zIdx).*mix.XEQ(zIdx);                         % [kg/s] Equilibrium vapor mass flow rate per wall
            Wint = WVeq-mix.HRM.WV(zIdx,:);                                % [kg/s] Vapor mass deviation from equilibrium

            % NOT USED FOR NOW: transversal transfer across wall regions
            %Wint = sum(Wint,2).*mix.WWALL(zIdx)./mix.W(zIdx);              % [kg/s] Lumped approach required if used with separate transversal transfer (MTRANSV)

            Mcond = min(0,Wint./UVeq./mix.RELAXTCOND(zIdx));               % [kg/s/m] Condensation (<0)
            Mevap = max(0,Wint./UVeq./mix.RELAXTEVAP(zIdx));               % [kg/s/m] Evaporation  (>0)

            % Restrict to reasonable bounds
            %TODO: Find a more physical bound
            %Mcond = -min(-Mcond,mix.HRM.WV(zIdx,:)./mix.DZ);               % [kg/s/m] Condensation (<0)
            %Mevap =  min( Mevap,mix.liquid.W(zIdx)./mix.DZ);               % [kg/s/m] Evaporation  (>0)

            %Mcond = -min(-Mcond,mix.HRM.WV(zIdx,:)./UVeq./0.03);           % [kg/s/m] Condensation (<0)
            %Mevap =  min( Mevap,mix.liquid.W(zIdx)./UVeq./0.03);           % [kg/s/m] Evaporation  (>0)
        end

        function Mintevap = MINTEVAP(mix, zIdx)
            %MINTEVAP Linear interfacial evaporation rate [kg/s/m]
            %
            % Extracts the evaporation component from :attr:`Solvers.Mixture.Mixture.MINT`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            [~, Mintevap] = mix.MINT(zIdx);                                % [kg/s/m]
        end

        function Mintcond = MINTCOND(mix, zIdx)
            %MINTCOND Linear interfacial condensation rate [kg/s/m]
            %
            % Extracts the condensation component from :attr:`Solvers.Mixture.Mixture.MINT`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
           
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            Mintcond = mix.MINT(zIdx);                                     % [kg/s/m]
        end

        function Mtrans = MTRANSV(mix, zIdx)
            %MTRANSV Linear transversal mass exchange [kg/s/m]
            %
            % Models transverse vapor mass exchange between wall regions using a
            % time relaxation approach. Currently not used.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Uses a fixed relaxation time for now (RELAXT = 0.01 s)

            % TODO: Implement also enthalpy exchange and include in total mass/energy exchange terms

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            UVeq   = mix.vapor.U(zIdx);                                    % [m/s] Approximated equilibrium vapor velocity
            WVeq   = sum(mix.HRM.WV(zIdx,:),2).*(mix.WWALL(zIdx)./mix.W(zIdx));
            Wtrans = WVeq-mix.HRM.WV(zIdx,:);
            RELAXT = 0.01; % [s]

            Mtrans = Wtrans./UVeq./RELAXT;                                 % [kg/s/m]
        end

        function walevapratio = WALEVAPRATIO(mix, zIdx)
            %WALEVAPRATIO Wall mass evaporation ratio [-]
            %
            % Computes the fraction of liquid mass undergoing wall boiling based on
            % equilibrium quality and boiling onset thresholds
            % :attr:`Inputs.Model.WBOILINGXSUB` and
            % :attr:`Inputs.Model.WBOILINGXSAT`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with boiling model parameters
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Ratio is clamped between 0 and 1
            % - CBT and MFBT flags suppress boiling at transition nodes

            % TODO: Implement models for the onsets of subcooled and saturated wall boiling, as needed.

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            xsub = model.WBOILINGXSUB;                                     % Equilibrium quality at onset of subcooled wall boiling [-]
            xsat = model.WBOILINGXSAT;                                     % Equilibrium quality at onset of saturated wall boiling [-]
            n    = model.WBOILINGN;                                        % Exponent of wall boiling function [-]

            xeq = mix.XEQ(zIdx);                                           % [-]
            walevapratio = min(1,max(0,((xeq-xsub)./(xsat-xsub)).^n));     % [-]

            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);                        % Boiling transition flag
            walevapratio = walevapratio.*double(~idxbt);                   % [-]

            % Correction for transition nodes
            %xeq0 = mix.XEQ(zIdx-1);
            %r = min(1,max(0,(xeq-xsat)./(xeq-xeq0)));
            %wboilingratio = r.*wboilingratio;
        end

        function Mwalevap = MWALEVAP(mix, zIdx)
            %MWALEVAP Linear wall mass evaporation rate [kg/s/m]
            %
            % Computes the wall boiling mass transfer rate using latent heat and
            % wall heat generation rate.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with heat transfer and boiling data
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Latent heat is computed based on :attr:`Inputs.Model.INTTRANSH` setting

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            switch model.INTTRANSH
                case 'BULK'
                    %HFG = mix.vapor.H(zIdx) - mix.liquid.H(zIdx);          % [J/kg] Vapor is generated at bulk enthalpy
                    HFG = mix.HRM.HV(zIdx,:) - mix.liquid.H(zIdx);         % [J/kg] Vapor is generated at bulk enthalpy
                case 'SATURATED'
                    HFG = mix.fluid.HG - mix.liquid.H(zIdx);               % [J/kg] Vapor is generated at saturation
            end

            Mwall = mix.LHGR(zIdx)./HFG;                                   % [kg/s/m]
            Mwalevap = mix.WALEVAPRATIO(zIdx).*Mwall;                      % [kg/s/m]
        end

        function Mtot = MTOT(mix, zIdx)
            %MTOT Total linear vapor mass transfer rate [kg/s/m]
            %
            % Computes the total vapor mass transfer rate by summing interfacial
            % condensation, evaporation, and wall boiling contributions.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            [Mcond, Mevap] = mix.MINT(zIdx);                               % [kg/s/m]
            Mtot = Mcond + Mevap + mix.MWALEVAP(zIdx);                     % [kg/s/m]
        end

        function [Hcond, Hevap] = HINT(mix, zIdx)
            %HINT Linear interfacial heat transfer rate [W/m]
            %
            % Computes the interfacial heat transfer rates due to condensation and
            % evaporation, based on interfacial mass transfer and enthalpy differences.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with flow and enthalpy data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial range)
            %
            % Notes:
            %
            % - Uses :attr:`Solvers.Mixture.Mixture.MINT` for mass transfer and :attr:`Solvers.Mixture.Mixture.HRM.HV` for vapor enthalpy
            % - Behavior depends on :attr:`Inputs.Model.INTTRANSH`:
            %
            %   - `'BULK'`: Consideration of bulk enthalpy
            %   - `'SATURATED'`: Consideration of saturated enthalpy

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;

            [Mcond, Mevap] = mix.MINT(zIdx);                               % [kg/s] Interfacial mass flows
            HV = mix.HRM.HV(zIdx,:);                                       % [J/kg] Vapor enthalpy
            %HV = repmat(mix.vapor.H(zIdx),1,geom.NWALL);                   % [J/kg] Vapor enthalpy

            switch mix.inputSet.model.INTTRANSH
                case 'BULK'
                    Hcond = zeros(length(zIdx),geom.NWALL);                % [W/m]
                    Hevap = Mevap.*(mix.liquid.H(zIdx)-HV);                % [W/m]
                case 'SATURATED'
                    Hcond = Mcond.*(mix.fluid.HG-HV);                      % [W/m]
                    Hevap = Mevap.*(mix.fluid.HF-HV);                      % [W/m]
            end
        end

        function Hintevap = HINTEVAP(mix, zIdx)
            %HINTEVAP Linear interfacial heat evaporation rate [W/m]
            %
            % Extracts the evaporation component from :attr:`Solvers.Mixture.Mixture.HINT`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            [~, Hintevap] = mix.HINT(zIdx);                                % [W/m]
        end

        function Hintcond = HINTCOND(mix, zIdx)
            %HINTCOND Linear interfacial heat condensation rate [W/m]
            %
            % Extracts the condensation component from :attr:`Solvers.Mixture.Mixture.HINT`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            Hintcond = mix.HINT(zIdx);                                     % [W/m]
        end

        function Hwalevap = HWALEVAP(mix, zIdx)
            %HWALEVAP Linear wall heat evaporation (boiling) rate [W/m]
            %
            % Computes the heat transfer rate associated with wall boiling.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with boiling and enthalpy data
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Behavior depends on :attr:`Inputs.Model.INTTRANSH`:
            %
            %   - BULK: Consideration of bulk enthalpy
            %   - SATURATED: Consideration of saturated enthalpy

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            geom = mix.inputSet.geometry;

            switch mix.inputSet.model.INTTRANSH
                case 'BULK'
                    Hwalevap = zeros(length(zIdx),geom.NWALL);             % [W/m]
                case 'SATURATED'
                    Mwalevap = mix.MWALEVAP(zIdx);                         % [kg/s] Linear mass wall boiling rate
                    HV = mix.HRM.HV(zIdx,:);                               % [J/kg] Vapor enthalpy
                    Hwalevap = Mwalevap.*(mix.fluid.HG-HV);                % [W/m]
            end
        end

        function Hwalheat = HWALHEAT(mix, zIdx)
            %HWALHEAT Linear wall heat to vapor rate [W/m]
            %
            % Returns the wall heat generation rate (LHGR) at boiling transition nodes.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Applies only at nodes flagged by
            % :attr:`Solvers.Mixture.Mixture.CBT` or
            % :attr:`Solvers.Mixture.Mixture.MFBT`.

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            idxbt = mix.CBT(zIdx) | mix.MFBT(zIdx);                        % Boiling transition flag
            Hwalheat = double(idxbt).*mix.LHGR(zIdx);                      % [W/m]
        end

        function Htot = HTOT(mix, zIdx)
            %HTOT Total linear vapor heat rate [W/m]
            %
            % Computes the total vapor heat transfer rate by summing interfacial and
            % wall contributions.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            [Hcond, Hevap] = mix.HINT(zIdx);
            Htot = Hcond + Hevap + mix.HWALEVAP(zIdx) + mix.HWALHEAT(zIdx); % [W/m]
        end

        function Hvtot = HVTOT(mix, zIdx)
            %HVTOT Total linear vapor specific enthalpy transfer [J/kg/m]
            %
            % Computes the specific enthalpy input to the vapor per unit mass flow.
            % Uses a lumped wall approach for now.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object
            % - zIdx — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Uses lumped wall approach: sums WV and Htot across walls
            % - Set to zero when WV is negligible

            % Only the wall lump approach (i.e. same vapor heat input to all walls) is working correctly for now
            % Otherwise, the liquid can become subcooled in post CHF calculations
            % TODO: Fix issue and allow wall specific approach. This can be useful for DNB -> inverted film boiling

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            WV   = mix.HRM.WV(zIdx,:);                                     % [kg/s] Vapor mass flow rate
            Htot = mix.HTOT(zIdx);                                         % [W/m] Total linear vapor heat rate
            WV   = sum(WV,2); Htot = sum(Htot,2);                          % [kg/s,W/m] Wall lump approach

            Hvtot = Htot./WV;                                              % [J/kg/m]
            Hvtot(WV <= 1E-8) = 0;
        end

    end

    %% --- Near-wall modeling ---
    methods (Hidden = true)

        function t = NEARWALLTRELAX(mix, zIdx)
            %NEARWALLTRELAX Time relaxation for near-wall energy transfer [s]
            %
            % Retrieves precomputed time relaxation values for near-wall energy
            % transfer. These values are calculated by
            % :attr:`Solvers.Mixture.Mixture.NEARWALLTRELAX_CALC()`
            % and cached in mix.nearwalltrelax when
            % :attr:`Solvers.Mixture.Mixture.H` is set, and are not
            % recalculated during repeated calls.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with cached near-wall data
            % - zIdx — Axial indices to retrieve (optional; returns full vector if omitted)

            if nargin < 2
                t = mix.nearwalltrelax;
            else
                t = mix.nearwalltrelax(zIdx);
            end
        end

        function lambda = NEARWALLRATIO(mix)
            %NEARWALLRATIO Near-wall mass flow distribution ratio [-]
            %
            % Returns the near-wall mass flow distribution ratio, which should be less
            % than 1. A ratio of 1 implies that :attr:`Solvers.Mixture.Mixture.NEARWALL.XEQ`
            % and :attr:`Solvers.Mixture.Mixture.XEQ` are equal under
            % azimuthally uniform heat flux.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object containing model parameters

            model = mix.inputSet.model;

            lambda = model.NEARWALLRATIO;
        end

        function w = WNEARWALL(mix, zIdx)
            %WNEARWALL Near-wall mass flow rate per wall [kg/s]
            %
            % Computes the near-wall mass flow rate by scaling the wall flow rate
            % (:attr:`Solvers.Mixture.Mixture.WWALL`) with the near-wall
            % ratio :attr:`Solvers.Mixture.Mixture.NEARWALLRATIO`.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object with wall flow data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial range)

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            w = mix.WWALL(zIdx).*mix.NEARWALLRATIO;
        end

        function area = ANEARWALL(mix)
            %ANEARWALL Near-wall flow area [m^2]
            %
            % Computes the near-wall flow area based on the geometry.
            % :attr:`Inputs.Geometry.RWALL` and
            % :attr:`Solvers.Mixture.Mixture.WNEARWALL
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object containing geometry data

            geom = mix.inputSet.geometry;

            area = mix.NEARWALLRATIO.*geom.RWALL.*geom.AREA;
        end

        function heq = HNEARWALLEQ(mix, zIdx)
            %HNEARWALLEQ Near-wall equilibrium entalpy [J/kg]
            %
            % Compute the near-wall equilibrium enthalpy.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object containing geometry data

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            h   = mix.H(zIdx);

            % Multiplier to 1D-enthalpy
            heq = model.NEARWALLHMULT.*h;

            % Separate treatment for spacers
            idx = ismember(zIdx,mix.KIDX);
            heq(idx) = h(idx);

            heq = mix.AFDISTR(h,heq,zIdx);        
        end

    end

    %% --- Onset of annular flow detection and modeling ---
    % OAFX, OAFIDX, OAFZ, OAFWL: Detects onset of annular flow
    % AFFNC, AFDISTR: Models transition using sigmoid distribution

    methods

        function oafx = OAFX(mix, zIdx)
            %OAFX Onset of annular flow equilibrium quality.
            %
            % Computes the equilibrium quality at the onset of annular flow using
            % a model selected in :attr:`Inputs.Model.OAF`. The quality is
            % evaluated over the specified axial indices.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object containing model, geometry, and fluid data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial range)
            %
            % Supported Models:
            %
            % - WALLIS: Full Wallis model
            % - WALLIS_SIMP: Simplified Wallis model
            
            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;
            HDIAM = mix.inputSet.geometry.HDIAM;
            MFLUX = mix.MFLUX(zIdx);

            % Densities
            RHOF = mix.fluid.RHOF;
            RHOG = mix.fluid.RHOG;
            DELTARHO = RHOF-RHOG;

            switch model.OAF
                case InputEnums.OAF.WALLIS
                    % Wallis model
                    oafx = (0.6+0.4.*sqrt(model.G*HDIAM*(DELTARHO)*RHOF)./MFLUX)./(0.6+sqrt(RHOF/RHOG)); % [-] Quality at onset of annular flow
                case InputEnums.OAF.WALLIS_SIMP
                    % Simplified Wallis model
                    oafx = sqrt(model.G*HDIAM*(DELTARHO)*RHOG)./MFLUX;
            end
        end

        function oafIdx = OAFIDX(mix)
            %OAFIDX Onset of annular flow node.
            %
            % Returns the axial node index corresponding to the onset of annular
            % flow, determined by comparing the equilibrium quality to the onset
            % threshold. The result is cached in mix.oafidx_const to avoid
            % recomputation.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object containing flow quality and onset threshold
            %
            % Notes:
            %
            % - If no node satisfies the condition, the most upstream node (1) is returned

            % Use saved value if it has been calculated already
            if ~isempty(mix.oafidx_const)
                oafIdx = mix.oafidx_const;
                return
            end

            oafIdx = find(mix.XEQ <= mix.OAFX, 1, 'last');                 % Find node corresponding to the onset of annular flow
            if isempty(oafIdx), oafIdx = 1; end                            % Most upstream node (1) when pre-annular flow region is not found

            % Save value
            mix.oafidx_const = oafIdx;
        end

        function oafz = OAFZ(mix)
            %OAFZ Onset of annular flow elevation.
            %
            % Returns the axial elevation (in meters) corresponding to the onset
            % of annular flow, as defined by :attr:`Solvers.Mixture.Mixture.OAFIDX`.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object containing axial grid data
           
            oafz = mix.Z(mix.OAFIDX);                                      % [m]
        end

        function oafwl = OAFWL(mix)
            %OAFWL Liquid mass flow rate at onset of annular flow.
            %
            % Returns the liquid mass flow rate at the axial index corresponding
            % to the onset of annular flow, as defined by :attr:`Solvers.Mixture.Mixture.OAFIDX`.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object containing liquid flow data

            oafwl = mix.liquid.W(mix.OAFIDX);                              % [kg/s]
        end

        function afFnc = AFFNC(mix, zIdx)
            %AFFNC Computes annular flow fraction over axial positions.
            %
            % Evaluates the annular flow fraction using a sigmoid function
            % parameterized by the transition model and geometry. The sigmoid is
            % evaluated via the cached `sigm` method.
            %
            % Inputs:
            %
            % - mix  — :class:`Solvers.Mixture.Mixture` object containing model and geometry data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial range)
            %
            % Notes:
            %
            % - Sigmoid parameters are scaled by node density (NNODES / LENGTH)
            % - The center of the transition is offset by mix.OAFIDX()
            % - Uses mix.sigm(...) to evaluate the sigmoid function

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            p = model.OAFTRANSITION;                                       % Sigmoid function parameters
            p = p.*(model.NNODES/geom.LENGTH);                             % ... in node length
            afFnc = mix.sigm(zIdx,[p(1), mix.OAFIDX()+p(2)]);
        end

        function afDistr = AFDISTR(mix,param1,param2,zIdx)
            %AFDISTR Computes annular flow distribution over axial positions.
            %
            % Evaluates a weighted distribution between param1 and param2 using
            % the annular flow fraction defined in :class:`Solvers.Mixture.Mixture.AFFNC`.
            %
            % Inputs:
            %
            % - mix    — :class:`Solvers.Mixture.Mixture` object containing axial grid and flow fractions
            % - param1 — First flow property
            % - param2 — Second flow property
            % - zIdx   — Axial indices to evaluate (optional; defaults to full axial range)
            %
            % Notes:
            %
            % - The annular flow fraction is extracted from :class:`Solvers.Mixture.Mixture.AFFNC` at zIdx
            % - The output is a linear interpolation: (1 - affnc) * param1 + affnc * param2
            % - mix(1).NZ is used for default indexing, assuming mix may be an array

            if nargin < 4, zIdx = (1:mix(1).NZ).'; end

            affnc = mix.AFFNC(zIdx);
            afDistr = (1-affnc).*param1 + affnc.*param2;
        end

    end

    methods (Access = private)

        function s = sigm(mix, zIdx, pCoefs)
            %SIGM Calculates a sigmoid function over axial positions.
            %
            % Evaluates a sigmoid function at the specified axial indices
            % using the parameters in pCoefs. The result is cached in
            % mix.sigm_const to avoid recomputation.
            %
            % Inputs:
            %
            % - mix    — :attr:`Solvers.Mixture.Mixture` object containing axial grid
            % - zIdx   — Axial indices to evaluate
            % - pCoefs — Sigmoid parameters [slope, center]
            %
            % Notes:
            %
            % - The sigmoid is computed once and stored in mix.sigm_const
            % - Changing pCoefs after the first call will not update the cached values

            if isempty(mix.sigm_const)
                zIdxs = (1:mix(1).NZ).';
                mix.sigm_const = 1./(1+exp(-pCoefs(1).*(zIdxs-pCoefs(2)))); % Define sigmoid function
            end
            s = mix.sigm_const(zIdx);
        end

    end

    %% --- Helper functions for internal calculations ---
    % MFLUX_CALC, XEQ_CALC, X_CALC, VF_CALC, RHO_CALC: Internal property calculations
    % RELAXTEVAP_CALC, RELAXTCOND_CALC, NEARWALLTRELAX_CALC: Time relaxation calculations
    % sigm: Computes sigmoid function for annular flow
    % copyElement: Deep copy of mixture object
    % timeInterpolate, axialInterpolate: Interpolation utilities

    methods(Access = protected, Hidden = true)

        function MFLUX_CALC(mix, zIdx)
            %MFLUX_CALC Calculates mixture mass flux [kg/m²·s] at specified axial positions.
            %
            % Computes the mass flux at the given axial indices by dividing
            % the mixture mass flow rate by the flow area. The result is
            % stored in mix.mflux.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing flow and geometry data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)

            mix.mflux(zIdx) = mix.W(zIdx)./mix.inputSet.geometry.AREA;
        end

        function XEQ_CALC(mix, zIdx)
            %XEQ_CALC Calculates equilibrium vapor quality [-] at specified axial positions.
            %
            % Computes the equilibrium vapor quality at the given axial
            % indices using the mixture enthalpy and fluid saturation
            % properties. The result is stored in mix.xeq.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing enthalpy and fluid data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Notes:
            % - Assumes H_f and H_fg are constant across the axial domain

            mix.xeq(zIdx) = (mix.H(zIdx)-mix.fluid.HF)./ mix.fluid.HFG;
        end

        function X_CALC(mix, zIdx)
            %X_CALC Calculates vapor quality [-] at specified axial positions.
            %
            % Computes the vapor quality at the given axial indices using
            % the thermal non-equilibrium model defined in
            % :attr:`Inputs.Model.THERMALNONEQ`.
            % The result is stored in mix.x.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid, model, and geometry data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Supported Models:
            %
            % - EQUILIBRIUM: Uses equilibrium quality directly
            % - SAHAZUBER: Applies Saha-Zuber correlation for subcooled boiling
            % - EPRI: Uses EPRI correlation with bubble departure modeling
            % - HRM: Computes quality from Homogeneous Relaxation Model
            %
            % Notes:
            %
            % - Automatically invokes XEQ_CALC to ensure equilibrium quality is up to date
            % - Quality is bounded between 0 and 1 for physical consistency
            % - SAHAZUBER and EPRI models include empirical correlations and unit conversions
            % - TODO: Validate applicability of models for asymmetric wall heating

            % Call XEQ first
            mix.XEQ_CALC(zIdx);                                            % Use mix.xeq to calculate x

            % First initialization
            % Needed since some parameters in EPRI model require the phase enthalpy (and hence X) to be calculated first
            if length(mix.X) <= 1
                mix.x(zIdx) = max(mix.xeq(zIdx),0);
                return
            end

            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            switch model.THERMALNONEQ
                case 'EQUILIBRIUM'
                    % Thermal equilibrium model
                    mix.x(zIdx) = max(mix.xeq(zIdx),0);

                case 'SAHAZUBER'
                    % Saha-Zuber model
                    %
                    % :cite:t:`sahazuber1973`
                    % Saturated properties, averaged heat flux and hydraulic diameter are used
                    % Point of net vapor generation is bounded by [xin 0]

                    % TODO: Validate and potentially modify model for applications to channels with walls of different heat fluxes (e.g. unheated wall)
                    mix.x(zIdx) = max(mix.xeq(zIdx),0);

                    HDIAM = geom.HDIAM;                                    % [m] Diameter
                    HFG = mix.fluid.HFG;                                   % [J/kg]
                    KF = mix.fluid.KF;                                     % [W/m/K] Saturated liquid thermal conductivity
                    CPL = mix.fluid.CPF;                                   % [J/kg/K] Saturated liquid constant pressure specific heat
                    MFLUX = mix.MFLUX(zIdx);                               % [kg/m^2/s] Mass flux
                    HEATFLUX = sum(geom.PERIM.*mix.HFLUX(zIdx,:),2)./sum(geom.PERIM,2); % [W/m^2] Averaged wall heat flux

                    Pe = MFLUX.*(HDIAM*CPL/KF);                            % [-] Peclet number
                    Bo = HEATFLUX./MFLUX./HFG;                             % [-] Boiling number
                    xb = -0.0022.*min(7E4,Pe).*Bo;                         % [-] Thermodynamic quality at point B
                    xb = max(xb,min(mix.XEQ(1),-1E-6));                    % [-] Bound by inlet quality (up to 0)

                    idx = mix.xeq(zIdx) > xb;
                    zIdx = zIdx(idx);
                    mix.x(zIdx) = mix.xeq(zIdx)-xb(idx).*exp(mix.xeq(zIdx)./xb(idx)-1);
                    mix.x(zIdx) = mix.x(zIdx)./(1-xb(idx).*exp(mix.xeq(zIdx)./xb(idx)-1));

                case 'EPRI'
                    % EPRI model
                    %
                    % :cite:t:`lellouche1982`

                    HDIAM    = mix.inputSet.geometry.HDIAM;                % [m] Hydraulic diameter

                    % Find quality at bubble departure point
                    %TODO: Array calculations performed at each call, can be optimized
                    HFG      = mix.fluid.HFG;                              % [J/kg]
                    CPL      = mix.fluid.CPL(mix.liquid.H);                % [J/kg/K]
                    KL       = mix.fluid.KL(mix.liquid.H);                 % [W/m/K] Liquid thermal conductivity
                    PRANDTLL = mix.fluid.PRANDTLL(mix.liquid.H);           % [-] Liquid Prandtl number
                    % CPL      = mix.fluid.CPF;                             % [J/kg/K]
                    % KL       = mix.fluid.KF;                              % [W/m/K] Liquid thermal conductivity
                    % PRANDTLL = mix.fluid.PRANDTLF;                        % [-] Liquid Prandtl number

                    REL      = mix.liquid.RE;                              % [-] Reynolds number based on liquid phase

                    qWD  = mix.HFLUX;                                      % [W/m^2]
                    HDB  = mix.HWALLLIQ;                                   % [W/m^2/K] Dittus-Boelter correaltion
                    HB   = 193.*exp(-mix.P./4.344E6);                      % [Btu/hr/ft^2/F] Modified (?) Thom correlation
                    HB   = HB.*0.29307107./0.3048^2./(5/9);                % [W/m^2/K]
                    CHN  = 0.2;                                            % [-] Hancox and Nicoll coefficient (0.2 for channels and tubes)
                    NUHN = CHN.*REL.^0.662.*PRANDTLL;                      % [-] Hancox and Nicoll Nusselt
                    HHN  = NUHN.*KL./HDIAM;                                % [W/m^2/K]

                    qWD = qWD.*3.41.*0.3048^2;                             % [Btu/hr/ft^2}
                    HDB = HDB./(0.29307107./0.3048^2./(5/9));              % [Btu/hr/ft^2/F]
                    HB  = HB./(0.29307107./0.3048^2./(5/9));               % [Btu/hr/ft^2/F]
                    HHN = HHN./(0.29307107./0.3048^2./(5/9));              % [Btu/hr/ft^2/F]

                    A = 4.*HB.*(HDB+HHN).^2;
                    B = 2.*HDB.^2.*(HHN+0.5.*HDB)+8.*qWD.*HB.*(HHN+HDB);
                    C = 4.*HB.*qWD.^2+qWD.*HDB.^2;

                    Z = (B-sqrt(B.^2-4.*A.*C))./(2.*A);                    % [F] Bulk subcooling at bubble departure point
                    Z = Z.*(5/9);                                          % [K] Bulk subcooling at bubble departure point
                    xd = -CPL.*Z./HFG;                                     % [-] Quality at bubble departure point (array)

                    dIdx = find(mix.XEQ-xd>0,1);
                    xd = xd(dIdx);                                         % [-] Quality at bubble departure point

                    % Vapor quality distribution
                    if isempty(xd)
                        mix.x(zIdx) = max(mix.xeq(zIdx),0);                % [-]
                    else
                        xdmod = xd.*(1-tanh(1-mix.xeq(zIdx)./xd));         % [-]
                        x     = (mix.xeq(zIdx)-xdmod)./(1-xdmod);          % [-]
                        mix.x(zIdx) = max(x,0);                            % [-]
                    end

                case 'HRM'
                    % [-] Homogegeneous Relaxation Model
                    %
                    % Model based on interfacial phase change time relaxation approach (main calculations in solve.m)
                    % Physical approach to geometrical and thermal inhomogeneities

                    mix.x(zIdx) = sum(mix.HRM.WV(zIdx,:),2)./mix.W(zIdx);
            end
            mix.x(zIdx) = min(mix.x(zIdx),1);
        end

        function VF_CALC(mix, zIdx)
            %VF_CALC Calculates void fraction [-] at specified axial positions.
            %
            % Computes the void fraction at the given axial indices using
            % the selected void model defined in :attr:`Inputs.Model.VOID`.
            % The result is stored in mix.vf.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid, model, and geometry data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Supported Models:
            %
            % - HOMOGENEOUS: Assumes unity slip ratio
            % - SLIP: Uses a constant slip ratio
            % - BESTION: Applies Bestion drift flux correlation
            % - EPRI: Applies EPRI drift flux correlation with iterative convergence
            %
            % Notes:
            %
            % - Automatically invokes X_CALC to ensure vapor quality is up to date
            % - BESTION and EPRI models require fluid property evaluation
            % - EPRI model includes iterative convergence with error tolerance
            % - Internal helper functions:
            %     - vfslip(x, S): Slip-based void fraction
            %     - vfdrift(C0, ugj): Drift flux-based void fraction

            % Call X first
            mix.X_CALC(zIdx);

            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            switch model.VOID
                case InputEnums.VOID.HOMOGENEOUS
                    % [-] Homogeneous void model
                    mix.vf(zIdx) = vfslip(mix.X(zIdx),1);

                case InputEnums.VOID.SLIP
                    % [-] Slip void model
                    mix.vf(zIdx) = vfslip(mix.X(zIdx),model.SLIP);

                case InputEnums.VOID.BESTION
                    % [-] Bestion drift flux model
                    %
                    % :cite:t:`BESTION1990229`
                    C0 = 1.;                                               % [-] Distribution parameter
                    RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
                    RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(RHOL-RHOV)./RHOV); % [m/s] Drift velocity
                    mix.vf(zIdx) = vfdrift(C0,ugj);

                case InputEnums.VOID.EPRI
                    % [-] EPRI drift flux model
                    %
                    % :cite:t:`lellouche1982`

                    RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
                    RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
                    SIG  = mix.fluid.SIGMA;                                % [N/m]
                    Pcrit = mix.fluid.PCRIT;                               % [Pa]
                    Press = mix.fluid.PRESSURE;                            % [Pa}

                    C1 = 4/(Press/Pcrit-(Press/Pcrit)^2);                  % [-]
                    K1 = min(0.8,1./(1+exp(-mix.liquid.RE(1)/1E5)));       % [-]

                    r = (1+1.57.*RHOV./RHOL)./(1-K1);                      % [-]
                    K0 = K1 + (1-K1).*(RHOV./RHOL).^(1/4);                 % [-]
                    L = @(vf) (1-exp(-C1.*vf))./(1-exp(-C1));              % [-]

                    C0  = @(vf) L(vf)./(K0+(1-K0).*vf.^r);                 % [-] Distribution parameter
                    ugj = @(vf) 1.41.*((RHOL-RHOV).*SIG.*model.G./RHOL.^2).^(1/4).*((1-vf)./(1+vf)).^(1/2).*cos(model.ANGLE/180*pi); % [m/s] Drift velocity

                    vf = vfslip(mix.X(zIdx),1);                            % [-] Initialize void fraction
                    MaxIter = 100;                                         % Maximum number fo iterations
                    MaxErr  = 0.001;                                       % [-] Maximum void fraction error
                    for i = 1:MaxIter
                        mix.vf(zIdx) = vfdrift(C0(vf),ugj(vf));
                        err = max(abs(mix.vf(zIdx)-vf));
                        if err < MaxErr, break; end
                        vf = mix.vf(zIdx);
                    end
                    if i == MaxIter, fprintf('%s EPRI void model : not converged -> err=%0.4f\n',class(mix), err); end
            end

            function vf = vfslip(x,S)
                %VFSLIP Void fraction based on slip model

                RHOL = mix.fluid.RHOL(mix.liquid.H(zIdx));
                RHOV = mix.fluid.RHOV(mix.vapor.H(zIdx));
                vf = x.*RHOL./(x.*RHOL+S.*(1-x).*RHOV);
            end

            function vf = vfdrift(C0,ugj)
                %VFDRIFT Void fraction based on drift flux model
                %
                % C0    [-]     Distribution parameter
                % ugj   [m/s]   Drift velocity

                vf  = mix.JG(zIdx)./(C0.*(mix.JG(zIdx)+mix.JL(zIdx))+ugj);
            end
        end

        function CBT_CALC(mix, zIdx)
            %CBT_CALC Calculates Critical Heat Flux (CHF) and Critical Boiling Transition (CBT) flag.
            %
            % Evaluates the critical heat flux at specified axial positions
            % using the CHF correlation defined in
            % :attr:`Inputs.Model.CBT` and sets the CBT flag based
            % on either elevation or heat flux criteria.
            %
            % Inputs:
            %
            % mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid, model, and geometry data
            % zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Supported Models:
            %
            % - NONE: Disables CHF and CBT detection
            % - ELEVATION: CBT triggered at or above a elevation specified by :attr:`Inputs.Model.CBTELEVATION`
            % - BIASI: Uses Biasi correlation for CHF estimation
            % - BEZRUKOV: Uses Bezrukov correlation for CHF estimation
            %
            % Notes:
            %
            % - CHF can adjusted using user-defined multipliers :attr:`Inputs.Model.CBTMULT` and obstruction effects defined by :attr:`Inputs.Model.CBTKEFFECT`
            % - CBT flag is set where wall heat flux exceeds CHF or based on elevation
            % - TODO: Extend with additional CHF correlations as necessary

            %fld   = mix.fluid;
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            % CHF
            Pr  = mix.P(end);                                              % [Pa] System pressure
            G   = mix.MFLUX(1:mix(1).NZ);                                  % [kg/m^2/s] Mass flux
            XEQ = mix.XEQ(1:mix(1).NZ);                                    % [-] Equilibrium quality
            D   = geom.HDIAM;                                              % [m] Diameter

            switch model.CBT
                case {InputEnums.CBT.NONE,InputEnums.CBT.ELEVATION}
                    chf = nan(mix(1).NZ,geom.NWALL);                       % Skip CHF calculation

                case InputEnums.CBT.BIASI
                    % Biasi correlation
                    %
                    % :cite:t:`biasi1966burnout`

                    Pr = Pr/1.01235E5;                                     % [ata] System pressure
                    G  = G./10;                                            % [g/cm^2/s] Mass flux
                    D  = D*1E2;                                            % [cm] Diameter

                    n = 0.6 - 0.2*double(D>=1);

                    HP = -1.159+0.149*Pr*exp(-0.019*Pr)+8.99*Pr/(10+Pr^2);
                    YP = 0.7249+0.099*Pr*exp(-0.032*Pr);

                    q1 = (3.780E3/D^n)./G.^0.6.*HP.*(1-XEQ);               % [W/cm^2] High quality
                    q2 = (1.883E3/D^n)./G.^(1/6).*(YP./G.^(1/6)-XEQ);      % [W/cm^2] Low quality

                    chf = repmat(max(q1,q2),1,geom.NWALL).*1E4;            % [W/m^2]

                case InputEnums.CBT.BEZRUKOV
                    % Bezrukov correlation
                    %
                    % :cite:t:`Bezrukov1976`

                    Pr = Pr/1E6;                                           % [MPa] System pressure

                    a1 =  0.795; a4 = -0.127;
                    a2 = -0.5;   a5 =  0.311;
                    a3 =  0.105; a6 = -0.0185;

                    q = a1.*(1-XEQ).^(a2+a3.*Pr).*G.^(a4+a5.*(1-XEQ)).*(1+a6.*Pr); % [MW/m^2]

                    chf = repmat(q,1,geom.NWALL).*1E6;                     % [W/m^2]
            end

            % Adjustment factors
            chf = model.CBTMULT(mix.Z).*chf;                               % Apply user input multiplier

            if max(model.KLOC) > 0
                z0 = mix.KDIST(); z0(mix.Z < model.KLOC(1)) = 1E6;         % [m] Distance from upstream obstruction (inlet effect ignored)
                chf = (1+model.CBTKEFFECT(1).*exp(model.CBTKEFFECT(2).*z0./geom.HDIAM)).*chf; % Apply spacer effect
            end

            mix.chf(zIdx,:) = chf(zIdx,:);                                 % [W/m^2] Critical heat flux

            % CBT flag
            switch model.CBT
                case InputEnums.CBT.ELEVATION
                    cbt = mix.Z >= model.CBTELEVATION;                     % CBT indicator based on input elevation

                otherwise
                    cbt = mix.HFLUX(1:mix.NZ,:) > chf;                     % CBT indicator based on CHF value
            end

            %cbt(mix.XEQ>=1,:) = true;                                      % Set cbt to 1 for Xeq >= 1

            mix.cbt(zIdx,:) = cbt(zIdx,:);                                 % [-] CBT flag
        end

        function MFBT_CALC(mix, zIdx)
            %MFBT_CALC Calculates the Minimum Film Boiling Transition (MFBT) flag.
            %
            % Evaluates whether the wall temperature exceeds the minimum
            % film boiling threshold at the specified axial indices, based
            % on the MFBT model defined in :attr:`Inputs.Model.MFBT.
            % The result is stored in mix.mfbt as a logical array.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid, model, and geometry data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Supported Models:
            %
            % - NONE: Disables MFBT detection
            % - CONSTANT: Applies a fixed temperature margin (DTMFB) above saturation
            %
            % Notes:
            %
            % - TODO: Extend with additional MFBT models as necessary 


            %MFBT_CALC Helper function to calculate the Minimum Film Boiling
            % Transition and CBT flag

            % TODO: Implement additional MFBT correlations

            fld   = mix.fluid;
            model = mix.inputSet.model;
            geom  = mix.inputSet.geometry;

            switch model.MFBT
                case InputEnums.MFBT.NONE
                    mfbt = false(length(zIdx),geom.NWALL);
                case InputEnums.MFBT.CONSTANT
                    mfbt = mix.TWALL(zIdx) > fld.TSAT+model.DTMFB;
            end

            mix.mfbt(zIdx,:) = mfbt;
        end

        function RHO_CALC(mix, zIdx)
            %RHO_CALC Calculates mixture density [kg/m^3] at specified axial positions.
            %
            % Computes the mixture density at the given axial indices by
            % combining vapor and liquid phase densities weighted by void
            % fraction. The result is stored in mix.rho.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid and phase data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Notes:
            %
            % - Automatically invokes VF_CALC to ensure void fraction is up to date
            % - Also triggers calculation of related thermal relaxation and transition flags:
            %
            %     - CBT_CALC
            %     - MFBT_CALC
            %     - RELAXTEVAP_CALC
            %     - RELAXTCOND_CALC
            %     - NEARWALLTRELAX_CALC

            % Call VF and CHF first
            mix.VF_CALC(zIdx);

            vf = mix.VF(zIdx);
            mix.rho(zIdx) = vf.*mix.fluid.RHOV(mix.vapor.H(zIdx)) + ...
                (1-vf).*mix.fluid.RHOL(mix.liquid.H(zIdx));

            mix.CBT_CALC(zIdx);
            mix.MFBT_CALC(zIdx);
            mix.RELAXTEVAP_CALC(zIdx);
            mix.RELAXTCOND_CALC(zIdx);
            mix.NEARWALLTRELAX_CALC(zIdx);
        end

        function RELAXTCOND_CALC(mix, zIdx)
            %RELAXTCOND_CALC Calculates relaxation time for wall-dependent
            % interfacial condensation.
            %
            % Computes the time relaxation associated with interfacial
            % condensation at the specified axial indices, based on the
            % thermal relaxation model defined in :attr:`Inputs.Model.THERMALRELAXTHERMALRELAX.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid and model data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Supported Models:
            %
            % - QUALITY: Interpolates relaxation time from predefined quality-time pairs
            % - VOID: Computes relaxation time based on void fraction and fluid properties
            %
            % Notes:
            %
            % - Local perturbation overrides are applied using mix.KTRELAX
            % - Relaxation time is bounded below by 1e-6 to ensure numerical stability
            % - TODO: Investigate whether this parameter should be wall-dependent

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;
            fld = mix.fluid;

            Xeq = mix.XEQ(zIdx);

            switch model.THERMALRELAX
                case InputEnums.THERMALRELAX.QUALITY
                    X = model.RELAXX;                                      % [-] Equilibrium quality array
                    T = model.RELAXTCOND(1:length(model.RELAXX));          % [-] Corresponding time relaxation

                    t = interp1(X,T,Xeq,'linear','extrap');                % [s] Interpolated time relaxation
                    t(Xeq<X(1))   = T(1);                                  % [s] Lower bound limit
                    t(Xeq>X(end)) = T(end);                                % [s] Upper bound limit

                case InputEnums.THERMALRELAX.VOID
                    d0     = model.RELAXCONDCOEF(1);                       % [m] Reference fluid particle Sauter mean diameter
                    n      = model.RELAXCONDCOEF(2);                       % [-] Exponent of phase volumetric ratio
                    dvf    = model.RELAXCONDCOEF(3);                       % [-] Small phase volumetric ratio bias to avoid singularity
                    b      = model.RELAXCONDCOEF(4);                       % [-] Exponent of quality difference
                    ALPHAL = fld.ALPHAL(mix.liquid.H(zIdx));               % [m/s^2] Liquid thermal diffusivity
                    VF     = mix.vapor.VF(zIdx);                           % [-] Vapor volume fraction
                    deltaX = Xeq-mix.HRM.X(zIdx,:);                        % [-] Quality difference
                    Fo     = 1./(VF+dvf).^n./abs(deltaX).^b;               % [-] Fourier number

                    t = d0.^2./ALPHAL.*Fo;                                 % [s] Time relaxation
            end

            %geom  = mix.inputSet.geometry;
            %t = repmat(t,1,geom.NWALL);                                    % Expand to all wall

            idx = mix.KTRELAX(zIdx)>0;                                     % Index of local perturbations
            t(idx,:) = mix.KTRELAX(zIdx(idx));                             % [s] Time relaxation at local perturbations
            t = max(1E-6,t);
            mix.relaxtcond(zIdx,:) = t;
        end

        function t = RELAXTEVAP_CALC(mix, zIdx)
            %RELAXTEVAP_CALC Calculates relaxation time for wall-dependent
            % interfacial evaporation.
            %
            % Computes the time relaxation associated with interfacial
            % evaporation at the specified axial indices, based on the
            % thermal relaxation model defined in :attr:`Inputs.Model.THERMALRELAX`.
            %
            % Inputs:
            %
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid and model data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Supported Models:
            %
            % - QUALITY: Interpolates relaxation time from predefined quality-time pairs
            % - VOID: Computes relaxation time based on void fraction and fluid properties
            %
            % Notes:
            %
            % - Local perturbation overrides are applied using mix.KTRELAX
            % - Relaxation time is bounded below by 1e-6 to ensure numerical stability
            % - TODO: Investigate whether this parameter should be wall-dependent

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;
            fld = mix.fluid;

            Xeq = mix.XEQ(zIdx);

            switch model.THERMALRELAX
                case InputEnums.THERMALRELAX.QUALITY
                    X = model.RELAXX;                                      % [-] Equilibrium quality array
                    T = model.RELAXTEVAP(1:length(model.RELAXX));          % [-] Corresponding time relaxation

                    t = interp1(X,T,Xeq,'linear','extrap');                % [s] Interpolated time relaxation
                    t(Xeq<X(1))   = T(1);                                  % [s] Lower bound limit
                    t(Xeq>X(end)) = T(end);                                % [s] Upper bound limit

                case InputEnums.THERMALRELAX.VOID
                    d0     = model.RELAXEVAPCOEF(1);                       % [m] Reference fluid particle Sauter mean diameter
                    n      = model.RELAXEVAPCOEF(2);                       % [-] Exponent of phase volumetric ratio
                    dvf    = model.RELAXEVAPCOEF(3);                       % [-] Small phase volumetric ratio bias to avoid singularity
                    b      = model.RELAXCONDCOEF(4);                       % [-] Exponent of quality difference
                    ALPHAV = fld.ALPHAV(mix.vapor.H(zIdx));                % [m/s^2] Liquid thermal diffusivity
                    VF     = mix.liquid.VF(zIdx);                          % [-] Liquid volume fraction
                    deltaX = Xeq-mix.HRM.X(zIdx,:);                        % [-] Quality difference
                    Fo     = 1./(VF+dvf).^n./abs(deltaX).^b;               % [-] Fourier number

                    t = d0.^2./ALPHAV.*Fo;                                 % [s] Time relaxation
            end

            idx = mix.KTRELAX(zIdx)>0;                                     % Index of local perturbations
            t(idx,:) = mix.KTRELAX(zIdx(idx));                             % [s] Time relaxation at local perturbations
            t = max(1E-6,t);
            mix.relaxtevap(zIdx,:) = t;
        end

        function NEARWALLTRELAX_CALC(mix, zIdx)
            %NEARWALLTRELAX_CALC Calculates near-wall relaxation time based
            % on equilibrium quality or void fraction models.
            %
            % Computes the relaxation time for near-wall energy transfer
            % based on the selected model in :attr:`Inputs.Model.NEARWALLRELAX`.
            % The result is stored in mix.nearwalltrelax at the specified
            % axial indices.
            %
            % Inputs:
            % - mix  — :attr:`Solvers.Mixture.Mixture` object containing fluid and model data
            % - zIdx — Axial indices to evaluate (optional; defaults to full axial domain)
            %
            % Supported Models:
            % - QUALITY: Interpolates relaxation time from predefined quality-time pairs
            % - VOID: Computes relaxation time based on void fraction and fluid properties
            %
            % Notes:
            % - Local perturbation overrides are applied using mix.KTRELAX
            % - Relaxation time is bounded below by 1e-6 to ensure numerical stability

            if nargin < 2, zIdx = (1:mix(1).NZ).'; end

            model = mix.inputSet.model;

            switch model.NEARWALLRELAX
                case InputEnums.NEARWALLRELAX.QUALITY
                    X = model.NEARWALLRELAXX;                              % [-] Equilibrium quality array
                    T = model.NEARWALLRELAXT(1:length(model.NEARWALLRELAXX)); % [-] Corresponding time relaxation

                    t = interp1(X,T,mix.XEQ(zIdx),'linear','extrap');      % [s] Interpolated time relaxation
                    t(mix.XEQ(zIdx)<X(1))   = T(1);                        % [s] Lower bound limit
                    t(mix.XEQ(zIdx)>X(end)) = T(end);                      % [s] Upper bound limit

                case InputEnums.NEARWALLRELAX.VOID
                    d0     = model.NEARWALLRELAXCOEF(1);                   % [m] Reference fluid particle Sauter mean diameter
                    n      = model.NEARWALLRELAXCOEF(2);                   % [-] Exponent of phase volumetric ratio
                    dvf    = model.NEARWALLRELAXCOEF(3);                   % [-] Small phase volumetric ratio bias to avoid singularity
                    ALPHAL = mix.fluid.ALPHAL(mix.liquid.H(zIdx));
                    t = d0.^2./ALPHAL./(mix.vapor.VF(zIdx)+dvf).^n;        % [s] Time relaxation
            end

            idx = mix.KTRELAX(zIdx)>0;                                     % Index of local perturbations
            t(idx,:) = mix.KTRELAX(zIdx(idx));                             % [s] Time relaxation at local perturbations
            t = max(1E-6,t);
            mix.nearwalltrelax(zIdx,:) = t;
        end

    end

    %% --- Other methods ---
    methods(Access = protected, Hidden = true)

        function cpObj = copyElement(obj)
            %COPYELEMENT Creates a deep copy of the Mixture object with updated phase references.
            %
            % Overrides the default copy behavior to ensure that the copied
            % Mixture object correctly reinitializes its associated Liquid
            % and Vapor phase objects. This is necessary because these phase
            % objects hold internal references to the Mixture instance.
            %
            % Notes:
            % - Uses matlab.mixin.Copyable base method for shallow copy
            % - Reconstructs Liquid and Vapor objects to point to the copied mixture

            import Solvers.Mixture.*

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);

            % Update liquid and vapor 'mix' property
            cpObj.liquid = Liquid(cpObj);
            cpObj.vapor = Vapor(cpObj);
        end


        function interpOut = timeInterpolate(mix, y)
            %TIMEINTERPOLATE Interpolates vector y over the solver time grid.
            %
            % Interpolates the values in y, defined at boundary condition
            % time points (:attr:`Inputs.InputSet.BoundaryConditions.TIME`),
            % to the solver's internal time grid (:attr:`Solvers.Mixture.TIME)
            % using the method specified in :attr:`Inputs.InputSet.options.TIMEINTERP`.
            %
            % Inputs:
            %
            % - mix — Mixture object containing time grid (TIME)
            % - y   — Vector of values defined at boundary condition times
            %
            % Output:
            %
            % - interpOut — Interpolated values at mix.TIME positions

            interpOut = interp1([mix.inputSet.bc.TIME], ...
                y, ...
                mix.TIME, ...
                mix.inputSet.options.TIMEINTERP);
        end

        function interpOut = axialInterpolate(mix, x, y)
            %AXIALINTERPOLATE Interpolates vector y over domain x at solver axial positions.
            %
            % Interpolates the values in y defined over x to the axial
            % positions specified in mix.Z using the interpolation method
            % defined in :attr:`Inputs.InputSet.options.AXIALINTERP`.
            % Extrapolation is enabled to handle out-of-bound values.
            %
            % Inputs:
            %
            % - mix — :class:`Solvers.Mixture.Mixture` object containing axial grid (Z)
            % - x   — Independent variable (e.g., axial mesh)
            % - y   — Dependent variable to interpolate
            %
            % Output:
            %
            % - interpOut — Interpolated values at mix.Z positions

            interpOut = interp1(x, ...
                y, ...
                mix.Z, ...
                mix.inputSet.options.AXIALINTERP, ...
                "extrap");
        end

    end

end

