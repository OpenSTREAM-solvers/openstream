classdef Model < Inputs.Input
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        ID               (1,1) string  {mustBeTextScalar}                                          % Model ID 
        NNODES                 double  {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} ...
                                                                           = []                    % Number of axial nodes 
        FLUID            (1,1) string  {mustBeTextScalar}                  = "WATER"               % Fluid ID
        PROPERTIES       (1,1) InputEnums.FLUIDPROPERTIES                  = 'SATURATED'           % Fluid property assumptions
        ANGLE            (1,1) double  {mustBeNumeric}                     = 0                     % Flow axis angle from vertical [deg]
        
        % Mixture solver models
        FRICTION         (1,3) double  {mustBeNumeric}                     = [0.2 -0.2 0]          % Wall friction coefficients [-]
        TPFM             (1,1) InputEnums.TPFM                             = 'HOMOGENEOUS'         % Two-phase friction multiplier
        KLOC             (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                 % Elevation of local perturbations [m] 
        KLOSS            (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                 % corresponding pressure loss coefficients [-]
        TPKM             (1,1) InputEnums.TPKM                             = 'HOMOGENEOUS'         % Two-phase local loss multiplier
        VOID             (1,1) InputEnums.VOID                             = 'HOMOGENEOUS'         % Void fraction model 
        SLIP             (1,1) double  {mustBePositive}                    = 1                     % Phase velocity ratio [-]
        CBT              (1,1) InputEnums.CBT                              = 'NONE'                % Critical Boiling Transition model 
        THERMALNONEQ     (1,1) InputEnums.THERMALNONEQ                     = 'EQUILIBRIUM'         % Thermal non-equilibrum model
        RELAXX           (1,:) double                                      = [-0.5 0.0]            % Thermal non-equilibrium interfacial phase change relaxation time thermodynamic quality [-]
        RELAXT           (1,:) double                                      = [0.15 0.10 0.10 0.01] % Thermal non-equilibrium interfacial phase change relaxation time array, at post-CBT and at local perturbations [s]
        WBOILINGX0       (1,1) double  {mustBeNegative}                    = -1                    % Thermal non-equilibrium thermodynamic quality at onset of wall boiling evaporation [-]
        WBOILINGN        (1,1) double  {mustBePositive}                    = 1                     % Thermal non-equilibrium exponent of wall boiling function [-]
        
        % Two-fluid solver models
        MOMENTLIQUID     (1,1) InputEnums.MOMENTLIQUID                     = 'SLIP'                % Liquid momentum conservation model
        MOMENTGAS        (1,1) InputEnums.MOMENTGAS                        = 'SLIP'                % Gas momentum conservation model  
        BOILCOEF         (1,1) InputEnums.BOILCOEF                         = 'QUADRATIC'           % Subcooled boiling interpolation
        INTLENGTH        (1,1) InputEnums.INTLENGTH                        = 'CONSTANT'            % Interfacial length scale model model
        INTAREA          (1,1) InputEnums.INTAREA                          = 'DISPGAS2DISPLIQ'     % Interfacial area model
        INTLENGTHCST     (1,1) double                                      = 2E-3                  % Constant interfacial length scale [m]
        INTTRANSH        (1,1) InputEnums.INTTRANSH                        = 'BULK'                % Interfacial enthalpy transfer model
        INTNU            (1,1) InputEnums.INTNU                            = 'CONSTANT'            % Interfacial heat transfer model
        INTNUVCST        (1,1) double                                      = 2.0                   % Dispersed gas constant interfacial Nusselt number [-]
        INTNULCST        (1,1) double                                      = 2.0                   % Dispersed liquid constant interfacial Nusselt number [-]        
        RANZMARSHALLVCST (1,4) double                                      = [2 0.6 1/2 1/3]       % Dispersed gas Ranz-Marshall coefficients [-]
        RANZMARSHALLLCST (1,4) double                                      = [2 0.6 1/2 1/3]       % Dispersed liquid Ranz-Marshall coefficients [-]
        LOCRELVEL        (1,1) InputEnums.LOCRELVEL                        = 'SCALED'              % Local relative velocity model
        RELVELCST        (1,1) double                                      = 1E-1                  % Multiplication factor to determine the local relative velocity [-]
        RELAXTCOND       (1,1) double                                      = 0.2                   % Condensation relaxation time [s]
        RELAXTEVAP       (1,1) double                                      = 0.2                   % Evaporation relaxation time [s]
        
        % Three-field solver models
        POSFILM          (1,1) logical                                     = true                  % Keep positive film flowrate/thickness
        OAF              (1,1) InputEnums.OAF                              = 'WALLIS'              % Onset of annular flow model
        OAFENTRAINED     (1,1) InputEnums.OAFENTRAINED                     = 'EQUILIBRIUM'         % Entrained model at onset of annular flow
        OAFDROPRATIO     (1,1) double  {mustBeInRange(OAFDROPRATIO,0,1)}   = 0.7                   % Drop/Liquid mass ratio at onset of annular flow [-]
        OAFTRANSITION    (1,2) double  {mustBeNumeric}                     = [0.10 0.0]            % Annular flow transition function parameters (sigmoid width/location wrt OAF) [m]
        DEPOSITION       (1,1) InputEnums.DEPOSITION                       = 'OKAWA'               % Drop deposition model
        ENTRAINMENT      (1,1) InputEnums.ENTRAINMENT                      = 'OKAWA2003'           % Film entrainment model
        MOMENTFILM       (1,1) InputEnums.MOMENTFILM                       = 'ALGEBRAIC'           % Film momentum conservation model
        VAPORFRIC        (1,1) InputEnums.VAPORFRIC                        = 'WALLIS'              % Vapor friction model
        VAPORFRICCST     (1,1) double  {mustBePositive}                    = 0.005                 % Vapor friction constant [-]
        THINFILMFRIC     (1,1) InputEnums.THINFILMFRIC                     = 'TURBULENT'           % Thin film wall friction model
        THINFILMTHICK    (1,1) double  {mustBePositive}                    = 1E-4                  % Minimum thin film thickness [m]        
        MOMENTDROP       (1,1) InputEnums.MOMENTDROP                       = 'SLIP'                % Drop momentum conservation model                                                           
        DROPSLIP         (1,1) double  {mustBePositive}                    = 1.0                   % Drop/vapor velocity ratio [-]
        DROPDIAM         (1,1) double  {mustBePositive}                    = 1E-3                  % Drop diameter [mm]
        DROPDRAG         (1,1) InputEnums.DROPDRAG                         = 'CONSTANT'            % Drop drag model
        DROPDRAGCOEF     (1,1) double  {mustBePositive}                    = 0.45                  % Drop drag coefficient [-]

        % Four-field solver models
        OAFFILMSPLIT     (1,1) InputEnums.OAFFILMSPLIT                     = 'EQUILIBRIUM'         % Film mass flow split model at onset of annular flow
        OAFBASERATIO     (1,1) double  {mustBeInRange(OAFBASERATIO,0,1)}   = 0.5                   % Base/Film mass ratio at onset of annular flow [-]
        BASEEQTHICK      (1,1) InputEnums.BASEEQTHICK                      = 'RISO'                % Equilibrium base film thickness model
        BASEEQTHICKCOEF  (:,1) double  {mustBeNumeric}                     = [5.37E-5 -0.64 1.21]  % Equilibrium base film thickness coefficients [-]
        RELAXTB          (:,1) double  {mustBeNonnegative}                 = 0.2                   % Base film / wave mass exchange relaxation time [s]
        WAVEMIXCOEF      (:,1) double  {mustBeNonnegative}                 = 2                     % Base film / wave turbulent mixing coefficient
        WAVEFREQUENCY    (1,1) InputEnums.WAVEFREQUENCY                    = 'RELAXATION'          % Wave number density model   
        EQSTROUHAL       (1,1) InputEnums.EQSTROUHAL                       = 'RISO'                % Equilibrium wave Strouhal number model
        EQSTROUHALCOEF   (:,1) double {mustBeNumeric}                      = [1.1236E-4 0.5 0.0]   % Equilibrium wave Strouhal number coefficients [-]
        RELAXTW          (:,1) double  {mustBeNonnegative}                 = 0.2                   % Wave number density relaxation time [s]
        MOMENTBASE       (1,1) InputEnums.MOMENTBASE                       = 'FULLNOP'             % Base film momentum conservation model
        MOMENTWAVE       (1,1) InputEnums.MOMENTWAVE                       = 'FULL'                % Wave momentum conservation model
        WAVEBASEINT      (1,1) InputEnums.WAVEBASEINT                      = 'VAPORSHEAR'          % Wave / base film interfacial momentum transfer model
        SHAPEFACTORCOEF  (:,1) double {mustBeNumeric}                      = [1.325E5 2]           % Wave shape factor coefficients [-]
        WAVEDRAGCOEF     (:,1) double  {mustBeNumeric}                     = [0.02 1.350E5 0.437]  % Wave drag coefficient [-]
        THINWAVETHICK    (1,1) double  {mustBePositive}                    = 1E-5                  % Minimum thin wave thickness [m]   

    end

    properties (Constant)
        G             (1,1) double  {mustBeNumeric}                        = 9.81                  % [m/s^2] Gravitational acceleration
    end

    methods
        function obj = Model(filePath,modelID)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                filePath = ""
                modelID = ""
            end

            % Call superclass constructor to parse file and select
            % specified modelID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', modelID)

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
                [isSpecified, useDefault, defaultValue] = obj.validateInputEntry(objPropname,id=modelID);
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

            % Default value used warning
            if ~isempty(defaultValueFieldNames)
                defaultValueWarningString = obj.defaultValueUsedReport(defaultValueFieldNames, defaultValues);
                if nargout == 0
                    warning('Model:defaultValueUsedWarning', ...
                        sprintf('%s\n',defaultValueWarningString));
                else
                    w = struct('warnID', 'Model:defaultValueUsedWarning', ...
                               'msg', defaultValueWarningString);
                    if isempty(obj.warnings)
                        obj.warnings = w;
                    else
                        obj.warnings(end+1) = w;
                    end
                end
            end

            % If extra fields in obj.inputStruct remain, warn user
            remainingInputStructFields = fieldnames(obj.inputStruct);
            if ~isempty(remainingInputStructFields)
                warning( ...
                    '%s: These entries were not used: \n\t %s ', ...
                    upper(class(obj)), sprintf('%s ',remainingInputStructFields{:}) ...
                    );
                obj.extra = obj.inputStruct;
            end

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)
            
        end
        

    end
    
    methods (Static)
        function writeInputFile(filePathName, ID, varargin)
            Inputs.Input.writeInputFile(filePathName, "a+", "ID", ID, varargin{:});
        end
    end

end

