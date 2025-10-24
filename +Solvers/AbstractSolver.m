classdef (Abstract) AbstractSolver < handle
    %ABSTRACTSOLVER
    %   Defines the base interface and shared functionality for all solver classes.
    %   Subclasses must implement the abstract methods and properties defined here.

    properties (SetAccess=protected, Abstract)
        % Input configuration object of type Inputs.InputSet
        inputSet    {isa(inputSet,'Inputs.InputSet')}
    end

    properties (SetAccess=protected, Abstract)
        % Solver state, defined by the SolverState enumeration
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
            %   Initializes the solver with a given inputSet and applies
            %   solver-specific properties.

            solverName = regexpi(metaclass(solver).Name, '(?<=\.)[^.]+(?=\.)', 'match','once'); % Extract Solver name            
            solver.inputSet = inputSet.applySolverDependentProps(solverName);
        end
        
        function log(solver, varargin)
            %LOG Log messages to the session log
            %
            solver.inputSet.session.log.log(varargin{:});
        end

        function save(solver, opts)
            %SAVE Save the solver object to a .mat file with a customizable name.
            %
            %   save(solver, opts)
            %
            %   Inputs:
            %       solver        - The solver object to be saved.
            %       opts.name     - (string) Name of the variable under which to save the solver. Default: 'solver'.'
            %       opts.showpath - (logical) Whether to display the save path. Default: true.

            arguments
                solver
                opts.name     (1,1) string  {mustBeTextScalar}             = 'solver'
                opts.showpath (1,1) logical                                = true              
            end

            session = solver.inputSet.session;

            if ~isfolder(session.directory)
                error('Directory %s does not exist. Check Session.log.LOGMODE. Try session.makeSessionDirectory()',session.directory);
            end

            outputFile = fullfile(session.directory, session.name + '.mat');
            dataStruct = struct();
            dataStruct.(opts.name) = solver;

            save(outputFile,'-struct','dataStruct');

            if opts.showpath
                fprintf('\nOutput file save to %s\n\n',outputFile)
            end
        end

    end

    methods (Static)
        
        function ITR = CreateITR(NZ, ITRFields)
            %CreateITR Create a structure for inner iteration values
            %
            %   Inputs:
            %       NZ        - Number of axial nodes (scalar)
            %       ITRFields - (string array) Names of fields to include in the struct
            %
            %   Output:
            %       ITR - Struct with fields initialized to zero vectors of length NZ

            arguments
                NZ        (1,1) double  
                ITRFields (1,:) string  = ["N","DW","DU"]                  % Cell structure to convert into struct
            end

            ITRCell = cell(numel(ITRFields),1);                            
            ITRCell(:) = {zeros(NZ,1)};                                    % Initialize with zeros
            ITR = cell2struct(ITRCell, ITRFields, 1);                      % Convert cell to struct with fieldnames
        end
        
    end
    
end

