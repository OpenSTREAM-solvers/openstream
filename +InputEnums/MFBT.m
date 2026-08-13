classdef MFBT
    %MFBT Enumeration of Minimum Film Boiling Transition (MFBT) models
    %
    % This class defines the available :attr:`Inputs.Model.MFBT` models for
    % evaluating the Minimum Film Boiling Transition, used by the mixture
    % solver.
    %
    % Models:
    %
    % - NONE     — No MFBT transition applied
    % - CONSTANT — Constant deviation from the saturation temperature using user-defined :attr:`Inputs.Model.DTMFB`

    enumeration
        NONE                 % No MFBT transition
        CONSTANT             % Constant deviation from saturation
    end
end