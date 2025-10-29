classdef WAVEFREQUENCY
    %WAVEFREQUENCY Enumeration of wave number density transport models
    %
    % This class defines the models used to solve the wave number density (or
    % wave frequency) transport equation, used in the four-field solver.
    %
    % Models:
    % - EQUILIBRIUM  — Assumes instantaneous equilibrium between wave generation and dissipation.
    % - RELAXATION   — Full transport model including time relaxation effects set by user-defined RELAXTW

    enumeration
        EQUILIBRIUM          % Equilibrium model (instantaneous wave number density adjustment)
        RELAXATION           % Time relaxation model
    end
end