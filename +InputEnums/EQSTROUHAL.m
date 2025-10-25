classdef EQSTROUHAL
    %EQSTROUHAL Enumeration of wave equilibrium Strouhal number models
    %
    %   This class defines the available models for calculating the
    %   wave equilibrium Strouhal number, used by the four-field solver.
    %
    %   Models:
    %       RISO     - Based on RISO dataset (Le Corre, 2022)
    %       SAWAI    - Based on SAWAI dataset (Le Corre, 2022)
    %       MFVAL    - MFVAL model (under development)
    %       CUSTOM   - Custom model using user-defined EQSTROUHALCOEF

    enumeration
        RISO                 % RISO dataset model (Le Corre, 2022)
        SAWAI                % SAWAI dataset model (Le Corre, 2022)
        MFVAL                % MFVAL model (in development)
        CUSTOM               % Custom model using EQSTROUHALCOEF
    end
end