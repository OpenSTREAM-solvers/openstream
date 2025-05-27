classdef EQSTROUHAL
%EQSTROUHAL Equilibrium Strouhal number
%
%   Defines the model used to calculate the wave equilibrium Strouhal
%   number.
%   Used by the four-field solver.
%
    enumeration
        RISO                 % RISO dataset from Le Corre (2022)
        SAWAI                % SAWAI dataset from Le Corre (2022)
        MFVAL                % MFVAL, in progress (20XX)
        CUSTOM               % Custom option using EQSTROUHALCOEF
    end

end