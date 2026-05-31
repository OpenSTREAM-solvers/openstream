classdef THERMALRELAX
    %THERMALRELAX Enumeration of MRM time relaxation models
    %
    % This class defines the available :attr:`Inputs.Model.THERMALRELAX`
    % models for calculating relaxation times in the MRM model, used when
    % :attr:`Inputs.Model.THERMALNONEQ` is set to `MRM`.
    %
    % Models:
    %
    % - FOURIERX    — Simple model relating the Fourier number to equilibrium quality using user-defined :attr:`Inputs.Model.RELAXX`, :attr:`Inputs.Model.RELAXCONDFO` and :attr:`Inputs.Model.RELAXEVAPFO`
    % - TIMEX       — Simple model relating relaxation time to equilibrium quality using user-defined :attr:`Inputs.Model.RELAXX`, :attr:`Inputs.Model.RELAXCONDT` and :attr:`Inputs.Model.RELAXTEVAPT`
    % - VOID        — Physical model simplified to Fourier number dependence on phase volumetric fraction and input characteristic length of the dispersed phase at CBT using user-defined :attr:`Inputs.Model.RELAXCONDCOEF` and :attr:`Inputs.Model.RELAXEVAPCOEF`
    % - HOMOGENEOUS — Physical model based on homogeneous assumptions and spherical dispersed phase
    % - FOURIER     — Empirical model based on Fourier number dependence on Reynolds number, etc, using user-defined :attr:`Inputs.Model.RELAXCONDFOCOEF` and :attr:`Inputs.Model.RELAXEVAPFOCOEF`

    enumeration
        FOURIERX             % Fourier number function of equilibrium quality
        TIMEX                % Relaxation time function of equilibrium quality
        VOID                 % Fourier number correlation function of phase volumetric fraction and dispersed phase length scale
        HOMOGENEOUS          % Homogeneous model
        FOURIER              % Fourier number correlation
    end
end