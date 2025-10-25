classdef DROPDRAG
    %DROPDRAG Enumeration of droplet drop drag coefficient models
    %
    %   This class defines the available models for calculating the
    %   droplet drag coefficient, used by the two-fluid solver.
    %
    %   Models:
    %       CONSTANT   - Constant drag coefficient using user-defined DROPDRAGCOEF
    %       STOKES     - Stokes flow regime model
    %       VISCOUS    - Viscous regime model
    %       DISTORTED  - Model for distorted (non-spherical) droplets

    enumeration
        CONSTANT             % User-defined constant drag coefficient
        STOKES               % Stokes regime drag model
        VISCOUS              % Viscous regime drag model
        DISTORDED            % Distorted droplet drag model
    end
end