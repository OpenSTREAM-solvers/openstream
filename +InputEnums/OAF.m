classdef OAF
%OAF Onset of annular flow model
%
%   Defines the model used to predict the onset of annular flow. 
%   Used by three-field and four-field solvers.
%
    enumeration
        WALLIS               % Full Wallis correlation (Equation 11.1019 in One-dimensional two-phase flow, 1969)
        WALLIS_SIMP          % Simplifed Wallis correlation (used when comparing against codes that use this approach)
    end

end