classdef (Abstract) AbstractSolver < handle
    %ABSTRACTSOLVER Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess=protected, Abstract)
        inputSet    {isa(inputSet,'Inputs.InputSet')}
    end

    properties (SetAccess=protected, Abstract)

        STATE (1,1) Solvers.SolverState                                     % Solver state defined by SolverState enum

    end

    methods (Abstract)
        initializeSolver
        solve
        plotz
        plott
        plotzt
        saveResults
    end

    methods

        function solver = AbstractSolver(inputSet)
        %ABSTRACTSOLVER Constructor
        %
            
            % Store inputSet as object property
            solver.inputSet = inputSet;

        end
        
        function log(solver, varargin)
        %LOG Log events
        %
            solver.inputSet.session.log.log(varargin{:});
        end
        
    end

    methods (Static)
        
        function ITR = CreateITR(NZ, ITRFields)
            % Create inner iteration value struct
            arguments
                NZ        (1,1) double  
                ITRFields (1,:) string  = ["N","DW","DU"]                   % Cell structure to convert into struct
            end

            ITRCell = cell(numel(ITRFields),1);                            
            ITRCell(:) = {zeros(NZ,1)};                                     % Initialize with zeros
            ITR = cell2struct(ITRCell, ITRFields, 1);                       % Convert cell to struct with fieldnames
        end
        
    end
end

