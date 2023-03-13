classdef Geometry < Inputs.Input
    %GEOMETRY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        ID         (1,1) string  {mustBeTextScalar,mustBeNonempty}         = 'NA'                  % Channel ID
        LENGTH     (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Axial length [m]
        AREA       (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Coolant area [m^2] 
        PERIM      (1,:) double  {mustBePositive,mustBeNonempty}           = 1                     % Perimeters [m]
        ANGLE      (1,1) double  {mustBeNumeric}                           = 0                     % Angle [rad] 
        
    end

    methods
        function obj = Geometry(filePath,optionsID)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here

            % Call superclass constructor to parse file and select
            % specified optionsID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', optionsID)
            
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
                [isValid, useDefault] = obj.validateInputEntry(objPropname,id=optionsID);
                if isValid && ~useDefault
                    obj.(objPropname) = ...
                                    upper(obj.inputStruct.(objPropname));
                    
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
        

    end

end

