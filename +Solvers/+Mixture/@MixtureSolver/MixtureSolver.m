classdef MixtureSolver < Solvers.AbstractSolver
    %MIXTURESOLVER defines any task related to initalizing, solving and plotting the results based on the mixture approach.
    %
    %   TODO: Detailed explanations
    
     properties (SetAccess=private)
        
        NZ           (1,1) double  {mustBeNumeric}                         = 0         % Number of axial steps [-]
        NTIME        (1,1) double  {mustBeNumeric}                         = 0         % Number of time steps [-]
        TIME         (:,1) double  {mustBeNumeric}                         = 0         % Time series [s]
        DT           (1,1) double  {mustBeNumeric}                         = 0         % Time step size [s]
        Z            (:,1) double  {mustBeNumeric}                         = 1.        % Elevation [m]
        DZ           (1,1) double  {mustBeNumeric}                         = 0         % Axial step size [m]

        fluid        {isa(fluid,'Inputs.FluidProperties')}
        boundaryConditions
        
        mixtureInit
        mixture

     end

     properties (SetAccess = protected)
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(mixSolver)
    end

    methods
        
        function mixSolver = MixtureSolver(inputSet)
        %MIXTURESOLVER Creates a Mixture solver
        %
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
            end

            % Call abstract class constructor
            mixSolver = mixSolver@Solvers.AbstractSolver(inputSet);
            
            % Initialize solver parameters
            mixSolver.initializeSolver();
        end
        
        function initializeSolver(mixSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            import Inputs.*
            import Solvers.Mixture.*
            import Solvers.*
            
            NWALL = mixSolver.inputSet.geometry.NWALL;

            % Calculate time steps
            mixSolver.DT = mixSolver.inputSet.options.TSTEP;                            % [s] Time interval
            mixSolver.TIME = colon(mixSolver.inputSet.bc(1).TIME, ...
                             mixSolver.DT, ...
                             mixSolver.inputSet.bc(end).TIME);                    % [s] Computational time array
            mixSolver.NTIME = length(mixSolver.TIME);

            % Calculate axial steps
            mixSolver.DZ = mixSolver.inputSet.geometry.LENGTH/mixSolver.inputSet.model.NNODES;    % [m] Uniform node length
            mixSolver.Z = (0:mixSolver.DZ:mixSolver.inputSet.geometry.LENGTH)';                   % [m] Node elevations
            mixSolver.NZ = length(mixSolver.Z);                                                   % Total number of axial nodes (add one for inlet conditions)
            
            % Interpolate BCs in time and space (z)
            mixSolver.interpBoundaryConditions();
            
            % Create mixture array (by timestep)

            % Setup DP structure
            % Grav:     [Pa] Gravitational pressure drop
            % Wall:     [Pa] Wall friction pressure drop
            % Acc_z:    [pa] Spatial acceleration pressure drop
            % Acc_t:    [Pa] Temporal acceleration pressure drop
            % K:        [Pa] Local pressure drop
            % Tot:      [Pa] Total pressure drop
            DPFields =  ["Grav","Wall","Acc_z","Acc_t","K","Tot"];         % Fieldnames for DP struct
            DPCell = cell(numel(DPFields),1);                              % Cell structure to convert into struct
            DPCell(:) = {zeros(mixSolver.NZ,1)};                           % Initialize with zeros
            DP    = cell2struct(DPCell, DPFields, 1);                      % Convert cell to struct with fieldnames
            DPSUM = cell2struct(DPCell, DPFields, 1);                      % Convert cell to struct with fieldnames
            
            % Setup MDER structure
            % U_z:    [m/s^2] Convective acceleration
            % U_t:    [m/s^2] Local acceleration
            % U  :    [m/s^2] Total acceleration
            % H_z:    [J/kg/s] Convective transport of enthalpy
            % H_t:    [J/kg/s] Local rate of change of enthalpy
            % H  :    [J/kg/s] Total rate of change of enthalpy
            MDERFields =  ["U_z","U_t","U","H_z","H_t","H"];               % Fieldnames for MDER struct
            MDERCell = cell(numel(MDERFields),1);                          % Cell structure to convert into struct
            MDERCell(:) = {zeros(mixSolver.NZ,1)};                         % Initialize with zeros
            MDER = cell2struct(MDERCell, MDERFields, 1);                   % Convert cell to struct with fieldnames
            
            % Setup TRELAX structure
            % TCOND: [s] Relaxation time for interfacial condensation
            % TEVAP: [s] Relaxation time for interfacial evaporation
            % WV   : [kg/s] Vapor mass flow rate
            % X    : [-] Vapor mass quality
            % HV   : [J/kg] Vapor enthalpy
            % TV   : [K] Vapor temperarure
            TRELAXFields =  ["TCOND","TEVAP","WV","X","HV","TV"];          % Fieldnames for TRELAX struct
            TRELAXCell = cell(numel(TRELAXFields),1);                      % Cell structure to convert into struct
            TRELAXCell(:) = {zeros(mixSolver.NZ,mixSolver.inputSet.geometry.NWALL)}; % Initialize with zeros
            TRELAX = cell2struct(TRELAXCell, TRELAXFields, 1);             % Convert cell to struct with fieldnames
            
            % Setup PSEUDO structure
            % TRELAX: [s] Relaxation time
            % WV    : [kg/s] Pseudo vapor mass flow rate
            % XEQ   : [-] Pseudo equilibrium quality
            PSEUDOFields =  ["TRELAX","WV","XEQ"];                         % Fieldnames for PSEUDO struct
            PSEUDOCell = cell(numel(PSEUDOFields),1);                      % Cell structure to convert into struct
            PSEUDOCell(:) = {zeros(mixSolver.NZ,mixSolver.inputSet.geometry.NWALL)}; % Initialize with zeros
            PSEUDO = cell2struct(PSEUDOCell, PSEUDOFields, 1);             % Convert cell to struct with fieldnames

            % Setup inner iteration value struct
            ITRFields = ["N","DW","DP","DPSUM","DH","DWV","DHV"];
            ITR = mixSolver.CreateITR(mixSolver.NZ, ITRFields);
            ITR.DWV = repmat(ITR.DWV,1,NWALL);
            ITR.DHV = repmat(ITR.DHV,1,NWALL);

            % Setup fluid property object
            mixSolver.fluid = FluidProperties( ...
                                    mixSolver.boundaryConditions.PRESSURE, ...
                                    mixSolver.inputSet.model);

            mixArr = Mixture.empty(0,mixSolver.NTIME);
            for tIdx = 1:mixSolver.NTIME
                
                % Inputset
                mixArr(tIdx).inputSet = mixSolver.inputSet;
                mixArr(tIdx).fluid = mixSolver.fluid(tIdx);
                
                % Axial Steps
                mixArr(tIdx).NZ = mixSolver.NZ;
                mixArr(tIdx).DZ = mixSolver.DZ;
                mixArr(tIdx).Z  = mixSolver.Z;
                
                % Time step
                mixArr(tIdx).NTIME = mixSolver.NTIME;
                mixArr(tIdx).DT    = mixSolver.DT;
                mixArr(tIdx).TIME  = mixSolver.TIME(tIdx);
                mixArr(tIdx).TIDX  = tIdx;

                % Wall heat flux
                mixArr(tIdx).HFLUX = ...
                    reshape( ...
                        mixSolver.boundaryConditions.HFLUX(:,:,tIdx), ...
                        mixSolver.NZ,...
                        [] ...
                        );
                
                % DP, DPSUM, MDER, TRELAX, PSEUDO, ITR
                mixArr(tIdx).DP     = DP;
                mixArr(tIdx).DPSUM  = DPSUM;
                mixArr(tIdx).MDER   = MDER;
                mixArr(tIdx).TRELAX = TRELAX;
                mixArr(tIdx).PSEUDO = PSEUDO;
                mixArr(tIdx).ITR    = ITR;
                
                % Phases
                mixArr(tIdx).liquid = Liquid(mixArr(tIdx));
                mixArr(tIdx).vapor  = Vapor(mixArr(tIdx));
                
                % Mass flow rate [kg/s], pressure [Pa], enthalpy [J/kg]
                mixArr(tIdx).W = repmat(mixSolver.boundaryConditions.MFLOW(tIdx),mixSolver.NZ,1);
                mixArr(tIdx).P = repmat(mixSolver.boundaryConditions.PRESSURE(tIdx),mixSolver.NZ,1);
                mixArr(tIdx).H = repmat(mixSolver.boundaryConditions.HIN(tIdx),mixSolver.NZ,1);
                
                % Initialize TRELAX after H to get correct XEQ
                mixArr(tIdx).TRELAX.WV   = max(0,mixArr(tIdx).XEQ).*mixArr(tIdx).WWALL;
                mixArr(tIdx).TRELAX.X    = repmat(max(0,mixArr(tIdx).XEQ),1,NWALL);
                mixArr(tIdx).TRELAX.HV   = repmat(mixSolver.fluid(tIdx).HG,mixSolver.NZ,NWALL);
                mixArr(tIdx).TRELAX.TV   = reshape(mixSolver.fluid(tIdx).T(mixArr(tIdx).TRELAX.HV),[],NWALL);
                
                % Initialize PSEUDO
                mixArr(tIdx).PSEUDO.WV   = mixArr(tIdx).XEQ.*mixArr(tIdx).WNEARWALL;
                mixArr(tIdx).PSEUDO.XEQ  = repmat(mixArr(tIdx).XEQ,1,NWALL);

            end

            % Store transient mixture array
            mixSolver.mixture = mixArr;

            % Create steady state mixture array
            mixSolver.mixtureInit = copy( ...
                repmat(mixArr(1),1,mixSolver.inputSet.options.SSMAXITER));

            % Update mixtureInit times and timesteps
            initTIMEDT = mixSolver.inputSet.options.SSTSTEP;
            initNTIME = length(mixSolver.mixtureInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(mixSolver.mixtureInit);

            for i = 1:length(mixSolver.mixtureInit)
                mixSolver.mixtureInit(i).TIME = initTIME(i);
                mixSolver.mixtureInit(i).DT = initTIMEDT;
                mixSolver.mixtureInit(i).NTIME = initNTIME;
                mixSolver.mixtureInit(i).TIDX = initTIDX(i);
            end

            % set STATE to UNSOLVED
            mixSolver.STATE = SolverState.UNSOLVED;

        end

        function mixSolver = interpBoundaryConditions(mixSolver)
        %INTERPBOUNDARYCONDITIONS Expand specified boundary conditions
        %to every node and timestep defined by the model and geometry.
        %
            
            % Retrieve list of boundary condition properties
            bcFields = mixSolver.inputSet.bc.listInputProperties();

            % Interpolate bc properties in time
            params = checkParams({'TIME','PRESSURE','HIN','MFLOW','POWER'});
            mixSolver.boundaryConditions = cell2struct( ...
                                        arrayfun( ...
                                            @(idx) mixSolver.timeInterpolate([mixSolver.inputSet.bc.(params(idx))]), ...
                                            1:length(params), ...
                                            'UniformOutput',false),...
                                        params,...
                                        2);

            % Interpolate wall power in space
            WPOWERZ = arrayfun( ...
                        @(bc)mixSolver.axialInterpolate( ...
                                        cumsum(bc.WMESH), ...
                                        bc.WPOWER ...
                                        ), ...
                        mixSolver.inputSet.bc, ...
                        'UniformOutput',false ...
                        );
            % Combine WPOWERZ to NZ x NWALL x N_bc
            WPOWERZ = reshape( ...
                            cell2mat(WPOWERZ), ...
                            mixSolver.NZ, ...
                            mixSolver.inputSet.geometry.NWALL, ...
                            []);
            
            % Interpolate wall power in time
            WPOWERT = arrayfun( ...
                        @(wallIdx) mixSolver.timeInterpolate( ...
                                    reshape(WPOWERZ(:,wallIdx,:), ...
                                        mixSolver.NZ, ...
                                        [] ...
                                   ).').', ...
                                   1:mixSolver.inputSet.geometry.NWALL, ...
                                   'UniformOutput',false);
            % Reorganize WPOWERT to NZ x NWall x NTIME
            WPOWERT = permute( ...
                        reshape( ...
                            cell2mat(WPOWERT), ...
                            mixSolver.NZ, ...
                            mixSolver.NTIME, ...
                            [] ...
                        ), [1 3 2]);
            
            mixSolver.boundaryConditions.WPOWER = WPOWERT;            
            
            % Calculate wall heat flux at each node in space & time
            % NOTE: This is very convoluted
            mixSolver.boundaryConditions.HFLUX = ...
                mixSolver.boundaryConditions.WPOWER .* reshape(mixSolver.boundaryConditions.POWER,1,1,[]) ...
                ./ sum(reshape( ...
                        mixSolver.inputSet.geometry.PERIM .* mixSolver.DZ,1,mixSolver.inputSet.geometry.NWALL,1 ...
                        ).* ...
                       mixSolver.boundaryConditions.WPOWER(2:end,:,:),[1,2] ...
                      );

            function validParams = checkParams(params)
            %CHECKPARAMS Ensure interpolation parameters are valid
            %parameters of the boundaryCondition mix.
                
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

        function plotter = plotz(mixSolver, tIdx, opt)
        %PLOTZ Plot spatial distributions of mixture parameters
        %
        %   NOTE: currently supports only single timeStep
        %
            arguments
                mixSolver
                tIdx            (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} = 1
                opt.display     {mustBeMember(opt.display,{'HFLUX','W','DP','U','DUDT','H','DHDT','VR','T','X','PWE','PEE','TRELAX','ALL'})} = {'HFLUX','W','DP','U','H','VR'}
                opt.solveMode   {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}            = 'TRANSIENT'
                opt.wall        (1,:) double {mustBeVector,mustBeInteger,mustBePositive}        = 1:mixSolver.inputSet.geometry.NWALL
                opt.zIdx        (:,1) double {mustBeVector,mustBeInteger,mustBePositive}        = 1:mixSolver.NZ
                opt.unitTemp    {mustBeMember(opt.unitTemp,{'K','C'})}                          = 'K'
                opt.arrangement {mustBeMember(opt.arrangement,{'flow','vertical','horizontal'})} = 'flow'
            end
            
            if isempty(opt.wall), opt.wall = 1:mixSolver.inputSet.geometry.NWALL; end
            if length(opt.zIdx) < 2
                mixSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            
            z     = mixSolver.Z(opt.zIdx);
            bc    = mixSolver.boundaryConditions;
            model = mixSolver.inputSet.model;
            geom  = mixSolver.inputSet.geometry;
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture(tIdx);
                case 'STEADY'
                    mix = mixSolver.mixtureInit(tIdx);
                    tIdx = 1;
            end
            
            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end

            bcHFLUX = bc.HFLUX(opt.zIdx,:,tIdx);

            plotter = Solvers.SolverPlotter( ...
                                sprintf('Axial distributions of mixture parameters at %0.3f [s] - %s', mix.TIME, opt.solveMode), ...
                                opt.wall,opt.arrangement);
            plotter.setZs(z);
            
            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    "tileTitle",         'Wall heat flux', ...
                    'xlabel'   ,     'Axial position [m]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plotz(  bcHFLUX                       ,'bc'         ,'DisplayName','Boundary Condition');
                plotter.plotz(mix.HFLUX(opt.zIdx,:)           ,'Mixture'                                       );
                if ismember('RELAXATION',model.THERMALNONEQ)
                    plotter.plotz(mix.liquid.HFLUX(opt.zIdx)      ,'Liquid'                                      );
                    plotter.plotz(mix.vapor.HFLUX(opt.zIdx)       ,'Vapor'                                       );
                    plotter.plotz(mix.vapor.HFLUXWALEVAP(opt.zIdx),'Evaporation','DisplayName','Wall evaporation');
                end
                if ~strcmp(model.CBT,'NONE')
                    plotter.plotz(mix.CHF(opt.zIdx)               ,'CHF'                                         );
                end
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',       'Mass flow rates', ...
                    'xlabel'   ,    'Axial position [m]', ...
                    'ylabel'   , 'Mass flow rate [kg/s]');
                
                plotter.plotz(mix.W(opt.zIdx)       ,'Mixture');
                plotter.plotz(mix.liquid.W(opt.zIdx),'Liquid' );
                plotter.plotz(mix.vapor.W(opt.zIdx) ,'Vapor'  );
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.TRELAX.WV(opt.zIdx,:) ,'WallVapor','DisplayName','Vapor (wall level)');
                end
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
            end

            % Pressure drops
            if any(ismember({'DP','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',     'Pressure drops', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   , 'Pressure drop [Pa]');
                plotter.plotz(mix.DPSUM.Grav(opt.zIdx) ,'Gravitational'                     )
                plotter.plotz(mix.DPSUM.Wall(opt.zIdx) ,'Wall'                              )
                plotter.plotz(mix.DPSUM.Acc_z(opt.zIdx),'Z'           ,'DisplayName','Acc Z')
                plotter.plotz(mix.DPSUM.Acc_t(opt.zIdx),'T'           ,'DisplayName','Acc t')
                plotter.plotz(mix.DPSUM.K(opt.zIdx)    ,'Local'                             )
                plotter.plotz(mix.DPSUM.Tot(opt.zIdx)  ,'Total'                             )
                plotter.legend('show', "Location", 'best');
                plotter.xlim([min(z) max(z)]);
            end
            
             % Velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Velocities', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,     'Velocity [m/s]');
                plotter.plotz(mix.U(opt.zIdx)       ,'Mixture')
                plotter.plotz(mix.liquid.U(opt.zIdx),'Liquid' )
                plotter.plotz(mix.vapor.U(opt.zIdx) ,'Vapor'  )
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
            end

            % Hydrodynamic accelerations
            if any(ismember({'DUDT','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle','Hydrodynamic accelerations', ...
                    'xlabel'   ,        'Axial position [m]', ...
                    'ylabel'   ,      'Acceleration [m/s^2]');
                plotter.plotz(mix.MDER.U_z(opt.zIdx),'Z','DisplayName','Convective')
                plotter.plotz(mix.MDER.U_t(opt.zIdx),'T','DisplayName','Local'     )
                plotter.plotz(mix.MDER.U(opt.zIdx)  ,'Mixture'                     )
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
            end
            
            % Enthalpies
            if any(ismember({'H','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Enthalpies', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,    'Enthalpy [J/kg]');
                
                plotter.plotz(mix.H(opt.zIdx)       ,'Mixture');
                plotter.plotz(mix.liquid.H(opt.zIdx),'Liquid' );
                plotter.plotz(mix.vapor.H(opt.zIdx) ,'Vapor'  );
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.TRELAX.HV(opt.zIdx,:) ,'WallVapor','DisplayName','Vapor (wall level)');
                end
                plotter.plotz(repmat(mixSolver.fluid(tIdx).HF,mixSolver.NZ,1),'SatLiq','DisplayName','Sat liquid');
                plotter.plotz(repmat(mixSolver.fluid(tIdx).HG,mixSolver.NZ,1),'SatVap','DisplayName','Sat vapor');
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end
            
            % Rates of change of enthalpy
            if any(ismember({'DHDT','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Rates of change of enthalpy', ...
                    'xlabel'   ,                  'Axial position [m]', ...
                    'ylabel'   , 'Rate of change of enthalpy [J/kg/s]');
                plotter.plotz(mix.MDER.H_z(opt.zIdx),'Z','DisplayName','Convective')
                plotter.plotz(mix.MDER.H_t(opt.zIdx),'T','DisplayName',     'Local')
                plotter.plotz(mix.MDER.H(opt.zIdx)  ,'Mixture'                     )
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
            end
            
            % Vapor ratios (void fraction and qualities)
            if any(ismember({'VR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Void fractions and qualities', ...
                    'xlabel'   ,           'Axial position [m]', ...
                    'ylabel'   ,  'Quality / Void fraction [-]');
                plotter.plotz(mix.XEQ(opt.zIdx),'Equil'       ,'DisplayName','Equilibrium quality')
                plotter.plotz(mix.X(opt.zIdx)  ,'Vapor'       ,'DisplayName','Vapor mass quality' )
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.TRELAX.X(opt.zIdx,:) ,'WallVapor','DisplayName','Vapor mass quality (wall level)');
                end
                plotter.plotz(mix.VF(opt.zIdx) ,'VoidFraction','DisplayName','Void fraction'      )
                plotter.legend('show', "Location", 'best');
                plotter.xlim([min(z) max(z)]);
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end
            
            % Temperatures
            if any(ismember({'T','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',                    'Temperatures', ...
                    'xlabel'   ,              'Axial position [m]', ...
                    'ylabel'   , ['Temperature [' opt.unitTemp ']']);
                
                plotter.plotz(mix.T(opt.zIdx)       +dTemp,'Mixture');
                plotter.plotz(mix.liquid.T(opt.zIdx)+dTemp,'Liquid' );
                plotter.plotz(mix.vapor.T(opt.zIdx) +dTemp,'Vapor'  );
                plotter.plotz(mix.TWALL(opt.zIdx)   +dTemp,'Wall'   );
                plotter.plotz(repmat(mixSolver.fluid(tIdx).TSAT,mixSolver.NZ,1)+dTemp,'Saturation');
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end
            
            % Mass exchanges
            if all([any(ismember({'PWE','ALL'},opt.display)) ismember('RELAXATION',model.THERMALNONEQ)])
                plotter.newTile( ...
                    'tileTitle',   'Vapor mass exchanges', ...
                    'xlabel'   ,     'Axial position [m]', ...
                    'ylabel'   , 'Mass exchange [kg/s/m]');
                
                plotter.plotz(mix.MWALEVAP(opt.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(mix.MINTEVAP(opt.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(mix.MINTCOND(opt.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(mix.MTOT(opt.zIdx)    ,'Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
            end
            
            % Energy exchanges
            if all([any(ismember({'PEE','ALL'},opt.display)) ismember('RELAXATION',model.THERMALNONEQ)])
                plotter.newTile( ...
                    'tileTitle', 'Vapor energy exchanges', ...
                    'xlabel'   ,     'Axial position [m]', ...
                    'ylabel'   ,  'Energy exchange [W/m]');
                
                plotter.plotz(mix.HWALHEAT(opt.zIdx),'Wall'           ,'DisplayName','Wall heat rate'          );
                plotter.plotz(mix.HWALEVAP(opt.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(mix.HINTEVAP(opt.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(mix.HINTCOND(opt.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(mix.HTOT(opt.zIdx)    ,'Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
            end
            
            % Qualities
            if any(ismember({'X','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',          'Qualities', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,        'Quality [-]');
                plotter.plotz(mix.XEQ(opt.zIdx)         ,'Equil'     ,'DisplayName','Equilibrium quality' )
                plotter.plotz(mix.X(opt.zIdx)           ,'Vapor'     ,'DisplayName','Vapor mass quality'  )
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.TRELAX.X(opt.zIdx,:)  ,'WallVapor' ,'DisplayName','Vapor mass quality (wall level)')
                end
                plotter.plotz(mix.PSEUDO.XEQ(opt.zIdx,:),'PseudoEquil','DisplayName','Pseudo-equilibrium quality')
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

            % Thermal time relaxations
            if any(ismember({'TRELAX'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Thermal time relaxations', ...
                    'xlabel'   ,       'Axial position [m]', ...
                    'ylabel'   ,      'Relaxation time [s]');
                plotter.plotz(mix.TRELAX.TEVAP(opt.zIdx,:),'InterfacialEvap','DisplayName','Interfacial evaporation')
                plotter.plotz(mix.TRELAX.TCOND(opt.zIdx,:),'InterfacialCond','DisplayName','Interfacial condensation')
                plotter.plotz(mix.PSEUDO.TRELAX(opt.zIdx,:),'PseudoEquil','DisplayName','Pseudo-equilibrium quality')
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

        end
        
        function plotter = plott(mixSolver, zIdx, opt)
        %PLOTT Plot temporal distributions of mixture parameters
        %
        %   NOTE: currently supports only single elevation
        %
            arguments
                mixSolver
                zIdx            (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} = mixSolver.NZ
                opt.display     {mustBeMember(opt.display,{'HFLUX','W','DP','U','DUDT','H','DHDT','VR','T','X','PWE','PEE','TRELAX','ALL'})} = {'HFLUX','W','DP','U','H','VR'}
                opt.solveMode   {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}            = 'TRANSIENT'
                opt.wall        (1,:) double {mustBeVector,mustBeInteger,mustBePositive}        = 1:mixSolver.inputSet.geometry.NWALL
                opt.tIdx        (:,1) double {mustBeVector,mustBeInteger,mustBePositive}        = 1:mixSolver.NTIME
                opt.reverseTime (1,1) logical                                                   = false
                opt.unitTemp    {mustBeMember(opt.unitTemp,{'K','C'})}                          = 'K'
                opt.arrangement {mustBeMember(opt.arrangement,{'flow','vertical','horizontal'})} = 'flow'
            end
            
            if isempty(opt.wall), opt.wall = 1:mixSolver.inputSet.geometry.NWALL; end
            
            model = mixSolver.inputSet.model;
            geom  = mixSolver.inputSet.geometry;

            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture(opt.tIdx);
                    fld = mixSolver.fluid(opt.tIdx);
                    bcHFLUX = permute(mixSolver.boundaryConditions.HFLUX(zIdx,:,:),[3 2 1]);
                case 'STEADY'
                    if isequal(opt.tIdx,[1:mixSolver.NTIME]')
                        opt.tIdx = 1:length(mixSolver.mixtureInit);
                    end
                    mix = mixSolver.mixtureInit(opt.tIdx);
                    fld = repmat(mixSolver.fluid(1),1,length(opt.tIdx));
                    bcHFLUX = repmat(mixSolver.boundaryConditions.HFLUX(zIdx,:,1),length(opt.tIdx),1);
            end
            
            time = [mix.TIME];
            if length(time) < 2
                mixSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            if opt.reverseTime
                time = time -time(end);
            end
            
            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end

            z = mixSolver.Z;
            plotter = Solvers.SolverPlotter( ...
                                sprintf('Time distributions of mixture parameters at %0.3f [m] - %s', z(zIdx), opt.solveMode), ...
                                opt.wall,opt.arrangement);
            plotter.setZs(time);
            
            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Wall heat flux', ...
                    'xlabel'   ,               'Time [s]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plotz(             bcHFLUX               ,'bc'     ,'DisplayName','Boundary Condition');
                plotter.plotz(mix.transient('HFLUX','zIdx',zIdx)','Mixture'                                   );
                if ismember('RELAXATION',model.THERMALNONEQ)
                    plotter.plotz(mix.transient('liquid.HFLUX'       ,'zIdx',zIdx)','Liquid'                                      );
                    plotter.plotz(mix.transient( 'vapor.HFLUX'       ,'zIdx',zIdx)','Vapor'                                       );
                    plotter.plotz(mix.transient( 'vapor.HFLUXWALEVAP','zIdx',zIdx)','Evaporation','DisplayName','Wall evaporation');
                end
                if ~strcmp(model.CBT,'NONE')
                    plotter.plotz(mix.transient('CHF'                ,'zIdx',zIdx)','CHF'                                         );
                end
                plotter.legend('show', 'Location', 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',       'Mass flow rates', ...
                    'xlabel'   ,              'Time [s]', ...
                    'ylabel'   , 'Mass flow rate [kg/s]');
                plotter.plotz(mix.transient(       'W','zIdx',zIdx)','Mixture');
                plotter.plotz(mix.transient('liquid.W','zIdx',zIdx)','Liquid' );
                plotter.plotz(mix.transient( 'vapor.W','zIdx',zIdx)','Vapor'  );
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.transient('TRELAX.WV','zIdx',zIdx)','WallVapor','DisplayName','Vapor (wall level)' );
                end
                plotter.legend('show', 'Location', 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

            % Pressure drops
            if any(ismember({'DP','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',     'Pressure drops', ...
                    'xlabel'   ,           'Time [s]', ...
                    'ylabel'   , 'Pressure drop [Pa]');
                plotter.plotz(mix.transient('DPSUM.Grav' ,'zIdx',zIdx)','Gravitational'          );
                plotter.plotz(mix.transient('DPSUM.Wall' ,'zIdx',zIdx)','Wall'                   );
                plotter.plotz(mix.transient('DPSUM.Acc_z','zIdx',zIdx)','Z','DisplayName','Acc Z');
                plotter.plotz(mix.transient('DPSUM.Acc_t','zIdx',zIdx)','T','DisplayName','Acc t');
                plotter.plotz(mix.transient('DPSUM.K'    ,'zIdx',zIdx)','Local'                  );
                plotter.plotz(mix.transient('DPSUM.Tot'  ,'zIdx',zIdx)','Total'                  );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',     'Velocities', ...
                    'xlabel'   ,       'Time [s]', ...
                    'ylabel'   , 'Velocity [m/s]');
                plotter.plotz(mix.transient(       'U','zIdx',zIdx)','Mixture');
                plotter.plotz(mix.transient('liquid.U','zIdx',zIdx)','Liquid' );
                plotter.plotz(mix.transient( 'vapor.U','zIdx',zIdx)','Vapor'  );
                plotter.legend('show', 'Location', 'best');
            end

            % Hydrodynamic accelerations
            if any(ismember({'DUDT','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle','Hydrodynamic accelerations', ...
                    'xlabel'   ,                  'Time [s]', ...
                    'ylabel'   ,      'Acceleration [m/s^2]');
                plotter.plotz(mix.transient('MDER.U_z','zIdx',zIdx)','Z','DisplayName','Convective' )
                plotter.plotz(mix.transient('MDER.U_t','zIdx',zIdx)','T','DisplayName','Local'      )
                plotter.plotz(mix.transient('MDER.U'  ,'zIdx',zIdx)','Mixture'                      )
                plotter.legend('show', 'Location', 'best');
            end
            
            % Enthalpies
            if any(ismember({'H','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',      'Enthalpies', ...
                    'xlabel'   ,        'Time [s]', ...
                    'ylabel'   , 'Enthalpy [J/kg]');
                plotter.plotz(mix.transient('H','zIdx',zIdx)','Mixture');
                plotter.plotz(mix.transient('liquid.H','zIdx',zIdx)','Liquid'                           );
                plotter.plotz(mix.transient( 'vapor.H','zIdx',zIdx)','Vapor'                            );
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.transient('TRELAX.HV','zIdx',zIdx)','WallVapor','DisplayName','Vapor (wall level)' );
                end
                plotter.plotz(fld.transient('HF')'                  ,'SatLiq','DisplayName','Sat liquid');
                plotter.plotz(fld.transient('HG')'                  ,'SatVap','DisplayName','Sat vapor' );
                plotter.legend('show', 'Location', 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

            % Rates fo change of enthalpy
            if any(ismember({'DUDH','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Rates of change of enthalpy', ...
                    'xlabel'   ,                            'Time [s]', ...
                    'ylabel'   , 'Rate of change of enthalpy [J/kg/s]');
                plotter.plotz(mix.transient('MDER.H_z','zIdx',zIdx)','Z','DisplayName','Convective')
                plotter.plotz(mix.transient('MDER.H_t','zIdx',zIdx)','T','DisplayName','Local'     )
                plotter.plotz(mix.transient('MDER.H'  ,'zIdx',zIdx)','Mixture'                     )
                plotter.legend('show', 'Location', 'best');
            end
            
            % Vapor ratios (void fraction and qualities)
            if any(ismember({'VR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Void fraction and qualities', ...
                    'xlabel'   ,                    'Time [s]', ...
                    'ylabel'   , 'Quality / Void fraction [-]');
                plotter.plotz(mix.transient('XEQ','zIdx',zIdx)','Equil','DisplayName','Equilibrium quality');
                plotter.plotz(mix.transient('X'  ,'zIdx',zIdx)','Vapor','DisplayName','Vapor mass quality' );
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.transient('TRELAX.X','zIdx',zIdx)','WallVapor','DisplayName','Vapor mass quality (wall level)' );
                end
                plotter.plotz(mix.transient('VF' ,'zIdx',zIdx)','VF'   ,'DisplayName','Void faction'       );
                plotter.legend("show", "Location", 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end
            
            % Temperatures
            if any(ismember({'T','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',                    'Temperatures', ...
                    'xlabel'   ,                        'Time [s]', ...
                    'ylabel'   , ['Temperature [' opt.unitTemp ']']);
                plotter.plotz(mix.transient('T','zIdx',zIdx)'       +dTemp,'Mixture'   );
                plotter.plotz(mix.transient('liquid.T','zIdx',zIdx)'+dTemp,'Liquid'    );
                plotter.plotz(mix.transient('vapor.T','zIdx',zIdx)' +dTemp,'Vapor'     );
                plotter.plotz(mix.transient('TWALL','zIdx',zIdx)'   +dTemp,'Wall'      );
                plotter.plotz(fld.transient('TSAT')'                +dTemp,'Saturation');
                plotter.legend('show', 'Location', 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end
            
            % Mass exchanges
            if all([any(ismember({'PWE','ALL'},opt.display)) ismember('RELAXATION',model.THERMALNONEQ)])
                plotter.newTile( ...
                    'tileTitle',   'Vapor mass exchanges', ...
                    'xlabel'   ,               'Time [s]', ...
                    'ylabel'   , 'Mass exchange [kg/s/m]');
                
                plotter.plotz(mix.transient('MWALEVAP','zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(mix.transient('MINTEVAP','zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(mix.transient('MINTCOND','zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(mix.transient('MTOT'    ,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
            end
            
            % Energy exchanges
            if all([any(ismember({'PEE','ALL'},opt.display)) ismember('RELAXATION',model.THERMALNONEQ)])
                plotter.newTile( ...
                    'tileTitle', 'Vapor energy exchanges', ...
                    'xlabel'   ,               'Time [m]', ...
                    'ylabel'   ,  'Energy exchange [W/m]');
                
                plotter.plotz(mix.transient('HWALHEAT','zIdx',zIdx)','Wall'           ,'DisplayName','Wall heat rate'          );
                plotter.plotz(mix.transient('HWALEVAP','zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(mix.transient('HINTEVAP','zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(mix.transient('HINTCOND','zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(mix.transient('HTOT'    ,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
            end
            
            % Qualities
            if any(ismember({'X','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Qualities', ...
                    'xlabel'   ,    'Time [s]', ...
                    'ylabel'   , 'Quality [-]');
                plotter.plotz(mix.transient(       'XEQ','zIdx',zIdx)','Equil'     ,'DisplayName','Equilibrium quality' );
                plotter.plotz(mix.transient(       'X'  ,'zIdx',zIdx)','Vapor'     ,'DisplayName','Vapor mass quality'  );
                if all([ismember('RELAXATION',model.THERMALNONEQ) geom.NWALL > 1])
                    plotter.plotz(mix.transient('TRELAX.X'  ,'zIdx',zIdx)','RelaxVapor','DisplayName','Vapor mass quality (wall level)');
                end
                plotter.plotz(mix.transient('PSEUDO.XEQ','zIdx',zIdx)','PseudoEquil','DisplayName','Pseudo-equilibrium quality');
                plotter.legend('show', 'Location', 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end

            % Thermal time relaxations
            if any(ismember({'TRELAX'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Thermal time relaxations', ...
                    'xlabel'   ,                 'Time [s]', ...
                    'ylabel'   ,      'Relaxation time [s]');
                plotter.plotz(mix.transient('TRELAX.TEVAP','zIdx',zIdx)' ,'InterfacialEvap','DisplayName','Interfacial evaporation')
                plotter.plotz(mix.transient('TRELAX.TCOND','zIdx',zIdx)' ,'InterfacialCond','DisplayName','Interfacial condensation')
                plotter.plotz(mix.transient('PSEUDO.TRELAX','zIdx',zIdx)','PseudoEquil','DisplayName','Pseudo.equilibrium quality')
                plotter.legend('show', 'Location', 'best');
                ymin = min(arrayfun(@(x) min(x.YLim),plotter.gca))-1E-6;
                ymax = max(arrayfun(@(x) max(x.YLim),plotter.gca))+1E-6;
                plotter.ylim([ymin ymax]);
            end
        end

        function fh = plotzt(mixSolver, opt)
        %PLOTZT: Plot 2D time/elevation distributions of mixture parameters
        %
            arguments
                mixSolver
                opt.display      {mustBeA(opt.display,{'cell','char'})}                   = {         'HFLUX',             'W',    'DPSUM.Tot',       'U',       'H',                 'X',           'VF'}
                opt.label        {mustBeA(opt.label,{'cell','char'})}                     = {'wall heat flux','mass flow rate','pressure drop','velocity','enthalpy','steam mass quality','void fraction'}
                opt.unit         {mustBeA(opt.unit,{'cell','char'})}                      = {         'W/m^2',          'kg/s',           'Pa',     'm/s',    'J/kg',                 '-',            '-'}
                opt.field         {mustBeMember(opt.field,{'mixture','liquid','vapor'})}    = {'mixture'}
                opt.solveMode    {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}     = 'TRANSIENT'
                opt.wall         (1,:) double {mustBeVector,mustBeInteger,mustBePositive} = 1:mixSolver.inputSet.geometry.NWALL
                opt.zIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:mixSolver.NZ
                opt.tIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:mixSolver.NTIME
                opt.reverseTime  (1,1) logical                                            = false
                opt.shading      {mustBeMember(opt.shading,{'faceted','flat','interp'})}   = 'interp'
                opt.view         (1,2) double                                             = [0 90]
            end
            
            if ~iscell(opt.display), opt.display = {opt.display}; end
            if ~iscell(opt.label)  , opt.label   = {opt.label}  ; end
            if ~iscell(opt.unit)   , opt.unit    = {opt.unit}   ; end
            if strcmp('ALL',opt.display)
                opt.display = {        'HFLUX',            'W',    'DPSUM.Tot',       'U',       'H',                 'X',           'VF',          'T',           'TWALL'};
                opt.label   = {'Wall heat flux','mass flow rate','pressure drop','velocity','enthalpy','steam mass quality','void fraction','temperature','wall temperature'};
                opt.unit    = {        'W/m^2',          'kg/s',          'Pa',     'm/s',    'J/kg',                 '-',            '-',          'K',               'K'};
            end
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = mixSolver.mixture(opt.tIdx);
                case 'STEADY'
                    if isequal(opt.tIdx,[1:mixSolver.NTIME]')
                        opt.tIdx = 1:length(mixSolver.mixtureInit);
                    end
                    mix = mixSolver.mixtureInit(opt.tIdx);
            end
            if isempty(opt.wall)
                opt.wall = 1:mixSolver.inputSet.geometry.NWALL;
            end
            if length(opt.zIdx) < 2
                mixSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            if length(opt.tIdx) < 2
                mixSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            
            for k = opt.wall
                if ismember('mixture',opt.field)
                    fh = figure('name',['Time/axial distributions of mixture parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt);
                    end
                end
                if ismember('liquid',opt.field)
                    fh = figure('name',['Time/axial distributions of mixture (liquid) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP','TWALL'})
                            mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt);
                        else
                            mix.plotzt(['liquid.' opt.display{i}],['Liquid ' opt.label{i}],opt.unit{i},k,opt);
                        end
                    end
                end
                if ismember('liquid',opt.field)
                    fh = figure('name',['Time/axial distributions of mixture (vapor) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP','TWALL'})
                            mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt);
                        else
                            mix.plotzt(['vapor.' opt.display{i}],['Vapor ' opt.label{i}],opt.unit{i},k,opt);
                        end
                    end
                end
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
                        error('%s does not exist. Check Session.log.LOGMODE. Try session.makeSessionDirectory()',session.directory);
                    end
            end
        end

        function interpOut = timeInterpolate(mix, y)
        %TIMEINTERPOLATE
        %
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
        %AXIALINTERPOLATE Linear extrapolation is used for cases where
        %interpolation returns NaN (for instance, point slightly outside
        %allowed tolerance when 'next' interpolation method is selected)
        %
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

