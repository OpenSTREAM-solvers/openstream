classdef Drop < Solvers.AbstractField
    %DROP Class for modeling drop field in three-field solver
    %
    % This class encapsulates the physical and numerical properties of the drop field,
    % including flow variables and phase interactions.
    % It supports multiple solver models and provides methods for computing derived
    % quantities.

    properties (SetAccess={?Solvers.AbstractField,?Solvers.AbstractSolver})

        % Solver properties

        NZ                                                                 = 0                    % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
        NTIME                                                              = 0                    % Number of time steps [-]
        TIME                                                               = 0                    % Time series [s]
        DT                                                                 = 0                    % Time step size [s] from :attr:`Inputs.Options.TSTEP`
        TIDX                                                               = 1                    % Time step index [-]
        Z                                                                  = 1.                   % Elevation [m]

        % Flow properties

        W            (:,1) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        U            (:,1) double  {mustBeNumeric}                         = 1.                   % Velocity [m/s]
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]

        % Iteration properties

        ITR                                                                                       % Iteration tracking

        % Mixture
        
        mix          (1,1)        {isa(mix, 'Solvers.Mixture.Mixture')}    = NaN                  % :class:`Solvers.Mixture.Mixture` object

    end

    properties (Access={?Solvers.AbstractSolver,?Solvers.AbstractPhase, ?Solvers.AbstractField})

        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        fluid                      {isa(fluid,'Inputs.FluidProperties')}                          % :class:`Inputs.FluidProperties` object
    
    end

    methods

        function drop = Drop(inputSet, fluid)
            %DROP Constructor for Drop class
            %
            % Initializes the drop field object with input configuration
            % and fluid properties.
            %
            % Inputs:
            %
            % - inputSet — :class:`Inputs.InputSet` object containing model, geometry, and boundary conditions
            % - fluid    — :class:`Inputs.FluidProperties` object containing thermophysical fluid data
  
            if nargin > 0
                % Store inputSet as object property
                drop.inputSet = inputSet;
                drop.fluid  = fluid;
            end

            % Overload copyable properties
            %mix.flowProperties = {'W','U','H'};
        end

        function conc = CONC(drop,zIdx)
            %CONC Drop concentration [kg/m^3]
            %
            % Calculates the local drop-field concentration based on mass flow
            % and vapor-phase properties.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)
 
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            vapor = drop.mix.vapor;
            rhof  = drop.fluid.RHOF;                                       % [kg/m^3]
            rhog  = drop.fluid.RHOG;                                       % [kg/m^3]

            Wd = drop.W(zIdx);                                             % [kg/s]
            negdrop = find(Wd<0);
            Wd = abs(Wd);                                                  % [kg/s]

            conc = Wd./(Wd./rhof+vapor.W(zIdx)./rhog);                     % [kg/m^3] Drop concentration
            conc(negdrop) = -conc(negdrop);
        end

        function kenh = KENH(drop,zIdx)
            %KENH Drop deposition enhancement factor [-]
            %
            % Calculates axial variation of deposition enhancement using
            % Windecker correlation or other models based on :attr:`Inputs.Model.DEPENHANCEMENT`.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)
 
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            model = drop.inputSet.model;
            kdist = drop.mix.KDIST(zIdx);

            switch model.DEPENHANCEMENT
                case InputEnums.DEPENHANCEMENT.NONE
                    % No drop deposition enhancement
                    kenh = ones(length(zIdx),1);
                case InputEnums.DEPENHANCEMENT.WINDECKER
                    % Windecker drop deposition enhancement model
                    B = 7.898; D = 4.791;                                  % [-] Model coefficients
                    zRef = [0.05 0.15 0.45];                               % [m] Reference locations from upstream spacer

                    % Blockage ratio effect
                    BR = [0 model.KBLOCKRATIO];                            % [-] Blockage ratios of local obstructions (including at inlet)
                    BR = BR(discretize(drop.Z(zIdx),[0 model.KLOC drop.Z(end)])); % [-] Corresponding axial distribution of blockage ratios
                    kenhmax = 0.95.*(D.*BR(:)+1).*(B.*BR(:)+1);            % [-] Corresponding axial distribution of max drop deposition enhancement factor

                    kfunc = @(z,kenhmax) ((kenhmax-1).*z/zRef(1)+1).*(z<=zRef(1)) + ...
                        kenhmax.*(z>zRef(1) & z<=zRef(2)) + ...
                        1./((1-1./kenhmax).*(z-zRef(2))./(zRef(3)-zRef(2))+1./kenhmax).*(z>zRef(2) & z<=zRef(3)) + ...
                        1.*(z>zRef(3));                                    % [-] Piece-wise axial enhancement function

                    kenh = kfunc(kdist,kenhmax);                           % [-] Axial distribution of drop deposition enhancement factor

                    % Empirical multiplier
                    KG = [0 model.KTUNING];                                % [-] Tuning coefficients of drop deposition enhancement (including at inlet)
                    KG = KG(discretize(drop.Z(zIdx),[0 model.KLOC drop.Z(end)])); % [-] Corresponding axial distribution of tuning coefficients

                    kenh = KG(:).*(kenh-1)+1;                              % [-] Final axial distribution of drop deposition enhancement factor
            end
        end

        function mdep = MDEP(drop,zIdx,enhanced)
            %MDEP Drop deposition mass flux [kg/m^2/s]
            %
            % Implements various deposition models selected based on :attr:`Inputs.Model.DEPOSITION`.
            % Applies enhancement factors, and restricts deposition to annular flow region.
            % The enhancement flag allow to enable/disable deposition enhancement 
            %
            % Inputs:
            %
            % - drop     — :class:`Solvers.ThreeField.Drop` object
            % - zIdx     — Axial indices to evaluate (optional)
            % - enhanced — Flag indicating enhanced deposition downstream obstructions (optional, default = true)

            %TODO: Fluid properties to be modified to handle superheated vapor when implementing thermal non-equilibrium model
 
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            if nargin < 3, enhanced = true;         end

            model = drop.inputSet.model;
            rhog  = drop.fluid.RHOG;                                       % [kg/m^3] Saturated vapor density
            sig   = drop.fluid.SIGMA;                                      % [N/m] Surface tension
            hdiam = drop.inputSet.geometry.HDIAM;                          % [m] Hydraulic diameter

            conc = abs(drop.CONC(zIdx));                                   % [kg/m^3] Drop concentration
            conc = conc + 1E-6;                                            % Avoid division by 0

            Wd = drop.W(zIdx);
            negdrop = find(Wd<0);
            %Wd = abs(Wd);

            switch model.DEPOSITION
                case InputEnums.DEPOSITION.NONE
                    % Suppress drop deposition
                    mdep = zeros(length(zIdx),1);
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
            if enhanced
                mdep = drop.KENH(zIdx).*mdep;                              % [kg/m^2/s] Enhanced drop deposition
            end
            mdep = drop.mix.AFDISTR(0,mdep,zIdx);                          % [kg/m^2/s] Deposition mass flux, in annular flow region only
        end

        function re = RE(drop, zIdx)
            %RE Drop Reynolds number [-]
            %
            % Calculates the Reynolds number for the drop field based on
            % mass flow rate, viscosity, and channel perimeter.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            perim = drop.inputSet.geometry.PERIM;                          % [m] Perimeter

            re = 4.*drop.W(zIdx)./drop.MU(zIdx)./sum(perim);               % [-]
        end

        function vr = VR(drop,zIdx)
            %VR Drop local relative velocity [m/s]
            %
            % Calculates the velocity difference between vapor and drop fields.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Only AREAMEAN option is implemented.

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            vr = drop.mix.vapor.U(zIdx) - drop.U(zIdx);                    % [m/s]
        end

        function rev = REV(drop,zIdx)
            %REV Drop Reynolds number with respect to vapor properties [-]
            %
            % Calculates Reynolds number using vapor density, viscosity,
            % and relative phase velocity.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            RHOV = drop.fluid.RHOV(drop.H(zIdx));                          % [kg/m^3]
            MUV  = drop.fluid.MUV(drop.H(zIdx));                           % [Pa.s]
            VR   = drop.VR(zIdx);                                          % [m/s]

            rev = RHOV.*abs(VR).*drop.DIAM(zIdx)./MUV;                     % [-]
        end

        function diam = DIAM(drop,zIdx)
            %DIAM Drop diameter [m]
            %
            % Returns the drop diameter based on :attr:`Inputs.Model.DROPDIAM`.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)
 
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            model = drop.inputSet.model;

            diam = repmat(model.DROPDIAM,length(zIdx),1);                  % [m]
        end

        function area = AREA(drop,zIdx)
            %AREA Drop interfacial area [m^2]
            %
            % Calculates the surface area of a spherical drop.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)
 
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            area = pi.*drop.DIAM(zIdx).^2;                                 % [m^2]
        end

        function volume = VOLUME(drop,zIdx)
            %VOLUME Drop volume [m^3]
            %
            % Calculates the volume of a spherical drop.
            %
            % Inputs:
            %
            % - drop    — :class:`Solvers.ThreeField.Drop` object
            % - zIdx    — Axial indices to evaluate (optional)
 
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            volume = (pi/6).*drop.DIAM(zIdx).^3;                           % [m^3]
        end

        function density = DENSITY(drop,zIdx)
            %DENSITY Drop number density [m^-3]
            %
            % Calculates the number of drops per unit volume based on
            % flow properties and geometry.
            %
            % Inputs:
            %
            % - drop     — :class:`Solvers.ThreeField.Drop` object
            % - zIdx     — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            area  = drop.inputSet.geometry.AREA;                           % [m^2] Cross-section area
            rhof  = drop.fluid.RHOF;                                       % [kg/m^3] Liquid density

            density = drop.W(zIdx)./drop.U(zIdx)./drop.VOLUME(zIdx)./rhof./area;  % [m^-3]
        end

        function ai = AI(drop,zIdx)
            %AI Drop volumetric interfacial area [m^-1]
            %
            % Calculates the interfacial area per unit volume for drops.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            ai = drop.DENSITY(zIdx).*drop.AREA(zIdx);                      % [m^-1]
        end

        function cd = DRAG(drop,zIdx)
            %DRAG Drop drag coefficient [-]
            %
            % Calculates drag coefficient using selected correlation based on
            % :attr:`Inputs.Model.DROPDRAG`.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            Re = drop.REV(zIdx);
            Re(Re <= 1E-3) = 1E-3;                                         % [-] Avoid division by 0

            model = drop.inputSet.model;

            switch model.DROPDRAG
                case InputEnums.DROPDRAG.CONSTANT
                    % Constant drag model
                    cd = repmat(model.DROPDRAGCOEF,length(zIdx),1);        % [-]

                case InputEnums.DROPDRAG.STOKES
                    % Stokes model
                    cd = 24./Re;                                           % [-]

                case InputEnums.DROPDRAG.VISCOUS
                    % Viscous model
                    cd = 24./Re.*(1+0.15.*Re.^0.687);                      % [-]

                case InputEnums.DROPDRAG.DISTORDED
                    % Distorted fluid particle (bubbly flow n=2.5)
                    %mult = sqrt(2)/3.*((1+17.67.*(1-liquid.VF(vapor,zIdx)).^(2.6))./(18.67.* (1-liquid.VF(vapor,zIdx)).^3)).^2;
                    mult = sqrt(2)/3.*(1-liquid.VF(vapor,zIdx)).^2;
                    cd = liquid.VISCL(zIdx).*Re.*mult;                     % [-]
            end

            cd = min(cd,1);
        end

        function Fbuoy = FBUOY(drop,zIdx)
            %FBUOY Drop buoyancy force [N/m^3]
            %
            % Calculates buoyancy force based on pressure gradient.
            %
            % Inputs:
            %
            % - drop    — :class:`Solvers.ThreeField.Drop` object
            % - zIdx    — Axial indices to evaluate (optional)
  
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            DPDZ = drop.mix.DP.Tot(zIdx)/drop.DZ;                          % [Pa/m] Pressure gradient

            Fbuoy = DPDZ;                                                  % [N/m^3]

            Fbuoy = drop.mix.AFDISTR(0,Fbuoy,zIdx);
        end

        function Fgrav = FGRAV(drop,zIdx)
            %FGRAV Gravitational force on drops [N/m^3]
            %
            % Calculates gravity force acting on drops based on channel
            % inclination angle.
            %
            % Inputs:
            %
            % - drop    — :class:`Solvers.ThreeField.Drop` object
            % - zIdx    — Axial indices to evaluate (optional)
 
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            geom = drop.inputSet.geometry;
            model = drop.inputSet.model;
            rhof = drop.fluid.RHOF;                                        % [kg/m^3] Liquid density

            Fgrav = -model.G*cos(geom.ANGLE*pi/180)*rhof;                  % [N/m^3]

            Fgrav = drop.mix.AFDISTR(0,Fgrav,zIdx);
        end

        function Fdrag = FDRAG(drop,zIdx)
            %FDRAG Vapor drag force on drops [N/m^3]
            %
            % Calculates shear force exerted by vapor on drops.
            %
            % Inputs:
            %
            % - drop    — :class:`Solvers.ThreeField.Drop` object
            % - zIdx    — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            UVAP = drop.mix.vapor.U(zIdx);                                 % [m/s] Vapor velocity
            rhog = drop.fluid.RHOG;                                        % [kg/m^3] Vapor density

            sgn = sign(UVAP-drop.U(zIdx));
            tau = sgn.*0.5.*drop.DRAG(zIdx).*rhog.*(abs(UVAP-drop.U(zIdx))).^2; % [N/m^2]

            Fdrag = drop.AREA(zIdx)./drop.VOLUME(zIdx).*tau;               % [N/m^3]

            Fdrag = drop.mix.AFDISTR(0,Fdrag,zIdx);
        end

        function Fent = FENT(drop,film,zIdx)
            %FENT Film entrainment shear force [N/m^3]
            %
            % Calculates shear force due to film entrainment acting on drops.
            %
            % Inputs:
            %
            % - drop    — :class:`Solvers.ThreeField.Drop` object
            % - film    — :class:`Solvers.ThreeField.Film` object
            % - zIdx    — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:drop(1).NZ).'; end

            perim = drop.inputSet.geometry.PERIM;                          % [m] Perimeter(s)
            ent   = -film.MENT(zIdx);                                      % [kg/m^2/s] Film entrainment mass flux
            rhof = drop.fluid.RHOF;                                        % [kg/m^3] Liquid density

            Fent = sum(perim.*(film.U(zIdx,:)-drop.U(zIdx)).*ent,2).*rhof.*drop.U(zIdx)./drop.W(zIdx); % [N/m^3]

            Fent = drop.mix.AFDISTR(0,Fent,zIdx);
        end

        function Ftot = FTOT(drop,film,zIdx,opt)
            %FTOT Total force acting on drops [N/m^3]
            %
            % Calculates combined forces (drag, buoyancy, gravity, entrainment)
            % based on selected option.
            %
            % Inputs:
            %
            % - drop    — :class:`Solvers.ThreeField.Drop` object
            % - film    — :class:`Solvers.ThreeField.Film` object
            % - zIdx    — Axial indices to evaluate (optional)
            % - opt     — Option flag (0: full balance, 1: simplified)

            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            if nargin < 4, opt = 0; end                                    % Option for complete of simplified force balance

            if opt == 1
                Ftot  = drop.FDRAG(zIdx)+drop.FBUOY(zIdx)+drop.FGRAV(zIdx); % [N/m^3] Fdrag + Fbuoy only
            else
                Ftot  = drop.FDRAG(zIdx)+drop.FBUOY(zIdx)+drop.FGRAV(zIdx)+drop.FENT(film,zIdx); % [N/m^3] Complete sum of forces
            end
        end

        function uslip = USLIP(drop,zIdx)
            %USLIP Slip velocity model for drops [m/s]
            %
            % Calculates drop velocity using slip ratio model based on
            % :attr:`Inputs.Model.DROPSLIP`.
            %
            % Inputs:
            %
            % - drop    — :class:`Solvers.ThreeField.Drop` object
            % - zIdx    — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            model = drop.inputSet.model;

            uslip = model.DROPSLIP.*drop.mix.vapor.U(zIdx);                % [m/s] Drop velocity

            uslip = drop.mix.AFDISTR(drop.mix.liquid.U(zIdx),uslip,zIdx);  % [m/s]
        end

        function ualgebr = UALGEBR(drop,film,zIdx)
            %UALGEBR Algebraic drop velocity [m/s]
            %
            % Calculates drop velocity consistent with mixture model
            % based on void fraction and geometry.
            %
            % Inputs:
            %
            % - drop      — :class:`Solvers.ThreeField.Drop` object
            % - film      — :class:`Solvers.ThreeField.Film` object
            % - zIdx      — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:drop(1).NZ).'; end

            perim = drop.inputSet.geometry.PERIM;                          % [m]
            area  = drop.inputSet.geometry.AREA;                           % [m^2]

            Ad = drop.mix.liquid.VF(zIdx).*area-sum(perim.*film.THICK(zIdx),2); % [m^2] Drop cross-section area based on void fraction
            ualgebr = drop.W(zIdx)/drop.fluid.RHOF./Ad;                    % [m/s] Corresponding drop velocity

            ualgebr = drop.mix.AFDISTR(drop.mix.liquid.U(zIdx),ualgebr,zIdx); % [m/s]
        end

        function Uequil = UEQUIL(drop,film,zIdx,opt)
            %UEQUIL Drop velocity based on equilibrium model (Ftot = 0) [m/s]
            %
            % Iteratively solves for drop velocity such that the total force acting
            % on the drop phase is zero (force balance). Uses secant method with
            % relaxation for convergence.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - film  — :class:`Solvers.ThreeField.Film` object
            % - zIdx  — Axial indices to evaluate (optional)
            % - opt   — Option flag for force balance:
            %           0 = full force balance (drag, buoyancy, gravity, entrainment)
            %           1 = simplified (drag + buoyancy only)
 
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            if nargin < 4, opt = 0; end                                    % Option for complete or simplified force balance

            options = drop.inputSet.options;

            iter(1).U = drop.U(zIdx);                                      % [m/s]
            iter(1).Ftot = drop.FTOT(film,zIdx,opt);                       % [N/m^3]

            iter(2).U = iter(1).U+0.1;                                     % [m/s]
            drop.U(zIdx) = iter(2).U;                                      % [m/s]
            iter(2).Ftot = drop.FTOT(film,zIdx,opt);% [N/m^3]

            eps = 1.0;
            for k = 3:options.UDEQUILMAXITER
                Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot); % [m/s]
                iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;               % [m/s]
                drop.U(zIdx) = iter(k).U;                                  % [m/s]
                iter(k).Ftot = drop.FTOT(film,zIdx,opt);                   % [N/m^3]
                err = max(abs(iter(k).Ftot),[],'all');                     % [N/m^3]
                if err < options.UDEQUILTOL, break; end
            end
            if err > options.UDEQUILTOL
                drop.log('\nEquilibrium drop velocity not converged at node %d after %d iterations. \nVolumetric force residual = %g N/m^3.\n',zIdx,k,err);
            end

            Uequil = drop.mix.AFDISTR(drop.mix.liquid.U(zIdx),drop.U(zIdx),zIdx);
        end

        function X = X(drop,zIdx)
            %X Vapor quality in the bulk (drop) region [-]
            %
            % Vapor quality in the bulk region, considering only the
            % droplet for the liquid phase. The bulk region is
            % complementary of the near-wall region, defined in the mixture
            % solver.
            %
            % Inputs:
            %
            % - drop  — :class:`Solvers.ThreeField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:drop(1).NZ).'; end

            X = 1-drop.W(zIdx)./drop.mix.NEARWALL.WBULK(zIdx);
        end

    end

    methods(Access = protected)

        function cpObj = copyElement(obj)
            %COPYELEMENT Overrides copyElement method for Drop class
            %
            % Creates a shallow copy of the Drop object while preserving references
            % to associated mixture and phase properties.
            %
            % Inputs:
            %
            % - obj   — :class:`Solvers.ThreeField.Drop` object

            import Solvers.ThreeField.*

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
        end

    end

end
