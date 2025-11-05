classdef BUBBLEDRAG
    %BUBBLEDRAG Enumeration of bubble drag coefficient models
    %
    % This class defines the available models for calculating the
    % bubble drag coefficient, used by the two-fluid solver.
    %
    % Models:
    %
    % - CONSTANT   — Constant drag coefficient using user-defined :attr:`Inputs.Model.BUBBLEDRAGCOEF`
    % - STOKES     — Stokes flow regime model (:math:`\frac{24}{Re_{p}}`)
    % - VISCOUS    — Viscous regime model (:cite:t:`Walter2024`)
    % - DISTORTED  — Model for distorted bubbles (non-spherical) (:cite:t:`Walter2024`)

    enumeration
        CONSTANT             % User-defined constant drag coefficient 
        STOKES               % Stokes regime drag model
        VISCOUS              % Viscous regime drag model
        DISTORDED            % Distorted bubble drag model
    end
end