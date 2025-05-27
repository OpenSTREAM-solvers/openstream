classdef THERMALNONEQ
%THERMAL Thermal non-equilibrium model
%
%   Defines the model used to calculate the phase thermal non-equilibrium
%   Used by the mixture solver
%
    enumeration
        EQUILIBRIUM          % Equilibrium model (X = XEQ)
        SAHAZUBER            % Saha-Zuber subcooled boiling model
        EPRI                 % EPRI subcooled boiling model
        RELAXATION           % Time relaxation subcooled boiling & post-CHF model
    end

end