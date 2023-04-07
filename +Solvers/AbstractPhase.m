classdef (Abstract) AbstractPhase < handle
    %ABSTRACTPHASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        TIME
        Z
    end

    methods (Abstract)
        mflux = MFLUX
        x = X
        vf = VF
        w = W
        u = U
        h = H
        re = RE
    end
end

