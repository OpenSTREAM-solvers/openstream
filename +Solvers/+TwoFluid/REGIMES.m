classdef REGIMES < double
    %REGIMES Enumeration of two-phase flow regimes
    %
    % This class defines the available two-phase flow regimes for constitutive
    % model selection, used by the two-fluid solver.
    %
    % The flow regimes are defined as an enum class to increase computational
    % efficiency while increasing readability of code, particularly when
    % different calculations are carried out for different flow regimes.
    %
    % Flow regimes:
    %
    % - LIQUID            — Single-phase liquid
    % - BUBBLY_SUBCOOLED  — Bubbly flow in subcooled region
    % - BUBBLY_SATURATED  — Bubbly flow in saturated region
    % - INTERMEDIATE      — Intermediate flow region
    % - ANNULAR           — Annular flow
    % - DFFB              — Dispersed Flow Film Boiling

    enumeration
        LIQUID              (0)
        BUBBLY_SUBCOOLED    (1)
        BUBBLY_SATURATED    (2)
        INTERMEDIATE        (3)
        ANNULAR             (4)
        DFFB                (5)
        
    end
end

