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
                % Store inputSet as object property
                base.inputSet = film.inputSet;
                base.fluid  = film.fluid;
                base.film  = film;

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
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % assuming split according to interfacial fraction, BETA
            % TODO: add as model option later
            betap = base.BETA(zIdx);

        end
        
        function ment = MENT(base, zIdx)
        %MENT Base entrainment mass flux
        %
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

        function eta = ETA(base, zIdx)
        %ETA Base film deposition fraction
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end

            % TODO: add as model option later
            eta = base.EPSILON(zIdx).*base.BETA(zIdx);
        end
        
        function Mwave = MWAVE(base,drop,zIdx)
        %MWAVE Mass flux interaction with wave
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end

            rho_ls = base.fluid.RHOF;
            relaxTB = base.inputSet.model.RELAXTB;
            Mwave = -base.MEVAP(zIdx)-base.MENT(zIdx)-base.ETA(zIdx).*drop.MDEP(zIdx)+rho_ls.*(base.EQTHICK(zIdx)-base.THICK(zIdx))./relaxTB;
            
            Mwave = base.film.mix.AFDISTR(0,Mwave,zIdx);
        end
        
        function Mtot = MTOT(base,drop,zIdx)
        %MTOT Total
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            % TODO: potentially move the MDEP method
            Mtot  = base.MEVAP(zIdx)+base.MENT(zIdx)+base.ETA(zIdx).*drop.MDEP(zIdx)+base.MWAVE(drop,zIdx);

        end
        
        function Fwave = FWAVE(base,zIdx)
        %FWAVE Wave force
        %
            if nargin < 2, zIdx = (1:base(1).NZ).'; end
            
            %TODO: add model option
            Fwave = base.film.wave.BETA().*base.FVAPOR(zIdx); % [N/m^2]
            
        end

        function Fvapor = FVAPOR(base,zIdx)
        %FVAPOR Film vapor shear stress
        %
            
            if nargin < 2, zIdx = (1:base(1).NZ).'; end
            
            % TODO: debug syntax
            Fvapor = base.BETA().* FVAPOR@Solvers.AbstractFilm(base,wave.film.mix,zIdx); % [N/m^2]
            
        end

        function Ftot = FTOT(base,drop,zIdx)
        %FTOT Total
        %
            if nargin < 3, zIdx = (1:base(1).NZ).'; end
            
            Ftot  = base.FWALL(zIdx)+base.FWAVE(zIdx)+base.FVAPOR(zIdx)+base.FBUOY(zIdx)+base.FGRAV(zIdx)+base.FDEP(drop,zIdx);   
            
        end

        function eqthick = EQTHICK(base,zIdx)
        %EQTHICK Base equilibrium thickness
        %   
            if nargin < 2, zIdx = (1:base(1).NZ).'; end
            
            D_H = base.inputSet.geometry.HDIAM();
            coefs = base.inputSet.model.BASEEQTHICKCOEF;
            Re_v = base.film.mix.vapor.RE(zIdx);
            Re_f = base.film.RE(zIdx);
            eqthick = D_H .* coefs(1) .* (Re_v.^coefs(2)) .* (Re_f.^coefs(3));
            
            % Limit eqthick to 1/2 of D_H, at most
            eqthick = min(eqthick, D_H/2);
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

