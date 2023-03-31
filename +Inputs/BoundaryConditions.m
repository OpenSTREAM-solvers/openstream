classdef BoundaryConditions < Inputs.Input & Inputs.IndexableInput
    %BOUNDARYCONDITIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        TIME       (:,1) double  {mustBeNumeric}                           = 0                     % Time [s]
        PRESSURE   (:,1) double  {mustBePositive}                          = 1                     % System pressure [Pa]
        HIN        (:,1) double  {mustBePositive}                          = 1                     % Inlet enthalpy [J/kg]
        MFLOW      (:,1) double  {mustBePositive}                          = 1                     % Mass flow rate [kg/s]
        POWER      (:,1) double  {mustBeNonnegative}                       = 1                     % Total power [W]
        WMESH      (:,:) double  {mustBePositive}                          = 1                     % Relative power node size distribution [m]
        WPOWER     (:,:) double  {mustBeNonnegative}                       = 1                     % Relative power distribution(s) [-] 
        
    end

    properties (SetAccess=private)
        geometryObj (1,1) {isa(geometryObj, 'Inputs.Geometry')}
    end

    methods (Access=public)
        
        function obj = BoundaryConditions(filePath, geometryObjInput)
            %BOUNDARYCONDITIONS Construct an instance of this class
            %   Detailed explanation goes here

            % Call superclass constructor to parse file
            obj = obj@Inputs.Input(filePath)

            % Save geometryObj
            obj.geometryObj = geometryObjInput;
            
            %
            % List of immutable obj property names
            objPropnames = string({metaclass(obj).PropertyList.Name}.');
            objPropnames = objPropnames( ...
                strcmp(string({metaclass(obj).PropertyList.SetAccess}),'immutable'));
           
            % Array of fieldnames using default values
            defaultValueFieldNames = string().empty();

            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                 % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is valid
                [isValid, useDefault] = obj.validateInputEntry(objPropname);
                if isValid && ~useDefault
                    obj.(objPropname) = ...
                                    [obj.inputStruct.(objPropname)];
                    
                    % Remove objPropname from inputStruct
                    obj.inputStruct = rmfield(obj.inputStruct, objPropname);
                elseif useDefault
                    defaultValueFieldNames(end+1) = objPropname;
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
            end

            % If default values were used, warn user
            if ~isempty(defaultValueFieldNames)
                warning( ...
                    '%s: Default values were used for these entries: \n\t %s ', ...
                    upper(class(obj)), sprintf('%s ',defaultValueFieldNames{:}) ...
                    );
            end
            
            % Transpose WMESH
            % COMMENT: Not sure why this is necessary
            obj.WMESH = obj.WMESH.';
            obj.WPOWER = obj.WPOWER.';
            
            % check if WPOWER size is consistent with geometry
            if size(obj.WPOWER,2) ~= size(obj.WMESH,2)*size(obj.geometryObj.PERIM,2)
                throw( ...
                    MException('InputError:BoundaryCondtionsInconsistency', ...
                               'Inconsistent WPOWER array size.') ...
                     );
            end
            
            %
            % Calculate private properties
            % NOTE: Nothing here for now

            %
            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

        end
        
        function  tsat = TSAT(obj,fluidObj)
            %TSAT [K] Saturation temperature given fluidObj
            tsat = fluidObj.coolpropH.TsatP(obj.PRESSURE);
        end
        
        function hf = HF(obj,fluidObj)
            %HF [J/kg] Liquid saturation given fluidObj
            hf = fluidObj.coolpropH.enthalpy('P',obj.PRESSURE,'Q',0);
        end
        
        function hg = HG(obj,fluidObj)
            %HF [J/kg] Vapor saturation given fluidObj
            hg = fluidObj.coolpropH.enthalpy('P',obj.PRESSURE,'Q',1);
        end
        
        function tin = TIN(obj,fluidObj)
            %TIN [K] Inlet temperature
            tin = fluidObj.coolpropH.temperature('P',obj.PRESSURE,'H', obj.HIN);
        end
        
        function dtin = DTIN(obj,fluidObj)
            %DTIN [K] Inlet subcooling temperature difference given fluidObj    
            dtin = obj.TSAT(fluidObj)-obj.TIN(fluidObj);
        end
        
        % Inlet subcooling, usage: obj.DHIN(model)
        function dhin = DHIN(obj,fluidObj)
            %DHIN [J/kg] Inlet subcooling enthalpy difference given fluidObj    
            dhin = obj.HF(fluidObj)-obj.HIN;
        end
        
        % Inlet equilibrium quality, usage: obj.XIN(model)
        function xin = XIN(obj,fluidObj)
            %XIN [-] Inlet equilibrium quality
            xin = -obj.DHIN(fluidObj)./(obj.HG(fluidObj)-obj.HF(fluidObj));
        end

%         function varargout = size(obj,varargin)
%             [varargout{1:nargout}] = size(obj.TIME,varargin{:});
%         end

        function plot(obj,fluidObj)
            %PLOT Plot boundary conditions
            % usage: bc.plot(fluidObj)

            figure('name','Boundary conditions plots')
            bcplot('PRESSURE','System pressure [Pa]',{},0)
            bcplot('HIN','Inlet enthalpy [J/kg]',{'HF','HG'},0)
            bcplot('MFLOW','Mass flow rate [kg/s]',{},0)
            bcplot('POWER','Power [W]',{},0)
            bcplot('TIN','Inlet temperature [K]',{'TSAT'},1)
            bcplot('XIN','Inlet quality [-]',{},1)
            bcplot('DTIN','Inlet subcooling [K]',{},1)
            bcplot('DHIN','Inlet subcooling [J/kg]',{},1)
            
            function bcplot(param,label,sat,flag)

                nexttile; hold all; grid on;
                t = obj.TIME;
                switch flag
                    case 0
                        plot(t,[obj.(param)],'.-')
                    case 1
                        plot(t,[obj.(param)(fluidObj)],'.-')
                end
                cellfun(@(x) plot(t,obj.(x)(fluidObj),'k--'),sat);
                xlabel('Time [s]'); xlim([min(t)-.01 max(t)+.01])
                ylabel(label)
                set(gca,'fontSize',14)
            end

        end

    end

    
    
    

end

