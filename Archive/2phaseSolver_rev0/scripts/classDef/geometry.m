%
%   Class geometry
%
%   Usage: geom = geometry(geomf)
%

classdef geometry
    
    %% Properties
    
    properties (SetAccess=private)
        
        ID         (1,1) string  {mustBeTextScalar,mustBeNonempty}         = 'NA'                  % Channel ID
        LENGTH     (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Axial length [m]
        AREA       (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Coolant area [m^2] 
        PERIM      (1,:) double  {mustBePositive,mustBeNonempty}           = 1                     % Perimeters [m]
        ANGLE      (1,1) double  {mustBeNumeric}                           = 0                     % Angle [rad] 
    
    end
        
    %% Methods
    
    methods
        
        % Constructor method
        function obj = geometry(geomf,id)
            
            fprintf('\n> Channel geometry loaded from %s ID in %s\n',id,geomf);
            geom = readInputFile(geomf);                                   % Load geometry file
            geom = geom(contains({geom.ID},id));                           % Keep geometry entry corresponding to id
            
            param = fieldnames(geom)';                                     % Field names in geometry file
            ind_p =ismember(param,fieldnames(obj)');                       % param indexes included in object properties
            if any(~ind_p)
                fprintf([' The following unkwown geometry inputs were discarded:' repmat(' %s',1,sum(~ind_p)) '\n'],param{~ind_p})
            end
            ind = ind_p;                                                   % param indexes used for object creation
            
            for k = find(ind)
                obj.(param{k}) = geom.(param{k});                          % Assign each field to geometry object
            end
            
            
        end
        
        % Hydraulic diameter
        function dh = HDIAM(obj)
            
            dh = 4*obj.AREA/sum(obj.PERIM);                                % [m] Hydraulic diameter
            
        end
        
        % Number of walls
        function N = NWALL(obj)
            
            N = length(obj.PERIM);                                         % Number fo walls
            
        end
        
    end
    
end
