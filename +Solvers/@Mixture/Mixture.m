classdef Mixture < handle
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=private)
        
        NZ           (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of time steps
        TIME         (:,1) double  {mustBeNumeric}                         = 0                    % [s] Time series
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux

     end

    properties
        inputSet    {isa(inputSet,'Inputs.InputSet')}
        boundaryConditions
    end
    
    methods
        function obj = Mixture(inputSet, opts)
            %MIXTURE Creates a Mixture solver obj
            %   Detailed explanation goes here
            arguments
                inputSet {isa(inputSet,'Inputs.InputSet')}
                opts.interpBoundaryConditions {islogical} = true
            end

            % Store inputSet as object property
            obj.inputSet = inputSet;
            
            % Calculate time steps
            obj.NZ = obj.inputSet.model.NNODES+1;                           % Total number of axial nodes (add one for inlet conditions)
            DT = obj.inputSet.options.TSTEP;                                % [s] Time interval
            obj.TIME = colon(obj.inputSet.bc.TIME(1), ...
                             DT, ...
                             obj.inputSet.bc.TIME(end));                    % [s] Computational time array
            obj.NTIME = length(obj.TIME);

            % Calculate axial steps
            obj.DZ = obj.inputSet.geometry.LENGTH/obj.inputSet.model.NNODES;    % [m] Uniform node length
            obj.Z = (0:obj.DZ:obj.inputSet.geometry.LENGTH)';                   % [m] Node elevations

            % Optionally interpolate BCs in time and space (z)
            if opts.interpBoundaryConditions
                obj.interpBoundaryConditions();
            end

        end
        
        function obj = interpBoundaryConditions(obj)
            %INTERPBOUNDARYCONDITIONS Expand specified boundary conditions
            %to every node and timestep defined by the model and geometry.
            %   Detailed explanation goes here
            
            % Retrieve list of boundary condition properties
            bcFields = obj.inputSet.bc.listInputProperties();

            % Interpolate bc properties in time
            params = checkParams({'TIME','PRESSURE','HIN','MFLOW','POWER'});
            obj.boundaryConditions = cell2struct( ...
                                        arrayfun( ...
                                            @(idx) obj.timeInterpolate(obj.inputSet.bc.(params(idx))), ...
                                            1:length(params), ...
                                            'UniformOutput',false),...
                                        params,...
                                        2);

            % Interpolate wall power in time
            WPOWERT = obj.timeInterpolate(obj.inputSet.bc.WPOWER);
            obj.boundaryConditions.WPOWER = zeros(obj.NTIME,obj.NZ,obj.inputSet.geometry.NWALL);
            
            % Interpolate wall power in axial space 
            %   Index order: (NTIME, NZ, NWALL)
            % NOTE: only the 1st row of WMESH is used
            obj.boundaryConditions.WPOWER = ...
                pagetranspose( ...
                    obj.axialInterpolate(cumsum(obj.inputSet.bc.WMESH(1,:).'), ...
                                     pagetranspose(WPOWERT)...
                                     ) ...
                );

            % Calculate wall heat flux at each node in space & time
            % NOTE: This is very covoluted
            obj.boundaryConditions.HFLUX = ...
                obj.boundaryConditions.WPOWER .* obj.boundaryConditions.POWER ...
                ./ sum(reshape(obj.inputSet.geometry.PERIM .* obj.DZ,1,1,3).*obj.boundaryConditions.WPOWER,[2,3]);


            function validParams = checkParams(params)
            %CHECKPARAMS Ensure interpolation parameters are valid
            %parameters of the boundaryCondition obj.
                
                validParams = string().empty();
                for idx = 1:length(params)
                    if find(bcFields==params(idx))
                        validParams(end+1) = params(idx);
                    else
                        throw( ...
                            MException( ...
                                'MixtureError:InvalidInterpolationParameter', ...
                                'Parameter %s is not a valid boundary condition parameter', ...
                                params{idx} ...
                                ) ...
                        );
                    end
                end

            end


        end

        function interpOut = timeInterpolate(obj, y)
            interpOut = interp1(obj.inputSet.bc.TIME, ...
                                y, ...
                                obj.TIME, ...
                                obj.inputSet.options.TIMEINTERP);
        end

        function interpOut = axialInterpolate(obj, x, y)
            interpOut = interp1(x, ...
                                y, ...
                                obj.Z, ...
                                obj.inputSet.options.AXIALINTERP, ...
                                "extrap");
        end
    end
end

