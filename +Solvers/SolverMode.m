classdef SolverMode < uint16
%SOLVERMODE Enumeration class of possible solver modes
%
%   Solvers can be set up for a new solution, or a continuation of an
%   exisiting solution.
    enumeration
        NEW                    (0)
        CONTINUE               (1)
        SUBSET                 (2)
    end
end