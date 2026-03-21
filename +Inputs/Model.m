classdef Model < Inputs.Input
    %MODEL Class for defining and managing physical model configuration
    %
    % This class encapsulates all physical modeling parameters used in the simulations,
    % including fluid properties, regime transitions, wall and interfacial
    % exchange models for all solvers. It reads model data from input files
    % and handles default values as well as input validation.

    properties (SetAccess=?Inputs.Input)

        ID               (1,1) string  {mustBeTextScalar}                                                    % Identifier for the model configuration
        NNODES                 double  {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} ...
                                                                           = 100                             % Number of axial nodes used in the simulation
        FLUID            (1,1) string  {mustBeTextScalar}                  = 'WATER'                         % CoolProp fluid identifier
        PROPERTIES       (1,1) InputEnums.FLUIDPROPERTIES                  = 'SATURATED'                     % Assumption model for fluid properties selected from :class:`InputEnums.FLUIDPROPERTIES`
        ANGLE            (1,1) double  {mustBeNumeric}                     = 0                               % Flow axis angle from vertical [deg]
        KLOC             (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                           % Elevation of local perturbations [m]

        % Two-phase flow regime and wall heat transfer transitions

        WBOILINGXSUB     (1,1) double  {mustBeNonpositive}                 = -0.2                            % Equilibrium thermodynamic quality at onset of subcooled wall boiling [-]
        WBOILINGN        (1,1) double  {mustBePositive}                    = 2                               % Wall boiling function exponent [-]
        WBOILINGXSAT     (1,1) double  {mustBeNumeric}                     =  0                              % Equilibrium thermodynamic quality at onset of saturated wall boiling [-]
        OAF              (1,1) InputEnums.OAF                              = 'WALLIS'                        % Onset of annular flow model selected from :class:`InputEnums.OAF`
        OAFTRANSITION    (1,2) double  {mustBeNumeric}                     = [0.10 0.0]                      % Annular flow transition function parameters (sigmoid width/location wrt OAF) [m]
        CBT              (1,1) InputEnums.CBT                              = 'NONE'                          % Critical Boiling Transition model selected from :class:`InputEnums.CBT`
        CBTMULT          (1,1) function_handle                             = @(z) 1                          % Critical boiling Heat flux multiplier function
        CBTKEFFECT       (1,2) double  {mustBeNumeric}                     = [0 0]                           % Grid effect coefficients (:math:`1 + C(1) \exp(C(2) z)`) [-]
        CBTELEVATION     (1,1) double  {mustBePositive}                    = 1                               % Critical Boiling Transition Elevation [m]
        MFBT             (1,1) InputEnums.MFBT                             = 'NONE'                          % Minimum Film Boiling Transition model selected from :class:`InputEnums.MFBT`
        DTMFB            (1,1) double  {mustBePositive}                    = 100;                            % Minimum film boiling temperature from saturation [K]

        % Wall (and local perturbations) momentum transfer

        SPMTM            (1,1) InputEnums.SPMTM                            = 'BLASIUS'                       % Single-phase wall momentum transfer model selected from :class:`InputEnums.SPMTM`
        FRICTION         (1,3) double  {mustBeNumeric}                     = [0.2 -0.2 0]                    % Wall friction coefficients [-]
        TPFM             (1,1) InputEnums.TPFM                             = 'HOMOGENEOUS'                   % Two-phase friction multiplier model selected from :class:`InputEnums.TPFM`
        KLOSS            (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                           % Pressure loss coefficients of local perturbations [-]
        TPKM             (1,1) InputEnums.TPKM                             = 'HOMOGENEOUS'                   % Two-phase local loss multiplier model selected from :class:`InputEnums.TPKM`
        BTMTM            (1,1) InputEnums.BTMTM                            = 'TPFM'                          % Boiling transition wall momentum transfer model selected from :class:`InputEnums.BTMTM`

        % Wall heat transfer

        SPHTM            (1,1) InputEnums.SPHTM                            = 'DITTUSBOELTER'                 % Single-phase wall heat transfer model selected from :class:`InputEnums.SPHTM`
        DITTUSBOELTERCOEF (1,3) double  {mustBeNumeric}                    = [0.023 0.8 0.4]                 % Dittus-Boelter coefficients [-]
        TPHTM            (1,1) InputEnums.TPHTM                            = 'THOM'                          % Two-phase wall heat transfer model selected from :class:`InputEnums.TPHTM`
        BTHTM            (1,1) InputEnums.BTHTM                            = 'VAPOR'                         % Boiling transition wall heat transfer model selected from :class:`InputEnums.BTHTM`
        MOECKCOEF        (1,4) double  {mustBeNumeric}                     = [1.09E-3 0.989 1.41 -1.15]      % Groeneveld-Moeck post-boiling transition model coefficients [-]

        % Mixture solver models

        VOID             (1,1) InputEnums.VOID                             = 'HOMOGENEOUS'                   % Void fraction model selected from :class:`InputEnums.VOID`
        SLIP             (1,1) double  {mustBePositive}                    = 1                               % Phase velocity ratio [-]
        THERMALNONEQ     (1,1) InputEnums.THERMALNONEQ                     = 'EQUILIBRIUM'                   % Thermal non-equilibrium model selected from :class:`InputEnums.THERMALNONEQ`

        % Mixture MRM solver models

        THERMALRELAX     (1,1) InputEnums.THERMALRELAX                     = 'TIMEX'                         % Thermal non-equilibrium time relaxation model selected from :class:`InputEnums.THERMALRELAX`
        RELAXX           (1,:) double                                      = [-0.5 -0.25 -0.1 0.0 1.0]       % Interfacial phase change relaxation time thermodynamic quality [-]
        RELAXCONDFO      (1,:) double                                      = [ 1.0  1.0   1.0 1.0 1.0].*1E-4 % Interfacial condensation Fourier number array [s]
        RELAXEVAPFO      (1,:) double                                      = [ 1.0  1.0   1.0 1.0 1.0].*5E-5 % Interfacial evaporation  Fourier number array [s]
        RELAXCONDT       (1,:) double                                      = [ 1.0  0.5   0.3 0.1 0.1]       % Interfacial condensation relaxation time array [s]
        RELAXEVAPT       (1,:) double                                      = [ 0.3  0.3   0.3 0.3 0.3]       % Interfacial evaporation  relaxation time array [s]
        RELAXCONDCOEF    (1,4) double  {mustBeNumeric}                     = [0.1E-3 1/3 0.05 0.0]           % Interfacial condensation time relaxation coefficients for homogeneous/non-homogeneous models
        RELAXEVAPCOEF    (1,4) double  {mustBeNumeric}                     = [0.1E-3 1/3 1E-5 0.0]           % Interfacial evaporation  time relaxation coefficients for homogeneous/non-homogeneous models
        RELAXEVAPFOCOEF  (1,3) double  {mustBeNumeric}                     = [5.75E5 3 0.8]                  % Interfacial evaporation  time relaxation coefficients for empirical Fourier number model
        KTRELAX          (1,:) double  {mustBeNumeric,mustBeNonempty}      = NaN                             % Thermal relaxation time at local perturbations [s]

        % Mixture near-wall models

        NEARWALLRATIO    (1,1) double  {mustBeInRange(NEARWALLRATIO,0,1)}  = 0.5                             % Near-wall mass flow distribution ratio [-]
        NEARWALLEQOAF    (1,1) logical                                     = false                           % Near-wall equilibrium at onset of annular two-phase flow
        NEARWALLH        (1,1) InputEnums.NEARWALLH                        = 'RATIO'                         % Near-wall equilibrium enthalpy model selected from :class:`InputEnums.NEARWALLH`
        NEARWALLHRATIO   (1,1) double  {mustBePositive}                    = 1.0                             % Near-wall equilibrium enthalpy ratio [-]
        NEARWALLRELAX    (1,1) InputEnums.NEARWALLRELAX                    = 'QUALITY'                       % Near-wall energy transfer time relaxation model selected from :class:`InputEnums.NEARWALLRELAX`
        NEARWALLRELAXX   (1,:) double                                      = [-0.5 -0.25 -0.1 0.0 1.0]       % Near-wall exchange relaxation time thermodynamic quality [-]
        NEARWALLRELAXT   (1,:) double                                      = [ 1.0  0.5   0.3 0.1 0.1]       % Near-wall energy transfer relaxation time array [s]
        NEARWALLRELAXCOEF (1,3) double  {mustBeNumeric}                    = [0.1E-3 1/3 0.05]               % Near-wall energy transfer time relaxation coefficients for void option

        % Two-fluid solver models

        INTLENGTH        (1,1) InputEnums.INTLENGTH                        = 'CONSTANT'                      % Interfacial length scale model model selected from :class:`InputEnums.INTLENGTH`
        INTAREA          (1,1) InputEnums.INTAREA                          = 'DISPGAS2DISPLIQ'               % Interfacial area model selected from :class:`InputEnums.INTAREA`
        INTLENGTHVCST    (1,1) double                                      = 2E-3                            % Dispersed gas    constant interfacial length scale [m]
        INTLENGTHLCST    (1,1) double                                      = 2E-3                            % Dispersed liquid constant interfacial length scale [m]
        LOCRELVEL        (1,1) InputEnums.LOCRELVEL                        = 'AREAMEAN'                      % Local relative phase velocity model selected from :class:`InputEnums.LOCRELVEL`
        RELVELCST        (1,1) double                                      = 1.0                             % Multiplication factor to the local relative velocity [-]

        MOMENTLIQUID     (1,1) InputEnums.MOMENTLIQUID                     = 'MIXTURE'                       % Liquid momentum conservation model selected from :class:`InputEnums.MOMENTLIQUID`
        MOMENTGAS        (1,1) InputEnums.MOMENTGAS                        = 'MIXTURE'                       % Gas momentum conservation model selected from :class:`InputEnums.MOMENTGAS`
        DROPDRAG         (1,1) InputEnums.DROPDRAG                         = 'VISCOUS'                       % Drop drag model selected from :class:`InputEnums.DROPDRAG`
        DROPDRAGCOEF     (1,1) double  {mustBePositive}                    = 0.45                            % Drop constant drag coefficient [-]
        BUBBLEDRAG       (1,1) InputEnums.BUBBLEDRAG                       = 'STOKES'                        % Bubble drag model selected from :class:`InputEnums.BUBBLEDRAG`
        BUBBLEDRAGCOEF   (1,1) double  {mustBePositive}                    = 0.45                            % Bubble constant drag coefficient [-]

        INTNU            (1,1) InputEnums.INTNU                            = 'RELAXATION'                    % Interfacial heat transfer model selected from :class:`InputEnums.INTNU`
        INTNUVCST        (1,1) double                                      = 2.0                             % Dispersed gas    constant interfacial Nusselt number [-]
        INTNULCST        (1,1) double                                      = 2.0                             % Dispersed liquid constant interfacial Nusselt number [-]
        RANZMARSHALLVCST (1,4) double                                      = [2 0.6 1/2 1/3]                 % Dispersed gas    Ranz-Marshall coefficients [-]
        RANZMARSHALLLCST (1,4) double                                      = [2 0.6 1/2 1/3]                 % Dispersed liquid Ranz-Marshall coefficients [-]
        INTTRANSH        (1,1) InputEnums.INTTRANSH                        = 'BULK'                          % Interfacial enthalpy transfer model selected from :class:`InputEnums.INTTRANSH`

        % Three-field solver models

        POSFILM          (1,1) logical                                     = true                            % Positive film flow rate/thickness model

        OAFENTRAINED     (1,1) InputEnums.OAFENTRAINED                     = 'EQUILIBRIUM'                   % Entrained drop model at onset of annular flow selected from :class:`InputEnums.OAFENTRAINED`
        OAFDROPRATIO     (1,1) double  {mustBeInRange(OAFDROPRATIO,0,1)}   = 0.7                             % Drop/Liquid mass ratio at onset of annular flow [-]

        DEPOSITION       (1,1) InputEnums.DEPOSITION                       = 'OKAWA'                         % Drop deposition model selected from :class:`InputEnums.DEPOSITION`
        DEPENHANCEMENT   (1,1) InputEnums.DEPENHANCEMENT                   = 'NONE'                          % Drop deposition enhancement model due to local perturbations selected from :class:`InputEnums.DEPENHANCEMENT`
        KBLOCKRATIO      (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                           % Blockage ratios of local perturbations [-]
        KTUNING          (1,:) double  {mustBeNumeric,mustBeNonempty}      = [0 0]                           % Drop deposition enhancement tuning coefficients [-]
        ENTRAINMENT      (1,1) InputEnums.ENTRAINMENT                      = 'OKAWA2003'                     % Film entrainment model selected from :class:`InputEnums.ENTRAINMENT`
        OKAWACOEFS       (1,:) double  {mustBeNumeric}                     = [320 0.111 4.79E-4 1]           % Coefficients of Okawa entrainment model [-]

        MOMENTFILM       (1,1) InputEnums.MOMENTFILM                       = 'ALGEBRAIC'                     % Film momentum conservation model selected from :class:`InputEnums.MOMENTFILM`
        VAPORFRIC        (1,1) InputEnums.VAPORFRIC                        = 'SOLVER_DEPENDENT'              % Vapor friction model selected from :class:`InputEnums.VAPORFRIC`
        VAPORFRICCST     (1,1) double  {mustBePositive}                    = 0.005                           % Vapor friction constant [-]
        THINFILMFRIC     (1,1) InputEnums.THINFILMFRIC                     = 'TURBULENT'                     % Thin film wall friction model selected from :class:`InputEnums.THINFILMFRIC`
        THINFILMTHICK    (1,1) double  {mustBePositive}                    = 1E-4                            % Minimum thin film thickness [m]

        MOMENTDROP       (1,1) InputEnums.MOMENTDROP                       = 'SLIP'                          % Drop momentum conservation model selected from :class:`InputEnums.MOMENTDROP`
        DROPSLIP         (1,1) double  {mustBePositive}                    = 1.0                             % Drop/vapor velocity ratio [-]
        DROPDIAM         (1,1) double  {mustBePositive}                    = 1E-3                            % Drop diameter [mm]

        % Four-field solver models

        OAFFILMSPLIT     (1,1) InputEnums.OAFFILMSPLIT                     = 'EQUILIBRIUM'                   % Film mass flow split model at onset of annular flow selected from :class:`InputEnums.OAFFILMSPLIT`
        OAFBASERATIO     (1,1) double  {mustBeInRange(OAFBASERATIO,0,1)}   = 0.5                             % Base/Film mass ratio at onset of annular flow [-]

        BASEEQTHICK      (1,1) InputEnums.BASEEQTHICK                      = 'RISO'                          % Equilibrium base film thickness model selected from :class:`InputEnums.BASEEQTHICK`
        BASEEQTHICKCOEF  (:,1) double  {mustBeNumeric}                     = [5.37E-5 -0.64 1.21]            % Equilibrium base film thickness coefficients [-]
        BASEYPLUS        (1,1) double  {mustBePositive}                    = 15                              % Equilibrium base film y+ value [-]
        RELAXTB          (:,1) double  {mustBeNonnegative}                 = 0.2                             % Base film / wave mass exchange relaxation time [s]

        WAVEMIXCOEF      (:,1) double  {mustBeNonnegative}                 = 2                               % Base film / wave turbulent mixing coefficient
        WAVEFREQUENCY    (1,1) InputEnums.WAVEFREQUENCY                    = 'RELAXATION'                    % Wave number density model selected from :class:`InputEnums.WAVEFREQUENCY`
        EQSTROUHAL       (1,1) InputEnums.EQSTROUHAL                       = 'RISO'                          % Equilibrium wave Strouhal number model selected from :class:`InputEnums.EQSTROUHAL`
        EQSTROUHALCOEF   (:,1) double  {mustBeNumeric}                     = [1.1236E-4 0.5 0.0]             % Equilibrium wave Strouhal number coefficients [-]
        RELAXTW          (:,1) double  {mustBeNonnegative}                 = 0.2                             % Wave number density relaxation time [s]
        CSTWAVEFREQ      (:,1) double  {mustBePositive}                    = 100                             % Imposed constant wave frequency [Hz]

        MOMENTBASE       (1,1) InputEnums.MOMENTBASE                       = 'FULLNOP'                       % Base film momentum conservation model selected from :class:`InputEnums.MOMENTBASE`
        MOMENTWAVE       (1,1) InputEnums.MOMENTWAVE                       = 'FULL'                          % Wave momentum conservation model selected from :class:`InputEnums.MOMENTWAVE`
        WAVEBASEINT      (1,1) InputEnums.WAVEBASEINT                      = 'VAPORSHEAR'                    % Wave / base film interfacial momentum transfer model selected from :class:`InputEnums.WAVEBASEINT`
        SHAPEFACTORCOEF  (:,1) double  {mustBeNumeric}                     = [1.325E5 2 1 0]                 % Wave shape factor coefficients [-]
        WAVEDRAGCOEF     (:,1) double  {mustBeNumeric}                     = [0.02 1.350E5 0.437]            % Wave drag coefficient [-]
        THINWAVETHICK    (1,1) double  {mustBePositive}                    = 1E-5                            % Minimum thin wave thickness [m]

    end

    properties (Constant)

        G             (1,1) double  {mustBeNumeric}                        = 9.81                            % Gravitational acceleration [m/s^2]
        SOLVERDEPENDENTPROPS                                               = struct("VAPORFRIC", ...
            struct('THREEFIELD', InputEnums.VAPORFRIC.WALLIS, ...
            'FOURFIELD', InputEnums.VAPORFRIC.CONSTANT, ...
            'DEFAULT',   InputEnums.VAPORFRIC.WALLIS, ...
            'DEP_FLAG',  InputEnums.VAPORFRIC.SOLVER_DEPENDENT) ...
            );                                                                                               % Mapping of solver-dependent properties and their values
    
    end

    methods

        function obj = Model(filePath,modelID)
            %MODEL Constructor for Model class
            %
            % Parses model input file and initializes properties.
            % Applies default values and validates entries.
            %
            % Inputs:
            %
            % - filePath — Path to model input file
            % - modelID  — Identifier for model configuration

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

                    % Take care of special cases
                    % Function handles provided in string format cannot be
                    % automatically cast to a function_handle. Here, a
                    % validation is first performed to detect restricted
                    % keywords, then converted.
                    if isa(obj.(objPropname), "function_handle") && isstring(obj.inputStruct.(objPropname))

                        % Check for insecure keywords in function handle
                        obj.validateFunctionHandleInput(obj.inputStruct.(objPropname))    ;
                        obj.(objPropname) = ...
                            str2func(obj.inputStruct.(objPropname));
                    else
                        obj.(objPropname) = ...
                            upper(obj.inputStruct.(objPropname));
                    end
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
            %WRITEINPUTFILE Writes model configuration data to input file
            %
            % Inputs:
            % - filePathName — Path to output file
            % - ID           — Model identifier
            % - varargin     — Additional name-value pairs for model properties

            Inputs.Input.writeInputFile(filePathName, "a+", "ID", ID, varargin{:});
        end

    end

end
