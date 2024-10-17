classdef SolverState < uint16
%SOLVERSTATE Enumeration class of possible solver states
%
    enumeration
        UNSOLVED                    (8)
        CREATED                     (0)
        SOLVEDCONVERGED             (1)
        SOLVEDNOTCONVERGED          (2)
        INITIALSTEPCONVERGED        (3)
        INITIALSTEPNOTCONVERGED     (4)
        UNINITIALIZED               (5)
        INITIALIZED                 (6)
        EMPTY                       (7)
    end
end