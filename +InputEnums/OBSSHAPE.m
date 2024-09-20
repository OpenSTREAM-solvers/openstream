classdef OBSSHAPE
%BASEEQTHICK Obstruction shape
%   Defines the general geometrical shape of the obstruction. Currently,
%   this only affects the visual effects in the output plots, and does not
%   affect flow calculations as the nearby flow field is over-simplified.
%
    enumeration
        CIRCLE
        TRIANGLE
        DIAMOND
        SQUARE
        CUSTOM
    end
end
    
