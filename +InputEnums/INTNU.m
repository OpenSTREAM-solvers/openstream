classdef INTNU
%INTNU Interfacial Nusselt number
%
%   Defines the model used to calculate the interfacial Nusselt number.
%   Used by the two-fluid solver.
%
    enumeration
        CONSTANT             % Constant Nu
        RANZMARSHALL         % Ranz-Marshall model
        RELAXATION           % Time relaxation model
    end

end