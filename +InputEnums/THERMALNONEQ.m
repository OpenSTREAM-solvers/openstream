classdef THERMALNONEQ
%THERMAL Thermal non-equilibrium model
%   Detailed explanation goes here
    enumeration
        EQUILIBRIUM % Equilibrium model
        SAHAZUBER   % Saha-Zuber subcooled boiling
        EPRI        % EPRI subcooled boiling
        RELAXATION  % Time relaxation subcooled boiling & post-CHF model
    end
end
    
