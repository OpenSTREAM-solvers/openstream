classdef OAF
    %OAF Enumeration of onset of annular flow models
    %
    %   This class defines the available models for predicting the onset
    %   of annular flow, used by the three-field and four-field solvers.
    %
    %   Models:
    %       - WALLIS       — Full Wallis correlation (Equation 11.1019 in *One-Dimensional Two-Phase Flow*, 1969)
    %       - WALLIS_SIMP  — Simplified Wallis correlation, used for compatibility with codes employing this approach

    enumeration
        WALLIS               % Full Wallis correlation (1969)
        WALLIS_SIMP          % Simplified Wallis correlation
    end
end