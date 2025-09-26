classdef MOMENTBASE
%MOMENTBASE Base film momentum conservation model
%
%   Defines the momentum conservation model for the base film. This
%   equation is used to solve for base film velocity.
%   Used by the four-field solver.
%
    enumeration
        ALGEBRAIC            % Simple algebraic model
        EQUILIBRIUM          % Equilibrium model
        EQUILIBRIUMS         % Equilibrium model based on simple force balance (Fwall + Fvapor = 0)
        FULL                 % Full non-equilibrium model
        FULLNOP              % Full non-equilibrium model without considering pressure terms (gravity and buoyancy)
    end

end