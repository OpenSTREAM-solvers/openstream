classdef MOMENTWAVE
%MOMENTWAVE Film momentum conservation model
%   Defines the type of momentum conservation used on the wave field. These
%   momentum conservation equations are used to solve for wave velocity
    enumeration
        ALGEBRAIC  % Consistent with mixture model (tau_wall = tau_f_wall)
        EQUILIBRIUM % (tau_int = tau_wall)
        FULL 
    end
end
    
