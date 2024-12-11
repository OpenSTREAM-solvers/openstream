classdef Model < Inputs.Input
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        ID               (1,1) string  {mustBeTextScalar}                                               % Model ID 
        NNODES                 double  {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} ...
                                                                           = []                    % Number of axial nodes 
        FLUID            (1,1) string  {mustBeTextScalar}                  = "WATER"               % Fluid ID
        PROPERTIES       (1,1) InputEnums.FLUIDPROPERTIES                  = 'SATURATED'           % Fluid property assumptions
        ANGLE            (1,1) double  {mustBeNumeric}                     = 0                     % Flow axis angle from vertical [deg]
        FRICTION         (1,3) double  {mustBeNumeric}                     = [0.2 -0.2 0]          % Wall friction coefficients
        TPFM             (1,1) InputEnums.TPFM                             = 'HOMOGENEOUS'         % Two-phase friction multiplier [-]
        KLOC             (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                 % Elevation of local perturbations [m] 
        KLOSS            (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                 % corresponding pressure loss coefficients [-]
        TPKM             (1,1) InputEnums.TPKM                             = 'HOMOGENEOUS'         % Two-phase local loss multiplier [-] 
        SCBOIL           (1,1) InputEnums.SCBOIL                           = 'NONE'                % Subcooled boiling mode
        VOID             (1,1) InputEnums.VOID                             = 'HOMOGENEOUS'         % Void fraction model 
        SLIP             (1,1) double  {mustBePositive}                    = 1                     % Phase velocity ratio [-]
        CBT              (1,1) InputEnums.CBT                              = 'NONE'                % Critical Boiling Transition model 
        RELAXX           (1,:) double                                      = [-0.5 0.0]            % Relaxation time eq quality [s]
        RELAXT           (1,:) double                                      = [0.15 0.10 0.10 0.01] % Relaxation time array [s]
        
        MOMENTLIQUID     (1,1) InputEnums.MOMENTLIQUID                     = 'SLIP'                % Liquid momentum conservation model [-]  
        MOMENTGAS        (1,1) InputEnums.MOMENTGAS                        = 'SLIP'                % Gas momentum conservation model [-]        
        BOILCOEF         (1,1) InputEnums.BOILCOEF                         = 'QUADRATIC'           % Subcooled boiling interpolation [-]        
        INTLENGTH        (1,1) InputEnums.INTLENGTH                        = 'CONSTANT'            % Interfacial length scale model model [-]
        INTAREA          (1,1) InputEnums.INTAREA                          = 'DISPGAS2DISPLIQ'     % Interfacial area model [-]
        INTLENGTHCST     (1,1) double                                      = 2E-3                  % Constant interfacial length scale [m]
        INTTRANSH        (1,1) InputEnums.INTTRANSH                        = 'BULK'                % Interfacial enthalpy transfer [-]
        INTNU            (1,1) InputEnums.INTNU                            = 'CONSTANT'            % Interfacial heat transfer model [-]
        INTNUVCST        (1,1) double                                      = 2.0                   % Dispersed gas constant interfacial Nusselt number [-]
        INTNULCST        (1,1) double                                      = 2.0                   % Dispersed liquid constant interfacial Nusselt number [-]        
        RANZMARSHALLVCST (1,4) double                                      = [2 0.6 1/2 1/3]       % Dispersed gas Ranz-Marshall coefficients [-]
        RANZMARSHALLLCST (1,4) double                                      = [2 0.6 1/2 1/3]       % Dispersed liquid Ranz-Marshall coefficients [-]
        LOCRELVEL        (1,1) InputEnums.LOCRELVEL                        = 'SCALED'              % Local relative velocity model [-]
        RELVELCST        (1,1) double                                      = 1E-1                  % Multiplication factor to determine the localrelative velocity [-]
        RELAXTCOND       (1,1) double                                      = 0.2                   % Condensation relaxation time [s]
        RELAXTEVAP       (1,1) double                                      = 0.2                   % Evaporation relaxation time [s]
        
        OAF              (1,1) InputEnums.OAF                              = 'WALLIS'              % Onset of annular flow model [-]
        OAFFILMSPLIT     (1,1) InputEnums.OAFFILMSPLIT                     = 'RATIO'               % Film mass flow rate at onset of annular flow [-]
        OAFBASERATIO     (1,1) double  {mustBeInRange(OAFBASERATIO,0,1)}   = 0.5                   % Base/Film mass ratio at onset of annular flow [-]
        OAFENTRAINED     (1,1) InputEnums.OAFENTRAINED                     = 'RATIO'               % Entrained model at onset of annular flow [-]
        OAFDROPRATIO     (1,1) double  {mustBeInRange(OAFDROPRATIO,0,1)}   = 0.7                   % Drop/Liquid mass ratio at onset of annular flow [-]
        OAFTRANSITION    (1,2) double  {mustBeNumeric}                     = [0.10 0.0]            % Annular flow transition function parameters (sigmoid width/location wrt OAF) [m]
        DEPOSITION       (1,1) InputEnums.DEPOSITION                       = 'GOVAN'               % Drop deposition model [-]
        ENTRAINMENT      (1,1) InputEnums.ENTRAINMENT                      = 'GOVAN'               % Film entrainment model [-]   
        MOMENTFILM       (1,1) InputEnums.MOMENTFILM                       = 'ALGEBRAIC'           % Film momentum conservation model [-]  
        MOMENTDROP       (1,1) InputEnums.MOMENTDROP                       = 'SLIP'                % Drop momentum conservation model [-]                                                                 
        DROPSLIP         (1,1) double  {mustBePositive}                    = 1.0                   % Drop velocity ratio [-]       
        THINFILMFRIC     (1,1) InputEnums.THINFILMFRIC                     = 'TURBULENT'           % Thin film wall friction model [-]  
        THINFILMTHICK    (1,1) double  {mustBePositive}                    = 1E-4                  % Thin film thickness [m]        
        VAPORFRIC        (1,1) InputEnums.VAPORFRIC                        = 'WALLIS'              % Vapor friction model [-]  
        VAPORFRICCST     (1,1) double  {mustBePositive}                    = 0.005                 % Vapor friction constant [-]
        POSFILM          (1,1) logical                                     = true                  % Keep positive film flowrate/thickness
        DROPDIAM         (1,1) double  {mustBePositive}                    = 1E-3                  % Drop diameter [mm]
        DROPDRAG         (1,1) InputEnums.DROPDRAG                         = 'CONSTANT'            % Drop drag model
        DROPDRAGCOEF     (1,1) double  {mustBePositive}                    = 0.45                  % Drop drag coefficient

        BASEEQTHICK      (1,1) InputEnums.BASEEQTHICK                      = 'DEFAULT'
        BASEEQTHICKCOEF  (:,1) double  {mustBeNumeric}                     = [5.37E-5 -0.64 1.21]  % Base equilibrium thickness coefficient
        RELAXTB          (:,1) double  {mustBeNonnegative}                 = 0.2                   % Base film relaxation time
        MOMENTBASE       (1,1) InputEnums.MOMENTBASE                       = 'ALGEBRAIC'           % Base Film momentum conservation model [-]  
        SHAPEFACTORCOEF  (:,1) double {mustBeNumeric}                      = [1.325E5 2]           % Wave shape factor coefficients
        EQSTROUHAL       (1,1) InputEnums.EQSTROUHAL                       = 'RISO'
        EQSTROUHALCOEF   (:,1) double {mustBeNumeric}                      = [1.1236E-4 0.5]       % Wave equilibrium Strouhal coefficients
        WAVEDRAGCOEF     (:,1) double  {mustBeNumeric}                     = [0.02 1.350E5 0.437]  % Wave drag coefficient
        WAVEFREQUENCY    (1,1) InputEnums.WAVEFREQUENCY                    = 'RELAXATION'          % Wave number conservation model   
        RELAXTW          (:,1) double  {mustBeNonnegative}                 = 0.2                   % Wave relaxation time
        MOMENTWAVE       (1,1) InputEnums.MOMENTWAVE                       = 'FULL'                % Film momentum conservation model [-]  
        WAVEMIXCOEF      (:,1) double  {mustBeNonnegative}                 = 0.0                   % Wave mixing coefficient
        
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

            % Iterate through obj property names
            for idx = 1:length(objPropnames)
                
                % Retrieve idx-th item in objPropnames
                objPropname = objPropnames(idx);
                
                % Check if the objPropname entry is specified, and if the
                % default value should be used
                [isSpecified, useDefault] = obj.validateInputEntry(objPropname,id=modelID);
                if ~useDefault
                    obj.(objPropname) = ...
                                    upper(obj.inputStruct.(objPropname));
                elseif useDefault
                    defaultValueFieldNames(end+1) = objPropname;
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

