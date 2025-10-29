classdef THERMALRELAX
    %THERMALRELAX Enumeration of thermal non-equilibrium time relaxation models
    %
    % This class defines the available models for calculating thermal
    % non-equilibrium time relaxation, used when THERMALNONEQ is set to RELAXATION.
    %
    % Models:
    %
    % - QUALITY  — Simple model relating relaxation time to equilibrium quality using user-defined RELAXX, RELAXTCOND and RELAXTEVAP
    % - VOID     — Physical model based on phase volumetric fraction using user-defined RELAXCONDCOEF and RELAXEVAPCOEF

    enumeration
        QUALITY              % Relaxation time function of equilibrium quality
        VOID                 % Relaxation time based on phase volumetric fraction
    end
end