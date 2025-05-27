classdef DEPENHANCEMENT
%DEPENHANCEMENT Deposition enhancement models
%
%   Defines the model used to calculate the droplet deposition enhancement.
%   Used by the three-field and four-field solvers.
%
    enumeration
        NONE                 % No enhancement
        WINDECKER            % Model adapted from Windecker (1999) documented in Le Corre (2024)
    end

end