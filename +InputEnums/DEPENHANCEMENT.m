classdef DEPENHANCEMENT
    %DEPENHANCEMENT Enumeration of droplet deposition enhancement models
    %
    % This class defines the available models for calculating local droplet
    % deposition enhancement, used by the three-field and four-field solvers.
    %
    % Models:
    %
    % - NONE       — No enhancement applied
    % - WINDECKER  — Model adapted from :cite:t:`windecker1999`, as documented in :cite:t:`LECORRE2024113613`, using user defined :attr:`Inputs.Model.KTUNING`

    enumeration
        NONE                 % No deposition enhancement
        WINDECKER            % Windecker-based enhancement model (Le Corre, 2024)
    end
end