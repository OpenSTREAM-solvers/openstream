classdef InputSet
    %INPUTSET Creates set of input objects
    %   Detailed explanation goes here
    
    properties
        modelObj
        optionsObj
        geometryObj
        bcObj
        
    end
    
    methods
        function obj = InputSet(opts)
            %INPUTSET Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                opts.modelFilePath              {isfile}            = ''    % Model input file (inp/json)
                opts.modelID                    {mustBeTextScalar}  = ''    % Model ID
                
                opts.optionsFilePath            {isfile}            = ''    % Options input file (inp/json)
                opts.optionsID                  {mustBeTextScalar}  = ''    % Options ID
                
                opts.geometryFilePath           {isfile}            = ''    % Geometry input file (inp/json)
                opts.geometryID                 {mustBeTextScalar}  = ''    % Geometry ID
                
                opts.bcFilePath                 {isfile}            = ''    % Boundary condition input file (inp/json)                
            end

            % Import Inputs pacakge
            import Inputs.*
            
            % Create input objects
            obj.modelObj = Model(opts.modelFilePath,opts.modelID);
            obj.optionsObj = Options(opts.optionsFilePath,opts.optionsID);
            obj.geometryObj = Geometry(opts.geometryFilePath, opts.geometryID);
            obj.bcObj = BoundaryConditions(opts.bcFilePath, obj.geometryObj);

        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

