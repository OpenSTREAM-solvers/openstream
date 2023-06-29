classdef Drop < Solvers.AbstractField
    %DROP Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=?Solvers.AbstractSolver)
        
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

     end

     properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
     end
    
    

    methods
        function drop = Drop(inputSet, fluid)
            %DROP Creates a Drop ?solver? drop
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                drop.inputSet = inputSet;
                drop.fluid  = fluid;
            end

        end
        
        function uslip = USLIP(drop,mix,zIdx)
        % Slip drop velocity model
    
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            
            uslip = model.DROPSLIP.*mix.vapor.U(zIdx);                     % [m/s] Drop velocity
        end

        function ualgebr = UALGEBR(drop,film,mix,zIdx)
        % Algebraic drop velocity model (consistent with mixture model)

            if nargin < 4, zIdx = (1:drop(1).NZ).'; end
            
            perim = drop.inputSet.geometry.PERIM;
            area  = drop.inputSet.geometry.AREA;
            
            Ad = mix.liquid.VF(zIdx).*area-sum(perim.*film.THICK(zIdx),2); % [m^2] Drop cross-section area based on void fraction
            ualgebr = drop.W(zIdx)/drop.fluid.RHOF./Ad;                    % [m/s] Corresponding drop velocity
            ualgebr = mix.AFDISTR(mix.U(zIdx),ualgebr,zIdx);               % [m/s] 
        end
        
        function conc = CONC(drop,mix,zIdx)
        % Drop concentration
        
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            vapor = mix.vapor;
            rhof  = drop.fluid.RHOF;
            rhog  = drop.fluid.RHOG;
            
            Wd = drop.W(zIdx);
            negdrop = find(Wd<0);
            Wd = abs(Wd);
            
            conc = Wd./(Wd./rhof+vapor.W(zIdx)./rhog); % [kg/m^3] Drop concentration
            conc(negdrop) = -conc(negdrop);
        end
        
        function mdep = MDEP(drop,mix,zIdx)
        % Drop deposition mass flux
    
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            rhog  = drop.fluid.RHOG;                                       % [kg/m^3] Saturated vapor density <-!!!To be modified to handle superheated vapor
            sig   = drop.fluid.SIGMA;                                      % [N/m] Surface tension
            hdiam = drop.inputSet.geometry.HDIAM;                          % [m] Hydraulic diameter
            
            conc = abs(drop.CONC(mix,zIdx));                               % [kg/m^3] Drop concentration
            
            Wd = drop.W(zIdx);
            negdrop = find(Wd<0);
            %Wd = abs(Wd);
            
            switch model.DEPOSITION
                case InputEnums.DEPOSITION.GOVAN
                    % Govan & Hewitt drop deposition model
                    if conc/rhog < 0.3
                        mdep = 0.18.*conc./sqrt(rhog*hdiam/sig);            % [kg/m^2/s] Deposition mass flux
                    else
                        mdep = 0.083.*(conc./rhog).^(-0.65).*conc./sqrt(rhog*hdiam/sig); % [kg/m^2/s] Deposition mass flux
                    end
                case InputEnums.DEPOSITION.OKAWA
                    % Okawa drop deposition model
                    kd = 0.0632.*(conc./rhog).^-0.5.*sqrt(sig./(rhog.*hdiam));% [m/s] Deposition mass transfer coefficient
                    mdep = kd.*conc;                                        % [kg/m^2/s] Deposition mass flux
            end
            
            mdep(negdrop)=-mdep(negdrop);
            mdep = mix.AFDISTR(0,mdep,zIdx);                                 % [kg/m^2/s] Deposition mass flux, in annular flow region only
        end

        function re = RE(drop, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            re = 4.*drop.W(zIdx)./drop.MU(zIdx)./sum(drop.inputSet.geometry.PERIM);
        end

        function out = struct(obj)
        %STRUCT Converter to struct
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
        %
            arguments
                srcObj
                targetObj (1,:) Solvers.ThreeField.Drop
                opts.all  (1,1) logical = false
            end

            for i = 1:length(targetObj)
                
                % Make sure obj meshes match
                if srcObj.Z ~= targetObj(1).Z
                    throw( ...
                        MException( ...
                            'DropError:copyFlowPropertiesError', ...
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

    methods(Access = protected)
    

        function cpObj = copyElement(obj)
        %COPYELEMENT Override copyElement method to create correct references
        %with properties liquid and vapor 
            
            import Solvers.ThreeField.*

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
           
        end
    end

end

