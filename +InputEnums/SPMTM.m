classdef SPMTM
    %SPMTM Enumeration of single-phase wall momentum transfer models
    %
    % This class defines the available :attr:`Inputs.Model.SPMTM` models for
    % calculating the single-phase wall momentum transfer (liquid or gas), used
    % by the mixture solver.
    %
    % Models:
    %
    % - BLASIUS — Blasius wall momentum transfer model (:math:`f = C(1) Re^{C(2)} + C(3)`) using user-defined :attr:`Inputs.Model.FRICTION` coefficients

    enumeration
        BLASIUS        % Blasius model
    end
end