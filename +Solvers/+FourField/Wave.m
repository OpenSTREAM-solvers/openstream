classdef Wave < Solvers.AbstractFilm
    %WAVE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Film heat flux

        % Flow properties
        W            (:,:) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            (:,:) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            (:,:) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        FREQUENCY    (:,:) double  {mustBeNumeric}                         = 1                    % [Hz] Wave frequency

        % Iteration properties
        ITR

     end

     properties (SetAccess=?Solvers.AbstractField, GetAccess=?Solvers.AbstractPhase)
        
        film

     end

    methods
        
        function wave = Wave(film)
            %WAVE Creates a Wave, wave
            %   Detailed explanation goes here

            if nargin > 0
                % Store film as object property
                wave.film  = film;

                props = {'NZ','Z','DZ','NTIME','DT','TIME','TIDX','inputSet','fluid','mix'};                
                % Copy properties to base and wave
                for prop = props
                    wave.(prop{:}) = film.(prop{:});
                end

                % Initialize W,U,H to proper size
                wave.W = repmat(wave.W,film.NZ,wave.inputSet.geometry.NWALL);
                wave.U = repmat(wave.U,film.NZ,wave.inputSet.geometry.NWALL);
                wave.H = repmat(wave.H,film.NZ,wave.inputSet.geometry.NWALL);
                wave.FREQUENCY = repmat(wave.FREQUENCY,film.NZ,film.inputSet.geometry.NWALL);
            end

            % Overload copyable properties
            wave.flowProperties = {'W','U','H', 'FREQUENCY'};

        end
        
        function wl = WL(wave, zIdx)
        %WL wave mass flow rate per unit perimeter
        %    
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            perim  = wave.inputSet.geometry.PERIM;
            
            wl = wave.W(zIdx,:)./perim;                                    % [kg/s/m] Wave mass flow rate per unit perimeter
        end
        
        function thick = THICK(wave, zIdx)
        %THICK wave thickness
        %    
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
        
            thick = wave.AMPLITUDE(zIdx) .* wave.BETA(zIdx);               % [m] Wave thickness
        end

        function beta = BETA(wave, zIdx)
        %BETA Wave film interfacial fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            %beta = 1-wave.film.base.BETA(zIdx);
            
            beta = wave.WIDTH(zIdx) ./ wave.SPACING(zIdx);
            epsilon = wave.EPSILON(zIdx);
            beta(isnan(beta)) = epsilon(isnan(beta));
            %beta(:) = 0.6;

            % Apply BETA to distribution
            beta = wave.film.mix.AFDISTR(epsilon,beta,zIdx);
        end

        function epsilon = EPSILON(wave, zIdx)
        %BETA Wave mass flow fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            epsilon = wave.W(zIdx, :) ./ wave.film.W(zIdx, :);
            epsilon(wave.W(zIdx,:)<=0) = 0.0;
        end

        function betap = BETAP(wave, zIdx)
        %BETAP Wave film heat flux fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            betap = 1-wave.film.base.BETAP(zIdx);
        end

        function eta = ETA(wave, zIdx)
        %ETA Wave film deposition fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            eta = 1-wave.film.base.ETA(zIdx);
        end

        function ment = MENT(wave,zIdx)
        %MENT Wave entrainment mass flux
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            % TODO: use coefficient later
            ment = wave.film.MENT(zIdx) - wave.film.base.MENT(zIdx);            
        end

        function mevap = MEVAP(wave, zIdx)
        %MEVAP Wave evaporation mass flux
        %            
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            mevap = wave.BETAP(zIdx) .* wave.film.MEVAP(zIdx,:);            
        end
        
        function mdep = MDEP(wave,drop,zIdx)
        %MDEP Wave deposition mass flux
        %            
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            mdep = wave.ETA(zIdx).*drop.MDEP(zIdx);
        end
        
        function mturb = MTURB(wave, zIdx)
        %MTURB Turbulent mass exchange
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            mturb = wave.film.base.MTURB(zIdx);
        end
        
        function Mbase = MBASE(wave,drop,zIdx)
        %MWAVE Mass flux interaction with base
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            % Net exchange term (eq. 32)
            [~, Mnet] = wave.film.base.MWAVE(drop,zIdx);
            
            % Base exchange + turbulent mixing term (eq.8)
            Mturb = wave.MTURB(zIdx);
            Mbase = max(-Mnet, 0) + Mturb;
            
            Mbase = wave.mix.AFDISTR(0,Mbase,zIdx);
        end
        
        function Mtot = MTOT(wave,drop,zIdx)
        %MTOT Total mass flux
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end
            
            % TODO: Create the MDEP method
            Mtot = wave.MEVAP(zIdx)+wave.MENT(zIdx)+wave.MDEP(drop,zIdx)+wave.MBASE(drop,zIdx)-wave.film.base.MWAVE(drop,zIdx);
            
        end

        function Fwall = FWALL(wave,zIdx)
        %FWALL Wave wall shear stress
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            error('Wave does not implement wall shear stress');
            
        end

        function Fbase = FBASE(wave,drop,zIdx)
        %FBASE Base interfacial force
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end
            
            Fbase = -wave.film.base.FWAVE(drop,zIdx); % [N/m^2]
            
        end

        function Fbasemass = FBASEMASS(wave,drop,zIdx)
        %FBASEMASS Wave mass exchange force
        %
            if nargin <3, zIdx = (1:wave(1).NZ).'; end
            
            %TODO:
            deltaU = wave.film.base.U(zIdx) - wave.U(zIdx);
            Fbasemass = wave.MBASE(drop,zIdx).*deltaU; % [N/m^2]
            
            Fbasemass = wave.mix.AFDISTR(0,Fbasemass,zIdx);
        end

        function Fvapor = FVAPOR(wave,zIdx)
        %FVAPOR Wave vapor shear stress
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            Fvapor = wave.FDRAG(zIdx) + wave.FSHEAR(zIdx);
            
        end

        function Fdrag = FDRAG(wave,zIdx)
        %FDRAG Film vapor shear stress due to drag
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            % Saturated vapor density
            rho_vs = wave.fluid.RHOG;
            
            % Difference in wave and vapor velocities
            dU = wave.mix.vapor.U(zIdx) - wave.U(zIdx);

            % Eq. 45
            Fdrag = 0.5 .* wave.SHAPEFACTOR(zIdx) .* wave.DRAGCOEF(zIdx) .* rho_vs .* dU.^2;
            Fdrag = wave.BETA(zIdx).*Fdrag;

            Fdrag = wave.mix.AFDISTR(0,Fdrag,zIdx);
        end

        function Fshear = FSHEAR(wave,zIdx)
        %FSHEAR Film vapor shear stress
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Friction factor
            f_v_w = wave.CV(zIdx);
            
            % Saturated vapor density
            rho_vs = wave.fluid.RHOG;
            
            % Difference in wave and vapor velocities
            dU = wave.mix.vapor.U(zIdx) - wave.U(zIdx);

            % Eq. 46
            Fshear = 0.5 .* f_v_w .* rho_vs .* dU.^2;
            Fshear = wave.BETA(zIdx).*Fshear;
            
        end
        
        function Fdep = FDEP(wave,drop,zIdx)
        %FDEP Droplet
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end
            
            deltaU = drop.U(zIdx) - wave.U(zIdx,:);
            Fdep = wave.MDEP(drop,zIdx) .* deltaU;                         % [N/m^2]
            
            Fdep = wave.mix.AFDISTR(0,Fdep,zIdx);
        end

        function Ftot = FTOT(wave,drop,zIdx)
        %FTOT Total
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end
            
            Ftot = wave.FVAPOR(zIdx)+wave.FBUOY(zIdx)+wave.FGRAV(zIdx)+wave.FDEP(drop,zIdx)+wave.FBASE(drop,zIdx)+wave.FBASEMASS(drop,zIdx);
            
        end

        function shapefactor = SHAPEFACTOR(wave, zIdx)
        %SHAPEFACTOR 
        %

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            coef = wave.inputSet.model.SHAPEFACTORCOEF;
            shapefactor = (wave.RE(zIdx)./coef(1)).^coef(2);
        end

        function eqst = EQSTROUHAL(wave, zIdx)
        %STROUHAL Correlation of equilibrium Strouhal number
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            model = wave.inputSet.model;
            
            switch model.EQSTROUHAL
                case 'RISO'
                    coefs = [1.1236E-4 0.5 0.0];                           % Eq. 59
                case 'SAWAI'
                    coefs = [77.67    -1.3 0.46];                          % Eq. 70
                case 'MFVAL'
                    coefs = [4.1E-8    0.5 0.5];
                case 'CUSTOM'
                    coefs = model.EQSTROUHALCOEF;
            end

            switch model.EQSTROUHAL
                case {'RISO','SAWAI','MFVAL','CUSTOM'}
                    re_v = wave.film.mix.vapor.RE(zIdx);
                    re_f = wave.film.RE(zIdx);
                    eqst = coefs(1) .* re_v.^coefs(2) .* re_f.^coefs(3);
                case {'CSTFREQ'}
                    geom = wave.inputSet.geometry;
                    d_h  = geom.HDIAM;                                     % [m]
                    eqst = model.CSTWAVEFREQ.*d_h./wave.film.mix.vapor.U(zIdx);
                    eqst = repmat(eqst,1,geom.NWALL);
            end

        end

        function eqfreq = EQFREQUENCY(wave, zIdx)
        %EQFREQUENCY
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Hydraulic diameter
            d_h = wave.inputSet.geometry.HDIAM;
            %nwall = wave.inputSet.geometry.NWALL;

            % Solve eqfreq using definition of St
            eqfreq = wave.EQSTROUHAL(zIdx).*wave.film.mix.vapor.U(zIdx)./d_h;

        end

        function eqperiod = EQPERIOD(wave, zIdx)
        %EQPERIOD Inverse of EQFREQ
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            eqperiod = 1./wave.EQFREQUENCY(zIdx);
        
        end

        function spacing = SPACING(wave, zIdx)
        %SPACING Wave spacing
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            spacing = wave.U(zIdx,:) ./ wave.FREQUENCY(zIdx,:);

        end

        function period = PERIOD(wave, zIdx)
        %PERIOD Wave time period
        %   Inverse of wave frequency

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            period = 1./wave.FREQUENCY(zIdx, :);

        end

        function n = N(wave, zIdx)
        %N Wave number density
        %   Inverse of wave spacing
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            n = 1./ wave.SPACING(zIdx);            

        end
        
        function wwidth = WIDTH(wave, zIdx)
        %WIDTH Wave width
        %   Function of amplitude, Shape factor
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            wwidth = wave.AMPLITUDE(zIdx)./wave.SHAPEFACTOR(zIdx);

            % if wwidth isnan, set to wave spacing
            spacing = wave.SPACING(zIdx);
            wwidth(isnan(wwidth)) = spacing(isnan(wwidth));

            % Limit width to be no larger than the spacing
            wwidth = min(wwidth, wave.SPACING(zIdx));

        end

        function amp = AMPLITUDE(wave, zIdx)
        %AMPLITUDE Wave amplitude
        %   Function of WL, rho, Shape factor, frequency
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            rhof = wave.fluid.RHOF;
            amp = (wave.WL(zIdx).* wave.SHAPEFACTOR(zIdx))./(rhof.* wave.FREQUENCY(zIdx,:));
            amp = sqrt(abs(amp));
            
            % Limit amp+base.thick to 1/2 of D_H, at most
            D_H = wave.inputSet.geometry.HDIAM;
            amp = min(amp, D_H/2-wave.film.base.THICK(zIdx));

        end
        
        function deltafreq = DELTAFREQ(wave, zIdx)
        %DELTAFREQ Wave frequency source/sink
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            relaxTW = wave.inputSet.model.RELAXTW;
            deltafreq = (wave.EQFREQUENCY(zIdx)-wave.FREQUENCY(zIdx,:))./wave.U(zIdx,:)./relaxTW;  % [Hz/m] Wave frequency exchange terms
            
            deltafreq = wave.mix.AFDISTR(0,deltafreq,zIdx);
        end
        
        function rev = REV(wave, zIdx)
        %REF Vapor Reynolds number (with respect to waves)
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Coefficients
            coefs = wave.inputSet.model.WAVEDRAGCOEF;

            % Vapor Reynolds number (Eq. 64)
            rho_vs = wave.fluid.RHOG;
            du = wave.film.mix.vapor.U(zIdx) - wave.U(zIdx,:);
            mu_vs = wave.fluid.MUG;
            rev = rho_vs .* du .* coefs(1) ./mu_vs;
        end

        function dragcoef = DRAGCOEF(wave, zIdx)
        %DRAGCOEF Wave drag coefficient
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Coefficients
            coefs = wave.inputSet.model.WAVEDRAGCOEF;
            
            % Vapor Reynolds number (Eq. 64)
            Re_vw = wave.REV(zIdx);

            % Draf Coef (Eq. 63)
            dragcoef = (coefs(2)./Re_vw).^2 + coefs(3);
        end
    
    end

end

