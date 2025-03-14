classdef Base < Solvers.AbstractFilm
    %BASE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Film heat flux
        %MEVAP        (:,:) double  {mustBeNumeric,mustBeNonpositive}       =-1.                   % [kg/s/m^2] Evaporation mass flux

        % Flow properties
        W            (:,:) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            (:,:) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            (:,:) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy

        % % Iteration properties
        ITR

     end

     properties (SetAccess=?Solvers.AbstractField, GetAccess=?Solvers.AbstractPhase)

        film

     end

     properties (Dependent)
         %MEVAP                                                                                    % [kg/s/m^2] Evaporation mass flux
     end

     
    methods
        function base = Base(film)
            %BASE Creates a Base, base
            %   Detailed explanation goes here

            if nargin > 0
                % Store film as object property
                base.film  = film;

                props = {'NZ','Z','DZ','NTIME','DT','TIME','TIDX','inputSet','fluid','mix'};                
                % Copy properties to base and wave
                for prop = props
                    base.(prop{:}) = film.(prop{:});
                end

                % Initialize W,U,H to proper size
                base.W = repmat(base.W,film.NZ,base.inputSet.geometry.NWALL);
                base.U = repmat(base.U,film.NZ,base.inputSet.geometry.NWALL);
                base.H = repmat(base.H,film.NZ,base.inputSet.geometry.NWALL);
            end
        end

        function epsilon = EPSILON(base, zIdx)
        %BETA Base film mass flow fraction
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            epsilon = base.W(zIdx,:) ./ base.film.W(zIdx,:);

            % epsilon is NaN if film.W == 0, i.e. dry
            % in this case, deposit on base
            % TODO: In NEGFILM case ...
            epsilon(isnan(epsilon)) = 1.0; 
        end
        
        function beta = BETA(base, zIdx)
        %BETA Base film interfacial fraction
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % TODO: for now, assume no wave
            % TODO: add as model option later
            % beta = 0.9;
            beta = 1-base.film.wave.BETA(zIdx);
        end

        function betap = BETAP(base, zIdx)
        %BETAP Base film heat flux fraction
        % Supression of heat flux to base film in pre-annular region is required to impose target base film thickness at OAF
        % The entire film evaporation hence occurs in the wave field
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % assuming split according to interfacial fraction, BETA
            % TODO: add as model option later
            betap = base.BETA(zIdx);
            
            betap = base.mix.AFDISTR(0,betap,zIdx);                        % Supress heat flux in pre-annular region
        end

        function eta = ETA(base, zIdx)
        %ETA Base film deposition fraction
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % TODO: add as model option later
            eta = base.EPSILON(zIdx).*base.BETA(zIdx);
        end
        
        function ment = MENT(base, zIdx)
        %MENT Base entrainment mass flux
        %   TODO: use coefficient later
            if nargin < 2, zIdx = (1:base(1).NZ).'; end
            
            % TODO: use coefficient later
            ment =  0.0 .* base.film.MENT(zIdx);            
        end

        function mevap = MEVAP(base, zIdx)
        %MEVAP Base evaporation mass flux
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            mevap = base.BETAP(zIdx) .* base.film.MEVAP(zIdx,:);
        end

        function Mturb = MTURB(base, zIdx)
        %MTURB Turbulent mass exchange
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            wave = base.film.wave;
            Kw_recp = base.inputSet.model.WAVEMIXCOEF;
            Mturb = min(abs(base.WL(zIdx)), wave.WL(zIdx)) ./ Kw_recp ./ wave.WIDTH(zIdx);
            Mturb = min(Mturb,10);
            Mturb = base.mix.AFDISTR(0,Mturb,zIdx);
        end
        
        function [Mwave, Mnet] = MWAVE(base,drop,zIdx)
        %MWAVE Base Mass flux interaction with wave
        %   Defined as a source term, Mwave is the 
            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            %TODO: implement model selection options

            % Saturated liquid density
            rho_ls = base.fluid.RHOF;
            % Relaxation term
            relaxTB = base.inputSet.model.RELAXTB;

            % Net exchange term (eq. 32)
            Mnet = -base.MEVAP(zIdx)-base.MENT(zIdx)-base.ETA(zIdx).*drop.MDEP(zIdx)+rho_ls.*(base.EQTHICK(zIdx)-base.THICK(zIdx))./relaxTB;

            % Wave exchange + turbulent mixing term (eq.7)
            Mturb = base.MTURB(zIdx);
            Mwave = max(Mnet, 0) + Mturb;

            % TODO: requires further investigation
            % if base.inputSet.model.POSFILM
            %     DeltaWLwave = max(0-base.film.wave.WL(zIdx),0);             % [kg/m-s] Wave flow is limited by 0
            %     DeltaMwave = DeltaWLwave ./ base.DZ;                        % [kg/m^2-s] Wave mass flux
            %     Mwave = Mwave - DeltaMwave;                                 % Apply to Mwave
            % end

            Mwave = base.mix.AFDISTR(0,Mwave,zIdx);
        end
        
        function Mtot = MTOT(base,drop,zIdx)
        %MTOT Total mass flux of the base film
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            % TODO: Create the MDEP method
            Mtot  = base.MEVAP(zIdx)+base.MENT(zIdx)+base.ETA(zIdx).*drop.MDEP(zIdx)+base.MWAVE(drop,zIdx)-base.film.wave.MBASE(drop,zIdx);

        end
        
        function Fwave = FWAVE(base,drop,zIdx)
        %FWAVE Wave interfacial force
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end
            
            switch base.inputSet.model.WAVEBASEINT
                case 'VAPORSHEAR'
                    Fwave = base.film.wave.BETA(zIdx).*base.FVAPOR(zIdx);  % [N/m^2]
                case 'VAPORSHEARDROPMASS'
                    Fwave = base.film.wave.BETA(zIdx).*base.FVAPOR(zIdx) + base.film.wave.FDEP(drop,zIdx); % [N/m^2]
            end
        end

        function Fwavemass = FWAVEMASS(base,drop,zIdx)
        %FWAVEMASS Base mass exchange force
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            %TODO:
            deltaU = base.film.wave.U(zIdx) - base.U(zIdx);
            Fwavemass = base.MWAVE(drop,zIdx).*deltaU; % [N/m^2]

            Fwavemass = base.mix.AFDISTR(0,Fwavemass,zIdx);
        end

        function Fbasevapor = FBASEVAPOR(base,zIdx)
        %FBASEVAPOR Film base vapor shear stress
        %   TODO: consider different way of doing this...
            
            if nargin < 2, zIdx = (1:base(1).NZ).'; end
            
            % TODO: debug syntax
            Fbasevapor = base.BETA(zIdx).* base.FVAPOR(zIdx); % [N/m^2]
            
        end

        function Fdep = FDEP(base,drop,zIdx)
        %FDEP Droplet
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            deltaU = drop.U(zIdx) - base.U(zIdx,:);
            Fdep = base.ETA(zIdx).*drop.MDEP(zIdx) .* deltaU;   % [N/m^2]
            
            Fdep = base.mix.AFDISTR(0,Fdep,zIdx);
        end

        function Ftot = FTOT(base,drop,zIdx)
        %FTOT Total
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            switch base.inputSet.model.MOMENTBASE
                case 'FULLNOP'
                    Ftot  = base.FWALL(zIdx)+base.FWAVE(drop,zIdx)+base.FWAVEMASS(drop,zIdx)+base.FBASEVAPOR(zIdx)+base.FDEP(drop,zIdx);
                otherwise
                    Ftot  = base.FWALL(zIdx)+base.FWAVE(drop,zIdx)+base.FWAVEMASS(drop,zIdx)+base.FBASEVAPOR(zIdx)+base.FBUOY(zIdx)+base.FGRAV(zIdx)+base.FDEP(drop,zIdx);
            end
        end

        function eqthick = EQTHICK(base,zIdx)
        %EQTHICK Base equilibrium thickness
        %   
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            D_H = base.inputSet.geometry.HDIAM;
            
            switch base.inputSet.model.BASEEQTHICK
                case 'RISO'
                    coefs = [5.37E-5 -0.64 1.21];
                    eqthick = ReMethod();
                case 'MFVAL'
                    coefs = [1.8E-5 -0.5 1.5];
                    eqthick = ReMethod();
                case 'COEFS'
                    coefs = base.inputSet.model.BASEEQTHICKCOEF;
                    eqthick = ReMethod();
                case 'YPLUS'
                    yplus = 15;
                    eqthick = base.YPLUS2THICK(yplus, zIdx);
            end

            function eqthick = ReMethod()
                
                Re_v = base.film.mix.vapor.RE(zIdx);
                Re_f = base.film.RE(zIdx);
                eqthick = D_H .* coefs(1) .* (Re_v.^coefs(2)) .* (Re_f.^coefs(3));
            end
            
            % Limit eqthick to 1/2 of D_H, at most
            eqthick = min(eqthick, D_H/2);
        end

        function tbase = TBASE(base, zIdx)
        %TBASE Base film exposed time
        %   The time in which the base film is exposed to the vapor (eq.24)

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            wave = base.film.wave;
            lambda_w = wave.SPACING(zIdx);
            DeltaU = wave.U(zIdx,:) - base.U(zIdx,:);
            tbase = base.BETA(zIdx).*lambda_w./DeltaU;

            % If the wave and base speeds are the same, the period can be
            % set to 0.
            tbase(isinf(tbase)) = 0;

            % TODO: Handle deltaU tending to 0 near OAF.
            % tbaseMax = max(0.1 ./ wave.U(zIdx,:));
            % tbase(abs(tbase) > tbaseMax) = 0;

            tbase = base.mix.AFDISTR(0, tbase, zIdx);

        end

        function tdry = TDRY(base, drop, zIdx)
        %TDRY Time duration in which the base is expected to dry out.
        %   Not included in the reference paper.

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            per = base.inputSet.geometry.PERIM;
            Wb = base.W(zIdx,:);
            Ub = base.U(zIdx,:);
            DeltaM=-base.MEVAP(zIdx) - base.ETA(zIdx).*drop.MDEP(zIdx);
            betaB = base.BETA(zIdx);
            
            tdry = base.TBASE(zIdx) - Wb.*betaB./per./Ub./DeltaM;
            tdry(DeltaM<=0) = 0;
            % If dry out doesn't occur, set to 0.
            tdry = max(tdry, 0);

        end

        function fdry = FDRY(base, drop, zIdx)
        %FDRY Dry fraction
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            tbase = base.TBASE(zIdx);
            fdry = base.TDRY(drop, zIdx)./tbase;

            % If the base is never exposed (tbase==0), fdry is 0 by
            % definition.
            fdry(tbase==0) = 0;

        end

        function wmin = WMIN(base, drop, zIdx)
        % WMIN Minimum base film mass flow rate (eq. 27)
        %   Base film mass flow rate at the end of the intermittent exposed
        %   time (TBASE).
            
            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            per = base.inputSet.geometry.PERIM;
            Wb = base.W(zIdx,:);
            Ub = base.U(zIdx,:);
            DeltaM=-base.MEVAP(zIdx) - base.ETA(zIdx).*drop.MDEP(zIdx);
            Betab = base.BETA(zIdx);
            wmin = Wb-per.*Ub.*DeltaM./Betab.*base.TBASE(zIdx);

            % When Betab == 0, Wmin is Wb
            wmin(Betab==0) = Wb(Betab==0);
            
            wmin = max(wmin, 0);
        end

        function wminl = WMINL(base, drop, zIdx)
        % WMINL Minimum base film mass flow rate per perimeter
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            wminl = base.WMIN(drop, zIdx) ./ base.inputSet.geometry.PERIM;
        end

        function thickmin = THICKMIN(base, drop, zIdx)
        % THICKMIN Minimum base film thickness (eq. 28)
        %   

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            rho_ls = base.fluid.RHOF;
            Ub = base.U(zIdx,:);
            per = base.inputSet.geometry.PERIM;
                
            thickmin = base.WMIN(drop, zIdx)./(rho_ls.*Ub.*per);
        end


        

        function copyFlowProperties(srcObj, targetObj, opts)
        %COPYFLOWPROPERTIES
        %
            arguments
                srcObj
                targetObj (1,:) Solvers.FourField.Base
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
                
                % TODO: copy film?
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

