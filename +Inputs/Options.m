classdef Options < Inputs.Input
    %OPTIONS Class for defining and managing numerical solver options
    %
    % This class encapsulates all numerical parameters used in the simulations,
    % including time stepping, convergence criteria, and relaxation factors
    % for all solvers. It reads options data from input files and handles default
    % values as well as input validation.

    properties (SetAccess=?Inputs.Input)

        ID               (1,1) string  {mustBeTextScalar}                                          % Identifier for the options configuration
        AXIALINTERP      (1,1) string  {mustBeTextScalar}                  = 'next'                % Method for interpolating axial power distribution
        TIMEINTERP       (1,1) string  {mustBeTextScalar}                  = 'linear'              % Method for interpolating time-dependent boundary conditions
        TSTEP            (1,1) double  {mustBeNumeric,mustBePositive}      = 0.1                   % Time step size for transient simulations [s]
        MAXITER          (1,1) uint8   {mustBeInteger,mustBePositive}      = 100                   % Maximum number of inner iterations per time step
        SSTSTEP          (1,1) double  {mustBeNumeric,mustBePositive}      = 1.0                   % Time step size for steady-state iterations [s]
        SSMAXITER        (1,1) uint8   {mustBeInteger,mustBePositive}      = 30                    % Maximum number of steady-state iterations

        % Mixture solver options

        MRMTIMEINT       (1,1) InputEnums.MRMTIMEINT                       = 'EXPONENTIAL'         % Time integration for vapor mass/energy conservation equations
        ERRORW           (1,1) double  {mustBeNumeric}                     = 1E-3                  % Mass flow rate error target in inner iterations [kg/s]
        ERRORP           (1,1) double  {mustBeNumeric}                     = 1E-1                  % Pressure error target in inner iterations [Pa]
        ERRORH           (1,1) double  {mustBeNumeric}                     = 1E-1                  % Enthalpy error target in inner iterations [J/kg]
        SSCONVW          (1,1) double  {mustBeNumeric}                     = 1E-3                  % Mass flow rate steady-state convergence criterion [kg/s]
        SSCONVP          (1,1) double  {mustBeNumeric}                     = 1E+0                  % Pressure steady-state convergence criterion [Pa]
        SSCONVH          (1,1) double  {mustBeNumeric}                     = 1E+0                  % Enthalpy steady-state convergence criterion [J/kg]
        RELAXWM          (1,1) double  {mustBeInRange(RELAXWM,0,1)}        = 1.0                   % Relaxation factor for the mixture mass conservation equation [-]
        RELAXPM          (1,1) double  {mustBeInRange(RELAXPM,0,1)}        = 1.0                   % Relaxation factor for the mixture momentum conservation equation [-]
        RELAXHM          (1,1) double  {mustBeInRange(RELAXHM,0,1)}        = 1.0                   % Relaxation factor for the mixture energy conservation equation [-]

        % Mixture (MRM) solver options

        RELAXWV          (1,1) double  {mustBeInRange(RELAXWV,0,1)}        = 0.7                   % Relaxation factor for the vapor  mass conservation equation [-]
        RELAXHV          (1,1) double  {mustBeInRange(RELAXHV,0,1)}        = 0.7                   % Relaxation factor for the vapor  energy conservation equation [-]

        % Two-fluid solver options

        ERRORU           (1,1) double  {mustBeNumeric}                     = 1E-4                  % Velocity error target in inner iterations [m/s]
        SSCONVU          (1,1) double  {mustBeNumeric}                     = 1E-3                  % Velocity steady-state convergence criterion [m/s]
        RELAXWL          (1,1) double  {mustBeInRange(RELAXWL,0,1)}        = 1                     % Relaxation factor for the liquid mass conservation equation [-]
        RELAXUL          (1,1) double  {mustBeInRange(RELAXUL,0,1)}        = 0.5                   % Relaxation factor for the liquid momentum conservation equation [-]
        RELAXUV          (1,1) double  {mustBeInRange(RELAXUV,0,1)}        = 0.5                   % Relaxation factor for the vapor  momentum conservation equation [-]
        RELAXHL          (1,1) double  {mustBeInRange(RELAXHL,0,1)}        = 1                     % Relaxation factor for the liquid energy conservation equation [-]

        % Three-field solver options

        ERRORWF          (1,1) double  {mustBeNumeric}                     = 1E-4                  % Film mass flow rate error target in inner iterations [kg/s/m]
        ERRORUF          (1,1) double  {mustBeNumeric}                     = 1E-2                  % Film velocity error target in inner iterations [m/s]
        ERRORUD          (1,1) double  {mustBeNumeric}                     = 1E-2                  % Drop velocity error target in inner iterations [m/s]
        SSCONVWF         (1,1) double  {mustBeNumeric}                     = 1E-4                  % Film mass flow rate steady-state convergence criterion [kg/s/m]
        SSCONVUF         (1,1) double  {mustBeNumeric}                     = 1E-2                  % Film velocity steady-state convergence criterion [m/s]
        SSCONVUD         (1,1) double  {mustBeNumeric}                     = 1E-2                  % Drop velocity steady-state convergence criterion [m/s]
        RELAXWF          (1,1) double  {mustBeInRange(RELAXWF,0,1)}        = 0.5                   % Relaxation factor for the film mass conservation equation [-]
        RELAXUF          (1,1) double  {mustBeInRange(RELAXUF,0,1)}        = 0.2                   % Relaxation factor for the film momentum conservation equation [-]
        RELAXUD          (1,1) double  {mustBeInRange(RELAXUD,0,1)}        = 0.2                   % Relaxation factor for the drop momentum conservation equation [-]

        % Four-field solver options
        
        ERRORFW          (1,1) double  {mustBeNumeric}                     = 1E-1                  % Wave frequency error target in inner iterations [Hz]
        SSCONVFW         (1,1) double  {mustBeNumeric}                     = 1E-1                  % Wave frequency steady-state convergence criterion [Hz]
        RELAXWB          (1,1) double  {mustBeInRange(RELAXWB,0,1)}        = 0.5                   % Relaxation factor for the base mass conservation equation [-]
        RELAXUB          (1,1) double  {mustBeInRange(RELAXUB,0,1)}        = 0.2                   % Relaxation factor for the base momentum conservation equation [-]
        RELAXWW          (1,1) double  {mustBeInRange(RELAXWW,0,1)}        = 0.5                   % Relaxation factor for the wave mass conservation equation [-]
        RELAXUW          (1,1) double  {mustBeInRange(RELAXUW,0,1)}        = 0.2                   % Relaxation factor for the wave momentum conservation equation [-]
        RELAXFW          (1,1) double  {mustBeInRange(RELAXFW,0,1)}        = 0.5                   % Relaxation factor for the wave number conservation equation [-]

    end

    methods

        function obj = Options(filePath,optionsID)
            %OPTIONS Constructor for Options class
            %
            % Parses options input file and initializes properties.
            % Applies default values and validates entries.
            %
            % Inputs:
            %
            % - filePath  — Path to options input file
            % - optionsID — Identifier for options configuration

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

            % Array of fieldnames using default values
            defaultValueFieldNames = string().empty();
            defaultValues = {};

            % Iterate through obj property names
            for idx = 1:length(objPropnames)

                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);

                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault, defaultValue] = obj.validateInputEntry(objPropname,id=optionsID);
                if ~useDefault
                    obj.(objPropname) = ...
                        upper(obj.inputStruct.(objPropname));
                elseif useDefault
                    defaultValueFieldNames(end+1) = objPropname;
                    defaultValues{end+1} = defaultValue;
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
                    'Options: These inputs were not used: %s ', ...
                    remainingInputStructFields{:} ...
                    );
                obj.extra = obj.inputStruct;
            end

            % Default value used warning
            if ~isempty(defaultValueFieldNames)
                defaultValueWarningString = obj.defaultValueUsedReport(defaultValueFieldNames, defaultValues);
                if nargout == 0
                    warning('Options:defaultValueUsedWarning', ...
                        sprintf('%s\n',defaultValueWarningString));
                else
                    w = struct('warnID', 'Options:defaultValueUsedWarning', ...
                        'msg', defaultValueWarningString);
                    if isempty(obj.warnings)
                        obj.warnings = w;
                    else
                        obj.warnings(end+1) = w;
                    end
                end
            end


            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)
        end

    end

    methods (Static)

        function writeInputFile(filePathName, ID, varargin)
            % Writes numerical options configuration to input file
            %
            % Inputs:
            %
            % - filePathName — Path to output file
            % - ID           — Options identifier
            % - varargin     — Additional name-value pairs for options properties

            Inputs.Input.writeInputFile(filePathName, "a+", "ID", ID, varargin{:});
        end

    end

end
