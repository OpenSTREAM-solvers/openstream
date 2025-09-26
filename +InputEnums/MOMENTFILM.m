classdef MOMENTFILM
%MOMENTFILM Film momentum conservation model
%
%   Defines momentum conservation model for the liquid film. This equation
%   is used to solve for the liquid film velocity.
%   Used by the three-field solver.
%
    enumeration
        ALGEBRAIC            % Simple algebraic model
        EQUILIBRIUM          % Equilibrium model
        EQUILIBRIUMS         % Equilibrium model based on simple force balance (Fwall + Fvapor = 0)
        FULL                 % Full non-equilibrium model
    end

end