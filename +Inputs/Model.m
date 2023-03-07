classdef Model < Inputs.Input
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        ID         (1,1) string  {mustBeTextScalar,mustBeNonempty}                                 % Model ID 
        NNODES           double  {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} ...
                                                                           = []                       % Number of axial nodes 
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
            % specified modelID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', modelID)
            
            %
            % List of obj property names
            objPropnames = string({metaclass(obj).PropertyList.Name}.');
            
            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is valid
                if obj.validateInputEntry(objPropname,id=modelID)
                    obj.(objPropname) = ...
                                    upper(obj.inputStruct.(objPropname));
                end
            end

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

        end
        

    end

end

