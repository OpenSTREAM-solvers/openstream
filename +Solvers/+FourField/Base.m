classdef Base < Solvers.AbstractFilm
    %BASE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess={?Solvers.AbstractFilm,?Solvers.AbstractSolver})
        
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

     properties (SetAccess=?Solvers.AbstractSolver, GetAccess=?Solvers.AbstractPhase)

        film

     end

     properties (Dependent)
         MEVAP                                                                                    % [kg/s/m^2] Evaporation mass flux
     end

     
    methods
        function base = Base(inputSet, fluid, film)
            %BASE Creates a Base, base
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                base.inputSet = inputSet;
                base.fluid  = fluid;
                base.film  = film;
            end
        end

        function epsilon = EPSILON(base)
        %BETA Base film mass flow fraction
        %
            epsilon = base.W ./ base.film.W;
        end
        
        function beta = BETA(base)
        %BETA Base film interfacial fraction
        %
            % TODO: for now, assume no wave
            % TODO: add as model option later
            beta = 1;
        end

        function betap = BETAP(base)
        %BETAP Base film heat flux fraction
        %
            % assuming split according to interfacial fraction, BETA
            % TODO: add as model option later
            betap = base.BETA;
        end
        
        function ment = MENT(base,mix,zIdx)
        %MENT Base entrainment mass flux
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            % TODO: use coefficient later
            ment =  1 .* base.film.MENT(mix,zIdx);            
        end

        function mevap = get.MEVAP(base)
        %MEVAP Base evaporation mass flux
        %            
            mevap = base.BETAP() .* base.film.MEVAP;            
        end

        function eta = ETA(base)
        %ETA Base film deposition fraction
        %
            % TODO: for now, assume no wave
            % TODO: add as model option later
            eta = 1;
        end
        
        function Mtot = MTOT(base,mix,drop,zIdx)
        %MTOT Total
        %
            if nargin < 4, zIdx = (1:base(1).NZ).'; end
            
            % TODO: 
            Mtot  = base.MEVAP(zIdx,:)+base.MENT(mix,zIdx)+ base.ETA().*drop.MDEP(mix,zIdx);
        end
        
        function Fwave = FWAVE(base,mix,zIdx)
        %FWAVE Wave force
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            %TODO: add model option
            Fwave = base.film.wave.BETA().*base.FVAPOR(mix,zIdx); % [N/m^2]
            
        end

        function Fvapor = FVAPOR(base,mix,zIdx)
        %FVAPOR Film vapor shear stress
        %
            
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            % TODO: debug syntax
            Fvapor = base.BETA().* FVAPOR@Solvers.AbstractFilm(base,mix,zIdx); % [N/m^2]
            
        end

        function Ftot = FTOT(base,mix,drop,zIdx)
        %FTOT Total
        %
            if nargin < 4, zIdx = (1:base(1).NZ).'; end
            
            Ftot  = base.FWALL(mix,zIdx)+base.FWAVE(mix,zIdx)+base.FVAPOR(mix,zIdx)+base.FBUOY(mix,zIdx)+base.FGRAV(mix,zIdx)+base.FDEP(mix,drop,zIdx);   
            
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

