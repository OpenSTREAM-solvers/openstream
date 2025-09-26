classdef WAVEFREQUENCY
%WAVEFREQUENCY Wave number density transport model
%
%   Defines the wave number density transport model. This equation is used
%   to solve for the wave number density (or wave frequency). 
%   Used by the four-field solver.
%
    enumeration
        EQUILIBRIUM          % Equilibrium model
        RELAXATION           % Full model with time relaxation approximation
    end

end