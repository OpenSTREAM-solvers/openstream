classdef FluidProperties
    %FLUIDPROPERTIES Defines all thermophysical properties for the selected
    %simulation fluid
    %
    %   TODO: Detailed explanations
    
    properties (SetAccess=immutable)
        
        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Fluid ID
        PROPERTIES (1,1) InputEnums.FLUIDPROPERTIES                        = 'SATURATED'           % Fluid property assumptions
        PRESSURE   (1,1) double  {mustBeNumeric}                           = 1                     % System pressure [Pa]
        TSAT       (1,1) double  {mustBeNumeric}                           = 1                     % Saturated fluid temperature [K]
        RHOF       (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid mass density [kg/m^3]
        RHOG       (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor mass density [kg/m^3]
        MUF        (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid viscosity [Pa.s]
        MUG        (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor viscosity [Pa.s]
        HF         (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid enthalpy [J/kg]
        HG         (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor enthalpy [J/kg]
        HFG        (1,1) double  {mustBeNumeric}                           = 0                     % Latent heat of evaporation [J/kg]
        SIGMA      (1,1) double  {mustBeNumeric}                           = 1                     % Surface tension [N/m]
        KF         (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid thermal conductivity [W/m/K]
        KG         (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor thermal conductivity [W/m/K]
        CPF        (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid constant pressure specific heat [J/kg/K]
        CPG        (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor constant pressure specific heat [J/kg/K]
        PRANDTLF   (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid Prandtl number [-]
        PRANDTLG   (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor Prandtl number [-]
        PCRIT      (1,1) double  {mustBeNumeric}                           = 1                     % Critical pressure [-]
    end

    properties (SetAccess=private)

        coolpropH   CoolPropWrapper.CoolPropWrapper
   
    end
    
    methods
        function obj = FluidProperties(P, modelObj)
            %FluidProperties Construct an instance of this class
            %
            arguments
                P        
                modelObj (1,1)        {isa(modelObj, 'Model')}
            end
            
            % Import the CoolPropWrapper class
            import CoolPropWrapper.CoolPropWrapper

            % Create fluid property object array
            obj(1:length(P)) = obj;
            
            % Setup CoolProp
            coolpropH = CoolPropWrapper(modelObj.FLUID);

            % set AbstractState to HEOS
            coolpropH.setAbstractStateSrc(coolpropH.EOS.BICUBIC_HEOS);

            % set to vector mode
            coolpropH.setOutputMode('vec');
            
            % Calculate properties at saturation
            coolpropH.setSpecifyPhase('twophase');
            TSAT     = coolpropH.temperature('P',P,'Q',1);                 % [K] Saturated fluid temperature
            RHOF     = coolpropH.density('P',P,'Q',0);                     % [kg/m^3] Saturated liquid mass density
            RHOG     = coolpropH.density('P',P,'Q',1);                     % [kg/m^3] Saturated vapor mass density
            MUF      = coolpropH.viscosity('P',P,'Q',0);                   % [Pa.s] Saturated liquid viscosity
            MUG      = coolpropH.viscosity('P',P,'Q',1);                   % [Pa.s] Saturated vapor viscosity
            HF       = coolpropH.enthalpy('P',P,'Q',0);                    % [J/kg] Saturated liquid enthalpy
            HG       = coolpropH.enthalpy('P',P,'Q',1);                    % [J/kg] Saturated vapor enthalpy
            SIGMA    = coolpropH.surfaceTension('P',P,'Q',1);              % [N/m] Surface tension
            KF       = coolpropH.conductivity('P',P,'Q',0);                % [W/m/K] Saturated liquid thermal conductivity
            KG       = coolpropH.conductivity('P',P,'Q',1);                % [W/m/K] Saturated vapor thermal conductivity
            CPF      = coolpropH.cp('P',P,'Q',0);                          % [J/kg/K] Saturated liquid constant pressure specific heat
            CPG      = coolpropH.cp('P',P,'Q',1);                          % [J/kg/K] Saturated vapor constant pressure specific heat
            PRANDTLF = coolpropH.prandtl('P',P,'Q',0);                     % [-] Saturated liquid Prandtl number
            PRANDTLG = coolpropH.prandtl('P',P,'Q',1);                     % [-] Saturated vapor Prandtl number
            coolpropH.setSpecifyPhase('');

            % Critical properties
            PCRIT    = coolpropH.CoolProp.p_critical;                      % [Pa] Critical pressure
            
            % Assign properties to each object
            for i = 1:length(obj)

                % Save fluid name and properies
                obj(i).FLUID = modelObj.FLUID;
                obj(i).PROPERTIES = modelObj.PROPERTIES;

                % Share the same coolPropH
                obj(i).coolpropH = coolpropH;

                % Distribute properties
                obj(i).PRESSURE = P(i);                                    % [Pa] System pressure
                obj(i).TSAT     = TSAT(i);                                 % [K] Saturated fluid temperature
                obj(i).RHOF     = RHOF(i);                                 % [kg/m^3] Saturated liquid mass density
                obj(i).RHOG     = RHOG(i);                                 % [kg/m^3] Saturated vapor mass density
                obj(i).MUF      = MUF(i);                                  % [Pa.s] Saturated liquid viscosity
                obj(i).MUG      = MUG(i);                                  % [Pa.s] Saturated vapor viscosity
                obj(i).HF       = HF(i);                                   % [J/kg] Saturated liquid enthalpy
                obj(i).HG       = HG(i);                                   % [J/kg] Saturated vapor enthalpy
                obj(i).HFG      = HG(i) - HF(i);                           % [J/kg] Latent heat of evaporation
                obj(i).SIGMA    = SIGMA(i);                                % [N/m] Surface tension
                obj(i).KF       = KF(i);                                   % [W/m/K] Saturated liquid thermal conductivity
                obj(i).KG       = KG(i);                                   % [W/m/K] Saturated vapor thermal conductivity
                obj(i).CPF      = CPF(i);                                  % [J/kg/K] Saturated liquid constant pressure specific heat
                obj(i).CPG      = CPG(i);                                  % [J/kg/K] Saturated vapor constant pressure specific heat
                obj(i).PRANDTLF = PRANDTLF(i);                             % [-] Saturated liquid Prandtl number
                obj(i).PRANDTLG = PRANDTLG(i);                             % [-] Saturated vapor Prandtl number
                obj(i).PCRIT    = PCRIT;                                   % [Pa] Critical pressure
                
            end
            
        end
        
        
        function t = T(obj,H)
        %T [K] Fluid temperature at obj.PRESSURE and given H
        %
            t = obj.coolpropH.temperature('P',obj.PRESSURE,'H',H); 
        end
        
        function h = H(obj,T)
        %H [J/kg] Fluid enthalpy at obj.PRESSURE and given T
        %
            h = obj.coolpropH.enthalpy('P',obj.PRESSURE,'T',T);
        end
        
        function rhol = RHOL(obj,H)
        %RHOL [kg/m^3] Liquid mass density (subcooled to saturated)
        %
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    rhol = repmat(obj.RHOF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    rhol = obj.coolpropH.density('P',obj.PRESSURE,'H',min(H,obj.HF));
            end
        end
        
        function rhov = RHOV(obj,H)
        %RHOV [kg/m^3] Vapor mass density (saturated to superheated)
        %    
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    rhov = repmat(obj.RHOG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    rhov = obj.coolpropH.density('P',obj.PRESSURE,'H',max(H,obj.HG));
            end
        end
        
        function mul = MUL(obj,H)
        %MUL [Pa.s] Liquid dynamic viscosity
        %
            arguments
                obj
                H
            end
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    mul = repmat(obj.MUF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    mul = obj.coolpropH.viscosity('P',obj.PRESSURE,'H',min(H,obj.HF));
            end
        end
        
        function muv = MUV(obj,H)
        %MUV [Pa.s] Vapor dynamic viscosity
        %
            arguments
                obj
                H
            end
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    muv = repmat(obj.MUG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    muv = obj.coolpropH.viscosity('P',obj.PRESSURE,'H',max(H,obj.HG));
            end
        end
        
        function kl = KL(obj,H)
        %KL [W/m/K] Liquid thermal conductivity (subcooled to saturated)
        %
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    kl = repmat(obj.KF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    kl = obj.coolpropH.conductivity('P',obj.PRESSURE,'H',min(H,obj.HF));
            end
        end
        
        function kv = KV(obj,H)
        %KV [W/m/K] Vapor thermal conductivity (saturated to superheated)
        %
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    kv = repmat(obj.KG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    kv = obj.coolpropH.conductivity('P',obj.PRESSURE,'H',max(H,obj.HG));
            end
        end
        
        function cpl = CPL(obj,H)
        %CPL [J/kg/K] Liquid constant pressure specific heat (subcooled to saturated)
        %
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    cpl = repmat(obj.CPF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    cpl = obj.coolpropH.cp('P',obj.PRESSURE,'H',min(H,obj.HF));
            end
        end
        
        function cpv = CPV(obj,H)
        %CPV [J/kg/K] Vapor constant pressure specific heat (subcooled to saturated)
        %
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    cpv = repmat(obj.CPG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    cpv = obj.coolpropH.cp('P',obj.PRESSURE,'H',max(H,obj.HG));
            end
        end
        
        function prandtll = PRANDTLL(obj,H)
        %PRANDTLL [-] Liquid Prandtl number (subcooled to saturated)
        %
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    prandtll = repmat(obj.PRANDTLF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    prandtll = obj.coolpropH.prandtl('P',obj.PRESSURE,'H',min(H,obj.HF));
            end
        end
        
        function prandtlv = PRANDTLV(obj,H)
        %PRANDTLV [-] Vapor Prandtl number (saturated to superheated)
        %
            arguments
                obj
                H
            end
            
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    prandtlv = repmat(obj.PRANDTLG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    prandtlv = obj.coolpropH.prandtl('P',obj.PRESSURE,'H',max(H,obj.HG));
            end
        end
        
        function paramData = transient(obj, param, opt)
        %TRANSIENT Generate transient distribution array for parameter param
        %
            arguments
                obj
                param         (1,1) string {mustBeTextScalar}
                opt.tIdx      (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:length(obj)
            end
            
            paramData = [obj(opt.tIdx).(param)];
        end
        
        function plot(obj, H)
        %PLOT Plot properties for given enthalpy vector
        %
            arguments
                obj
                H
            end
            figure( ...
                'name',sprintf('%s property plots at %s [Pa]',obj.FLUID, num2str(obj.PRESSURE)) ...
                );
            propplot('T','Fluid temperature [K]',{'TSAT'})
            propplot('RHOL','Liquid density [kg/m^3]',{'RHOF','RHOG'})
            propplot('RHOV','Vapor density [kg/m^3]',{'RHOF','RHOG'})
            propplot('MUL','Liquid dynamic viscosity [Pa.s]',{'MUF','MUG'})
            propplot('MUV','Vapor dynamic viscosity [Pa.s]',{'MUF','MUG'})


            function propplot(prop,plotLabelY,satPropertyName)

                nexttile; hold all; grid on;
                % Plot enthalpy vs. prop
                plot(H,obj.(prop)(H),'.-')
                % Plot each satProperty
                for i = 1:length(satPropertyName)
                    satProperty = obj.(satPropertyName{i});
                    plot(xlim,repmat(satProperty,1,2),'k--');
                end
                xlabel('Enthalpy [J/kg]'); xlim([min(H) max(H)]);
                ylabel(plotLabelY)
                set(gca,'fontSize',14)
            
            end
        end

    end

end

