classdef FourFieldSolver < Solvers.ThreeField.ThreeFieldSolver
    %FOURFIELDSOLVER defines any task related to initalizing, solving and plotting the results based on the four-field approach.
    %
    %   TODO: Detailed explanations
    
     properties (SetAccess=protected)
        
%         NZ           (1,1) double  {mustBeNumeric}                         = 0         % Number of axial steps [-]
%         NTIME        (1,1) double  {mustBeNumeric}                         = 0         % Number of time steps [-]
%         TIME         (:,1) double  {mustBeNumeric}                         = 0         % Time series [s]
%         DT           (1,1) double  {mustBeNumeric}                         = 0         % Time step size [s]
%         Z            (:,1) double  {mustBeNumeric}                         = 1.        % Elevation [m]
%         DZ           (1,1) double  {mustBeNumeric}                         = 0         % Axial step size [m]
%         
%         fluid       {isa(fluid,'Inputs.FluidProperties')}
%         boundaryConditions
%         
%         filmInit
%         dropInit
%         fluidInit
%         film
%         drop

     end

     properties (SetAccess = protected)
        % mixSolver
        % inputSet
        % STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(tfSolver)
    end

    methods
        
        function ffSolver = FourFieldSolver(inputSet,mixSolver)
            %FOURFIELDSOLVER Creates a FourField solver
            %
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            ffSolver = ffSolver@Solvers.ThreeField.ThreeFieldSolver(inputSet,mixSolver);
            
            % % Store mixSolver handle
            % ffSolver.mixSolver = mixSolver;
            % 
            % % Attempt to solve mixSolver if it is unsolved
            % if ffSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
            %     ffSolver.mixSolver.solve();
            % end
            % 
            % % Initialize solver parameters
            % ffSolver.initializeSolver();
        end
        
        function initializeSolver(ffSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            import Inputs.*
            import Solvers.FourField.*
            import Solvers.SolverState
            
            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                ffSolver.(p{:}) = ffSolver.mixSolver.(p{:});
            end
            
            % Local parameters
            mixArr = ffSolver.mixSolver.mixture;                            % Mixture solution
            model  = ffSolver.inputSet.model;                               % Models
            geom   = ffSolver.inputSet.geometry;                            % Geometry
            
            % Setup inner iteration value struct
            ITRf = ffSolver.CreateITR(ffSolver.NZ, ["N","DWL","DU"]);
            ITRf.DWL = repmat(ITRf.DWL,1,geom.NWALL);
            ITRf.DU  = repmat(ITRf.DU,1,geom.NWALL);
            ITRd = ffSolver.CreateITR(ffSolver.NZ, ["N","DU"]);

            % Create film and drop arrays (by timestep)
            flmArr(ffSolver.NTIME) = Film();
            drpArr(ffSolver.NTIME) = Drop();
            props = {'NZ','Z','DZ','NTIME','DT','TIME','TIDX','inputSet','fluid', 'mix'};                 % film and drop properties
            
            for tIdx = 1:ffSolver.NTIME

                % Convenience variables (handles)
                flm         = flmArr(tIdx);
                drp         = drpArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = ffSolver.fluid(tIdx);
                
                % Inputset and fluid
                flm.inputSet = ffSolver.inputSet;
                flm.fluid    = fluid;

                % Corresponding Mixture
                flm.mix = mix;
                
                % Axial step sizes             
                flm.NZ = ffSolver.NZ;
                flm.DZ = ffSolver.DZ;
                flm.Z  = ffSolver.Z;
                
                % Time step
                flm.NTIME = ffSolver.NTIME;
                flm.DT    = ffSolver.DT;
                flm.TIME  = ffSolver.TIME(tIdx);
                flm.TIDX  = tIdx;
                
                % Copy properties to drop
                for p = props
                    drp.(p{:}) = flm.(p{:});
                end

                % ITR
                drp.ITR = ITRd;
                   
                % Wall/film evaporation heat flux
                HFLUX = mix.HFLUX;                                         % [W/m^2] Wall heat flux
                avgHFLUX = sum(HFLUX.*geom.PERIM,2)./sum(geom.PERIM);      % [W/m^2] Average heat flux
                avgHFLUX = repmat(avgHFLUX,1,geom.NWALL);                  % [W/m^2] ... distributed to all walls
                evapFn = [0;diff(mix.X)./diff(mix.XEQ)];                   % [-] Evaporation function
                evapFn(~isfinite(evapFn)) = 1;                             % [-] Fix potential division by 0
                flm.HFLUX = mix.AFDISTR(evapFn.*avgHFLUX,HFLUX);           % [W/m^2] Film evaporation heat flux
                    
                % Film evaporation (thermal equilibrium assumption)
                flm.MEVAP = -flm.HFLUX./(fluid.HG-fluid.HF);               % [kg/m^2/s] Evaporation mass flux

                % Initialize base and wave
                flm.initializeBaseAndWave();
                
                % Entrained ratio at onset of annular flow
                switch model.OAFENTRAINED
                    case InputEnums.OAFENTRAINED.RATIO
                        e0 = model.OAFDROPRATIO;
                    case InputEnums.OAFENTRAINED.EQUILIBRIUM
                        e0 = ffSolver.EQUIL(flm,drp,mix,mix.OAFIDX);
                end

                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note 1: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                % Note 2: other, maybe better, initialization states could be investigated
                drp.W = repmat(e0.*mix.OAFWL,ffSolver.NZ,1);               % [kg/s] Set drop mass flow to onset of annular flow conditions everywhere

                % Transient mass gradient in drop field
                drp.W = drp.W+mix.W-mix.W(mix.OAFIDX);                     % [kg/s] 
                
                % Transient mass gradient in film.base and film.wave,
                % set constant base mass flow in pre-annular flow region and recalculate drop mass flow rate
                flm.initializeBaseAndWave( ...
                                mix.liquid.W(1)-drp.W(1), ...              % Inlet flow rate (all walls)
                                ITRf ...                                   % Iteration struct
                             );
                flmW = flm.W(1:mix.OAFIDX,:);                              % [kg/s] Save total film flow rate
                flm.base.W(1:mix.OAFIDX,:) = repmat(flm.base.W(mix.OAFIDX,:),mix.OAFIDX,1); % [kg/s] Set constant base film flow rate 
                flm.wave.W(1:mix.OAFIDX,:) = max(0,flmW-flm.base.W(1:mix.OAFIDX,:)); % [kg/s] Adjust wave flow rate   
                
                drp.W = mix.liquid.W-sum(flm.W,2);                         % [kg/s] Recalculate consistent drop flow rate
                
                % Initialize velocity [m/s]
                %drp.U = mix.liquid.U;                                      % [m/s] Drop velocity
                drp.U = drp.USLIP();                                        % [m/s] Drop velocity
                
                %flm.U = repmat(mix.liquid.U,1,geom.NWALL); % [m/s]
                                                
                % Initialize enthalpy [J/kg] by number of spatial nodes, NZ
                drp.H = repmat(fluid.HF,ffSolver.NZ,1);                

            end

            % Store transient mixture array
            ffSolver.film = flmArr;
            ffSolver.drop = drpArr;

            % Create steady state arrays
            ffSolver.filmInit = copy( ...
                repmat(flmArr(1),1,ffSolver.inputSet.options.SSMAXITER));
            ffSolver.dropInit = copy( ...
                repmat(drpArr(1),1,ffSolver.inputSet.options.SSMAXITER));
            
            % Steady state fluidProperties
            ffSolver.fluidInit = FluidProperties( ...
                                    ffSolver.boundaryConditions.PRESSURE(1), ...
                                    ffSolver.inputSet.model);

            % Update filmInit and dropInit times and timesteps
            initTIMEDT = ffSolver.inputSet.options.SSTSTEP;
            initNTIME = length(ffSolver.filmInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(ffSolver.filmInit);

            for i = 1:length(ffSolver.filmInit)

                ffSolver.filmInit(i).TIME = initTIME(i);
                ffSolver.filmInit(i).DT = initTIMEDT;
                ffSolver.filmInit(i).NTIME = initNTIME;
                ffSolver.filmInit(i).TIDX = initTIDX(i);

                % Make copy of last mixtureInit
                ffSolver.filmInit(i).mix       = copy(ffSolver.mixSolver.mixtureInit(end));
                ffSolver.filmInit(i).mix.TIME  = initTIME(i);
                ffSolver.filmInit(i).mix.DT    = initTIMEDT;
                ffSolver.filmInit(i).mix.NTIME = initNTIME;
                ffSolver.filmInit(i).mix.TIDX  = initTIDX(i);

                % Initialize base and wave in each film
                ffSolver.filmInit(i).initializeBaseAndWave();

                ffSolver.dropInit(i).mix    = ffSolver.filmInit(i).mix;
                ffSolver.dropInit(i).TIME   = initTIME(i);
                ffSolver.dropInit(i).DT     = initTIMEDT;
                ffSolver.dropInit(i).NTIME  = initNTIME;
                ffSolver.dropInit(i).TIDX   = initTIDX(i);
                
            end

            % set STATE to UNSOLVED
            ffSolver.STATE = SolverState.UNSOLVED;
        end
        
        function e0 = EQUIL(ffSolver,flm,drp,mix,zIdx)
        %EQUIL find entrained ratio at film/drop equilibrium state (ent = dep)
        %
            errMax = 1E-4; errMax0 = errMax;                               % [kg/s/m] Convergence criterion
            nwall = ffSolver.inputSet.geometry.NWALL;                      % Number of walls
            perim = ffSolver.inputSet.geometry.PERIM;                      % [m] Perimeter
            W = mix.liquid.W(zIdx);                                        % [kg/s] Liquid flow rate
            
            for k = 1:100
                if k == 1
                    Wd(k) = 0.5.*W;                                        % [kg/s] Initial guess: 50% of liquid mass in droplet field
                elseif k == 2
                    Wd(k) = (0.7-double(delta(k-1)>0)*0.4).*W;             % [kg/s] Next guess: 30% or 70% of liquid mass in droplet field (depending on sign of delta)
                elseif k == 3
                    Wd(k) = max(min(interp1(delta,Wd,0,'linear','extrap'),W),0); % [kg/s] Next guess
                else
                    if all(diff(delta)./diff(Wd) > 0)
                        % Expected behavior
                        try
                            Wd(k) = max(min(interp1(delta(~isnan(delta)),Wd(~isnan(delta)),0,'linear','extrap'),W),0); % [kg/s] Next guess
                        catch
                            Wd(k) = max(min(Wd(k-1)*(1-20*delta(k-1)),W),0); % [kg/s] Next guess (in case interpolation fails)
                            Wd(k-1) = nan; delta(k-1) = nan;               % Remove previous iteration (avoid interpolation failure at next iteration)
                            errMax = errMax0*10;                           % Relax convergence criterion when interpolation fails
                        end
                    else
                        % Nonsensical behavior
                        Wd(k) = max(min(Wd(k-1)*(1-20*delta(k-1)),W),0);   % [kg/s] Next guess (ad-hoc sensitivity factor)
                        errMax = errMax0*10;                               % Relax convergence criterion for nonsensical behavior
                    end
                end
                drp.W(zIdx) = Wd(k);                                       % [kg/s] Update droplet mass flowrate
                flm.distributeOAFW((W-drp.W(zIdx)).*perim./sum(perim), zIdx); % [kg/s] Corresponding film flow distribution (considered uniform)
                delta(k) = drp.MDEP(zIdx).*sum(perim)+sum(flm.MENT(zIdx).*perim,2); % [kg/s/m] Linear deposition - entraiment mass flow rate
                err = abs(delta(k));
                if err < errMax, break; end
            end
            if err > errMax
                disp('Equilibrium entrainment ratio at onset of annular flow: not converged')
            end
            
            e0 = drp.W(zIdx)./W;                                           % [-] Entrained ratio
        end

        function plotter = plotz(ffSolver, tIdx, opt)
        %PLOTZ Plot spatial distributions of four-field parameters
        %
        %   NOTE: currently supports only single timeStep
        %
            arguments
                ffSolver
                tIdx          (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive}                                                     = 1
                opt.display   {mustBeMember(opt.display,{'HFLUX','W','WL','RE','U','THICK','FREQUENCY','WAL','BR','WR','FWE','FME','DME','ALL'})} = {'HFLUX','W','U','FREQUENCY'}
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}                                                                = 'TRANSIENT'
                opt.wall      (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                                                            = 1:ffSolver.inputSet.geometry.NWALL
                opt.zIdx      (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                                                            = 1:ffSolver.NZ
                opt.annular   (1,1) logical                                                                                                       = true
                opt.unitTemp  {mustBeMember(opt.unitTemp,{'K','C'})}                                                                              = 'K'
            end
            
            if isempty(opt.wall), opt.wall = 1:ffSolver.inputSet.geometry.NWALL; end
            if length(opt.zIdx) < 2
                ffSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            
            z   = ffSolver.Z(opt.zIdx);
            bc  = ffSolver.boundaryConditions;
        
            switch opt.solveMode
                case 'TRANSIENT'
                    flm = ffSolver.film(tIdx);
                    drp = ffSolver.drop(tIdx);
                case 'STEADY'
                    flm = ffSolver.filmInit(tIdx);
                    drp = ffSolver.dropInit(tIdx);
                    tIdx = 1;
            end
            
            if opt.annular
                zaf    = z(z >= flm.mix.OAFZ);
                zafIdx = opt.zIdx(opt.zIdx >= flm.mix.OAFIDX) - opt.zIdx(1) + 1;
            else
                zaf    = z;
                zafIdx = opt.zIdx;
            end

            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end
            
            mix = flm.mix;
            bcHFLUX = bc.HFLUX(opt.zIdx,:,tIdx);
            oafZ = repmat(mix.OAFZ,1,2);

            plotter = Solvers.SolverPlotter( ...
                                sprintf('Axial distributions of four-field parameters at %0.3f [s] - %s', flm.TIME, opt.solveMode), ...
                                opt.wall);
            plotter.setZs(z);

            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Wall heat flux', ...
                    'xlabel'   ,     'Axial position [m]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plotz(  bcHFLUX            ,'bc'  ,'DisplayName','Boundary Condition');
                plotter.plotz(flm.HFLUX(opt.zIdx,:),'Film','XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end

            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Field mass flow rates', ...
                    'xlabel'   ,    'Axial position [m]', ...
                    'ylabel'   , 'Mass flow rate [kg/s]');
                plotter.plotz(sum([drp.W(opt.zIdx) flm.W(opt.zIdx,:)],2),'Liquid'                              );
                plotter.plotz(drp.W(opt.zIdx)                           ,'Drop'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.W(opt.zIdx)                           ,'Film'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.W(opt.zIdx,:)                    ,'Wave'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.W(opt.zIdx,:)                    ,'Base'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.WMIN(drp,opt.zIdx)               ,'Base min','XData',zaf,'subset',zafIdx);
                plotter.plotz(mix.vapor.W(opt.zIdx)                     ,'Vapor'                               );
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end

            % Film WL
            if any(ismember({'WL','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Film mass flow rates per unit perimeter', ...
                    'xlabel'   ,                      'Axial position [m]', ...
                    'ylabel'   ,            'Film mass flow rate [kg/s/m]');
                plotter.plotz(flm.WL(opt.zIdx)            ,'Film'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.WL(opt.zIdx)       ,'Wave'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.WL(opt.zIdx)       ,'Base'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.WMINL(drp,opt.zIdx),'Base min','XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location',  'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end
            
            % Reynolds numbers
            if any(ismember({'RE','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',               'Reynolds numbers', ...
                    'xlabel'   ,             'Axial position [m]', ...
                    'ylabel'   , {'Vapor Re [-]', 'Liquid Re [-]'});
                plotter.plotz(mix.vapor.RE(opt.zIdx),'Vapor','yyaxis', 'left');
                plotter.plotz(flm.wave.RE(opt.zIdx) , 'Wave','yyaxis','right','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.RE(opt.zIdx) , 'Base','yyaxis','right','XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end
            
            % Field velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',     'Field velocities', ...
                    'xlabel'   ,   'Axial position [m]', ...
                    'ylabel'   , 'Field velocity [m/s]');
                plotter.plotz(drp.U(opt.zIdx)       ,'Drop' ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.U(opt.zIdx)       ,'Film' ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.U(opt.zIdx,:),'Wave' ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.U(opt.zIdx,:),'Base' ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(mix.vapor.U(opt.zIdx) ,'Vapor'                            );
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end
            
            % Film thicknesses
            if any(ismember({'THICK','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Film thicknesses', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   , 'Film thickness [m]');
                plotter.plotz(flm.THICK(opt.zIdx)            ,'Film'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.THICK(opt.zIdx)       ,'Wave'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.AMPLITUDE(opt.zIdx)   ,'Wave Amp','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.THICK(opt.zIdx)       ,'Base'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.EQTHICK(opt.zIdx)     ,'Base Eq' ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.THICKMIN(drp,opt.zIdx),'Base Min','XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
                %plotters.ylim([0 1E-3]);
            end

            % Wave frequencies
            if any(ismember({'FREQUENCY','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Wave frequencies', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,     'Frequency [Hz]');
                plotter.plotz(flm.wave.FREQUENCY(opt.zIdx,:),'Wave'   ,'DisplayName','Non-equilibrium','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.EQFREQUENCY(opt.zIdx),'Wave Eq','DisplayName',    'Equilibrium','XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end

            % Wave axial lengths
            if any(ismember({'WAL','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',  'Wave axial lengths', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,   'Axial length [m]');
                plotter.plotz(flm.wave.SPACING(opt.zIdx),'Spacing','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.WIDTH(opt.zIdx)  ,  'Width','XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end

            % Base film/Film ratios
            if any(ismember({'BR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Base film/Film ratios', ...
                    'xlabel'   ,    'Axial position [m]', ...
                    'ylabel'   ,          'Fraction [-]');
                plotter.plotz(flm.base.EPSILON(opt.zIdx) ,'Vapor','DisplayName',        'Mass','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.BETA(opt.zIdx)    ,'Interfacial'                       ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.BETAP(opt.zIdx)   ,'Evaporation'                       ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.ETA(opt.zIdx)     ,'Deposition'                        ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FDRY(drp,opt.zIdx),'Base','DisplayName','Base dry time','XData',zaf,'subset',zafIdx);
                plotter.legend("show", 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
                plotter.ylim([0 1]);
            end

            % Wave/Film ratios
            if any(ismember({'WR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Wave/Film ratios', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,       'Fraction [-]');
                plotter.plotz(flm.wave.EPSILON(opt.zIdx)    ,'Vapor'      ,'DisplayName', 'Mass','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.BETA(opt.zIdx)       ,'Interfacial'                      ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.BETAP(opt.zIdx)      ,'Evaporation'                      ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.ETA(opt.zIdx)        ,'Deposition'                       ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.SHAPEFACTOR(opt.zIdx),'Wave'       ,'DisplayName','Shape','XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
                plotter.ylim([0 1]);
            end
            
            % Base film and wave mass exchanges
            if any(ismember({'FWE','ALL'},opt.display))
                ah_base = plotter.newTile( ...
                    'tileTitle', 'Base film mass exchanges', ...
                    'xlabel'   ,      'Axial position [m]', ...
                    'ylabel'   ,    'Mass flux [kg/s/m^2]');
                plotter.plotz(flm.base.MDEP(drp,opt.zIdx) , 'Deposition','DisplayName','Drop deposition'      ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.MENT(opt.zIdx)     ,'Entrainment','DisplayName','Base film entrainment','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.MEVAP(opt.zIdx)    ,'Evaporation','DisplayName','Base film evaporation','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.MWAVE(drp,opt.zIdx),'Wave'       ,'DisplayName','Exchange from wave'   ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.MTOT(drp,opt.zIdx) ,'Total'                                            ,'XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
                
                ah_wave = plotter.newTile( ...
                    "tileTitle",  'Wave mass exchanges', ...
                    'xlabel'   ,   'Axial position [m]', ...
                    'ylabel'   , 'Mass flux [kg/s/m^2]');
                plotter.plotz(flm.wave.MDEP(drp,opt.zIdx) ,'Deposition' ,'DisplayName','Drop deposition'   ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.MENT(opt.zIdx)     ,'Entrainment','DisplayName','Wave entrainment'  ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.MEVAP(opt.zIdx)    ,'Evaporation','DisplayName','Wave evaporation'  ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.MBASE(drp,opt.zIdx),'Wave'       ,'DisplayName','Exchange from base','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.MTOT(drp,opt.zIdx) ,'Total'                                         ,'XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_base)
                    linkaxes([ah_base(wallIdx), ah_wave(wallIdx)]);
                end
            end

            % Base film and wave momentum exchanges
            if any(ismember({'FME','ALL'},opt.display))
                ah_base = plotter.newTile( ...
                    'tileTitle', 'Base momentum exchanges', ...
                    'xlabel'   ,      'Axial position [m]', ...
                    'ylabel'   ,    'Shear stress [N/m^2]');
                plotter.plotz(flm.base.FDEP(drp)     ,'Deposition','DisplayName','Drop deposition','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FWALL()       ,'Wall'                                      ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FBASEVAPOR()  ,'Vapor'                                     ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FWAVE(drp)    ,'Wave'                                      ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FWAVEMASS(drp),'WaveMass'  ,'DisplayName',      'Wave mass','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FBUOY()       ,'Buoyancy'                                  ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FGRAV()       ,'Gravity'                                   ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.base.FTOT(drp)     ,'Total'                                     ,'XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
                
                ah_wave = plotter.newTile( ...
                    'tileTitle', 'Wave momentum exchanges', ...
                    'xlabel'   ,      'Axial position [m]', ...
                    'ylabel'   ,    'Shear stress [N/m^2]');
                plotter.plotz(flm.wave.FDEP(drp)     ,'Deposition','DisplayName','Drop deposition','XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.FSHEAR()      ,'Vapor'     ,'DisplayName','Vapor shear'    ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.FDRAG()       ,'VaporDrag' ,'DisplayName','Vapor drag'     ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.FBASE(drp)    ,'Wave'      ,'DisplayName','Base'           ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.FBASEMASS(drp),'WaveMass'  ,'DisplayName','Base mass'      ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.FBUOY()       ,'Buoyancy'                                  ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.FGRAV()       ,'Gravity'                                   ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(flm.wave.FTOT(drp)     ,'Total'                                     ,'XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
                
                % Link exchange axes
                for wallIdx = 1:length(ah_base)
                    linkaxes([ah_base(wallIdx), ah_wave(wallIdx)]);
                end
            end

            % Drop momentum exchanges
            if any(ismember({'DME','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Drop momentum exchanges', ...
                    'xlabel'   ,      'Axial position [m]', ...
                    'ylabel'   ,    'Shear stress [N/m^3]');
                plotter.plotz(drp.FENT(flm),'Entrainment', 'DisplayName', 'Film entrainment','XData',zaf,'subset',zafIdx);
                plotter.plotz(drp.FDRAG()  ,'Vapor'                                         ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(drp.FBUOY()  ,'Buoyancy'                                      ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(drp.FGRAV()  ,'Gravity'                                       ,'XData',zaf,'subset',zafIdx);
                plotter.plotz(drp.FTOT(flm),'Total'                                         ,'XData',zaf,'subset',zafIdx);
                plotter.legend('show', 'Location', 'best');
                plotter.xlim([min(z) max(z)]);
                plotter.plotOAF(oafZ);
            end
        end
        
        function plotter = plott(ffSolver, zIdx, opt)
        %PLOTT Plot temporal distributions of four-field parameters
        %
        %   NOTE: currently supports only single elevation
        %
            arguments
                ffSolver
                zIdx            (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive}                                                     = ffSolver.NZ
                opt.display     {mustBeMember(opt.display,{'HFLUX','W','WL','RE','U','THICK','FREQUENCY','WAL','BR','WR','FWE','FME','DME','ALL'})} = {'HFLUX','W','U','FREQUENCY'}
                opt.solveMode   {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}                                                                = 'TRANSIENT'
                opt.wall        (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                                                            = 1:ffSolver.inputSet.geometry.NWALL
                opt.tIdx        (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                                                            = 1:ffSolver.NTIME
                opt.reverseTime (1,1) logical                                                                                                       = false
                opt.unitTemp    {mustBeMember(opt.unitTemp,{'K','C'})}                                                                              = 'K'
            end
            
            if isempty(opt.wall), opt.wall = 1:ffSolver.inputSet.geometry.NWALL; end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = ffSolver.mixSolver.mixture(opt.tIdx);
                    %fld = ffSolver.mixSolver.fluid(opt.tIdx);
                    flm = ffSolver.film(opt.tIdx);
                    drp = ffSolver.drop(opt.tIdx);
                    bcHFLUX = permute(ffSolver.boundaryConditions.HFLUX(zIdx,:,:),[3 2 1]);
                case 'STEADY'
                    if isequal(opt.tIdx,[1:ffSolver.NTIME]')
                        opt.tIdx = 1:length(ffSolver.filmInit);
                    end
                    mix = ffSolver.mixSolver.mixtureInit(opt.tIdx);
                    %fld = repmat(ffSolver.mixSolver.fluid(1),1,length(opt.tIdx));
                    flm = ffSolver.filmInit(opt.tIdx);
                    drp = ffSolver.dropInit(opt.tIdx);
                    bcHFLUX = repmat(ffSolver.boundaryConditions.HFLUX(zIdx,:,1),length(opt.tIdx),1);
            end
            
            time = [flm.TIME];
            if length(time) < 2
                ffSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            if opt.reverseTime
                time = time -time(end);
            end
            
            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end

            z = ffSolver.Z;
            plotter = Solvers.SolverPlotter( ...
                                sprintf('Time distributions of four-field parameters at %0.3f [m] - %s', z(zIdx), opt.solveMode), ...
                                opt.wall);
            plotter.setZs(time);
            
            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Wall heat flux', ...
                    'xlabel'   ,               'Time [s]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plotz(             bcHFLUX               ,'bc'  ,'DisplayName','Boundary Condition');
                plotter.plotz(flm.transient('HFLUX','zIdx',zIdx)','Film'                                   );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Field mass flow rates', ...
                    'xlabel'   ,              'Time [s]', ...
                    'ylabel'   , 'Mass flow rate [kg/s]');
                liquidW = sum([drp.transient('W','zIdx',zIdx)' flm.transient('W','zIdx',zIdx)'],2);
                plotter.plotz(               liquidW                      ,'Liquid'  );
                plotter.plotz(drp.transient(      'W'       ,'zIdx',zIdx)','Drop'    );
                plotter.plotz(flm.transient(      'W'       ,'zIdx',zIdx)','Film'    );
                plotter.plotz(flm.transient( 'wave.W'       ,'zIdx',zIdx)','Wave'    );
                plotter.plotz(flm.transient( 'base.W'       ,'zIdx',zIdx)','Base'    );
                plotter.plotz(flm.transient( 'base.WMIN',drp,'zIdx',zIdx)','Base min');
                plotter.plotz(mix.transient('vapor.W'       ,'zIdx',zIdx)','Vapor'   );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Film WL
            if any(ismember({'WL','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Film mass flow rates per unit perimeter', ...
                    'xlabel'   ,                                'Time [s]', ...
                    'ylabel'   ,            'Film mass flow rate [kg/s/m]');
                plotter.plotz(flm.transient(     'WL'       ,'zIdx',zIdx)','Film'    );
                plotter.plotz(flm.transient('wave.WL'       ,'zIdx',zIdx)','Wave'    );
                plotter.plotz(flm.transient('base.WL'       ,'zIdx',zIdx)','Base'    );
                plotter.plotz(flm.transient('base.WMINL',drp,'zIdx',zIdx)','Base min');
                plotter.legend('show', 'Location', 'best');
            end
            
            % Reynolds numbers
            if any(ismember({'RE','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',               'Reynolds numbers', ...
                    'xlabel'   ,                       'Time [s]', ...
                    'ylabel'   , {'Vapor Re [-]', 'Liquid Re [-]'});
                plotter.plotz(mix.transient('vapor.RE','zIdx',zIdx)','Vapor','yyaxis','left' );
                plotter.plotz(flm.transient( 'wave.RE','zIdx',zIdx)','Wave' ,'yyaxis','right');
                plotter.plotz(flm.transient( 'base.RE','zIdx',zIdx)','Base' ,'yyaxis','right');
                plotter.legend('show', 'Location', 'best');
            end
            
            % Field velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',     'Field velocities', ...
                    'xlabel'   ,             'Time [s]', ...
                    'ylabel'   , 'Field velocity [m/s]');
                plotter.plotz(drp.transient(      'U','zIdx',zIdx)','Drop' );
                plotter.plotz(flm.transient(      'U','zIdx',zIdx)','Film' );
                plotter.plotz(flm.transient( 'wave.U','zIdx',zIdx)','Wave' );
                plotter.plotz(flm.transient( 'base.U','zIdx',zIdx)','Base' );
                plotter.plotz(mix.transient('vapor.U','zIdx',zIdx)','Vapor');
                plotter.legend('show', 'Location', 'best');
            end
            
            % Film thicknesses
            if any(ismember({'THICK','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Film thicknesses', ...
                    'xlabel'   ,           'Time [s]', ...
                    'ylabel'   , 'Film thickness [m]');
                plotter.plotz(flm.transient(     'THICK'       ,'zIdx',zIdx)','Film'    );
                plotter.plotz(flm.transient('wave.THICK'       ,'zIdx',zIdx)','Wave'    );
                plotter.plotz(flm.transient('wave.AMPLITUDE'   ,'zIdx',zIdx)','Wave Amp');
                plotter.plotz(flm.transient('base.THICK'       ,'zIdx',zIdx)','Base'    );
                plotter.plotz(flm.transient('base.EQTHICK'     ,'zIdx',zIdx)','Base Eq' );
                plotter.plotz(flm.transient('base.THICKMIN',drp,'zIdx',zIdx)','Base Min');
                plotter.legend('show', 'Location', 'best');
                %plotters.ylim([0 1E-3]);
            end
            
            % Wave frequencies
            if any(ismember({'FREQUENCY','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Wave frequencies', ...
                    'xlabel'   ,           'Time [s]', ...
                    'ylabel'   ,     'Frequency [Hz]');
                plotter.plotz(flm.transient('wave.FREQUENCY'  ,'zIdx',zIdx)','Wave'   ,'DisplayName','Non-equilibrium');
                plotter.plotz(flm.transient('wave.EQFREQUENCY','zIdx',zIdx)','Wave Eq','DisplayName',    'Equilibrium');
                plotter.legend('show', 'Location', 'best');
            end
            
            % Wave axial lengths
            if any(ismember({'WAL','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',  'Wave axial lengths', ...
                    'xlabel'   ,  'Axial position [m]', ...
                    'ylabel'   ,            'Time [s]');
                plotter.plotz(flm.transient('wave.SPACING','zIdx',zIdx)','Spacing');
                plotter.plotz(flm.transient('wave.WIDTH'  ,'zIdx',zIdx)','Width'  );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Base film/Film ratios
            if any(ismember({'BR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',  'Base film/Film ratios', ...
                    'xlabel'   ,               'Time [s]', ...
                    'ylabel'   ,           'Fraction [-]');
                plotter.plotz(flm.transient('base.EPSILON'    ,'zIdx',zIdx)','Vapor'      ,'DisplayName','Mass'         );
                plotter.plotz(flm.transient('base.BETA'       ,'zIdx',zIdx)','Interfacial'                              );
                plotter.plotz(flm.transient('base.BETAP'      ,'zIdx',zIdx)','Evaporation'                              );
                plotter.plotz(flm.transient('base.ETA'        ,'zIdx',zIdx)','Deposition'                               );
                plotter.plotz(flm.transient('base.FDRY'   ,drp,'zIdx',zIdx)','Base'       ,'DisplayName','Base dry time');
                plotter.legend('show', 'Location', 'best');
                plotter.ylim([0 1]);
            end
            
            % Wave/Film ratios
            if any(ismember({'WR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Wave/Film ratios', ...
                    'xlabel'   ,         'Time [s]', ...
                    'ylabel'   ,     'Fraction [-]');
                plotter.plotz(flm.transient('wave.EPSILON'    ,'zIdx',zIdx)','Vapor'      ,'DisplayName','Mass' );
                plotter.plotz(flm.transient('wave.BETA'       ,'zIdx',zIdx)','Interfacial'                      );
                plotter.plotz(flm.transient('wave.BETAP'      ,'zIdx',zIdx)','Evaporation'                      );
                plotter.plotz(flm.transient('wave.ETA'        ,'zIdx',zIdx)','Deposition'                       );
                plotter.plotz(flm.transient('wave.SHAPEFACTOR','zIdx',zIdx)','Wave'       ,'DisplayName','Shape');
                plotter.legend('show', 'Location', 'best');
                plotter.ylim([0 1]);
            end
            
            % Base film and wave mass exchanges
            if any(ismember({'FWE','ALL'},opt.display))
                ah_base = plotter.newTile( ...
                    'tileTitle', 'Base film mass exchanges', ...
                    'xlabel'   ,                 'Time [s]', ...
                    'ylabel'   ,    'Mass flux [kg/s/m^2]');
                plotter.plotz(flm.transient('base.MDEP' ,drp,'zIdx',zIdx)','Deposition' ,'DisplayName','Drop deposition'      );
                plotter.plotz(flm.transient('base.MENT'     ,'zIdx',zIdx)','Entrainment','DisplayName','Base film entrainment');
                plotter.plotz(flm.transient('base.MEVAP'    ,'zIdx',zIdx)','Evaporation','DisplayName','Base film evaporation');
                plotter.plotz(flm.transient('base.MWAVE',drp,'zIdx',zIdx)','Wave'       ,'DisplayName','Exchange from wave'   );
                plotter.plotz(flm.transient('base.MTOT' ,drp,'zIdx',zIdx)','Total'                                            );
                plotter.legend('show', 'Location', 'best');
                
                ah_wave = plotter.newTile( ...
                    'tileTitle',  'Wave mass exchanges', ...
                    'xlabel'   ,             'Time [s]', ...
                    'ylabel'   , 'Mass flux [kg/s/m^2]');
                plotter.plotz(flm.transient('wave.MDEP' ,drp,'zIdx',zIdx)','Deposition' ,'DisplayName','Drop deposition'   );
                plotter.plotz(flm.transient('wave.MENT'     ,'zIdx',zIdx)','Entrainment','DisplayName','Wave entrainment'  );
                plotter.plotz(flm.transient('wave.MEVAP'    ,'zIdx',zIdx)','Evaporation','DisplayName','Wave evaporation'  );
                plotter.plotz(flm.transient('wave.MBASE',drp,'zIdx',zIdx)','Wave'       ,'DisplayName','Exchange from base');
                plotter.plotz(flm.transient('wave.MTOT' ,drp,'zIdx',zIdx)','Total'                                         );
                plotter.legend('show', 'Location', 'best');
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_base)
                    linkaxes([ah_base(wallIdx), ah_wave(wallIdx)]);
                end
            end
            
            % Base film and wave momentum exchanges
            if any(ismember({'FME','ALL'},opt.display))
                ah_base = plotter.newTile( ...
                    'tileTitle', 'Base momentum exchanges', ...
                    'xlabel'   ,                'Time [s]', ...
                    'ylabel'   ,    'Shear stress [N/m^2]');
                plotter.plotz(flm.transient('base.FDEP'     ,drp,'zIdx',zIdx)','Deposition','DisplayName','Drop deposition');
                plotter.plotz(flm.transient('base.FWALL'        ,'zIdx',zIdx)','Wall'                                      );
                plotter.plotz(flm.transient('base.FBASEVAPOR'   ,'zIdx',zIdx)','Vapor'                                     );
                plotter.plotz(flm.transient('base.FWAVE'    ,drp,'zIdx',zIdx)','Wave'                                      );
                plotter.plotz(flm.transient('base.FWAVEMASS',drp,'zIdx',zIdx)','WaveMass','DisplayName'  ,'Wave mass'      );
                plotter.plotz(flm.transient('base.FBUOY'        ,'zIdx',zIdx)','Buoyancy'                                  );
                plotter.plotz(flm.transient('base.FGRAV'        ,'zIdx',zIdx)','Gravity'                                   );
                plotter.plotz(flm.transient('base.FTOT'     ,drp,'zIdx',zIdx)','Total'                                     );
                plotter.legend('show', 'Location', 'best')
                
                ah_wave = plotter.newTile( ...
                    'tileTitle', 'Wave momentum exchanges', ...
                    'xlabel'   ,                'Time [s]', ...
                    'ylabel'   ,    'Shear stress [N/m^2]');
                plotter.plotz(flm.transient('wave.FDEP'     ,drp,'zIdx',zIdx)','Deposition','DisplayName','Drop deposition');
                plotter.plotz(flm.transient('wave.FSHEAR'       ,'zIdx',zIdx)','Vapor'     ,'DisplayName','Vapor shear'    );
                plotter.plotz(flm.transient('wave.FDRAG'        ,'zIdx',zIdx)','VaporDrag' ,'DisplayName','Vapor drag'     );
                plotter.plotz(flm.transient('wave.FBASE'    ,drp,'zIdx',zIdx)','Wave'      ,'DisplayName','Base'           );
                plotter.plotz(flm.transient('wave.FBASEMASS',drp,'zIdx',zIdx)','WaveMass'  ,'DisplayName','Base mass'      );
                plotter.plotz(flm.transient('wave.FBUOY'        ,'zIdx',zIdx)','Buoyancy'                                  );
                plotter.plotz(flm.transient('wave.FGRAV'        ,'zIdx',zIdx)','Gravity'                                   );
                plotter.plotz(flm.transient('wave.FTOT'     ,drp,'zIdx',zIdx)','Total'                                     );
                plotter.legend('show', 'Location', 'best');
                
                % Link exchange axes
                for wallIdx = 1:length(ah_base)
                    linkaxes([ah_base(wallIdx), ah_wave(wallIdx)]);
                end
            end
            
            % Drop momentum exchanges
            if any(ismember({'DME','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Drop momentum exchanges', ...
                    'xlabel'   ,                'Time [s]', ...
                    'ylabel'   ,    'Shear stress [N/m^3]');
                plotter.plotz(drp.transient('FENT' ,flm,'zIdx',zIdx)','Entrainment','DisplayName','Film entrainment');
                plotter.plotz(drp.transient('FDRAG'    ,'zIdx',zIdx)','Vapor'                                       );
                plotter.plotz(drp.transient('FBUOY'    ,'zIdx',zIdx)','Buoyancy'                                    );
                plotter.plotz(drp.transient('FGRAV'    ,'zIdx',zIdx)','Gravity'                                     );
                plotter.plotz(drp.transient('FTOT' ,flm,'zIdx',zIdx)','Total'                                       );
                plotter.legend('show', 'Location', 'best');
            end
        end
        
        function plotzt(ffSolver, opt)
        %PLOTZT: Plot 2D time/elevation distributions of four-field parameters
        %
            arguments
                ffSolver
                opt.display      {mustBeA(opt.display,{'cell','char'})}                   = {         'HFLUX',             'W',       'U','FREQUENCY'}
                opt.label        {mustBeA(opt.label,{'cell','char'})}                     = {'wall heat flux','mass flow rate','velocity','frequency'}
                opt.unit         {mustBeA(opt.unit,{'cell','char'})}                      = {         'W/m^2',          'kg/s',     'm/s',       'Hz'}
                opt.field        {mustBeMember(opt.field,{'drop','film','wave','base'})}  = {'wave','base'}
                opt.solveMode    {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}     = 'TRANSIENT'
                opt.wall         (1,:) double {mustBeVector,mustBeInteger,mustBePositive} = 1:ffSolver.inputSet.geometry.NWALL
                opt.zIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:ffSolver.NZ
                opt.tIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:ffSolver.NTIME
                opt.annular      (1,1) logical                                            = true
                opt.reverseTime  (1,1) logical                                            = false
                opt.shading      {mustBeMember(opt.shading,{'faceted','flat','interp'})}  = 'interp'
                opt.view         (1,2) double                                             = [0 90]
            end
            
            if ~iscell(opt.display), opt.display = {opt.display}; end
            if ~iscell(opt.label)  , opt.label   = {opt.label}  ; end
            if ~iscell(opt.unit)   , opt.unit    = {opt.unit}   ; end
            if strcmp('ALL',opt.display)
                    opt.display = {         'HFLUX',             'W',                               'WL',       'U',    'THICK','AMPLITUDE','FREQUENCY','SPACING','WIDTH',      'EPSILON',                'BETA',               'BETAP',                'ETA',             'FDRY', 'SHAPEFACTOR'};
                    opt.label   = {'wall heat flux','mass flow rate','mass flow rate per unit perimeter','velocity','thickness','amplitude','frequency','spacing','width','mass fraction','interfacial fraction','evaporation fraction','deposition fraction','dry time fraction','shape factor'};
                    opt.unit    = {         'W/m^2',          'kg/s',                           'kg/s/m',     'm/s',        'm',        'm',       'Hz',      'm',    'm',            '-',                   '-',                   '-',                  '-',                '-',           '-'};
            end
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = ffSolver.mixSolver.mixture(opt.tIdx);
                    drp = ffSolver.drop(opt.tIdx);
                    flm = ffSolver.film(opt.tIdx);
                case 'STEADY'
                    if isequal(opt.tIdx,[1:ffSolver.NTIME]')
                        opt.tIdx = 1:length(ffSolver.filmInit);
                    end
                    mix = ffSolver.mixSolver.mixtureInit(opt.tIdx);
                    drp = ffSolver.dropInit(opt.tIdx);
                    flm = ffSolver.filmInit(opt.tIdx);
            end
            if isempty(opt.wall)
                opt.wall = 1:ffSolver.inputSet.geometry.NWALL;
            end
            if length(opt.zIdx) < 2
                ffSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            if length(opt.tIdx) < 2
                ffSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            
            for k = opt.wall
                if ismember('drop',opt.field)
                    fh_drp = figure('name',['Time/axial distributions of four-field (drop) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP'})
                            ax_drp(i) = mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt);
                        elseif contains(opt.display{i},{'WL','THICK','AMPLITUDE','FREQUENCY','SPACING','WIDTH','EPSILON','BETA','BETAP','ETA','FDRY','SHAPEFACTOR'})
                            continue
                        else
                            ax_drp(i) = drp.plotzt(opt.display{i},['Drop '    opt.label{i}],opt.unit{i},k,opt,flm,opt.annular);
                        end
                    end
                end
                if ismember('film',opt.field)
                    fh_flm = figure('name',['Time/axial distributions of four-field (film) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP'})
                            ax_flm(i) = mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt);
                        elseif contains(opt.display{i},{'AMPLITUDE','FREQUENCY','SPACING','WIDTH','EPSILON','BETA','BETAP','ETA','FDRY','SHAPEFACTOR'})
                            continue
                        else
                            ax_flm(i) = flm.plotzt(opt.display{i},['Film '    opt.label{i}],opt.unit{i},k,opt,drp,opt.annular);
                        end
                    end
                end
                if ismember('wave',opt.field)
                    fh_wav = figure('name',['Time/axial distributions of four-field (wave) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP'})
                            ax_flm(i) = mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt);
                        elseif contains(opt.display{i},{'FDRY'})
                            continue    
                        else
                            ax_flm(i) = flm.plotzt(['wave.' opt.display{i}],['Wave '    opt.label{i}],opt.unit{i},k,opt,drp,opt.annular);
                        end
                    end
                end
                if ismember('base',opt.field)
                    fh_wav = figure('name',['Time/axial distributions of four-field (wave) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        if contains(opt.display{i},{'HFLUX','DP'})
                            ax_bas(i) = mix.plotzt(opt.display{i},['Mixture ' opt.label{i}],opt.unit{i},k,opt);
                        elseif contains(opt.display{i},{'AMPLITUDE','FREQUENCY','SPACING','WIDTH','SHAPEFACTOR'})
                            continue
                        else
                            ax_bas(i) = flm.plotzt(['base.' opt.display{i}],['Base film '    opt.label{i}],opt.unit{i},k,opt,drp,opt.annular);
                        end
                    end
                end
            end
        end
        
        function saveResults(ffSolver, opts)
        %SAVERESULTS
        %
        arguments
            ffSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = ffSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', ffSolver.Z, ...
                                'TIME', ffSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', ffSolver.boundaryConditions, ...
                                'filmInit', struct(ffSolver.filmInit), ...
                                'dropInit', struct(ffSolver.dropInit), ...
                                'film', struct(ffSolver.film), ...
                                'base', struct([ffSolver.film.base]), ...
                                'wave', struct([ffSolver.film.wave]), ...
                                'drop', struct(ffSolver.drop));
                    
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

    end
    
end

