classdef NEARWALLH
    %NEARWALLH Enumeration of near-wall equilibrium enthalpy models
    %
    % This class defines the available :attr:`Inputs.Model.NEARWALLH`
    % models for setting the near-wall enthalpy to mixture enthalpy ratio,
    % used by the mixture solvers.
    %
    % Models:
    %
    % - RATIO       — Constant near-wall enthalpy to mixture enthalpy ratio using user-defined :attr:`Inputs.Model.NEARWALLHRATIO`
    % - FILM        — Mass flux-dependent input for annular two-phase flow

    enumeration
        RATIO                % Constant ratio model 
        FILM                 % Mass flux-dependent input for annular two-phase flow
    end
end