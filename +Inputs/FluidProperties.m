classdef FluidProperties
    %FLUIDPROPERTIES Class for managing thermophysical properties of a fluid
    %
    % This class encapsulates saturated and generic fluid properties used in thermal-hydraulic simulations.
    % Saturated properties are computed based on system pressure and stored as class properties.
    % Generic properties (e.g., temperature, density, viscosity) are computed dynamically using enthalpy and pressure.

    properties (SetAccess=immutable)

        FLUID      (1,1) string  {mustBeTextScalar}                        = 'WATER'               % Coolprop fluid identifier
        PROPERTIES (1,1) InputEnums.FLUIDPROPERTIES                        = 'SATURATED'           % Fluid property assumptions from :attr:`Inputs.Model.PROPERTIES`
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
        ALPHAF     (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid thermal diffusivity [m^2/s]
        ALPHAG     (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor thermal diffusivity [m^2/s]
        PRANDTLF   (1,1) double  {mustBeNumeric}                           = 1                     % Saturated liquid Prandtl number [-]
        PRANDTLG   (1,1) double  {mustBeNumeric}                           = 1                     % Saturated vapor Prandtl number [-]
        PCRIT      (1,1) double  {mustBeNumeric}                           = 1                     % Critical pressure [-]
        UC         (1,1) double  {mustBeNumeric}                           = 1                     % Kutateladze critical velocity [m/s]

    end

    properties (SetAccess=private, Hidden)

        TMIN       (1,1) double  {mustBeNumeric}                           = 1                     % Minimum temperature [K]
        HMIN       (1,1) double  {mustBeNumeric}                           = 1                     % Minimum enthalpy [J/kg]
        TMAX       (1,1) double  {mustBeNumeric}                           = 1                     % Maximum temperature [K]
        HMAX       (1,1) double  {mustBeNumeric}                           = 1                     % Maximum enthalpy [J/kg]

        coolpropH   CoolPropWrapper.CoolPropWrapper

    end

    methods
        function obj = FluidProperties(P, modelObj)
            %FLUIDPROPERTIES Constructor for FluidProperties class
            %
            % Initializes fluid properties at given pressure(s) using CoolProp.
            % Saturated properties are computed and assigned to each object instance.
            %
            % Inputs:
            %
            % - P        — Vector of system pressures [Pa]
            % - modelObj — Model object containing fluid name and property assumptions

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
            ALPHAF   = KF./RHOF./CPF;                                      % [m^2/s] Saturated liquid thermal diffusivity
            ALPHAG   = KG./RHOG./CPG;                                      % [m^2/s] Saturated vapor thermal diffusivity
            PRANDTLF = coolpropH.prandtl('P',P,'Q',0);                     % [-] Saturated liquid Prandtl number
            PRANDTLG = coolpropH.prandtl('P',P,'Q',1);                     % [-] Saturated vapor Prandtl number
            coolpropH.setSpecifyPhase('');

            % Critical properties
            PCRIT    = coolpropH.CoolProp.p_critical;                      % [Pa] Critical pressure
            UC       = (SIGMA.*modelObj.G.*(RHOF-RHOG)./RHOG.^2).^0.25;    % [m/s] Kutateladze vapor critical velocity

            % Limiting properties for which CoolProp has valid data for the fluid
            TMIN     = coolpropH.CoolProp.Tmin+1;                          % [K] Minimum temperature
            HMIN     = coolpropH.enthalpy('P',P,'T',TMIN);                 % [J/kg] Minimum enthalpy
            TMAX     = coolpropH.CoolProp.Tmax-1;                          % [K] Maximum temperature
            HMAX     = coolpropH.enthalpy('P',P,'T',TMAX);                 % [J/kg] Maximum enthalpy

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
                obj(i).ALPHAF   = ALPHAF(i);                               % [m^2/s] Saturated liquid thermal diffusivity
                obj(i).ALPHAG   = ALPHAG(i);                               % [m^2/s] Saturated vapor thermal diffusivity
                obj(i).PRANDTLF = PRANDTLF(i);                             % [-] Saturated liquid Prandtl number
                obj(i).PRANDTLG = PRANDTLG(i);                             % [-] Saturated vapor Prandtl number
                obj(i).PCRIT    = PCRIT;                                   % [Pa] Critical pressure
                obj(i).UC       = UC(i);                                   % [m/s] Kutateladze critical velocity
                obj(i).TMIN     = TMIN;                                    % [K] Minimum temperature
                obj(i).HMIN     = HMIN(i);                                 % [J/kg] Minimum enthalpy
                obj(i).TMAX     = TMAX;                                    % [K] Maximum temperature
                obj(i).HMAX     = HMAX(i);                                 % [J/kg] Maximum enthalpy

            end
        end

        function t = T(obj,H)
            %T Fluid temperature at given enthalpy and system pressure [K]
            %
            % Enthalpy is clamped between HMIN and HMAX to ensure valid CoolProp input

            H = min(max(H,obj.HMIN),obj.HMAX);                             % [J/kg]
            t = obj.coolpropH.temperature('P',obj.PRESSURE,'H',H);
        end

        function h = H(obj,T)
            %H Fluid enthalpy at given temperature and system pressure [J/kg]

            h = obj.coolpropH.enthalpy('P',obj.PRESSURE,'T',T);
        end

        function rhol = RHOL(obj,H)
            %RHOL Liquid mass density [kg/m^3]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    rhol = repmat(obj.RHOF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = max(min(H,obj.HF),obj.HMIN);
                    rhol = obj.coolpropH.density('P',obj.PRESSURE,'H',H);
            end
        end

        function rhov = RHOV(obj,H)
            %RHOV Vapor mass density [kg/m^3]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    rhov = repmat(obj.RHOG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = min(max(H,obj.HG),obj.HMAX);                       % [J/kg]
                    rhov = obj.coolpropH.density('P',obj.PRESSURE,'H',H);
            end
        end

        function mul = MUL(obj,H)
            %MUL Liquid dynamic viscosity [Pa.s]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    mul = repmat(obj.MUF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = max(min(H,obj.HF),obj.HMIN);
                    mul = obj.coolpropH.viscosity('P',obj.PRESSURE,'H',H);
            end
        end

        function muv = MUV(obj,H)
            %MUV Vapor dynamic viscosity [Pa.s]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end
            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    muv = repmat(obj.MUG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = min(max(H,obj.HG),obj.HMAX);                       % [J/kg]
                    muv = obj.coolpropH.viscosity('P',obj.PRESSURE,'H',H);
            end
        end

        function kl = KL(obj,H)
            %KL Liquid thermal conductivity [W/m/K]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    kl = repmat(obj.KF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = max(min(H,obj.HF),obj.HMIN);                       % [J/kg]
                    kl = obj.coolpropH.conductivity('P',obj.PRESSURE,'H',H);
            end
        end

        function kv = KV(obj,H)
            %KV Vapor thermal conductivity [W/m/K]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    kv = repmat(obj.KG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = min(max(H,obj.HG),obj.HMAX);                       % [J/kg]
                    kv = obj.coolpropH.conductivity('P',obj.PRESSURE,'H',H);
            end
        end

        function cpl = CPL(obj,H)
            %CPL Liquid constant pressure specific heat [J/kg/K]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    cpl = repmat(obj.CPF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = max(min(H,obj.HF),obj.HMIN);                       % [J/kg]
                    cpl = obj.coolpropH.cp('P',obj.PRESSURE,'H',H);
            end
        end

        function cpv = CPV(obj,H)
            %CPV Vapor constant pressure specific heat [J/kg/K]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    cpv = repmat(obj.CPG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = min(max(H,obj.HG),obj.HMAX);                       % [J/kg]
                    cpv = obj.coolpropH.cp('P',obj.PRESSURE,'H',H);
            end
        end

        function alphal = ALPHAL(obj,H)
            %ALPHAL Liquid thermal diffusivity [m^2/s]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    alphal = repmat(obj.ALPHAF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    alphal = obj.KL(H)./obj.RHOL(H)./obj.CPL(H);
            end
        end

        function alphav = ALPHAV(obj,H)
            %ALPHAV Vapor thermal diffusivity  [m^2/s]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    alphav = repmat(obj.ALPHAG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    alphav = obj.KV(H)./obj.RHOV(H)./obj.CPV(H);
            end
        end

        function prandtll = PRANDTLL(obj,H)
            %PRANDTLL Liquid Prandtl number [-]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    prandtll = repmat(obj.PRANDTLF,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = max(min(H,obj.HF),obj.HMIN);                       % [J/kg]
                    prandtll = obj.coolpropH.prandtl('P',obj.PRESSURE,'H',H);
            end
        end

        function prandtlv = PRANDTLV(obj,H)
            %PRANDTLV Vapor Prandtl number [-]
            %
            % Behavior depends on property assumption model (:attr:`Inputs.Model.PROPERTIES`)

            arguments
                obj
                H
            end

            switch obj.PROPERTIES
                case InputEnums.FLUIDPROPERTIES.SATURATED
                    prandtlv = repmat(obj.PRANDTLG,numel(H),1);
                case InputEnums.FLUIDPROPERTIES.PSYSTEM
                    H = min(max(H,obj.HG),obj.HMAX);                       % [J/kg]
                    prandtlv = obj.coolpropH.prandtl('P',obj.PRESSURE,'H',H);
            end
        end

        function paramData = transient(obj, param, opt)
            %TRANSIENT Generate transient distribution array for parameter param

            arguments
                obj
                param         (1,1) string {mustBeTextScalar}
                opt.tIdx      (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:length(obj)
            end

            paramData = [obj(opt.tIdx).(param)];
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
