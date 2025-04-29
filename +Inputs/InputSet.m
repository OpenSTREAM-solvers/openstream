classdef InputSet
    %INPUTSET Creates set of input objects
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        model
        options
        geometry
        bc

        session                   (1,1) Session.Session
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

                opts.LOGMODE (1,1)      Session.LogMode         = Session.LogMode.LOGTOCONSOLEONLY
                opts.sessionName        {isStringScalar}    = ""        % Session name
                opts.sessionDirName     {isStringScalar}    = ""        % Session directory name
                opts.sessionParentDir   {isfolder}          = userpath  % Session parent directory
                opts.overwriteSessionFiles ...
                                        {islogical}         = false     % Flag to overwrite existing session files
            end

            % Import pacakges
            import Inputs.*
            
            %
            % Setup Log mechanism
            % Build sessionName as needed
            if opts.sessionName == ""
                [~,sessionName] = fileparts(opts.bcFilePath);
            else
                sessionName = opts.sessionName;
            end

            % Build sessionDirName as needed
            if opts.sessionDirName == ""
                sessionDirName = strcat( ...
                                    opts.geometryID,'-', ...
                                    opts.modelID,'-', ...
                                    opts.optionsID);
            else
                sessionDirName = opts.sessionDirName;
            end

            % Create Log
            sessionParentDir = opts.sessionParentDir;
            obj.session = Session.Session( ...
                                "name",sessionName, ...
                                "dirName",sessionDirName, ...
                                "parentDir",sessionParentDir, ...
                                "overwriteFiles", opts.overwriteSessionFiles);
            obj.session.setupLog(opts.LOGMODE);
            
            % Create input objects
            obj.session.log.diaryOn();
            try
                obj.model = Model(opts.modelFilePath,opts.modelID);
                obj.options = Options(opts.optionsFilePath,opts.optionsID);
                obj.geometry = Geometry(opts.geometryFilePath, opts.geometryID);
                obj.bc = BoundaryConditions(opts.bcFilePath, obj.geometry);
            catch ME
                getReport(ME);
                obj.session.log.diaryOn();
                rethrow(ME)
            end
            
            % procss warnings
            inputsWithWarnings = {obj.model, obj.options, obj.geometry, obj.bc};
            for i=1:length(inputsWithWarnings)
                inputObj = inputsWithWarnings{i};
                for j = 1:length(inputObj.warnings)
                    obj.session.log.warning(inputObj.warnings(j).warnID, sprintf("%s\n",inputObj.warnings(j).msg));
                end
            end

            obj.session.log.diaryOff();

        end
    end

    
end

