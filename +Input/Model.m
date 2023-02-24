classdef Model < Input.Input
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        ID         (1,1) string  {mustBeTextScalar,mustBeNonempty}         = 'NA'                  % Model ID 
        NNODES     (1,1) double  {mustBeInteger,mustBePositive}            = 100                   % Number of axial nodes 
        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Fluid ID
        PROPERTIES (1,1) string  {mustBeTextScalar,mustBeMember(PROPERTIES, ["SATURATED","PSYSTEM"])} ...
                                                                           = 'SATURATED'           % Fluid property assumptions
        FRICTION   (1,3) double  {mustBeNumeric}                           = [0.2 -0.2 0]          % Wall friction coefficients
        TPFM       (1,1) string  {mustBeTextScalar}                        = 'HOMOGENEOUS'         % Two-phase friction multiplier [-]
        KLOC       (1,:) double  {mustBeNumeric}                           = 0                     % Elevation of local perturbations [m] 
        KLOSS      (1,:) double  {mustBeNumeric}                           = 0                     % corresponding pressure loss coefficients [-]
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
            inputStructfieldnames = fieldnames(obj.inputStruct);

            % Iterate each fieldname to set as property 
            for idx = 1:length(inputStructfieldnames)
                % Fieldname to process
                inputStructfieldname = inputStructfieldnames{idx};

                % Try to set the struct field value to property is the
                % property exists
                if isprop(obj, inputStructfieldname)
                    try
                        obj.(inputStructfieldname) = ...
                                upper(obj.inputStruct.(inputStructfieldname));
    
                    catch ME
                        warning(getReport(ME))
                    end
                else
                    warning('%s is not a property of %s.', inputStructfieldname, class(obj));
                end
            end
           
        end
        

    end
end

