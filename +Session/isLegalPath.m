function bool = isLegalPath(pathname)
%ISLEGALPATH Checks if the given pathname is valid on the current operating system
%
% This function attempts to convert the input pathname to a Java Path object.
% If the conversion succeeds, the path is considered legal and the function returns true.
% If an exception is thrown during conversion, the path is considered illegal and the function returns false.
%
% Input:
% - pathname — String representing the file or folder path to validate
%
% Output:
% - bool     — Logical true if the path is valid, false otherwise

bool = true;
try
    java.io.File(pathname).toPath;
catch
    bool = false;
end

end