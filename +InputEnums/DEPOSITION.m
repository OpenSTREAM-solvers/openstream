classdef DEPOSITION
%DEPOSITION Deposition models
%
%   Defines the model used to calculate the dropvdeposition mass flux.
%   Used by the three-field and four-fieldsolvers.
%
%   NOTE: the entrainment and deposition correlations are coupled, i.e., it
%   is recommended to use the same model for both entrainment and
%   deposition mass flux.
%
    enumeration
        NONE                 % No deposition
        GOVAN                % Hewitt and Govan (1990)
        OKAWA                % Okawa et al. (2003)
    end

end