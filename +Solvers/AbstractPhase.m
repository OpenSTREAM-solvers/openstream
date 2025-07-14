classdef (Abstract) AbstractPhase < handle
    %ABSTRACTPHASE defines all methods shared by all phase class
    %definitions across all solvers
    %
    %   TODO: Detailed explanations

    methods (Abstract)
        TIME    % Time [s]
        Z       % Axial node [m]
        X       % Mass fraction [-]
        VF      % Void fraction [-]
        W       % Mass flow rate [kg/s]
        U       % Velocity [m/s]
        H       % Enthalpy [J/kg]
        MFLUX   % Mass flux [kg/m^2-s]
        HFLUX   % Wall field heat flux [W/m^2]
        RE      % Reynold's Number [-]
        T       % Temperature [K]
    end
   
end

