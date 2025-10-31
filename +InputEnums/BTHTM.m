classdef BTHTM
    %BTHTM Enumeration of post-boiling transition wall heat transfer models
    %
    % This class defines the available models for calculating the
    % post-boiling transition wall heat transfer, used by the mixture solver.
    %
    % Models:
    %
    % - VAPOR — Wall heat transfer to the vapor phase only, based on single-phase heat transfer model selected in :attr:`InputsEnums.SPHTM`

    enumeration
        VAPOR                  % Wall heat transfer to the vapor phase only
    end
end