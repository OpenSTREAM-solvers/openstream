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
        
        function conc = CONC(drop,mix,zIdx)
        % Drop concentration
        
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            vapor = mix.vapor;
            rhof  = drop.fluid.RHOF;
            rhog  = drop.fluid.RHOG;
            
            Wd = drop.W(zIdx);
            negdrop = find(Wd<0);
            Wd = abs(Wd);
            
            conc = Wd./(Wd./rhof+vapor.W(zIdx)./rhog);                     % [kg/m^3] Drop concentration
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
                        mdep = 0.18.*conc./sqrt(rhog*hdiam/sig);           % [kg/m^2/s] Deposition mass flux
                    else
                        mdep = 0.083.*(conc./rhog).^(-0.65).*conc./sqrt(rhog*hdiam/sig); % [kg/m^2/s] Deposition mass flux
                    end
                case InputEnums.DEPOSITION.OKAWA
                    % Okawa drop deposition model
                    kd = 0.0632.*(conc./rhog).^-0.5.*sqrt(sig./(rhog.*hdiam));% [m/s] Deposition mass transfer coefficient
                    mdep = kd.*conc;                                       % [kg/m^2/s] Deposition mass flux
            end
            
            mdep(negdrop)=-mdep(negdrop);
            mdep = mix.AFDISTR(0,mdep,zIdx);                               % [kg/m^2/s] Deposition mass flux, in annular flow region only
        end

        function re = RE(drop, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            perim = drop.inputSet.geometry.PERIM;                          % [m] Perimeter
            
            re = 4.*drop.W(zIdx)./drop.MU(zIdx)./sum(perim);               % [-]
        end
        
        function diam = DIAM(drop,zIdx)
        %DIAM drop diameter
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            
            diam = repmat(model.DROPDIAM,length(zIdx),1);                  % [m]
        end
        
        function area = AREA(drop,zIdx)
        %AREA drop interfacial area
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            area = pi.*drop.DIAM(zIdx).^2;                                 % [m^2]
        end
        
        function volume = VOLUME(drop,zIdx)
        %VOLUME drop volume
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            volume = (pi/6).*drop.DIAM(zIdx).^3;                           % [m^3]
        end
        
        function density = DENSITY(drop,zIdx)
        %DENSITY drop number density
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            area  = drop.inputSet.geometry.AREA;                           % [m^2] Cross-section area
            rhof  = drop.fluid.RHOF;                                       % [kg/m^3] Liquid density
            
            density = drop.W(zIdx)./drop.U(zIdx)./drop.VOLUME(zIdx)./rhof./area;  % [m^-3]
        end
        
        function ai = AI(drop,zIdx)
        %AI drop volumetric interfacial area
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            ai = drop.DENSITY(zIdx).*drop.AREA(zIdx);                      % [m^-1]
        end
        
        function drag = DRAG(drop,zIdx)
        %DRAG drop drag coefficient
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            
            switch model.DROPDRAG
                case InputEnums.DROPDRAG.CONSTANT
                    % Constant drag model
                    drag = repmat(model.DROPDRAGCOEF,length(zIdx),1);      % [-]
            end
        end
        
        function Fbuoy = FBUOY(drop,mix,zIdx)
        %FBUOY Drop buoyancy
        %
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            DPDZ = -mix.DP.Tot(zIdx)/drop.DZ;                              % [Pa/m] Pressure gradient
            
            Fbuoy = -DPDZ;                                                 % [N/m^3]
            
            Fbuoy = mix.AFDISTR(0,Fbuoy,zIdx);   
        end
        
        function Fgrav = FGRAV(drop,mix,zIdx)
        %FGRAV Drop gravity
        %
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            rhof = drop.fluid.RHOF;                                        % [kg/m^3] Liquid density
            
            Fgrav = -model.G*cos(model.ANGLE*pi/180)*rhof;                 % [N/m^3]
            
            Fgrav = mix.AFDISTR(0,Fgrav,zIdx);

        end   
        
        function Fdrag = FDRAG(drop,mix,zIdx)
        %FVAPOR drop vapor drag
        %
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            UVAP = mix.vapor.U(zIdx);                                      % [m/s] Vapor velocity
            rhog = drop.fluid.RHOG;                                        % [kg/m^3] Vapor density
            
            sgn = sign(UVAP-drop.U(zIdx));
            tau = sgn.*0.5.*drop.DRAG(zIdx).*rhog.*(abs(UVAP-drop.U(zIdx))).^2; % [N/m^2]
            
            Fdrag = drop.AREA(zIdx)./drop.VOLUME(zIdx).*tau;               % [N/m^3]
            
            Fdrag = mix.AFDISTR(0,Fdrag,zIdx);
        end
        
        function Fent = FENT(drop,mix,film,zIdx)
        %FENT Film entrainment shear
        %
            if nargin < 4, zIdx = (1:drop(1).NZ).'; end
            
            perim = drop.inputSet.geometry.PERIM;                          % [m] Perimeter(s)
            ent   = -film.MENT(mix,zIdx);                                  % [kg/m^2/s] Film entrainment mass flux
            rhof = drop.fluid.RHOF;                                        % [kg/m^3] Liquid density
            
            Fent = sum(perim.*(film.U(zIdx,:)-drop.U(zIdx)).*ent,2).*rhof.*drop.U(zIdx)./drop.W(zIdx); % [N/m^3]
            
            Fent = mix.AFDISTR(0,Fent,zIdx);   
        end
        
        function Ftot = FTOT(drop,mix,film,zIdx,opt)
        %FTOT Total
        %
            if nargin < 4, zIdx = (1:drop(1).NZ).'; end
            if nargin < 5, opt = 0; end                                    % Option for complete of simplified force balance
            
            if opt == 1
                Ftot  = drop.FDRAG(mix,zIdx)+drop.FBUOY(mix,zIdx)+drop.FGRAV(mix,zIdx); % [N/m^3] Fdrag + Fbuoy only
            else
                Ftot  = drop.FDRAG(mix,zIdx)+drop.FBUOY(mix,zIdx)+drop.FGRAV(mix,zIdx)+drop.FENT(mix,film,zIdx); % [N/m^3] Complete sum of forces
            end
        end
        
        function uslip = USLIP(drop,mix,zIdx)
        % Slip drop velocity model
    
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            
            uslip = model.DROPSLIP.*mix.vapor.U(zIdx);                     % [m/s] Drop velocity
            
            uslip = mix.AFDISTR(mix.liquid.U(zIdx),uslip,zIdx);            % [m/s] 
        end
        
        function ualgebr = UALGEBR(drop,film,mix,zIdx)
        % Algebraic drop velocity model (consistent with mixture model)

            if nargin < 4, zIdx = (1:drop(1).NZ).'; end
            
            perim = drop.inputSet.geometry.PERIM;
            area  = drop.inputSet.geometry.AREA;
            
            Ad = mix.liquid.VF(zIdx).*area-sum(perim.*film.THICK(zIdx),2); % [m^2] Drop cross-section area based on void fraction
            ualgebr = drop.W(zIdx)/drop.fluid.RHOF./Ad;                    % [m/s] Corresponding drop velocity
            
            ualgebr = mix.AFDISTR(mix.liquid.U(zIdx),ualgebr,zIdx);        % [m/s] 
        end
        
        function Uequil = UEQUIL(drop,mix,film,zIdx,opt)
        %UEQUIL Drop velocity based on equilibrium model (Ftot = 0)
        %
            if nargin < 4, zIdx = (1:drop(1).NZ).'; end
            if nargin < 5, opt = 0; end                                    % Option for complete or simplified force balance
            
            iter(1).U = drop.U(zIdx);
            iter(1).Ftot = drop.FTOT(mix,film,zIdx,opt);
            
            iter(2).U = iter(1).U+0.1;
            drop.U(zIdx) = iter(2).U;
            iter(2).Ftot = drop.FTOT(mix,film,zIdx,opt);
            
            eps = 1.0;
            for k = 3:100
                Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot);
                iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;
                drop.U(zIdx) = iter(k).U;
                iter(k).Ftot = drop.FTOT(mix,film,zIdx,opt);
                err = max(abs(iter(k).Ftot),[],'all');
                if err<1E-3, break; end
            end
            if err > 1E-3, disp('Drop UEQUIL model : not converged')
            end
            
            Uequil = mix.AFDISTR(mix.liquid.U(zIdx),drop.U(zIdx),zIdx);
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

