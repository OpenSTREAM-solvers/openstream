classdef Geometry < Inputs.Input
    %GEOMETRY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        ID         (1,1) string  {mustBeTextScalar}                                                % Channel ID
        LENGTH     (1,1) double  {mustBeNonnegative,mustBeNonempty}           = 1                     % Axial length [m]
        AREA       (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Coolant area [m^2] 
        PERIM      (1,:) double  {mustBePositive,mustBeNonempty}           = 1                     % Perimeters [m]
        ANGLE      (1,1) double  {mustBeNumeric}                           = 0                     % Angle [rad] 
        
    end

    methods
        function obj = Geometry(filePath,geometryID)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                filePath = ""
                geometryID = ""
            end

            % Call superclass constructor to parse file and select
            % specified optionsID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', geometryID)

            % Return default value if empty inputs are given
            if strlength(filePath) == 0
                obj.ID = "DEFAULT";
                return
            end
            
            %
            % List of immutable obj property names
            objPropnames = obj.listInputProperties();
            
            % Array of fieldnames using default values
            defaultValueFieldNames = string().empty();

            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault] = obj.validateInputEntry(objPropname,id=geometryID);
                if ~useDefault
                    obj.(objPropname) = ...
                                    upper(obj.inputStruct.(objPropname));
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
                obj.extra = obj.inputStruct;
            end

            % If default values were used, warn user
            if ~isempty(defaultValueFieldNames)
                warning( ...
                    '%s: Default values were used for these entries: \n\t %s ', ...
                    upper(class(obj)), sprintf('%s ',defaultValueFieldNames{:}) ...
                    );
            end

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

        end

        function dh = HDIAM(obj)
            % HDIAM Hydraulic diameter
            
            dh = 4*obj.AREA/sum(obj.PERIM);
            
        end
        
        function N = NWALL(obj)
            % NWALL Number of walls
            
            N = length(obj.PERIM);
            
        end
        
        function obj = setProperty(obj, propName, value)
            %SETPROPERTY A setter for protected properties
            %
            % Limited to access protected properties

            % TODO: Check if propName is a protected property

            % Change property value
            obj.(propName) = value;

        end

    end
    
    methods (Static)
        function writeInputFile(filePathName, ID, varargin)
            Inputs.Input.writeInputFile(filePathName, "a+", "ID", ID, varargin{:});
        end
    end

end

