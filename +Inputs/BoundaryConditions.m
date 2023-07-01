classdef BoundaryConditions < Inputs.Input %& Inputs.IndexableInput
    %BOUNDARYCONDITIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        TIME       (1,1) double  {mustBeNumeric}                           = 0                     % Time [s]
        PRESSURE   (1,1) double  {mustBePositive}                          = 1                     % System pressure [Pa]
        HIN        (1,1) double  {mustBePositive}                          = 1                     % Inlet enthalpy [J/kg]
        TISO       (1,1) double  {mustBePositive}                          = 293                   % Isothermal temperature [K], only for 2-spcies mixture
        MFLOW      (1,1) double  {mustBePositive}                          = 1                     % Mass flow rate [kg/s]
        POWER      (1,1) double  {mustBeNonnegative}                       = 1                     % Total power [W]
        WMESH      (1,:) double  {mustBePositive}                          = 1                     % Relative power node size distribution [m]
        WPOWER     (:,:) double  {mustBeNonnegative}                       = 1                     % Relative power distribution(s) [-] 
        
    end

    properties (SetAccess=private, GetAccess=private)
        geometryObj (1,1) {isa(geometryObj, 'Inputs.Geometry')}
    end

    methods (Access=public)
        
        function obj = BoundaryConditions(filePath, geometryObjInput)
            %BOUNDARYCONDITIONS Construct an instance of this class
            %   Detailed explanation goes here
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
            
            %
            % List of immutable obj property names
            objPropnames = obj.listInputProperties();

            % Create object array
            for i=1:length(obj.inputStruct)
                objs(i)=BoundaryConditions('',geometryObjInput);
            end
           
            % Array of fieldnames using default values
            defaultValueFieldNames = string().empty();

            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                 % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault] = obj.validateInputEntry(objPropname);
                if ~useDefault
                    [objs.(objPropname)] = ...
                                    deal(obj.inputStruct.(objPropname));
                elseif useDefault
                    defaultValueFieldNames(end+1) = objPropname;
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

            % If default values were used, warn user
            if ~isempty(defaultValueFieldNames)
                warning( ...
                    '%s: Default values were used for these entries: \n\t %s ', ...
                    upper(class(obj)), sprintf('%s ',defaultValueFieldNames{:}) ...
                    );
            end
            
            % Transpose WMESH
            % COMMENT: Not sure why this is necessary
%             obj.WMESH = obj.WMESH.';
%             obj.WPOWER = obj.WPOWER.';
            
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
            
            

            %
            % Calculate private properties
            % NOTE: Nothing here for now

            %
            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

            obj = objs;

        end
        
        function  tsat = TSAT(obj,fluidObj)
            %TSAT [K] Saturation temperature given fluidObj
            switch obj.PROPERTIES
                case {InputEnums.FLUIDPROPERTIES.SATURATED, InputEnums.FLUIDPROPERTIES.PSYSTEM}
                    tsat = fluidObj.coolpropH.TsatP(obj.PRESSURE);
                case InputEnums.FLUIDPROPERTIES.ISOTHERMAL
                    tsat = obj.TISO;
            end
        end
        
        function hf = HF(obj,fluidObj)
            %HF [J/kg] Liquid saturation given fluidObj
            switch obj.PROPERTIES
                case {InputEnums.FLUIDPROPERTIES.SATURATED, InputEnums.FLUIDPROPERTIES.PSYSTEM}
                    hf = fluidObj.coolpropHLiq.enthalpy('P',obj.PRESSURE,'Q',0);
                case InputEnums.FLUIDPROPERTIES.ISOTHERMAL
                    hf = fluidObj.coolpropHLiq.enthalpy('P',obj.PRESSURE,'T',obj.TISO);
            end
        end
        
        function hg = HG(obj,fluidObj)
            %HF [J/kg] Vapor saturation given fluidObj
            switch obj.PROPERTIES
                case {InputEnums.FLUIDPROPERTIES.SATURATED, InputEnums.FLUIDPROPERTIES.PSYSTEM}
                    hg = fluidObj.coolpropHVap.enthalpy('P',obj.PRESSURE,'Q',1);
                case InputEnums.FLUIDPROPERTIES.ISOTHERMAL
                    hg = fluidObj.coolpropHVap.enthalpy('P',obj.PRESSURE,'T',obj.TISO);
            end
        end
        
        function tin = TIN(obj,fluidObj)
            %TIN [K] Inlet temperature
            switch obj.PROPERTIES
                case {InputEnums.FLUIDPROPERTIES.SATURATED, InputEnums.FLUIDPROPERTIES.PSYSTEM}
                    tin = fluidObj.coolpropH.temperature('P',obj.PRESSURE,'H', obj.HIN);
                case InputEnums.FLUIDPROPERTIES.ISOTHERMAL
                    tin = obj.TISO;
            end
        end
        
        function dtin = DTIN(obj,fluidObj)
            %DTIN [K] Inlet subcooling temperature difference given fluidObj    
            switch obj.PROPERTIES
                case {InputEnums.FLUIDPROPERTIES.SATURATED, InputEnums.FLUIDPROPERTIES.PSYSTEM}
                    dtin = obj.TSAT(fluidObj)-obj.TIN(fluidObj);
                case InputEnums.FLUIDPROPERTIES.ISOTHERMAL
                    dtin = 0;
            end
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

