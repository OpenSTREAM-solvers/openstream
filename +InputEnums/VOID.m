classdef VOID
%VOID Void fraction model
%   This defines the type of void fraction model used. The homogenous model
%   assumes the velocity of the fields is the same. The slip model assigns
%   a slip ratio. The Bestion model is a correlation. 
    enumeration
        HOMOGENEOUS % Assumes vapor velocity = liquid velocity
        SLIP    % Drift-flux model. Assumes a slip ratio
        BESTION 
    end
end
    
