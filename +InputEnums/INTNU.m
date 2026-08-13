classdef INTNU
    %INTNU Enumeration of interfacial Nusselt number models
    %
    % This class defines the available :attr:`Inputs.Model.INTNU` models
    % for calculating the interfacial Nusselt number, used by the two-fluid
    % solver.
    %
    % Models:
    %
    % - CONSTANT      — Assumes a constant Nusselt number using user-defined :attr:`Inputs.Model.INTNUVCST` and :attr:`Inputs.Model.INTNULCST` for the dispersed gas and liquid phases, respectively
    % - RANZMARSHALL  — Ranz-Marshall correlation-based model (:cite:t:`ranzmarshall1952`) using user-defined :attr:`Inputs.Model.RANZMARSHALLVCST` and :attr:`Inputs.Model.RANZMARSHALLLCST` for the dispersed gas and liquid phases, respectively
    % - RELAXATION    — Time relaxation-based model (:cite:t:`Walter2024`)

    enumeration
        CONSTANT             % Constant Nusselt number
        RANZMARSHALL         % Ranz-Marshall correlation
        RELAXATION           % Time relaxation model
    end
end