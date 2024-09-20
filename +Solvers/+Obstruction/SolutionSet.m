classdef SolutionSet < handle
    %SOLUTIONSET Organizes the solution sets in the ObstructionSolver
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        solutionType               {mustBeMember(solutionType, {'OBS', 'NONOBS'})} = 'NONOBS'

        inputSet (1,1) Inputs.InputSet
        
        axialStartPosition  double {mustBeNonnegative, mustBeNumeric}
        axialEndPosition    double {mustBePositive, mustBeNumeric}
        
    end

    properties (SetAccess=protected)
        solver
    end
    
    methods
        function obj = SolutionSet(solutionType, inputSet, axialBounds)
            %SOLUTIONSET Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin == 0
                return;
            end

            % Set solution type
            obj.solutionType = solutionType;

            % Save inputSet
            obj.inputSet = inputSet;

            % Set axial start/end positions
            obj.axialStartPosition = min(axialBounds);
            obj.axialEndPosition = max(axialBounds);
        end
        
        function setSolver(obj, solver)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            obj.solver = solver;

        end
    end
end

