classdef THERMALRELAX
    %THERMALRELAX Enumeration of MRM time relaxation models
    %
    % This class defines the available :attr:`Inputs.Model.THERMALRELAX`
    % models for calculating relaxation times in the MRM model, used when
    % :attr:`Inputs.Model.THERMALNONEQ` is set to `MRM`.
    %
    % Models:
    %
    % - TIMEX          — Simple model relating relaxation time to equilibrium quality using user-defined :attr:`Inputs.Model.TRELAXX`, :attr:`Inputs.Model.TRELAXTCOND` and :attr:`Inputs.Model.TRELAXTEVAP`
    % - FOURIERX       — Simple model relating the Fourier number to equilibrium quality using user-defined :attr:`Inputs.Model.TRELAXX`, :attr:`Inputs.Model.TRELAXFOCOND` and :attr:`Inputs.Model.TRELAXFOEVAP`
    % - HOMOGENEOUS    — Physical model based on homogeneous assumptions and spherical dispersed phase
    % - NONHOMOGENEOUS — Physical model based on non-homogeneous (i.e., uses the calculated phase velocity slip) assumptions and spherical dispersed phase
    % - VOID           — Physical model simplified to Fourier number dependence on phase volumetric fraction and input characteristic length of the dispersed phase at CBT using user-defined :attr:`Inputs.Model.TRELAXCONDCOEF` and :attr:`Inputs.Model.TRELAXEVAPCOEF`
    % - FOURIER        — Empirical model

    enumeration
        TIMEX                % Relaxation time function of equilibrium quality
        FOURIERX             % Fourier number function of equilibrium quality
        HOMOGENEOUS          % Homogeneous model
        NONHOMOGENEOUS       % Non-homogeneous model
        VOID                 % Fourier number correlation function of phase volumetric fraction and dispersed phase length scale
        FOURIER              % Fourier number correlation
    end
end