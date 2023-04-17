classdef InputSet
    %INPUTSET Creates set of input objects
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        model
        options
        geometry
        bc

        sessionName
        sessionDir
        overwriteSessionFiles (1,1) logical
    end
    
    methods
        function obj = InputSet(opts)
            %INPUTSET Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                opts.modelFilePath      {isfile}            = ''        % Model input file (inp/json)
                opts.modelID            {mustBeTextScalar}  = ''        % Model ID
                
                opts.optionsFilePath    {isfile}            = ''        % Options input file (inp/json)
                opts.optionsID          {mustBeTextScalar}  = ''        % Options ID
                
                opts.geometryFilePath   {isfile}            = ''        % Geometry input file (inp/json)
                opts.geometryID         {mustBeTextScalar}  = ''        % Geometry ID
                
                opts.bcFilePath         {isfile}            = ''        % Boundary condition input file (inp/json)

                opts.sessionName        {isStringScalar}    = ""        % Session name
                opts.sessionParentDir   {isfolder}          = userpath  % Session parent directory
                opts.overwriteSessionFiles ...
                                        {islogical}         = false     % Flag to overwrite existing session files
            end

            % Import Inputs pacakge
            import Inputs.*
            
            % Create input objects
            obj.model = Model(opts.modelFilePath,opts.modelID);
            obj.options = Options(opts.optionsFilePath,opts.optionsID);
            obj.geometry = Geometry(opts.geometryFilePath, opts.geometryID);
            obj.bc = BoundaryConditions(opts.bcFilePath, obj.geometry);
            
            % Build session name as needed
            if strlength(opts.sessionName) == 0
                [~,bcFileName] = fileparts(opts.bcFilePath);
                obj.sessionName = strcat( ...
                                    obj.model.ID,'-', ...
                                    obj.geometry.ID,'-', ...
                                    obj.options.ID,'-', ...
                                    bcFileName);
            else
                obj.sessionName = opts.sessionName;
            end

            % Check if session directory is legal and/or exists
            obj.overwriteSessionFiles = opts.overwriteSessionFiles;
            sessionDir = fullfile(opts.sessionParentDir, obj.sessionName);
            if ~obj.isLegalPath(sessionDir)
                throw( ...
                    MException( ...
                        'InputSetError:IllegalSessionDirectoryError', ...
                        'Session directory %s is not a legal path', sessionDir ...
                    ) ...
                );
            elseif isfolder(sessionDir)
                if ~obj.overwriteSessionFiles
                    throw( ...
                        MException( ...
                            'InputSetError:ExistingSessionDirectoryError', ...
                            'Session directory %s already exists.', sessionDir ...
                        ) ...
                    );
                else
                    rmdir(sessionDir,'s');
                end
            end

            % Make session directory
            [status, msg, msgID] = mkdir(sessionDir);
            if status ~= 1
                throw( ...
                    MException(msgID,msg) ...
                );
            else
                obj.sessionDir = sessionDir;
            end


        end
    end

    methods (Access=private)
        function bool = isLegalPath(obj,str)
            bool = true;
            try
                java.io.File(str).toPath;
            catch
                bool = false;
            end
        end
    end
end

