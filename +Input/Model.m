classdef Model < Input.Input
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        ID         (1,1) string  {mustBeTextScalar,mustBeNonempty}                                 % Model ID 
        NNODES     (1,1) double  {mustBeInteger,mustBePositive}            = 100                   % Number of axial nodes 
        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Fluid ID
        PROPERTIES (1,1) string  {mustBeTextScalar,mustBeMember(PROPERTIES, ["SATURATED","PSYSTEM"])} ...
                                                                           = 'SATURATED'           % Fluid property assumptions
        FRICTION   (1,3) double  {mustBeNumeric}                           = [0.2 -0.2 0]          % Wall friction coefficients
        TPFM       (1,1) string  {mustBeTextScalar}                        = 'HOMOGENEOUS'         % Two-phase friction multiplier [-]
        KLOC       (1,:) double  {mustBeNumeric,mustBeNonempty}            = [0 0 0]               % Elevation of local perturbations [m] 
        KLOSS      (1,:) double  {mustBeNumeric,mustBeNonempty}            = [0 0 0]               % corresponding pressure loss coefficients [-]
        TPKM       (1,1) string  {mustBeTextScalar}                        = 'HOMOGENEOUS'         % Two-phase local loss multiplier [-] 
        SCBOIL     (1,1) string  {mustBeMember(SCBOIL, ["NONE"])} ...
                                                                           = 'NONE'                % Subcooled boiling mode
        VOID       (1,1) string  {mustBeMember(VOID, ["HOMOGENEOUS","SLIP"])} ...
                                                                           = 'HOMOGENEOUS'         % Void fraction model 
        SLIP       (1,1) double  {mustBePositive}                          = 1                     % Phase velocity ratio [-]
    
    end
    
    methods
        function obj = Model(filePath,modelID)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here

            % Call superclass constructor to parse file and select
            % specified modelID
            obj = obj@Input.Input(filePath, 'ID', modelID)
            
            %
            % List of properties set in inputStruct 
            inputStructFieldnames = fieldnames(obj.inputStruct);

            % List of obj properties
            objPropnames = string({metaclass(obj).PropertyList.Name}.');
            
            % Iterate through obj properties
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-item in objPropnames
                objPropname = objPropnames(idx);

                % Is the objProp required
                propProps = findprop(obj,objPropname);
                propIsRequired = ~propProps.HasDefault;
                
                % Find propname in inputStructFieldnames
                if find(inputStructFieldnames == objPropname)
                    
                    % assign field entry as inputField
                    inputField = obj.inputStruct.(objPropname);

                    % Is inputField value empty
                    inputFieldIsEmpty = isempty(inputField) || (isstring(inputField) && strlength(inputField)==0);

                    % Check requirements
                    if propIsRequired && inputFieldIsEmpty
                    % Throw exception if property is required, yet a
                    % value was not specified
                        throw( ...
                            MException( ...
                                sprintf('MODEL:missingRequiredValueError'), ...
                                'Entry with key %s in model %s was empty', objPropname, modelID) ...
                        );
                    elseif ~propIsRequired && inputFieldIsEmpty
                    % Provide warning if property is optional and a
                    % value was not specified. Use default instead.
                        warning('MODEL: Value for entry %s was not set. Default value used: %s', ...
                            objPropname, num2str(propProps.DefaultValue));
                    else
                        % Assign specified non-empty value to property
                        % Let MATLAB throw errors from parameter validation
                        obj.(objPropname) = ...
                                upper(obj.inputStruct.(objPropname));
                    end
                else
                    if propIsRequired
                    % A required property was not specified
                    % COMMENT: Just let MATLAB handle this error through 
                    % property validation    
                    else
                    % An optional property was not specified
                        warning('MODEL: Value for optional property %s was not set. Default value used: %s', ...
                            objPropname, num2str(propProps.DefaultValue));
                    end
                end

            end

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

        end
        

    end
end

