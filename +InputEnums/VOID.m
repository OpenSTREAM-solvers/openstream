classdef VOID
    %VOID Enumeration of void fraction models
    %
    % This class defines the models used to calculate the void fraction in the
    % mixture solver.
    %
    % Models:
    % - HOMOGENEOUS — Assumes vapor and liquid phases move at the same velocity.
    % - SLIP        — Assumes a slip ratio between vapor and liquid phases using user-defined SLIP.
    % - BESTION     — Drift-flux model developed by Bestion.
    % - EPRI        — Drift-flux model developed by the Electric Power Research Institute (EPRI).

    enumeration
        HOMOGENEOUS          % Homogeneous flow model (vapor velocity = liquid velocity)
        SLIP                 % Slip flow model (gas/liquid velocity ratio)
        BESTION              % Bestion drift-flux model
        EPRI                 % EPRI drift-flux model
    end
end