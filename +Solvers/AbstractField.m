classdef (Abstract) AbstractField < matlab.mixin.Copyable
    %ABSTRACTFIELD Base class for field definitions across solvers
    %
    % This abstract class defines shared properties and methods for all field-type
    % classes used in solver implementations. It provides mechanisms for transient
    % data extraction, plotting, memoization, struct conversion, and property copying.

    properties (Abstract=true, SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})

        NZ           (1,1) double  {mustBeNumeric}                         % Number of axial steps [-]
        NTIME        (1,1) double  {mustBeNumeric}                         % Number of time steps [-]
        TIME         (1,1) double  {mustBeNumeric}                         % Time series [s]
        DT           (1,1) double  {mustBeNumeric}                         % Time step size [s]
        TIDX         (1,1) double  {mustBeNumeric}                         % Time step index [-]
        Z            (:,1) double  {mustBeNumeric}                         % Elevation [m]
        ITR          (1,1) struct                                          % Iteration properties

    end

    properties (Access = protected)

        %memoizedFunctions = dictionary();
        % Currently using containers.Map() for MATLAB version
        memoizedFunctions = containers.Map();                              % Memoization store for function handles

    end

    properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})

        inputSet                   {isa(inputSet,'Inputs.InputSet')}                              % :class:`Inputs.InputSet` object

    end

    properties (SetAccess = protected, Hidden)

        flowProperties (:,:) cell = {'W','U','H','ITR'}                    % Flow properties used for copying

    end

    methods

        function absField = AbstractField()
            %ABSTRACTFIELD Constructor for AbstractField class

        end

        function paramData = transient(obj, param, subobj, opt)
            %TRANSIENT Extracts transient distribution array for a given parameter
            %
            % Supports wall-wise and axial/time slicing with optional
            % subobject access.

            arguments
                obj
                param         (1,1) string {mustBeTextScalar}
                subobj                                                                 = []
                opt.wall      (1,:) double {mustBeVector,mustBeInteger,mustBePositive} = []
                opt.zIdx      (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:obj(1).NZ
                opt.tIdx      (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:length(obj)
            end

            % Read parameter
            p = split(param,'.');
            if isscalar(p)
                if isempty(subobj)
                    paramData = cell2mat(arrayfun(@(x) x.(param),obj(opt.tIdx),'uni',0));
                else
                    paramData = cell2mat(arrayfun(@(x,y) x.(param)(y),obj(opt.tIdx),subobj(opt.tIdx),'uni',0));
                end
            else
                if isempty(subobj)
                    paramData = cell2mat(arrayfun(@(x) x.(p{1}).(p{2}),obj(opt.tIdx),'uni',0));
                else
                    paramData = cell2mat(arrayfun(@(x,y) x.(p{1}).(p{2})(y),obj(opt.tIdx),subobj(opt.tIdx),'uni',0));
                end
            end

            % Size parameter based on options
            NWALL = size(paramData,2)/length(opt.tIdx);
            if isempty(opt.wall), opt.wall = 1:NWALL; end
            if NWALL > 1
                idx = cell2mat(arrayfun(@(n) [n:NWALL:size(paramData,2)],opt.wall,'uni',0));
                paramData = paramData(:,idx);                              % Wall discretization
            end
            paramData = paramData(opt.zIdx,:);                             % Keep relevant axial length
            paramData = reshape(paramData,length(opt.zIdx),length(opt.tIdx),length(opt.wall));

            % Special case for single elevation
            if isscalar(opt.zIdx)
                paramData = permute(paramData,[3 2 1]);
            end
        end

        function ax = plotzt(obj, param ,ylabelText ,ylabelUnit ,k ,opt, subobj, annular,time)
            %PLOTZT 2D Generates a 2D space-time distribution plot for a given parameter

            % Supports unit conversion, pre-annular flow masking, and
            % customizable view options.

            if nargin < 8, annular = false; end
            if nargin < 9, time = []; end

            z     = obj(1).Z(opt.zIdx);                                    % [m]
            if isempty(time), time = [obj(opt.tIdx).TIME];  end            % [s]
            if opt.reverseTime
                time = time -time(end);
            end

            % Load data
            try
                paramData = obj.transient(param,       'wall',k,'zIdx',opt.zIdx,'tIdx',opt.tIdx);
            catch
                paramData = obj.transient(param,subobj,'wall',k,'zIdx',opt.zIdx,'tIdx',opt.tIdx);
            end

            % Adjust for temperature unit
            if strcmp(ylabelUnit,'C')
                paramData = paramData-273.15;
            end

            % Remove pre-annular flow region
            if annular
                try
                    OAFIDX = arrayfun(@(x) x.OAFIDX,obj);
                catch
                    OAFIDX = arrayfun(@(x) x.mix.OAFIDX,obj);
                end
                OAFIDX = OAFIDX - opt.zIdx(1) + 1;
                for k = 1:length(OAFIDX)
                    paramData(1:OAFIDX(k),k) = nan;
                end
            end

            ax = nexttile; hold on; grid on; title(ylabelText)
            [t_mesh,z_mesh] = meshgrid(time,z);
            surf(z_mesh,t_mesh,paramData,'edgeColor','none');
            xlabel('Axial position [m]'); xlim([min(z)       max(z)]);
            ylabel('Time [s]')          ; ylim([min(time) max(time)]);
            cb = colorbar(); cb.Label.String = [ylabelText ' [' ylabelUnit ']']; cb.Label.FontSize = 14;
            set(gca,'fontSize',14)
            shading(opt.shading)
            view(opt.view);
        end

        function out = memoizeFunction(obj, methodStr, methodHandle, varargin)
            %MEMOIZEDMETHOD Registers and retrieves memoized function handles
            %
            % Avoids redundant computation by caching results.
            %
            % Adapted from https://stackoverflow.com/a/75037451

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

        function log(obj, varargin)
            %LOG Log messages to the createdBySolver session log

            if isempty(obj.inputSet)
                disp(varargin{:})
            else
                obj.inputSet.session.log.log(varargin{:});
            end
        end

        function warning(obj, varargin)
            %LOG Log warning messages to the createdBySolver session log

            if isempty(obj.inputSet)
                warning(varargin{:})
            else
                obj.inputSet.session.log.warning(varargin{:});
            end
        end

        function out = struct(obj)
            %STRUCT Converts field object to a structured array
            %
            % Includes TIME, ITR, and flow properties.

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
            %COPYFLOWPROPERTIES Copies flow properties from source to target field object
            %
            % Supports full or partial copying depending on 'opts.all'
            % flag.

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

