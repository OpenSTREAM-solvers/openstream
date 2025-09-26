classdef MOMENTLIQUID
%MOMENTLIQUID Liquid momentum conservation model
%
%   Defines the conservation model for the liquid phase. This equation si
%   used to solve for the liquid velocity.
%   Used by the two-fluid model.
%
    enumeration
        MIXTURE              % Same gas velocity as for the mixture model
        SLIP                 % Slip ratio model (gas/liquid velocity) 
        FULL                 % Full non-equilibrium model
    end

end