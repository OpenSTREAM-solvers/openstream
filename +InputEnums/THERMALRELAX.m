classdef THERMALRELAX
    %THERMALRELAX Enumeration of HRM time relaxation models
    %
    % This class defines the available :attr:`Inputs.Model.THERMALRELAX`
    % models for calculating relaxation times in the HRM model, used when
    % :attr:`Inputs.Model.THERMALNONEQ` is set to `HRM`.
    %
    % Models:
    %
    % - QUALITY  — Simple model relating relaxation time to equilibrium quality using user-defined :attr:`Inputs.Model.TRELAXX`, :attr:`Inputs.Model.TRELAXTCOND` and :attr:`Inputs.Model.TRELAXTEVAP`
    % - VOID     — Physical model based on phase volumetric fraction using user-defined :attr:`Inputs.Model.TRELAXCONDCOEF` and :attr:`Inputs.Model.TRELAXEVAPCOEF`

    enumeration
        QUALITY              % Relaxation time function of equilibrium quality
        VOID                 % Relaxation time based on phase volumetric fraction
    end
end