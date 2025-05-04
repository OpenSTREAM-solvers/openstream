classdef FLUIDPROPERTIES
%FLUIDPROPERTIES Fluid property calculation assumptions
%   Defines the pressure to be used for calculating fluid properties
    enumeration
        SATURATED   % Assuming P = P_sat for the entirety of the flow channel
        PSYSTEM     % Considers the pressure change along the flow channel
    end
end
    
