classdef LOCRELVEL
    %LOCRELVEL Enumeration of local relative velocity models
    %
    % This class defines the available :attr:`Inputs.Model.LOCRELVEL` models
    % for calculating the local relative velocity between liquid and vapor
    % phases, used by the two-fluid solver.
    %
    % Models:
    %
    % - AREAMEAN  — Difference between area-averaged phase velocities (:cite:t:`Walter2024`)
    % - SCALED    — Scaled difference using user-defined :attr:`Inputs.Model.RELVELCST` (:cite:t:`Walter2024`)
    % - DRIFT     — Uses drift velocity as the local relative velocity (:cite:t:`Walter2024`)
    % - SIMPLE    — Simplified assumptions for bubbly and annular flow regime (:cite:t:`Walter2024`)

    enumeration
        AREAMEAN             % Area-averaged velocity difference
        SCALED               % Scaled area-averaged velocity difference
        DRIFT                % Drift velocity model
        SIMPLE               % Simplified model for bubbly and annular flow
    end
end