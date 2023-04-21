classdef Log < handle
    %LOG Console log manager
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)

        LOGMODE               (1,1) Session.LogMode
        diaryOn               (1,1) logical         = false

        % log file
        LOGFID                              = -1                                 % Logging file ID
        logFileName           (1,1) string
    end

    properties (Access = private)
        session               (1,1)
    end
    
    properties (Dependent)
        logFilePath           (1,1) string
        diaryFilePath         (1,1) string
    end

    methods
        function obj = Log(LOGMODE, opts)
            %LOG Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                LOGMODE        (1,1)    Session.LogMode      = Session.LogMode.LOGTOCONSOLEONLY               
                                                                            % LogMode
                opts.session   (1,1)    Session.Session      
                opts.LOGFID    (1,1)    int32                = -1
            end

            % Store LOGMODE and LOGFID
            obj.LOGMODE = LOGMODE;
            obj.LOGFID = opts.LOGFID;   % TODO: verify is valid file

            % Make logging filesystem as needed
            switch obj.LOGMODE
                case {Session.LogMode.NONE, Session.LogMode.LOGTOCONSOLEONLY}
                    % Do nothing
                case {Session.LogMode.LOGTOFILEONLY, Session.LogMode.BOTH}
                    % Check if session directory is legal and/or exists
                    if ~obj.isLegalPath(opts.session.directory)
                        throw( ...
                            MException( ...
                                'LogError:IllegalSessionDirectoryError', ...
                                'Session directory %s is not a legal path', opts.session.dir ...
                            ) ...
                        );
                    elseif isfolder(opts.session.directory)
                        if ~opts.session.overwriteFiles
                            throw( ...
                                MException( ...
                                    'LogError:ExistingSessionDirectoryError', ...
                                    'Session directory %s already exists.', opts.session.directory ...
                                ) ...
                            );
                        else
                            %TODO: add warning about deletion
                            [status, msg, msgID] = rmdir(opts.session.directory,'s');
                            if status ~= 1
                                throw( ...
                                    MException(msgID,msg) ...
                                );
                            else
                                warning('%s was removed.', opts.session.directory);
                            end
                        end
                    end
        
                    % Make session directory
                    [status, msg, msgID] = mkdir(opts.session.directory);
                    if status ~= 1
                        throw( ...
                            MException(msgID,msg) ...
                        );
                    else
                        obj.session = opts.session;
                    end

                    % Make log file
                    obj.setupLog();
                    
            end

            

        end
        
        function log(obj, varargin)
        %LOG Log events
        %
            import Session.LogMode

            if obj.LOGMODE == LogMode.NONE
                return
            else
                if (obj.LOGMODE == LogMode.BOTH || ...
                        obj.LOGMODE == LogMode.LOGTOFILEONLY) ...
                    && obj.LOGFID >= 0
                    builtin('fprintf',obj.LOGFID, varargin{:}); 
                end
                if (obj.LOGMODE == LogMode.BOTH || ...
                        obj.LOGMODE == LogMode.LOGTOCONSOLEONLY)
                    builtin('fprintf',varargin{:}); 
                end
            end
        end

        function toggleDiary(obj, off)
        %TOGGLEDIARY Toggle diary keeping function
        %
        arguments
            obj
            off (1,1) logical     = false
        end
    
            if nargin < 2
                if (obj.LOGMODE == Session.LogMode.LOGTOFILEONLY || ...
                    obj.LOGMODE == Session.LogMode.BOTH) && ~obj.diaryOn
                    diary(obj.diaryFilePath)
                    obj.diaryOn = true;
                else
                    diary off
                    obj.diaryOn = false;
                end
            elseif off
                diary('off');
                obj.diaryOn = false;
            end
        end

        function out = get.logFilePath(obj)
            out = fullfile(obj.session.directory, ...
                            strcat(obj.logFileName,'.log'));
        end

        function out = get.diaryFilePath(obj)
            out = fullfile(obj.session.directory, ...
                            strcat(obj.logFileName,'.diary'));
        end

        function closeLog(obj)
        %CLOSELOG Close log file reference
        %
            fclose(obj.LOGFID);
        end

        function delete(obj)
        %DELETE Deconstructor of Log
        %

            if obj.LOGFID >= 0
                try
                    obj.closeLog();
                    obj.toggleDiary('off');
                catch
                end
            end

        end


    end    
        

    methods (Access=protected)

        function setupLog(obj)
        %SETUPLOG Setup the logging file
        %
            % Update OUTPUTDIR using value from inputSet
            
            if (obj.LOGMODE == Session.LogMode.LOGTOFILEONLY || ...
                obj.LOGMODE == Session.LogMode.BOTH) && ...
                obj.LOGFID == -1
                
                % Create log file
                obj.logFileName = obj.session.name;
                obj.LOGFID = fopen(obj.logFilePath(),"a+t");

            end
        end

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

