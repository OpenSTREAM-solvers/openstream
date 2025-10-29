classdef MOMENTLIQUID
    %MOMENTLIQUID Enumeration of liquid momentum conservation models
    %
    % This class defines the available models for solving the momentum
    % conservation equation for the liquid phase, used to compute liquid
    % velocity in the two-fluid solver.
    %
    % Models:
    % - MIXTURE  — Uses the same velocity as in the mixture model
    % - SLIP     — Slip ratio model (gas/liquid velocity) using user-defined SLIP
    % - FULL     — Full non-equilibrium momentum model

    enumeration
        MIXTURE              % Liquid velocity equal to mixture velocity
        SLIP                 % Slip ratio model (gas/liquid velocity) 
        FULL                 % Full non-equilibrium momentum model
    end
end