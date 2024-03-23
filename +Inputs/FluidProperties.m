classdef FluidProperties
    %FLUIDPROPERTIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Fluid ID
        PROPERTIES (1,1) InputEnums.FLUIDPROPERTIES                        = 'SATURATED'           % Fluid property assumptions
        PRESSURE   (1,1) double  {mustBeNumeric}                           = 1                     % [Pa] System pressure
        TSAT       (1,1) double  {mustBeNumeric}                           = 1                     % [K] Saturated fluid temperature
        RHOF       (1,1) double  {mustBeNumeric}                           = 1                     % [kg/m^3] Saturated liquid mass density
        RHOG       (1,1) double  {mustBeNumeric}                           = 1                     % [kg/m^3] Saturated vapor mass density
        MUF        (1,1) double  {mustBeNumeric}                           = 1                     % [Pa.s] Saturated liquid viscosity
        MUG        (1,1) double  {mustBeNumeric}                           = 1                     % [Pa.s] Saturated vapor viscosity
        HF         (1,1) double  {mustBeNumeric}                           = 1                     % [J/kg] Saturated liquid enthalpy
        HG         (1,1) double  {mustBeNumeric}                           = 1                     % [J/kg] Saturated vapor enthalpy
        HFG        (1,1) double  {mustBeNumeric}                           = 0                     % [J/kg] Latent heat of evaporation
        SIGMA      (1,1) double  {mustBeNumeric}                           = 1                     % [N/m] Surface tension
        KF         (1,1) double  {mustBeNumeric}                           = 1                     % [W/m/K] Saturated liquid conductivity
        KG         (1,1) double  {mustBeNumeric}                           = 1                     % [W/m/K] Saturated vapor conductivity
        
    end

    properties (SetAccess=private)

        coolpropH   CoolPropWrapper.CoolPropWrapper
    
    end
    
    methods
        function obj = FluidProperties(P, modelObj)
            %FLUIDPROPERTIES Construct an instance of this class
            %   Detailed explanation goes here
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
            TSAT  = coolpropH.temperature('P',P,'Q',1);             % [K] Saturated fluid temperature
            RHOF  = coolpropH.density('P',P,'Q',0);                 % [kg/m^3] Saturated liquid mass density
            RHOG  = coolpropH.density('P',P,'Q',1);                 % [kg/m^3] Saturated vapor mass density
            MUF   = coolpropH.viscosity('P',P,'Q',0);               % [Pa.s] Saturated liquid viscosity
            MUG   = coolpropH.viscosity('P',P,'Q',1);               % [Pa.s] Saturated vapor viscosity
            HF    = coolpropH.enthalpy('P',P,'Q',0);                % [J/kg] Saturated liquid enthalpy
            HG    = coolpropH.enthalpy('P',P,'Q',1);                % [J/kg] Saturated vapor enthalpy
            SIGMA = coolpropH.surfaceTension('P',P,'Q',1);          % [N/m] Surface tension
            KF    = coolpropH.conductivity('P',P,'Q',0);            % [W/m/K] Saturated liquid conductivity
            KG    = coolpropH.conductivity('P',P,'Q',1);            % [W/m/K] Saturated vapor conductivity

            coolpropH.setSpecifyPhase('');

            % Assign properties to each object
            for i = 1:length(obj)

                % Save fluid name and properies
                obj(i).FLUID = modelObj.FLUID;
                obj(i).PROPERTIES = modelObj.PROPERTIES;

                % Share the same coolPropH
                obj(i).coolpropH = coolpropH;

                % Distribute properties
                obj(i).PRESSURE = P(i);                                     % [Pa] Saturated fluid pressure
                obj(i).TSAT  = TSAT(i);                                     % [K] Saturated fluid temperature
                obj(i).RHOF  = RHOF(i);                                     % [kg/m^3] Saturated liquid mass density
                obj(i).RHOG  = RHOG(i);                                     % [kg/m^3] Saturated vapor mass density
                obj(i).MUF   = MUF(i);                                      % [Pa.s] Saturated liquid viscosity
                obj(i).MUG   = MUG(i);                                      % [Pa.s] Saturated vapor viscosity
                obj(i).HF    = HF(i);                                       % [J/kg] Saturated liquid enthalpy
                obj(i).HG    = HG(i);                                       % [J/kg] Saturated vapor enthalpy
                obj(i).HFG   = HG(i) - HF(i);                               % [J/kg] Latent heat of evaporation
                obj(i).SIGMA = SIGMA(i);                                    % [N/m] Surface tension
                obj(i).KF    = KF(i);                                       % [W/m/K] Saturated liquid conductivity
                obj(i).KG    = KG(i);                                       % [W/m/K] Saturated vapor conductivity
                
            end
            
        end
        
        
        function t = T(obj,H)
            %T Fluid temperature [K] at obj.PRESSURE and H
            t = obj.coolpropH.temperature('P',obj.PRESSURE,'H',H); 
            
        end
        
        function h = H(obj,T)
            %H Fluid enthalpy [J/kg] at obj.PRESSURE and T
            h = obj.coolpropH.enthalpy('P',obj.PRESSURE,'T',T);
            
        end
        
        function rhol = RHOL(obj,H)
            %RHOL Liquid mass density (subcooled to saturated) [kg/m^3]
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
            %RHOV Vapor mass density (saturated to superheated) [kg/m^3]
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
            %MUL Liquid dynamic viscosity [Pa-s]
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
            %MUV Vapor dynamic viscosity [Pa-s]
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
            %KL Liquid conductivity (subcooled to saturated) [W/m/K]
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
            %KV Vapor conductivity (saturated to superheated) [W/m/K]
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
        
        function plot(obj, H)
            %PLOT Plot properties for given enthalpy vector
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

