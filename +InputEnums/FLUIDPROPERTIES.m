classdef FLUIDPROPERTIES
%FLUIDPROPERTIES Fluid property calculation assumptions
%
%   Defines the input parameters used to calculate the fluid properties.
%   Used by all solvers.
%
    enumeration
        SATURATED            % Properties based on saturated assumption (at system pressure)
        PSYSTEM              % Properties based on system pressure and local phase enthalpy
    end

end