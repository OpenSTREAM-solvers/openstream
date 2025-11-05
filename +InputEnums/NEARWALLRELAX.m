classdef NEARWALLRELAX
    %NEARWALLRELAX Enumeration of near-wall energy transfer time relaxation models
    %
    % This class defines the available models for calculating the
    % near-wall energy transfer time relaxation, used in mixture solver.
    %
    % Models:
    %
    % - QUALITY — Simple model relating relaxation time to equilibrium quality using user-defined :attr:`Inputs.Model.NEARWALLRELAXX` and :attr:`Inputs.Model.NEARWALLRELAXT`
    % - VOID    — Physical model based on local phase volumetric fraction using user-defined :attr:`Inputs.Model.NEARWALLRELAXCOEF`

    enumeration
        QUALITY              % Relaxation time function of equilibrium quality
        VOID                 % Relaxation time based on phase volumetric fraction
    end
end