classdef Film < Solvers.AbstractFilm
    %FILM Class for modeling liquid film in four-field solver
    %
    % Represents the physical and numerical properties of the liquid film in a
    % four-field thermal-hydraulic solver. The film consists of two sub-fields:
    % base film and wave film, which interact with vapor and droplet phases.
    %
    % This class manages initialization, mass flow distribution, velocity and
    % enthalpy calculations, and provides methods for splitting film flow at
    % the onset of annular flow (OAF) according to model options.
    %
    % Key responsibilities:
    %
    % - Store solver state (time, axial positions, heat flux, evaporation flux)
    % - Aggregate flow properties from base and wave components
    % - Initialize base and wave fields and apply OAF split logic
    % - Support equilibrium calculations for film thickness and flow ratios

    properties (SetAccess={?Solvers.AbstractSolver, ?Solvers.AbstractField})

        % Solver state
        NZ                                                                 = 0                    % Number of axial steps [-]
        NTIME                                                              = 0                    % Number of time steps [-]
        TIME                                                               = 0                    % Time series [s]
        DT                                                                 = 0                    % Time step size [s]
        TIDX                                                               = 1                    % Time step index [-]
        Z                                                                  = 1.                   % Elevation [m]
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % Film heat flux [W/m^2]
        MEVAP        (:,:) double  {mustBeNumeric,mustBeNonpositive}       =-1.                   % Evaporation mass flux [kg/s/m^2]

        % Iteration properties
        ITR

    end

    properties (SetAccess=?Solvers.AbstractSolver)

        wave           (1,1)         {isa(wave,'Solvers.FourField.Wave')}   = NaN                  % :class:`Solvers.FourField.Wave` object
        base           (1,1)         {isa(base,'Solvers.FourField.Base')}   = NaN                  % :class:`Solvers.FourField.Base` object

    end

    properties (Dependent)

        % Flow properties
        W            %(:,:) double  {mustBeNumeric}                         = 1.                   % Mass flow rate [kg/s]
        U            %(:,:) double  {mustBeNumeric}                         = 1.                   % Velocity [m/s]
        H            %(:,:) double  {mustBeNumeric}                         = 1E6                  % Enthalpy [J/kg]

    end


    methods

        function film = Film(inputSet, fluid)
            %FILM Creates a Film object
            %
            % Initializes the film object with input set and fluid properties required
            % by the four-field solver.
            %
            % Inputs:
            %   inputSet — :class:`Inputs.InputSet` object containing geometry and model options
            %   fluid    — :class:`Inputs.Fluid` object containing thermophysical properties

            if nargin > 0
                % Store inputSet as object property
                film.inputSet = inputSet;
                film.fluid  = fluid;
            end
        end

        function w = get.W(film)
            %W Film mass flow rate [kg/s]
            %
            % Computes the total film mass flow rate as the sum of base and wave mass flow
            % rates across all walls.
            %
            % Inputs:
            %   film — :class:`Solvers.FourField.Film` object

            w = film.base.W + film.wave.W;
        end

        function h = get.H(film)
            %H Film enthalpy [J/kg]
            %
            % Returns the film specific enthalpy. Currently assumes the film enthalpy
            % equals the base-film enthalpy.
            %
            % Inputs:
            %   film — :class:`Solvers.FourField.Film` object

            h = film.base.H;
        end

        function u = get.U(film)
            %U Mass-weighted film velocity [m/s]
            %
            % Computes a mass-consistent film velocity using base and wave contributions.
            % Falls back to base velocity where total film mass flow is zero.
            %
            % Inputs:
            %   film — :class:`Solvers.FourField.Film` object

            %TODO: a more appropriate value may be needed for film velocity.

            %u = (film.base.W.*film.base.U + film.wave.W.*film.wave.U)./film.W;
            u = film.W./(film.base.W./film.base.U + film.wave.W./film.wave.U);
            u(film.W==0) = film.base.U(film.W==0);
        end

        function eb = distributeOAFW(film, Wf, zIdx)
            %DISTRIBUTEOAFW Distribute film mass flow at OAF [kg/s]
            %
            % Distributes the film mass flow rate at the onset of annular flow (OAF)
            % between base and wave fields according to the
            % :attr:`Inputs.Model.OAFFILMSPLIT` model option.
            %
            % Inputs:
            %   film — :class:`Solvers.FourField.Film` object
            %   Wf   — Film mass flow rate to distribute [kg/s] (per wall or per z-index)
            %   zIdx — Axial indices to apply distribution (optional)

            if nargin < 3, zIdx = (1:film(1).NZ).'; end

            model = film.inputSet.model;

            switch model.OAFFILMSPLIT
                case InputEnums.OAFFILMSPLIT.RATIO
                    eb = model.OAFBASERATIO;
                case InputEnums.OAFFILMSPLIT.EQUILIBRIUM
                    eb = film.EQUIL(Wf, zIdx);
            end
            if isscalar(zIdx) && size(Wf,1)~=1
                error('Film.DISTRIBUTEOAFW: Matrix W cannot be used with scalar zIdx');
            elseif ~isscalar(zIdx) && size(Wf,1)~=length(zIdx)
                error('Film.DISTRIBUTEOAFW: Matrix W and zIdx size mismatch');
            elseif ~isscalar(zIdx) && size(Wf,1)==1
                Wf = repmat(Wf,length(zIdx),1);                            % [kg/s]
            end

            if ~isobject(film.wave) || ~isobject(film.base)
                error('Film.DISTRIBUTEOAFW: base or wave not initialized');
            end

            film.wave.W(zIdx,:) = (1-eb) .* Wf;                            % [kg/s]
            film.base.W(zIdx,:) = eb .* Wf;                                % [kg/s]
        end

        function eb = EQUIL(film, Wf, zIdx)
            %EQUIL Equilibrium base/wave split ratio [-]
            %
            % Calculates the equilibrium split ratio of film mass flow between base
            % and wave using base equilibrium thickness, base velocity, perimeter,
            % and liquid density.
            %
            % Inputs:
            %   film — :class:`Solvers.FourField.Film` object
            %   Wf   — Film mass flow rate [kg/s]
            %   zIdx — Axial indices to evaluate (optional)

            if nargin < 3, zIdx = (1:film(1).NZ); end
            zIdx = zIdx(:);

            perim = film.inputSet.geometry.PERIM;                          % [m] Perimeter
            eqthick_b = film.base.EQTHICK(zIdx);                           % [kg/s] Base equilibrium thickness

            Wb = eqthick_b .* film.base.U(zIdx) .* perim .* film.base.fluid.RHOF;  % [kg/s] Base mass flow rate
            eb = Wb./Wf;
            eb = min(eb,1);

        end

        function initializeBaseAndWave(film, WIN, ITR)
            %INITIALIZEBASEANDWAVE Initialize base and wave fields
            %
            % Initializes base and wave arrays given inlet film mass flow rate and
            % iteration settings. Performs OAF film split, computes velocities,
            % enthalpies, and sets initial wave frequency using equilibrium correlations.
            %
            % Inputs:
            %   film — :class:`Solvers.FourField.Film` object
            %   WIN  — Inlet film mass flow rate [kg/s]
            %   ITR  — Iteration control struct

            %% Constant properties

            % Create base, wave and set film reference
            if ~isobject(film.base), film.base = Solvers.FourField.Base(film); end
            if ~isobject(film.wave), film.wave = Solvers.FourField.Wave(film); end

            % Stop if no input arguments (except film)
            if nargin == 1
                return
            end

            %% Mass flow rate and velocity

            model = film.inputSet.model;
            geom  = film.inputSet.geometry;

            % [kg/s] Distribute film at inlet uniformly on all walls
            film.base.W(1,1:geom.NWALL) = WIN.*geom.PERIM./sum(geom.PERIM); % [kg/s]

            % [kg/s] Apply simple mass conservation, all evaporation in base film for now
            film.base.W = film.base.W(1,:)+cumsum(film.MEVAP).*geom.PERIM.*film.DZ; % [kg/s]

            % Limit film mass flux minimum to 0 [kg/s], all liquid in base film for now
            film.base.W = max(0, film.base.W);                             % [kg/s]
            film.wave.W = 0.*film.base.W;                                  % [kg/s]

            % Velocity
            film.base.U = film.UALGEBR();                                  % [m/s] Base velocity
            film.wave.U = film.base.U;                                     % [m/s] Wave velocity

            % Distribute film between base and wave (order matters)
            % Film mass flow rate at onset of annular flow
            film.distributeOAFW(film.base.W);

            % Set minimum of wave velocity to 1 m/s
            % TODO: Maybe revisit in the future...
            % film.wave.U(film.wave.U<1) = 1.0;
            film.wave.U(:,:) = repmat(film.mix.vapor.U .* 0.5, 1, geom.NWALL); % [m/s]

            % Initialize enthalpy [J/kg] by number of spatial nodes, NZ
            film.base.H = repmat(film.fluid.HF, film.NZ, 1);               % [J/kg]
            film.wave.H = film.base.H;                                     % [J/kg]

            % Initialize wave period using wave.EQPERIOD
            %TODO: consider using wave number density
            film.wave.FREQUENCY(1:film.NZ,1:geom.NWALL) = film.wave.EQFREQUENCY(); % [Hz]
            oafIdx = film.mix.OAFIDX;
            film.wave.FREQUENCY(1:oafIdx,1:geom.NWALL) = repmat(film.wave.EQFREQUENCY(oafIdx),oafIdx,1); % [Hz]

            % Setup iteration struct
            film.base.ITR = ITR;
            film.wave.ITR = ITR;
        end

        function copyFlowProperties(srcObj, targetObj, opts)
            %COPYFLOWPROPERTIES Copy flow properties between Film objects
            %
            % Copies flow-related properties (base and wave fields) from a source Film
            % object to one or more target Film objects. Ensures that spatial meshes
            % match before copying.
            %
            % Inputs:
            %   srcObj    — Source :class:`Solvers.FourField.Film` object
            %   targetObj — Target :class:`Solvers.FourField.Film` object(s)
            %   opts.all  — Logical flag to copy all properties (optional, default = false)

            arguments
                srcObj
                targetObj (1,:) Solvers.FourField.Film
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

                % Copy base and wave
                propNames = {'base', 'wave'};
                for j = 1:length(propNames)
                    % Copy base and wave flow properties
                    srcObj.(propNames{j}).copyFlowProperties(targetObj(i).(propNames{j}));
                end
            end
        end

    end

    methods (Access = protected)

        function cp = copyElement(film)
            %COPYELEMENT Customized copy method for Film object
            %
            % Creates a deep copy of the Film object, including its base and wave
            % sub-objects. Updates references so that copied sub-objects point to the
            % new Film instance.
            %
            % Inputs:
            %   film — :class:`Solvers.FourField.Film` object

            % Shallow copy film
            cp = copyElement@matlab.mixin.Copyable(film);

            % Deep copy of film base and wave
            propNames = {'base', 'wave'};
            for j = 1:length(propNames)
                % Make shallow copy of base and wave
                cp.(propNames{j}) = copy(cp.(propNames{j}));
                % Reference film to srcObj
                cp.(propNames{j}).film = cp;
            end
        end

    end

end

