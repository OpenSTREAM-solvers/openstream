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
        DP           (1,1) struct                                                                 % [-] Detailed pressure drops
        ITR          (1,1) struct                                                                 % [-] Detailed inner iteration results
        
    end
    
    %% Methods
    
    methods
        
        % Constructor method
        function obj = mixture(bcond)
            
            fprintf('\n> Mixture field initialized\n');
            
            obj(1:length(bcond.TIME)) = obj;                               % Initialize object array
            N = length(bcond.Z);                                           % Number of axial nodes
            
            for k = 1:length(bcond.TIME)
                obj(k).TIME  = bcond.TIME(k);                              % [s] Time
                obj(k).Z     = bcond.Z;                                    % [m] Elevation
                obj(k).HFLUX = bcond.HFLUX{k};                             % [W/m^2] Wall heat flux

                obj(k).W     = repmat(bcond.MFLOW(k),N,1);                 % [kg/s] Mass flow rate
                obj(k).P     = repmat(bcond.PRESSURE(k),N,1);              % [Pa] Pressure
                obj(k).H     = repmat(bcond.HIN(k),N,1);                   % [J/kg] Enthalpy
                
                obj(k).DP.Grav  = zeros(N,1);                              % [Pa] Gravitational pressure drop
                obj(k).DP.Wall  = zeros(N,1);                              % [Pa] Wall friction pressure drop
                obj(k).DP.Acc_z = zeros(N,1);                              % [pa] Spatial acceleration pressure drop
                obj(k).DP.Acc_t = zeros(N,1);                              % [Pa] Temporal acceleration pressure drop
                obj(k).DP.K     = zeros(N,1);                              % [Pa] Local pressure drop
                obj(k).DP.Tot   = zeros(N,1);                              % [Pa] Total pressure drop
                
                obj(k).ITR.N    = zeros(N,1);
                obj(k).ITR.DW   = zeros(N,1);
                obj(k).ITR.DP   = zeros(N,1);
                obj(k).ITR.DH   = zeros(N,1);
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
        
        % Void fraction, usage: mix(i).VF(prop(i),model,geom,k) or VF(mix(i),prop(i),model,geom,k)
        function vf = VF(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            switch model.VOID
                case 'HOMOGENEOUS'
                    vf = vfslip(obj.X(prop,model,k),prop,1);               % [-] Homogeneous void model
                case 'SLIP'
                    vf = vfslip(obj.X(prop,model,k),prop,model.SLIP);      % [-] Slip void dmodel
                case 'BESTION'
                    C0 = 1.;                                               % [-] Distribution parameter
                    ugj = 0.188.*(model.G.*geom.HDIAM.*(prop.RHOF-prop.RHOG)./prop.RHOG).^(1/2); % [m/s] Drift velocity
                    vf = vfdrift(obj,prop,model,geom,C0,ugj,k);            % [-] Bestion drift flux model
            end
            
        end
        
        % Density, usage: mix(i).RHO(prop(i),model,geom,k) or RHO(mix(i),prop(i),model,geom,k)
        function rho = RHO(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            rho = obj.VF(prop,model,geom,k).*prop.RHOV(obj.H(k))+(1-obj.VF(prop,model,geom,k)).*prop.RHOL(obj.H(k)); % [kg/m^3] Density
            
        end
        
        % Dynamic viscosity, usage: mix(i).MU(prop(i),model,k) or MU(mix(i),prop(i),model,k)
        function mu = MU(obj,prop,model,k)
            
            if nargin < 4, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            mu = obj.X(prop,model,k).*prop.MUV(obj.H(k))+(1-obj.X(prop,model,k)).*prop.MUL(obj.H(k)); % [Pa.s] Dynamic viscosity
            
        end
        
        % Velocity, usage: mix(i).U(prop(i),model,geom,k) or U(mix(i),prop(i),model,geom,k)
        function u = U(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            u = obj.W(k)./obj.RHO(prop,model,geom,k)./geom.AREA;                % [m/s] Velocity
            
        end
        
        % Superficial liquid velocity, usage: mix(i).JL(prop(i),model,geom,k) or JL(mix(i),prop(i),model,geom,k)
        function jl = JL(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            jl = (1-obj.X(prop,model,k)).*obj.MFLUX(geom,k)./prop.RHOL(obj.H(k));  % [m/s] Superficial liquid velocity
            
        end
        
        % Superficial vapor velocity, usage: mix(i).JG(prop(i),model,geom,k) or JG(mix(i),prop(i),model,geom,k)
        function jg = JG(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            jg = obj.X(prop,model,k).*obj.MFLUX(geom,k)./prop.RHOV(obj.H(k));  % [m/s] Superficial vapor velocity
            
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
            tauw = 0.5.*(obj.FW(prop,model,geom,k)./4)./obj.RHO(prop,model,geom,k).*(obj.W(k)./geom.AREA).^2; % [Pa] Mixture wall shear stress
            
        end
        
        % Local pressure loss coefficient, usage: mix(i).KLOSS(model,k) or KLOSS(mix(i),model,k)
        function kloss = KLOSS(obj,model,k)
        
        if nargin < 3, k = 1:length(obj.Z); end                            % Case where node elevation is not specified
        kloss = zeros(length(obj.Z),1);                                    % [-] Initialize local loss coefficient array to 0
        [~,ind]=min(abs(obj.Z-model.KLOC));                                % Find local loss elevation indexes (closest node)
        kloss(ind)=model.KLOSS;                                            % [-] Apply loss
        kloss = kloss(k);                                                  % [-] Restrict to selected nodes
        
        end

        
        % Local pressure loss, usage: mix(i).DPK(prop(i),model,geom,k) or DPK(mix(i),prop(i),model,geom,k)
        function dpk = DPK(obj,prop,model,geom,k)
            
            if nargin < 5, k = 1:length(obj.Z); end                        % Case where node elevation is not specified
            dpk = 0.5.*obj.KLOSS(model,k)./obj.RHO(prop,model,geom,k).*(obj.W(k)./geom.AREA).^2; % [Pa] Mixture local pressure loss
            
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
                case {'X','MU'}
                    tarray = arrayfun(@(x,y) x.(param)(y,model,k),obj,prop); 
                case {'VF','RHO','U','RE','FW','TAUW'}
                    tarray = arrayfun(@(x,y) x.(param)(y,model,geom,k),obj,prop);
            end
            
        end
        
        % Plot axial distributions of parameters at time step i, usage: mix.plotz(i,prop,model,geom) or plotz(mix,i,prop,model,geom)
        function plotz(obj,i,prop,model,geom)
            
            liq = liquid(obj(i));
            vap = vapor(obj(i));
            
            figure('name',['Axial distributions of mixture parameters at ' num2str(obj(i).TIME) ' [s]'])
            
            nexttile; hold all; grid on;
            plot(obj(i).Z,obj(i).W,'.-')
            plot(liq.Z,liq.W(obj(i),prop(i),model),'.-')
            plot(vap.Z,vap.W(obj(i),prop(i),model),'.-')
            xlabel('Axial position [m]'); xlim(obj(i).Z([1 end]));
            ylabel('Mass flowrates [kg/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(obj(i).Z,cumsum(obj(i).DP.Tot),'.-')
            plot(obj(i).Z,cumsum(obj(i).DP.Grav),'.-')
            plot(obj(i).Z,cumsum(obj(i).DP.Wall),'.-')
            plot(obj(i).Z,cumsum(obj(i).DP.Acc_z),'.-')
            plot(obj(i).Z,cumsum(obj(i).DP.Acc_t),'.-')
            plot(obj(i).Z,cumsum(obj(i).DP.K),'.-')
            xlabel('Axial position [m]'); xlim(obj(i).Z([1 end]));
            ylabel('Pressure drop [Pa]')
            legend({'Total','Gravitational','Wall','Acc z','Acc t','Local'},'location','northWest');
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(obj(i).Z,obj(i).XEQ(prop(i)),'.-')
            plot(obj(i).Z,obj(i).X(prop(i),model),'.-')
            plot(obj(i).Z,obj(i).VF(prop(i),model,geom),'.-')
            xlabel('Axial position [m]'); xlim(obj(i).Z([1 end]));
            ylabel('Quality / Void fraction [-]')
            legend({'Equilibrium quality','Vapor mass quality','Void fraction'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(obj(i).Z,obj(i).U(prop(i),model,geom),'.-')
            plot(liq.Z,liq.U(obj(i),prop(i),model,geom),'.-')
            plot(vap.Z,vap.U(obj(i),prop(i),model,geom),'.-')
            xlabel('Axial position [m]'); xlim(obj(i).Z([1 end]));
            ylabel('Velocities [m/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)
            
        end
        
        % Plot time series of parameters at node k, usage: mix.plott(option,model) or plott(mix,option,model)
        function plott(obj,k,prop,model,geom)
            
            figure('name',['Time series of mixture parameters at ' num2str(obj(1).Z(k)') ' [m]'])
            
            timeplot(obj,k,'W','Mass flowrates [kg/s]',prop,model,geom)
            timeplot(obj,k,'P','Pressure [Pa]',prop,model,geom)
            timeplot(obj,k,'XEQ','Equilibrium quality [-]',prop,model,geom)
            timeplot(obj,k,'X','Steam mass quality [-]',prop,model,geom)
            timeplot(obj,k,'VF','Void fraction [-]',prop,model,geom)
            timeplot(obj,k,'U','Velocity [m/s]',prop,model,geom)
            
        end
        
    end
    
end

%%

% Void fraction based on slip model
function vf = vfslip(x,prop,S)

vf = x.*prop.RHOF./(x.*prop.RHOF+S.*(1-x).*prop.RHOG);                     % [-] Void fraction

end

% Void fraction based on drift flux model
function vf = vfdrift(obj,prop,model,geom,C0,ugj,k)

vf  = obj.JG(prop,model,geom,k)./(C0.*(obj.JG(prop,model,geom,k)+obj.JL(prop,model,geom,k))+ugj); % [-] Void fraction

end

%
function timeplot(obj,k,param,name,prop,model,geom)

nexttile; hold all; grid on;
for ik=k
    plot([obj.TIME],obj.TARRAY(param,ik,prop,model,geom),'.-','displayName',[num2str(obj(1).Z(ik)) ' [m]'])
end
xlabel('Time [s]'); xlim([obj([1 end]).TIME]);
ylabel(name)
legend('show','location','southEast')
set(gca,'fontSize',14)

end
