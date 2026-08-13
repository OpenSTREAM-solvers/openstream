classdef OAFFILMSPLIT
    %OAFFILMSPLIT Enumeration of film mass flow ratio models at onset of annular flow
    %
    % This class defines the available :attr:`Inputs.Model.OAFFILMSPLIT`
    % models for splitting the base film and wave mass flow rates at the
    % onset of annular flow, used by the four-field solver.
    %
    % Models:
    %
    % - RATIO        — Ratio of base film to film mass flow rates using user-defined :attr:`Inputs.Model.OAFBASERATIO`
    % - EQUILIBRIUM  — Equilibrium model (film thickness = equilibrium film thickness) (:cite:t:`LECORREMODEL`)

    enumeration
        RATIO                % Ratio model (base/film mass flow rates)
        EQUILIBRIUM          % Equilibrium model (Film thickness = Equilibrium film thickness)
    end
end