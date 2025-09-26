classdef TPFM
%TPFM Two-phase wall friction multiplier
%
%   Defines the model used to calculate the two-phase wall friction
%   multiplier.
%   Used by the mixture solver.
%
    enumeration
        HOMOGENEOUS          % Homogeneous model
        SLIP                 % Phase velocity slip model
        EPRI                 % EPRI model
    end

end