classdef OAF
%OAF Onset of annular flow model
%  Defines the model to predict the position at which the onset of
%  annualr flow occurs based on local flow conditions. Wallis correlation 
% is Equation 11.1019  in One-dimensional two-phase flow. Wallis (1969).
% The correlation was built using air-water data.
    enumeration
        WALLIS % Full Wallis correlation
        WALLIS_SIMP % Simplifed Wallis correlation (Justification?)
    end
end
    
