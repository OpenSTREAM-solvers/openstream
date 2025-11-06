classdef TPHTM
    %TPHTM Enumeration of two-phase wall heat transfer models
    %
    % This class defines the available :attr:`Inputs.Model.TPHTM` models for
    % calculating the two-phase wall heat transfer, used by the mixture solver.
    %
    % Models:
    %
    % - THOM    — Thom wall heat transfer model (:cite:t:`Rohsenow1998`)

    enumeration
        THOM                  % Thom model
    end
end