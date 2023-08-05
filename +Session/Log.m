classdef Log < handle
    %LOG Console log manager
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)

        LOGMODE               (1,1) Session.LogMode
        diaryIsOn               (1,1) logical         = false

        % log file
        LOGFID                              = -1                                 % Logging file ID
        logFileName           (1,1) string
    end

    properties (Access = private)
        session         (1,1)
        keepLogOpen     (1,1) logical                     = false
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
                opts.LOGFID    (1,1)    double                = -1
            end

            % Store LOGMODE and LOGFID
            obj.LOGMODE = LOGMODE;
            if ~isempty(fopen(opts.LOGFID))
                obj.LOGFID = opts.LOGFID;
            end

            % Store session
            if isfield(opts, 'session')
                obj.session = opts.session;
            else
                return;
            end

            % Make logging filesystem as needed
            switch obj.LOGMODE
                case {Session.LogMode.NONE, Session.LogMode.LOGTOCONSOLEONLY}
                    % Do nothing
                case {Session.LogMode.LOGTOFILEONLY, Session.LogMode.BOTH}
                    
                    % Make session directory
                    obj.session.makeSessionDirectory();

                    % Make log file
                    obj.openLog();

                    % Close log
                    obj.closeLog();
                    
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
                    obj.openLog();
                    builtin('fprintf',obj.LOGFID, varargin{:});
                    if ~obj.keepLogOpen
                        obj.closeLog();
                    end
                end
                if (obj.LOGMODE == LogMode.BOTH || ...
                        obj.LOGMODE == LogMode.LOGTOCONSOLEONLY)
                    builtin('fprintf',varargin{:}); 
                end
            end
        end

        function diaryOff(obj)
        %DIARYOFF   Turn diary off
            diary('off');
            obj.diaryIsOn = false;
        end

        function diaryOn(obj)
        %DIARYON    Turn diary on
            if (obj.LOGMODE == Session.LogMode.LOGTOFILEONLY || ...
                obj.LOGMODE == Session.LogMode.BOTH) && ~obj.diaryIsOn
                
                diary(obj.diaryFilePath)
                obj.diaryIsOn = true;
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

        function delete(obj)
        %DELETE Deconstructor of Log
        %

            if obj.LOGFID >= 0
                try
                    obj.closeLog();
                    obj.diaryOff();
                catch
                end
            end

        end

        function openLog(obj, opts)
        %SETUPLOG Open/Setup the logging file
        %
        arguments
            obj
            opts.keepLogOpen = false         % Keep log open
        end
            % Update OUTPUTDIR using value from inputSet
            
            if (obj.LOGMODE == Session.LogMode.LOGTOFILEONLY || ...
                obj.LOGMODE == Session.LogMode.BOTH) && ...
                obj.LOGFID == -1
                
                % Create log file
                obj.logFileName = obj.session.name;
                obj.LOGFID = fopen(obj.logFilePath(),"a+t");

                % Update obj.keepLogOpen if specified
                if opts.keepLogOpen
                    obj.keepLogOpen = true;
                end

            end
        end

        function closeLog(obj)
        %CLOSELOG Close log file reference
        %
            if obj.LOGFID >= 0
                fclose(obj.LOGFID);
                obj.LOGFID = -1;

                % Reset obj.keepLogOpen
                obj.keepLogOpen = false;
            end
        end


    end    

end

