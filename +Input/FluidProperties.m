classdef FluidProperties < Input.Input
    %FluidProperties Summary of this class goes here
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
        
    end

    properties (SetAccess=private)

        coolpropH   CoolPropWrapper
    
    end
    
    methods
        function obj = FluidProperties(filePath)
            %FLUIDPROPERTIES Construct an instance of this class
            %   Detailed explanation goes here
            
            import CoolPropWrapper.CoolPropWrapper

            % Call superclass constructor to parse file and select
            % specified modelID
            obj = obj@Input.Input(filePath)

            % Setup CoolProp
            obj.coolpropH = CoolPropWrapper();

            

        end
        

    end
end

