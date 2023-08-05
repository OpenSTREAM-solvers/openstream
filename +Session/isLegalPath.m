function bool = isLegalPath(pathname)
%ISLEGALPATH Determine if a path is legal in current OS
    bool = true;
    try
        java.io.File(pathname).toPath;
    catch
        bool = false;
    end
end