classdef (Abstract) AbstractSolver < handle
    %ABSTRACTSOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private, Abstract)

        STATE (1,1) Solvers.SolverState                                           % Solver state defined by SolverState enum

    end

    methods (Abstract)
%         mflux = MFLUX
%         xeq = XEQ
%         x = X
%         vf = VF
%         rho = RHO
%         mu = MU
%         u = U
%         jl = JL
%         jg = JG
%         re = RE
%         rel = REL
%         fw = FW
%         tauw = TAUW
%         kloss = KLOSS
%         dpk = DPK
%         t = T

        solve
%         plotz
    end
end

