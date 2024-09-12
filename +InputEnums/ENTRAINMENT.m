classdef ENTRAINMENT
%ENTRAINMENT Entrainment models
%   Defines which droplet entrainment mass flux model is used. 
%   NOTE: the entrainment and deposition correlations are coupled, i.e. the
%   same model should be used for both entrainment and deposotion mass flux
    enumeration
        GOVAN       %Hewitt and Govan (1990)
        OKAWA2003   %Okawa et al. (2003)
        OKAWA2004   % Okawa et al. (2004)
        USERDEF     % Following the model of Okawa et al. (2004), allows user defined thresholds and coefficients
    end
end
    
