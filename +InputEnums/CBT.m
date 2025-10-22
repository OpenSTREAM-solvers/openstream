classdef CBT
%CBT Critical Boiling Transition model
%
%   Defines the model used to evaluate the Critical Boilign Transition.
%   Used by the mixture solver.
%
    enumeration
        NONE                 % No CBT transition
        BIASI                % Biasi model
        ELEVATION            % CBT from given elevation
    end

end