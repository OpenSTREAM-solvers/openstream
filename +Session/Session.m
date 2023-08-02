classdef Session < handle
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        name        (1,1) string        = ""
        dirName     (1,1) string        = ""
        parentDir         {isfolder}    = ""
        overwriteFiles ...                              % Flag to overwrite existing session files
                    (1,1) logical       = false

        log         (1,1) Session.Log
    end

    properties (Dependent)
        directory   (1,1) string
    end
    
    methods
        function session = Session(opt)
            %SESSION Construct an instance of this class
            %   Detailed explanation goes here
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
            directory = fullfile(session.parentDir,session.dirName);
        end

        function setupLog(session, LOGMODE, opts)
        %SETUPLOG Setup log
        %
            arguments
                session
                LOGMODE        (1,1)    Session.LogMode      = Session.LogMode.LOGTOCONSOLEONLY               
                                                                            % LogMode
                opts.LOGFID    (1,1)    int32            = -1
            end
            
            session.log = Session.Log(LOGMODE, ...
                                      "session",session, ...
                                      "LOGFID",opts.LOGFID);
        end

        function makeSessionDirectory(obj)
        %MAKESESSIONDIRECTORY Make the session directory
        %
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
                    %TODO: add warning about deletion
                    [status, msg, msgID] = rmdir(obj.directory,'s');
                    if status ~= 1
                        throw( ...
                            MException(msgID,msg) ...
                        );
                    else
                        warning('%s was removed.', obj.directory);
                    end
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