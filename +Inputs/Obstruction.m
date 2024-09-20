classdef Obstruction < Inputs.Input
    %OBSTRUCTION Reuseable wall obstruction definition
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        ID         (1,1) string  {mustBeTextScalar}                                                % Channel ID
        SHAPE      (1,1) InputEnums.OBSSHAPE                                                       % Base geom. shape
        WALL       (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Wall index as defined by Geometry
        RLOCATION  (2,1) double  {mustBePositive,mustBeNonempty}           = [0.5 0.5]             % Relative location on wall (axial, span)

        % CIRCLE GEOM
        DIAMETER   (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Diameter [m]

        % TRIANGLE GEOM
        SIDELENGTH (3,1) double  {mustBePositive,mustBeNonempty}           = [1 1 1].*1E-3         % Side lengths [m] (from pointing vertex, CW)
        POINTANGLE (1,1) double  {mustBeNumeric,mustBeNonempty}            = 0                     % Point direction against flow direction (0) [deg]

        % Calculated properties
        LENGTH     (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Axial length [m]
        WIDTH     (1,1) double  {mustBePositive,mustBeNonempty}            = 1                     % Spanwise width [m]
        AREA       (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Coolant area [m^2] 
        PERIM      (1,:) double  {mustBePositive,mustBeNonempty}           = 1                     % Perimeters [m]
        NWALL      (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Number of walls [-] TODO: consider removing this property
        
    end

    methods
        function obj = Obstruction(filePath,obstructionID)
            %MODEL Construct an instance of this class
            %
            %   Detailed explanation goes here
            arguments
                filePath = ""
                obstructionID = ""
            end

            % Call superclass constructor to parse file and select
            % specified optionsID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', obstructionID);

            % Return default value if empty inputs are given
            if strlength(filePath) == 0
                obj.ID = "DEFAULT";
                return
            end
            
            %
            % List of immutable obj property names
            objPropnames = obj.listInputProperties("exclude",{"LENGTH", "WDITH", "AREA", "PERIM", "NWALL"});
            
            % Array of fieldnames using default values
            defaultValueFieldNames = string().empty();

            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault] = obj.validateInputEntry(objPropname,id=obstructionID);
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
            % TODO: remove excluded properties from this list
            if ~isempty(defaultValueFieldNames)
                warning( ...
                    '%s: Default values were used for these entries: \n\t %s ', ...
                    upper(class(obj)), sprintf('%s ',defaultValueFieldNames{:}) ...
                    );
            end

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)
            
            % Calculate Length, Area, Perim, NWall
            switch (obj.SHAPE)
                case InputEnums.OBSSHAPE.CIRCLE
                    obj.LENGTH = obj.DIAMETER;
                    obj.WIDTH = obj.DIAMETER;
                    obj.AREA = 0.25.*pi.*obj.DIAMETER.^2;
                    obj.PERIM = pi.*obj.DIAMETER;
                    obj.NWALL = 1;
                otherwise
                    error("TWOPHASESOLVER:errorObstruction:invalidShape", ...
                        "Obstruction shape invalid or not yet implemented");
            end

        end

        function dh = HDIAM(obj)
            % HDIAM Hydraulic diameter
            %
            %   TODO: Verfiy this is correct and typical for flow obs.
            
            dh = 4*obj.AREA/sum(obj.PERIM);

        end

        function [axialBounds, spanBounds] = placeObsOnWall(obj, wallLength, wallWidth)

            % Assume RLOCATION refers to the symmetrical width/length of
            % the obstruction
            axialBounds = wallLength.*obj.RLOCATION(1)+(obj.LENGTH./2).*[-1, 1];
            axialBounds(axialBounds<0) = 0;
            spanBounds = wallWidth.*obj.RLOCATION(2)+(obj.WIDTH./2).*[-1, 1];

        end

        

    end
    
    methods (Static)
        function writeInputFile(filePathName, ID, varargin)
            Inputs.Input.writeInputFile(filePathName, "a+", "ID", ID, varargin{:});
        end
    end

end

