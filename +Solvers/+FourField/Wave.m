classdef Wave < Solvers.AbstractFilm
    %WAVE Class for modeling liquid waves in four-field solver
    %
    % This class represents the physical and numerical properties of the
    % wave field in a four-field thermal-hydraulic solver.
    % It handles flow variables, heat transfer, and phase interaction
    % mechanisms between the waves and other fields (base film, drop, vapor).
    %
    % The class supports initialization from an existing film object and
    % provides methods for computing derived quantities such as mass flow
    % fractions, interfacial fractions, and deposition/evaporation fluxes.

    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})

        % Solver state
        NZ                                                                 = 0                    % Number of axial steps [-]
        NTIME                                                              = 0                    % Number of time steps [-]
        TIME                                                               = 0                    % Time series [s]
        DT                                                                 = 0                    % Time step size [s]
        TIDX                                                               = 1                    % Time step index [-]
        Z                                                                  = 1.                   % Elevation [m]
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % Film heat flux [W/m^2]

        % Flow properties
        W            (:,:) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        U            (:,:) double  {mustBeNumeric}                         = 1.                   % Velocity [m/s]
        H            (:,:) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]
        FREQUENCY    (:,:) double  {mustBeNumeric}                         = 1                    % Wave frequency [Hz]

        % Iteration properties
        ITR

    end

    properties (SetAccess=?Solvers.AbstractField, GetAccess=?Solvers.AbstractPhase)

        film

    end

    methods

        function wave = Wave(film)
            %WAVE Constructor for Wave class
            %
            % Initializes the wave object using properties from an
            % existing film object. Copies solver configuration and geometry
            % data, and allocates flow property arrays for multiple walls.
            %
            % Inputs:
            %
            % - film — :class:`Solvers.AbstractFilm` object representing the parent film

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
            %WL Wave mass flow rate per unit perimeter [kg/s/m]
            %
            % Calculates the mass flow carried by the wave field at specified
            % axial locations.
            %
            % Inputs:
            %
            % - wave  — :class:`Solvers.FourField.Wave` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            perim  = wave.inputSet.geometry.PERIM;

            wl = wave.W(zIdx,:)./perim;
        end

        function thick = THICK(wave, zIdx)
            %THICK Wave thickness [m]
            %
            % Computes the wave thickness as the product of amplitude and
            % interfacial fraction. This parameter represents the thickness
            % that the wave field would have if fully overlayed on top of
            % the base film.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            thick = wave.AMPLITUDE(zIdx) .* wave.BETA(zIdx);
        end

        function beta = BETA(wave, zIdx)
            %BETA Wave film interfacial fraction [-]
            %
            % Calculates the fraction of the interface occupied by waves.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            % TODO: add as model option later

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            beta = wave.WIDTH(zIdx) ./ wave.SPACING(zIdx);
            epsilon = wave.EPSILON(zIdx);
            beta(isnan(beta)) = epsilon(isnan(beta));

            % Apply BETA to distribution
            beta = wave.film.mix.AFDISTR(epsilon,beta,zIdx);
        end

        function epsilon = EPSILON(wave, zIdx)
            %EPSILON Wave mass flow fraction [-]
            %
            % Computes the fraction of total film mass flow carried by waves.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            epsilon = wave.W(zIdx, :) ./ wave.film.W(zIdx, :);
            epsilon(wave.W(zIdx,:)<=0) = 0.0;
        end

        function betap = BETAP(wave, zIdx)
            %BETAP Wave film heat flux fraction [-]
            %
            % Determines the fraction of heat flux directed to the waves.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            betap = 1-wave.film.base.BETAP(zIdx);
        end

        function eta = ETA(wave, zIdx)
            %ETA Wave film deposition fraction
            %
            % Computes the fraction of deposition attributed to waves.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            eta = 1-wave.film.base.ETA(zIdx);
        end

        function ment = MENT(wave,zIdx)
            %MENT Wave entrainment mass flux [kg/m^2/s]
            %
            % Computes the mass flux associated with entrainment from the wave field.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            ment = wave.film.MENT(zIdx) - wave.film.base.MENT(zIdx);
        end

        function mevap = MEVAP(wave, zIdx)
            %MEVAP Wave evaporation mass flux [kg/m^2/s]
            %
            % Calculates the evaporation mass flux from the wave field based on heat flux fraction.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            mevap = wave.BETAP(zIdx) .* wave.film.MEVAP(zIdx,:);
        end

        function mdep = MDEP(wave,drop,zIdx)
            %MDEP Wave deposition mass flux [kg/m^2/s]
            %
            % Computes the deposition mass flux from waves to droplets.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   drop — :class:`Solvers.FourField.Drop` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            mdep = wave.ETA(zIdx).*drop.MDEP(zIdx);
        end

        function mturb = MTURB(wave, zIdx)
            %MTURB Turbulent mass exchange [kg/m^2/s]
            %
            % Returns the turbulent mixing mass flux between wave and base film.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            mturb = wave.film.base.MTURB(zIdx);
        end

        function Mbase = MBASE(wave,drop,zIdx)
            %MBASE Mass flux interaction with base film [kg/m^2/s]
            %
            % Computes the net mass exchange between wave and base film, including turbulent mixing.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   drop — :class:`Solvers.FourField.Drop` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            % Net exchange term (eq. 32)
            [~, Mnet] = wave.film.base.MWAVE(drop,zIdx);

            % Base exchange + turbulent mixing term (eq.8)
            Mturb = wave.MTURB(zIdx);
            Mbase = max(-Mnet, 0) + Mturb;

            Mbase = wave.mix.AFDISTR(0,Mbase,zIdx);
        end

        function Mtot = MTOT(wave,drop,zIdx)
            %MTOT Total mass flux [kg/m^2/s]
            %
            % Calculates the total mass flux for the wave field, including evaporation,
            % entrainment, deposition, and interactions with base film.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   drop — :class:`Solvers.FourField.Drop` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            Mtot = wave.MEVAP(zIdx)+wave.MENT(zIdx)+wave.MDEP(drop,zIdx)+wave.MBASE(drop,zIdx)-wave.film.base.MWAVE(drop,zIdx);
        end

        function Fwall = FWALL(wave,zIdx)
            %FWALL Wave wall shear stress [N/m^2]
            %
            % Placeholder method. Wave does not implement wall shear stress.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            error('Wave does not implement wall shear stress');
        end

        function Fbase = FBASE(wave,drop,zIdx)
            %FBASE Base interfacial force [N/m^2]
            %
            % Computes the interfacial force between wave and base film.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   drop — :class:`Solvers.FourField.Drop` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            Fbase = -wave.film.base.FWAVE(drop,zIdx);

        end

        function Fbasemass = FBASEMASS(wave,drop,zIdx)
            %FBASEMASS Wave mass exchange force [N/m^2]
            %
            % Calculates the force due to mass exchange between wave and base film.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   drop — :class:`Solvers.FourField.Drop` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin <3, zIdx = (1:wave(1).NZ).'; end

            deltaU = wave.film.base.U(zIdx) - wave.U(zIdx);                % [m/s]
            Fbasemass = wave.MBASE(drop,zIdx).*deltaU;

            Fbasemass = wave.mix.AFDISTR(0,Fbasemass,zIdx);
        end

        function Fvapor = FVAPOR(wave,zIdx)
            %FVAPOR Wave vapor shear stress [N/m^2]
            %
            % Computes the total shear stress exerted by vapor on the wave field.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            Fvapor = wave.FDRAG(zIdx) + wave.FSHEAR(zIdx);
        end

        function Fdrag = FDRAG(wave,zIdx)
            %FDRAG Vapor drag force on wave [N/m^2]
            %
            % Calculates the shear stress due to vapor drag acting on the wave field.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

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
            %FSHEAR Vapor shear stress [N/m^2]
            %
            % Computes the shear stress exerted by vapor on the wave field using friction factor.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Friction factor
            f_v_w = wave.CV(zIdx);                                         % [-]

            % Saturated vapor density
            rho_vs = wave.fluid.RHOG;                                      % [kg/m^3]

            % Difference in wave and vapor velocities
            dU = wave.mix.vapor.U(zIdx) - wave.U(zIdx);                    % [m/s]

            % Eq. 46
            Fshear = 0.5 .* f_v_w .* rho_vs .* dU.^2;
            Fshear = wave.BETA(zIdx).*Fshear;
        end

        function Fdep = FDEP(wave,drop,zIdx)
            %FDEP Droplet interaction force [N/m^2]
            %
            % Calculates the force due to deposition of droplets onto the wave field.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   drop — :class:`Solvers.FourField.Drop` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            deltaU = drop.U(zIdx) - wave.U(zIdx,:);                        % [m/s]
            Fdep = wave.MDEP(drop,zIdx) .* deltaU;

            Fdep = wave.mix.AFDISTR(0,Fdep,zIdx);
        end

        function Ftot = FTOT(wave,drop,zIdx)
            %FTOT Total interfacial force [N/m^2]
            %
            % Computes the total interfacial force acting on the wave field, including
            % vapor shear, buoyancy, gravity, droplet interaction, and base film forces.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   drop — :class:`Solvers.FourField.Drop` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            Ftot = wave.FVAPOR(zIdx)+wave.FBUOY(zIdx)+wave.FGRAV(zIdx)+wave.FDEP(drop,zIdx)+wave.FBASE(drop,zIdx)+wave.FBASEMASS(drop,zIdx);
        end

        function shapefactor = SHAPEFACTOR(wave, zIdx)
            %SHAPEFACTOR Wave shape factor [-]
            %
            % Computes the dimensionless shape factor for waves based on Reynolds number
            % and :attr:`Inputs.Model.SHAPEFACTORCOEF` model.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            coef = wave.inputSet.model.SHAPEFACTORCOEF;
            shapefactor = (wave.RE(zIdx)./coef(1)).^coef(2);
        end

        function eqst = EQSTROUHAL(wave, zIdx)
            %EQSTROUHAL Equilibrium Strouhal number [-]
            %
            % Calculates the equilibrium Strouhal number using selected
            % :attr:`Inputs.Model.EQSTROUHAL` model.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

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
            %EQFREQUENCY Equilibrium wave frequency [Hz]
            %
            % Computes the equilibrium wave frequency based on Strouhal number and
            % vapor velocity.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Hydraulic diameter
            d_h = wave.inputSet.geometry.HDIAM;

            % Solve eqfreq using definition of St
            eqfreq = wave.EQSTROUHAL(zIdx).*wave.film.mix.vapor.U(zIdx)./d_h;
        end

        function eqperiod = EQPERIOD(wave, zIdx)
            %EQPERIOD Equilibrium wave period [s]
            %
            % Calculates the inverse of equilibrium wave frequency.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            eqperiod = 1./wave.EQFREQUENCY(zIdx);
        end

        function spacing = SPACING(wave, zIdx)
            %SPACING Wave spacing [m]
            %
            % Computes the axial spacing between waves based on velocity and frequency.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            spacing = wave.U(zIdx,:) ./ wave.FREQUENCY(zIdx,:);
        end

        function period = PERIOD(wave, zIdx)
            %PERIOD Wave time period [s]
            %
            % Calculates the inverse of wave frequency.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            period = 1./wave.FREQUENCY(zIdx, :);
        end

        function n = N(wave, zIdx)
            %N Wave number density [1/m]
            %
            % Computes the number of waves per unit length (inverse of wave spacing).
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            n = 1./ wave.SPACING(zIdx);
        end

        function wwidth = WIDTH(wave, zIdx)
            %WIDTH Wave width [m]
            %
            % Calculates wave width as a function of amplitude and shape factor,
            % limited by wave spacing.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            wwidth = wave.AMPLITUDE(zIdx)./wave.SHAPEFACTOR(zIdx);

            % if wwidth isnan, set to wave spacing
            spacing = wave.SPACING(zIdx);                                  % [m]
            wwidth(isnan(wwidth)) = spacing(isnan(wwidth));

            % Limit width to be no larger than the spacing
            wwidth = min(wwidth, wave.SPACING(zIdx));
        end

        function amp = AMPLITUDE(wave, zIdx)
            %AMPLITUDE Wave amplitude [m]
            %
            % Computes wave amplitude based on mass flow, shape factor, fluid density,
            % and frequency. Limited by half the hydraulic diameter.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            rhof = wave.fluid.RHOF;                                        % [kg/m^3]
            amp = (wave.WL(zIdx).* wave.SHAPEFACTOR(zIdx))./(rhof.* wave.FREQUENCY(zIdx,:));
            amp = sqrt(abs(amp));

            % Limit amp+base.thick to 1/2 of D_H, at most
            D_H = wave.inputSet.geometry.HDIAM;                            % [m]
            amp = min(amp, D_H/2-wave.film.base.THICK(zIdx));
        end

        function deltafreq = DELTAFREQ(wave, zIdx)
            %DELTAFREQ Wave frequency source/sink [Hz/m]
            %
            % Calculates the exchange term for wave frequency relaxation toward
            % equilibrium frequency.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            relaxTW = wave.inputSet.model.RELAXTW;                         % [s]
            deltafreq = (wave.EQFREQUENCY(zIdx)-wave.FREQUENCY(zIdx,:))./wave.U(zIdx,:)./relaxTW;

            deltafreq = wave.mix.AFDISTR(0,deltafreq,zIdx);
        end

        function rev = REV(wave, zIdx)
            %REV Vapor Reynolds number (relative to waves) [-]
            %
            % Computes the Reynolds number for vapor flow interacting with waves.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Coefficients
            coefs = wave.inputSet.model.WAVEDRAGCOEF;                      % [-]

            % Vapor Reynolds number (Eq. 64)
            rho_vs = wave.fluid.RHOG;                                      % [kg/m^3]
            du = wave.film.mix.vapor.U(zIdx) - wave.U(zIdx,:);             % [m/s]
            mu_vs = wave.fluid.MUG;                                        % [Pa.s]
            rev = rho_vs .* du .* coefs(1) ./mu_vs;
        end

        function dragcoef = DRAGCOEF(wave, zIdx)
            %DRAGCOEF Wave drag coefficient [-]
            %
            % Calculates the drag coefficient for vapor-wave interaction based on
            % Reynolds number and :attr:`Inputs.Model.WAVEDRAGCOEF` model coefficients.
            %
            % Inputs:
            %   wave — :class:`Solvers.FourField.Wave` object
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Coefficients
            coefs = wave.inputSet.model.WAVEDRAGCOEF;                      % [-]

            % Vapor Reynolds number (Eq. 64)
            Re_vw = wave.REV(zIdx);                                        % [-]

            % Draf Coef (Eq. 63)
            dragcoef = (coefs(2)./Re_vw).^2 + coefs(3);
        end

    end

end
