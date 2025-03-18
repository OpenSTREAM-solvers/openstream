classdef (Abstract) AbstractFilm < Solvers.AbstractField
    %ABSTRACTFILM Summary of this class goes here
    %
    %   Detailed explanation goes here

    properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})
        
        DZ           (1,1) double  {mustBeNumeric}                         =0      % [m] Axial step size
        inputSet                   {isa(inputSet,'Inputs.InputSet')}
        fluid                      {isa(fluid,'Inputs.FluidProperties')}
        mix          (1,1)        {isa(mix, 'Solvers.Mixture.Mixture')}    = NaN
    end
   

    methods
        
        function absfilm = AbstractFilm(inputSet, fluid)
            %ABSFILM Creates an abstract film, absfilm
            %
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                absfilm.inputSet = inputSet;
                absfilm.fluid  = fluid;
            end

            % Overload copyable properties
            %mix.flowProperties = {'W','U','H'};
        end
        
        function wl = WL(absfilm,zIdx)
        %WL Film mass flow rate per unit perimeter
        %    
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            perim  = absfilm.inputSet.geometry.PERIM;
            
            wl = absfilm.W(zIdx,:)./perim;                                 % [kg/s/m] Film mass flow rate per unit perimeter
        end
        
        function thick = THICK(absfilm,zIdx)
        %THICK Film thickness
        %
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            rhof  = absfilm.fluid.RHOF;                                    % [kg/m^3] Saturated liquid density
            
            thick = absfilm.WL(zIdx)./absfilm.U(zIdx,:)./rhof;             % [m] Film thickness
        end

        function re = RE(absfilm,zIdx)
        %RE Film Reynolds number [-]
        %
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            muf   = absfilm.fluid.MUF;                                     % [kg/m^3] Saturated liquid viscosity
            
            re = abs(4.*absfilm.WL(zIdx)./muf);                            % [-] Film Reynolds number
        end
        
        function ment = MENT(absfilm,zIdx)
        %MENT Film entrainment mass flux
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            model = absfilm.inputSet.model;
            vapor = absfilm.mix.vapor;
            rhof  = absfilm.fluid.RHOF;                                    % [kg/m^3] Saturated liquid density
            rhog  = absfilm.fluid.RHOG;                                    % [kg/m^3] Saturated vapor density
            muf   = absfilm.fluid.MUF;                                     % [kg/m^3] Saturated liquid viscosity
            mug   = absfilm.fluid.MUG;                                     % [kg/m^3] Saturated vapor viscosity
            sig   = absfilm.fluid.SIGMA;                                   % [N/m] Surface tension
            hdiam = absfilm.inputSet.geometry.HDIAM;                       % [m] Hydraulic diameter
            area  = absfilm.inputSet.geometry.AREA;                        % [m^2] Coolant area
            perim = absfilm.inputSet.geometry.PERIM;                       % [m^2] Coolant area
            
            Wf = absfilm.W(zIdx,:);
            negfilm = find(Wf<0);
            Wf = abs(Wf);
            
            switch model.ENTRAINMENT
                case InputEnums.ENTRAINMENT.NONE
                    % Suppress film entrainment
                    ment = zeros(length(zIdx),1);
                case InputEnums.ENTRAINMENT.GOVAN
                    % Govan & Hewitt film entrainment model
                    k = 5.75e-5; n1 = 0.316; n2 = 0.632;                   % Model constants
                    Wfc = muf.*exp(5.8504+0.4249*mug/muf*sqrt(rhof/rhog)).*perim./4; % [kg/s] Critical film flow rate
                    ment = k*((Wf./perim-Wfc./perim).^2*16/(rhof*sig*hdiam)).^n1.*(rhof/rhog)^n2.*vapor.W(zIdx)./area; % [kg/m^2/s] Entrainment mass flux
                    ment(Wf<=Wfc) = 0;                                     % Set to 0 below critical film flowrate
                case InputEnums.ENTRAINMENT.OKAWA2003
                    % Okawa et al. 2003 film entrainment model
                    ke = 4.79E-4; n  = 0.111; Refc = 320;                  % Model constants
                    %ke = 3.50E-4;   % RISO TS20
                    %ke = 15E-4;     % RISO TS17/26L
                    slip = ones(size(Wf)); err=1;                          % [-, -] Set initial guess and error for delta search

                    % Wall friction factor (model consistent with entrainment correlation derivation)
                    Cw = absfilm.CW_LAM_CALC(zIdx, 0.005);                 % [-] Wall friction factor, C=0.005
                    
                    % Film thickness (model consistent with entrainment correlation derivation)
                    %delta0 = Wf./film.UEQUILS(mix,zIdx)./perim./rhof;      % Could use this simpler option instead if VAPORFRIC=WALLISTHICK could be selected specifically for this calculation
                    for it = 1:100
                        delta = (rhog/rhof).*slip.*Wf./max(1e-10,vapor.W(zIdx)).*area./perim;  % [m] Film thicknesse(s)
                        Cv = absfilm.CV_WALLISTHICK_CALC(delta, 0.005);    % [-] Interfacial friction factor, thick=delta, C=0.005
                        newslip = sqrt(Cw./Cv.*(rhof/rhog));               % [-] Slip formulation
                        err = max(abs((newslip)./(slip)-1));               % [-] Error
                        slip = newslip;                                    % [-] Update slip
                        if err < 0.01; break
                        end
                    end
                    if err > 0.01
                        disp('Okawa correlation : not converged')
                    end
                    
                    entnum = Cv.*rhog.*absfilm.mix.JG(zIdx).^2.*delta./sig; % [-] Entrainment number
                    ment = (ke*rhof).*entnum.*(rhof/rhog)^n;               % [kg/m^2/s] Entrainment mass flux
                    
                    %ment(absfilm.RE(zIdx)<=Refc) = 0;                      % Set to 0 below critical film Reynolds
                    deltaRe = 100;                                         % [-] Set a Re window size across critical film Reynolds
                    mult = min(1,max(0,(absfilm.RE(zIdx)-(Refc-deltaRe/2))./deltaRe)); % Set to 0 (linearly across Re window to avoid potential non-convergence)
                    ment = mult.*ment;
            end
            
            ment(negfilm)=-ment(negfilm);
            ment = -absfilm.mix.AFDISTR(0,ment,zIdx);                      % [kg/m^2/s] Entrainment mass flux, in annular flow region only

        end
        
        function Mtot = MTOT(absfilm,drop,zIdx)
        %MTOT Total
        %
            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end
            
            %TODO: incorporate mix as a property?
            Mtot  = absfilm.MEVAP(zIdx,:)+absfilm.MENT(zIdx)+drop.MDEP(zIdx);   
        end
        
        function Cw = CW(absfilm,zIdx)
        %CW Wall friction factor
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            model = absfilm.inputSet.model;
            C = 0.005;                                                     % Constant friction factor
            
            switch model.THINFILMFRIC
                case InputEnums.THINFILMFRIC.TURBULENT
                    %
                    Cw = absfilm.CW_TURB_CALC(zIdx, C);                    % Call private method

                case InputEnums.THINFILMFRIC.LAMINAR
                    %
                    Cw = absfilm.CW_LAM_CALC(zIdx, C);                     % Call private method
            end
            
            Cw  = absfilm.mix.AFDISTR(C,Cw,zIdx);
            
        end
        
        function Fwall = FWALL(absfilm,zIdx)
        %FWALL Film wall shear stress
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            Fwall  = -0.5.*absfilm.CW(zIdx).*absfilm.fluid.RHOF.*absfilm.U(zIdx,:).^2; % [N/m^2]
            
        end

        function Uwall = UWALL(absfilm,zIdx)
        %UWALL [m/s] Film wall velocity 
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            rho_ls = absfilm.fluid.RHOF;
            Uwall  = (-absfilm.FWALL(zIdx)./rho_ls).^0.5;                    % [m/s] Wall friction velocity

        end

        function thick = YPLUS2THICK(absfilm, yplus, zIdx)
        %YPLUS2THICK Calculate thickness from wall unit value
        %
            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end

            rho_ls = absfilm.fluid.RHOF;                                    % Saturated liquid mass density
            mu_ls = absfilm.fluid.MUF;                                      % Saturated liquid viscosity
            nu_ls = mu_ls./rho_ls;                                          % Saturated liquid kinematic viscosity
            thick = yplus./absfilm.UWALL(zIdx).*nu_ls;                      % [m] Converted thickness

        end
        
        function Cv = CV(absfilm,zIdx)
        %CV Film/vapor interfacial friction factor
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            model = absfilm.inputSet.model;
            nwall = absfilm.inputSet.geometry.NWALL;                          % Number of walls
            C = model.VAPORFRICCST;                                        % [-] Friction constant
            
            switch model.VAPORFRIC
                case InputEnums.VAPORFRIC.CONSTANT
                    %
                    Cv = repmat(C,length(zIdx),nwall);                     % [-]
                    
                case InputEnums.VAPORFRIC.WALLIS
                    %
                    vf = absfilm.mix.vapor.VF(zIdx);                               % [-]
                    Cv = C.*(1+75.*(1-vf));                                % [-]
                    Cv = repmat(Cv,1,nwall);                               % [-]
                    
                case InputEnums.VAPORFRIC.WALLISTHICK
                    %
                    thick = abs(absfilm.THICK(zIdx));                         % [m] Film thickness
                    Cv = absfilm.CV_WALLISTHICK_CALC(thick,C);                 % Call private method
            end
            
            Cv  = absfilm.mix.AFDISTR(0,Cv,zIdx);   
            
        end
        
        function Fvapor = FVAPOR(absfilm,zIdx)
        %FVAPOR Film vapor shear stress
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            UVAP = absfilm.mix.vapor.U(zIdx);                                      % [m/s] Vapor velocity
            
            Fvapor = 0.5.*absfilm.CV(zIdx).*absfilm.fluid.RHOG.*(UVAP-absfilm.U(zIdx,:)).^2; % [N/m^2]
            
        end
        
        function Fbuoy = FBUOY(absfilm,zIdx)
        %FBUOY Film buoyancy
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            thick = abs(absfilm.THICK(zIdx));                                 % [m] Film thickness
            DPDZ = -absfilm.mix.DP.Tot(zIdx)/absfilm.DZ;                              % [Pa/m] Pressure gradient
            
            Fbuoy = -thick.*(DPDZ);                                        % [N/m^2]
            
            Fbuoy = absfilm.mix.AFDISTR(0,Fbuoy,zIdx);   
            
        end
        
        function Fgrav = FGRAV(absfilm,zIdx)
        %FGRAV Film gravity
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            model = absfilm.inputSet.model;
            thick = abs(absfilm.THICK(zIdx));                                 % [m] Film thickness
            
            Fgrav = -thick.*(model.G*cos(model.ANGLE*pi/180)*absfilm.fluid.RHOF); % [N/m^2]
            
            Fgrav = absfilm.mix.AFDISTR(0,Fgrav,zIdx);

        end
        
        function Fdep = FDEP(absfilm,drop,zIdx)
        %FDEP Drop deposition shear
        %
            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end
            
            dep  = drop.MDEP(zIdx);                                    % [kg/m^2/s] Drop deposition mass flux
            
            Fdep = (drop.U(zIdx)-absfilm.U(zIdx,:)).*dep;                     % [N/m^2]
            
            Fdep = absfilm.mix.AFDISTR(0,Fdep,zIdx);   
            
        end
        
        function Ftot = FTOT(absfilm,drop,zIdx)
        %FTOT Total
        %
            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end
            
            %Ftot  = film.FWALL(zIdx)+film.FVAPOR(zIdx)+film.FBUOY(zIdx)+film.FDEP(drop,zIdx);   
            Ftot  = absfilm.FWALL(zIdx)+absfilm.FVAPOR(zIdx)+absfilm.FBUOY(zIdx)+absfilm.FGRAV(zIdx)+absfilm.FDEP(drop,zIdx);   
            
        end
        
        function Ualgebr = UALGEBR(absfilm,zIdx)
        %UALGEBR Film velocity based on simple algebraic model
        %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            TAUW  = absfilm.mix.TAUW(zIdx);                                        % [Pa] Wall shear stress
            Cw = absfilm.CW(zIdx);
            
            Ualgebr = sqrt((2*TAUW/absfilm.fluid.RHOF)./Cw);                  % [m/s] 
            
            Ualgebr  = absfilm.mix.AFDISTR(absfilm.mix.liquid.U(zIdx),Ualgebr,zIdx);  

        end
        
        function Uequil = UEQUILS(absfilm,zIdx)
            %UEQUILS Film velocity based on simple equilibrium model (Fwall + Fvapor = 0)
            %
            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end
            
            iter(1).U = absfilm.U(zIdx,:);
            iter(1).Ftot = absfilm.FVAPOR(zIdx)+absfilm.FWALL(zIdx);
            
            iter(2).U = iter(1).U+0.1;
            absfilm.U(zIdx,:)=iter(2).U;
            iter(2).Ftot = absfilm.FVAPOR(zIdx)+absfilm.FWALL(zIdx);
            
            eps = 1.0;
            for k = 3:100
                Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot);
                iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;
                absfilm.U(zIdx,:)=iter(k).U;
                iter(k).Ftot = absfilm.FVAPOR(zIdx)+absfilm.FWALL(zIdx);
                err = max(abs(iter(k).Ftot),[],'all');
                if err<1E-3, break; end
            end
            if err > 1E-3
                fprintf('%s UEQUILS model : not converged -> err=%0.4f\n',class(absfilm), err);
            end
            
            Uequil = absfilm.mix.AFDISTR(absfilm.mix.liquid.U(zIdx),absfilm.U(zIdx,:),zIdx);
            
        end
        
        function Uequil = UEQUIL(absfilm,drop,zIdx)
            %UEQUIL Film velocity based on complete equilibrium model (Ftot = 0)
            %
            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end
            
            iter(1).U = absfilm.U(zIdx,:);
            iter(1).Ftot = absfilm.FTOT(drop,zIdx);
            
            iter(2).U = iter(1).U+0.1;
            absfilm.U(zIdx,:)=iter(2).U;
            iter(2).Ftot = absfilm.FTOT(drop,zIdx);
            
            eps = 1.0;
            for k = 3:100
                Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot);
                iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;
                absfilm.U(zIdx,:)=iter(k).U;
                iter(k).Ftot = absfilm.FTOT(drop,zIdx);
                err = max(abs(iter(k).Ftot),[],'all');
                if err<1E-3, break; end
            end
            if err > 1E-3
                fprintf('%s UEQUIL model : not converged -> err=%0.4f\n',class(absfilm), err);
            end
            
            Uequil = absfilm.mix.AFDISTR(absfilm.mix.liquid.U(zIdx),absfilm.U(zIdx,:),zIdx);
            
        end
        
    end

    methods(Access = private)
        
        function Cw = CW_TURB_CALC(film,zIdx,C)
        %CW_TURB_CALC Private method to calculate the turbulent wall
        %friction factor

            nwall = film.inputSet.geometry.NWALL;                  % Number of walls
            Cw = repmat(C,length(zIdx),nwall);                     % [-]

        end

        function Cw = CW_LAM_CALC(film,zIdx,C)
        %CW_LAM_CALC Private method to calculate the laminar wall%friction
        %factor

            RE = max(film.RE(zIdx),1E-6);
            Cw = max(16./RE,C);                                    % [-]
        end

        function Cv = CV_WALLISTHICK_CALC(film, thick, C)
        %CV_WALLISTHICK_CALC Private method to calculate the interfacial
        %shear using the WALLISTHICK model

            area = film.inputSet.geometry.AREA;                    % [m^2] Cross-section area
            perim = film.inputSet.geometry.PERIM;                  % [m]   Perimeter(s)
            Cv = C.*(1+(75/area).*sum(perim.*thick,2));            % [-]

        end
    end

    methods(Access = protected)
    
        function cpObj = copyElement(obj)
        %COPYELEMENT Override copyElement method to create correct references
        %with properties liquid and vapor 

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
           
        end
    end

end

