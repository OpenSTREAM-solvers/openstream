%
%   Class mixture
%
%   Usage: mix = mixture(bcond)
%

classdef mixture
    
    %% Properties
    
    properties (SetAccess=private)
        
        TIME         (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
        
    end
    
    properties
        
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                         = 7E6                  % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        
    end
    
    %% Methods
    
    methods
        
        % Constructor method
        function obj = mixture(bcond)
            
            fprintf('\n*** Creating mixture class ***\n\n');
            
            obj(1:length(bcond.TIME)) = obj;                               % Initialize object array
            N = length(bcond.Z);                                           % Number of axial nodes
            
            for k = 1:length(bcond.TIME)
                obj(k).TIME  = bcond.TIME(k);                              % [s] Time
                obj(k).Z     = bcond.Z;                                    % [m] Elevation
                obj(k).HFLUX = bcond.HFLUX{k};                             % [W/m^2] Wall heat flux

                obj(k).W     = repmat(bcond.MFLOW(k),N,1);                 % [kg/s] Mass flow rate
                obj(k).P     = repmat(bcond.PRESSURE(k),N,1);              % [Pa] Pressure
                obj(k).H     = repmat(bcond.HIN(k),N,1);                   % [J/kg] Enthalpy
            end
            
        end
        
        % Mass flux, usage: mix(i).MFLUX(geom,k)
        function mflux = MFLUX(obj,geom,k)
            
            if nargin < 3, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            mflux = obj.W(k)/geom.AREA;                                    % [kg/m^2/s] Mass flux
            
        end
        
        % Equilibrium quality, usage: mix(i).XEQ(prop(i),k) or XEQ(mix(i),prop(i),k)
        function xeq = XEQ(obj,prop,k)
            
            if nargin < 3, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            xeq = (obj.H(k)-prop.HF)./prop.HFG;                            % [-] Equilibrium quality
            
        end
        
        % Vapor quality, usage: mix(i).X(prop(i),model,k) or X(mix(i),prop(i),model,k)
        function x = X(obj,prop,model,k)
            
            if nargin < 4, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            switch model.SCBOIL
                case 'NONE'
                    x = min(max(obj.XEQ(prop,k),0),1);                     % [-] Vapor quality
            end
            
        end
        
%         % Void fraction, usage: mix(i).VF(prop(i),model,k) or VF(mix(i),prop(i),model,k)
%         function vf = VF(obj,prop,model,k)
%             
%             if nargin < 4, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
%             switch model.VOID
%                 case 'HOMOGENEOUS'
%                     vf = vfslip(obj.X(prop,model,k),prop,1);               % [-] Homogeneous void model
%                 case 'SLIP'
%                     vf = vfslip(obj.X(prop,model,k),prop,model.SLIP);      % [-] Slip void dmodel
%             end
%             
%         end
        
        % Density, usage: mix(i).RHO(prop(i),model,k) or RHO(mix(i),prop(i),model,k)
        function rho = RHO(obj,prop,model,k)
            
            if nargin < 4, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            rho = obj.VF(prop,model,k).*prop.RHOV(obj.H(k))+(1-obj.VF(prop,model,k)).*prop.RHOL(obj.H(k)); % [kg/m^3] Density
            
        end
        
        % Dynamic viscosity, usage: mix(i).MU(prop(i),model,k) or MU(mix(i),prop(i),model,k)
        function mu = MU(obj,prop,model,k)
            
            if nargin < 4, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            mu = obj.X(prop,model,k).*prop.MUV(obj.H(k))+(1-obj.X(prop,model,k)).*prop.MUL(obj.H(k)); % [Pa.s] Dynamic viscosity
            
        end
        
        % Velocity, usage: mix(i).U(prop(i),model,geom,k) or U(mix(i),prop(i),model,geom,k)
        function u = U(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            u = obj.W(k)./obj.RHO(prop,model,k)./geom.AREA;                % [m/s] Velocity
            
        end
        
        % Reynolds number, usage: mix(i).RE(prop(i),model,geom,k) or RE(mix(i),prop(i),model,geom,k)
        function re = RE(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            re = 4.*obj.W(k)./obj.MU(prop,model,k)./sum(geom.PERIM);       % [-] Reynolds number
            
        end
        
        % Liquid-equivalent Reynolds number, usage: mix(i).REL(prop(i),geom,k) or REL(mix(i),prop(i),geom,k)
        function rel = REL(obj,prop,geom,k)
            
            if nargin < 4, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            rel = 4.*obj.W(k)./prop.MUL(obj.H(k))./sum(geom.PERIM);        % [-] Liquid-equivalent Reynolds number
            
        end
        
        % Wall friction factor, usage: mix(i).FW(prop(i),model,geom,k) or FW(mix(I),prop(i),model,geom,k)
        function fw = FW(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            fw = model.FRICTION(1).*obj.RE(prop,model,geom,k).^model.FRICTION(2)+model.FRICTION(3); % [-] Wall friction factor
            
        end
        
        % Wall shear stress, usage: mix(i).TAUW(prop(i),model,geom,k) or TAUW(mix(i),prop(i),model,geom,k)
        function tauw = TAUW(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            tauw = 0.5.*(obj.FW(prop,model,geom,k)./4)./obj.RHO(prop,model,k).*(obj.W(k)./geom.AREA).^2; % [Pa] Mixture wall shear stress
            
        end
        
        % Temperature, usage: mix(i).T(prop(i)) or T(mix(i),prop(i),k)
        function t = T(obj,prop,k)
            
            if nargin < 3, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            t = prop.T(obj.H(k));                                          % [K] Temperature
            
        end
        
        % Time array of selected parameter at selected node k, usage: mix.TARRAY(param,k,prop,model,geom) or TARRAY(mix,param,k,prop,model,geom)
        function tarray = TARRAY(obj,param,k,prop,model,geom)
            
            switch param
                case {'W','P','H'}
                    tarray = arrayfun(@(x) x.(param)(k),obj);
                case {'MFLUX'}
                    tarray = arrayfun(@(x) x.(param)(geom,k),obj);
                case {'XEQ','T'}
                    tarray = arrayfun(@(x,y) x.(param)(y,k),obj,prop);
                case {'REL'}
                    tarray = arrayfun(@(x,y) x.(param)(y,geom,k),obj,prop);           
                case {'X','VF','RHO','MU'}
                    tarray = arrayfun(@(x,y) x.(param)(y,model,k),obj,prop); 
                case {'U','RE','FW','TAUW'}
                    tarray = arrayfun(@(x,y) x.(param)(y,model,geom,k),obj,prop);
            end
            
        end
        
    end
    
end

%%

% % Void fraction based on slip model
% function vf = vfslip(x,prop,S)
% 
% vf  = x.*prop.RHOF./(x.*prop.RHOF+S.*(1-x).*prop.RHOG);                    % [-] Void fraction based on slip model
% 
% end
