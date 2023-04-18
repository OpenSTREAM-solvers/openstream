classdef Film < matlab.mixin.Copyable
    %FILM Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=?Solvers.ThreeField.ThreeFieldSolver)
        
        % Solver properties
        NZ           (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of time steps
        TIME         (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time step size
        TIDX         (1,1) double  {mustBeNumeric}                         = 1                    % [-] Time step index
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux
        
        % Flow properties
        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        U            (:,1) double  {mustBeNumeric}                         = 1.                   % [m/s] Velocity
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy

        % Iteration properties
        ITR          (1,1) struct 

     end

     properties (SetAccess=?Solvers.ThreeField.ThreeFieldSolver, GetAccess=?Solvers.AbstractPhase)
        
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        inputSet    {isa(inputSet,'Inputs.InputSet')}
        fluid       {isa(fluid,'Inputs.FluidProperties')}
     end
    
    

    methods
        function film = Film(inputSet, fluid)
            %FILM Creates a Film ?solver? film
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                film.inputSet = inputSet;
                film.fluid  = fluid;
            end

        end

        function re = RE(mix, zIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:mix(1).NZ; end
            
            re = 4.*mix.W(zIdx)./mix.MU(zIdx)./sum(mix.inputSet.geometry.PERIM);
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
                targetObj (1,:) Solvers.ThreeField.Film
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

    methods(Access = protected)
    

        function cpObj = copyElement(obj)
        %COPYELEMENT Override copyElement method to create correct references
        %with properties liquid and vapor 
            
            import Solvers.ThreeField.*

            % Make a shallow copy of all four properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
           
        end
    end

end

