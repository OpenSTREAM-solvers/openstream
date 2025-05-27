classdef DROPDRAG
%DROPDRAG drop drag model
%
%   Defines the model used to calculate the drop drag coefficient.
%   Used by the two-fluid solver.
%
    enumeration
        CONSTANT             % Specified (constant) 
        STOKES               % Stokes model
        VISCOUS              % Viscous model
        DISTORDED            % Distorded drop model
    end

end