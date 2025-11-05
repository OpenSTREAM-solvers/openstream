classdef InputSet
    %INPUTSET Class for managing a complete set of input objects
    %
    % This class initializes and stores all input components required for a simulation run.
    % It handles model, options, geometry, and boundary condition inputs, and sets up logging
    % via a Session object. It also supports applying solver-dependent property modifications.

    properties (SetAccess = private)

        model                                                              % Model input object
        options                                                            % Options input object
        geometry                                                           % Geometry input object
        bc                                                                 % BoundaryConditions input object
        session                   (1,1) Session.Session                    % Session object for logging and file management

    end

    methods

        function obj = InputSet(opts)
            %INPUTSET Constructor for InputSet class
            %
            % Initializes all input objects and sets up logging session.
            % Parses input files and handles warnings.
            %
            % Inputs:
            %
            % - opts — Struct with fields:
            %
            %          - modelFilePath, modelID
            %          - optionsFilePath, optionsID
            %          - geometryFilePath, geometryID
            %          - bcFilePath
            %          - LOGMODE, sessionName, sessionDirName
            %          - sessionParentDir, overwriteSessionFiles

            arguments
                opts.modelFilePath      {isfile}            = ''           % Model input file (inp/json)
                opts.modelID            {mustBeTextScalar}  = ''           % Model identifier

                opts.optionsFilePath    {isfile}            = ''           % Options input file (inp/json)
                opts.optionsID          {mustBeTextScalar}  = ''           % Options identifier

                opts.geometryFilePath   {isfile}            = ''           % Geometry input file (inp/json)
                opts.geometryID         {mustBeTextScalar}  = ''           % Geometry identifier

                opts.bcFilePath         {isfile}            = ''           % Boundary condition input file (inp/json)

                opts.LOGMODE (1,1)      Session.LogMode     = Session.LogMode.LOGTOCONSOLEONLY
                opts.sessionName        {isStringScalar}    = ""           % Session name
                opts.sessionDirName     {isStringScalar}    = ""           % Session directory name
                opts.sessionParentDir   {isfolder}          = userpath     % Session parent directory
                opts.overwriteSessionFiles ...
                                        {islogical}         = false        % Flag to overwrite existing session files
            end

            % Import packages
            import Inputs.*

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

            % process warnings
            inputsWithWarnings = {obj.model, obj.options, obj.geometry, obj.bc};
            for inputTypeIdx=1:length(inputsWithWarnings)
                inputObjs = inputsWithWarnings{inputTypeIdx};

                % inputObjs is an array for obj.bc in transient situations.
                for inputObj = inputObjs
                    for warningIdx = 1:length(inputObj.warnings)
                        obj.session.log.warning(inputObj.warnings(warningIdx).warnID, sprintf("%s\n",inputObj.warnings(warningIdx).msg));
                    end
                end
            end

            obj.session.log.diaryOff();
        end

        function inputSet = applySolverDependentProps(inputSet, solverName)
            %APPLYSOLVERDEPENDENTPROPS Applies solver-dependent property modifications to all input objects
            %
            % Useful for customizing inputs based on selected solver
            %
            % Inputs:
            %
            % - inputSet   — InputSet object
            % - solverName — Name of the solver to apply dependencies for

            arguments
                inputSet        Inputs.InputSet
                solverName      {mustBeTextScalar}
            end

            inputSet.model = inputSet.model.applySolverDependentProperties(solverName);
            inputSet.options = inputSet.options.applySolverDependentProperties(solverName);
            inputSet.geometry = inputSet.geometry.applySolverDependentProperties(solverName);
            inputSet.bc = inputSet.bc.applySolverDependentProperties(solverName);
        end

    end

end
