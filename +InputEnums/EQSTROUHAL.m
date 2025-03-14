classdef EQSTROUHAL
%EQSTROUHAL Equilibrium Strouhal number
%   Defines which base film equilibrium model to use
%
    enumeration
        RISO        % RISO dataset from Le Corre (2022)
        SAWAI       % SAWAI dataset from Le Corre (2022)
        MFVAL       % MFVAL, in progress (20XX)
        CUSTOM      % Custom option using EQSTROUHALCOEF
    end
end
    
