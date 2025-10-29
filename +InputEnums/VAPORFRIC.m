classdef VAPORFRIC
    %VAPORFRIC Enumeration of vapor to film interfacial friction models
    %
    % This class defines the models used to calculate the vapor-to-film interfacial
    % friction coefficient used by the three-field and four-field solvers.
    %
    % Models:
    %
    % - CONSTANT          — Uses a fixed, friction coefficient using user-defined VAPORFRICCST
    % - WALLIS            — Wallis model based on void fraction (:cite:t:`wallis1969`).
    % - WALLISTHICK       — Wallis model based on film thickness (:cite:t:`ADAMSSON20112843`, Equation 35).
    % - SOLVER_DEPENDENT  — Friction model determined by the solver configuration.

    enumeration
        CONSTANT             % Constant friction coefficient
        WALLIS               % Wallis model (based on void fraction)
        WALLISTHICK          % Wallis model (based on film thickness)
        SOLVER_DEPENDENT     % Solver-dependent model selection
    end
end