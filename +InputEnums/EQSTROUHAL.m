classdef EQSTROUHAL
    %EQSTROUHAL Enumeration of wave equilibrium Strouhal number models
    %
    % This class defines the available :attr:`Inputs.Model.EQSTROUHAL`
    % models for calculating the wave equilibrium Strouhal number, used by
    % the four-field solver.
    %
    % Models:
    %
    % - RISO     — Based on RISO dataset (:cite:t:`LECORREMODEL`)
    % - SAWAI    — Based on SAWAI dataset (:cite:t:`LECORREMODEL`)
    % - MFVAL    — MFVAL model (under development)
    % - CUSTOM   — Custom model using user-defined :attr:`Inputs.Model.EQSTROUHALCOEF`

    enumeration
        RISO                 % RISO dataset model (Le Corre, 2022)
        SAWAI                % SAWAI dataset model (Le Corre, 2022)
        MFVAL                % MFVAL model (in development)
        CUSTOM               % Custom model using EQSTROUHALCOEF
    end
end