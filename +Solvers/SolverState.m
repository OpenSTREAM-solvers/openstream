classdef SolverState < uint16
%SOLVERSTATE Enumeration class of possible solver states
%
    enumeration
        UNSOLVED                    (0)
        SOLVEDCONVERGED             (1)
        SOLVEDNOTCONVERGED          (2)
        INITIALSTEPNOTCONVERGED     (3)
    end
end