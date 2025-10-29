classdef MOMENTBASE
    %MOMENTBASE Enumeration of base film momentum conservation models
    %
    % This class defines the available models for solving the base film
    % momentum conservation equation, used to compute the base film velocity
    % in the four-field solver.
    %
    % Models:
    % - ALGEBRAIC     — Simple algebraic model
    % - EQUILIBRIUM   — Equilibrium model
    % - EQUILIBRIUMS  — Simplified equilibrium model based on force balance (:math:`F_{\mathrm{wall}} + F_{\mathrm{vapor}} = 0`)
    % - FULL          — Full non-equilibrium model
    % - FULLNOP       — Full non-equilibrium model excluding pressure terms (gravity and buoyancy)

    enumeration
        ALGEBRAIC            % Simple algebraic momentum model
        EQUILIBRIUM          % Equilibrium momentum model
        EQUILIBRIUMS         % Simplified force balance model (Fwall + Fvapor = 0)
        FULL                 % Full non-equilibrium momentum model
        FULLNOP              % Full non-equilibrium momentum model without pressure terms
    end
end