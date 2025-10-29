classdef LOCRELVEL
    %LOCRELVEL Enumeration of local relative velocity models
    %
    % This class defines the available models for calculating the local
    % relative velocity between liquid and vapor phases, used by the
    % two-fluid solver.
    %
    % Models:
    % - AREAMEAN  — Difference between area-averaged phase velocities
    % - SCALED    — Scaled difference using user-defined RELVELCST
    % - DRIFT     — Uses drift velocity as the local relative velocity
    % - SIMPLE    — Simplified assumptions for bubbly and annular flow regimes

    enumeration
        AREAMEAN             % Area-averaged velocity difference
        SCALED               % Scaled area-averaged velocity difference
        DRIFT                % Drift velocity model
        SIMPLE               % Simplified model for bubbly and annular flow
    end
end