classdef ThreeFieldSolver < Solvers.AbstractSolver
    %THREEFIELDSOLVER Solver for initializing, solving, and visualizing three-field flow.
    %
    % The ThreeFieldSolver class handles the setup, execution, and visualization
    % of thermal-hydraulic simulations using a two-phase three-field approach.
    %
    % Responsibilities:
    %
    % - Initializes solver parameters from an :class:`Inputs.InputSet` object
    % - Constructs :class:`Solvers.ThreeField.Film` and :class:`Solvers.ThreeField.Drop` objects for transient and steady-state analysis
    % - Provides plotting utilities for spatial and temporal distributions
    %
    % Key Components:
    %
    % - Liquid field construction (film/drop)
    % - Field mass/momentum/energy transport modeling
    % - Pressure drop gradient obtained from mixture solver
    % - Vapor solution obtained from mixture solver
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

        filmInit                                                                       % Null transient film object
        dropInit                                                                       % Null transient drop object
        film                                                                           % Film object
        drop                                                                           % Drop object

    end

    properties (SetAccess = protected)

        mixSolver                                                                      % Mixture object :class:`Solvers.Mixture.Mixture`
        inputSet                                                                       % Input set object :class:`Inputs.InputSet`
        STATE                                                              = Solvers.SolverState.UNSOLVED

    end

    methods

        solve(tfSolver)                                                                % Solving algorithm

    end

    methods

        function tfSolver = ThreeFieldSolver(inputSet,mixSolver)
            %THREEFIELDSOLVER Constructor for the ThreeFieldSolver class.
            %
            % Creates a new instance of the ThreeFieldSolver class using the
            % provided :class:`Inputs.InputSet`. This constructor initializes
            % the solver by calling the abstract :class:`Solvers.AbstractSolver`
            % superclass constructor and then sets up all necessary solver
            % parameters and internal data structures via
            % :meth:`Solvers.ThreeField.ThreeFieldSolver.initializeSolver <Solvers.ThreeField.ThreeFieldSolver.ThreeFieldSolver.initializeSolver>`
            %
            % Input:
            %
            % - inputSet — An :class:`Inputs.InputSet` object containing model configuration, geometry, boundary conditions, and solver options.
            % - mixSolver — An optional solved :class:`Solvers.Mixture.MixtureSolver` object
            %
            % Notes:
            %
            % - This constructor assumes :class:`Inputs.InputSet` is fully validated.
            % - A solved mixture-model solution is required for initialization. If a solved mixture solver is supplied, its solution is reused. If unsolved, or if no mixture solver is supplied, one is created and solved automatically.
            % - Solver initialization includes liquid and vapor objects setup.
            % - Time/space discretization and boundary condition interpolation initialized by :class:`Solvers.Mixture.MixtureSolver` are used

            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            tfSolver = tfSolver@Solvers.AbstractSolver(inputSet);

            % Store mixSolver handle
            tfSolver.mixSolver = mixSolver;

            % Attempt to solve mixSolver if it is unsolved
            if tfSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
                tfSolver.mixSolver.solve();
            end

            % Initialize solver parameters
            tfSolver.initializeSolver();
        end

        function initializeSolver(tfSolver)
            %INITIALIZESOLVER Initializes solver parameters and constructs film/drop objects.
            %
            % Sets up the solver's internal state using the provided
            % :class:`Inputs.InputSet` and :class:`Solvers.ThreeField.ThreeFieldSolver`,
            % This includes initialization of data structures for transient and steady-state
            % simulations based on the mixture solver solutions.
            %
            % Operations performed:
            %
            % - Initializes film and drop arrays for each time step
            % - Initializes fluid property objects
            % - Sets up mixture object
            % - Assigns initial conditions for phase mass flow rates, velocities, enthalpies
            %
            % Notes:
            %
            % - The function assumes uniform axial discretization.
            % - Wall heat flux is computed from interpolated boundary conditions.

            import Inputs.*
            import Solvers.ThreeField.*
            import Solvers.*

            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                tfSolver.(p{:}) = tfSolver.mixSolver.(p{:});
            end

            % Local parameters
            mixArr = tfSolver.mixSolver.mixture;                           % Mixture solution
            model  = tfSolver.inputSet.model;                              % Models
            geom   = tfSolver.inputSet.geometry;                           % Geometry

            % Setup inner iteration value struct
            ITRFields = ["N","DWL","DU"];
            ITRf = tfSolver.CreateITR(tfSolver.NZ, ITRFields);
            ITRf.DWL = repmat(ITRf.DWL,1,geom.NWALL);
            ITRf.DU  = repmat(ITRf.DU,1,geom.NWALL);
            ITRFields = ["N","DU"];
            ITRd = tfSolver.CreateITR(tfSolver.NZ, ITRFields);

            % Create film and drop arrays (by timestep)
            flmArr(tfSolver.NTIME) = Film();
            drpArr(tfSolver.NTIME) = Drop();
            props = {'NZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid', 'mix'}; % film and drop properties

            for tIdx = 1:tfSolver.NTIME

                % Convenience variables (handles)
                flm         = flmArr(tIdx);
                drp         = drpArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = tfSolver.fluid(tIdx);

                % Inputset, fluid
                flm.inputSet = tfSolver.inputSet;
                flm.fluid    = fluid;
                flm.mix      = mix;

                % Axial Steps
                drp.DZ = tfSolver.DZ;

                flm.NZ = tfSolver.NZ;
                flm.DZ = tfSolver.DZ;
                flm.Z  = tfSolver.Z;

                % Time step
                flm.NTIME = tfSolver.NTIME;
                flm.DT    = tfSolver.DT;
                flm.TIME  = tfSolver.TIME(tIdx);
                flm.TIDX  = tIdx;

                % Copy properties to drop
                for p = props
                    drp.(p{:}) = flm.(p{:});
                end

                % Wall/film evaporation heat flux
                HFLUX = mix.HFLUX;                                         % [W/m^2] Wall heat flux
                avgHFLUX = sum(HFLUX.*geom.PERIM,2)./sum(geom.PERIM);      % [W/m^2] Average heat flux
                avgHFLUX = repmat(avgHFLUX,1,geom.NWALL);                  % [W/m^2] ... distributed to all walls
                evapFn = [0;max(0,diff(mix.X)./diff(mix.XEQ))];            % [-] Evaporation function
                evapFn(~isfinite(evapFn)) = 1;                             % [-] Fix potential division by 0
                flm.HFLUX = mix.AFDISTR(evapFn.*avgHFLUX,HFLUX);           % [W/m^2] Film evaporation heat flux

                % Film evaporation (thermal equilibrium assumption)
                flm.MEVAP = -flm.HFLUX./(fluid.HG-fluid.HF);               % [kg/m^2/s] Evaporation mass flux

                % Entrained ratio at onset of annular flow
                switch model.OAFENTRAINED
                    case InputEnums.OAFENTRAINED.RATIO
                        e0 = model.OAFDROPRATIO;
                    case InputEnums.OAFENTRAINED.EQUILIBRIUM
                        e0 = tfSolver.EQUIL(flm,drp,mix,mix.OAFIDX);
                end

                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note 1: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                % Note 2: other, maybe better, initialization states could be investigated
                drp.W = repmat(e0.*mix.OAFWL,tfSolver.NZ,1);               % [kg/s] Set drop mass flow to onset of annular flow conditions everywhere

                % Transient mass gradient in film field
                %flmArr(tIdx).W = (mix(tIdx).W-drpArr(tIdx).W).*geom.PERIM./sum(geom.PERIM);           % [kg/s] Distribute film at inlet uniformly on all walls
                %flmArr(tIdx).W = flmArr(tIdx).W+cumsum(flmArr(tIdx).MEVAP).*geom.PERIM.*tfSolver.DZ;  % [kg/s] Apply simple mass conservation

                % ... or transient mass gradient in drop field
                drp.W = drp.W+mix.W-mix.W(mix.OAFIDX);                                            % [kg/s]
                flm.W(1,1:geom.NWALL) = (mix.liquid.W(1)-drp.W(1)).*geom.PERIM./sum(geom.PERIM);  % [kg/s] Distribute film at inlet uniformly on all walls
                flm.W = flm.W(1,:)+cumsum(flm.MEVAP).*geom.PERIM.*tfSolver.DZ;                    % [kg/s] Apply simple mass conservation

                % Limit film flow rate minimum to 0
                flm.W = max(0,flm.W);
                drp.W = mix.liquid.W-sum(flm.W,2);                         % [kg/s] Recalculate consistent drop flow rate


                % Initialize field velocities [m/s]
                %drp.U = mix.liquid.U;                                     % [m/s] Drop velocity
                drp.U = drp.USLIP();                                        % [m/s] Drop velocity

                %flm.U = repmat(mix.liquid.U,1,geom.NWALL); % [m/s]
                flm.U = flm.UALGEBR();                                     % [m/s] Film velocity

                % Initialize field enthalpies [J/kg] by number of spatial nodes, NZ
                drp.H = repmat(fluid.HF,tfSolver.NZ,1);
                flm.H = repmat(fluid.HF,tfSolver.NZ,1);

                % ITR
                flm.ITR = ITRf;
                drp.ITR = ITRd;

            end

            % Store transient mixture array
            tfSolver.film = flmArr;
            tfSolver.drop = drpArr;

            % Create steady state mixture array
            tfSolver.filmInit = copy( ...
                repmat(flmArr(1),1,tfSolver.inputSet.options.SSMAXITER));
            tfSolver.dropInit = copy( ...
                repmat(drpArr(1),1,tfSolver.inputSet.options.SSMAXITER));

            % Update filmInit and dropInit times and timesteps
            initTIMEDT = tfSolver.inputSet.options.SSTSTEP;
            initNTIME = length(tfSolver.filmInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(tfSolver.filmInit);

            for i = 1:length(tfSolver.filmInit)

                tfSolver.filmInit(i).TIME = initTIME(i);
                tfSolver.filmInit(i).DT = initTIMEDT;
                tfSolver.filmInit(i).NTIME = initNTIME;
                tfSolver.filmInit(i).TIDX = initTIDX(i);

                tfSolver.filmInit(i).mix       = copy(tfSolver.mixSolver.mixtureInit(end));
                tfSolver.filmInit(i).mix.TIME  = initTIME(i);
                tfSolver.filmInit(i).mix.DT    = initTIMEDT;
                tfSolver.filmInit(i).mix.NTIME = initNTIME;
                tfSolver.filmInit(i).mix.TIDX  = initTIDX(i);

                tfSolver.dropInit(i).mix    = tfSolver.filmInit(i).mix;

                tfSolver.dropInit(i).TIME = initTIME(i);
                tfSolver.dropInit(i).DT = initTIMEDT;
                tfSolver.dropInit(i).NTIME = initNTIME;
                tfSolver.dropInit(i).TIDX = initTIDX(i);
            end

            % set STATE to UNSOLVED
            tfSolver.STATE = SolverState.UNSOLVED;
        end

        function e0 = EQUIL(tfSolver,flm,drp,mix,zIdx)
            %EQUIL Find entrained ratio at film/drop equilibrium state [-]
            %
            % Iteratively computes the entrained liquid ratio at the onset of annular
            % flow by balancing droplet deposition and film entrainment rates.
            %
            % Inputs:
            %
            % - tfSolver — :class:`Solvers.ThreeField.ThreeFieldSolver` object
            % - flm      — Film field object (:class:`Solvers.ThreeField.Film`)
            % - drp      — Droplet field object (:class:`Solvers.ThreeField.Drop`)
            % - mix      — Mixture object (:class:`Solvers.Mixture.Mixture`)
            % - zIdx     — Axial index for evaluation
            %
            % Algorithm:
            %
            % - Starts with an initial guess for droplet mass flow (50% of liquid mass)
            % - Updates droplet and film flow rates iteratively
            % - Computes difference between deposition and entrainment rates
            % - Stops when error < 1e-4 kg/s/m or after 100 iterations
            %
            % Notes:
            %
            % - Enhanced drop deposition is disabled
            % - Uses interpolation for improved convergence
            % - Falls back to ad-hoc update if interpolation fails
            % - Method update film and drop mass flow rates. Use flm.copy() and drp.copy() as input arguments if used in post-process

            options = tfSolver.inputSet.options;

            errMax = options.OAFEQUILTOL; errMax0 = errMax;                % [kg/s/m] Convergence criterion
            nwall = tfSolver.inputSet.geometry.NWALL;                      % Number of walls
            perim = tfSolver.inputSet.geometry.PERIM;                      % [m] Perimeter
            W = mix.liquid.W(zIdx);                                        % [kg/s] Liquid flow rate

            for k = 1:options.OAFEQUILMAXITER
                if k == 1
                    Wd(k) = 0.5.*W;                                        % [kg/s] Initial guess: 50% of liquid mass in droplet field
                elseif k == 2
                    Wd(k) = (0.7-double(delta(k-1)>0)*0.4).*W;             % [kg/s] Next guess: 30% or 70% of liquid mass in droplet field (depending on sign of delta)
                %elseif k == 3
                %    Wd(k) = max(min(interp1(delta,Wd,0,'linear','extrap'),W),0); % [kg/s] Next guess
                else
                    if all(diff(delta)./diff(Wd) > 0)
                        % Expected behavior
                        try
                            Wd(k) = max(min(interp1(delta(~isnan(delta)),Wd(~isnan(delta)),0,'linear','extrap'),W),0); % [kg/s] Next guess
                        catch
                            Wd(k) = max(min(Wd(k-1)*(1-20*delta(k-1)),W),0); % [kg/s] Next guess (in case interpolation fails)
                            Wd(k-1) = nan; delta(k-1) = nan;               % Remove previous iteration (avoid interpolation failure at next iteration)
                            errMax = errMax0*10;                           % Relax convergence criterion when interpolation fails
                        end
                    else
                        % Nonsensical behavior
                        Wd(k) = max(min(Wd(k-1)*(1-20*delta(k-1)),W),0);   % [kg/s] Next guess (ad-hoc sensitivity factor)
                        errMax = errMax0*10;                               % Relax convergence criterion for nonsensical behavior
                    end
                end
                drp.W(zIdx) = Wd(k);                                       % [kg/s] Update droplet mass flowrate
                flm.W(zIdx,1:nwall) = (W-drp.W(zIdx)).*perim./sum(perim);  % [kg/s] Corresponding film flow distribution (considered uniform)
                delta(k) = drp.MDEP(zIdx,false).*sum(perim)+sum(flm.MENT(zIdx).*perim,2); % [kg/s/m] Linear deposition - entrainment mass flow rate
                err = abs(delta(k));
                if err < errMax, break; end
            end

            e0 = drp.W(zIdx)./W;                                           % [-] Entrained ratio

            if err > errMax
                tfSolver.log('\nEquilibrium entrainment ratio at onset of annular flow not converged at node %d after %d iterations. \nLinear mass flux residual = %g kg/s/m; entrained ratio = %g.\n',zIdx,k,err,e0);
            end
        end

        function plotter = plotz(tfSolver, tIdx, opts)
            %PLOTZ Plots spatial (axial) distributions of three-field parameters.
            %
            % Generates axial plots of selected three-field parameters at specified
            % time indices. The function supports multiple display modes, wall
            % selections, and optional animation over time.
            %
            % Inputs:
            %
            % - tfSolver          — :class:`Solvers.ThreeField.ThreeFieldSolver` object containing simulation data
            % - tIdx              — Time index or indices (vector of positive integers)
            % - opts.display      — Parameters to display (e.g., 'HFLUX', 'W', 'U', etc.)
            % - opts.solveMode    — Solve mode: 'REAL' or 'NULL'
            % - opts.wall         — Wall index(es) to plot
            % - opts.zIdx         — Axial indices to include in the plot
            % - opts.obstructions — Logical flag to display obstruction locations
            % - opts.annular      — Logical flag to plot annular two-phase flow parameters only from the onset of annular flow
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
                tfSolver
                tIdx              (:,1) double {mustBeInteger,mustBePositive}                                         = []
                opts.display      {matlab.system.mustBeMember(opts.display,{'HFLUX','W','WL','U','THICK','FWE','FME','DME','ALL','VR'})} = {'HFLUX','W','U'}
                opts.solveMode    {mustBeMember(opts.solveMode,{'REAL','NULL'})}                                      = 'REAL'
                opts.wall         (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                            = 1:tfSolver.inputSet.geometry.NWALL
                opts.zIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                            = 1:tfSolver.NZ
                opts.obstructions (1,1) logical                                                                       = false
                opts.annular      (1,1) logical                                                                       = true
                opts.unitTemp     {mustBeMember(opts.unitTemp,{'K','C'})}                                             = 'K'
                opts.arrangement  {mustBeMember(opts.arrangement,{'flow','vertical','horizontal'})}                   = 'flow'
                opts.resize       (1,1) double {mustBeNonnegative}                                                    = 0
                opts.nearWall     (1,1) logical                                                                       = false
            end

            if length(opts.zIdx) < 2
                tfSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end

            z   = tfSolver.Z(opts.zIdx);
            bc  = tfSolver.boundaryConditions;

            switch opts.solveMode
                case 'REAL'
                    if isempty(tIdx), tIdx = 1:tfSolver.NTIME; end
                    mixs = tfSolver.mixSolver.mixture(tIdx);
                    flms = tfSolver.film(tIdx);
                    drps = tfSolver.drop(tIdx);
                    bcHFLUX = arrayfun(@(idx) bc.HFLUX(opts.zIdx,:,flms(idx).TIDX),1:length(tIdx),'uni',0);
                    solveMode = '';
                case 'NULL'
                    if isempty(tIdx), tIdx = 1:length(tfSolver.filmInit); end
                    mixs = repmat(tfSolver.mixSolver.mixtureInit(end),1,length(tIdx));
                    flms = tfSolver.filmInit(tIdx);
                    drps = tfSolver.dropInit(tIdx);
                    bcHFLUX = arrayfun(@(n) bc.HFLUX(opts.zIdx,:,1),1:length(tIdx),'uni',0);
                    solveMode = '- Null transient';
            end

            % Temperature unit offset between C and K
            dTemp = 0; if strcmpi(opts.unitTemp,'C'), dTemp = -273.15; end

            % Set up plotter
            if isscalar(tIdx)
                plotter = Solvers.SolverPlotter( ...
                    sprintf('Axial distributions of three-field parameters at %0.3f [s] %s', flms(1).TIME, solveMode), ...
                    opts.wall, "arrangement", opts.arrangement);
            else
                plotter = Solvers.SolverPlotter( ...
                    sprintf('Axial distributions of three-field parameters at %s [s] %s', '%0.3f', solveMode), ...
                    opts.wall, ...
                    "arrangement", opts.arrangement, ...
                    "isAnimation", true, ...
                    "animationSeries", [flms.TIME]);
            end

            plotter.setZs(z);

            function tf = displayVariable(memberList)
                tf = any(ismember(memberList, upper(opts.display)));
            end

            % Loop through each tIdx
            for idx = 1:length(tIdx)

                flm = flms(idx);
                drp = drps(idx);
                mix = mixs(idx);

                klocZ = mix.KLOCZ(opts.zIdx);                              % [m] Elevations of obstructions

                if opts.annular
                    zaf    = z(z >= flm.mix.OAFZ);
                    zafIdx = opts.zIdx(opts.zIdx >= flm.mix.OAFIDX) - opts.zIdx(1) + 1;
                else
                    zaf    = z;
                    zafIdx = opts.zIdx;
                end

                oafZ = repmat(mix.OAFZ,1,2);

                % Wall heat flux
                if displayVariable({'HFLUX','ALL'})
                    plotter.addTile( ...
                        'tileTitle',         'Wall heat flux', ...
                        'xlabel'   ,     'Axial position [m]', ...
                        'ylabel'   , 'Wall heat flux [W/m^2]');
                    plotter.plotz(  bcHFLUX{idx}        ,'bc'  ,'DisplayName','Boundary Condition');
                    plotter.plotz(flm.HFLUX(opts.zIdx,:),'Film','XData',zaf,'subset',zafIdx);
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Mass flow rates
                if displayVariable({'W','ALL'})
                    plotter.addTile( ...
                        'tileTitle',    'Field mass flow rates', ...
                        'xlabel',          'Axial position [m]', ...
                        'ylabel', 'Field mass flow rate [kg/s]');
                    plotter.plotz(sum([drp.W(opts.zIdx) flm.W(opts.zIdx,:)],2),'Liquid'                           );
                    plotter.plotz(drp.W(opts.zIdx)                            ,'Drop'  ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.W(opts.zIdx,:)                          ,'Film'  ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(mix.vapor.W(opts.zIdx)                      ,'Vapor'                             );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Film WL
                if displayVariable({'WL','ALL'})
                    plotter.addTile( ...
                        'tileTitle', 'Film mass flow rate per unit perimeter', ...
                        'xlabel'   ,                     'Axial position [m]', ...
                        'ylabel'   ,           'Film mass flow rate [kg/s/m]');
                    plotter.plotz(flm.WL(opts.zIdx),'Film','XData',zaf,'subset',zafIdx)
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Field velocities
                if displayVariable({'U','ALL'})
                    plotter.addTile( ...
                        'tileTitle',     'Field velocities', ...
                        'xlabel'   ,   'Axial position [m]', ...
                        'ylabel'   , 'Field velocity [m/s]');
                    plotter.plotz(      drp.U(opts.zIdx)  ,'Drop','XData',zaf,'subset',zafIdx);
                    plotter.plotz(      flm.U(opts.zIdx,:),'Film','XData',zaf,'subset',zafIdx);
                    plotter.plotz(mix.vapor.U(opts.zIdx)  ,'Vapor'                           );
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Film thickness
                if displayVariable({'THICK','ALL'})
                    plotter.addTile( ...
                        'tileTitle',    'Film thickness', ...
                        'xlabel',   'Axial position [m]', ...
                        'ylabel',   'Film thickness [m]');
                    plotter.plotz(flm.THICK(opts.zIdx),'Film','XData',zaf,'subset',zafIdx);
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Film mass Exchange
                if displayVariable({'FWE','ALL'})
                    plotter.addTile( ...
                        'tileTitle',  'Film mass exchanges', ...
                        'xlabel',      'Axial position [m]', ...
                        'ylabel',    'Mass flux [kg/s/m^2]');
                    plotter.plotz(drp.MDEP(opts.zIdx)    ,'Deposition' ,'DisplayName','Drop deposition' ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.MENT(opts.zIdx)    ,'Entrainment','DisplayName','Film entrainment','XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.MEVAP(opts.zIdx)   ,'Evaporation','DisplayName','Film evaporation','XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.MTOT(drp,opts.zIdx),      'Total');
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Film momentum exchanges
                if displayVariable({'FME','ALL'})
                    plotter.addTile( ...
                        'tileTitle', 'Film momentum exchanges', ...
                        'xlabel',         'Axial position [m]', ...
                        'ylabel',       'Shear stress [N/m^2]');
                    plotter.plotz(flm.FDEP(drp,opts.zIdx),'Deposition','DisplayName','Drop deposition','XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.FWALL(opts.zIdx)   ,'Wall'                                      ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.FVAPOR(opts.zIdx)  ,'Vapor'                                     ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.FBUOY(opts.zIdx)   ,'Buoyancy'                                  ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.FGRAV(opts.zIdx)   ,'Gravity'                                   ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(flm.FTOT(drp,opts.zIdx),'Total'                                     ,'XData',zaf,'subset',zafIdx);
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Drop momentum exchanges
                if displayVariable({'DME','ALL'})
                    plotter.addTile( ...
                        "tileTitle", 'Drop momentum exchanges', ...
                        'xlabel',         'Axial position [m]', ...
                        'ylabel',       'Shear stress [N/m^3]');
                    plotter.plotz(drp.FENT(flm,opts.zIdx),'Entrainment','DisplayName','Film entrainment','XData',zaf,'subset',zafIdx);
                    plotter.plotz(drp.FDRAG(opts.zIdx)   ,'Vapor'                                       ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(drp.FBUOY(opts.zIdx)   ,'Buoyancy'                                    ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(drp.FGRAV(opts.zIdx)   ,'Gravity'                                     ,'XData',zaf,'subset',zafIdx);
                    plotter.plotz(drp.FTOT(flm,opts.zIdx),'Total'                                       ,'XData',zaf,'subset',zafIdx);
                    plotter.legend('show', 'Location', 'best');
                    plotter.xlim([min(z) max(z)]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

                % Vapor ratios (void fraction and qualities)
                if displayVariable({'VR'})
                    plotter.addTile( ...
                        'tileTitle', 'Void fraction and qualities', ...
                        'xlabel'   ,          'Axial position [m]', ...
                        'ylabel'   , 'Quality / Void fraction [-]');
                    mix = flm.mix;
                    plotter.plotz(mix.XEQ(opts.zIdx),'Equil'       ,'DisplayName','Equilibrium quality')
                    plotter.plotz(mix.X(opts.zIdx)  ,'Vapor'       ,'DisplayName','Vapor mass quality' )
                    plotter.plotz(mix.VF(opts.zIdx) ,'VoidFraction','DisplayName','Void fraction'      );
                    if opts.nearWall
                        plotter.plotz(flm.X(opts.zIdx),'NearWall','DisplayName','Near-wall (film) mass quality','XData',zaf,'subset',zafIdx);
                        plotter.plotz(drp.X(opts.zIdx),'Bulk'    ,'DisplayName','Bulk (drop) mass quality'     ,'XData',zaf,'subset',zafIdx);
                    end
                    plotter.legend('show', "Location", 'best');
                    plotter.xlim([min(z) max(z)]);
                    ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                    ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                    plotter.ylim([ymin ymax]);
                    plotter.plotOAF(oafZ);
                    if opts.obstructions
                        plotter.plotK(klocZ);
                    end
                end

            end

            if opts.resize > 0
                plotter.resizeFigure(opts.resize);
            end
        end

        function plotter = plott(tfSolver, zIdx, opt)
            %PLOTT Plots temporal distributions of three-field parameters at a given axial location.
            %
            % Generates time-series plots of selected three-field parameters at
            % a specified axial index. The method supports multiple display
            % modes, wall selections, and plot arrangements.
            %
            % Inputs:
            %
            % - tfSolver          — :class:`Solvers.ThreeField.ThreeFieldSolver` object containing simulation data
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
                tfSolver
                zIdx            (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive}                    = tfSolver.NZ
                opt.display     {mustBeMember(opt.display,{'HFLUX','W','WL','U','THICK','FWE','FME','DME','ALL','VR'})} = {'HFLUX','W','U'}
                opt.solveMode   {mustBeMember(opt.solveMode,{'REAL','NULL'})}                                      = 'REAL'
                opt.wall        (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                           = 1:tfSolver.inputSet.geometry.NWALL
                opt.tIdx        (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                           = []
                opt.reverseTime (1,1) logical                                                                      = false
                opt.unitTemp    {mustBeMember(opt.unitTemp,{'K','C'})}                                             = 'K'
                opt.arrangement {mustBeMember(opt.arrangement,{'flow','vertical','horizontal'})}                   = 'flow'
                opt.resize      (1,1) double {mustBeNonnegative}                                                   = 0
                opt.nearWall    (1,1) logical                                                                      = false
            end

            if isempty(opt.wall), opt.wall = 1:tfSolver.inputSet.geometry.NWALL; end

            switch opt.solveMode
                case 'REAL'
                    if isempty(opt.tIdx), opt.tIdx = 1:tfSolver.NTIME; end
                    mix = tfSolver.mixSolver.mixture(opt.tIdx);
                    %fld = tfSolver.mixSolver.fluid(opt.tIdx);
                    flm = tfSolver.film(opt.tIdx);
                    drp = tfSolver.drop(opt.tIdx);
                    bcHFLUX = permute(tfSolver.boundaryConditions.HFLUX(zIdx,:,:),[3 2 1]);
                    solveMode = '';
                case 'NULL'
                    if isempty(opt.tIdx), opt.tIdx = 1:length(tfSolver.filmInit);  end
                    mix = repmat(tfSolver.mixSolver.mixtureInit(end),1,length(opt.tIdx));
                    %fld = repmat(tfSolver.mixSolver.fluid(1),1,length(opt.tIdx));
                    flm = tfSolver.filmInit(opt.tIdx);
                    drp = tfSolver.dropInit(opt.tIdx);
                    bcHFLUX = repmat(tfSolver.boundaryConditions.HFLUX(zIdx,:,1),length(opt.tIdx),1);
                    solveMode = '- Null transient';
            end

            time = [flm.TIME];
            if length(time) < 2
                tfSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            if opt.reverseTime
                time = time -time(end);
            end

            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end

            z = tfSolver.Z;
            plotter = Solvers.SolverPlotter( ...
                sprintf('Time distributions of three-field parameters at %0.3f [m] %s', z(zIdx), solveMode), ...
                opt.wall,'arrangement',opt.arrangement);
            plotter.setZs(time);

            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Wall heat flux', ...
                    'xlabel'   ,               'Time [s]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plotz(             bcHFLUX               ,'bc'  ,'DisplayName','Boundary Condition');
                plotter.plotz(flm.transient('HFLUX','zIdx',zIdx)','Film'                                   );
                plotter.legend('show', 'Location', 'best');
            end

            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Field mass flow rates', ...
                    'xlabel'   ,              'Time [s]', ...
                    'ylabel'   , 'Mass flow rate [kg/s]');
                liquidW = sum([drp.transient('W','zIdx',zIdx)' flm.transient('W','zIdx',zIdx)'],2);
                plotter.plotz(               liquidW               ,'Liquid');
                plotter.plotz(drp.transient(      'W','zIdx',zIdx)','Drop'  );
                plotter.plotz(flm.transient(      'W','zIdx',zIdx)','Film'  );
                plotter.plotz(mix.transient('vapor.W','zIdx',zIdx)','Vapor' );
                plotter.legend('show', 'Location', 'best');
            end

            % Film WL
            if any(ismember({'WL','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Film mass flow rate per unit perimeter', ...
                    'xlabel'   ,                               'Time [s]', ...
                    'ylabel'   ,           'Film mass flow rate [kg/s/m]');
                plotter.plotz(flm.transient('WL','zIdx',zIdx)','Film');
            end

            % Field velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',     'Field velocities', ...
                    'xlabel'   ,             'Time [s]', ...
                    'ylabel'   , 'Field velocity [m/s]');
                plotter.plotz(drp.transient(      'U','zIdx',zIdx)','Drop' );
                plotter.plotz(flm.transient(      'U','zIdx',zIdx)','Film' );
                plotter.plotz(mix.transient('vapor.U','zIdx',zIdx)','Vapor');
                plotter.legend('show', 'Location', 'best');
            end

            % Film thickness
            if any(ismember({'THICK','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',  'Film thickness', ...
                    'xlabel',           'Time [s]', ...
                    'ylabel', 'Film thickness [m]');
                plotter.plotz(flm.transient('THICK','zIdx',zIdx)','Film');
            end

            % Film mass Exchange
            if any(ismember({'FWE','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Film mass exchanges', ...
                    'xlabel',               'Time [s]', ...
                    'ylabel',   'Mass flux [kg/s/m^2]');
                plotter.plotz(drp.transient('MDEP' ,    'zIdx',zIdx)','Deposition' ,'DisplayName','Drop deposition' );
                plotter.plotz(flm.transient('MENT' ,    'zIdx',zIdx)','Entrainment','DisplayName','Film entrainment');
                plotter.plotz(flm.transient('MEVAP',    'zIdx',zIdx)','Evaporation','DisplayName','Film evaporation');
                plotter.plotz(flm.transient('MTOT' ,drp,'zIdx',zIdx)','Total'                                       );
                plotter.legend('show', 'Location', 'best');
            end

            % Film momentum exchanges
            if any(ismember({'FME','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Film momentum exchanges', ...
                    'xlabel',                   'Time [s]', ...
                    'ylabel',       'Shear stress [N/m^2]');
                plotter.plotz(flm.transient('FDEP'  ,drp,'zIdx',zIdx)','Deposition','DisplayName','Drop deposition');
                plotter.plotz(flm.transient('FWALL' ,    'zIdx',zIdx)','Wall'                                      );
                plotter.plotz(flm.transient('FVAPOR',    'zIdx',zIdx)','Vapor'                                     );
                plotter.plotz(flm.transient('FBUOY' ,    'zIdx',zIdx)','Buoyancy'                                  );
                plotter.plotz(flm.transient('FGRAV' ,    'zIdx',zIdx)','Gravity'                                   );
                plotter.plotz(flm.transient('FTOT'  ,drp,'zIdx',zIdx)','Total'                                     );
                plotter.legend('show', 'Location', 'best');
            end

            % Drop momentum exchanges
            if any(ismember({'DME','ALL'},opt.display))
                plotter.newTile( ...
                    "tileTitle", 'Drop momentum exchanges', ...
                    'xlabel',                   'Time [s]', ...
                    'ylabel',       'Shear stress [N/m^3]');
                plotter.plotz(drp.transient('FENT' ,flm,'zIdx',zIdx)','Entrainment','DisplayName','Film entrainment');
                plotter.plotz(drp.transient('FDRAG',    'zIdx',zIdx)','Vapor'                                       );
                plotter.plotz(drp.transient('FBUOY',    'zIdx',zIdx)','Buoyancy'                                    );
                plotter.plotz(drp.transient('FGRAV',    'zIdx',zIdx)','Gravity'                                     );
                plotter.plotz(drp.transient('FTOT' ,flm,'zIdx',zIdx)','Total'                                       );
                plotter.legend('show', 'Location', 'best');
            end

            % Vapor ratios (void fraction and qualities)
            if any(ismember({'VR'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Void fraction and qualities', ...
                    'xlabel'   ,                    'Time [s]', ...
                    'ylabel'   , 'Quality / Void fraction [-]');
                mix = flm.mix;
                plotter.plotz(mix.transient('XEQ','zIdx',zIdx)','Equil','DisplayName','Equilibrium quality');
                plotter.plotz(mix.transient('X'  ,'zIdx',zIdx)','Vapor','DisplayName','Vapor mass quality' );
                plotter.plotz(mix.transient('VF' ,'zIdx',zIdx)','VF'   ,'DisplayName','Void faction'       );
                if opt.nearWall
                    plotter.plotz(flm.transient('X','zIdx',zIdx)','NearWall','DisplayName','Near-wall (film) mass quality');
                    plotter.plotz(drp.transient('X','zIdx',zIdx)','Bulk'    ,'DisplayName','Bulk (drop) mass quality'     );
                end
                plotter.legend("show", "Location", 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

            if opt.resize > 0
                plotter.resizeFigure(opt.resize);
            end
        end

        function plotzt(tfSolver, opt)
            %PLOTZT Plots 2D time/elevation distributions of three-field parameters.
            %
            % Generates surface plots of selected three-field related parameters
            % over time and axial (elevation) positions. It supports plotting
            % for film and drop fields, and can handle both real
            % and null (initial) transient data.
            %
            % Inputs:
            %
            % - tfSolver          — :class:`Solvers.ThreeField.ThreeFieldSolver` object containing simulation data
            % - opt.display       — Parameter(s) to display (e.g., 'HFLUX', 'U', etc.)
            % - opt.label         — Corresponding labels for display parameters
            % - opt.unit          — Units for each parameter
            % - opt.field         — Field to plot: 'film' or 'drop'
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
                tfSolver
                opt.display      {mustBeA(opt.display,{'cell','char'})}                   = {         'HFLUX',             'W',       'U'}
                opt.label        {mustBeA(opt.label,{'cell','char'})}                     = {}
                opt.unit         {mustBeA(opt.unit,{'cell','char'})}                      = {}
                opt.field        {mustBeMember(opt.field,{'drop','film'})}                = {'drop','film'}
                opt.solveMode    {mustBeMember(opt.solveMode,{'REAL','NULL'})}            = 'REAL'
                opt.wall         (1,:) double {mustBeVector,mustBeInteger,mustBePositive} = 1:tfSolver.inputSet.geometry.NWALL
                opt.zIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:tfSolver.NZ
                opt.tIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = []
                opt.annular      (1,1) logical                                            = true
                opt.reverseTime  (1,1) logical                                            = false
                opt.shading      {mustBeMember(opt.shading,{'faceted','flat','interp'})}  = 'interp'
                opt.view         (1,2) double                                             = [0 90]
            end

            if ~iscell(opt.display), opt.display = {opt.display}; end
            if ~iscell(opt.label)  , opt.label   = {opt.label}  ; end
            if ~iscell(opt.unit)   , opt.unit    = {opt.unit}   ; end

            display = {         'HFLUX',             'W',                               'WL',       'U',    'THICK'};
            label   = {'wall heat flux','mass flow rate','mass flow rate per unit perimeter','velocity','thickness'};
            unit    = {         'W/m^2',          'kg/s',                           'kg/s/m',     'm/s',        'm'};
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
                tfSolver.log('Error: Labels and/or units must be specified for the selected parameters.\n');
                return
            end

            switch opt.solveMode
                case 'REAL'
                    if isempty(opt.tIdx), opt.tIdx = 1:tfSolver.NTIME; end
                    mix = tfSolver.mixSolver.mixture(opt.tIdx);
                    drp = tfSolver.drop(opt.tIdx);
                    flm = tfSolver.film(opt.tIdx);
                    solveMode = '';
                case 'NULL'
                    if isempty(opt.tIdx), opt.tIdx = 1:length(tfSolver.filmInit);  end
                    mix = repmat(tfSolver.mixSolver.mixtureInit(end),1,length(opt.tIdx));
                    drp = tfSolver.dropInit(opt.tIdx);
                    flm = tfSolver.filmInit(opt.tIdx);
                    solveMode = '- Null transient';
            end
            time = [drp(opt.tIdx).TIME];
            if isempty(opt.wall)
                opt.wall = 1:tfSolver.inputSet.geometry.NWALL;
            end
            if length(opt.zIdx) < 2
                tfSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            if length(opt.tIdx) < 2
                tfSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end

            for k = opt.wall
                if ismember('drop',opt.field)
                    name = ['Time/axial distributions of three-field (drop) parameters ' solveMode ' - Wall ' num2str(k)];
                    fh_drp = figure('name',name);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP'})
                            ax_drp(i) = mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt,[],0,time);
                        elseif contains(opt.display{i},{'WL','THICK'})
                            continue
                        else
                            ax_drp(i) = drp.plotzt(opt.display{i},['Drop '    opt.label{i}],opt.unit{i},k,opt,flm,opt.annular);
                        end
                    end
                    sgtitle(fh_drp,name,'FontSize',18);
                end
                if ismember('film',opt.field)
                    name = ['Time/axial distributions of three-field (film) parameters ' solveMode ' - Wall ' num2str(k)];
                    fh_flm = figure('name',name);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP'})
                            ax_flm(i) = mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt,[],0,time);
                        else
                            ax_flm(i) = flm.plotzt(opt.display{i},['Film '    opt.label{i}],opt.unit{i},k,opt,drp,opt.annular);
                        end
                    end
                    sgtitle(fh_flm,name,'FontSize',18);
                end
            end
        end

    end

end
