classdef TPKM
%TPKM Two-phase local loss multiplier
%
%   Detailed explanation goes here
%   Used by the mixture model.
%
    enumeration
        HOMOGENEOUS          % Homogeneous model
        SLIP                 % Phase velocity slip model
        ROMIE                % Romie model (equivalent to homogeneous model when homogeneous void fraction model is used)
    end

end