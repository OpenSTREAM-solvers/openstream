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
        
        wave           (1,1)         {isa(wave,'Solvers.FourField.Wave')}   = Solvers.FourField.Wave()
        base           (1,1)         {isa(base,'Solvers.FourField.Base')}   = Solvers.FourField.Base() 
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
            u = (film.base.W.*film.base.U + film.wave.W.*film.wave.U)./film.W;

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
                
                % TODO: copy wave and base?
                % % Copy properties
                % propNames = {'W','U','H'};
                % for j = 1:length(propNames)
                %     if opts.all
                %         targetObj(1).(propNames{j}) = srcObj.(propNames{j});
                %     else
                %         targetObj(1).(propNames{j})(2:end) = srcObj.(propNames{j})(2:end);
                %     end
                % end


            end

        end
    
    end

    

end

