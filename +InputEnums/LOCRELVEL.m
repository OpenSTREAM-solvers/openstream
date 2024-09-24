classdef LOCRELVEL
%LOCRELVEL Local relative velocity between liquid and vapor phase
% Defines the model for the local relative velocity
%
    enumeration
        AREAMEAN      % Assumes the difference between area averaged phase velocities
        SCALED        % Multiplies the difference between area averaged phase velocities with a input constant
        DRIFT         % Assumes drift velocity as local relative velocity
        SIMPLE        % Simple assumptions for bubbly and annular flow
    end
end
    
