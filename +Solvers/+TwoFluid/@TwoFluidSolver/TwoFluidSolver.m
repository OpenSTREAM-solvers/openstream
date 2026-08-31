classdef TwoFluidSolver < Solvers.AbstractSolver
    %TWOFLUIDSOLVER Solver for initializing, solving, and visualizing two-fluid flow.
    %
    % The TwoFluidSolver class handles the setup, execution, and visualization
    % of thermal-hydraulic simulations using a two-phase two-fluid approach.
    %
    % Responsibilities:
    %
    % - Initializes solver parameters from an :class:`Inputs.InputSet` object
    % - Constructs :class:`Solvers.TwoFluid.Liquid` and :class:`Solvers.TwoFluid.Vapor` objects for transient and steady-state analysis
    % - Provides plotting utilities for spatial and temporal distributions
    %
    % Key Components:
    %
    % - Phase construction (liquid/vapor)
    % - Phase mass/momentum/energy transport modeling
    % - Pressure drop gradient obtained from mixture solver
    % - Support for relaxation models
    % - Visualization of results across time and axial domains

    properties (SetAccess=protected)

        NZ           (1,1) double  {mustBeNumeric}                         = 0         % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
        NTIME        (1,1) double  {mustBeNumeric}                         = 0         % Number of time steps [-]
        TIME         (:,1) double  {mustBeNumeric}                         = 0         % Time series [s]
        DT           (1,1) double  {mustBeNumeric}                         = 0         % Time step size [s] from :attr:`Inputs.Options.TSTEP`
        Z            (:,1) double  {mustBeNumeric}                         = 1.        % Elevation [m]
        DZ           (1,1) double  {mustBeNumeric}                         = 0         % Axial step size [m]

        fluid       {isa(fluid,'Inputs.FluidProperties')}                              % Fluid object :class:`Inputs.FluidProperties`
        boundaryConditions                                                             % Boundary conditions object :class:`Inputs.BoundaryConditions`

        liquidInit                                                                     % Null transient liquid object
        vaporInit                                                                      % Null transient vapor object
        liquid                                                                         % Liquid object
        vapor                                                                          % Vapor object

    end

    properties (SetAccess = protected)

        mixSolver                                                                      % Mixture object :class:`Solvers.Mixture.Mixture`
        inputSet                                                                       % Input set object :class:`Inputs.InputSet`
        STATE                                                              = Solvers.SolverState.UNSOLVED
    
    end

    methods

        solve(twfSolver)                                                               % Solving algorithm
    
    end

    methods

        function twfSolver = TwoFluidSolver(inputSet,mixSolver)
            %TWOFLUIDSOLVER Constructor for the TwoFluidSolver class.
            %
            % Creates a new instance of the TwoFluidSolver class using the
            % provided :class:`Inputs.InputSet`. This constructor initializes
            % the solver by calling the abstract :class:`Solvers.AbstractSolver`
            % superclass constructor and then sets up all necessary solver
            % parameters and internal data structures via
            % :meth:`Solvers.TwoFluid.TwoFluidSolver.initializeSolver <Solvers.TwoFluid.TwoFluidSolver.TwoFluidSolver.initializeSolver>`
            %
            % Input:
            %
            % - inputSet — An :class:`Inputs.InputSet` object containing model configuration, geometry, boundary conditions, and solver options.
            % - mixSolver — An optional solved :class:`Solvers.Mixture.MixtureSolver` object
            %
            % Notes:
            %
            % - This constructor assumes :class:`Inputs.InputSet` is fully validated.
            % - A solved mixture-model solution is required for initialization. If a solved mixture solver is supplied, its solution is reused. If unsolved of if no mixture solver is supplied, one is created and solved automatically.
            % - Solver initialization includes liquid and vapor objects setup.
            % - Time/space discretization and boundary condition interpolation initialized by :class:`Solvers.Mixture.MixtureSolver` are used

            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            twfSolver = twfSolver@Solvers.AbstractSolver(inputSet);

            % Store mixSolver handle
            twfSolver.mixSolver = mixSolver;

            % Attempt to solve mixSolver if it is unsolved
            if twfSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
                twfSolver.mixSolver.solve();
            end

            % Initialize solver parameters
            twfSolver.initializeSolver();

        end

        function initializeSolver(twfSolver)
            %INITIALIZESOLVER Initializes solver parameters and constructs liquid/vapor objects.
            %
            % Sets up the solver's internal state using the provided
            % :class:`Inputs.InputSet` and :class:`Solvers.TwoFluid.TwoFluidSolver`,
            % This includes initialization of data structures for transient and steady-state
            % simulations based on the mixture solver solutions.
            %
            % Operations performed:
            %
            % - Initializes liquid and vapor arrays for each time step
            % - Initializes fluid property objects
            % - Sets up mixture object
            % - Assigns initial conditions for phase mass flow rates, velocities, enthalpies
            %
            % Notes:
            %
            % - The function assumes uniform axial discretization.
            % - Wall heat flux is computed from interpolated boundary conditions.

            import Inputs.*
            import Solvers.TwoFluid.*
            import Solvers.*

            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                twfSolver.(p{:}) = twfSolver.mixSolver.(p{:});
            end

            % Local parameters
            mixArr = twfSolver.mixSolver.mixture;                          % Mixture solution

            % Setup inner iteration value struct
            ITRFields = ["N","DW","DU","DH"];
            ITRl = twfSolver.CreateITR(twfSolver.NZ, ITRFields);
            ITRFields = ["N","DW","DU","DH"];
            ITRv = twfSolver.CreateITR(twfSolver.NZ, ITRFields);

            % Create liquid and vapor arrays (by timestep)
            liqArr(twfSolver.NTIME) = Liquid();
            vapArr(twfSolver.NTIME) = Vapor();
            props = {'NZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid'};  % liquid and vapor properties

            for tIdx = 1:twfSolver.NTIME

                % Convenience variables (handles)
                liq         = liqArr(tIdx);
                vap         = vapArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = twfSolver.fluid(tIdx);

                % Inputset, fluid
                liq.inputSet = twfSolver.inputSet;
                liq.fluid    = fluid;

                % Axial Steps
                vap.DZ = twfSolver.DZ;

                liq.NZ = twfSolver.NZ;
                liq.DZ = twfSolver.DZ;
                liq.Z  = twfSolver.Z;

                % Time step
                liq.NTIME = twfSolver.NTIME;
                liq.DT    = twfSolver.DT;
                liq.TIME  = twfSolver.TIME(tIdx);
                liq.TIDX  = tIdx;

                % Copy properties to vapor
                for p = props
                    vap.(p{:}) = liq.(p{:});
                end

                % Initialize mixture
                liq.mix = Mixture(mix,liq,vap);
                vap.mix = liq.mix;

                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                liq.W = mix.liquid.W;                                      % [kg/s] Mixture model liquid mass flow rate
                vap.W = mix.vapor.W;                                       % [kg/s] Mixture model vapor mass flow rate

                % Initialize velocity [m/s]
                liq.U = mix.liquid.U;                                      % [m/s] Mixture model liquid velocity
                vap.U = mix.vapor.U;                                       % [m/s] Mixture model vapor velocity

                % Initialize enthalpy [J/kg]
                liq.H = min(mix.H,fluid.HF);                               % [J/kg] Mixture model enthalpy, up to liquid saturation
                vap.H = max(mix.H,fluid.HG);                               % [J/kg] Mixture model enthalpy, down to vapor saturation

                % ITR
                liq.ITR = ITRl;
                vap.ITR = ITRv;

            end

            % Store transient mixture array
            twfSolver.liquid = liqArr;
            twfSolver.vapor  = vapArr;

            % Create steady state mixture array
            twfSolver.liquidInit = copy( ...
                repmat(liqArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.vaporInit  = copy( ...
                repmat(vapArr(1),1,twfSolver.inputSet.options.SSMAXITER));

            % Update liquidInit and vaporInit times and timesteps
            initTIMEDT = twfSolver.inputSet.options.SSTSTEP;
            initNTIME  = length(twfSolver.liquidInit);
            initTIME   = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX   = 1:length(twfSolver.liquidInit);

            for i = 1:length(twfSolver.liquidInit)
                twfSolver.liquidInit(i).TIME  = initTIME(i);
                twfSolver.liquidInit(i).DT    = initTIMEDT;
                twfSolver.liquidInit(i).NTIME = initNTIME;
                twfSolver.liquidInit(i).TIDX  = initTIDX(i);

                twfSolver.vaporInit(i).TIME   = initTIME(i);
                twfSolver.vaporInit(i).DT     = initTIMEDT;
                twfSolver.vaporInit(i).NTIME  = initNTIME;
                twfSolver.vaporInit(i).TIDX   = initTIDX(i);
            end

            % set STATE to UNSOLVED
            twfSolver.STATE = SolverState.UNSOLVED;

        end

        function plotter = plotz(twfSolver, tIdx, opts)
            %PLOTZ Plots spatial (axial) distributions of two-fluid parameters.
            %
            % Generates axial plots of selected two-fluid parameters at specified
            % time indices. The function supports multiple display modes, wall
            % selections, and optional animation over time.
            %
            % Inputs:
            %
            % - twfSolver         — :class:`Solvers.TwoFluid.TwoFluidSolver` object containing simulation data
            % - tIdx              — Time index or indices (vector of positive integers)
            % - opts.display      — Parameters to display (e.g., 'HFLUX', 'W', 'U', etc.)
            % - opts.solveMode    — Solve mode: 'REAL' or 'NULL'
            % - opts.wall         — Wall index(es) to plot
            % - opts.zIdx         — Axial indices to include in the plot
            % - opts.obstructions — Logical flag to display obstruction locations
            % - opts.unitTemp     — Temperature unit: 'K' or 'C'
            % - opts.arrangement  — Plot arrangement: 'flow', 'vertical', or 'horizontal'
            % - opts.resize       — Resize factor for plot scaling
            %
            % Notes:
            %
            % - If multiple time indices are provided, the function creates an animated plot.
            % - At least two axial indices must be specified to enable spatial plotting.
            % - Temperature unit conversion is applied if 'C' is selected.
            % - Obstruction locations are plotted if opts.obstructions is true.
            % - Each wall is plotted in a separate tile with appropriate legends and axis scaling.

            arguments
                twfSolver
                tIdx           (:,1) double {mustBeInteger,mustBePositive}                                                     = []
                opts.display   {matlab.system.mustBeMember(opts.display,{'HFLUX','W','U','H','VR','T','INTAREA','REGIME','PWE','PME','PEE','ALL'})} = {'HFLUX','W','U','H','VR'}
                opts.solveMode {mustBeMember(opts.solveMode,{'REAL','NULL'})}                                                  = 'REAL'
                opts.wall      (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                                        = 1:twfSolver.inputSet.geometry.NWALL
                opts.zIdx      (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                                        = 1:twfSolver.NZ
                opts.obstructions (1,1) logical                                                                                = false
                opts.unitTemp  {mustBeMember(opts.unitTemp,{'K','C'})}                                                         = 'K'
                opts.arrangement {mustBeMember(opts.arrangement,{'flow','vertical','horizontal'})}                             = 'flow'
                opts.resize    (1,1) double {mustBeNonnegative}                                                                = 0
            end

            if length(opts.zIdx) < 2
                twfSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end

            z     = twfSolver.Z(opts.zIdx);
            bc    = twfSolver.boundaryConditions;
            model = twfSolver.inputSet.model;

            switch opts.solveMode
                case 'REAL'
                    if isempty(tIdx), tIdx = 1:twfSolver.NTIME; end
                    mixs = twfSolver.mixSolver.mixture(tIdx);
                    liqs = twfSolver.liquid(tIdx);
                    vaps = twfSolver.vapor(tIdx);
                    fld     = twfSolver.fluid;
                    bcHFLUX = arrayfun(@(idx) bc.HFLUX(opts.zIdx,:,liqs(idx).TIDX),1:length(tIdx),'uni',0);
                    solveMode = '';
                case 'NULL'
                    if isempty(tIdx), tIdx = 1:length(twfSolver.liquidInit); end
                    mixs = repmat(twfSolver.mixSolver.mixtureInit(end),1,length(tIdx));
                    liqs = twfSolver.liquidInit(tIdx);
                    vaps = twfSolver.vaporInit(tIdx);
                    fld     = repmat(twfSolver.fluid(1),1,length(tIdx));
                    bcHFLUX = arrayfun(@(n) bc.HFLUX(opts.zIdx,:,1),1:length(tIdx),'uni',0);
                    solveMode = '- Null transient';
            end

            % Temperature unit offset between C and K
            dTemp = 0; if strcmp(opts.unitTemp,'C'), dTemp = -273.15; end

            % Set up plotter
            if isscalar(tIdx)
                plotter = Solvers.SolverPlotter( ...
                    sprintf('Axial distributions of two-fluid parameters at %0.3f [s] %s', liqs(1).TIME, solveMode), ...
                    opts.wall, "arrangement", opts.arrangement);
            else
                plotter = Solvers.SolverPlotter( ...
                    sprintf('Axial distributions of two-fluid parameters at %s [s] %s', '%0.3f', solveMode), ...
                    opts.wall, ...
                    "arrangement", opts.arrangement, ...
                    "isAnimation", true, ...
                    "animationSeries", [liqs.TIME]);
            end
            plotter.setXs(z);

            function tf = displayVariable(memberList)
                tf = any(ismember(memberList, upper(opts.display)));
            end

            % Loop through each tIdx
            for idx = 1:length(tIdx)

                liq = liqs(idx);
                vap = vaps(idx);
                mix = mixs(idx);

                klocZ = mix.KLOCZ(opts.zIdx);                              % [m] Elevations of obstructions

                % Wall heat flux
                if displayVariable({'HFLUX','ALL'})
                    plotter.addTile( ...
                        'tileTitle',         'Wall heat flux', ...
                        'xlabel'   ,     'Axial position [m]', ...
                        'ylabel'   , 'Wall heat flux [W/m^2]');
                    plotter.plot(  bcHFLUX{idx}                 ,'bc'         ,'DisplayName','Boundary Condition');
                    plotter.plot(mix.HFLUX(opts.zIdx,:)         ,'Mixture'                                       );
                    plotter.plot(liq.HFLUX(opts.zIdx)           ,'Liquid'                                        );
                    plotter.plot(vap.HFLUX(opts.zIdx)           ,'Vapor'                                         );
                    plotter.plot(vap.HFLUXWALEVAP(liq,opts.zIdx),'Evaporation','DisplayName','Wall evaporation'  );
                    if ~strcmp(model.CBT,'NONE')
                        plotter.plot(mix.CHF(opts.zIdx)         ,'CHF'                                           );
                    end
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Mass flow rates
                if displayVariable({'W','ALL'})
                    plotter.addTile( ...
                        'tileTitle', 'Phase mass flow rates', ...
                        'xlabel',       'Axial position [m]', ...
                        'ylabel',    'Mass flow rate [kg/s]');
                    plotter.plot(mix.W(opts.zIdx) ,'Mixture');
                    plotter.plot(liq.W(opts.zIdx) ,'Liquid' );
                    plotter.plot(vap.W(opts.zIdx) ,'Vapor'  );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Phase velocities
                if displayVariable({'U','ALL'})
                    plotter.addTile( ...
                        'tileTitle',   'Phase velocities', ...
                        'xlabel'   , 'Axial position [m]', ...
                        'ylabel'   ,     'Velocity [m/s]');
                    plotter.plot(mix.U(opts.zIdx) ,'Mixture');
                    plotter.plot(liq.U(opts.zIdx) ,'Liquid' );
                    plotter.plot(vap.U(opts.zIdx) ,'Vapor'  );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Phase enthalpies
                if displayVariable({'H','ALL'})
                    plotter.addTile( ...
                        'tileTitle',   'Phase enthalpies', ...
                        'xlabel'   , 'Axial position [m]', ...
                        'ylabel'   ,    'Enthalpy [J/kg]');

                    plotter.plot(mix.H(opts.zIdx) ,'Mixture');
                    plotter.plot(liq.H(opts.zIdx) ,'Liquid' );
                    plotter.plot(vap.H(opts.zIdx) ,'Vapor'  );
                    plotter.plot(repmat(fld(idx).HF,twfSolver.NZ,1),'SatLiq','DisplayName','Sat liquid');
                    plotter.plot(repmat(fld(idx).HG,twfSolver.NZ,1),'SatVap','DisplayName','Sat vapor' );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Vapor ratios (void fraction and qualities)
                if displayVariable({'VR','ALL'})
                    plotter.addTile( ...
                        'tileTitle', 'Void fractions and qualities', ...
                        'xlabel'   ,           'Axial position [m]', ...
                        'ylabel'   ,  'Quality / Void fraction [-]');
                    plotter.plot(mix.XEQ(opts.zIdx)   ,'Equil'       ,'DisplayName','Equilibrium quality')
                    plotter.plot(vap.X(opts.zIdx)     ,'Vapor'       ,'DisplayName','Vapor mass quality' )
                    plotter.plot(vap.VF(liq,opts.zIdx),'VoidFraction','DisplayName','Void fraction'      )
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Phase temperatures
                if displayVariable({'T','ALL'})
                    plotter.addTile( ...
                        'tileTitle',              'Phase temperatures', ...
                        'xlabel'   ,              'Axial position [m]', ...
                        'ylabel'   , ['Temperature [' opts.unitTemp ']']);

                    plotter.plot(liq.T(opts.zIdx)+dTemp,'Liquid');
                    plotter.plot(vap.T(opts.zIdx)+dTemp, 'Vapor');
                    plotter.plot(repmat(fld(idx).TSAT,twfSolver.NZ,1)+dTemp,'Saturation');
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Vapor and liquid mass exchanges
                if displayVariable({'PWE','ALL'})
                    ah_vap = plotter.addTile( ...
                        'tileTitle', 'Vapor mass exchanges', ...
                        'xlabel',      'Axial position [m]', ...
                        'ylabel',  'Mass exchange [kg/s/m]');
                    plotter.plot(vap.MWALEVAP(liq,opts.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                    plotter.plot(vap.MINTEVAP(liq,opts.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation' );
                    plotter.plot(vap.MINTCOND(liq,opts.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                    plotter.plot(vap.MTOT(liq,opts.zIdx)    ,'Total'                                                   );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                    plotter.ylim([-ymax ymax]);

                    ah_liq = plotter.addTile( ...
                        'tileTitle', 'Liquid mass exchanges', ...
                        'xlabel',       'Axial position [m]', ...
                        'ylabel',   'Mass exchange [kg/s/m]');
                    plotter.plot(liq.MWALEVAP(vap,opts.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                    plotter.plot(liq.MINTEVAP(vap,opts.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation' );
                    plotter.plot(liq.MINTCOND(vap,opts.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                    plotter.plot(liq.MTOT(vap,opts.zIdx)    ,'Total'                                                   );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                    plotter.ylim([-ymax ymax]);

                    % Link exchange axes
                    % TODO: this can be a plotter method
                    for wallIdx = 1:length(ah_liq)
                        linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                    end
                    if opts.obstructions
                        plotter.plotK(klocZ,ah_vap);
                        plotter.plotK(klocZ,ah_liq);
                    end
                end

                % Vapor and liquid momentum Exchanges
                if displayVariable({'PME','ALL'})
                    ah_vap = plotter.addTile( ...
                        'tileTitle', 'Vapor momentum exchanges', ...
                        'xlabel',          'Axial position [m]', ...
                        'ylabel',          'Shear stress [N/m]');
                    plotter.plot(vap.FWALL(liq,opts.zIdx)   ,'Wall'           ,'DisplayName','Wall shear'             );
                    plotter.plot(vap.FDRAG(liq,opts.zIdx)   ,'Interfacial'    ,'DisplayName','Interfacial shear'      );
                    plotter.plot(vap.FBUOY(liq,opts.zIdx)   ,'Buoyancy'                                               );
                    plotter.plot(vap.FGRAV(liq,opts.zIdx)   ,'Gravity'                                                );
                    plotter.plot(vap.FWALEVAP(liq,opts.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'       );
                    plotter.plot(vap.FINTEVAP(liq,opts.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation');
                    plotter.plot(vap.FTOT(liq,opts.zIdx)    ,'Total'                                                  );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                    plotter.ylim([-ymax ymax]);

                    ah_liq = plotter.addTile( ...
                        'tileTitle', 'Liquid momentum exchanges', ...
                        'xlabel',           'Axial position [m]', ...
                        'ylabel',           'Shear stress [N/m]');
                    plotter.plot(liq.FWALL(vap,opts.zIdx)   ,'Wall'           ,'DisplayName','Wall shear'              );
                    plotter.plot(liq.FDRAG(vap,opts.zIdx)   ,'Interfacial'    ,'DisplayName','Interfacial shear'       );
                    plotter.plot(liq.FBUOY(vap,opts.zIdx)   ,'Buoyancy'                                                );
                    plotter.plot(liq.FGRAV(vap,opts.zIdx)   ,'Gravity'                                                 );
                    plotter.plot(liq.FINTCOND(vap,opts.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                    plotter.plot(liq.FTOT(vap,opts.zIdx)    ,'Total'                                                   );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                    plotter.ylim([-ymax ymax]);

                    % Link exchange axes
                    % TODO: this can be a plotter method
                    for wallIdx = 1:length(ah_liq)
                        linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                    end
                    if opts.obstructions
                        plotter.plotK(klocZ,ah_vap);
                        plotter.plotK(klocZ,ah_liq);
                    end
                end

                % Vapor and liquid energy Exchanges
                if displayVariable({'PEE','ALL'})
                    ah_vap = plotter.addTile( ...
                        'tileTitle', 'Vapor energy exchanges', ...
                        'xlabel',        'Axial position [m]', ...
                        'ylabel',     'Energy transfer [W/m]');
                    plotter.plot(vap.HWALHEAT(opts.zIdx)    ,'Wall'                                                    );
                    plotter.plot(vap.HWALEVAP(liq,opts.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                    plotter.plot(vap.HINTEVAP(liq,opts.zIdx),'InterfacialCond','DisplayName','Interfacial evaporation' );
                    plotter.plot(vap.HINTCOND(liq,opts.zIdx),'InterfacialEvap','DisplayName','Interfacial condensation');
                    plotter.plot(vap.HTOT(liq,opts.zIdx)    ,'Total'                                                   );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                    plotter.ylim([-ymax ymax]);

                    ah_liq = plotter.addTile( ...
                        'tileTitle', 'Liquid energy exchanges', ...
                        'xlabel',         'Axial position [m]', ...
                        'ylabel',      'Energy transfer [W/m]');
                    plotter.plot(liq.HWALHEAT(opts.zIdx)    ,'Wall'                                                    );
                    plotter.plot(liq.HWALEVAP(vap,opts.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                    plotter.plot(liq.HINTEVAP(vap,opts.zIdx),'InterfacialCond','DisplayName','Interfacial evaporation' );
                    plotter.plot(liq.HINTCOND(vap,opts.zIdx),'InterfacialEvap','DisplayName','Interfacial condensation');
                    plotter.plot(liq.HTOT(vap,opts.zIdx)    ,'Total'                                                   );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                    plotter.ylim([-ymax ymax]);

                    % Link exchange axes
                    % TODO: this can be a plotter method
                    for wallIdx = 1:length(ah_liq)
                        linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                    end
                    if opts.obstructions
                        plotter.plotK(klocZ,ah_vap);
                        plotter.plotK(klocZ,ah_liq);
                    end
                end

                % Volumetric interfacial area
                if displayVariable({'INTAREA','ALL'})
                    plotter.addTile( ...
                        'tileTitle', 'Volumetric interfacial area', ...
                        'xlabel'   ,          'Axial position [m]', ...
                        'ylabel'   ,    'Interfacial area [m^-^1]');
                    plotter.plot(liq.INTAREA(vap,opts.zIdx),'Interfacial')
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Two-phase flow regimes
                if displayVariable({'REGIME','ALL'})
                    plotter.addTile( ...
                        'tileTitle', 'Two-phase flow regimes', ...
                        'xlabel'   ,     'Axial position [m]');
                    plotter.plot(liq.FLOWREGIME(opts.zIdx),'Interfacial')
                    labels = strrep(cellstr(unique(liq.FLOWREGIME)),'_',' ');
                    plotter.ylabels(labels);
                    plotter.ylim([0 length(labels)+1]);
                    plotter.xlim([min(z) max(z)]);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end
            end

            if opts.resize > 0
                plotter.resizeFigure(opts.resize);
            end
        end

        function plotter = plott(twfSolver, zIdx, opt)
            %PLOTT Plots temporal distributions of two-fluid parameters at a given axial location.
            %
            % Generates time-series plots of selected two-fluid parameters at
            % a specified axial index. The method supports multiple display
            % modes, wall selections, and plot arrangements.
            %
            % Inputs:
            %
            % - twfSolver         — :class:`Solvers.TwoFluid.TwoFluidSolver` object containing simulation data
            % - zIdx              — Axial index (scalar, positive integer)
            % - opt.display       — Parameters to display (e.g., 'HFLUX', 'W', 'U', etc.)
            % - opt.solveMode     — Solve mode: 'REAL' or 'NULL'
            % - opt.wall          — Wall index(es) to plot
            % - opt.tIdx          — Time indices to include in the plot
            % - opt.reverseTime   — Logical flag to reverse time axis
            % - opt.unitTemp      — Temperature unit: 'K' or 'C'
            % - opt.arrangement   — Plot arrangement: 'flow', 'vertical', or 'horizontal'
            % - opt.resize        — Resize factor for plot scaling
            %
            % Notes:
            %
            % - If opt.display is set to 'ALL', all supported parameters are plotted.
            % - The function validates that at least two time indices are provided.
            % - Temperature unit conversion is applied if 'C' is selected.
            % - Each wall is plotted in a separate tile with appropriate legends and axis scaling.

            arguments
                twfSolver
                zIdx            (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive}                                  = twfSolver.NZ
                opt.display     {mustBeMember(opt.display,{'HFLUX','W','U','H','VR','T','INTAREA','REGIME','PWE','PME','PEE','ALL'})} = {'HFLUX','W','U','H','VR'}
                opt.solveMode   {mustBeMember(opt.solveMode,{'REAL','NULL'})}                                                    = 'REAL'
                opt.wall        (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                                         = 1:twfSolver.inputSet.geometry.NWALL
                opt.tIdx        (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                                         = []
                opt.reverseTime (1,1) logical                                                                                    = false
                opt.unitTemp    {mustBeMember(opt.unitTemp,{'K','C'})}                                                           = 'K'
                opt.arrangement {mustBeMember(opt.arrangement,{'flow','vertical','horizontal'})}                                 = 'flow'
                opt.resize      (1,1) double {mustBeNonnegative}                                                                 = 0
            end

            if isempty(opt.wall), opt.wall = 1:twfSolver.inputSet.geometry.NWALL; end

            model = twfSolver.inputSet.model;

            switch opt.solveMode
                case 'REAL'
                    if isempty(opt.tIdx), opt.tIdx = 1:twfSolver.NTIME; end
                    mix = twfSolver.mixSolver.mixture(opt.tIdx);
                    fld = twfSolver.mixSolver.fluid(opt.tIdx);
                    liq = twfSolver.liquid(opt.tIdx);
                    vap = twfSolver.vapor(opt.tIdx);
                    bcHFLUX = permute(twfSolver.boundaryConditions.HFLUX(zIdx,:,:),[3 2 1]);
                    solveMode = '';
                case 'NULL'
                    if isempty(opt.tIdx), opt.tIdx = 1:length(twfSolver.liquidInit);  end
                    mix = repmat(twfSolver.mixSolver.mixtureInit(end),1,length(opt.tIdx));
                    fld = repmat(twfSolver.mixSolver.fluid(1),1,length(opt.tIdx));
                    liq = twfSolver.liquidInit(opt.tIdx);
                    vap = twfSolver.vaporInit(opt.tIdx);
                    bcHFLUX = repmat(twfSolver.boundaryConditions.HFLUX(zIdx,:,1),length(opt.tIdx),1);
                    solveMode = '- Null transient';
            end

            time = [liq.TIME];
            if length(time) < 2
                twfSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            if opt.reverseTime
                time = time -time(end);
            end

            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end

            z = twfSolver.Z;
            plotter = Solvers.SolverPlotter( ...
                sprintf('Time distributions of two-fluid parameters at %0.3f [m] %s', z(zIdx), solveMode), ...
                opt.wall,'arrangement',opt.arrangement);
            plotter.setXs(time);

            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Wall heat flux', ...
                    'xlabel'   ,               'Time [s]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plot(             bcHFLUX                          ,'bc'         ,'DisplayName','Boundary Condition');
                plotter.plot(liq.transient('mix.HFLUX'   ,    'zIdx',zIdx)','Mixture'                                       );
                plotter.plot(liq.transient('HFLUX'       ,    'zIdx',zIdx)','Liquid'                                        );
                plotter.plot(vap.transient('HFLUX'       ,    'zIdx',zIdx)','Vapor'                                         );
                plotter.plot(vap.transient('HFLUXWALEVAP',liq,'zIdx',zIdx)','Evaporation','DisplayName','Wall evaporation'  );
                if ~strcmp(model.CBT,'NONE')
                    plotter.plot(liq.transient('mix.CHF'     ,    'zIdx',zIdx)','CHF'                                           );
                end
                plotter.legend('show', 'Location', 'best');
            end

            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Phase mass flow rates', ...
                    'xlabel',                 'Time [s]', ...
                    'ylabel',    'Mass flow rate [kg/s]');
                plotter.plot(liq.transient('mix.W','zIdx',zIdx)','Mixture');
                plotter.plot(liq.transient('W'    ,'zIdx',zIdx)','Liquid' );
                plotter.plot(vap.transient('W'    ,'zIdx',zIdx)','Vapor'  );
                plotter.legend('show', 'Location', 'best');
            end

            % Phase velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Phase velocities', ...
                    'xlabel'   ,           'Time [s]', ...
                    'ylabel'   ,     'Velocity [m/s]');
                plotter.plot(liq.transient('mix.U','zIdx',zIdx)','Mixture');
                plotter.plot(liq.transient('U'    ,'zIdx',zIdx)','Liquid' );
                plotter.plot(vap.transient('U'    ,'zIdx',zIdx)','Vapor'  );
                plotter.legend('show', 'Location', 'best');
            end

            % Phase enthalpies
            if any(ismember({'H','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Phase enthalpies', ...
                    'xlabel'   ,           'Time [s]', ...
                    'ylabel'   ,    'Enthalpy [J/kg]');
                plotter.plot(liq.transient('mix.H','zIdx',zIdx)','Mixture'                           );
                plotter.plot(liq.transient('H'    ,'zIdx',zIdx)','Liquid'                            );
                plotter.plot(vap.transient('H'    ,'zIdx',zIdx)','Vapor'                             );
                plotter.plot(fld.transient('HF')'               ,'SatLiq' ,'DisplayName','Sat liquid');
                plotter.plot(fld.transient('HG')'               ,'SatVap' ,'DisplayName','Sat vapor' );
                plotter.legend('show', 'Location', 'best');
            end

            % Vapor ratios (void fraction and qualities)
            if any(ismember({'VR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Void fractions and qualities', ...
                    'xlabel'   ,                     'Time [s]', ...
                    'ylabel'   ,  'Quality / Void fraction [-]');
                plotter.plot(liq.transient('mix.XEQ',    'zIdx',zIdx)','Equil'       ,'DisplayName','Equilibrium quality');
                plotter.plot(vap.transient('X'      ,    'zIdx',zIdx)','Vapor'       ,'DisplayName','Vapor mass quality' );
                plotter.plot(vap.transient('VF'     ,liq,'zIdx',zIdx)','VoidFraction','DisplayName','Void fraction'      );
                plotter.legend('show', 'Location', 'best');
            end

            % Phase temperatures
            if any(ismember({'T','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',              'Phase temperatures', ...
                    'xlabel'   ,                        'Time [s]', ...
                    'ylabel'   , ['Temperature [' opt.unitTemp ']']);
                plotter.plot(liq.transient('T','zIdx',zIdx)'+dTemp,'Liquid'    );
                plotter.plot(vap.transient('T','zIdx',zIdx)'+dTemp,'Vapor'     );
                plotter.plot(fld.transient('TSAT')'         +dTemp,'Saturation');
                plotter.legend('show', 'Location', 'best');
            end

            % Vapor and liquid mass exchanges
            if any(ismember({'PWE','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor mass exchanges', ...
                    'xlabel',                'Time [s]', ...
                    'ylabel',  'Mass exchange [kg/s/m]');
                plotter.plot(vap.transient('MWALEVAP',liq,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plot(vap.transient('MINTEVAP',liq,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plot(vap.transient('MINTCOND',liq,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plot(vap.transient('MTOT'    ,liq,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);

                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid mass exchanges', ...
                    'xlabel',                 'Time [s]', ...
                    'ylabel',   'Mass exchange [kg/s/m]');
                plotter.plot(liq.transient('MWALEVAP',vap,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plot(liq.transient('MINTEVAP',vap,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plot(liq.transient('MINTCOND',vap,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plot(liq.transient('MTOT'    ,vap,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);

                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end

            % Vapor and liquid momentum Exchanges
            if any(ismember({'PME','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor momentum exchanges', ...
                    'xlabel',                    'Time [s]', ...
                    'ylabel',          'Shear stress [N/m]');
                plotter.plot(vap.transient('FWALL'   ,liq,'zIdx',zIdx)','Wall'           ,'DisplayName','Wall shear'             );
                plotter.plot(vap.transient('FDRAG'   ,liq,'zIdx',zIdx)','Interfacial'    ,'DisplayName','Interfacial shear'      );
                plotter.plot(vap.transient('FBUOY'   ,liq,'zIdx',zIdx)','Buoyancy'                                               );
                plotter.plot(vap.transient('FGRAV'   ,liq,'zIdx',zIdx)','Gravity'                                                );
                plotter.plot(vap.transient('FWALEVAP',liq,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'       );
                plotter.plot(vap.transient('FINTEVAP',liq,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation');
                plotter.plot(vap.transient('FTOT'    ,liq,'zIdx',zIdx)','Total'                                                  );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);

                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid momentum exchanges', ...
                    'xlabel',                     'Time [s]', ...
                    'ylabel',           'Shear stress [N/m]');
                plotter.plot(liq.transient('FWALL'   ,vap,'zIdx',zIdx)','Wall'           ,'DisplayName','Wall shear'              );
                plotter.plot(liq.transient('FDRAG'   ,vap,'zIdx',zIdx)','Interfacial'    ,'DisplayName','Interfacial shear'       );
                plotter.plot(liq.transient('FBUOY'   ,vap,'zIdx',zIdx)','Buoyancy'                                                );
                plotter.plot(liq.transient('FGRAV'   ,vap,'zIdx',zIdx)','Gravity'                                                 );
                plotter.plot(liq.transient('FINTCOND',vap,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plot(liq.transient('FTOT'    ,vap,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);

                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end

            % Vapor and liquid energy Exchanges
            if any(ismember({'PEE','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor energy exchanges', ...
                    'xlabel',                  'Time [s]', ...
                    'ylabel',     'Energy transfer [W/m]');
                plotter.plot(vap.transient('HWALHEAT',    'zIdx',zIdx)','Wall'                                                    );
                plotter.plot(vap.transient('HWALEVAP',liq,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plot(vap.transient('HINTEVAP',liq,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial evaporation' );
                plotter.plot(vap.transient('HINTCOND',liq,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial condensation');
                plotter.plot(vap.transient('HTOT'    ,liq,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);

                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid energy exchanges', ...
                    'xlabel',                   'Time [s]', ...
                    'ylabel',      'Energy transfer [W/m]');
                plotter.plot(liq.transient('HWALHEAT',    'zIdx',zIdx)','Wall'                                                    );
                plotter.plot(liq.transient('HWALEVAP',vap,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plot(liq.transient('HINTEVAP',vap,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial evaporation' );
                plotter.plot(liq.transient('HINTCOND',vap,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial condensation');
                plotter.plot(liq.transient('HTOT'    ,vap,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);

                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end

            % Volumetric interfacial area
            if any(ismember({'INTAREA','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Volumetric interfacial area', ...
                    'xlabel'   ,                    'Time [s]', ...
                    'ylabel'   ,    'Interfacial area [m^-^1]');
                plotter.plot(liq.transient('INTAREA',vap,'zIdx',zIdx)','Interfacial');
            end

            % Two-phase flow regimes
            if any(ismember({'REGIME','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Two-phase flow regimes', ...
                    'xlabel'   ,     'Axial position [m]');
                plotter.plot(liq.transient('FLOWID','zIdx',zIdx)','Interfacial')
                labels = arrayfun(@(x) unique(x.FLOWREGIME),liq,'uni',0);
                labels = strrep(cellstr(unique([labels{:}])),'_',' ');
                plotter.ylabels(labels);
                plotter.ylim([0 length(labels)+1]);
            end

            if opt.resize > 0
                plotter.resizeFigure(opt.resize);
            end
        end

        function plotzt(twfSolver, opt)
            %PLOTZT Plots 2D time/elevation distributions of two-fluid parameters.
            %
            % Generates surface plots of selected two-fluid related parameters
            % over time and axial (elevation) positions. It supports plotting
            % for liquid and vapor fields, and can handle both real
            % and null (initial) transient data.
            %
            % Inputs:
            %
            % - twfSolver         — :class:`Solvers.TwoFluid.TwoFluidSolver` object containing simulation data
            % - opt.display       — Parameter(s) to display (e.g., 'HFLUX', 'U', etc.)
            % - opt.label         — Corresponding labels for display parameters
            % - opt.unit          — Units for each parameter
            % - opt.field         — Field to plot: 'liquid' or 'vapor'
            % - opt.solveMode     — Solve mode: 'REAL' or 'NULL'
            % - opt.wall          — Wall index(es) to plot
            % - opt.zIdx          — Axial indices (must include at least 2)
            % - opt.tIdx          — Time indices (must include at least 2)
            % - opt.reverseTime   — Logical flag to reverse time axis
            % - opt.shading       — Surface shading style: 'faceted', 'flat', or 'interp'
            % - opt.view          — View angle for 3D plot [azimuth elevation]
            %
            % Notes:
            %
            % - If 'ALL' is passed to opt.display, all supported parameters are plotted.
            % - The function validates that at least two axial and time indices are provided to enable meaningful 2D plotting.
            % - Each wall is plotted in a separate figure window with appropriate titles and subplot grouping.

            arguments
                twfSolver
                opt.display      {mustBeA(opt.display,{'cell','char'})}                   = {'HFLUX','W','U','H','X','VF'}
                opt.label        {mustBeA(opt.label,{'cell','char'})}                     = {}
                opt.unit         {mustBeA(opt.unit,{'cell','char'})}                      = {}
                opt.field        {mustBeMember(opt.field,{'liquid','vapor'})}             = {'liquid','vapor'}
                opt.solveMode    {mustBeMember(opt.solveMode,{'REAL','NULL'})}            = 'REAL'
                opt.wall         (1,:) double {mustBeVector,mustBeInteger,mustBePositive} = 1:twfSolver.inputSet.geometry.NWALL
                opt.zIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:twfSolver.NZ
                opt.tIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = []
                opt.reverseTime  (1,1) logical                                            = false
                opt.shading      {mustBeMember(opt.shading,{'faceted','flat','interp'})}  = 'interp'
                opt.view         (1,2) double                                             = [0 90]
            end

            if ~iscell(opt.display), opt.display = {opt.display}; end
            if ~iscell(opt.label)  , opt.label   = {opt.label}  ; end
            if ~iscell(opt.unit)   , opt.unit    = {opt.unit}   ; end

            display = {         'HFLUX',             'W',       'U',       'H',           'X',                 'VF',          'T',                    'INTAREA'};
            label   = {'wall heat flux','mass flow rate','velocity','enthalpy','mass quality','volumetric fraction','temperature','volumetric interfacial area'};
            unit    = {         'W/m^2',          'kg/s',     'm/s',    'J/kg',           '-',                  '-',          'K',                      'm^-^1'};
            if strcmp('ALL',opt.display)
                opt.display = display;
            end
            if isempty(opt.label)
                opt.label   = label(ismember(display,opt.display));
            end
            if isempty(opt.unit)
                opt.unit    = unit(ismember(display,opt.display));
            end
            if isempty(opt.label) || isempty(opt.unit)
                twfSolver.log('Error: Labels and/or units must be specified for the selected parameters.\n');
                return
            end

            switch opt.solveMode
                case 'REAL'
                    if isempty(opt.tIdx), opt.tIdx = 1:twfSolver.NTIME; end
                    mix = twfSolver.mixSolver.mixture(opt.tIdx);
                    liq = twfSolver.liquid(opt.tIdx);
                    vap = twfSolver.vapor(opt.tIdx);
                    solveMode = '';
                case 'NULL'
                    if isempty(opt.tIdx), opt.tIdx = 1:length(twfSolver.liquidInit);  end
                    mix = repmat(twfSolver.mixSolver.mixtureInit(end),1,length(opt.tIdx));
                    liq = twfSolver.liquidInit(opt.tIdx);
                    vap = twfSolver.vaporInit(opt.tIdx);
                    solveMode = '- Null transient';
                    time = [liq(opt.tIdx).TIME];
            end
            if isempty(opt.wall)
                opt.wall = 1:twfSolver.inputSet.geometry.NWALL;
            end
            if length(opt.zIdx) < 2
                twfSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            if length(opt.tIdx) < 2
                twfSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end

            for k = opt.wall
                if ismember('liquid',opt.field)
                    name = ['Time/axial distributions of two-fluid (liquid) parameters ' solveMode ' - Wall ' num2str(k)];
                    fh_liq = figure('name',name);
                    for i = 1:length(opt.display)
                        ax_liq(i) = liq.plotzt(opt.display{i},['Liquid ' opt.label{i}],opt.unit{i},k,opt,vap);
                    end
                    sgtitle(fh_liq,name,'FontSize',18);
                end
                if ismember('vapor',opt.field)
                    name = ['Time/axial distributions of two-fluid (vapor) parameters ' solveMode ' - Wall ' num2str(k)];
                    fh_vap = figure('name',name);
                    for i = 1:length(opt.display)
                        ax_vap(i) = vap.plotzt(opt.display{i},['Vapor '  opt.label{i}],opt.unit{i},k,opt,liq);
                    end
                    sgtitle(fh_vap,name,'FontSize',18);
                end
            end
        end

    end

end
