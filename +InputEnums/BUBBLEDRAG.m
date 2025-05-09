classdef BUBBLEDRAG
%BUBBLEDRAG Bubble drag model
%
%   Defines the model for the bubble drag coefficient.
%
%   Model used by the two-fluid solver.
%
    enumeration
        CONSTANT        % Specified (constant) 
        STOKES          % Stokes model
        VISCOUS         % Viscous model
        DISTORDED       % Distorded bubble model
    end
end
    
