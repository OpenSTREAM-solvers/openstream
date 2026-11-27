classdef (Abstract) AbstractSolver < handle
    %ABSTRACTSOLVER Defines the base interface and shared functionality for all solver classes.
    %
    % Subclasses must implement the abstract methods and properties defined here.

    properties (SetAccess=protected, Abstract)

        % Input configuration object of type :class:`Inputs.InputSet`
        inputSet    Inputs.InputSet

    end

    properties (SetAccess=protected, Abstract)

        % Solver state, defined by :class:`Solvers.SolverState` enumeration
        STATE (1,1) Solvers.SolverState

    end

    methods (Abstract)

        initializeSolver
        solve
        plotz
        plott
        plotzt

    end

    methods

        function solver = AbstractSolver(inputSet)
            %ABSTRACTSOLVER Constructor for AbstractSolver
            %
            % Initializes the solver with a given :class:`Inputs.InputSet`
            % and applies solver-specific properties.

            solverName = regexpi(metaclass(solver).Name, '(?<=\.)[^.]+(?=\.)', 'match','once'); % Extract Solver name
            solver.inputSet = inputSet.applySolverDependentProps(solverName);
        end

        function log(solver, varargin)
            %LOG Log messages to the session log

            solver.inputSet.session.log.log(varargin{:});
        end

        function warning(solver, varargin)
            %WARNING Log warning messages to the session log

            solver.inputSet.session.log.warning(varargin{:});
        end

        function name = solverName(solver)
            %SOLVERNAME Returns the name of the solver

            parts = split(class(solver),'.');
            name = parts{end};
        end

        function save(solver, opts)
            %SAVE Save the solver object to a .mat file with a customizable name.
            %
            % Inputs:
            %
            % - solver        — The solver object to be saved.
            % - opts.name     — (string) Name of the variable under which to save the solver. Default set to solver name
            % - opts.showpath — (logical) Whether to display the save path. Default: true.

            arguments
                solver
                opts.name     (1,1) string  {mustBeTextScalar}             = solver.solverName()
                opts.showpath (1,1) logical                                = true
            end

            session = solver.inputSet.session;

            if ~isfolder(session.directory)
                error('OpenSTREAM:AbstractSolver:DirectoryDoesNotExist','Directory %s does not exist. Check Session.log.LOGMODE. Try session.makeSessionDirectory()',session.directory);
            end

            outputFile = fullfile(session.directory, session.name + '_' + solver.solverName() + '.mat');
            dataStruct = struct();
            dataStruct.(opts.name) = solver;

            save(outputFile,'-struct','dataStruct');

            if opts.showpath
                solver.log('\nOutput file saved to %s\n\n',outputFile)
            end
        end

    end

    methods (Static)

        function ITR = CreateITR(NZ, ITRFields)
            %CreateITR Create and initialize the inner iteration storage structure
            %
            % Inputs:
            %
            % - NZ        — Number of axial nodes (scalar)
            % - ITRFields — (string array) Names of fields to include in the struct
            %
            % Output:
            %
            % - ITR       — Struct with fields initialized to zero vectors of length NZ

            arguments
                NZ        (1,1) double
                ITRFields (1,:) string  = ["N","DW","DU"]                  % Cell structure to convert into struct
            end

            ITRCell = cell(numel(ITRFields),1);
            ITRCell(:) = {zeros(NZ,1)};                                    % Initialize with zeros
            ITR = cell2struct(ITRCell, ITRFields, 1);                      % Convert cell to struct with fieldnames
        end

    end

    methods(Access = protected, Hidden = true)

        function checkMixSolverConsistency(solver, mixSolver)
            %CHECKMIXSOLVERCONSISTENCY Error if mixSolver has a different axial mesh or time grid

            a = solver.inputSet;
            b = mixSolver.inputSet;
            if a.geometry.LENGTH ~= b.geometry.LENGTH || ~isequal(a.geometry.PERIM, b.geometry.PERIM) || ...
                    a.model.NNODES ~= b.model.NNODES || a.options.TSTEP ~= b.options.TSTEP || ...
                    ~isequal([a.bc.TIME], [b.bc.TIME])
                msg = 'The provided mixture solver has a different axial mesh, wall definition or time grid.';
                throwAsCaller(MException(sprintf('OpenSTREAM:%s:InconsistentMixSolver', solver.solverName()),msg));
            end
        end

        function checkMixSolverState(solver, mixSolver)
            %CHECKMIXSOLVERSTATE Warn if the mixture solution is not converged

            import Solvers.SolverState
            if any(mixSolver.STATE == [SolverState.INITIALSTEPNOTCONVERGED, SolverState.SOLVEDNOTCONVERGED])
                solver.warning('Mixture solution is not converged (%s). %s results may not be reliable.', string(mixSolver.STATE), solver.solverName());
            end
        end

    end

    methods (Static, Access = protected)

        function inventory = flowInventory(W, U, Wmin)
            %FLOWINVENTORY Safely evaluate the transient flow inventory W./U

            Umin = 1e-12;                                                   % [m/s] Numerical zero velocity threshold

            inventory = zeros(size(W));

            moving = abs(U) > Umin;
            inventory(moving) = W(moving)./U(moving);

            inconsistent = ~moving & abs(W) > Wmin;
            if any(inconsistent, 'all')
                error('OpenSTREAM:AbstractSolver:ZeroVelocityWithNonzeroFlow', ...
                    'Nonzero mass flow rate is associated with zero velocity.');
            end
        end

end

end

