classdef Model < Inputs.Input
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        
        ID          (1,1) string  {mustBeTextScalar,mustBeNonempty}                                % Model ID 
        NNODES           double  {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} ...
                                                                           = []                    % Number of axial nodes 
        FLUID       (1,1) string  {mustBeTextScalar}                       = "WATER"               % Fluid ID
        PROPERTIES  (1,1) InputEnums.FLUIDPROPERTIES                       = 'SATURATED'           % Fluid property assumptions
        ANGLE       (1,1) double  {mustBeNumeric}                          = 0                     % Flow axis angle from vertical [deg]
        FRICTION    (1,3) double  {mustBeNumeric}                          = [0.2 -0.2 0]          % Wall friction coefficients
        TPFM        (1,1) InputEnums.TPFM                                  = 'HOMOGENEOUS'         % Two-phase friction multiplier [-]
        KLOC        (1,:) double  {mustBeNumeric,mustBeNonempty}           = [0 0]                 % Elevation of local perturbations [m] 
        KLOSS       (1,:) double  {mustBeNumeric,mustBeNonempty}           = [0 0]                 % corresponding pressure loss coefficients [-]
        TPKM        (1,1) InputEnums.TPKM                                  = 'HOMOGENEOUS'         % Two-phase local loss multiplier [-] 
        SCBOIL      (1,1) InputEnums.SCBOIL                                = 'NONE'                % Subcooled boiling mode
        VOID        (1,1) InputEnums.VOID                                  = 'HOMOGENEOUS'         % Void fraction model 
        SLIP        (1,1) double  {mustBePositive}                         = 1                     % Phase velocity ratio [-]
        
        OAF           (1,1) InputEnums.OAF                                 = 'WALLIS'              % Onset of annular flow model [-]
        OAFDROPRATIO  (1,1) double  {mustBeInRange(OAFDROPRATIO,0,1)}      = 0.7                   % Drop/Liquid mass ratio at onset of annular flow [-]
        OAFTRANSITION (1,2) double  {mustBeNumeric}                        = [0.04 0.0]            % Annular flow transition function parameters (sigmoid width/location wrt OAF) [m]
        DEPOSITION    (1,1) InputEnums.DEPOSITION                          = 'GOVAN'               % Drop deposition model [-]
        ENTRAINMENT   (1,1) InputEnums.ENTRAINMENT                         = 'GOVAN'               % Film entrainment model [-]   
        MOMENTFILM    (1,1) InputEnums.MOMENTFILM                          = 'ALGEBRAIC'           % Film momentum conservation model [-]  
        MOMENTDROP    (1,1) InputEnums.MOMENTDROP                          = 'SLIP'                % Drop momentum conservation model [-]                                                                 
        DROPSLIP      (1,1) double  {mustBePositive}                       = 1.0                   % Drop velocity ratio [-]       
        THINFILMFRIC  (1,1) InputEnums.THINFILMFRIC                        = 'LAMINAR'             % Thin film wall friction model [-]  
        THINFILMTHICK (1,1) double  {mustBePositive}                       = 1E-4                  % Thin film thickness [m]        
        VAPORFRIC     (1,1) InputEnums.VAPORFRIC                           = 'WALLIS'              % Vapor friction model [-]  
        VAPORFRICCST  (1,1) double  {mustBePositive}                       = 0.005                 % Vapor friction constant [-]
        POSFILM       (1,1) logical                                        = true                  % Keep positive film flowrate/thickness
    end

    properties (SetAccess = private)
        G          (1,1) double  {mustBeNumeric}                           = 9.81                  % [m/s^2] Gravitational acceleration
    end

    methods
        function obj = Model(filePath,modelID)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here

            % Call superclass constructor to parse file and select
            % specified modelID using "ID" key
            obj = obj@Inputs.Input(filePath, 'ID', modelID)
            
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
            end

            % Remove dynamic property inputStruct
            inputStructProp = obj.findprop('inputStruct');
            delete(inputStructProp)
            
        end
        

    end

end

