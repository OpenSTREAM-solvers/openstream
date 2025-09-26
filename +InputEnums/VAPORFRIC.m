classdef VAPORFRIC
%VAPORFRIC Vapor to film interfacial friction model
%
%   Defines the model used to calculate the vapor to film interfacial
%   friction coefficient.
%   Used by the three-field and four-field solvers
%
    enumeration
        CONSTANT             % Constant value
        WALLIS               % Wallis model (based on void fraction)
        WALLISTHICK          % Wallis model (based on film thickness)
        SOLVER_DEPENDENT     % Solver dependant
    end

end