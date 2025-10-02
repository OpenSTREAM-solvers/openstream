classdef THERMALRELAX
%THERMALRELAX Thermal non-equilibrium time relaxation model
%
%   Defines the thermal non-equilibrium time relaxation model used when
%   THERMALNONEQ is set to 'RELAXATION'
%
    enumeration
        QUALITY              % Simple model relating time condensation to equilibrium quality
        VOID                 % Physical model based on phase volumetric fraction
    end

end