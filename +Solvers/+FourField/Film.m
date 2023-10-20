classdef Film < Solvers.AbstractFilm
    %FILM Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=?Solvers.AbstractSolver)
        
        % Solver properties
        NZ                                                                 = 0                    % [-] Number of axial steps
        NTIME                                                              = 0                    % [-] Number of time steps
        TIME                                                               = 0                    % [s] Time series
        DT                                                                 = 0                    % [s] Time step size
        TIDX                                                               = 1                    % [-] Time step index
        Z                                                                  = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Film heat flux
        MEVAP        (:,:) double  {mustBeNumeric,mustBeNonpositive}       =-1.                   % [kg/s/m^2] Evaporation mass flux

        % Iteration properties
        ITR
     end

     properties (SetAccess=?Solvers.AbstractSolver)
        wave           (1,1)         {isa(wave,'Solvers.FourField.Wave')}   = NaN
        base           (1,1)         {isa(base,'Solvers.FourField.Base')}   = NaN
     end

     properties (Dependent)

        % Flow properties
        W            %(:,:) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            %(:,:) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            %(:,:) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy

     end

     
    methods
        function film = Film(inputSet, fluid)
            %FILM Creates a Film, film
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                film.inputSet = inputSet;
                film.fluid  = fluid;
            end
        end

        function w = get.W(film)

            w = film.base.W + film.wave.W;

        end

        function h = get.H(film)
        %H Enthalpy of the film
        %   Assuming

            h = film.base.H;
        end

        function u = get.U(film)
        %U Mass-weighted film velocity

            %TODO: a more appropriate value may be needed for film velocity.
            %u = (film.base.W.*film.base.U + film.wave.W.*film.wave.U)./film.W;
            u = film.W./(film.base.W./film.base.U + film.wave.W./film.wave.U);
            u(film.W==0) = film.base.U(film.W==0);
        end

        function distributeOAFW(film, W, zIdx)
        % DISTRIBUTEOAFW Distributes film mass flow rate at onset of 
        % annular flow to base and wave, based on option: OAFFILMSPLIT

        if nargin < 3, zIdx = (1:film(1).NZ).'; end

        model = film.inputSet.model;

        switch model.OAFFILMSPLIT
            case InputEnums.OAFFILMSPLIT.RATIO
                eb = model.OAFBASERATIO;
        end
        if isscalar(zIdx) && size(W,1)~=1
            error('Film.DISTRIBUTEOAFW: Matrix W cannot be used with scalar zIdx');
        elseif ~isscalar(zIdx) && size(W,1)~=length(zIdx)
            error('Film.DISTRIBUTEOAFW: Matrix W and zIdx size mismatch');
        elseif ~isscalar(zIdx) && size(W,1)==1
            W = repmat(W,length(zIdx),1);
        end
        
        if ~isobject(film.wave) || ~isobject(film.base)
            error('Film.DISTRIBUTEOAFW: base or wave not initialized');
        end

        film.wave.W(zIdx,:) = (1-eb) .* W;
        film.base.W(zIdx,:) = eb .* W;

    end
        
        function initializeBaseAndWave(film, WIN, ITR)
        %INITIALIZEBASEANDWAVE Initialize base and wave arrays given WTOT
            
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
            geom = film.inputSet.geometry;

            % [kg/s] Distribute film at inlet uniformly on all walls
            film.base.W(1,1:geom.NWALL) = WIN.*geom.PERIM./sum(geom.PERIM);

            % [kg/s] Apply simple mass conservation
            film.base.W = film.base.W(1,:)+cumsum(film.base.MEVAP).*geom.PERIM.*film.DZ;
            
            % Limit film mass flux minimum to 0 [kg/s]
            film.base.W = max(0, film.base.W);

            % Distribute film between base and wave (order matters)
            % Film mass flow rate at onset of annular flow
            film.distributeOAFW(film.base.W);

            % Velocity
            film.base.U = film.UALGEBR();                                   % [m/s] Base velocity
            film.wave.U = film.base.U;                                      % [m/s] Wave velocity

            % Set minimum of wave velocity to 1 m/s
            % TODO: Maybe revisit in the future...
            % film.wave.U(film.wave.U<1) = 1.0;
            film.wave.U(:,:) = repmat(film.mix.vapor.U .* 0.5, 1, geom.NWALL);

            % Initialize enthalpy [J/kg] by number of spatial nodes, NZ
            film.base.H = repmat(film.fluid.HF, film.NZ, 1);
            film.wave.H = film.base.H;

            % Initialize wave period using wave.EQPERIOD
            %TODO: consider using wave number density
            film.wave.FREQUENCY(1:film.NZ,1:geom.NWALL) = film.wave.EQFREQUENCY();

            % Setup iteration struct
            film.base.ITR = ITR;
            film.wave.ITR = ITR;

        end
               
        function copyFlowProperties(srcObj, targetObj, opts)
        %COPYFLOWPROPERTIES
        %
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
      %COPYELEMENT Customized copy method to copy base and wave handles

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

