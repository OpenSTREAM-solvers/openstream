classdef OAFENTRAINED
    %OAFENTRAINED Enumeration of entrained drop models at onset of annular flow
    %
    %   This class defines the available models for splitting the droplet
    %   and film mass flow rates at the onset of annular flow, used by the
    %   three-field and four-field solvers.
    %
    %   Models:
    %       RATIO       - Ratio of droplet to liquid mass flow rates using
    %                     user-defined OAFDROPRATIO
    %       EQUILIBRIUM - Equilibrium assumption model (Ment = Mdep)

    enumeration
        RATIO                % Ratio model (drop/liquid mass flow rates)
        EQUILIBRIUM          % Equilibrium model (Ment = Mdep)
    end
end