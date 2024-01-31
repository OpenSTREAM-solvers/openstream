%
%   Class boundaryConditions
%
%   Usage: bc = boundaryConditions(bcf)
%

classdef boundaryConditions
    
    %% Properties
    
    properties (SetAccess=private)
        
        TIME       (1,1) double  {mustBeNumeric}                           = 0                     % Time [s]
        PRESSURE   (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % System pressure [Pa]
        HIN        (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Inlet enthalpy [J/kg]
        MFLOW      (1,1) double  {mustBePositive,mustBeNonempty}           = 1                     % Mass flow rate [kg/s]
        POWER      (1,1) double  {mustBeNonnegative,mustBeNonempty}        = 1                     % Total power [W]
        WMESH      (1,:) double  {mustBePositive,mustBeNonempty}           = 1                     % Relative power node size distribution [m]
        WPOWER     (:,:) double  {mustBeNonnegative,mustBeNonempty}        = 1                     % Relative power distribution(s) [-] 
    
    end
    
    %% Methods
    
    methods
        
        % Constructor method
        function obj = boundaryConditions(bcf)
            
            fprintf('\n> Boundary conditions loaded from %s\n',bcf);
            bc = readInputFile(bcf);                                       % Load boundary conditions file
            
            % Remove unknown input fields
            param = fieldnames(bc);                                        % List of input fields
            ind_p =ismember(param,fieldnames(obj))';                       % param indexes included in object properties
            if any(~ind_p)
                fprintf(['  The following unkwown boundary condition inputs were discarded:' repmat(' %s',1,sum(~ind_p)) '\n'],param{~ind_p})
            end
            bc = rmfield(bc,param(~ind_p));                                % Remove unknown fields
            
            obj(1:length(bc))=obj;                                         % Build object array
            for k = 1:length(param)
                [obj.(param{k})] = deal(bc.(param{k}));                    % Assign each field to object array
            end
            for i=1:numel(obj)
                obj(i).WPOWER = reshape(obj(i).WPOWER,numel(obj(i).WMESH),[])'; % Reshape wall power
            end
            %!!!Should check that bc.WPOWER, bc.WMESH and geom.PERIM are consistent!!!
            
        end
        
        % Mass flux, usage: obj.MFLUX(geom)
        function MF = MFLUX(obj,geom)
            
            MF = arrayfun(@(x) x.MFLOW/geom.AREA,obj);                     % [kg/m^2/s] Mass flux
            
        end
        
        % Saturation temperature, usage: obj.TSAT(model)
        function  tsat = TSAT(obj,model)
            
            tsat = arrayfun(@(x) py.CoolProp.CoolProp.PropsSI('T','P',x.PRESSURE,'Q',1,model.FLUID),obj); % [K] Saturation temperature
            
        end
        
        % Liquid saturation enthalpy, usage: obj.HF(model)
        function hf = HF(obj,model)
            
            hf = arrayfun(@(x) py.CoolProp.CoolProp.PropsSI('H','P',x.PRESSURE,'Q',0,model.FLUID),obj); % [J/kg] Liquid saturation enthalpy
            
        end
        
        % Liquid saturation enthalpy, usage: obj.HG(model)
        function hg = HG(obj,model)
            
            hg = arrayfun(@(x) py.CoolProp.CoolProp.PropsSI('H','P',x.PRESSURE,'Q',1,model.FLUID),obj); % [J/kg] Vapor saturation enthalpy
            
        end
        
        % Inlet temperature, usage: obj.TIN(model)
        function tin = TIN(obj,model)
            
            tin = arrayfun(@(x) py.CoolProp.CoolProp.PropsSI('T','H',x.HIN,'P',x.PRESSURE,model.FLUID),obj); % [K] Inlet temperature
            
        end
        
        % Inlet subcooling, usage: obj.DTIN(model)
        function dtin = DTIN(obj,model)
            
            dtin = obj.TSAT(model)-obj.TIN(model);                         % [K] Inlet subcooling
            
        end
        
        % Inlet subcooling, usage: obj.DHIN(model)
        function dhin = DHIN(obj,model)
            
            dhin = arrayfun(@(x) x.HF(model)-x.HIN,obj);                   % [J/kg] Inlet subcooling
            
        end
        
        % Inlet equilibrium quality, usage: obj.XIN(model)
        function XIN = XIN(obj,model)
            
            XIN = -obj.DHIN(model)./(obj.HG(model)-obj.HF(model));         % [-] Inlet equilibrium quality
            
        end
                
        % Plot boundary conditions, usage: bc.plot(option,model)
        function plot(obj,model)
            
            figure('name','Boundary conditions plots')
            bcplot(obj,'PRESSURE','System pressure [Pa]',model,{},0)
            bcplot(obj,'HIN','Inlet enthalpy [J/kg]',model,{'HF','HG'},0)
            bcplot(obj,'MFLOW','Mass flow rate [kg/s]',model,{},0)
            bcplot(obj,'POWER','Power [W]',model,{},0)
            bcplot(obj,'TIN','Inlet temperature [K]',model,{'TSAT'},1)
            bcplot(obj,'XIN','Inlet quality [-]',model,{},1)
            bcplot(obj,'DTIN','Inlet subcooling [K]',model,{},1)
            bcplot(obj,'DHIN','Inlet subcooling [J/kg]',model,{},1)
            
        end
        
    end
    
end

%%

function bcplot(obj,param,label,model,sat,flag)

nexttile; hold all; grid on;
t = [obj.TIME];
switch flag
    case 0
        plot(t,[obj.(param)],'.-')
    case 1
        plot(t,[obj.(param)(model)],'.-')
end
cellfun(@(x) plot(t,obj.(x)(model),'k--'),sat);
xlabel('Time [s]'); xlim([min(t)-.01 max(t)+.01])
ylabel(label)
set(gca,'fontSize',14)

end
