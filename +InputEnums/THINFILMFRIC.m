classdef THINFILMFRIC
    %THINFILMFRIC Enumeration of thin film friction models
    %
    %   This class defines the available models for calculating wall friction
    %   under thin film conditions, used by the three-field and four-field solvers.
    %
    %   Models:
    %       - LAMINAR   — Laminar flow model (16/Ref)
    %       - TURBULENT — Turbulent flow model

    enumeration
        LAMINAR              % Laminar thin film friction model
        TURBULENT            % Turbulent thin film friction model
    end
end