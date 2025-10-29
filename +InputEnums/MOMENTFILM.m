classdef MOMENTFILM
    %MOMENTFILM Enumeration of film momentum conservation models
    %
    % This class defines the available models for solving the momentum
    % conservation equation for the liquid film, used to compute film
    % velocity in the three-field solver.
    %
    % Models:
    % - ALGEBRAIC     — Simple algebraic model
    % - EQUILIBRIUM   — Equilibrium model
    % - EQUILIBRIUMS  — Simplified equilibrium model based on force balance (:math:`F_{\mathrm{wall}} + F_{\mathrm{vapor}} = 0')
    % - FULL          — Full non-equilibrium momentum model

    enumeration
        ALGEBRAIC            % Algebraic momentum model
        EQUILIBRIUM          % Equilibrium momentum model
        EQUILIBRIUMS         % Simplified force balance model (Fwall + Fvapor = 0)
        FULL                 % Full non-equilibrium momentum model
    end

end