classdef BTHTM
    %BTHTM Enumeration of post-boiling transition wall heat transfer models
    %
    % This class defines the available :attr:`Inputs.Model.BTHTM` models for
    % calculating the post-boiling transition wall heat transfer, used by the
    % mixture solver.
    %
    % Models:
    %
    % - VAPOR    — Wall heat transfer to the vapor phase only, based on single-phase heat transfer model selected in :attr:`Inputs.Model.SPHTM`
    % - DOUGALL  — Dougall-Rohsenow wall heat transfer model (:cite:t:`DougallRohsenow1963`)
    % - BISHOP   — Bishop-Sandberg-Tong wall heat transfer model (:cite:t:`Bishop1965`)
    % - MOECK    — Groeneveld-Moeck wall heat transfer model (:cite:t:`GroeneveldMoeck1969`)
    % - DELORME  — Groeneveld-Delorme wall heat transfer model (:cite:t:`GroeneveldDelorme1976`)
    % - CONDIEIV — Condie-Bengston IV wall heat transfer model (:cite:t:`Morris1982`)

    enumeration
        VAPOR                  % Wall heat transfer to the vapor phase only
        DOUGALL                % Dougall-Rohsenow wall heat transfer model
        BISHOP                 % Bishop-Sandberg-Tong wall heat transfer model
        MOECK                  % Groeneveld-Moeck wall heat transfer model
        DELORME                % Groeneveld-Delorme wall heat transfer model
        CONDIEIV               % Condie-Bengston wall heat transfer model
    end
end