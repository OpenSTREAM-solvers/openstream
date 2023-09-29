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
        
        function wl = WL(wave,zIdx)
        %WL wave mass flow rate per unit perimeter
        %    
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end
            
            perim  = wave.inputSet.geometry.PERIM;
            
            wl = wave.W(zIdx,:)./perim;                                    % [kg/s/m] Film mass flow rate per unit perimeter
        end
        
        function thick = THICK(wave,zIdx)
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

            beta = 1-wave.film.base.BETA(zIdx);
        end

        function epsilon = EPSILON(wave, zIdx)
        %BETA Wave mass flow fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            epsilon = wave.W(zIdx, :) ./ wave.film.W(zIDx, :);
        end

        function betap = BETAP(wave, zIdx)
        %BETAP Wave film heat flux fraction
        %
            if nargin < 2, zIdx = (1:wave(1).NZ).'; end

            betap = 1-wave.film.base.BETAP(zIdx);
        end

        function ment = MENT(wave,mix,zIdx)
        %MENT Base entrainment mass flux
        %
            if nargin < 3, zIdx = (1:wave(1).NZ).'; end
            
            % TODO: use coefficient later
            ment = wave.film.MENT(mix,zIdx) - wave.film.base.MENT(mix,zIdx);            
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

            % TODO: for now, assume no wave
            % TODO: add as model option later
            eta = 1-wave.film.base.ETA(zIdx);
        end
                
        function Mtot = MTOT(wave,mix,drop,zIdx)
        %MTOT Total
        %
            if nargin < 4, zIdx = (1:wave(1).NZ).'; end
            
            Mtot  = wave.MEVAP(zIdx)+wave.MENT(mix,zIdx)+wave.ETA(zIdx).*drop.MDEP(mix,zIdx);   
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

