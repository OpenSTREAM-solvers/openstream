classdef (Abstract) AbstractField < matlab.mixin.Copyable
    %ABSTRACTFIELD Summary of this class goes here
    %
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

    properties (Access = protected)
        %memoizedFunctions = dictionary();
        % Currently using containers.Map() for MATLAB version
        memoizedFunctions = containers.Map();
    end

    methods
        
        function absField = AbstractField()
            
        end

        function out = memoizeFunction(obj, methodStr, methodHandle, varargin)
        %MEMOIZEDMETHOD Implement a mechanism for registering memoizeable
        %functions
        %
        %  Adapted from https://stackoverflow.com/a/75037451
        %
            %For the first call with a particular method, create and
            %memoize a function handle view of the method
            if ~isConfigured(obj.memoizedFunctions) || ~obj.memoizedFunctions.isKey(methodStr)
                fn_method = @(varargin)methodHandle(varargin{:});
                fn = memoize(fn_method);
                obj.memoizedFunctions(methodStr) = fn;
            end
            
            %For all calls, get the store function handle out of
            %storage, and use it.
            fn = obj.memoizedFunctions(methodStr);
            out = fn(varargin{:});
            
        end

    end

end

