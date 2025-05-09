classdef BASEEQTHICK
%BASEEQTHICK Base film equilibrium thickness model
%
%   Defines which base film equilibrium thickness model to use,
%   driving the mass transfer between base film and waves.
%
%   Model used by the four-field solver.
%
    enumeration
        RISO            % Model based on RISO dataset from Le Corre (2022)
        COEFS           % Same model form as RISO, with specified coeffients
        YPLUS           % Model based on specified y+
        MFVAL           % MFVAL, in progress (20XX)
    end
end
    
