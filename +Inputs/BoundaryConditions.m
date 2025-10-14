classdef BoundaryConditions < Inputs.Input %& Inputs.IndexableInput
    %BOUNDARYCONDITIONS Defines all boundary parameters.
    %
    %   Class definition for the boundary conditions.
    %   Provide acess to saturated fluid properties at system pressure
    %   using methods.
    %   
    
    properties (SetAccess=?Inputs.Input)
        
        TIME             double  {mustBeNumeric, mustBeScalarOrEmpty}                              % Time [s]
        PRESSURE         double  {mustBePositive, mustBeScalarOrEmpty}     = []                    % System pressure [Pa]
        HIN              double  {mustBePositive, mustBeScalarOrEmpty}     = []                    % Inlet enthalpy [J/kg]
        MFLOW            double  {mustBePositive, mustBeScalarOrEmpty}     = []                    % Mass flow rate [kg/s]
        POWER      (1,1) double  {mustBeNonnegative}                       = 0                     % Total power [W]
        WMESH      (1,:) double  {mustBePositive}                          = 1                     % Relative power node size distribution [m]
        WPOWER     (:,:) double  {mustBeNonnegative}                       = 1                     % Relative power distribution(s) [-] 
        
    end

    properties (SetAccess=private, GetAccess=private)
        geometryObj (1,1) {isa(geometryObj, 'Inputs.Geometry')}
    end

    methods (Access=public)
        
        function obj = BoundaryConditions(filePath, geometryObjInput)
            %BOUNDARYCONDITIONS Construct an instance of this class
            %
            arguments
                filePath = ""
                geometryObjInput = Inputs.Geometry();
            end

            import Inputs.BoundaryConditions

            % Call superclass constructor to parse file
            obj = obj@Inputs.Input(filePath);

            % Save geometryObj
            obj.geometryObj = geometryObjInput;

            % Return naive object if not inputs are provided
            if strlength(filePath) == 0
                return
            end
            
            % List of immutable obj property names
            objPropnames = obj.listInputProperties();

            % Create object array
            for i=1:length(obj.inputStruct)
                objs(i)=BoundaryConditions('',geometryObjInput);
            end
           
            % Array of fieldnames using default values
            defaultValueFieldNames = string().empty();
            defaultValues = {};

            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                 % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault, defaultValue] = obj.validateInputEntry(objPropname);
                if ~useDefault
                    [objs.(objPropname)] = ...
                                    deal(obj.inputStruct.(objPropname));
                elseif useDefault
                    defaultValueFieldNames(end+1) = objPropname;
                    defaultValues{end+1} = defaultValue;
                end

                if isSpecified
                    % Remove objPropname from inputStruct
                    obj.inputStruct = rmfield(obj.inputStruct, objPropname);
                end

            end

            % If extra fields in obj.inputStruct remain, warn user
            remainingInputStructFields = fieldnames(obj.inputStruct);
            if ~isempty(remainingInputStructFields)
                warning( ...
                    '%s: These entries were not used: \n\t %s ', ...
                    upper(class(obj)), sprintf('%s ',remainingInputStructFields{:}) ...
                    );
                for i=1:length(obj.inputStruct)
                    objs(i).extra=obj.inputStruct(i);
                end
            end

            % Default value used warning
            if ~isempty(defaultValueFieldNames)
                defaultValueWarningString = obj.defaultValueUsedReport(defaultValueFieldNames, defaultValues);
                if nargout == 0
                    warning('BoundaryConditions:defaultValueUsedWarning', ...
                        sprintf('%s\n',defaultValueWarningString));
                else
                    w = struct('warnID', 'BoundaryConditions:defaultValueUsedWarning', ...
                               'msg', defaultValueWarningString);
                    if isempty(obj.warnings)
                        obj.warnings = w;
                    else
                        obj.warnings(end+1) = w;
                    end
                end
            end
            
            % Transpose WMESH
            % COMMENT: Not sure why this is necessary
            % obj.WMESH = obj.WMESH.';
            % obj.WPOWER = obj.WPOWER.';
            
            % check if WMESH size is consistent with geometry
            %if any(cellfun(@sum,{objs.WMESH}) ~= obj.geometryObj.LENGTH)
            if any(~ismembertol(cellfun(@sum,{objs.WMESH}),obj.geometryObj.LENGTH,1E-3))    
                throw( ...
                    MException('InputError:BoundaryCondtionsInconsistency', ...
                               'Inconsistent WMESH lengths.') ...
                     );
            end

            % check if WPOWER size is consistent with geometry
            % reshape
            if any(cellfun(@height,{objs.WPOWER}) ~= cellfun(@width,{objs.WMESH}) .* arrayfun(@(obj) width(obj.geometryObj.PERIM), objs))
                throw( ...
                    MException('InputError:BoundaryCondtionsInconsistency', ...
                               'Inconsistent WPOWER array size.') ...
                     );
            else
                for idx = 1:length(objs)
                    
                    objs(idx).WPOWER = reshape(objs(idx).WPOWER, width(objs(idx).WMESH), []);
                    % if all walls have 0 power, set all to 1, and throw
                    % warning
                    if all(objs(idx).WPOWER == 0,'all')
                        objs(idx).WPOWER = objs(idx).WPOWER*0+1;
                        warning('BoundaryConditionsWarning:AllZeroWPOWER', ...
                                'All elements of WPOWER at time index %u is 0. Using 1 instead.', ...
                                idx);
                    end
                end
            end 

            % Calculate private properties
            % NOTE: Nothing here for now

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

            obj = objs;

        end
        
        function  tsat = TSAT(obj,fluidObj)
            %TSAT [K] Saturation temperature given fluid object
            %
            tsat = fluidObj.coolpropH.TsatP(obj.PRESSURE);
        end
        
        function hf = HF(obj,fluidObj)
            %HF [J/kg] Liquid saturation given fluid object
            %
            hf = fluidObj.coolpropH.enthalpy('P',obj.PRESSURE,'Q',0);
        end
        
        function hg = HG(obj,fluidObj)
            %HF [J/kg] Vapor saturation given fluid object
            hg = fluidObj.coolpropH.enthalpy('P',obj.PRESSURE,'Q',1);
        end
        
        function tin = TIN(obj,fluidObj)
            %TIN [K] Inlet temperature
            %
            tin = fluidObj.coolpropH.temperature('P',obj.PRESSURE,'H', obj.HIN);
        end
        
        function dtin = DTIN(obj,fluidObj)
            %DTIN [K] Inlet subcooling temperature given fluid object   
            %
            dtin = obj.TSAT(fluidObj)-obj.TIN(fluidObj);
        end
        
        function dhin = DHIN(obj,fluidObj)
            %DHIN [J/kg] Inlet subcooling enthalpy given fluid object   
            %
            dhin = obj.HF(fluidObj)-obj.HIN;
        end
        
        function xin = XIN(obj,fluidObj)
            %XIN [-] Inlet equilibrium quality given fluid object
            %
            xin = -obj.DHIN(fluidObj)./(obj.HG(fluidObj)-obj.HF(fluidObj));
        end

%         function varargout = size(obj,varargin)
%             [varargout{1:nargout}] = size(obj.TIME,varargin{:});
%         end

        function plot(obj,fluidObj,opt)
            %PLOT Plot boundary conditions given fluid object
            %
            arguments
                obj
                fluidObj
                opt.display     {mustBeMember(opt.display,{'PRESSURE','HIN','MFLOW','POWER','TIN','XIN','DTIN','DHIN'})} = {'PRESSURE','HIN','MFLOW','POWER','TIN','XIN','DTIN','DHIN'}
                opt.tIdx        (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                                 = 1:length(obj)
                opt.unitTemp    {mustBeMember(opt.unitTemp,{'K','C'})}                                                   = 'K'
            end
            
            if length(opt.tIdx) < 2
                disp('Error: At least 2 time indexes required to plot time series.');
                return
            end
            obj = obj(opt.tIdx);
            
            figure('name','Boundary conditions plots')
            if ismember('PRESSURE',opt.display )
                bcplot('PRESSURE','System pressure [Pa]'   ,{}         ,0)
            end
            if ismember('HIN',opt.display )
                bcplot('HIN'     ,'Inlet enthalpy [J/kg]'  ,{'HF','HG'},0)
            end
            if ismember('MFLOW',opt.display )
                bcplot('MFLOW'   ,'Mass flow rate [kg/s]'  ,{}         ,0)
            end
            if ismember('POWER',opt.display )
                bcplot('POWER'   ,'Power [W]'              ,{}         ,0)
            end
            if ismember('TIN',opt.display )
                bcplot('TIN'     ,'Inlet temperature [K]'  ,{'TSAT'}   ,1,opt.unitTemp)
            end
            if ismember('XIN',opt.display )
                bcplot('XIN'     ,'Inlet quality [-]'      ,{}         ,1)
            end
            if ismember('DTIN',opt.display )
                bcplot('DTIN'    ,'Inlet subcooling [K]'   ,{}         ,1)
            end
            if ismember('DHIN',opt.display )
                bcplot('DHIN'    ,'Inlet subcooling [J/kg]',{}         ,1)
            end
            
            function bcplot(param,label,sat,flag,unitTemp)
                
                if nargin<5, unitTemp = 'K'; end
                delta = 0;
                if strcmp('C',unitTemp)
                    delta = -273.15;
                    label = strrep(label,'K','C');
                end

                nexttile; hold all; grid on;
                t = [obj.TIME];
                switch flag
                    case 0
                        plot(t,[obj.(param)]+delta,'.-')
                    case 1
                        plot(t,arrayfun(@(x,y) x.(param)(y),obj,fluidObj)+delta,'.-')
                end
                cellfun(@(param) plot(t,arrayfun(@(x,y) x.(param)(y),obj,fluidObj)+delta,'k--'),sat);
                xlabel('Time [s]'); xlim([min(t)-.01 max(t)+.01])
                ylabel(label)
                set(gca,'fontSize',14)
            end
        end

    end
    
    methods (Static)

        function writeInputFile(filePathName, ...
                                    TIME, PRESSURE, HIN, MFLOW, ...
                                    varargin)
            if TIME == 0
                fileAccessMode = 'w+';
            else
                fileAccessMode = 'a+';
            end
            Inputs.Input.writeInputFile( ...
                filePathName, fileAccessMode, ...
                "TIME", TIME, ...
                "PRESSURE", PRESSURE, ...
                "HIN", HIN, ...
                "MFLOW", MFLOW, ...
                varargin{:} ...
            );
        end
        
    end

end

