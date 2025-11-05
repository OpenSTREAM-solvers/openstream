classdef TPFM
    %TPFM Enumeration of two-phase wall friction multiplier models
    %
    % This class defines the available models for calculating the two-phase wall
    % friction multiplier used by the mixture solver.
    %
    % Models:
    %
    % - HOMOGENEOUS  — Assumes no slip between phases; both phases move at the same velocity
    % - SLIP         — Accounts for velocity differences (slip) between liquid and vapor phases using user-defined :attr:`Inputs.Model.SLIP`
    % - EPRI         — Empirical model developed by the Electric Power Research Institute (EPRI) (:cite:t:`reddy1982`)

    enumeration
        HOMOGENEOUS          % Homogeneous flow model
        SLIP                 % Slip flow model
        EPRI                 % EPRI empirical model
    end
end