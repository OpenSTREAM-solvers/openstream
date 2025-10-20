classdef CBT
%CBT Critical Boiling Transition model
%
%   Defines the model used to evaluate the Critical Boilign Transition.
%   Used by the mixture solver.
%
    enumeration
        NONE                 % No CBT transition
        BIASI                % Biasi model
        LUT2006              % Groeneveld 2006 LUT
    end

end