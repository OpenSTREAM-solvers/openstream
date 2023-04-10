classdef Options < Inputs.Input
    %OPTIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        ID           (1,1) string  {mustBeTextScalar,mustBeNonempty}                               % Option ID 
        TSTEP        (1,1) double  {mustBeNumeric,mustBePositive}          = 0.1                   % [s] Time step
        MAXITER      (1,1) uint8   {mustBeInteger,mustBePositive}          = 100                   % Max number of inner (point) iterations
        ERRORW       (1,1) double  {mustBeNumeric}                         = 1E-3                  % Mass flow rate error target in inner iterations [kg/s]
        ERRORP       (1,1) double  {mustBeNumeric}                         = 1E-0                  % Pressure error target in inner ierations [Pa]
        ERRORH       (1,1) double  {mustBeNumeric}                         = 1E-0                  % Enthalpy error target in inner ierations [J/kg]
        SSMAXITER    (1,1) uint8   {mustBeInteger,mustBePositive}          = 10                    % Max number of steady-state iterations
        SSCONVW      (1,1) double  {mustBeNumeric}                         = 2E-4                  % Mass flow rate steady-state convergence criterion [kg/s]
        SSCONVP      (1,1) double  {mustBeNumeric}                         = 1E-0                  % Pressure steady-state convergence criterion [Pa]
        SSCONVH      (1,1) double  {mustBeNumeric}                         = 1E-0                  % Enthalpy steady-state convergence criterion [J/kg]
        AXIALINTERP  (1,1) string  {mustBeTextScalar}                      = 'next'                % Axial power interpolation method
        TIMEINTERP   (1,1) string  {mustBeTextScalar}                      = 'linear'              % Time-dependant boundary conditions interpolation method
        RELAXWM      (1,1) double  {mustBeInRange(RELAXWM,0,1)}            = 1                     % Relaxation factor for the mixture mass conservation equation
        RELAXPM      (1,1) double  {mustBeInRange(RELAXPM,0,1)}            = 1                     % Relaxation factor for the mixture momentum conservation equation
        RELAXHM      (1,1) double  {mustBeInRange(RELAXHM,0,1)}            = 1
        
    end

    methods
        function obj = Options(filePath,optionsID)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here

            % Call superclass constructor to parse file and select
            % specified modelID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', optionsID)
            
            %
            % List of immutable obj property names
            objPropnames = obj.listInputProperties();
            
            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is valid
                if obj.validateInputEntry(objPropname,id=optionsID)
                    obj.(objPropname) = ...
                                    upper(obj.inputStruct.(objPropname));

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

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)

        end
        

    end

end

