%
%   Class fluidproperties
%
%   Usage: prop = fluidProperties(P,model)
%

classdef fluidProperties
    
    %% Properties
    
    properties (SetAccess=private)
        
        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Fluid ID
        PROPERTIES (1,1) string  {mustBeTextScalar,mustBeMember(PROPERTIES, ["SATURATED","PSYSTEM"])} ...
                                                                           = 'SATURATED'           % Fluid property assumptions
        PRESSURE   (1,1) double  {mustBeNumeric}                           = 1                     % [Pa] System pressure
        TSAT       (1,1) double  {mustBeNumeric}                           = 1                     % [K] Saturated fluid temperature
        RHOF       (1,1) double  {mustBeNumeric}                           = 1                     % [kg/m^3] Saturated liquid mass density
        RHOG       (1,1) double  {mustBeNumeric}                           = 1                     % [kg/m^3] Saturated vapor mass density
        MUF        (1,1) double  {mustBeNumeric}                           = 1                     % [Pa.s] Saturated liquid viscosity
        MUG        (1,1) double  {mustBeNumeric}                           = 1                     % [Pa.s] Saturated liquid viscosity
        HF         (1,1) double  {mustBeNumeric}                           = 1                     % [J/kg] Saturated liquid enthalpy
        HG         (1,1) double  {mustBeNumeric}                           = 1                     % [J/kg] Saturated vapor enthalpy
        
    end
        
    %% Methods
    
    methods
        
        % Constructor method
        function obj = fluidProperties(P,model)
            
            fprintf('\n> fluidproperties initialized for ''%s'' with ''%s'' assumption\n',model.FLUID,model.PROPERTIES);
            
            obj(1:length(P)) = obj;                                        % Initialize object array
            fluid = model.FLUID;                                           % Fluid ID
            
            for k = 1:length(P)
                
                obj(k).FLUID = fluid;                                      % Fluid ID
                obj(k).PROPERTIES = model.PROPERTIES;                      % Fluid property assumptions
                obj(k).PRESSURE = P(k);                                    % [Pa] System pressure
                
                obj(k).TSAT = py.CoolProp.CoolProp.PropsSI('T','P',P(k),'Q',1,fluid); % [K] Saturated fluid temperature
                obj(k).RHOF = py.CoolProp.CoolProp.PropsSI('D','P',P(k),'Q',0,fluid); % [kg/m^3] Saturated liquid mass density
                obj(k).RHOG = py.CoolProp.CoolProp.PropsSI('D','P',P(k),'Q',1,fluid); % [kg/m^3] Saturated vapor mass density
                obj(k).MUF  = py.CoolProp.CoolProp.PropsSI('V','P',P(k),'Q',0,fluid); % [Pa.s] Saturated liquid viscosity
                obj(k).MUG  = py.CoolProp.CoolProp.PropsSI('V','P',P(k),'Q',1,fluid); % [Pa.s] Saturated vapor viscosity
                obj(k).HF   = py.CoolProp.CoolProp.PropsSI('H','P',P(k),'Q',0,fluid); % [J/kg] Saturated liquid enthalpy
                obj(k).HG   = py.CoolProp.CoolProp.PropsSI('H','P',P(k),'Q',1,fluid); % [J/kg] Saturated vapor enthalpy
                
            end
            
        end
        
        % Latent heat of evaporation, usage: prop.HFG or HFG(prop)
        function hfg = HFG(obj)
            
            hfg = obj.HG-obj.HF;                                           % [J/kg] Latent heat of evaporation
            
        end
        
        % Fluid temperature, usage: prop(i).T(H) of T(prop(i),H)
        function t = T(obj,H)
            
            t = arrayfun(@(h) py.CoolProp.CoolProp.PropsSI('T','H',h,'P',obj.PRESSURE,obj.FLUID),H); % [K] Fluid temperature
            
        end
        
        % Fluid enthalpy, usage: prop.H(T) or H(prop,T)
        function h = H(obj,T)
            
            h = arrayfun(@(t) py.CoolProp.CoolProp.PropsSI('H','T',t,'P',obj.PRESSURE,obj.FLUID),T); % [J/kg] Fluid enthalpy
            
        end
        
        % Liquid mass density (subcooled to saturated), usage: prop(i).RHOL(H) or RHOL(prop(i),H)
        function rhol = RHOL(obj,H)
            
            switch obj.PROPERTIES
                case 'SATURATED'
                    rhol = repmat(obj.RHOF,numel(H),1);
                case 'PSYSTEM'
                    rhol = arrayfun(@(h) py.CoolProp.CoolProp.PropsSI('D','H',h,'P',obj.PRESSURE,obj.FLUID),min(H,obj.HF)); % [kg/m^3] Liquid mass density (subcooled to saturated)
            end
            
        end
        
        % Vapor mass density (saturated to superheated), usage: prop.RHOV(H) or RHOV(prop,H)
        function rhov = RHOV(obj,H)
            
            switch obj.PROPERTIES
                case 'SATURATED'
                    rhov = repmat(obj.RHOG,numel(H),1);
                case 'PSYSTEM'
                    rhov = arrayfun(@(h) py.CoolProp.CoolProp.PropsSI('D','H',h,'P',obj.PRESSURE,obj.FLUID),max(H,obj.HG)); % [kg/m^3] Vapor mass density (saturated to superheated)
            end
            
        end
        
        % Liquid dynamic viscosity (subcooled to saturated), usage: prop.MUL(H) or MUL(prop,H)
        function mul = MUL(obj,H)
            
            switch obj.PROPERTIES
                case 'SATURATED'
                    mul = repmat(obj.MUF,numel(H),1);
                case 'PSYSTEM'
                    mul = arrayfun(@(h) py.CoolProp.CoolProp.PropsSI('V','H',h,'P',obj.PRESSURE,obj.FLUID),min(H,obj.HF)); % [Pa.s] Liquid dynamic viscosity (subcooled to saturated)
            end
            
        end
        
        % Vapor dynamic viscosity (saturated to superheated), usage: prop.MUV(H) or MUV(prop,H)
        function muv = MUV(obj,H)
            
            switch obj.PROPERTIES
                case 'SATURATED'
                    muv = repmat(obj.MUG,numel(H),1);
                case 'PSYSTEM'
                    muv = arrayfun(@(h) py.CoolProp.CoolProp.PropsSI('V','H',h,'P',obj.PRESSURE,obj.FLUID),max(H,obj.HG)); % [Pa.s] Vapor dynamic viscosity (saturated to superheated)
            end
            
        end
        
        % Plot properties for given enthalpy array, usage: prop.plot(h) or plot(prop,H)
        function plot(obj,H)
            
            figure('name',strcat(obj.FLUID,[' property plots at ' num2str(obj.PRESSURE) ' [Pa]']))
            propplot(H,obj,'T','Fluid temperature [K]',{'TSAT'})
            propplot(H,obj,'RHOL','Liquid density [kg/m^3]',{'RHOF','RHOG'})
            propplot(H,obj,'RHOV','Vapor density [kg/m^3]',{'RHOF','RHOG'})
            propplot(H,obj,'MUL','Liquid dynamic viscosity [Pa.s]',{'MUF','MUG'})
            propplot(H,obj,'MUV','Vapor dynamic viscosity [Pa.s]',{'MUF','MUG'})
            
        end
        
        
    end
    
end

%%

function propplot(H,obj,param,label,sat)

nexttile; hold all; grid on;
plot(H,obj.(param)(H),'.-')
cellfun(@(x) plot(xlim,repmat(obj.(x),1,2),'k--'),sat);
xlabel('Enthalpy [J/kg]'); xlim([min(H) max(H)])
ylabel(label)
set(gca,'fontSize',14)

end
