classdef Wave < Solvers.AbstractFilm
    %WAVE Summary of this class goes here
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
        PERIOD       (:,:) double  {mustBeNumeric}                         = 1                    % [s] Wave time period

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
        function wave = Wave(inputSet, fluid, film)
            %WAVE Creates a Wave, wave
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                wave.inputSet = inputSet;
                wave.fluid  = fluid;
                wave.film  = film;
            end
        end
        
        function wl = WL(wave, zIdx)
        %WL wave mass flow rate per unit perimeter
        %    
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            perim  = wave.inputSet.geometry.PERIM;
            
            wl = wave.W(zIdx,:)./perim;                                    % [kg/s/m] Film mass flow rate per unit perimeter
        end
        
        function thick = THICK(wave, zIdx)
        %THICK wave thickness
        %    
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
        
            rhof  = wave.fluid.RHOF;                                       % [kg/m^3] Saturated liquid density
        
            thick = wave.WL(zIdx)./wave.U(zIdx,:)./rhof;                   % [m] Film thickness
        end

        function beta = BETA(wave, zIdx)
        %BETA Wave film interfacial fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            %beta = 1-wave.film.base.BETA(zIdx);
            % Use a constant if wave.W is a scalar. 
            %   This occurs during the initialization phase only.
            if isscalar(wave.W)
                beta = 0.01;
                epsilon = wave.EPSILON(1);
            else
                beta = wave.WIDTH(zIdx) ./ wave.SPACING(zIdx);
                % ...
                epsilon = wave.EPSILON(zIdx);
                beta(isnan(beta)) = epsilon(isnan(beta));
                %beta(:) = 0.6;
            end

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

        function ment = MENT(wave,zIdx)
        %MENT Base entrainment mass flux
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

        function eta = ETA(wave, zIdx)
        %ETA Wave film deposition fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            eta = 1-wave.film.base.ETA(zIdx);
        end
        
        function Mbase = MBASE(wave,drop,zIdx)
        %MWAVE Mass flux interaction with wave
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end

            Mbase = -wave.film.base.MWAVE(drop,zIdx);

        end
        
        function Mtot = MTOT(wave,drop,zIdx)
        %MTOT Total mass flux
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end
            
            Mtot  = wave.MEVAP(zIdx)+wave.MENT(zIdx)+wave.ETA(zIdx).*drop.MDEP(zIdx)+wave.MBASE(drop,zIdx);
            
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
            
            coefs = wave.inputSet.model.EQSTROUHALCOEF;
            re_v = wave.film.mix.vapor.RE(zIdx);
            eqst = coefs(1) .* re_v.^coefs(2);

        end

        function eqfreq = EQFREQ(wave, zIdx)
        %EQFREQ
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Hydraulic diameter
            d_h = wave.inputSet.geometry.HDIAM();
            % Solve eqfreq using definition of St
            eqfreq = wave.EQSTROUHAL(zIdx).*wave.film.mix.vapor.U(zIdx)./d_h;

        end

        function eqperiod = EQPERIOD(wave, zIdx)
        %EQPERIOD Inverse of EQFREQ
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            eqperiod = 1./wave.EQFREQ(zIdx);
        
        end

        function spacing = SPACING(wave, zIdx)
        %SPACING Wave spacing
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            spacing = wave.U(zIdx,:) ./ wave.FREQ(zIdx);

        end

        function freq = FREQ(wave, zIdx)
        %FREQ Wave freq
        %   Inverse of wave time period

            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            freq = 1./wave.PERIOD(zIdx, :);

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
            
            wwidth = wave.AMP(zIdx)./wave.SHAPEFACTOR(zIdx);

            % if wwidth isnan, set to wave spacing
            spacing = wave.SPACING(zIdx);
            wwidth(isnan(wwidth)) = spacing(isnan(wwidth));

            % Limit width to be no larger than the spacing
            wwidth = min(wwidth, wave.SPACING(zIdx));

        end

        function amp = AMP(wave, zIdx)
        %AMP Wave amplitude
        %   Function of WL, rho, Shape factor, frequency
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            rhof = wave.fluid.RHOF;
            amp = (wave.WL(zIdx).* wave.SHAPEFACTOR(zIdx))./(rhof.* wave.FREQ(zIdx));
            amp = sqrt(abs(amp));
            
            % Limit amp+base.thick to 1/2 of D_H, at most
            D_H = wave.inputSet.geometry.HDIAM();
            amp = min(amp, D_H/2-wave.film.base.THICK(zIdx));

        end

        function dragcoef = DRAGCOEF(wave, zIdx)
        %DRAGCOEF Wave drag coefficient
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            % Coefficients
            coefs = wave.inputSet.model.WAVEDRAGCOEF;

            % Vapor Reynolds number (Eq. 64)
            rho_vs = wave.fluid.RHOG;
            du = wave.film.mix.vapor.U(zIdx) - wave.U(zIdx,:);
            mu_vs = wave.fluid.MUG;
            Re_vw = rho_vs .* du .* coefs(1) ./mu_vs;

            % Draf Coef (Eq. 63)
            coefs = wave.inputSet.model.WAVEDRAGCOEF;
            dragcoef = (coefs(2)./Re_vw).^2 + coefs(3);

        end
        
        function out = struct(obj)
        %STRUCT Converter to struct
        %
            for i = length(obj):-1:1
                out(i) = struct('TIME', obj(i).TIME, ...
                                'W',   obj(i).W, ...
                                'U',   obj(i).U, ...
                                'H',   obj(i).H, ...
                                'ITR', obj(i).ITR);
            end
        end

        function copyFlowProperties(srcObj, targetObj, opts)
        %COPYFLOWPROPERTIES
        %
            arguments
                srcObj
                targetObj (1,:) Solvers.FourField.Wave
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

