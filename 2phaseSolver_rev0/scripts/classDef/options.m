%
%   Class options
%
%   Usage: option = options(optionf,id)
%

classdef options
    
    %% Properties
    
    properties (SetAccess=private)
        
        ID           (1,1) string  {mustBeTextScalar,mustBeNonempty}       = 'NA'                  % Option ID 
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
        RELAXHM      (1,1) double  {mustBeInRange(RELAXHM,0,1)}            = 1                     % Relaxation factor for the mixture energy conservation equation
    
    end
        
    %% Methods
    
    methods
        
        % Constructor method
        function obj = options(optionf,id)
            
            fprintf('\n> Numerical options loaded from %s ID in %s\n',id,optionf);
            option = readInputFile(optionf);                               % Load option file
            option = option(contains({option.ID},id));                     % Keep option entry corresponding to id
            
            param = fieldnames(option);                                    % Field names in option file
            ind_p =ismember(param,fieldnames(obj))';                       % param indexes included in object properties
            ind_e = ~structfun(@isempty,option)';                          % param indexes not empty
            if any(~ind_p)
                fprintf([' The following unkwown option inputs were discarded:' repmat(' %s',1,sum(~ind_p)) '\n'],param{~ind_p})
            end
            if any(~ind_e)
                fprintf([' The following empty option inputs were replaced by default values:' repmat(' %s',1,sum(~ind_e)) '\n'],param{~ind_e})
            end
            ind = all([ind_p;ind_e]);                                      % param indexes used for object creation

            for k = find(ind)
                obj.(param{k}) = option.(param{k});                        % Assign corresponding param to object
            end
            
        end
        
    end
    
end
