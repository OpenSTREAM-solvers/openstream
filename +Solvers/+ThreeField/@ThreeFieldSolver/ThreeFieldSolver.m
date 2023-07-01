classdef ThreeFieldSolver < Solvers.AbstractSolver
    %THREEFIELDSOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=private)
        
        NZ           (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of time steps
        TIME         (:,1) double  {mustBeNumeric}                          = 0         % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                          = 0         % [s] Time step size
        Z            (:,1) double  {mustBeNumeric}                          = 1.        % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                          = 0         % [m] Axial step size

        fluid       {isa(fluid,'Inputs.FluidProperties')}
        boundaryConditions
        
        filmInit
        dropInit
        fluidInit
        film
        drop

     end

     properties (SetAccess = protected)
        mixSolver
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(tfSolver)
    end

    methods
        function tfSolver = ThreeFieldSolver(inputSet,mixSolver)
            %THREEFIELDSOLVER Creates a ThreeField solver
            %   Detailed explanation goes here
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            tfSolver = tfSolver@Solvers.AbstractSolver(inputSet);
            
            % Store mixSolver handle
            tfSolver.mixSolver = mixSolver;

            % Attempt to solve mixSolver if it is unsolved
            if tfSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
                tfSolver.mixSolver.solve();
            end
            
            % Initialize solver parameters
            tfSolver.initializeSolver();

        end
        
        function initializeSolver(tfSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.ThreeField.*
            import Solvers.*
            
            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                tfSolver.(p{:}) = tfSolver.mixSolver.(p{:});
            end
            
            % Local parameters
            mix   = tfSolver.mixSolver.mixture;                            % Mixture solution
            model = tfSolver.inputSet.model;                               % Models
            geom  = tfSolver.inputSet.geometry;                            % Geometry
            
            % Setup inner iteration value struct
            ITRFields = ["N","DWL","DU"];
            ITR = tfSolver.CreateITR(tfSolver.NZ, ITRFields);

            % Create film and drop arrays (by timestep)
            flmArr = Film.empty(0,tfSolver.NTIME);
            drpArr = Drop.empty(0,tfSolver.NTIME);
            props = {'NZ','Z','NTIME','DT','TIME','TIDX'};                 % film and drop properties
            
            for tIdx = 1:tfSolver.NTIME
                
                % Inputset
                drpArr(tIdx).inputSet = tfSolver.inputSet;
                drpArr(tIdx).fluid    = tfSolver.fluid(tIdx);
                
                flmArr(tIdx).inputSet = tfSolver.inputSet;
                flmArr(tIdx).fluid    = tfSolver.fluid(tIdx);
                
                % Axial Steps
                drpArr(tIdx).DZ = tfSolver.DZ;
                
                flmArr(tIdx).NZ = tfSolver.NZ;
                flmArr(tIdx).DZ = tfSolver.DZ;
                flmArr(tIdx).Z  = tfSolver.Z;
                
                % Time step
                flmArr(tIdx).NTIME = tfSolver.NTIME;
                flmArr(tIdx).DT    = tfSolver.DT;
                flmArr(tIdx).TIME  = tfSolver.TIME(tIdx);
                flmArr(tIdx).TIDX  = tIdx;
                
                % Copy properties to drop
                for p = props
                    drpArr(tIdx).(p{:}) = flmArr(tIdx).(p{:});
                end
                    
                % Wall evaporation heat flux
                HFLUX = mix(tIdx).HFLUX;                                   % [W/m^2] Wall heat flux
                avgHFLUX = sum(HFLUX.*geom.PERIM,2)./sum(geom.PERIM);      % [W/m^2] Average heat flux
                avgHFLUX = repmat(avgHFLUX,1,geom.NWALL);                  % [W/m^2] ... distributed to all walls
                
                evapFn = double(mix(tIdx).XEQ > 0);                        % Saturated evaporation function
                Nbo = find(evapFn > 0,1);                                  % Boiling transition node
                if Nbo >1
                    evapFn(Nbo) = mix(tIdx).XEQ(Nbo)/diff(mix(tIdx).XEQ(Nbo-1:Nbo)); % Adjust evaporation function in transition node (part toward subcooled liquid, part toward evaporation)
                end
                
                flmArr(tIdx).HFLUX = mix(tIdx).AFDISTR(evapFn.*avgHFLUX,HFLUX); % [W/m^2] Film evaporation heat flux
                    
                % Film evaporation (thermal equilibrium assumption)
                flmArr(tIdx).MEVAP = -flmArr(tIdx).HFLUX./(tfSolver.fluid(tIdx).HG-tfSolver.fluid(tIdx).HF); % [kg/m^2/s] Evaporation mass flux
                
                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note 1: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                % Note 2: other, maybe better, initialization states could be investigated
                drpArr(tIdx).W = repmat(model.OAFDROPRATIO.*mix(tIdx).OAFWL,tfSolver.NZ,1); % [kg/s] % Set drop mass flow to onset of annular flow conditions everywhere
                
                % Transient mass gradient in film field
                %flmArr(tIdx).W = (mix(tIdx).W-drpArr(tIdx).W).*geom.PERIM./sum(geom.PERIM);           % [kg/s] Distribute film at inlet uniformly on all walls
                %flmArr(tIdx).W = flmArr(tIdx).W+cumsum(flmArr(tIdx).MEVAP).*geom.PERIM.*tfSolver.DZ;  % [kg/s] Apply simple mass conservation
                
                % ... or transient mass gradient in drop field
                drpArr(tIdx).W = drpArr(tIdx).W+mix(tIdx).W-mix(tIdx).W(mix(tIdx).OAFIDX);                                % 
                flmArr(tIdx).W(1,1:geom.NWALL) = (mix(tIdx).liquid.W(1)-drpArr(tIdx).W(1)).*geom.PERIM./sum(geom.PERIM);  % [kg/s] Distribute film at inlet uniformly on all walls
                flmArr(tIdx).W = flmArr(tIdx).W(1,:)+cumsum(flmArr(tIdx).MEVAP).*geom.PERIM.*tfSolver.DZ;                 % [kg/s] Apply simple mass conservation
                
                % Limit film flow rate minimum to 0
                flmArr(tIdx).W = max(0,flmArr(tIdx).W);
                drpArr(tIdx).W = mix(tIdx).liquid.W-sum(flmArr(tIdx).W,2); % [kg/s] Recalculate consistent drop flow rate
                
                
                % Initialize velocity [m/s]
                switch model.MOMENTDROP
                    case {InputEnums.MOMENTDROP.SLIP, InputEnums.MOMENTDROP.ALGEBRAIC}
                        drpArr(tIdx).U = drpArr(tIdx).USLIP(mix(tIdx));    % [m/s] Drop velocity
                end
                
                switch model.MOMENTFILM
                    case InputEnums.MOMENTFILM.ALGEBRAIC
                        flmArr(tIdx).U = flmArr(tIdx).UALGEBR(mix(tIdx));  % [m/s]
                    case InputEnums.MOMENTFILM.EQUILIBRIUMS
                        flmArr(tIdx).U = flmArr(tIdx).UEQUILS(mix(tIdx));  % [m/s]
                    case {InputEnums.MOMENTFILM.EQUILIBRIUM, InputEnums.MOMENTFILM.FULL}
                        flmArr(tIdx).U = flmArr(tIdx).UEQUILS(mix(tIdx));  % [m/s] Initialize
                        %flmArr(tIdx).U = flmArr(tIdx).UEQUIL(mix(tIdx),drpArr(tIdx)); % [m/s]
                end
                                
                % Initialize enthalpy [J/kg] by number of spatial nodes, NZ
                drpArr(tIdx).H = repmat(tfSolver.fluid(tIdx).HF,tfSolver.NZ,1);
                flmArr(tIdx).H = repmat(tfSolver.fluid(tIdx).HF,tfSolver.NZ,1);
                
                % ITR
                flmArr(tIdx).ITR = ITR;

            end

            % Store transient mixture array
            tfSolver.film = flmArr;
            tfSolver.drop = drpArr;

            % Create steady state mixture array
            tfSolver.filmInit = copy( ...
                repmat(flmArr(1),1,tfSolver.inputSet.options.SSMAXITER));
            tfSolver.dropInit = copy( ...
                repmat(drpArr(1),1,tfSolver.inputSet.options.SSMAXITER));
            tfSolver.fluidInit = FluidProperties( ...
                                    repmat( ...
                                        tfSolver.boundaryConditions.PRESSURE(1), ...
                                        1, ...
                                        tfSolver.inputSet.options.SSMAXITER), ...
                                    tfSolver.inputSet.model);

            % Update filmInit and dropInit times and timesteps
            initTIMEDT = tfSolver.inputSet.options.SSTSTEP;
            initNTIME = length(tfSolver.filmInit);
            initTIME = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX = 1:length(tfSolver.filmInit);

            for i = 1:length(tfSolver.filmInit)
                tfSolver.filmInit(i).TIME = initTIME(i);
                tfSolver.filmInit(i).DT = initTIMEDT;
                tfSolver.filmInit(i).NTIME = initNTIME;
                tfSolver.filmInit(i).TIDX = initTIDX(i);
                tfSolver.dropInit(i).TIME = initTIME(i);
                tfSolver.dropInit(i).DT = initTIMEDT;
                tfSolver.dropInit(i).NTIME = initNTIME;
                tfSolver.dropInit(i).TIDX = initTIDX(i);
            end

            % set STATE to UNSOLVED
            tfSolver.STATE = SolverState.UNSOLVED;

        end

        function plotz(tfSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
            arguments
                tfSolver
                tIdx    (1,1) double
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
            end
        
            switch opt.solveMode
                case 'TRANSIENT'
                    flm = tfSolver.film(tIdx);
                    drp = tfSolver.drop(tIdx);
                case 'STEADY'
                    flm = tfSolver.filmInit(tIdx);
                    drp = tfSolver.dropInit(tIdx);
            end
            
            bc  = tfSolver.boundaryConditions;
            mix = tfSolver.mixSolver.mixture(tIdx);
            z   = tfSolver.Z;
            figure('name',['Axial distributions of three-field parameters at ' num2str(flm.TIME) ' [s]'])
            
            nexttile; hold all; grid on; title('Wall heat flux')
            plot(z,bc.HFLUX(:,:,tIdx),'s-')
            plot(z,flm.HFLUX,'.--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim([0 z(end)]);
            ylabel('Wall heat flux [W/m^2]')
            set(gca,'fontSize',14)
                
            nexttile; hold all; grid on; title('Mass flow rates')
            plot(z,mix.liquid.W,'s')
            plot(z,sum([drp.W flm.W],2),'r+-')
            plot(z,drp.W,'o-')
            plot(z,flm.W,'.-')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Field mass flowrate [kg/s]')
            legend({'Mixture Liquid','Drop + Film','Drop','Film'},'location','northEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Film mass flow rates per unit perimeter')
            plot(z,flm.WL,'.-')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Film mass flowrate [kg/s/m]')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Field velocities')
            plot(z,mix.liquid.U,'s')
            plot(z,drp.U,'o-')
            plot(z,flm.U,'.-')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Field velocity [m/s]')
            legend({'Mixture Liquid','Drop','Film'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Film thicknesses')
            plot(z,flm.THICK,'.-')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Film thickness [m]')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Film mass exchanges')
            plot(z,drp.MDEP(mix),'o-')
            plot(z,flm.MENT(mix),'.-')
            plot(z,flm.MEVAP,'+-')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Mass flux [kg/s/m^2]')
            legend({'Drop deposition','Film entrainment','Film evaporation'},'location','northEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on; title('Film momentum exchanges')
            plot(z,flm.FDEP(mix,drp),'o-')
            plot(z,flm.FWALL(mix),'.-')
            plot(z,flm.FVAPOR(mix),'.-')
            plot(z,flm.FBUOY(mix),'.-')
            plot(z,flm.FGRAV(mix),'.-')
            plot(z,flm.FTOT(mix,drp),'k--')
            plot(repmat(mix.OAFZ,1,2),ylim,'r--','handleVisibility','off')
            xlabel('Axial position [m]'); xlim(z([1 end]));
            ylabel('Shear stress [N/m^2]')
            legend({'Drop deposition','Wall','Vapor','Buoyancy','Gravity','Total'},'location','northEast')
            set(gca,'fontSize',14)
            
        end
    
        function plott(tfSolver, zIdx, opt)
            %PLOTT 
            % 
            arguments
                tfSolver
                zIdx (:,1) double
                opt.tIdx (:,1) double = -1
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})} = 'TRANSIENT'
                opt.reverseTime (1,1) logical = false
            end
            
            switch opt.solveMode
                case 'TRANSIENT'
                    flm = tfSolver.film;
                    drp = tfSolver.drop;
                case 'STEADY'
                    flm = tfSolver.filmInit;
                    drp = tfSolver.dropInit;
            end

            if isscalar(opt.tIdx) && (opt.tIdx < 0)
                opt.tIdx = 1:length(flm);
            end

            % Cannot plot time series of one time step
            if isscalar(flm) || isscalar(opt.tIdx)
                mixSolver.log('Error: Non-scalar time index required to plot time series.\n');
                return
%                 throw( ...
%                     MException( ...
%                         'MixtureSolverPlottError:ScalarTimestepError', ...
%                         'Non-scalar time index required to plot time series'))
            end

            % Time vector
            plotTimeVector = [flm(opt.tIdx).TIME];
            if opt.reverseTime
                plotTimeVector = plotTimeVector - plotTimeVector(end);
            end            

            figure('name',['Time series of mixture parameters at ' num2str(mixSolver.Z(zIdx(1))) ' [m]']);
            
            timeplot('W','Mass flowrates [kg/s]')
            timeplot('U','Velocity [m/s]')

            function timeplot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(flm,param)
                    paramData = arrayfun( ...
                                    @(i) flm(i).(param), ...
                                    1:length(plotTimeVector), ...
                                    'UniformOutput', false);
                    paramData = cell2mat(paramData);

                else
                    paramData = [flm.(param)];
                end
                
                plot(plotTimeVector, paramData(zIdx,opt.tIdx),'.-');

                legendStr = num2str(tfSolver.Z(zIdx),'z=%0.4f m');
                legend(legendStr,'Location','southeast');
                
                xlabel('Time [s]'); xlim(plotTimeVector([1 end]));
                ylabel(ylabelText)
                set(gca,'fontSize',14)
            
            end

        end
        
        function saveResults(tfSolver, opts)
        %SAVERESULTS
        %
        arguments
            tfSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = tfSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', tfSolver.Z, ...
                                'TIME', tfSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', tfSolver.boundaryConditions, ...
                                'filmInit', struct(tfSolver.filmInit), ...
                                'dropInit', struct(tfSolver.dropInit), ...
                                'film', struct(tfSolver.film), ...
                                'drop', struct(tfSolver.drop));
                    
                    save( ...
                        fullfile( ...
                            session.directory, strcat(session.name,'.mat')), ...
                        '-struct', ...
                        "results", ...
                        "-mat" ...
                    );
            end


        end

    end
end

