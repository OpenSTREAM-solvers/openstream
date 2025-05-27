classdef MOMENTGAS
%MOMENTGAS Gas momentum conservation model
%
%  Defines the conservation model for the gas phase. This equation is use
%  to solve for the gas velocity.
%  Used by the two-fluid solver.
%
    enumeration
        MIXTURE              % Same gas velocity as for the mixture model
        SLIP                 % Slip ratio model (gas/liquid velocity) 
        FULL                 % Full non-equilibrium model
    end

end