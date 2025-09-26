classdef THINFILMFRIC
%THINFILMFRIC Thin film friction model
%
%   Defines the model to be used to calculate the film wall friction under
%   thin film conditions.
%   Used by the three-field and four-field solvers.
%
    enumeration
        LAMINAR              % Laminar model (16/Ref)
        TURBULENT            % Turbulent model
    end

end