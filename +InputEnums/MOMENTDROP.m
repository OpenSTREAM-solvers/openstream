classdef MOMENTDROP
%MOMENTDROP Drop momentum conservation model
%
%   Defines the momentum conservation model for the drops. This equation is
%   used to solve for drop velocity.
%   Used by the three-field and four-field solvers.
%
    enumeration
        ALGEBRAIC            % Simple algebraic model consistent with mixture solver
        SLIP                 % Slip ratio model(droplet/gas velocity)
        EQUILIBRIUM          % Equilibrium model
        EQUILIBRIUMS         % Equilibrium model based on simple force balance (Fdrag + Fgrav + Fbuoy = 0)
        FULL                 % Full non-equilibrium model
    end

end