classdef VOID
%VOID Void fraction model
%
%   Defines the model used to calculate the void fraction model.
%   Used by the mixture solver.
%
    enumeration
        HOMOGENEOUS          % Assumes vapor velocity = liquid velocity
        SLIP                 % Assumes a slip ratio (gas/liquid)
        BESTION              % Bestion drift-flux model
        EPRI                 % EPRI drift-flux model
    end

end