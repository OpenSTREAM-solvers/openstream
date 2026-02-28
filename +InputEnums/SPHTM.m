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
    % - SIEDERTATE       — Sieder-Tate wall heat transfer model (:math:`\mathrm{Nu} = 0.027 \cdot \mathrm{Re}^{0.8} \cdot \mathrm{Pr}^{1/3} \cdot \left(\frac{\mu_b}{\mu_w}\right)^{0.14}`) (:cite:t:`SiederTate1936`)
    % - GNIELINSKI       — Gnielinski wall heat transfer model (:cite:t:`Gnielinski1976`)

    enumeration
        DITTUSBOELTER        % Dittus-Boelter model for heating
        DITTUSBOELTERGEN     % Generalized Dittus-Boelter model
        SIEDERTATE           % Sieder-Tate model
        GNIELINSKI           % Gnielinski model
    end
end