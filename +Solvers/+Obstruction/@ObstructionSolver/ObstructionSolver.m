classdef ObstructionSolver < Solvers.AbstractSolver
    %OBSTRUCTIONSOLVER Summary of this class goes here
    %
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
        
        solutionSets (:,1) Solvers.Obstruction.SolutionSet
        axialBounds
        spanBounds

     end

     properties (SetAccess = protected)
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
        solverType
     end

    methods
        function obsSolver = ObstructionSolver(inputSet, solverType)
            %OBSTRUCTIONSOLVER Creates a Obstruction solver 
            %  
            %  Detailed explanation goes here

            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                solverType          InputEnums.SOLVER
            end

            import Solvers.Obstruction.*

            % Check if obstructions are nonempty in inputSet
            if isempty(inputSet.obs)
                error("MIXTURESOLVER:NoObstructionError", "No obstructions are in the inputSet");
            end

            % For now, assume only one obstruction is given
            obs = inputSet.obs(1);

            % Wall perimeter
            wallPerim = inputSet.geometry.PERIM(obs.WALL);

            % Place the obstruction on the wall; determine bounds
            [axialBounds, spanBounds] = obs.placeObsOnWall( ...
                                                inputSet.geometry.LENGTH, ...
                                                wallPerim);
            
            obsSolver.axialBounds = [0 axialBounds inputSet.geometry.LENGTH];
            obsSolver.spanBounds = [0 spanBounds wallPerim];

            % Split inputSet into axial segments
            obsSolver.inputSet = inputSet.SplitByAxialPosition(obsSolver.axialBounds);

            % Split last/3rd inputSet by tracks
            obsSolver.inputSet(end).SplitBySpanPosition(obs.WALL, obsSolver.spanBounds);

            % Store solver type
            obsSolver.solverType = solverType;
            
            
            
        end
        
        function initializeSolver(obsSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
        % 
            
            import Solvers.Obstruction.SolutionSet
            import Solvers.SolverState            

            % set STATE to INITIALIZED
            obsSolver.STATE = SolverState.INITIALIZED;

            % Log 
            
        end

        function solve(obsSolver)
        %SOLVE
        %
        % Solve the problem

            import Solvers.Obstruction.SolutionSet
            import Solvers.SolverState

            % Split the solution into three parts: 
            % 1. Before the obstruction
            obsSolver.solutionSets(1) = SolutionSet( ...
                                            "NONOBS", ...
                                            obsSolver.inputSet(1), ...
                                            obsSolver.axialBounds(1:2));
            obsSolver.solutionSets(1).setSolver( ...
                Solvers.(obsSolver.solverType.solverPath())(obsSolver.inputSet(1)));
            % Solve
            obsSolver.solutionSets(1).solver.solve();


            % 2. Along the obstruction
            obsSolver.solutionSets(2) = SolutionSet( ...
                                            "OBS", ...
                                            obsSolver.inputSet(2), ...
                                            obsSolver.axialBounds(2:3));
            % Create mixture solver if another solver is used
            if obsSolver.solverType ~= InputEnums.SOLVER.MIXTURE
                
                % Set initSolver to true
                mixSolver = Solvers.Mixture.MixtureSolver(obsSolver.inputSet(2), "initSolver", true);
                
                % Replace mixtureInit with []
                % NOTE: maybe the last time step in previous segment is
                % better than empty array?
                mixSolver.clearInit();

                % copy flow properties in continue mode
                obsSolver.solutionSets(1).solver.mixSolver.mixture(:).copyFlowProperties(mixSolver.mixture(:), "copyMode", "continue");
                
                % Set solver state to INITIALSTEPCONVERGED
                

                % Create solver without init
                subSolver = Solvers.(obsSolver.solverType.solverPath())(obsSolver.inputSet(2), mixSolver, 'initSolver', false);
                subSolver
            else
                % Solve
                subSolver = Solvers.(obsSolver.solverType.solverPath())(obsSolver.inputSet(2));
            end
                


            
            % Replace inits with last steps from previous solver
            
            obsSolver.solutionSets(2).setSolver( ...
                Solvers.(obsSolver.solverType.solverPath())(obsSolver.inputSet(2)));

            %   3. After the obstruction
            obsSolver.solutionSets(3) = SolutionSet( ...
                                            "NONOBS", ...
                                            obsSolver.inputSet(3), ...
                                            obsSolver.axialBounds(3:4));
            obsSolver.solutionSets(3).setSolver( ...
                Solvers.(obsSolver.solverType.solverPath())(obsSolver.inputSet(3)));


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
                tfSolver.log('Error: Non-scalar time index required to plot time series.\n');
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

            figure('name',['Time series of mixture parameters at ' num2str(tfSolver.Z(zIdx(1))) ' [m]']);
            
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
                set(gca,'fontsize',10)
            
            end

        end
        
        function plotter = plotz(obsSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
        warning("Plotz not supported right now.")
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

