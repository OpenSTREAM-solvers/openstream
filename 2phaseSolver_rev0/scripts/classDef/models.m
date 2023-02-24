%
%   Class models
%
%   Usage: model = models(modelf,id)
%

classdef models
    
    %% Properties
    
    properties (SetAccess=private)
        
        ID         (1,1) string  {mustBeTextScalar,mustBeNonempty}         = 'NA'                  % Model ID 
        NNODES     (1,1) double  {mustBeInteger,mustBePositive}            = 100                   % Number of axial nodes 
        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Fluid ID
        PROPERTIES (1,1) string  {mustBeTextScalar,mustBeMember(PROPERTIES, ["SATURATED","PSYSTEM"])} ...
                                                                           = 'SATURATED'           % Fluid property assumptions
        G          (1,1) double  {mustBeNumeric}                           = 9.81                  % [m/s^2] Gravitational acceleration
        FRICTION   (1,3) double  {mustBeNumeric}                           = [0.2 -0.2 0]          % Wall friction coefficients
        TPFM       (1,1) string  {mustBeTextScalar}                        = 'HOMOGENEOUS'         % Two-phase friction multiplier [-]
        KLOC       (1,:) double  {mustBeNumeric}                           = 0                     % Elevation of local perturbations [m] 
        KLOSS      (1,:) double  {mustBeNumeric}                           = 0                     % corresponding pressure loss coefficients [-]
        TPKM       (1,1) string  {mustBeTextScalar}                        = 'HOMOGENEOUS'         % Two-phase local loss multiplier [-] 
        SCBOIL     (1,1) string  {mustBeMember(SCBOIL, ["NONE"])} ...
                                                                           = 'NONE'                % Subcooled boiling mode
        VOID       (1,1) string  {mustBeMember(VOID, ["HOMOGENEOUS","SLIP","BESTION"])} ...
                                                                           = 'HOMOGENEOUS'         % Void fraction model 
        SLIP       (1,1) double  {mustBePositive}                          = 1                     % Phase velocity ratio [-]
    
    end
        
    %% Methods
    
    methods
        
        % Constructor method
        function obj = models(modelf,id)
            
            fprintf('\n> Physical models loaded from %s ID in %s\n',id,modelf);
            model = readInputFile(modelf);                                 % Load model file
            model = model(contains({model.ID},id));                        % Keep model entry corresponding to id
            
            param = fieldnames(model);                                     % Field names in model file
            ind_p = ismember(param,fieldnames(obj))';                      % param indexes included in object properties
            ind_e = ~structfun(@isempty,model)';                           % param indexes not empty
            if any(~ind_p)
                fprintf([' The following unkwown model inputs were discarded:' repmat(' %s',1,sum(~ind_p)) '\n'],param{~ind_p})
            end
            if any(~ind_e)
                fprintf([' The following empty model inputs were replaced by default values:' repmat(' %s',1,sum(~ind_e)) '\n'],param{~ind_e})
            end
            ind = all([ind_p;ind_e]);                                      % param indexes used for object creation
            
            for k = find(ind)
                obj.(param{k}) = upper(model.(param{k}));                  % Assign corresponding param to object
            end
                        
        end
        
    end
    
end
