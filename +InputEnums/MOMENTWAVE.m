classdef MOMENTWAVE
%MOMENTWAVE Film momentum conservation model
%   Defines the type of momentum conservation used on the liquid film. The
%   conservation equations are used to solve for liquid-film velocity
    enumeration
        ALGEBRAIC  % Consistent with mixture model (tau_wall = tau_f_wall)
        EQUILIBRIUM % (tau_int = tau_wall)
        EQUILIBRIUMS 
        FULL 
    end
end
    
