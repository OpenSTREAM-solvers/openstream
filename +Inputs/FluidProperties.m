classdef FluidProperties < Inputs.IndexableInput
    %FLUIDPROPERTIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Fluid ID
        PROPERTIES (1,1) string  {mustBeTextScalar,mustBeMember(PROPERTIES, ["SATURATED","PSYSTEM"])} ...
                                                                           = 'SATURATED'           % Fluid property assumptions
        PRESSURE   (:,1) double  {mustBeNumeric}                           = 1                     % [Pa] System pressure
        TSAT       (:,1) double  {mustBeNumeric}                           = 1                     % [K] Saturated fluid temperature
        RHOF       (:,1) double  {mustBeNumeric}                           = 1                     % [kg/m^3] Saturated liquid mass density
        RHOG       (:,1) double  {mustBeNumeric}                           = 1                     % [kg/m^3] Saturated vapor mass density
        MUF        (:,1) double  {mustBeNumeric}                           = 1                     % [Pa.s] Saturated liquid viscosity
        MUG        (:,1) double  {mustBeNumeric}                           = 1                     % [Pa.s] Saturated liquid viscosity
        HF         (:,1) double  {mustBeNumeric}                           = 1                     % [J/kg] Saturated liquid enthalpy
        HG         (:,1) double  {mustBeNumeric}                           = 1                     % [J/kg] Saturated vapor enthalpy
        SIGMA      (:,1) double  {mustBeNumeric}                           = 1                     % [N/m] Surface tension
        
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
            
            % Save fluid name and properies
            obj.FLUID = modelObj.FLUID;
            obj.PROPERTIES = modelObj.PROPERTIES;
            
            % Setup CoolProp
            obj.coolpropH = CoolPropWrapper(obj.FLUID);

            % set AbstractState to HEOS
            obj.coolpropH.setAbstractStateSrc(obj.coolpropH.EOS.BICUBIC_HEOS);

            % set to vector mode
            obj.coolpropH.setOutputMode('vec');
            
            % Save pressure vector
            obj.PRESSURE = P;

            % Calculate properties at saturation
            obj.coolpropH.setSpecifyPhase('twophase');
            obj.TSAT  = obj.coolpropH.temperature('P',obj.PRESSURE,'Q',1);             % [K] Saturated fluid temperature
            obj.RHOF  = obj.coolpropH.density('P',obj.PRESSURE,'Q',0);                 % [kg/m^3] Saturated liquid mass density
            obj.RHOG  = obj.coolpropH.density('P',obj.PRESSURE,'Q',1);                 % [kg/m^3] Saturated vapor mass density
            obj.MUF   = obj.coolpropH.viscosity('P',obj.PRESSURE,'Q',0);               % [Pa.s] Saturated liquid viscosity
            obj.MUG   = obj.coolpropH.viscosity('P',obj.PRESSURE,'Q',1);               % [Pa.s] Saturated vapor viscosity
            obj.HF    = obj.coolpropH.enthalpy('P',obj.PRESSURE,'Q',0);                % [J/kg] Saturated liquid enthalpy
            obj.HG    = obj.coolpropH.enthalpy('P',obj.PRESSURE,'Q',1);                % [J/kg] Saturated vapor enthalpy
            
            
            % set AbstractState to HEOS
            obj.coolpropH.setAbstractStateSrc(obj.coolpropH.EOS.HEOS);
            obj.SIGMA = obj.coolpropH.surfaceTension('P',obj.PRESSURE,'Q',1);          % [N/m] Surface tension        
            obj.coolpropH.setAbstractStateSrc(obj.coolpropH.EOS.HEOS);

            obj.coolpropH.setSpecifyPhase('');
            
        end
        
        
        function hfg = HFG(obj)
            %HFG Latent heat of evaporation
            hfg = obj.HG-obj.HF;                                           % [J/kg] Latent heat of evaporation
            
        end
        
        
        function t = T(obj,H,idx)
            %T Fluid temperature [K] at obj.PRESSURE and H
            arguments
                obj
                H
                idx = 1:length(obj.PRESSURE)
            end
            t = obj.coolpropH.temperature('P',obj.PRESSURE(idx),'H',H); 
            
        end
        
        function h = H(obj,T,idx)
            %H Fluid enthalpy [J/kg] at obj.PRESSURE and T
            arguments
                obj
                T
                idx = 1:length(obj.PRESSURE)
            end
            h = obj.coolpropH.enthalpy('P',obj.PRESSURE(idx),'T',T);
            
        end
        
        function rhol = RHOL(obj,H,idx)
            %RHOL Liquid mass density (subcooled to saturated) [kg/m^3]
            arguments
                obj
                H
                idx = 1:length(obj.PRESSURE)
            end
            
            switch obj.PROPERTIES
                case 'SATURATED'
                    rhol = repmat(obj.RHOF(idx),numel(H),1);
                case 'PSYSTEM'
                    rhol = obj.coolpropH.density('P',obj.PRESSURE(idx),'H',min(H,obj.HF));
            end
            
        end
        
        function rhov = RHOV(obj,H,idx)
            %RHOV Vapor mass density (saturated to superheated) [kg/m^3]
            arguments
                obj
                H
                idx = 1:length(obj.PRESSURE)
            end
            
            switch obj.PROPERTIES
                case 'SATURATED'
                    rhov = repmat(obj.RHOG(idx),numel(H),1);
                case 'PSYSTEM'
                    rhov = obj.coolpropH.density('P',obj.PRESSURE(idx),'H',max(H,obj.HG));
            end
            
        end
        
        function mul = MUL(obj,H,idx)
            %MUL Liquid dynamic viscosity [Pa-s]
            arguments
                obj
                H
                idx = 1:length(obj.PRESSURE)
            end
            switch obj.PROPERTIES
                case 'SATURATED'
                    mul = repmat(obj.MUF(idx),numel(H),1);
                case 'PSYSTEM'
                    mul = obj.coolpropH.viscosity('P',obj.PRESSURE(idx),'H',min(H,obj.HF));
            end
            
        end
        
        function muv = MUV(obj,H,idx)
            %MUV Vapor dynamic viscosity [Pa-s]
            arguments
                obj
                H
                idx = 1:length(obj.PRESSURE)
            end
            switch obj.PROPERTIES
                case 'SATURATED'
                    muv = repmat(obj.MUF(idx),numel(H),1);
                case 'PSYSTEM'
                    muv = obj.coolpropH.viscosity('P',obj.PRESSURE(idx),'H',max(H,obj.HG));
            end
            
        end
        
        function varargout = size(obj,varargin)
            [varargout{1:nargout}] = size(obj.PRESSURE,varargin{:});
        end
        
        function plot(obj, H, idx)
            %PLOT Plot properties for given enthalpy vector
            arguments
                obj
                H
                idx (1,1) {isinteger} = 1
            end
            figure( ...
                'name',sprintf('%s property plots at %s [Pa]',obj.FLUID, num2str(obj.PRESSURE(idx))) ...
                );
            propplot('T','Fluid temperature [K]',{'TSAT'})
            propplot('RHOL','Liquid density [kg/m^3]',{'RHOF','RHOG'})
            propplot('RHOV','Vapor density [kg/m^3]',{'RHOF','RHOG'})
            propplot('MUL','Liquid dynamic viscosity [Pa.s]',{'MUF','MUG'})
            propplot('MUV','Vapor dynamic viscosity [Pa.s]',{'MUF','MUG'})


            function propplot(prop,plotLabelY,satPropertyName)

                nexttile; hold all; grid on;
                % Plot enthalpy vs. prop
                plot(H,obj.(prop)(H,idx),'.-')
                % Plot each satProperty
                for i = 1:length(satPropertyName)
                    satProperty = obj.(satPropertyName{i});
                    plot(xlim,repmat(satProperty(idx),1,2),'k--');
                end
                xlabel('Enthalpy [J/kg]'); xlim([min(H) max(H)]);
                ylabel(plotLabelY)
                set(gca,'fontSize',14)
            
            end
            
        end

    end

end

