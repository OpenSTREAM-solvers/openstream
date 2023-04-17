classdef (Abstract) AbstractSolver < handle
    %ABSTRACTSOLVER Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess=protected, Abstract)
        inputSet    {isa(inputSet,'Inputs.InputSet')}
    end

    properties (SetAccess=protected, Abstract)

        STATE (1,1) Solvers.SolverState                                     % Solver state defined by SolverState enum

    end

    properties (Access = public)
        OUTPUTDIR                           = userpath                          % Output directory
        LOGFID                              =-1                                 % Logging file ID
        LOGMODE (1,1) Solvers.LogMode       = Solvers.LogMode.LOGTOCONSOLEONLY  % Logging mode
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
            import Solvers.LogMode

            if solver.LOGMODE == LogMode.NONE
                return
            else
                if (solver.LOGMODE == LogMode.BOTH || ...
                        solver.LOGMODE == LogMode.LOGTOFILEONLY) ...
                    && solver.LOGFID >= 0
                    builtin('fprintf',solver.LOGFID, varargin{:}); 
                end
                if (solver.LOGMODE == LogMode.BOTH || ...
                        solver.LOGMODE == LogMode.LOGTOCONSOLEONLY)
                    builtin('fprintf',varargin{:}); 
                end
            end
        end

        function setupLog(solver)
        %SETUPLOG Setup the logging functions for solver
        %
            % Update OUTPUTDIR using value from inputSet
            solver.OUTPUTDIR = solver.inputSet.sessionDir;
            
            if (solver.LOGMODE == Solvers.LogMode.LOGTOFILEONLY || ...
                solver.LOGMODE == Solvers.LogMode.BOTH) && ...
                solver.LOGFID == -1
                
                % Create log file
                solver.LOGFID = fopen(fullfile(solver.OUTPUTDIR,'log.txt'),"w+t");

            end
        end

        function delete(solver)
        %DELETE Deconstructor of solver
        %

            if solver.LOGFID >= 0
                try
                    fclose(solver.LOGFID);
                catch
                end
            end

        end
    end
end

