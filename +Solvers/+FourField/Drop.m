classdef Drop < Solvers.ThreeField.Drop
    %DROP Class for modeling drop field in four-field solver
    %
    % This class encapsulates the physical and numerical properties of the drop field,
    % including flow variables and phase interactions.
    % It supports multiple solver models and provides methods for computing derived
    % quantities.
    %
    % All methods are inherited from :class:`Solvers.ThreeField.Drop`

    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})

    end

    properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)

    end

    methods

        % Inherit from Solvers.ThreeField.Drop
        % Add modifications here

    end

end

