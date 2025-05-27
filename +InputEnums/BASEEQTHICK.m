classdef BASEEQTHICK
%BASEEQTHICK Base film equilibrium thickness model
%
%   Defines the model used to calculate the equilibrium base film  thickness.
%   Used by the four-field solver.
%
    enumeration
        RISO                 % Model based on RISO dataset from Le Corre (2022)
        COEFS                % Generalized form of RISO model, with specified coefficients
        YPLUS                % Model based on specified y+
        MFVAL                % MFVAL, in progress (20XX)
    end

end