classdef DEPOSITION
    %DEPOSITION Enumeration of droplet deposition models
    %
    %   This class defines the available models for calculating the
    %   droplet deposition mass flux, used by the three-field and
    %   four-field solvers.
    %
    %   NOTE: Entrainment and deposition correlations are coupled.
    %   It is recommended to use the same model for both entrainment
    %   and deposition mass flux to ensure consistency.
    %
    %   Models:
    %       NONE    - No deposition applied
    %       GOVAN   - Hewitt and Govan correlation (1990)
    %       OKAWA   - Okawa et al. correlation (2003)

    enumeration
        NONE                 % No deposition
        GOVAN                % Hewitt and Govan (1990) deposition model
        OKAWA                % Okawa et al. (2003) deposition model
    end
end