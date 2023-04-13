classdef Film < matlab.mixin.Copyable
    %FILM Summary of this class goes here
    %   Detailed explanation goes here
    
     properties %(SetAccess=?Solvers.ThreeField.ThreeFieldSolver)
        
        % Solver properties

        NZ           (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of time steps
        TIME         (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time step size
        TIDX         (1,1) double  {mustBeNumeric}                         = 1                    % [-] Time step index
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Film heat flux
        MEVAP        (:,:) double  {mustBeNumeric,mustBeNonpositive}       =-1.                   % [kg/s/m^2] Evaporation mass flux
        
        % Flow properties
        W            (:,:) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            (:,:) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            (:,:) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        
        % Iteration properties
        ITR          (1,1) struct 

     end

     properties (SetAccess=?Solvers.ThreeField.ThreeFieldSolver, GetAccess=?Solvers.AbstractPhase)
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
     end
    
    

    methods
        function film = Film(inputSet, fluid)
            %FILM Creates a Film ?solver? film
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                film.inputSet = inputSet;
                film.fluid  = fluid;
            end
        end
        
        function wl = WL(film,zIdx)
        % Film mass flow rate per unit perimeter
        %    
            if nargin < 2, zIdx = 1:film.NZ; end
            
            perim  = film.inputSet.geometry.PERIM;
            
            wl = film.W(zIdx,:)./perim;                                    % [kg/s/m] Film mass flow rate per unit perimeter
        end
        
        function thick = THICK(film,zIdx)
        % Film thickness
        %    
            if nargin < 2, zIdx = 1:film.NZ; end
            
            rhof  = film.fluid.RHOF;                                       % [kg/m^3] Saturated liquid density
            
            thick = film.WL(zIdx)./film.U(zIdx,:)./rhof;                   % [m] Film thickness
        end

        function re = RE(film,zIdx)
        % RE Film Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:film.NZ; end
            
            muf   = film.fluid.MUF;                                        % [kg/m^3] Saturated liquid viscosity
            
            re = abs(4.*film.WL(zIdx)./muf);                               % [-] Film Reynolds number
        end
        
        function ment = MENT(film,mix,zIdx)
        % Film entrainment mass flux
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            model = film.inputSet.model;
            vapor = mix.vapor;
            rhof  = film.fluid.RHOF;                                       % [kg/m^3] Saturated liquid density
            rhog  = film.fluid.RHOG;                                       % [kg/m^3] Saturated vapor density
            muf   = film.fluid.MUF;                                        % [kg/m^3] Saturated liquid viscosity
            mug   = film.fluid.MUG;                                        % [kg/m^3] Saturated vapor viscosity
            sig   = film.fluid.SIGMA;                                      % [N/m] Surface tension
            hdiam = film.inputSet.geometry.HDIAM;                          % [m] Hydraulic diameter
            area  = film.inputSet.geometry.AREA;                           % [m^2] Coolant area
            perim = film.inputSet.geometry.PERIM;                          % [m^2] Coolant area
            
            Wf = film.W(zIdx,:);
            negfilm = find(Wf<0);
            Wf = abs(Wf);
            
            switch model.ENTRAINMENT
                case 'GOVAN'
                    % Govan & Hewitt film entrainment model
                    k = 5.75e-5; n1 = 0.316; n2 = 0.632;                   % Model constants
                    Wfc = muf.*exp(5.8504+0.4249*mug/muf*sqrt(rhof/rhog)).*perim./4; % [kg/s] Critical film flow rate
                    ment = k*((Wf./perim-Wfc./perim).^2*16/(rhof*sig*hdiam)).^n1.*(rhof/rhog)^n2.*vapor.W(zIdx)./area; % [kg/m^2/s] Entrainment mass flux
                    ment(Wf<=Wfc) = 0;                                     % Set to 0 below critical film flowrate
            end
            
            ment(negfilm)=-ment(negfilm);
            ment = -mix.AFDISTR(0,ment,zIdx);                              % [kg/m^2/s] Entrainment mass flux, in annular flow region only
            
        end
        
        function Mtot = MTOT(film,mix,drop,zIdx)
        % Total
        %
            if nargin < 4, zIdx = 1:film(1).NZ; end
            
            Mtot  = film.MEVAP(zIdx,:)+film.MENT(mix,zIdx)+drop.MDEP(mix,zIdx);   
        end
        
        function Cw = CW(film,mix,zIdx)
        % Wall friction factor
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            model = film.inputSet.model;
            C = 0.005;                                                     % Constant friction factor
            
            switch model.THINFILMFRIC
                case "TURBULENT"
                    %
                    nwall = film.inputSet.geometry.NWALL;                  % Number of walls
                    Cw = repmat(C,length(zIdx),nwall);                     % [-]
                case "LAMINAR"
                    %
                    RE = max(film.RE(zIdx),1E-6);
                    Cw = max(16./RE,C);                                    % [-]
            end
            
            Cw  = mix.AFDISTR(0,Cw,zIdx);   
            
        end
        
        function Fwall = FWALL(film,mix,zIdx)
        % Film wall shear stress
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            Fwall  = -0.5.*film.CW(mix,zIdx).*film.fluid.RHOF.*film.U(zIdx,:).^2; % [N/m^2]
            
        end
        
        function Cv = CV(film,mix,zIdx)
        % Film/vapor interfacial friction factor
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            nwall = film.inputSet.geometry.NWALL;                          % Number of walls
            
            Cv = repmat(0.005,length(zIdx),nwall);                          % [-]
            
            Cv  = mix.AFDISTR(0,Cv,zIdx);   
            
        end
        
        function Fvapor = FVAPOR(film,mix,zIdx)
        % Film vapor shear stress
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            UVAP = mix.vapor.U(zIdx);                                      % [m/s] Vapor velocity
            
            Fvapor = 0.5.*film.CV(mix,zIdx).*film.fluid.RHOG.*(UVAP-film.U(zIdx,:)).^2; % [N/m^2]
            
        end
        
        function Fbuoy = FBUOY(film,mix,zIdx)
        % Film buoyancy
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            thick = abs(film.THICK(zIdx));                                 % [m] Film thickness
            DPDZ = -mix.DP.Tot(zIdx)/film.DZ;                              % [Pa/m] Pressure gradient
            
            Fbuoy  = -thick.*(DPDZ);                                       % [N/m^2]
            
            Fbuoy  = mix.AFDISTR(0,Fbuoy,zIdx);   
            
        end
        
        function Fgrav = FGRAV(film,mix,zIdx)
        % Film gravity
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            model = film.inputSet.model;
            thick = abs(film.THICK(zIdx));                                 % [m] Film thickness
            
            Fgrav  = -thick.*(model.G*film.fluid.RHOF);
            
            Fgrav  = mix.AFDISTR(0,Fgrav,zIdx);   
            
        end
        
        function Fdep = FDEP(film,mix,drop,zIdx)
        % Drop deposition shear
        %
            if nargin < 4, zIdx = 1:film(1).NZ; end
            
            dep   = drop.MDEP(mix,zIdx);                                    % [kg/m^2/s] Drop deposition mass flux
            
            Fdep   = (drop.U(zIdx)-film.U(zIdx,:)).*dep;                   % [N/m^2]
            
            Fdep  = mix.AFDISTR(0,Fdep,zIdx);   
        end
        
        function Ftot = FTOT(film,mix,drop,zIdx)
        % Total
        %
            if nargin < 4, zIdx = 1:film(1).NZ; end
            
            %Ftot  = film.FWALL(mix,zIdx)+film.FVAPOR(mix,zIdx);   
            Ftot  = film.FWALL(mix,zIdx)+film.FVAPOR(mix,zIdx)+film.FBUOY(mix,zIdx)+film.FGRAV(mix,zIdx)+film.FDEP(mix,drop,zIdx);   
            
        end
        
        function Ualgebr = UALGEBR(film,mix,zIdx)
        % Film velocity based on simple algebraic model
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            TAUW  = mix.TAUW(zIdx);                                        % [Pa] Wall shear stress
            Cw = film.CW(mix,zIdx);
            
            Ualgebr = sqrt((2*TAUW/film.fluid.RHOF)./Cw);                  % [m/s] 
            
            Ualgebr  = mix.AFDISTR(mix.liquid.U(zIdx),Ualgebr,zIdx);  
            
        end
        
        function Uequil = UEQUILS(film,mix,zIdx)
        % Film velocity based on simple equilibrium model (Fwall + Fvapor = 0)
        %
            if nargin < 3, zIdx = 1:film(1).NZ; end
            
            UVAP = mix.vapor.U(zIdx);                                      % [m/s] Vapor velocity
            Cw = film.CW(mix,zIdx);
            Cv = film.CV(mix,zIdx);
            
            Uequil = UVAP./(1+sqrt(Cw./Cv).*sqrt(film.fluid.RHOF/film.fluid.RHOG)); % [m/s]
            
            Uequil  = mix.AFDISTR(mix.liquid.U(zIdx),Uequil,zIdx);  
        end
        
        function Uequil = UEQUIL(film,mix,drop,zIdx)
        % Film velocity based on complete equilibrium model (Ftot = 0)
        %
        if nargin < 4, zIdx = 1:film(1).NZ; end
        
        iter(1).U = film.U(zIdx,:);
        iter(1).Ftot = film.FTOT(mix,drop,zIdx);
        
        iter(2).U = iter(1).U+0.1;
        film.U(zIdx,:)=iter(2).U;
        iter(2).Ftot = film.FTOT(mix,drop,zIdx);
        
        eps = 1.0;
        for k = 3:20
            Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot);
            iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;
            film.U(zIdx,:)=iter(k).U;
            iter(k).Ftot = film.FTOT(mix,drop,zIdx);
            if max(abs(iter(k).Ftot),[],'all')<1E-3, break; end
        end
        
        Uequil = mix.AFDISTR(mix.liquid.U(zIdx),film.U(zIdx,:),zIdx);
        
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
                targetObj (1,:) Solvers.ThreeField.Film
                opts.all  (1,1) logical = false
            end

            for i = 1:length(targetObj)
                
                % Make sure obj meshes match
                if srcObj.Z ~= targetObj(1).Z
                    throw( ...
                        MException( ...
                            'FilmError:copyFlowPropertiesError', ...
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

