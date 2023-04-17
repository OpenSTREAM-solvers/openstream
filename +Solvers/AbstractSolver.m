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
end

