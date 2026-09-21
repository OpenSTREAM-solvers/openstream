classdef (Abstract) AbstractFilm < Solvers.AbstractField
    %ABSTRACTFILM Base class for liquid film models in three- and four-field solvers
    %
    % This abstract class defines shared methods and properties for liquid film modeling.
    % It includes calculations for film thickness, entrainment, shear forces, and velocity models.
    % Specific entrainment models (e.g., Okawa, Govan) and friction models are implemented.

    properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})

        DZ           (1,1) double  {mustBeNumeric}                         =0      % Axial step size [m]
        inputSet                   {isa(inputSet,'Inputs.InputSet')}               % :class:`Inputs.InputSet` object containing geometry, model, and boundary conditions
        fluid                      {isa(fluid,'Inputs.FluidProperties')}           % :class:`Inputs.FluidProperties` object containing fluid thermophysical properties
        mix          (1,1)         {isa(mix, 'Solvers.Mixture.Mixture')}   = NaN   % :class:`Solvers.Mixture.Mixture` object of the mixture solver
    end


    methods

        function absfilm = AbstractFilm(inputSet, fluid)
            %AbstractFilm Constructor for AbstractFilm class
            %
            % Initializes :class:`Inputs.InputSet` and :class:`Inputs.FluidProperties`

            if nargin > 0
                % Store inputSet as object property
                absfilm.inputSet = inputSet;
                absfilm.fluid  = fluid;
            end

            % Overload copyable properties
            %mix.flowProperties = {'W','U','H'};
        end

        function wl = WL(absfilm,zIdx)
            %WL Film mass flow rate per unit perimeter [kg/s/m]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            perim  = absfilm.inputSet.geometry.PERIM;                      % [m] Perimeter

            wl = absfilm.W(zIdx,:)./perim;
        end

        function thick = THICK(absfilm,zIdx)
            %THICK Film thickness [m]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            rhof  = absfilm.fluid.RHOF;                                    % [kg/m^3] Saturated liquid density

            thick = absfilm.WL(zIdx)./absfilm.U(zIdx,:)./rhof;
        end

        function re = RE(absfilm,zIdx)
            %RE Film Reynolds number [-]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            muf   = absfilm.fluid.MUF;                                     % [kg/m^3] Saturated liquid viscosity

            re = abs(4.*absfilm.WL(zIdx)./muf);
        end

        function ment = MENT(absfilm,zIdx)
            %MENT Film entrainment mass flux [kg/m^2/s]
            % 
            % Based on selected :attr:`Inputs.Model.ENTRAINMENT` model.

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            model = absfilm.inputSet.model;

            Wf = absfilm.W(zIdx,:);
            negfilm = find(Wf<0);
            Wf = abs(Wf);

            switch model.ENTRAINMENT
                case InputEnums.ENTRAINMENT.NONE
                    % Suppress film entrainment
                    ment = zeros(length(zIdx),1);

                case InputEnums.ENTRAINMENT.GOVAN
                    % Govan & Hewitt film entrainment model
                    vapor = absfilm.mix.vapor;
                    rhof  = absfilm.fluid.RHOF;                            % [kg/m^3] Saturated liquid density
                    rhog  = absfilm.fluid.RHOG;                            % [kg/m^3] Saturated vapor density
                    muf   = absfilm.fluid.MUF;                             % [kg/m^3] Saturated liquid viscosity
                    mug   = absfilm.fluid.MUG;                             % [kg/m^3] Saturated vapor viscosity
                    sig   = absfilm.fluid.SIGMA;                           % [N/m] Surface tension
                    hdiam = absfilm.inputSet.geometry.HDIAM;               % [m] Hydraulic diameter
                    area  = absfilm.inputSet.geometry.AREA;                % [m^2] Coolant area
                    perim = absfilm.inputSet.geometry.PERIM;               % [m^2] Coolant area

                    k = 5.75e-5; n1 = 0.316; n2 = 0.632;                   % Model constants
                    Wfc = muf.*exp(5.8504+0.4249*mug/muf*sqrt(rhof/rhog)).*perim./4; % [kg/s] Critical film flow rate
                    ment = k*((Wf./perim-Wfc./perim).^2*16/(rhof*sig*hdiam)).^n1.*(rhof/rhog)^n2.*vapor.W(zIdx)./area; % [kg/m^2/s] Entrainment mass flux
                    ment(Wf<=Wfc) = 0;                                     % Set to 0 below critical film flowrate

                case InputEnums.ENTRAINMENT.OKAWA2003
                    % Okawa et al. 2003 film entrainment model
                    coefs = [320 0.111 4.79E-4 1];
                    ment  = absfilm.OKAWAMENT(zIdx, coefs);

                case InputEnums.ENTRAINMENT.OKAWA2004
                    % Okawa et al. 2004 film entrainment model
                    coefs = [320 0 0.0310 2.3 0.0675 1.2 0.2950 0.5];
                    ment  = absfilm.OKAWAMENT(zIdx, coefs);

                case InputEnums.ENTRAINMENT.OKAWA2004MOD
                    % Modified Okawa et al. (2004) from Adamsson and Le Corre (2011)
                    coefs = [320 0 0.0310 2.3 0.0675 1.2];
                    ment  = absfilm.OKAWAMENT(zIdx, coefs);

                case InputEnums.ENTRAINMENT.OKAWAGEN
                    % Generic Okawa model
                    coefs = model.OKAWACOEFS;
                    ment  = absfilm.OKAWAMENT(zIdx, coefs);
            end

            ment(negfilm)=-ment(negfilm);
            ment = -absfilm.mix.AFDISTR(0,ment,zIdx);                      % [kg/m^2/s] Entrainment mass flux, in annular flow region only
        end

        function Mtot = MTOT(absfilm,drop,zIdx)
            %MTOT Total film mass transfer [kg/m^2/s]

            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end

            Mtot  = absfilm.MEVAP(zIdx,:)+absfilm.MENT(zIdx)+drop.MDEP(zIdx);
        end

        function Cw = CW(absfilm,zIdx)
            %CW Film wall friction factor [-]
            %
            % Based on selected :attr:`Inputs.Model.THINFILMFRIC` model.

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
            %FWALL Film wall shear stress [N/m^2]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            Fwall  = -0.5.*absfilm.CW(zIdx).*absfilm.fluid.RHOF.*absfilm.U(zIdx,:).^2;
        end

        function Uwall = UWALL(absfilm,zIdx)
            %UWALL Film wall friction velocity [m/s]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            rho_ls = absfilm.fluid.RHOF;                                   % [kg/m^3] Saturated liquid density

            Uwall  = (-absfilm.FWALL(zIdx)./rho_ls).^0.5;
        end

        function thick = YPLUS2THICK(absfilm, yplus, zIdx)
            %YPLUS2THICK Thickness based on wall unit value [m]

            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end

            rho_ls = absfilm.fluid.RHOF;                                   % Saturated liquid mass density
            mu_ls = absfilm.fluid.MUF;                                     % Saturated liquid viscosity
            nu_ls = mu_ls./rho_ls;                                         % Saturated liquid kinematic viscosity

            thick = yplus./absfilm.UWALL(zIdx).*nu_ls;                     % Converted thickness [m]
        end

        function Cv = CV(absfilm,zIdx)
            %CV Film/vapor interfacial friction factor [-]
            %
            % Based on selected :attr:`Inputs.Model.VAPORFRIC` model.

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            model = absfilm.inputSet.model;
            nwall = absfilm.inputSet.geometry.NWALL;                       % Number of walls
            C = model.VAPORFRICCST;                                        % [-] Friction constant

            switch model.VAPORFRIC
                case InputEnums.VAPORFRIC.CONSTANT
                    %
                    Cv = repmat(C,length(zIdx),nwall);                     % [-]

                case InputEnums.VAPORFRIC.WALLIS
                    %
                    vf = absfilm.mix.vapor.VF(zIdx);                       % [-]
                    Cv = C.*(1+75.*(1-vf));                                % [-]
                    Cv = repmat(Cv,1,nwall);                               % [-]

                case InputEnums.VAPORFRIC.WALLISTHICK
                    %
                    thick = abs(absfilm.THICK(zIdx));                      % [m] Film thickness
                    Cv = absfilm.CV_WALLISTHICK_CALC(thick,C);             % Call private method
            end

            Cv  = absfilm.mix.AFDISTR(0,Cv,zIdx);                          % [-]
        end

        function Fvapor = FVAPOR(absfilm,zIdx)
            %FVAPOR Vapor shear stress on film [N/m^2]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            UVAP = absfilm.mix.vapor.U(zIdx);                              % [m/s] Vapor velocity

            Fvapor = 0.5.*absfilm.CV(zIdx).*absfilm.fluid.RHOG.*(UVAP-absfilm.U(zIdx,:)).^2; % [N/m^2]
        end

        function Fbuoy = FBUOY(absfilm,zIdx)
            %FBUOY Film buoyancy force [N/m^2]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            thick = abs(absfilm.THICK(zIdx));                              % [m] Film thickness
            DPDZ = absfilm.mix.DP.Tot(zIdx)/absfilm.DZ;                    % [Pa/m] Pressure gradient

            Fbuoy = thick.*(DPDZ);                                         % [N/m^2]

            Fbuoy = absfilm.mix.AFDISTR(0,Fbuoy,zIdx);
        end

        function Fgrav = FGRAV(absfilm,zIdx)
            %FGRAV Gravitational force on film [N/m^2]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            geom = absfilm.inputSet.geometry;
            model = absfilm.inputSet.model;
            thick = abs(absfilm.THICK(zIdx));                              % [m] Film thickness

            Fgrav = -thick.*(model.G*cos(geom.ANGLE*pi/180)*absfilm.fluid.RHOF); % [N/m^2]

            Fgrav = absfilm.mix.AFDISTR(0,Fgrav,zIdx);
        end

        function Fdep = FDEP(absfilm,drop,zIdx)
            %FDEP Drop deposition shear force [N/m^2]

            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end

            dep  = drop.MDEP(zIdx);                                        % [kg/m^2/s] Drop deposition mass flux

            Fdep = (drop.U(zIdx)-absfilm.U(zIdx,:)).*dep;                  % [N/m^2]

            Fdep = absfilm.mix.AFDISTR(0,Fdep,zIdx);
        end

        function Ftot = FTOT(absfilm,drop,zIdx)
            %FTOT Total film forces per unit wall area [N/m^2]

            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end

            Ftot  = absfilm.FWALL(zIdx)+absfilm.FVAPOR(zIdx)+absfilm.FBUOY(zIdx)+absfilm.FGRAV(zIdx)+absfilm.FDEP(drop,zIdx);  % [N/m^2]
        end

        function Ualgebr = UALGEBR(absfilm,zIdx)
            %UALGEBR Film velocity using simple algebraic model [m/s]
            %
            % From :cite:t:`ADAMSSON2014316` (eq. 21 or 23).

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            TAUW  = absfilm.mix.TAUW(zIdx);                                % [Pa] Wall shear stress
            Cw = absfilm.CW(zIdx);

            Ualgebr = sqrt((2*TAUW/absfilm.fluid.RHOF)./Cw);               % [m/s]

            Ualgebr  = absfilm.mix.AFDISTR(absfilm.mix.liquid.U(zIdx),Ualgebr,zIdx);
        end

        function Uequil = UEQUILS(absfilm,zIdx)
            %UEQUILS Film velocity assuming equilibrium between wall and vapor
            % shear  [m/s]

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            options = absfilm.inputSet.options;

            iter(1).U = absfilm.U(zIdx,:);
            iter(1).Ftot = absfilm.FVAPOR(zIdx)+absfilm.FWALL(zIdx);

            iter(2).U = iter(1).U+0.1;
            absfilm.U(zIdx,:)=iter(2).U;
            iter(2).Ftot = absfilm.FVAPOR(zIdx)+absfilm.FWALL(zIdx);

            eps = 1.0;
            for k = 3:options.UFEQUILMAXITER
                Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot);
                iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;
                absfilm.U(zIdx,:)=iter(k).U;
                iter(k).Ftot = absfilm.FVAPOR(zIdx)+absfilm.FWALL(zIdx);
                err = max(abs(iter(k).Ftot),[],'all');
                if err < options.UFEQUILTOL, break; end
            end
            if err > options.UFEQUILTOL
                fprintf('%s UEQUILS model : not converged -> err=%0.4f\n',class(absfilm), err);
            end

            Uequil = absfilm.mix.AFDISTR(absfilm.mix.liquid.U(zIdx),absfilm.U(zIdx,:),zIdx);
        end

        function Uequil = UEQUIL(absfilm,drop,zIdx)
            %UEQUIL Film velocity using full force equilibrium model [m/s]

            if nargin < 3, zIdx = (1:absfilm(1).NZ).'; end

            options = absfilm.inputSet.options;

            iter(1).U = absfilm.U(zIdx,:);
            iter(1).Ftot = absfilm.FTOT(drop,zIdx);

            iter(2).U = iter(1).U+0.1;
            absfilm.U(zIdx,:)=iter(2).U;
            iter(2).Ftot = absfilm.FTOT(drop,zIdx);

            eps = 1.0;
            for k = 3:options.UFEQUILMAXITER
                Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot);
                iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;
                absfilm.U(zIdx,:)=iter(k).U;
                iter(k).Ftot = absfilm.FTOT(drop,zIdx);
                err = max(abs(iter(k).Ftot),[],'all');
                if err < options.UFEQUILTOL, break; end
            end
            if err > options.UFEQUILTOL
                fprintf('%s UEQUIL model : not converged -> err=%0.4f\n',class(absfilm), err);
            end

            Uequil = absfilm.mix.AFDISTR(absfilm.mix.liquid.U(zIdx),absfilm.U(zIdx,:),zIdx);
        end

        function X = X(absfilm,zIdx)
            %X Vapor quality in the near-wall region [-]
            %
            % Vapor quality in the near-wall region, considering only the
            % film for the liquid phase. The near-wall region is defined in
            % the mixture solver.
            %
            % Inputs:
            %
            % - absfilm  — :class:`Solvers.AbstractFilm` object
            % - zIdx    — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:absfilm(1).NZ).'; end

            X = 1-absfilm.W(zIdx,:)./absfilm.mix.NEARWALL.W(zIdx,:);
        end

    end

    methods(Access = private)

        function Cw = CW_TURB_CALC(absfilm,zIdx,C)
            %CW_TURB_CALC Private method to calculate the turbulent wall
            % friction factor [-]

            nwall = absfilm.inputSet.geometry.NWALL;                       % Number of walls
            Cw = repmat(C,length(zIdx),nwall);                             % [-]
        end

        function Cw = CW_LAM_CALC(absfilm,zIdx,C)
            %CW_LAM_CALC Private method to calculate the laminar wall
            % friction factor [-]

            RE = max(absfilm.RE(zIdx),1E-6);
            Cw = max(16./RE,C);                                            % [-]
        end

        function Cv = CV_WALLISTHICK_CALC(absfilm, thick, C)
            %CV_WALLISTHICK_CALC Private method to calculate the interfacial
            % shear factor [-]
            % 
            % Based on the :attr:`Inputs.Model.VAPORFRIC` = `WALLISTHICK` model.

            area = absfilm.inputSet.geometry.AREA;                         % [m^2] Cross-section area
            perim = absfilm.inputSet.geometry.PERIM;                       % [m]   Perimeter(s)
            Cv = C.*(1+(75/area).*sum(perim.*thick,2));                    % [-]
        end

        function entnum = ENTNUM(absfilm, zIdx)
            %ENTNUM Private method to calculate the entrainment number [-]
            %
            % Based on Okawa model assumptions.

            options = absfilm.inputSet.options;

            vapor = absfilm.mix.vapor;
            rhof  = absfilm.fluid.RHOF;                                    % [kg/m^3] Saturated liquid density
            rhog  = absfilm.fluid.RHOG;                                    % [kg/m^3] Saturated vapor density
            sig   = absfilm.fluid.SIGMA;                                   % [N/m] Surface tension
            area  = absfilm.inputSet.geometry.AREA;                        % [m^2] Coolant area
            perim = absfilm.inputSet.geometry.PERIM;                       % [m^2] Coolant area

            Wf = abs(absfilm.W(zIdx,:));

            % Wall friction factor (model consistent with entrainment correlation derivation)
            Cw = absfilm.CW_LAM_CALC(zIdx, 0.005);                         % [-] Wall friction factor, C=0.005

            % Film thickness (model consistent with entrainment correlation derivation)
            %delta0 = Wf./film.UEQUILS(mix,zIdx)./perim./rhof;              % Could use this simpler option instead if VAPORFRIC=WALLISTHICK could be selected specifically for this calculation
            slip = ones(size(Wf)); err=1;                                  % [-, -] Set initial guess and error for delta search
            for it = 1:options.ENTNUMMAXITER
                delta = (rhog/rhof).*slip.*Wf./max(1e-10,vapor.W(zIdx)).*area./perim; % [m] Film thickness(es)
                Cv = absfilm.CV_WALLISTHICK_CALC(delta, 0.005);            % [-] Interfacial friction factor, thick=delta, C=0.005
                newslip = sqrt(Cw./Cv.*(rhof/rhog));                       % [-] Slip formulation
                err = max(abs((newslip)./(slip)-1));                       % [-] Error
                slip = newslip;                                            % [-] Update slip
                if err < options.ENTNUMTOL; break
                end
            end
            if err > options.ENTNUMTOL
                disp('Okawa correlation : not converged')
                absfilm.log('\nEntrainment number not converged at node %d after %d iterations. \nSlip residual = %g.\n',zIdx,it,err);
            end

            entnum = Cv.*rhog.*absfilm.mix.JG(zIdx).^2.*delta./sig;        % [-] Entrainment number
        end

        function ment = OKAWAMENT(absfilm, zIdx, coefs)
            %OKAWAMENT Private method to calculate the entrainment mass flux [kg/m^2/s]
            %
            % Based on Okawa models.

            rhof   = absfilm.fluid.RHOF;                                   % [kg/m^3] Saturated liquid density
            rhog   = absfilm.fluid.RHOG;                                   % [kg/m^3] Saturated vapor density
            entnum = absfilm.ENTNUM(zIdx);                                 % [-] Entrainment number

            Refc = coefs(1); n = coefs(2);
            [ke, n2] = absfilm.OKAWACOEFS(entnum, coefs);

            ment = ke.*rhof.*entnum.^n2.*(rhof/rhog).^n;                   % [kg/m^2/s] Entrainment mass flux

            %ment(film.RE(zIdx)<=Refc) = 0;                                 % Set to 0 below critical film Reynolds
            deltaRe = 100;                                                 % [-] Set a Re window size across critical film Reynolds
            mult = min(1,max(0,(absfilm.RE(zIdx)-(Refc-deltaRe/2))./deltaRe)); % Set to 0 (linearly across Re window to avoid potential non-convergence)
            ment = mult.*ment;
        end

        function [ke, n2] = OKAWACOEFS(absfilm, entnum, coefs)
            %OKAWACOEFS Private method to determine the coefficients used in
            % :attr:`Inputs.Model.ENTRAINMENT` = `OKAWA` entrainment models
            % 
            % Based on the calculated entrainment number

            n2array = coefs(4:2:end);
            entbp = coefs(5:2:end);

            for k = 1:numel(entnum)
                kearray = coefs(3);
                for i = find(entbp-entnum(k)<=0)
                    kearray(i+1) = kearray(i)*entbp(i)^n2array(i)/entbp(i)^n2array(i+1);
                end
                ke(k) = kearray(end);
                n2(k) = n2array(length(kearray));
            end
            ke = reshape(ke,size(entnum)); n2 = reshape(n2,size(entnum));
        end

    end

    methods(Access = protected)

        function cpObj = copyElement(obj)
            %COPYELEMENT Override copyElement method to ensure correct references
            %with properties liquid and vapor during object copying

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
        end

    end

end