classdef TPKM
    %TPKM Enumeration of two-phase local loss multiplier models
    %
    %   This class defines the available models for calculating the two-phase
    %   local loss multiplier used by the mixture model
    %
    %   Models:
    %       HOMOGENEOUS - Assumes no slip between phases; both phases move at the same velocity.
    %       SLIP        - Accounts for velocity differences (slip) between liquid and vapor phases.
    %       ROMIE       - Romie model; behaves like the homogeneous model when a homogeneous void fraction model is applied.

    enumeration
        HOMOGENEOUS          % Homogeneous model
        SLIP                 % Slip flow model
        ROMIE                % Romie model
    end
end