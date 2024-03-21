classdef (Abstract) AbstractField < matlab.mixin.Copyable
    %ABSTRACTFIELD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract=true, SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
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

    properties (SetAccess = protected)
        flowProperties (:,:) cell = {'W','U','H'}            % Flow properties used for copying
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

        function out = struct(obj)
        %STRUCT Converter to struct
        %
            flowProps = obj.flowProperties;
            for i = length(obj):-1:1
                
                % Add `TIME` and `ITR` by default
                outElement = struct('TIME', obj(i).TIME, ...
                                'ITR', obj(i).ITR);

                % Add flow properties as specified
                for flowPropIdx = 1:length(flowProps)
                    
                    % Name of flow property
                    flowProp = flowProps{flowPropIdx};
                    
                    % Set flowProp as new field
                    outElement.(flowProp) = obj(i).(flowProp);

                end

                % add outElement to out
                out(i) = outElement;
            end
        end

        function copyFlowProperties(srcObj, targetObj, opts)
        %COPYFLOWPROPERTIES
        %
            arguments
                srcObj
                targetObj (1,:) Solvers.AbstractField
                opts.all  (1,1) logical = false
            end

            % TODO: add type check for srcObj and targetObj

            for i = 1:length(targetObj)
                
                % Make sure obj meshes match
                if srcObj.Z ~= targetObj(1).Z
                    classType = class(srcObj);
                    throw( ...
                        MException( ...
                            'AbstractFieldError:copyFlowPropertiesError', ...
                            sprintf('Source and target objects (%s) have mismatched spatial meshes', classType) ...
                            ) ...
                        );
                end
                
                % Copy properties
                propNames = srcObj.flowProperties;
                for j = 1:length(propNames)
                    % Full copy
                    if opts.all
                        targetObj(1).(propNames{j}) = srcObj.(propNames{j});
                    % Partial copy to preserve inlet conditions
                    else
                        % Scalar structs are copied per field
                        if isstruct(targetObj(1).(propNames{j})) && isscalar(targetObj(1).(propNames{j}))
                            structFields = fieldnames(targetObj(1).(propNames{j}));
                            for ii = 1:length(structFields)
                                targetObj(1).(propNames{j}).(structFields{ii})(2:end) = ...
                                    srcObj.(propNames{j}).(structFields{ii})(2:end);
                            end
                        % Non-scalar properties are copied as a vector
                        else
                            targetObj(1).(propNames{j})(2:end) = srcObj.(propNames{j})(2:end);
                        end
                        
                    end
                end


            end

        end

    end

end

