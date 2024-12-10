inputSet_noObs = Inputs.InputSet( ...
                    modelFilePath = './inputs/models.inp', modelID = 'BARCS', ...
                    optionsFilePath = './inputs/options.inp', optionsID = 'STEADY', ...
                    geometryFilePath = './inputs/geom.inp', geometryID = 'BARC', ...
                    bcFilePath = './inputs/bc_barc.inp', ...
                    sessionParentDir = fullfile(pwd,'outputs'), ...
                    overwriteSessionFiles = true, ...
                    LOGMODE = 'BOTH');

solver = Solvers.ThreeField.ThreeFieldSolver(inputSet_noObs);
% solver = Solvers.FourField.FourFieldSolver(inputSet_noObs);

solver.solve();

%% PLOT?
solver.mixSolver.plotz(1);
%tfSolver.mixSolver.plotz(tfSolver.mixSolver.NTIME);
% tfSolver.plotz(1);
linkaxes(findobj(gcf().Children.Children,'Type','Axes'),'x');
%xlim([0, 2.75]);
solver.plotz(1);
sgtitle('Non-obstructed')

%% OBS Solver

inputSet = Inputs.InputSet( ...
    modelFilePath = './inputs/models.inp', modelID = 'BARCS', ...
    optionsFilePath = './inputs/options.inp', optionsID = 'STEADY', ...
    geometryFilePath = './inputs/geom.inp', geometryID = 'BARC', ...
    bcFilePath = './inputs/bc_barc.inp', ...
    obsFilePath = './inputs/obstruction.inp', obsIDs = {'ROD'}, ...
    sessionParentDir = fullfile(pwd,'outputs'), ...
    overwriteSessionFiles = true, ...
    LOGMODE = 'BOTH');

% inputSet = Inputs.InputSet( ...
%             modelFilePath         = './inputs/models.inp',  modelID    = 'MFVALS', ...
%             optionsFilePath       = './inputs/options.inp', optionsID  = 'STEADY', ...
%             geometryFilePath      = './inputs/geom.inp',    geometryID = 'MFVAL', ...
%             bcFilePath            = './inputs/bc_mfval_subcooled.inp', ...
%             obsFilePath = './inputs/obstruction.inp', obsIDs = {'ROD'}, ...
%             sessionParentDir      = fullfile(pwd,'outputs'), ...
%             overwriteSessionFiles = true, ...
%             LOGMODE               = 'BOTH');

obsSolver = Solvers.Obstruction.ObstructionSolver(inputSet, 'THREEFIELD');
% obsSolver = Solvers.Obstruction.ObstructionSolver(inputSet, 'FOURFIELD');
obsSolver.solve();

% Plot
plotter = obsSolver.solutionSets(1).solver.mixSolver.plotz(1);
% obsSolver.solutionSets(1).solver.mixSolver.plotz(obsSolver.solutionSets(1).solver.mixSolver.NTIME);
% obsSolver.solutionSets(1).solver.plotz(1);
linkaxes(findobj(gcf().Children.Children,'Type','Axes'),'x');

plotter = obsSolver.solutionSets(2).solver.mixSolver.plotz(1, 'plotter', plotter);
% obsSolver.solutionSets(1).solver.mixSolver.plotz(obsSolver.solutionSets(1).solver.mixSolver.NTIME);
xlim(plotter.gca(), 'auto');
ylim(plotter.gca(), 'auto');

plotter = obsSolver.solutionSets(3).solver.mixSolver.plotz(1, 'plotter', plotter);
% obsSolver.solutionSets(1).solver.mixSolver.plotz(obsSolver.solutionSets(1).solver.mixSolver.NTIME);
linkaxes(findobj(findobj(gcf().Children, 'Type', 'tiledlayout').Children,'Type','Axes'),'x');



plotter = obsSolver.solutionSets(1).solver.plotz(1);
linkaxes(findobj(findobj(gcf().Children, 'Type', 'tiledlayout').Children,'Type','Axes'),'x');
xlim([0 5.5]);

plotter = obsSolver.solutionSets(2).solver.plotz(1, 'plotter', plotter);
linkaxes(findobj(findobj(gcf().Children, 'Type', 'tiledlayout').Children,'Type','Axes'),'x');
xlim([0 5.5]);
sgtitle('three-field, obstructed, pre-wake regions')

plotter = obsSolver.solutionSets(3).solver.plotz(1, 'plotter', plotter);
linkaxes(findobj(findobj(gcf().Children, 'Type', 'tiledlayout').Children,'Type','Axes'),'x');
xlim([0 5.5]);
