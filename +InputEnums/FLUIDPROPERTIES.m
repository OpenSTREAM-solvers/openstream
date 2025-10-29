classdef FLUIDPROPERTIES
    %FLUIDPROPERTIES Enumeration of fluid property calculation assumptions
    %
    % This class defines the assumptions used to calculate fluid
    % properties, applicable to all solvers.
    %
    % Models:
    % - SATURATED  — Properties based on saturated conditions at system pressure
    % - PSYSTEM    — Properties based on system pressure and local phase enthalpy

    enumeration
        SATURATED            % Saturated fluid properties (at system pressure)
        PSYSTEM              % Properties from system pressure and local phase enthalpy
    end
end