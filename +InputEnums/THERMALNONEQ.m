classdef THERMALNONEQ
    %THERMALNONEQ Enumeration of thermal non-equilibrium models
    %
    % This class defines the available models for calculating phase thermal
    % non-equilibrium effects, used by the mixture solver.
    %
    % Models:
    %
    % - EQUILIBRIUM  — Assumes thermal equilibrium (:math:`X = \max(0, X_{EQ})`)
    % - SAHAZUBER    — Saha-Zuber subcooled boiling model (:cite:t:`sahazuber1973`)
    % - EPRI         — EPRI subcooled boiling model (:cite:t:`lellouche1982`)
    % - RELAXATION   — Time relaxation model for subcooled boiling and post-CHF conditions

    enumeration
        EQUILIBRIUM          % Equilibrium model (X = max(0,XEQ))
        SAHAZUBER            % Saha-Zuber subcooled boiling model
        EPRI                 % EPRI subcooled boiling model
        RELAXATION           % Time relaxation (subcooled boiling & post-CHF)
    end
end