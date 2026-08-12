classdef OAF
    %OAF Enumeration of onset of annular flow models
    %
    % This class defines the available :attr:`Inputs.Model.OAF` models for
    % predicting the onset of annular flow, used by the three-field and
    % four-field solvers.
    %
    % Models:
    %
    % - WALLIS       — Full Wallis correlation (:cite:t:`wallis1969`, Equation 11.1019)
    % - WALLIS_SIMP  — Simplified Wallis correlation (:cite:t:`sanmiguel2015`, Equation 6), used for compatibility with codes employing this approach
    % - LEVITAN      — Levitan correlation (:cite:t:`Levitan1989`)

    enumeration
        WALLIS               % Full Wallis correlation (1969)
        WALLIS_SIMP          % Simplified Wallis correlation
        LEVITAN              % Levitan correlation
    end
end