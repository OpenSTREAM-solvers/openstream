classdef Log < handle
    %LOG Console and file-based logging manager
    %
    % This class manages logging of messages and warnings to console and/or file.
    % It supports multiple logging modes, integrates with session management,
    % and provides diary functionality for persistent logs.

    properties (SetAccess = protected)

        LOGMODE               (1,1) Session.LogMode                        % Logging mode (console only, file only, both, or none)
        diaryIsOn             (1,1) logical         = false                % Flag indicating whether MATLAB diary is active

        % log file
        LOGFID                                      = -1                   % File ID for log file
        logFileName           (1,1) string                                 % Name of the log file (without extension)

        % Warnings
        showWarnings          (1,1) logical         = true                 % Flag to control display of warnings

    end

    properties (Access = private)

        session               (1,1)                                        % Session object for directory and naming context
        keepLogOpen           (1,1) logical         = false                % Flag to keep log file open between writes

    end

    properties (Dependent)

        logFilePath           (1,1) string                                 % Full path to the log file
        diaryFilePath         (1,1) string                                 % Full path to the diary file

    end

    methods

        function obj = Log(LOGMODE, opts)
            %LOG Constructor for Log class
            %
            % Initializes logging mode, session context, and warning settings.
            % Creates log file and session directory if needed.
            %
            % Inputs:
            %
            % - LOGMODE          — Determines where logs go (console, file, both, or none), using :class:`Session.LogMode`.
            % - opt.session      — Session object for directory and naming context
            % - opt.LOGFID       — File ID for the open log file.
            % - opt.showWarnings — Whether to display warnings in the console.

            arguments
                LOGMODE           (1,1)    Session.LogMode  = Session.LogMode.LOGTOCONSOLEONLY
                % LogMode
                opts.session      (1,1)    Session.Session
                opts.LOGFID       (1,1)    double           = -1
                opts.showWarnings (1,1)    logical          = true
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

            % Show warnings
            if isfield(opts, 'showWarnings')
                obj.showWarnings = opts.showWarnings;
            else
                obj.showWarnings = true;
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
            %LOG Logs messages to console and/or file depending on LOGMODE

            import Session.LogMode

            if obj.LOGMODE == LogMode.NONE
                return
            end
            
            % Write to log file
            if (obj.LOGMODE == LogMode.LOGTOFILEONLY || ...
                    obj.LOGMODE == LogMode.BOTH)

                % Open the log file
                obj.openLog();

                % Write to the log
                builtin('fprintf',obj.LOGFID, varargin{:});

                % Close the log if keepLogOpen is unset
                if ~obj.keepLogOpen
                    obj.closeLog();
                end
            end

            % Write to console
            if (obj.LOGMODE == LogMode.LOGTOCONSOLEONLY || ...
                    obj.LOGMODE == LogMode.BOTH)
                builtin('fprintf',varargin{:});
            end
        end

        function warning(obj, varargin)
            %WARNING Logs warnings using MATLAB's built-in warning mechanism

            import Session.LogMode

            % Display on console (and diary, if on)
            if obj.showWarnings
                % Use built-in warning function
                builtin('warning', varargin{:});            
            end

            % Write to log file
            if obj.LOGMODE == LogMode.LOGTOFILEONLY || ...
                    obj.LOGMODE == LogMode.BOTH

                % Open the log file
                obj.openLog();

                % Format warning for the log file
                if numel(varargin) >= 2 && ...
                        (ischar(varargin{1}) || isStringScalar(varargin{1})) && ...
                        contains(string(varargin{1}), ':')
                    warningID = string(varargin{1});
                    warningMessage = sprintf(varargin{2}, varargin{3:end});
                    builtin('fprintf', obj.LOGFID, ...
                        'Warning [%s]: %s\n', warningID, warningMessage);
                else
                    warningMessage = sprintf(varargin{:});
                    builtin('fprintf', obj.LOGFID, ...
                        'Warning: %s\n', warningMessage);
                end

                % Close the log if keepLogOpen is unset
                if ~obj.keepLogOpen
                    obj.closeLog();
                end
            end
        end

        function diaryOff(obj)
            %DIARYOFF Turn off diary logging

            diary('off');
            obj.diaryIsOn = false;
        end

        function diaryOn(obj)
            %DIARYON Turn on diary logging if applicable

            % TODO: re-evaluate if using the diary is needed. What does
            % the diary do that the log doesn't? If we find a use case,
            % describe it here.

            if (obj.LOGMODE == Session.LogMode.LOGTOFILEONLY || ...
                    obj.LOGMODE == Session.LogMode.BOTH) && ~obj.diaryIsOn

                diary(obj.diaryFilePath)
                obj.diaryIsOn = true;
            end
        end

        function out = get.logFilePath(obj)
            % Returns full path to log file

            out = fullfile(obj.session.directory, ...
                strcat(obj.logFileName,'.log'));
        end

        function out = get.diaryFilePath(obj)
            % Returns full path to diary file

            out = fullfile(obj.session.directory, ...
                strcat(obj.logFileName,'.diary'));
        end

        function delete(obj)
            %DELETE Destructor for log class
            %
            % Ensures log file and diary are properly closed

            try
                if obj.LOGFID >= 0
                    obj.closeLog();
                end

                if obj.diaryIsOn
                    obj.diaryOff();
                end
            catch
            end
        end

        function openLog(obj, opts)
            %OPENLOG Opens log file for writing
            %
            % Optionally keeps it open between writes

            arguments
                obj
                opts.keepLogOpen = false         % Keep log open
            end

            if (obj.LOGMODE == Session.LogMode.LOGTOFILEONLY || ...
                    obj.LOGMODE == Session.LogMode.BOTH) && ...
                    obj.LOGFID == -1

                % Create log file
                obj.logFileName = obj.session.name;
                [obj.LOGFID, msg] = fopen(obj.logFilePath(),"a+t");

                % Check that log file was opened successfully
                if obj.LOGFID == -1
                    error('OpenSTREAM:Log:openLogError', ...
                        'Unable to open log file %s: %s', ...
                        obj.logFilePath(), msg);
                end

                % Update obj.keepLogOpen if specified
                if opts.keepLogOpen
                    obj.keepLogOpen = true;
                end
            end
        end

        function closeLog(obj)
            %CLOSELOG Closes log file and resets file ID
            if obj.LOGFID >= 0
                fclose(obj.LOGFID);
                obj.LOGFID = -1;

                % Reset obj.keepLogOpen
                obj.keepLogOpen = false;
            end
        end

        function closeAll(obj)
            %CLOSEALL Close the log file and turn off the diary if active

            obj.closeLog();
            if obj.diaryIsOn
                obj.diaryOff();
            end
        end

    end

end
