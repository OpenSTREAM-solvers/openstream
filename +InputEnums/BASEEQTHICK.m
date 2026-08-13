classdef BASEEQTHICK
    %BASEEQTHICK Enumeration of base film equilibrium thickness models
    %
    % This class defines the available :attr:`Inputs.Model.BASEEQTHICK`
    % models for calculating the equilibrium base film thickness, used by
    % the four-field solver.
    %
    % Models:
    %
    % - RISO   — Based on RISO dataset (:cite:t:`LECORREMODEL`)
    % - COEFS  — Generalized RISO model using user-defined :attr:`Inputs.Model.BASEEQTHICKCOEF`
    % - YPLUS  — Based on dimensionless wall distance (y+) using user-defined :attr:`Inputs.Model.BASEYPLUS`
    % - MFVAL  — MFVAL model (under development)

    enumeration
        RISO                 % RISO dataset-based model (Le Corre, 2022)
        COEFS                % Generalized form of RISO model with specified coefficients
        YPLUS                % Model based on specified y+ value
        MFVAL                % MFVA model (under development)
    end
end