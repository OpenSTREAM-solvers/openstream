classdef BUBBLEDRAG
%BUBBLEDRAG Bubble drag model
%
%   Defines the model used to calculate the bubble drag coefficient.
%   Used by the two-fluid solver.
%
    enumeration
        CONSTANT             % Specified (constant) 
        STOKES               % Stokes model
        VISCOUS              % Viscous model
        DISTORDED            % Distorded bubble model
    end

end