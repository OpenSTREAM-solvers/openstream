classdef Geometry < Inputs.Input
    %GEOMETRY Defines all geometrical inputs.
    %
    %   Class definition for the geometrical inputs
    %   Data are read from the geometry input file using InputSet
    %
    
    properties (SetAccess=?Inputs.Input)
        
        ID         (1,1) string  {mustBeTextScalar}                                                % Channel ID
        LENGTH     (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Axial length [m]
        AREA       (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Coolant area [m^2] 
        PERIM      (1,:) double  {mustBePositive,mustBeNonempty}           = 1                     % Perimeters [m]
        ANGLE      (1,1) double  {mustBeNumeric}                           = 0                     % Angle [rad] 
        
    end

    methods
        function obj = Geometry(filePath,geometryID)
        %Geometry Construct an instance of this class
        %
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
            defaultValues = {};

            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault, defaultValue] = obj.validateInputEntry(objPropname,id=geometryID);
                if ~useDefault
                    obj.(objPropname) = ...
                                    upper(obj.inputStruct.(objPropname));
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
                obj.extra = obj.inputStruct;
            end

            % Default value used warning
            if ~isempty(defaultValueFieldNames)
                defaultValueWarningString = obj.defaultValueUsedReport(defaultValueFieldNames, defaultValues);
                if nargout == 0
                    warning('Geometry:defaultValueUsedWarning', ...
                        sprintf('%s\n',defaultValueWarningString));
                else
                    w = struct('warnID', 'Geometry:defaultValueUsedWarning', ...
                               'msg', defaultValueWarningString);
                    if isempty(obj.warnings)
                        obj.warnings = w;
                    else
                        obj.warnings(end+1) = w;
                    end
                end
            end

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)
        end

        function dh = HDIAM(obj)
        % HDIAM Hydraulic diameter
        %
            dh = 4*obj.AREA/sum(obj.PERIM);
        end
        
        function da = ADIAM(obj)
        % ADIAM Diameter based on coolant cross-section area
        %
            da = 2*sqrt(obj.AREA/pi);
        end
        
        function N = NWALL(obj)
        % NWALL Number of walls
        %
            N = length(obj.PERIM);
        end
        
        function R = RWALL(obj)
        % RWALL Wall perimeter ratio
        %    
            R = obj.PERIM./sum(obj.PERIM); 
        end

    end
    
    methods (Static)
        function writeInputFile(filePathName, ID, varargin)
            Inputs.Input.writeInputFile(filePathName, "a+", "ID", ID, varargin{:});
        end
    end

end

