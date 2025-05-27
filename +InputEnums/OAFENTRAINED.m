classdef OAFENTRAINED
%OAFENTRAINED Entrained drop model at onset of annular flow
%
%   Defines the model used to calculate the drop mass flow rate at the
%   onset of annular flow.
%   Used by the three-field and four-field solvers.
%
    enumeration
        RATIO                % Ratio (drop/liquid mass flow rates)
        EQUILIBRIUM          % Equilibrium assumption model (Ment = Mdep)
    end

end