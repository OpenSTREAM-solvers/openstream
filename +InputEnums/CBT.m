classdef CBT
    %CBT Enumeration of Critical Boiling Transition (CBT) models
    %
    %   This class defines the available models for evaluating the
    %   Critical Boiling Transition, used by the mixture field.
    %
    %   Models:
    %       NONE       - No CBT transition applied
    %       BIASI      - Biasi correlation model
    %       ELEVATION  - CBT determined from specified elevation using
    %                    user-defined CBTELEVATION

    enumeration
        NONE                 % No Critical Boiling Transition
        BIASI                % Biasi model fro CBT prediction
        ELEVATION            % CBT based on specified elevation (CBTELEVATION)
    end
end