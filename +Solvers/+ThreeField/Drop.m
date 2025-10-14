classdef Drop < Solvers.AbstractField
    %DROP Summary of this class goes here
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

     properties (Access=private)
        dep_enh_facs  (:,1) double  {mustBeNumeric}                         = []                   % solved deposition enhancement factors
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

            % Overload copyable properties
            %mix.flowProperties = {'W','U','H'};

        end
        
        function conc = CONC(drop,zIdx)
        % Drop concentration
        
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            vapor = drop.mix.vapor;
            rhof  = drop.fluid.RHOF;
            rhog  = drop.fluid.RHOG;
            
            Wd = drop.W(zIdx);
            negdrop = find(Wd<0);
            Wd = abs(Wd);
            
            conc = Wd./(Wd./rhof+vapor.W(zIdx)./rhog);                     % [kg/m^3] Drop concentration
            conc(negdrop) = -conc(negdrop);
        end
        
        function kenh = KENH(drop,zIdx)
        % Drop deposition enhancement factor
        % Model documented in Le Corre, 2024.
            
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            kdist = drop.mix.KDIST(zIdx);
            
            switch model.DEPENHANCEMENT
                case InputEnums.DEPENHANCEMENT.NONE
                    % No drop deposition enhancement
                    kenh = ones(length(zIdx),1);
                case InputEnums.DEPENHANCEMENT.WINDECKER
                    % Windecker drop depositon endhancement model
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
        
        function mdep = MDEP(drop,zIdx)
        % Drop deposition mass flux
    
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            rhog  = drop.fluid.RHOG;                                       % [kg/m^3] Saturated vapor density <-!!!To be modified to handle superheated vapor
            sig   = drop.fluid.SIGMA;                                      % [N/m] Surface tension
            hdiam = drop.inputSet.geometry.HDIAM;                          % [m] Hydraulic diameter
            
            conc = abs(drop.CONC(zIdx));                                   % [kg/m^3] Drop concentration
            conc = conc + 1E-6;                                            % Avoid division by 0 in mded correlations
            
            Wd = drop.W(zIdx);
            negdrop = find(Wd<0);
            %Wd = abs(Wd);
            
            switch model.DEPOSITION
                case InputEnums.DEPOSITION.NONE
                    % Supress drop deposition
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
            
            k_enh_dep = drop.ENHANCEDEP(zIdx);
            mdep = k_enh_dep .* mdep;
            mdep(negdrop)=-mdep(negdrop);
            mdep = drop.KENH(zIdx).*mdep;                                  % [kg/m^2/s] Enhanced drop deposition
            mdep = drop.mix.AFDISTR(0,mdep,zIdx);                          % [kg/m^2/s] Deposition mass flux, in annular flow region only
        end

        function re = RE(drop, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            perim = drop.inputSet.geometry.PERIM;                          % [m] Perimeter
            
            re = 4.*drop.W(zIdx)./drop.MU(zIdx)./sum(perim);               % [-]
        end
        
        function vr = VR(drop,zIdx)
        %VR Local relative velocity [m/s]
        %Only AREAMEAN option has been iplemented
            
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            vr = drop.mix.vapor.U(zIdx) - drop.U(zIdx);                    % [m/s]
        end
        
        function rev = REV(drop,zIdx)
        %REV Reynolds number with respect to vapor properties and relative phase velocity [-]
        
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            RHOV = drop.fluid.RHOV(drop.H(zIdx));
            MUV  = drop.fluid.MUV(drop.H(zIdx));  
            VR   = drop.VR(zIdx);
            
            rev = RHOV.*abs(VR).*drop.DIAM(zIdx)./MUV;                     % [-]
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
        
        function cd = DRAG(drop,zIdx)
        %DRAG drop drag coefficient
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            Re = drop.REV(zIdx);
            Re(Re <= 1E-3) = 1E-3;                                       % [-] Avoid division by 0 
            
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
        %FBUOY Drop buoyancy
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            DPDZ = drop.mix.DP.Tot(zIdx)/drop.DZ;                          % [Pa/m] Pressure gradient
            
            Fbuoy = DPDZ;                                                  % [N/m^3]
            
            Fbuoy = drop.mix.AFDISTR(0,Fbuoy,zIdx);   
        end
        
        function Fgrav = FGRAV(drop,zIdx)
        %FGRAV Drop gravity
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            rhof = drop.fluid.RHOF;                                        % [kg/m^3] Liquid density
            
            Fgrav = -model.G*cos(model.ANGLE*pi/180)*rhof;                 % [N/m^3]
            
            Fgrav = drop.mix.AFDISTR(0,Fgrav,zIdx);

        end   
        
        function Fdrag = FDRAG(drop,zIdx)
        %FVAPOR drop vapor drag
        %
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            UVAP = drop.mix.vapor.U(zIdx);                                 % [m/s] Vapor velocity
            rhog = drop.fluid.RHOG;                                        % [kg/m^3] Vapor density
            
            sgn = sign(UVAP-drop.U(zIdx));
            tau = sgn.*0.5.*drop.DRAG(zIdx).*rhog.*(abs(UVAP-drop.U(zIdx))).^2; % [N/m^2]
            
            Fdrag = drop.AREA(zIdx)./drop.VOLUME(zIdx).*tau;               % [N/m^3]
            
            Fdrag = drop.mix.AFDISTR(0,Fdrag,zIdx);
        end
        
        function Fent = FENT(drop,film,zIdx)
        %FENT Film entrainment shear
        %
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            perim = drop.inputSet.geometry.PERIM;                          % [m] Perimeter(s)
            ent   = -film.MENT(zIdx);                                  % [kg/m^2/s] Film entrainment mass flux
            rhof = drop.fluid.RHOF;                                        % [kg/m^3] Liquid density
            
            Fent = sum(perim.*(film.U(zIdx,:)-drop.U(zIdx)).*ent,2).*rhof.*drop.U(zIdx)./drop.W(zIdx); % [N/m^3]
            
            Fent = drop.mix.AFDISTR(0,Fent,zIdx);   
        end
        
        function Ftot = FTOT(drop,film,zIdx,opt)
        %FTOT Total
        %
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            if nargin < 4, opt = 0; end                                    % Option for complete of simplified force balance
            
            if opt == 1
                Ftot  = drop.FDRAG(zIdx)+drop.FBUOY(zIdx)+drop.FGRAV(zIdx); % [N/m^3] Fdrag + Fbuoy only
            else
                Ftot  = drop.FDRAG(zIdx)+drop.FBUOY(zIdx)+drop.FGRAV(zIdx)+drop.FENT(film,zIdx); % [N/m^3] Complete sum of forces
            end
        end
        
        function uslip = USLIP(drop,zIdx)
        % Slip drop velocity model
    
            if nargin < 2, zIdx = (1:drop(1).NZ).'; end
            
            model = drop.inputSet.model;
            
            uslip = model.DROPSLIP.*drop.mix.vapor.U(zIdx);                     % [m/s] Drop velocity
            
            uslip = drop.mix.AFDISTR(drop.mix.liquid.U(zIdx),uslip,zIdx);            % [m/s] 
        end
        
        function ualgebr = UALGEBR(drop,film,zIdx)
        % Algebraic drop velocity model (consistent with mixture model)

            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            
            perim = drop.inputSet.geometry.PERIM;
            area  = drop.inputSet.geometry.AREA;
            
            Ad = drop.mix.liquid.VF(zIdx).*area-sum(perim.*film.THICK(zIdx),2); % [m^2] Drop cross-section area based on void fraction
            ualgebr = drop.W(zIdx)/drop.fluid.RHOF./Ad;                    % [m/s] Corresponding drop velocity
            
            ualgebr = drop.mix.AFDISTR(drop.mix.liquid.U(zIdx),ualgebr,zIdx);        % [m/s] 
        end
        
        function Uequil = UEQUIL(drop,film,zIdx,opt)
        %UEQUIL Drop velocity based on equilibrium model (Ftot = 0)
        %
            if nargin < 3, zIdx = (1:drop(1).NZ).'; end
            if nargin < 4, opt = 0; end                                    % Option for complete or simplified force balance
            
            iter(1).U = drop.U(zIdx);
            iter(1).Ftot = drop.FTOT(film,zIdx,opt);
            
            iter(2).U = iter(1).U+0.1;
            drop.U(zIdx) = iter(2).U;
            iter(2).Ftot = drop.FTOT(film,zIdx,opt);
            
            eps = 1.0;
            for k = 3:100
                Uiter = iter(k-2).U-iter(k-2).Ftot.*(iter(k-1).U-iter(k-2).U)./(iter(k-1).Ftot-iter(k-2).Ftot);
                iter(k).U = (1-eps).*iter(k-1).U+eps.*Uiter;
                drop.U(zIdx) = iter(k).U;
                iter(k).Ftot = drop.FTOT(film,zIdx,opt);
                err = max(abs(iter(k).Ftot),[],'all');
                if err<1E-3, break; end
            end
            if err > 1E-3, disp('Drop UEQUIL model : not converged')
            end
            
            Uequil = drop.mix.AFDISTR(drop.mix.liquid.U(zIdx),drop.U(zIdx),zIdx);
        end

    end

    methods(Access=private)

        function k_enh_dep = ENHANCEDEP(drop, zIdx)
            %ENHANCEDEP Private function to calculate the enhancement deposition factor

            % Use saved value if it has been calculated already
            if ~isempty(drop.dep_enh_facs)
                k_enh_dep = drop.dep_enh_facs(zIdx);
                return
            end

            model = drop.inputSet.model;

            % Model coefficients
            % In the future, allow these to be user defined
            B = 7.898;
            D = 4.791;
            k_enh_dep_MAX = (D * model.KBLOCKRATIO + 1) .* (B * model.KBLOCKRATIO + 1);

            spacer_locs = find(drop.mix.DP.K);
            kg = model.KTUNING;

            drop.dep_enh_facs = ones(drop.NZ,1);

            for i = 1:length(spacer_locs)
                zId = spacer_locs(i);
                while drop.Z(zId) - drop.Z(spacer_locs(i)) <= 0.45
                    if drop.Z(zId) - drop.Z(spacer_locs(i)) <= 0.05
                        drop.dep_enh_facs(zId) = model.KTUNING(i) * ((0.95 * k_enh_dep_MAX(i) - 1) * (drop.Z(zId) - drop.Z(spacer_locs(i))) / 0.05 + 1 - 1) + 1; 
                    elseif drop.Z(zId) - drop.Z(spacer_locs(i)) <= 0.15
                        drop.dep_enh_facs(zId) = model.KTUNING(i) * (0.95 * k_enh_dep_MAX(i) - 1) + 1;
                    else
                        drop.dep_enh_facs(zId) = model.KTUNING(i) * (1 / ((1 - 1 / (0.95 * k_enh_dep_MAX(i))) * (drop.Z(zId) - drop.Z(spacer_locs(i)) - 0.15) / 0.3 + 1 / (0.95 * k_enh_dep_MAX(i))) - 1) + 1;
                    end
                    zId = zId + 1;
                    if zId > drop.NZ
                        break
                    end
                end
            end

            k_enh_dep = drop.dep_enh_facs(zIdx);
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

