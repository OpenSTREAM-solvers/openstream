function [ver, majorVersion,minorVersion,updateVersion] = openstreamVersion()
%OPENSTREAMVERSION Return the current OpenSTREAM version.
%
%   [VER, MAJOR, MINOR, UPDATE] = OPENSTREAMVERSION() returns the
%   OpenSTREAM version as a string and its individual version components.
%
%   VER is the full version string. MAJOR, MINOR, and UPDATE are the
%   corresponding numeric version components.
%
%   Example:
%       [ver, major, minor, update] = openstreamVersion()

ver = "2026.0";

ver_parts = strsplit(ver, ".");

majorVersion = 0;
minorVersion = 0;
updateVersion = 0;

if numel(ver_parts) >= 1, majorVersion =  str2double(ver_parts(1)); end
if numel(ver_parts) >= 2, minorVersion =  str2double(ver_parts(2)); end
if numel(ver_parts) >= 3, updateVersion = str2double(ver_parts(3)); end


end

