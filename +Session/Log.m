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

        function warning(obj, varargin)
            %WARNING Logs warnings using MATLAB's built-in warning mechanism
            %
            % Optionally writes to file if warnings are suppressed

            import Session.LogMode

            if obj.showWarnings == true

                % Use built-in warning function
                builtin('warning', varargin{:});

                % Since the warning is displayed using the built-in function,
                % recording-to-file depends on diary on or off.

            else
                % If LOGTOFILEONLY, open and write to log
                if obj.LOGMODE == LogMode.LOGTOFILEONLY || ...
                        obj.LOGMODE == LogMode.BOTH

                    % Open the log file
                    obj.openLog();

                    % Write warnings to the log
                    builtin('fprintf',obj.LOGFID, 'Warning:\n');
                    builtin('fprintf',obj.LOGFID, '%s\n', varargin{:});

                    % Close the log if keepLogOpen is unset
                    if ~obj.keepLogOpen
                        obj.closeLog();
                    end

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

            if obj.LOGFID >= 0
                try
                    obj.closeLog();
                    obj.diaryOff();
                catch
                end
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
            %CLOSELOG Closes log file and resets file ID
            if obj.LOGFID >= 0
                fclose(obj.LOGFID);
                obj.LOGFID = -1;

                % Reset obj.keepLogOpen
                obj.keepLogOpen = false;
            end
        end

    end

end
