classdef THERMALNONEQ
    %THERMALNONEQ Enumeration of thermal non-equilibrium models
    %
    % This class defines the available :attr:`Inputs.Model.THERMALNONEQ`
    % models for calculating phase thermal non-equilibrium effects, used by
    % the mixture solver.
    %
    % Models:
    %
    % - EQUILIBRIUM  — Assumes thermal equilibrium (:math:`X = \max(0, X_{EQ})`)
    % - SAHAZUBER    — Saha-Zuber subcooled boiling model (:cite:t:`sahazuber1973`)
    % - EPRI         — EPRI subcooled boiling model (:cite:t:`lellouche1982`)
    % - MRM          — Homogeneous Relaxation Model for subcooled boiling and post-CHF conditions (MRM)

    enumeration
        EQUILIBRIUM          % Equilibrium model (X = max(0,XEQ))
        SAHAZUBER            % Saha-Zuber subcooled boiling model
        EPRI                 % EPRI subcooled boiling model
        MRM                  % Homogeneous Relaxation Model (subcooled boiling & post-CHF)
    end
end