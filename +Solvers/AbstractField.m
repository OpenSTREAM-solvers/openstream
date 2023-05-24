classdef (Abstract) AbstractField < matlab.mixin.Copyable
    %ABSTRACTFIELD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract=true, SetAccess=?Solvers.AbstractSolver)
        NZ           (1,1) double  {mustBeNumeric}                          % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                          % [-] Number of time steps
        TIME         (1,1) double  {mustBeNumeric}                          % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                          % [s] Time step size
        TIDX         (1,1) double  {mustBeNumeric}                          % [-] Time step index
        Z            (:,1) double  {mustBeNumeric}                          % [m] Elevation

        % Flow properties
        % W            (:,:) double  {mustBeNumeric}                          % [kg/s] Mass flow rate
        % U            (:,:) double  {mustBeNumeric}                          % [m/s] Velocity
        % H            (:,:) double  {mustBeNumeric}                          % [J/kg] Enthalpy

        % Iteration properties
        ITR          (1,1) struct
    end

    methods
        
        function absField = AbstractField()
            
        end

    end

end

