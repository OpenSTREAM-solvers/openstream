classdef Base < Solvers.AbstractFilm
    %BASE Class for modeling liquid base film in four-field solver
    %
    % This class represents the physical and numerical properties of the
    % base film field in a four-field thermal-hydraulic solver.
    % It handles flow variables, heat transfer, and phase interaction
    % mechanisms between the base film and other fields (wave, drop, vapor).
    %
    % The class supports initialization from an existing film object and
    % provides methods for computing derived quantities such as mass flow
    % fractions, interfacial fractions, and deposition/evaporation fluxes.

    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})

        % Solver properties
        NZ                                                                 = 0                    % Number of axial steps [-] from :attr:`Inputs.Model.NNODES`
        NTIME                                                              = 0                    % Number of time steps [-]
        TIME                                                               = 0                    % Time series [s]
        DT                                                                 = 0                    % Time step size [s] from :attr:`Inputs.InputSet.options.TSTEP`
        TIDX                                                               = 1                    % Time step index [-]
        Z                                                                  = 1.                   % Elevation [m]
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % Film heat flux [W/m^2]

        % Flow properties
        W            (:,:) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        U            (:,:) double  {mustBeNumeric}                         = 1.                   % Velocity [m/s]
        H            (:,:) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]

        % Iteration properties
        ITR

    end

    properties (SetAccess=?Solvers.AbstractField, GetAccess=?Solvers.AbstractPhase)

        film

    end

    methods

        function base = Base(film)
            %BASE Constructor for Base class
            %
            % Initializes the base film object using properties from an
            % existing film object. Copies solver configuration and geometry
            % data, and allocates flow property arrays for multiple walls.
            %
            % Inputs:
            %
            % - film — :class:`Solvers.AbstractFilm` object representing the parent film


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
            %EPSILON Base film mass flow fraction [-]
            %
            % Calculates the fraction of total film mass flow carried by the
            % base film at specified axial locations.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            epsilon = base.W(zIdx,:) ./ base.film.W(zIdx,:);

            % epsilon is NaN if film.W == 0, i.e. dry
            % in this case, deposit on base
            % TODO: In NEGFILM case ...
            epsilon(isnan(epsilon)) = 1.0;
        end

        function beta = BETA(base, zIdx)
            %BETA Base film interfacial fraction [-]
            %
            % Computes the fraction of interfacial area attributed to the
            % base film.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % TODO: add as model option later
            beta = 1-base.film.wave.BETA(zIdx);
        end

        function betap = BETAP(base, zIdx)
            %BETAP Base film heat flux fraction [-]
            %
            % Determines the fraction of heat flux directed to the base film.
            % Applies suppression in pre-annular region to enforce target
            % base film thickness at onset of annular flow (OAF).
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Notes:
            %
            % - Applies suppression in pre-annular region to enforce target base film thickness at onset of annular flow (OAF). The entire film evaporation hence occurs in the wave field.

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % assuming split according to interfacial fraction, BETA
            % TODO: add as model option later
            betap = base.BETA(zIdx);

            betap = base.mix.AFDISTR(0,betap,zIdx);                        % Suppress heat flux in pre-annular region
        end

        function eta = ETA(base, zIdx)
            %ETA Base film deposition fraction [-]
            %
            % Computes the fraction of drop deposition allocated to the base
            % film based on mass flow and interfacial fractions.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % TODO: add as model option later
            eta = base.EPSILON(zIdx).*base.BETA(zIdx);
        end

        function ment = MENT(base, zIdx)
            %MENT Base entrainment mass flux [kg/m^2/s]
            %
            % Placeholder for future implementation if needed. Currently
            % returns zero entrainment.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % TODO: use coefficient later
            ment =  0.0 .* base.film.MENT(zIdx);
        end

        function mevap = MEVAP(base, zIdx)
            %MEVAP Base evaporation mass flux [kg/m^2/s]
            %
            % Computes evaporation flux from the base film using heat flux
            % fraction and parent film evaporation rate.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            mevap = base.BETAP(zIdx) .* base.film.MEVAP(zIdx,:);
        end

        function mdep = MDEP(base,drop,zIdx)
            %MDEP Base deposition mass flux [kg/m^2/s]
            %
            % Calculates deposition flux to the base film from drops,
            % scaled by deposition fraction.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            mdep = base.ETA(zIdx).*drop.MDEP(zIdx);
        end

        function Mturb = MTURB(base, zIdx)
            %MTURB Turbulent mass exchange [kg/m^2/s]
            %
            % Estimates turbulent mass exchange between base and wave films
            % using wave mixing coefficient :attr:`Inputs.Model.WAVEMIXCOEF`.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            wave = base.film.wave;
            Kw_recp = base.inputSet.model.WAVEMIXCOEF;
            Mturb = min(abs(base.WL(zIdx)), wave.WL(zIdx)) ./ Kw_recp ./ wave.WIDTH(zIdx);
            Mturb = min(Mturb,10);
            Mturb = base.mix.AFDISTR(0,Mturb,zIdx);
        end

        function [Mwave, Mnet] = MWAVE(base,drop,zIdx)
            %MWAVE Base film mass flux interaction with wave [kg/m^2/s]
            %
            % Computes the mass flux exchange between the base film and wave field.
            % Includes net exchange term based on relaxation toward equilibrium
            % thickness and turbulent mixing contribution.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)
            %
            % Outputs:
            %
            % - Mwave — Mass flux transferred to wave field [kg/m^2/s]
            % - Mnet  — Net exchange term before turbulent adjustment [kg/m^2/s]

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            %TODO: implement model selection options

            % Saturated liquid density
            rho_ls = base.fluid.RHOF;
            % Relaxation term
            relaxTB = base.inputSet.model.RELAXTB;

            % Net exchange term (eq. 32)
            Mnet = -base.MEVAP(zIdx)-base.MENT(zIdx)-base.MDEP(drop,zIdx)+rho_ls.*(base.EQTHICK(zIdx)-base.THICK(zIdx))./relaxTB;

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
            %MTOT Total mass flux of the base film [kg/m^2/s]
            %
            % Calculates the total mass flux exchange associated with the base film,
            % including evaporation, entrainment, deposition, and wave interaction.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            Mtot  = base.MEVAP(zIdx)+base.MENT(zIdx)+base.MDEP(drop,zIdx)+base.MWAVE(drop,zIdx)-base.film.wave.MBASE(drop,zIdx);
        end

        function Fwave = FWAVE(base,drop,zIdx)
            %FWAVE Wave interfacial force [N/m^2]
            %
            % Computes the interfacial shear force exerted by the wave field on the
            % base film based on :attr:`Inputs.Model.WAVEBASEINT` model.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            switch base.inputSet.model.WAVEBASEINT
                case 'VAPORSHEAR'
                    Fwave = base.film.wave.BETA(zIdx).*base.FVAPOR(zIdx);  % [N/m^2]
                case 'VAPORSHEARDROPMASS'
                    Fwave = base.film.wave.BETA(zIdx).*base.FVAPOR(zIdx) + base.film.wave.FDEP(drop,zIdx); % [N/m^2]
            end
        end

        function Fwavemass = FWAVEMASS(base,drop,zIdx)
            %FWAVEMASS Base-wave mass exchange force [N/m^2]
            %
            % Calculates the momentum exchange force due to mass transfer between
            % base and wave films, based on velocity difference and MWAVE flux.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            deltaU = base.film.wave.U(zIdx) - base.U(zIdx);
            Fwavemass = base.MWAVE(drop,zIdx).*deltaU; % [N/m^2]

            Fwavemass = base.mix.AFDISTR(0,Fwavemass,zIdx);
        end

        function Fbasevapor = FBASEVAPOR(base,zIdx)
            %FBASEVAPOR Vapor shear stress on base film [N/m^2]
            %
            % Computes the shear force exerted by the vapor phase on the base film,
            % scaled by interfacial fraction.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

            %   TODO: consider different way of doing this...

            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % TODO: debug syntax
            Fbasevapor = base.BETA(zIdx).* base.FVAPOR(zIdx);              % [N/m^2]
        end

        function Fdep = FDEP(base,drop,zIdx)
            %FDEP Droplet deposition force [N/m^2]
            %
            % Calculates the momentum transfer to the base film from droplet
            % deposition, based on velocity difference and deposition flux.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            deltaU = drop.U(zIdx) - base.U(zIdx,:);
            Fdep = base.MDEP(drop,zIdx) .* deltaU;                         % [N/m^2]

            Fdep = base.mix.AFDISTR(0,Fdep,zIdx);
        end

        function Ftot = FTOT(base,drop,zIdx)
            %FTOT Total interfacial force on base film [N/m^2]
            %
            % Aggregates all force contributions acting on the base film, including
            % wall shear, wave interaction, vapor shear, buoyancy, gravity, and
            % droplet deposition based on :attr:`Inputs.Model.MOMENTBASE` model.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            switch base.inputSet.model.MOMENTBASE
                case 'FULLNOP'
                    Ftot  = base.FWALL(zIdx)+base.FWAVE(drop,zIdx)+base.FWAVEMASS(drop,zIdx)+base.FBASEVAPOR(zIdx)+base.FDEP(drop,zIdx);
                otherwise
                    Ftot  = base.FWALL(zIdx)+base.FWAVE(drop,zIdx)+base.FWAVEMASS(drop,zIdx)+base.FBASEVAPOR(zIdx)+base.FBUOY(zIdx)+base.FGRAV(zIdx)+base.FDEP(drop,zIdx);
            end
        end

        function eqthick = EQTHICK(base,zIdx)
            %EQTHICK Base equilibrium thickness [m]
            %
            % Computes the equilibrium thickness of the base film based on
            % :attr:`Inputs.Model.BASEEQTHICK` model.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

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
                    yplus = base.inputSet.model.BASEYPLUS;
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
            %TBASE Base film exposure time [s]
            %
            % Calculates the time during which the base film is exposed to vapor
            % between successive waves, based on wave spacing and relative velocity
            % (eq 24 of :cite:t:`LECORREMODEL`).
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - zIdx  — Axial indices to evaluate (optional)

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
            %TDRY Base film dry-out time [s]
            %
            % Estimates the time of base film dry out under current
            % evaporation and deposition conditions. Returns zero if dry-out does
            % not occur.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            per = base.inputSet.geometry.PERIM;
            Wb = base.W(zIdx,:);
            Ub = base.U(zIdx,:);
            DeltaM=-base.MEVAP(zIdx) - base.MDEP(drop,zIdx);
            betaB = base.BETA(zIdx);

            tdry = base.TBASE(zIdx) - Wb.*betaB./per./Ub./DeltaM;
            tdry(DeltaM<=0) = 0;
            % If dry out doesn't occur, set to 0.
            tdry = max(tdry, 0);
        end

        function fdry = FDRY(base, drop, zIdx)
            %FDRY Dry fraction [-]
            %
            % Computes the fraction of the exposure period during which the base
            % film is expected to be dry.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            tbase = base.TBASE(zIdx);
            fdry = base.TDRY(drop, zIdx)./tbase;

            % If the base is never exposed (tbase==0), fdry is 0 by definition.
            fdry(tbase==0) = 0;
        end

        function wmin = WMIN(base, drop, zIdx)
            %WMIN Minimum base film mass flow rate [kg/s]
            %
            % Calculates the minimum mass flow rate of the base film at the end of
            % its exposure period (TBASE), accounting for evaporation and deposition.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            per = base.inputSet.geometry.PERIM;
            Wb = base.W(zIdx,:);
            Ub = base.U(zIdx,:);
            DeltaM=-base.MEVAP(zIdx) - base.MDEP(drop,zIdx);
            Betab = base.BETA(zIdx);
            wmin = Wb-per.*Ub.*DeltaM./Betab.*base.TBASE(zIdx);

            % When Betab == 0, Wmin is Wb
            wmin(Betab==0) = Wb(Betab==0);

            wmin = max(wmin, 0);
        end

        function wminl = WMINL(base, drop, zIdx)
            %WMINL Minimum base film mass flow rate per perimeter [kg/m-s]
            %
            % Computes the minimum base film mass flow rate normalized by channel
            % perimeter.
            %
            % Inputs:
            %
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            wminl = base.WMIN(drop, zIdx) ./ base.inputSet.geometry.PERIM;
        end

        function thickmin = THICKMIN(base, drop, zIdx)
            %THICKMIN Minimum base film thickness [m]
            %
            % Calculates the minimum thickness of the base film at the end of its
            % exposure period, based on mass flow rate, liquid density, velocity,
            % and channel perimeter (eq. 28 of :cite:t:`LECORREMODEL`).
            %
            % Inputs:
            % - base  — :class:`Solvers.FourField.Base` object
            % - drop  — :class:`Solvers.FourField.Drop` object
            % - zIdx  — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            rho_ls = base.fluid.RHOF;
            Ub = base.U(zIdx,:);
            per = base.inputSet.geometry.PERIM;

            thickmin = base.WMIN(drop, zIdx)./(rho_ls.*Ub.*per);
        end

        function copyFlowProperties(srcObj, targetObj, opts)
            %COPYFLOWPROPERTIES Copy flow property arrays between Base objects
            %
            % Copies selected flow properties (W, U, H) from a source object to one
            % or more target Base objects. Supports full copy or partial copy
            % (excluding first axial node) based on options.
            %
            % Inputs:
            % - srcObj     — Source object containing flow properties
            % - targetObj  — Array of :class:`Solvers.FourField.Base` objects to update
            % - opts.all   — Logical flag; if true, copies all axial nodes, otherwise skips the first node (default: false)

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
