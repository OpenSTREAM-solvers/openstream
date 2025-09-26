classdef MOMENTWAVE
%MOMENTWAVE Film momentum conservation model
%
%   Defines the momentum conservation model for the wave field. This
%   equation is used to solve for the wave velocity.
%   Used by the four-field solver.
%
    enumeration
        ALGEBRAIC            % Simple algebraic model
        EQUILIBRIUM          % Equilibrium model
        FULL                 % Full non-equilibrium model
    end

end