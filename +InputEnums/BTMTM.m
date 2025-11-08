classdef BTMTM
    %BTMTM Enumeration of post-boiling transition wall momentum transfer models
    %
    % This class defines the available :attr:`Inputs.Model.BTMTM` models for
    % calculating the post-boiling transition wall momentum transfer, used by the
    % mixture solver.
    %
    % Models:
    %
    % - TPFM  — Wall momentum transfer based on  two-phase friction multiplier, using multiplier selected in :attr:`Inputs.Model.TPFM`
    % - VAPOR — Wall momentum transfer based on vapor phase only, using single-phase momentum transfer model selected in :attr:`Inputs.Model.SPMTM`

    enumeration
        TPFM                   % Wall momentum transfer based on two-phase friction multiplier
        VAPOR                  % Wall momentum transfer based on vapor phase only
    end
end