classdef INTAREA
    %INTAREA Enumeration of volumetric interfacial area calculation models
    %
    % This class defines the available :attr:`Inputs.Model.INTAREA` models
    % for calculating the volumetric interfacial area, used by the two-fluid
    % solver.
    %
    % Models:
    %
    % - DISPGAS2DISPLIQ  — Transition from spherical bubbles to spherical droplets (:cite:t:`Walter2024`)

    enumeration
        DISPGAS2DISPLIQ      % Transition from spherical bubbles to spherical droplets 
    end
end