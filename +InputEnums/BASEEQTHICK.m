classdef BASEEQTHICK
%BASEEQTHICK Base film equilibrium thickness model
%   Defines which base film equilibrium model to use
%
    enumeration
        RISO        % RISO dataset from Le Corre (2022)
        MFVAL       % MFVAL, in progress (20XX)
        COEFS       % Manually specified coeffients
        YPLUS
    end
end
    
