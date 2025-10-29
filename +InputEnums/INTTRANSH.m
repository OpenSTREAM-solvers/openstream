classdef INTTRANSH
    %INTTRANSH Enumeration of interfacial enthalpy transfer models
    %
    % This class defines the available models for calculating the phase
    % enthalpy associated with interfacial mass transfer, used by the
    % mixture and two-fluid solvers.
    %
    % Models:
    %
    % - BULK       — Uses bulk phase enthalpy
    % - SATURATED  — Uses saturated phase enthalpy

    enumeration
        BULK                 % Bulk phase enthalpy
        SATURATED            % Saturated phase enthalpy
    end
end