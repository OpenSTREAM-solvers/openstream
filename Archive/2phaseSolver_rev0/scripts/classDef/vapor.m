%
%   Class vapor
%
%   Usage: vap = vapor(mix)
%

classdef vapor
    
    %% Properties
    
    properties (SetAccess=private)
        
        TIME         (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        
    end
    
    %% Methods
    
    methods
        
        % Constructor method
        function obj = vapor(mix)
            
            fprintf('\n> Vapor phase initialized\n');
            
            obj(1:length(mix)) = obj;                                      % Initialize object array
            
            for k = 1:length(mix)
                obj(k).TIME = mix(k).TIME;                                 % [s] Time
                obj(k).Z    = mix(k).Z;                                    % [m] Elevation
            end
            
        end
        
        % Mass fraction, usage: vap(i).X(mix(i),prop(i),model) or X(vap(i),mix(i),prop(i),model)
        function x = X(~,mix,prop,model)
            
            x = mix.X(prop,model);                                         % [-] Mass fraction
            
        end
        
        % Volume fraction, usage: vap(i).VF(mix(i),prop(i),model,geom) or VF(vap(i),mix(i),prop(i),model,geom)
        function vf = VF(~,mix,prop,model,geom)
            
            vf = mix.VF(prop,model,geom);                                  % [-] Volume fraction
            
        end
        
        % Mass flow rate, usage: vap(i).W(mix(i),prop(i),model) or W(vap(i),mix(i),prop(i),model)
        function w = W(obj,mix,prop,model)
            
            w = obj.X(mix,prop,model).*mix.W;                              % [kg/s] Mass flow rate
            
        end
        
        % Velocity, usage: vap(i).U(mix(i),prop(i),model,geom)
        function u = U(obj,mix,prop,model,geom)
            
            u = obj.MFLUX(mix,prop,model,geom)./obj.VF(mix,prop,model,geom)./prop.RHOV(mix.H); % [m/s] Velocity
            
        end
        
        % Enthalpy, usage: vap(i).H(mix(i),prop(i)) or H(vap(i),mix(i),prop(i))
        function h = H(~,mix,prop)
            
            h = min(mix.H,prop.HG);                                        % [J/kg] Enthalpy
            
        end
        
        % Mass flux, usage: vap(i).MFLUX(mix(i),prop(i),model,geom)
        function mflux = MFLUX(obj,mix,prop,model,geom)
            
            mflux = obj.W(mix,prop,model)/geom.AREA;                       % [kg/m^2/s] Mass flux
            
        end
        
        % Reynolds number, usage: vap(i).RE(mix(i),prop(i),model,geom) or RE(vap(i),mix(i),prop(i),model,geom)
        function re = RE(obj,mix,prop,model,geom)
            
            re = 4.*obj.W(mix,prop,model)./prop.MUG(mix.H)./sum(geom.PERIM); % [-] Reynolds number
            
        end
        
        % Time array of selected parameter at selected node, usage: vap.TARRAY(param,node) or TARRAY(vap,param,node)
        function tarray = TARRAY(obj,param,node)
            
            tarray = arrayfun(@(x) x.(param)(node),obj);
            
        end
        
    end
    
end
