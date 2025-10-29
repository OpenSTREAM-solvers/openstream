classdef MOMENTWAVE
    %MOMENTWAVE Enumeration of film momentum conservation models
    %
    % This class defines the available models for solving the momentum
    % conservation equation for the wave field, used to compute wave velocity
    % in the four-field solver.
    %
    % Models:
    % - ALGEBRAIC    — Simple algebraic model
    % - EQUILIBRIUM  — Equilibrium model
    % - FULL         — Full non-equilibrium momentum model

    enumeration
        ALGEBRAIC            % Algebraic momentum model
        EQUILIBRIUM          % Equilibrium momentum model
        FULL                 % Full non-equilibrium momentum model
    end
end