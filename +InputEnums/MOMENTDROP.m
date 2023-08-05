classdef MOMENTDROP
%MOMENTDROP Drop momentum conservation model
%   This defines the type of conservation model used on the droplets in
%   the Drop class. 
    enumeration
        ALGEBRAIC
        SLIP % ratio between droplet velocity and vapor core
        EQUILIBRIUMS % considers only core drops
        EQUILIBRIUM % takes into account low-velocity drops
        FULL % considers inertial terms, need to accelerate slow drops
    end
end
    
