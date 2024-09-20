classdef SOLVER
%SOLVER Name of available solver
%   Defines the solver name
%
    enumeration
        MIXTURE
        TWOFLUID
        THREEFIELD
        FOURFIELD
        OBSTRUCTION
    end

    methods

        function solverPath = solverPath(enum)
            import InputEnums.SOLVER

            switch (enum)
                case SOLVER.MIXTURE     
                    solverPath = "Mixture.MixtureSolver";
                case SOLVER.TWOFLUID    
                    solverPath = "TwoFluid.TwoFluidSolver";
                case SOLVER.THREEFIELD  
                    solverPath = "ThreeField.ThreeFieldSolver";
                case SOLVER.FOURFIELD   
                    solverPath = "FourField.FourFieldSolver";
                case SOLVER.OBSTRUCTION 
                    solverPath = "Obstruction.ObstructionSolver";
                otherwise
                    error("Unknown solver name");
            end

        end

    end
end
    
