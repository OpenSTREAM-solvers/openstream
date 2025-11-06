classdef BTHTM
    %BTHTM Enumeration of post-boiling transition wall heat transfer models
    %
    % This class defines the available :attr:`Inputs.Model.BTHTM` models for
    % calculating the post-boiling transition wall heat transfer, used by the
    % mixture solver.
    %
    % Models:
    %
    % - VAPOR — Wall heat transfer to the vapor phase only, based on single-phase heat transfer model selected in :attr:`Inputs.Model.SPHTM`

    enumeration
        VAPOR                  % Wall heat transfer to the vapor phase only
    end
end