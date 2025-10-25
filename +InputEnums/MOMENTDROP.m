classdef MOMENTDROP
    %MOMENTDROP Enumeration of droplet momentum conservation models
    %
    %   This class defines the available models for solving the droplet
    %   momentum conservation equation, used to compute droplet velocity
    %   in the three-field and four-field solvers.
    %
    %   Models:
    %       ALGEBRAIC     - Simple algebraic model consistent with mixture solver
    %       SLIP          - Slip ratio model (droplet/gas velocity)
    %       EQUILIBRIUM   - Equilibrium model
    %       EQUILIBRIUMS  - Simplified equilibrium model based on force balance
    %                       (Fdrag + Fgravity + Fbuoyancy = 0)
    %       FULL          - Full non-equilibrium momentum model

    enumeration
        ALGEBRAIC            % Algebraic model consistent with mixture solver
        SLIP                 % Slip ratio model (droplet/gas velocity)
        EQUILIBRIUM          % Equilibrium momentum model
        EQUILIBRIUMS         % Simple force balance model
        FULL                 % Full non-equilibrium momentum model
    end
end