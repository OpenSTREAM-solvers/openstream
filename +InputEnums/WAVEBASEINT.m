classdef WAVEBASEINT
    %WAVEBASEINT Enumeration of wave to base film interfacial momentum transfer models
    %
    %   This class defines the models used to calculate the interfacial momentum
    %   transfer between wave and base film regions, used by the four-field solver.
    %
    %   Available Models:
    %       VAPORSHEAR           - Vapor shear across wave area (consistent with Le Corre 2022, Eq. 46).
    %       VAPORSHEARDROPMASS   - Also includes drop deposition momentum transfer, ensuring consistency
    %                              between wave and base film velocities for thin films.

    enumeration
        VAPORSHEAR           % Vapor shear across wave area (Le Corre 2022, eq 46) 
        VAPORSHEARDROPMASS   % Add drop deposition momentum transfer for thin film consistency
    end
end