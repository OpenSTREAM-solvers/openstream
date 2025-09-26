classdef ENTRAINMENT
%ENTRAINMENT Entrainment models
%
%   Defines the model used to calculate the drop entrainment mass flux.
%   Used by the three-field and four-fieldsolvers.
%
%   NOTE: the entrainment and deposition correlations are coupled, i.e., it
%   is recommended to use the same model for both entrainment and
%   deposition mass flux.
%
    enumeration
        NONE                 % No entrainment
        GOVAN                % Hewitt and Govan (1990)
        OKAWA2003            % Okawa et al. (2003)
        OKAWA2004            % Okawa et al. (2004)
        OKAWA2004MOD         % Modified Okawa et al. (2004) from Adamsson and Le Corre (2011)
        OKAWAGEN             % Generic Okawa model
    end

end