classdef DROPDRAG
    %DROPDRAG Enumeration of droplet drop drag coefficient models
    %
    % This class defines the available models for calculating the
    % droplet drag coefficient, used by the two-fluid solver.
    %
    % Models:
    %
    % - CONSTANT   — Constant drag coefficient using user-defined :attr:`Inputs.Model.DROPDRAGCOEF`
    % - STOKES     — Stokes flow regime model (:math:`\frac{24}{Re_{p}}`)
    % - VISCOUS    — Viscous regime model (:cite:t:`Walter2024`)
    % - DISTORTED  — Model for distorted (non-spherical) droplets (:cite:t:`Walter2024`)

    enumeration
        CONSTANT             % User-defined constant drag coefficient
        STOKES               % Stokes regime drag model
        VISCOUS              % Viscous regime drag model
        DISTORDED            % Distorted droplet drag model
    end
end