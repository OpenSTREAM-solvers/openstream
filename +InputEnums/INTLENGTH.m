classdef INTLENGTH
    %INTLENGTH Enumeration of interfacial length scale models
    %
    % This class defines the available :attr:`Inputs.Model.INTLENGTH`
    % models for calculating the interfacial length scale, used by the
    % two-fluid solver.
    %
    % Models:
    %
    % - CONSTANT  — Assumes a constant interfacial length scale using user-defined :attr:`Inputs.Model.INTLENGTHVCST` and :attr:`Inputs.Model.INTLENGTHLCST` for the dispersed gas and liquid phases, respectively

    enumeration
        CONSTANT           % Constant interfacial length scale
    end
end