classdef Liquid < Solvers.AbstractField
    %LIQUID Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            (:,1) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy

        % Iteration properties
        ITR

        % Mixture
        mix          (1,1)        {isa(mix, 'Solvers.Mixture.Mixture')}   = NaN

     end

     properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
     end
    
     
    
    methods
        function liquid = Liquid(inputSet, fluid)
            %liquid Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin > 0
                % Store inputSet as object property
                liquid.inputSet = inputSet;
                liquid.fluid  = fluid;
            end
        end
        
        function x = X(liquid,zIdx)
        %X Liquid mass fraction
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            x = liquid.W(zIdx)./liquid.mix.W(zIdx);                          % [-]
        end
        
        function t = T(liquid,zIdx)
        %T Liquid temperature
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            P  = liquid.fluid.PRESSURE;
            
            t = liquid.fluid.coolpropH.temperature('P',P,'H',liquid.H(zIdx)); % [K]
        end
        
        function hflux = HFLUX(liquid,zIdx)
        %HFLUX Wall heat flux to liquid phase
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ   = liquid.mix.XEQ;
            HFLUX = liquid.mix.HFLUX;
            
            % Heat flux to liquid phase up to XEQ = 1
            k = [1; diff(min(1,XEQ))./diff(XEQ)];                          % [-] Subcooled / saturation ratio
            hflux = k(zIdx).*HFLUX(zIdx,:);                                % [W/m^2] 
        end
        
        function Mwevap = MWEVAP(liquid,zIdx)
        %MWEVAP Wall evaporation mass flux
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            XEQ = liquid.mix.XEQ;
            HG  = liquid.fluid.HG;
            HF  = liquid.fluid.HF;
            
            % Thermal equilibrium assumption
            k = [0; diff(min(1,max(0,XEQ)))./diff(XEQ)];                   % [-] Saturation ratio
            Mwevap = -k(zIdx).*liquid.HFLUX(zIdx)./(HG-HF);                % [kg/s/m^2]
            
            % Entire heat flux evaporates the liquid
            %Mwevap = -liquid.HFLUX(zIdx)./(HG-HF);                         % [kg/s/m^2]
        end
        
        function Mwall = MWALL(liquid,zIdx)
        %MWALL Wall evaporation mass transfer
        %No condensation considered at the wall
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;
            
            Mwall = sum(PERIM.*liquid.MWEVAP(zIdx),2);                     % [kg/s/m]
        end

        function Mtot = MTOT(liquid,zIdx)
        %MTOT Total mass transfer
        %TODO: add interfacial mass terms later
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            Mtot  = liquid.MWALL(zIdx);                                    % [kg/s/m]
        end
        
        
        
        function Hwhf = HWHF(liquid,zIdx)
        %HWHF wall energy transfer from wall heat flux

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            PERIM = liquid.inputSet.geometry.PERIM;

            Hwhf = sum(PERIM.*liquid.HFLUX(zIdx),2);                      % [W/s/m]
        end
        
        function Hwall = HWALL(liquid,zIdx)
        %HWALL wall energy transfer from mass transfer

            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            HG = liquid.fluid.HG;

            Hwall = liquid.MWALL(zIdx).*(HG-liquid.H(zIdx));               % [W/s/m]
        end
        
        function Htot = HTOT(liquid,zIdx)
        %HTOT Total energy transfer
        %TODO: add interfacial mass terms later
        
            if nargin < 2, zIdx = (1:liquid(1).NZ).'; end
            
            Htot  = liquid.HWHF(zIdx) + liquid.HWALL(zIdx);                % [W/s/m]
        end
        
        
        
        
        
        
        
        
        function out = struct(obj)
        %STRUCT Converter to struct
        % TODO: Should it be in abstractField?
        %
            for i = length(obj):-1:1
                out(i) = struct('TIME', obj(i).TIME, ...
                                'W',   obj(i).W, ...
                                'U',   obj(i).U, ...
                                'H',   obj(i).H, ...
                                'ITR', obj(i).ITR);
            end
        end
        
        function copyFlowProperties(srcObj, targetObj, opts)
        %COPYFLOWPROPERTIES
        % TODO: Should it be in abstractField?
        %
            arguments
                srcObj
                targetObj (1,:) Solvers.TwoFluid.Liquid
                opts.all  (1,1) logical = false
            end

            for i = 1:length(targetObj)
                
                % Make sure obj meshes match
                if srcObj.Z ~= targetObj(1).Z
                    throw( ...
                        MException( ...
                            'LiquidError:copyFlowPropertiesError', ...
                            'Source and target objects have mismatched spatial meshes' ...
                            ) ...
                        );
                end
                
                % Copy properties
                propNames = {'W','U','H'};
                for j = 1:length(propNames)
                    if opts.all
                        targetObj(1).(propNames{j}) = srcObj.(propNames{j});
                    else
                        targetObj(1).(propNames{j})(2:end) = srcObj.(propNames{j})(2:end);
                    end
                end
            end
        end

    end
end

