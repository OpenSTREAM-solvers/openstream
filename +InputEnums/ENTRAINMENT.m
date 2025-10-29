classdef ENTRAINMENT
    %ENTRAINMENT Enumeration of droplet entrainment models
    %
    % This class defines the available models for calculating the
    % droplet entrainment mass flux, used by the three-field and
    % four-field solvers.
    %
    % NOTE: Entrainment and deposition correlations are coupled.
    % It is recommended to use the same model for both entrainment
    % and deposition mass flux to ensure consistency.
    %
    % Models:
    % - NONE          — No entrainment
    % - GOVAN         — Hewitt and Govan correlation (1990)
    % - OKAWA2003     — Okawa et al. correlation (2003)
    % - OKAWA2004     — Okawa et al. correlation (2004)
    % - OKAWA2004MOD  — Modified Okawa (2004) model from Adamsson & Le Corre (2011)
    % - OKAWAGEN      — Generic Okawa-based model using user-defined OKAWACOEFS

    enumeration
        NONE                 % No entrainment
        GOVAN                % Hewitt and Govan (1990) entrainment model
        OKAWA2003            % Okawa et al. (2003) entrainment model
        OKAWA2004            % Okawa et al. (2004) entrainment model
        OKAWA2004MOD         % Modified Okawa et al. (2004) model (from Adamsson and Le Corre, 2011)
        OKAWAGEN             % Generic Okawa-based entrainment model using OKAWACOEFS
    end
end