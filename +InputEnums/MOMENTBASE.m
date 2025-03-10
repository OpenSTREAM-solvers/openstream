classdef MOMENTBASE
%MOMENTBASE Base film momentum conservation model
%   Defines the type of momentum conservation used on the base film. These
%   momentum conservation equations are used to solve for  base film velocity
    enumeration
        ALGEBRAIC  % Consistent with mixture model (tau_wall = tau_f_wall)
        EQUILIBRIUM % (tau_int = tau_wall)
        EQUILIBRIUMS 
        FULL 
        FULLNOP
    end
end
    
