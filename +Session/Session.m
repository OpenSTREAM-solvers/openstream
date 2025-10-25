classdef Session < handle
    %SESSION Class for managing simulation session metadata and logging
    %
    % This class handles session naming, directory creation, and logging setup.
    % It ensures that session directories are valid and manages file overwriting behavior.
    % It also integrates with the Log class to control output and warnings.

    properties (SetAccess = protected)

        name        (1,1) string        = ""                               % Name of the session (used for log file naming)
        dirName     (1,1) string        = ""                               % Name of the session directory
        parentDir         {isfolder}    = ""                               % Parent directory where session folder will be created
        overwriteFiles ...                                                 % Flag to allow overwriting existing session files
                    (1,1) logical       = false

        log         (1,1) Session.Log                                      % Log object for managing output and warnings
        
        % Warnings
        showWarnings          (1,1) logical = true                         % Flag to control display of warnings
    
    end

    properties (Dependent)

        directory   (1,1) string                                           % Full path to the session directory
   
    end
    
    methods

        function session = Session(opt)
            %SESSION Constructor for Session class
            %
            % Initializes session metadata including name, directory, and overwrite behavior.
            %
            % Inputs:
            %   opt.name            - Session name
            %   opt.dirName         - Directory name
            %   opt.parentDir       - Parent directory path
            %   opt.overwriteFiles  - Flag to allow overwriting existing session files

            arguments
                opt.name        (1,1) string        = ""
                opt.dirName     (1,1) string        = ""
                opt.parentDir         {isfolder}    = userpath
                opt.overwriteFiles ...
                                (1,1) logical       = false
            end
            session.name        = opt.name;
            session.dirName     = opt.dirName;
            session.parentDir   = opt.parentDir;
            session.overwriteFiles ...
                                = opt.overwriteFiles;
        end

        function directory = get.directory(session)
            % Returns full path to the session directory

            directory = fullfile(session.parentDir,session.dirName);
        end

        function setupLog(session, LOGMODE, opts)
            %SETUPLOG Initializes the Log object for the session
            %
            % Inputs:
            %   LOGMODE - Logging mode (console, file, both, none)
            %   opts.LOGFID - Optional file ID for logging

            arguments
                session                 Session.Session
                LOGMODE        (1,1)    Session.LogMode  = Session.LogMode.LOGTOCONSOLEONLY               
                                                                           % LogMode
                opts.LOGFID    (1,1)    int32            = -1
            end
            
            switch LOGMODE
                case {Session.LogMode.NONE, Session.LogMode.LOGTOFILEONLY}
                    session.showWarnings = false;
                otherwise
                    session.showWarnings = true;
            end

            session.log = Session.Log(LOGMODE, ...
                                      "session",session, ...
                                      "LOGFID",opts.LOGFID,...
                                      "showWarnings", session.showWarnings);
        end

        function makeSessionDirectory(obj)
            %MAKESESSIONDIRECTORY Creates the session directory
            %
            % Validates path legality, handles existing directories,
            % closes open files and diaries if necessary, and creates the directory.

            % Check if session directory is legal and/or exists
            if ~Session.isLegalPath(obj.directory)
                throw( ...
                    MException( ...
                        'LogError:IllegalSessionDirectoryError', ...
                        'Session directory %s is not a legal path', obj.directory ...
                    ) ...
                );
            elseif isfolder(obj.directory)
                if ~obj.overwriteFiles
                    throw( ...
                        MException( ...
                            'LogError:ExistingSessionDirectoryError', ...
                            'Session directory %s already exists.', obj.directory ...
                        ) ...
                    );
                else
                    % Check if there are any open files through fopen
                    if isMATLABReleaseOlderThan("R2024a")
                        openFileIDs = fopen('all');
                    else
                        openFileIDs = openedFiles();
                    end
                    for fid = openFileIDs
                        % Retrieve file directory
                        floc = fopen(fid);
                        fdir = fileparts(floc);
                        % See if file is in obj.directory
                        if fdir == obj.directory
                            % Close the file
                            fclose(fid);
                            warning('File closed: %s', floc);
                        end
                    end

                    % Check if diary file is open
                    if get(0,'Diary') == "on"
                        diaryLoc = get(0,'DiaryFile');
                        diaryDir = fileparts(diaryLoc);
                        % See if file is in obj.directory
                        if diaryDir == obj.directory
                            % Close diary
                            set(0, 'Diary', 'off');
                            warning('Opened diary closed: %s', diaryLoc);
                        end
                    end
                    
                    [status, msg, msgID] = rmdir(obj.directory,'s');
                    if status ~= 1
                        % Sometimes, setting diary off fixes this
                        diary off;
                        [status, msg, msgID] = rmdir(obj.directory,'s');
                        if status ~= 1
                            msg = sprintf("%s\n%s", msg, ...
                                    "Try deleting existing instances of the solver.\n" + ...
                                    "This error is likely caused by abandoned fopen files " + ...
                                    "that were not properly closed. Try running `fopen('all')` " + ...
                                    "to list all open fids.");
                            throw( ...
                                MException(msgID,msg) ...
                            );
                        end
                    end
                        warning('%s was removed.', obj.directory);
                    
                end
            end

            % Make session directory
            [status, msg, msgID] = mkdir(obj.directory);
            if status ~= 1
                throw( ...
                    MException(msgID,msg) ...
                );
            end
        end
        
    end
    
end