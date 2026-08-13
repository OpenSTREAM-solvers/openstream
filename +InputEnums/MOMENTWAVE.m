classdef MOMENTWAVE
    %MOMENTWAVE Enumeration of film momentum conservation models
    %
    % This class defines the available :attr:`Inputs.Model.MOMENTWAVE` models
    % for solving the momentum conservation equation for the wave field, used
    % to compute wave velocity in the four-field solver.
    %
    % Models:
    %
    % - ALGEBRAIC    — Simple algebraic model (:cite:t:`ADAMSSON2014316`, Equations 21 or 23)
    % - EQUILIBRIUM  — Equilibrium model
    % - FULL         — Full non-equilibrium momentum model (:cite:t:`LECORREMODEL`)

    enumeration
        ALGEBRAIC            % Algebraic momentum model
        EQUILIBRIUM          % Equilibrium momentum model
        FULL                 % Full non-equilibrium momentum model
    end
end