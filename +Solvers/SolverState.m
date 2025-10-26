classdef SolverState < uint16
    %SOLVERSTATE Enumeration of solver execution states
    %
    % This enumeration defines the possible states a solver can be in
    % during or after execution. It is used to track solver execution and
    % convergence status.

    enumeration
        UNSOLVED                    (0)                % Solver has not yet run
        SOLVEDCONVERGED             (1)                % Solver completed and converged successfully
        SOLVEDNOTCONVERGED          (2)                % Solver completed but did not converge
        INITIALSTEPCONVERGED        (3)                % Initial steady-state step completed and converged
        INITIALSTEPNOTCONVERGED     (4)                % Initial steady-state step completed but did not converge
    end
    
end