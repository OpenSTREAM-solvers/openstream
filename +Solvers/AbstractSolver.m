classdef (Abstract) AbstractSolver < handle
    %ABSTRACTSOLVER Summary of this class goes here
    %   Detailed explanation goes here
    

    methods (Abstract)
        mflux = MFLUX
        xeq = XEQ
        x = X
        vf = VF
        rho = RHO
        mu = MU
        u = U
        jl = JL
        jg = JG
        re = RE
        rel = REL
        fw = FW
        tauw = TAUW
        kloss = KLOSS
        dpk = DPK
        t = T

        solve
        plotz
    end
end

