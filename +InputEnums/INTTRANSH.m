classdef INTTRANSH
%INTTRANSH Interfacial enthalpy transfer
%
%   Defines the model used to calculate the phase enthalpy related to the
%   interfacial mass transfer.
%   Used by the mixture and two-fluid solvers.
%
    enumeration
        BULK                 % Bulk enthalpy
        SATURATED            % Saturated enthalpy
    end

end