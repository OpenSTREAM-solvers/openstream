classdef CBT
    %CBT Enumeration of Critical Boiling Transition (CBT) models
    %
    % This class defines the available :attr:`Inputs.Model.CBT` models for
    % evaluating the Critical Boiling Transition, used by the mixture field.
    %
    % Models:
    %
    % - NONE       — No CBT transition applied
    % - BIASI      — Biasi correlation model (:cite:t:`biasi1966burnout`)
    % - ELEVATION  — CBT determined from specified elevation using user-defined CBTELEVATION

    enumeration
        NONE                 % No Critical Boiling Transition
        BIASI                % Biasi model fro CBT prediction
        ELEVATION            % CBT based on user-defined elevation using :attr:`Inputs.Model.CBTELEVATION`
    end
end