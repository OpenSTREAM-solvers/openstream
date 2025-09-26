classdef WAVEBASEINT
%WAVEBASEINT Wave to base film interfacial momentum transfer model
%
%   Defines the model used for the wave to base film interfacial momentum
%   transfer.
%   Used by the four-field solver.
%
    enumeration
        VAPORSHEAR           % Vapor shear across wave area (consistent with Le Corre 2022, eq 46) 
        VAPORSHEARDROPMASS   % Add effect of drop depostion momentum transfer so that wave and base film velocitiea are fully consistent for thin film
    end

end