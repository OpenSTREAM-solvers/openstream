classdef Options < Inputs.Input
    %OPTIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        ID           (1,1) string  {mustBeTextScalar}                                              % Option ID 
        TSTEP        (1,1) double  {mustBeNumeric,mustBePositive}          = 0.1                   % Time step [s]
        MAXITER      (1,1) uint8   {mustBeInteger,mustBePositive}          = 100                   % Max number of inner (point) iterations
        ERRORW       (1,1) double  {mustBeNumeric}                         = 1E-3                  % Mass flow rate error target in inner iterations [kg/s]
        ERRORP       (1,1) double  {mustBeNumeric}                         = 1E-1                  % Pressure error target in inner ierations [Pa]
        ERRORH       (1,1) double  {mustBeNumeric}                         = 1E-1                  % Enthalpy error target in inner ierations [J/kg]
        SSTSTEP      (1,1) double  {mustBeNumeric,mustBePositive}          = 1.0                   % Time step for steady-state iterations [s]
        SSMAXITER    (1,1) uint8   {mustBeInteger,mustBePositive}          = 10                    % Max number of steady-state iterations
        SSCONVW      (1,1) double  {mustBeNumeric}                         = 1E-3                  % Mass flow rate steady-state convergence criterion [kg/s]
        SSCONVP      (1,1) double  {mustBeNumeric}                         = 1E-1                  % Pressure steady-state convergence criterion [Pa]
        SSCONVH      (1,1) double  {mustBeNumeric}                         = 1E-1                  % Enthalpy steady-state convergence criterion [J/kg]
        AXIALINTERP  (1,1) string  {mustBeTextScalar}                      = 'next'                % Axial power interpolation method
        TIMEINTERP   (1,1) string  {mustBeTextScalar}                      = 'linear'              % Time-dependant boundary conditions interpolation method
        RELAXWM      (1,1) double  {mustBeInRange(RELAXWM,0,1)}            = 1                     % Relaxation factor for the mixture mass conservation equation
        RELAXPM      (1,1) double  {mustBeInRange(RELAXPM,0,1)}            = 1                     % Relaxation factor for the mixture momentum conservation equation
        RELAXHM      (1,1) double  {mustBeInRange(RELAXHM,0,1)}            = 1                     % Relaxation factor for the mixture energy conservation equation
        
        ERRORWF      (1,1) double  {mustBeNumeric}                         = 1E-4                  % Film mass flow rate error target in inner iterations [kg/s/m]
        ERRORUF      (1,1) double  {mustBeNumeric}                         = 1E-2                  % Film velocity error target in inner iterations [m/s]
        ERRORUD      (1,1) double  {mustBeNumeric}                         = 1E-2                  % Drop velocity error target in inner iterations [m/s]
        SSCONVWF     (1,1) double  {mustBeNumeric}                         = 1E-4                  % Film mass flow rate steady-state convergence criterion [kg/s/m]
        SSCONVUF     (1,1) double  {mustBeNumeric}                         = 1E-2                  % Film velocity steady-state convergence criterion [m/s]
        RELAXWF      (1,1) double  {mustBeInRange(RELAXWF,0,1)}            = 0.5                   % Relaxation factor for the film mass conservation equation
        RELAXUF      (1,1) double  {mustBeInRange(RELAXUF,0,1)}            = 0.2                   % Relaxation factor for the film momentum conservation equation
        RELAXUD      (1,1) double  {mustBeInRange(RELAXUD,0,1)}            = 0.2                   % Relaxation factor for the drop momentum conservation equation
    end

    methods
        function obj = Options(filePath,optionsID)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                filePath = ""
                optionsID = ""
            end

            % Call superclass constructor to parse file and select
            % specified modelID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', optionsID);

            % Return default value if empty inputs are given
            if strlength(filePath) == 0
                obj.ID = "DEFAULT";
                return
            end
            
            %
            % List of immutable obj property names
            objPropnames = obj.listInputProperties();
            
            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault] = obj.validateInputEntry(objPropname,id=optionsID);
                if ~useDefault
                    obj.(objPropname) = ...
                                    upper(obj.inputStruct.(objPropname));
                end
                
                if isSpecified
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
    
    methods (Static)
        function writeInputFile(filePathName, ID, varargin)
            Inputs.Input.writeInputFile_inner(filePathName, "a+", "ID", ID, varargin{:});
        end
    end

end

