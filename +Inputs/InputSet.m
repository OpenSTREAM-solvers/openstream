classdef InputSet
    %INPUTSET Creates set of input objects
    %   Detailed explanation goes here
    
    properties
        model
        options
        geometry
        bc
        
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
            obj.model = Model(opts.modelFilePath,opts.modelID);
            obj.options = Options(opts.optionsFilePath,opts.optionsID);
            obj.geometry = Geometry(opts.geometryFilePath, opts.geometryID);
            obj.bc = BoundaryConditions(opts.bcFilePath, obj.geometry);

        end

    end
end

