classdef TwoFluidSolver < Solvers.AbstractSolver
    %MIXTURESOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=protected)
        
        NZ           (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of time steps
        TIME         (:,1) double  {mustBeNumeric}                          = 0         % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                          = 0         % [s] Time step size
        Z            (:,1) double  {mustBeNumeric}                          = 1.        % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                          = 0         % [m] Axial step size

        fluid       {isa(fluid,'Inputs.FluidProperties')}
        boundaryConditions
        
        mixtureInit
        mixture

     end

     properties (SetAccess = protected)
        mixSolver
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(twfSolver)
    end

    methods
        function twfSolver = TwoFluidSolver(inputSet,mixSolver)
            %MIXTURESOLVER Creates a Mixture solver
            %   Detailed explanation goes here
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            twfSolver = twfSolver@Solvers.AbstractSolver(inputSet);
            
            % Store mixSolver handle
            twfSolver.mixSolver = mixSolver;

            % Attempt to solve mixSolver if it is unsolved
            if twfSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
                twfSolver.mixSolver.solve();
            end
            
            % Initialize solver parameters
            twfSolver.initializeSolver();

        end
        
        function initializeSolver(twfSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.TwoField.*
            import Solvers.*

            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                twfSolver.(p{:}) = twfSolver.mixSolver.(p{:});
            end

            % Calculate time steps
            %mixSolver.DT = mixSolver.inputSet.options.TSTEP;                            % [s] Time interval
            %mixSolver.TIME = colon(mixSolver.inputSet.bc(1).TIME, ...
            %                 mixSolver.DT, ...
            %                 mixSolver.inputSet.bc(end).TIME);                    % [s] Computational time array
            %mixSolver.NTIME = length(mixSolver.TIME);

            % Calculate axial steps
            %mixSolver.DZ = mixSolver.inputSet.geometry.LENGTH/mixSolver.inputSet.model.NNODES;    % [m] Uniform node length
            %mixSolver.Z = (0:mixSolver.DZ:mixSolver.inputSet.geometry.LENGTH)';                   % [m] Node elevations
            %mixSolver.NZ = length(mixSolver.Z);                                                   % Total number of axial nodes (add one for inlet conditions)
            
            % Interpolate BCs in time and space (z)
            %mixSolver.interpBoundaryConditions();
            
            %
            % Create mixture array (by timestep)

            % Setup DP and ITR
            % Grav:     [Pa] Gravitational pressure drop
            % Wall:     [Pa] Wall friction pressure drop
            % Acc_z:    [pa] Spatial acceleration pressure drop
            % Acc_t:    [Pa] Temporal acceleration pressure drop
            % K:        [Pa] Local pressure drop
            % Tot:      [Pa] Total pressure drop
            %DPFields =  ["Grav","Wall","Acc_z","Acc_t","K","Tot"];          % Fieldnames for DP struct
            %DPCell = cell(numel(DPFields),1);                               % Cell structure to convert into struct
            %DPCell(:) = {zeros(mixSolver.NZ,1)};                            % Initialize with zeros
            %DP = cell2struct(DPCell, DPFields, 1);                          % Convert cell to struct with fieldnames

            % Local parameters
            mixArr = twfSolver.mixSolver.mixture;                            % Mixture solution
            %model  = twfSolver.inputSet.model;                               % Models
            %geom   = twfSolver.inputSet.geometry;

            % Setup inner iteration value struct
            ITRFields = ["N","DWL","DUL"];
            ITRl = twfSolver.CreateITR(twfSolver.NZ, ITRFields);
            ITRFields = ["N","DWV","DUV"];
            ITRv = twfSolver.CreateITR(twfSolver.NZ, ITRFields);

            %%%%

            % Create film and drop arrays (by timestep)
            liqArr(twfSolver.NTIME) = Liquid();
            vapArr(twfSolver.NTIME) = Vapour();
            props = {'NZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid', 'mix'};                 % film and drop properties
            
            for tIdx = 1:tfSolver.NTIME

                % Convenience variables (handles)
                liq         = liqArr(tIdx);
                vap         = vapArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = twfSolver.fluid(tIdx);
                
                % Inputset, fluid                
                liq.inputSet = twfSolver.inputSet;
                liq.fluid    = fluid;
                liq.mix      = mix;
                
                % Axial Steps
                vap.DZ = tfSolver.DZ;
                
                liq.NZ = twfSolver.NZ;
                liq.DZ = twfSolver.DZ;
                liq.Z  = twfSolver.Z;
                
                % Time step
                liq.NTIME = twfSolver.NTIME;
                liq.DT    = twfSolver.DT;
                liq.TIME  = twfSolver.TIME(tIdx);
                liq.TIDX  = tIdx;
                
                % Copy properties to vapour
                for p = props
                    vap.(p{:}) = liq.(p{:});
                end
                    
                % Wall evaporation heat flux
                %HFLUX = mix.HFLUX;                                   % [W/m^2] Wall heat flux
                %avgHFLUX = sum(HFLUX.*geom.PERIM,2)./sum(geom.PERIM);      % [W/m^2] Average heat flux
                %avgHFLUX = repmat(avgHFLUX,1,geom.NWALL);                  % [W/m^2] ... distributed to all walls
                
                %evapFn = double(mix.XEQ > 0);                        % Saturated evaporation function
                %Nbo = find(evapFn > 0,1);                                  % Boiling transition node
                %if Nbo >1
                    % Adjust evaporation function in transition node 
                    % (part toward subcooled liquid, part toward evaporation)
                %    evapFn(Nbo) = mix.XEQ(Nbo)/diff(mix.XEQ(Nbo-1:Nbo)); 
                %end
                
                %flm.HFLUX = mix.AFDISTR(evapFn.*avgHFLUX,HFLUX); % [W/m^2] Film evaporation heat flux
                    
                % Film evaporation (thermal equilibrium assumption)
                %flm.MEVAP = -flm.HFLUX./(fluid.HG-fluid.HF); % [kg/m^2/s] Evaporation mass flux
                
                % Entrained ratio at onset of annular flow
                %switch model.OAFENTRAINED
                %    case InputEnums.OAFENTRAINED.RATIO
                %        e0 = model.OAFDROPRATIO;
                %    case InputEnums.OAFENTRAINED.EQUILIBRIUM
                %        e0 = tfSolver.EQUIL(flm,drp,mix,mix.OAFIDX);
                %end
                
                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note 1: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                % Note 2: other, maybe better, initialization states could be investigated
                %drpArr(tIdx).W = repmat(e0.*mixArr(tIdx).OAFWL,tfSolver.NZ,1); % [kg/s] % Set drop mass flow to onset of annular flow conditions everywhere
                
                % Transient mass gradient in film field
                %flmArr(tIdx).W = (mix(tIdx).W-drpArr(tIdx).W).*geom.PERIM./sum(geom.PERIM);           % [kg/s] Distribute film at inlet uniformly on all walls
                %flmArr(tIdx).W = flmArr(tIdx).W+cumsum(flmArr(tIdx).MEVAP).*geom.PERIM.*tfSolver.DZ;  % [kg/s] Apply simple mass conservation
                
                % ... or transient mass gradient in drop field
                %drp.W = drp.W+mix.W-mix.W(mix.OAFIDX);                                % 
                %flm.W(1,1:geom.NWALL) = (mix.liquid.W(1)-drp.W(1)).*geom.PERIM./sum(geom.PERIM);  % [kg/s] Distribute film at inlet uniformly on all walls
                %flm.W = flm.W(1,:)+cumsum(flm.MEVAP).*geom.PERIM.*tfSolver.DZ;                 % [kg/s] Apply simple mass conservation
                
                % Limit film flow rate minimum to 0
                %flm.W = max(0,flm.W);
                %drp.W = mix.liquid.W-sum(flm.W,2); % [kg/s] Recalculate consistent drop flow rate
                
                
                % Initialize velocity [m/s]
                %drp.U = mix.liquid.U;                                      % [m/s] Drop velocity
                %drp.U = drp.USLIP();                                        % [m/s] Drop velocity
                
                %flm.U = repmat(mix.liquid.U,1,geom.NWALL); % [m/s]
                %flm.U = flm.UALGEBR();                                      % [m/s] Film velocity
                                
                % Initialize enthalpy [J/kg] by number of spatial nodes, NZ
                %drp.H = repmat(fluid.HF,tfSolver.NZ,1);
                %flm.H = repmat(fluid.HF,tfSolver.NZ,1);
                
                % ITR
                liq.ITR = ITRl;
                vap.ITR = ITRv;


            % % Setup fluid property object
            % mixSolver.fluid = FluidProperties( ...
            %                         mixSolver.boundaryConditions.PRESSURE, ...
            %                         mixSolver.inputSet.model);
            % 
            % mixArr = Mixture.empty(0,mixSolver.NTIME);
            % for tIdx = 1:mixSolver.NTIME
            % 
            %     % Inputset
            %     mixArr(tIdx).inputSet = mixSolver.inputSet;
            %     mixArr(tIdx).fluid = mixSolver.fluid(tIdx);
            % 
            %     % Axial Steps
            %     mixArr(tIdx).NZ = mixSolver.NZ;
            %     mixArr(tIdx).DZ = mixSolver.DZ;
            %     mixArr(tIdx).Z = mixSolver.Z;
            % 
            %     % Time step
            %     mixArr(tIdx).NTIME = mixSolver.NTIME;
            %     mixArr(tIdx).DT = mixSolver.DT;
            %     mixArr(tIdx).TIME = mixSolver.TIME(tIdx);
            %     mixArr(tIdx).TIDX = tIdx;
            % 
            %     % Wall heat flux
            %     mixArr(tIdx).HFLUX = ...
            %         reshape( ...
            %             mixSolver.boundaryConditions.HFLUX(:,:,tIdx), ...
            %             mixSolver.NZ,...
            %             [] ...
            %             );
            % 
            %     % Mass flow ratep [kg/s], pressure [Pa], enthalpy [J/kg]
            %     mixArr(tIdx).W     = repmat(mixSolver.boundaryConditions.MFLOW(tIdx),mixSolver.NZ,1);
            %     mixArr(tIdx).P     = repmat(mixSolver.boundaryConditions.PRESSURE(tIdx),mixSolver.NZ,1);
            %     mixArr(tIdx).H     = repmat(mixSolver.boundaryConditions.HIN(tIdx),mixSolver.NZ,1);
            % 
            %     % DP, ITR
            %     mixArr(tIdx).DP = DP;
            %     mixArr(tIdx).ITR = ITR;
            % 
            %     % Phases
            %     mixArr(tIdx).liquid = Liquid(mixArr(tIdx));
            %     mixArr(tIdx).vapor = Vapor(mixArr(tIdx));
                

            end

            % Store transient mixture array
            %twfSolver.mixture = mixArr;
            twfSolver.liquid = liqArr;
            twfSolver.vapour = vapArr;


            % Create steady state mixture array
            twfSolver.liquidInit = copy( ...
                repmat(liqArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.vapourInit = copy( ...
                repmat(vapArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.fluidInit = FluidProperties( ...
                                    repmat( ...
                                        twfSolver.boundaryConditions.PRESSURE(1), ...
                                        1, ...
                                        twfSolver.inputSet.options.SSMAXITER), ...
                                    twfSolver.inputSet.model);

            % Update mixtureInit times and timesteps
            initTIMEDT = twfSolver.inputSet.options.SSTSTEP;
            initNTIME = length(twfSolver.liquidInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(twfSolver.liquidInit);

            for i = 1:length(twfSolver.liquidInit)
                twfSolver.liquidInit(i).TIME = initTIME(i);
                twfSolver.liquidInit(i).DT = initTIMEDT;
                twfSolver.liquidInit(i).NTIME = initNTIME;
                twfSolver.liquidInit(i).TIDX = initTIDX(i);

                twfSolver.liquidInit(i).mix       = copy(twfSolver.mixSolver.mixtureInit(end));
                twfSolver.liquidInit(i).mix.TIME  = initTIME(i);
                twfSolver.liquidInit(i).mix.DT    = initTIMEDT;
                twfSolver.liquidInit(i).mix.NTIME = initNTIME;
                twfSolver.liquidInit(i).mix.TIDX  = initTIDX(i);

                twfSolver.vapourInit(i).mix    = twfSolver.liquidInit(i).mix;

                twfSolver.vapourInit(i).TIME = initTIME(i);
                twfSolver.vapourInit(i).DT = initTIMEDT;
                twfSolver.vapourInit(i).NTIME = initNTIME;
                twfSolver.vapourInit(i).TIDX = initTIDX(i);
            end

            % set STATE to UNSOLVED
            twfSolver.STATE = SolverState.UNSOLVED;

        end

        % function mixSolver = interpBoundaryConditions(mixSolver)
        %     %INTERPBOUNDARYCONDITIONS Expand specified boundary conditions
        %     %to every node and timestep defined by the model and geometry.
        %     %   Detailed explanation goes here
        % 
        %     % Retrieve list of boundary condition properties
        %     bcFields = mixSolver.inputSet.bc.listInputProperties();
        % 
        %     % Interpolate bc properties in time
        %     params = checkParams({'TIME','PRESSURE','HIN','MFLOW','POWER'});
        %     mixSolver.boundaryConditions = cell2struct( ...
        %                                 arrayfun( ...
        %                                     @(idx) mixSolver.timeInterpolate([mixSolver.inputSet.bc.(params(idx))]), ...
        %                                     1:length(params), ...
        %                                     'UniformOutput',false),...
        %                                 params,...
        %                                 2);
        % 
        %     % Interpolate wall power in space
        %     WPOWERZ = arrayfun( ...
        %                 @(bc)mixSolver.axialInterpolate( ...
        %                                 cumsum(bc.WMESH), ...
        %                                 bc.WPOWER ...
        %                                 ), ...
        %                 mixSolver.inputSet.bc, ...
        %                 'UniformOutput',false ...
        %                 );
        %     % Combine WPOWERZ to NZ x NWALL x N_bc
        %     WPOWERZ = reshape( ...
        %                     cell2mat(WPOWERZ), ...
        %                     mixSolver.NZ, ...
        %                     mixSolver.inputSet.geometry.NWALL, ...
        %                     []);
        % 
        %     % Interpolate wall power in time
        %     WPOWERT = arrayfun( ...
        %                 @(wallIdx) mixSolver.timeInterpolate( ...
        %                             reshape(WPOWERZ(:,wallIdx,:), ...
        %                                 mixSolver.NZ, ...
        %                                 [] ...
        %                            ).').', ...
        %                            1:mixSolver.inputSet.geometry.NWALL, ...
        %                            'UniformOutput',false);
        %     % Reorganize WPOWERT to NZ x NWall x NTIME
        %     WPOWERT = permute( ...
        %                 reshape( ...
        %                     cell2mat(WPOWERT), ...
        %                     mixSolver.NZ, ...
        %                     mixSolver.NTIME, ...
        %                     [] ...
        %                 ), [1 3 2]);
        % 
        %     mixSolver.boundaryConditions.WPOWER = WPOWERT;
        % 
        % 
        %     % Calculate wall heat flux at each node in space & time
        %     % NOTE: This is very convoluted
        %     mixSolver.boundaryConditions.HFLUX = ...
        %         mixSolver.boundaryConditions.WPOWER .* reshape(mixSolver.boundaryConditions.POWER,1,1,[]) ...
        %         ./ sum(reshape( ...
        %                 mixSolver.inputSet.geometry.PERIM .* mixSolver.DZ,1,mixSolver.inputSet.geometry.NWALL,1 ...
        %                 ).* ...
        %                mixSolver.boundaryConditions.WPOWER,[1,2] ...
        %               );
        % 
        %     function validParams = checkParams(params)
        %     %CHECKPARAMS Ensure interpolation parameters are valid
        %     %parameters of the boundaryCondition mix.
        % 
        %         validParams = string().empty();
        %         for idx = 1:length(params)
        %             if find(bcFields==params(idx))
        %                 validParams(end+1) = params(idx);
        %             else
        %                 throw( ...
        %                     MException( ...
        %                         'MixtureError:InvalidInterpolationParameter', ...
        %                         'Parameter %s is not a valid boundary condition parameter', ...
        %                         params{idx} ...
        %                         ) ...
        %                 );
        %             end
        %         end
        % 
        %     end
        % 
        % end

% adjust plot functions

        function plotz(mixSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
            arguments
                mixSolver
                tIdx    (1,1) double
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture(tIdx);
                case 'STEADY'
                    mix = mixSolver.mixtureInit(tIdx);
            end
            
            figure('name',['Axial distributions of mixture parameters at ' num2str(mix.TIME) ' [s]'])
                
            nexttile; hold all; grid on; title('Mass flow rates')
            plot(mix.Z,mix.W,'.-')  
            plot(mix.liquid.Z,mix.liquid.W,'.-')
            plot(mix.vapor.Z,mix.vapor.W,'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Mass flowrates [kg/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Pressure drop')
            plot(mix.Z,cumsum(mix.DP.Tot),'.-') 
            plot(mix.Z,cumsum(mix.DP.Grav),'.-')
            plot(mix.Z,cumsum(mix.DP.Wall),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_z),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_t),'.-')
            plot(mix.Z,cumsum(mix.DP.K),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Pressure drop [Pa]')
            legend({'Total','Gravitational','Wall','Acc z','Acc t','Local'},'location','northWest');
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Void fraction and quality')
            plot(mix.Z,mix.XEQ(1:mix.NZ),'.-')  
            plot(mix.Z,mix.X(1:mix.NZ),'.-')
            plot(mix.Z,mix.VF(1:mix.NZ),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Quality / Void fraction [-]')
            legend({'Equilibrium quality','Vapor mass quality','Void fraction'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Field velocity')
            plot(mix.Z,mix.U(1:mix.NZ),'.-')  
            plot(mix.liquid.Z,mix.liquid.U(1:mix.NZ),'.-')
            plot(mix.vapor.Z,mix.vapor.U(1:mix.NZ),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Velocities [m/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)

        end
    
        function plott(mixSolver, zIdx, opt)
            %PLOTT 
            % 
            arguments
                mixSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture;
                case 'STEADY'
                    mix = mixSolver.mixtureInit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(mix);
            end

            % Cannot plot time series of one time step
            if isscalar(mix) || isscalar(opt.tIdx)
                mixSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
            end

            % Time vector
            plotTimeVector = [mix(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time series of mixture parameters at ' num2str(mixSolver.Z(zIdx(1))) ' [m]']);
            
            timeplot('W','Mass flowrates [kg/s]')
            timeplot('P','Pressure [Pa]')
            timeplot('XEQ','Equilibrium quality [-]')
            timeplot('X','Steam mass quality [-]')
            timeplot('VF','Void fraction [-]')
            timeplot('U','Velocity [m/s]')

            function timeplot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(mix,param)
                    paramData = arrayfun( ...
                                    @(i) mix(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [mix.(param)];
                end
                
                plot(plotTimeVector, paramData(zIdx,opt.tIdx),'.-');

                legendStr = num2str(mixSolver.Z(zIdx),'z=%0.4f m');
                legend(legendStr,'Location','southeast');
                
                xlabel('Time [s]'); xlim(plotTimeVector([1 end]));
                ylabel(ylabelText)
                set(gca,'fontSize',14)
            
            end

        end

        function plotzt(mixSolver, zIdx, opt)
        % 2d plot, position z on horizontal and time t on vertical axis
            arguments
                mixSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end

            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture;
                case 'STEADY'
                    mix = mixSolver.mixtureInit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(mix);
            end

            % Cannot plot time series of one time step
            if isscalar(mix) || isscalar(opt.tIdx)
                mixSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
            end

            % Time vector
            plotTimeVector = [mix(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time series of mixture parameters at ' num2str(mixSolver.Z(zIdx(1))) ' [m]']);
            
            zt_plot('W','Mass flowrates [kg/s]')
            zt_plot('P','Pressure [Pa]')
            zt_plot('XEQ','Equilibrium quality [-]')
            zt_plot('X','Steam mass quality [-]')
            zt_plot('VF','Void fraction [-]')
            zt_plot('U','Velocity [m/s]')

            function zt_plot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(mix,param)
                    paramData = arrayfun( ...
                                    @(i) mix(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [mix.(param)];
                end
                
                [t_mesh,z_mesh] = meshgrid(plotTimeVector,mixSolver.Z);

                surf(z_mesh,t_mesh,paramData);
                shading interp 
                xlabel('Position z [m]') 
                ylabel('Time t [s]') 
                view(2);
                cb = colorbar(); 
                ylabel(cb,ylabelText,'FontSize',12,'Rotation',270)
            
            end

        end

        
        function saveResults(mixSolver, opts)
        %SAVERESULTS
        %
        arguments
            mixSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = mixSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', mixSolver.Z, ...
                                'TIME', mixSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', mixSolver.boundaryConditions, ...
                                'mixtureInit', struct(mixSolver.mixtureInit), ...
                                'mixture', struct(mixSolver.mixture));

                    if isfolder(session.directory)
                        save( ...
                            fullfile( ...
                                session.directory, strcat(session.name,'.mat')), ...
                            '-struct', ...
                            "results", ...
                            "-mat" ...
                        );
                    else
                        error('%s does not exist. Check Session.log.LOGMODE. Try session.makeSessionDirectory()');
                    end
            end


        end

        function interpOut = timeInterpolate(mix, y)
            if isscalar([mix.inputSet.bc.TIME])
                interpOut = y;
            else
                interpOut = interp1([mix.inputSet.bc.TIME].', ...
                                    y, ...
                                    mix.TIME, ...
                                    mix.inputSet.options.TIMEINTERP);
            end
        end

        function interpOut = axialInterpolate(mix, x, y)
        %AXIALINTERPOLATE
        % Linear extrapolation is used for cases where interpolation returns NaN (for instance, point slightly outside allowed tolerance when 'next' interpolation methos is selected)
            interpOut = interp1(x, ...
                                y, ...
                                mix.Z, ...
                                mix.inputSet.options.AXIALINTERP, ...
                                "extrap");
            interpOut(isnan(interpOut)) = interp1(x, ...
                                y, ...
                                mix.Z(isnan(interpOut)), ...
                                'linear', ...
                                "extrap");               
        end
    end
end

