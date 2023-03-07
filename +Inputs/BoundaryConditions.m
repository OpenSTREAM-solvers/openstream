classdef BoundaryConditions < Inputs.Input
    %BOUNDARYCONDITIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        TIME       (:,1) double  {mustBeNumeric,mustBeNonempty}            = 0                     % Time [s]
        PRESSURE   (:,1) double  {mustBePositive,mustBeNonempty}           = 1                     % System pressure [Pa]
        HIN        (:,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Inlet enthalpy [J/kg]
        MFLOW      (:,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Mass flow rate [kg/s]
        POWER      (:,1) double  {mustBeNonnegative,mustBeNonempty}        = 1                     % Total power [W]
        WMESH      (:,:) double  {mustBePositive,mustBeNonempty}           = 1                     % Relative power node size distribution [m]
        WPOWER     (:,:) double  {mustBeNonnegative,mustBeNonempty}        = 1                     % Relative power distribution(s) [-] 
        
    end

    methods
        function obj = BoundaryConditions(filePath, geometryInput)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here

            % Call superclass constructor to parse file
            obj = obj@Inputs.Input(filePath)
            
            %
            % List of obj property names
            objPropnames = string({metaclass(obj).PropertyList.Name}.');
            
            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is valid
                if obj.validateInputEntry(objPropname)
                    obj.(objPropname) = ...
                                    [obj.inputStruct.(objPropname)];
                    
                    % Remove objPropname from inputStruct
                    obj.inputStruct = rmfield(obj.inputStruct, objPropname);
                end
            end

            % If extra fields in obj.inputStruct remain, warn user
            remainingInputStructFields = fieldnames(obj.inputStruct);
            if ~isempty(remainingInputStructFields)
                warning( ...
                    'BOUNDARY_CONDITIONS: These inputs were not used: %s ', ...
                    remainingInputStructFields{:} ...
                    );
            end
            
            % Transpose WMESH
            obj.WMESH = obj.WMESH.';

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

        end
        

    end

end

