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
        
    end
end