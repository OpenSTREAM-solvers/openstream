%
%   Class liquid
%
%   Usage: liq = liquid(mix)
%

classdef liquid
    
    %% Properties
    
    properties (SetAccess=private)
        
        TIME         (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        
    end
    
    %% Methods
    
    methods
        
        % Constructor method
        function obj = liquid(mix)
            
            fprintf('\n> Liquid phase initialized\n');
            
            obj(1:length(mix)) = obj;                                      % Initialize object array
            
            for k = 1:length(mix)
                obj(k).TIME = mix(k).TIME;                                 % [s] Time
                obj(k).Z    = mix(k).Z;                                    % [m] Elevation
            end
            
        end
        
        % Mass fraction, usage: liq(i).X(mix(i),prop(i),model) or X(liq(i),mix(i),prop(i),model)
        function x = X(~,mix,prop,model)
            
            x = 1-mix.X(prop,model);                                       % [-] Mass fraction
            
        end
        
        % Volume fraction, usage: liq(i).VF(mix(i),prop(i),model,geom) or VF(liq(i),mix(i),prop(i),model,geom)
        function vf = VF(~,mix,prop,model,geom)
            
            vf = 1-mix.VF(prop,model,geom);                                % [-] Volume fraction
            
        end
        
        % Mass flow rate, usage: liq(i).W(mix(i),prop(i),model) or W(liq(i),mix(i),prop(i),model)
        function w = W(obj,mix,prop,model)
            
            w = obj.X(mix,prop,model).*mix.W;                              % [kg/s] Mass flow rate
            
        end
        
        % Velocity, usage: liq(i).U(mix(i),prop(i),model,geom)
        function u = U(obj,mix,prop,model,geom)
            
            u = obj.MFLUX(mix,prop,model,geom)./obj.VF(mix,prop,model,geom)./prop.RHOL(mix.H); % [m/s] Velocity
            
        end
        
        % Enthalpy, usage: liq(i).H(mix(i),prop(i)) or H(liq(i),mix(i),prop(i))
        function h = H(~,mix,prop)
            
            h = max(mix.H,prop.HF);                                        % [J/kg] Enthalpy
            
        end
        
        % Mass flux, usage: liq(i).MFLUX(mix(i),prop(i),model,geom)
        function mflux = MFLUX(obj,mix,prop,model,geom)
            
            mflux = obj.W(mix,prop,model)/geom.AREA;                       % [kg/m^2/s] Mass flux
            
        end
        
        % Reynolds number, usage: liq(i).RE(mix(i),prop(i),model,geom) or RE(liq(i),mix(i),prop(i),model,geom)
        function re = RE(obj,mix,prop,model,geom)
            
            re = 4.*obj.W(mix,prop,model)./prop.MUL(mix.H)./sum(geom.PERIM); % [-] Reynolds number
            
        end
        
        % Time array of selected parameter at selected node, usage: liq.TARRAY(param,node) or TARRAY(liq,param,node)
        function tarray = TARRAY(obj,param,node)
            
            tarray = arrayfun(@(x) x.(param)(node),obj);
            
        end
        
    end
    
end
