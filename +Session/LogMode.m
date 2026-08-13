classdef LogMode < uint16
    %LOGMODE Enumeration of supported logging modes
    %
    % This enumeration defines the available logging configurations
    % for the simulation framework. It is used to control whether
    % messages and warnings are printed to the console, written to a file,
    % both, or suppressed entirely.

    enumeration
        NONE                (0)      % No logging output
        LOGTOFILEONLY       (1)      % Log messages to file only
        LOGTOCONSOLEONLY    (2)      % Log messages to console only
        BOTH                (3)      % Log messages to both console and file
    end
end