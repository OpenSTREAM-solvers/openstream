classdef (Abstract) AbstractPhase < handle
    %ABSTRACTPHASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent, Abstract, SetAccess=private)
        MFLUX
        X
        VF
        W
        U
        H
        RE
    end
end

