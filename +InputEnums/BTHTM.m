classdef BTHTM
    %BTHTM Enumeration of post-boiling transition wall heat transfer models
    %
    % This class defines the available :attr:`Inputs.Model.BTHTM` models for
    % calculating the post-boiling transition wall heat transfer, used by the
    % mixture solver.
    %
    % Models:
    %
    % - VAPOR   — Wall heat transfer to the vapor phase only, based on single-phase heat transfer model selected in :attr:`Inputs.Model.SPHTM`
    % - DOUGALL — Dougall-Rohsenow wall heat transfer model (:cite:t:`DougallRohsenow1963`)
    % - DELORME — Groeneveld-Delorme wall heat transfer model (:cite:t:`GroeneveldDelorme1976`)

    enumeration
        VAPOR                  % Wall heat transfer to the vapor phase only
        DOUGALL                % Dougall-Rohsenow wall heat transfer model
        DELORME                % Groeneveld-Delorme wall heat transfer model
    end
end