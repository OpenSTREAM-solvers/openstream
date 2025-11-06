classdef SPHTM
    %SPHTM Enumeration of single-phase wall heat transfer models
    %
    % This class defines the available :attr:`Inputs.Model.SPHTM` models for
    % calculating the single-phase wall heat transfer (liquid or gas), used
    % by the mixture solver.
    %
    % Models:
    %
    % - DITTUSBOELTER    — Dittus-Boelter wall heat transfer model for heating (:math:`\mathrm{Nu} = 0.023 \cdot \mathrm{Re}^{0.8} \cdot \mathrm{Pr}^{0.4}`) (:cite:t:`DittusBoelter`, :cite:t:`McAdams1942`)
    % - DITTUSBOELTERGEN — Generalized Dittus-Boelter wall heat transfer model using user-defined :attr:`Inputs.Model.DITTUSBOELTERCOEF`

    enumeration
        DITTUSBOELTER        % Dittus_Boelter model for heating
        DITTUSBOELTERGEN     % Generalized Dittus_Boelter model
    end
end