classdef MOMENTGAS
    %MOMENTGAS Enumeration of gas momentum conservation models
    %
    % This class defines the available :attr:`Inputs.Model.MOMENTGAS` models
    % for solving the momentum conservation equation for the gas phase, used
    % to compute gas velocity in the two-fluid solver.
    %
    % Models:
    %
    % - MIXTURE  — Uses the same gas velocity as in the mixture model
    % - SLIP     — Slip ratio model (gas/liquid velocity) using% user-defined :attr:`Inputs.Model.SLIP`
    % - FULL     — Full non-equilibrium momentum model (:cite:t:`LeCorre2025OpenSTREAM`, :cite:t:`Walter2024`)

    enumeration
        MIXTURE              % Gas velocity equal the mixture velocity
        SLIP                 % Slip ratio model (gas/liquid velocity) 
        FULL                 % Full non-equilibrium momentum model
    end
end