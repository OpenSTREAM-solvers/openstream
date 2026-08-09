classdef MRMTIMEINT
    %MRMTIMEINT Enumeration of time integration options for the MRM vapor mass/energy conservation equations
    %
    % This class defines the available :attr:`Inputs.Options.MRMTIMEINT` options
    % for solving the vapor mass and energy conservation equations when using
    % the MRM model in the mixture solver.
    %
    % Models:
    %
    % - EULER       — Backward Euler
    % - EXPONENTIAL — Exponential

    enumeration
        EULER              % Backward Euler
        EXPONENTIAL        % Exponential 
    end
end