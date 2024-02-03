classdef DEPOSITION
%DEPOSITION Deposition models
%   Defines which droplet deposition mass flux model is used. 
%   NOTE: the entrainment and deposition correlations are coupled, i.e. the
%   same model should be used for both entrainment and deposotion mass flux
    enumeration
        GOVAN  %Hewitt and Govan (1990)
        OKAWA %Okawa et al. (2003)
    end
end
    
