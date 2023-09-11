%close all;
clearvars

diary off

import Inputs.*
import Solvers.*
import Solvers.Mixture.*

%Inputs
% inputSet = InputSet( ...
%             modelFilePath         = './inputs/models.inp',  modelID    = 'MFVALS', ...
%             optionsFilePath       = './inputs/options.inp', optionsID  = 'STEADY', ...
%             geometryFilePath      = './inputs/geom.inp',    geometryID = 'MFVAL', ...
%             bcFilePath            = './inputs/bc_mfval_subcooled.inp', ...
%             sessionParentDir      = fullfile(pwd,'outputs'), ...
%             overwriteSessionFiles = true, ...
%             LOGMODE               = 'BOTH');
        
inputSet = InputSet( ...
            modelFilePath         = './inputs/models.inp',  modelID    = 'BARCS', ...
            optionsFilePath       = './inputs/options.inp', optionsID  = 'STEADY', ...
            geometryFilePath      = './inputs/geom.inp',    geometryID = 'BARC', ...
            bcFilePath            = './inputs/bc_barc.inp', ...
            sessionParentDir      = fullfile(pwd,'outputs'), ...
            overwriteSessionFiles = true, ...
            LOGMODE               = 'BOTH');        
%         
% Create the mixture solver
mixSolver = MixtureSolver(inputSet);

% mixSolver is initialized at construction. Here, it is explicitly initialized for clarity.
mixSolver.initializeSolver(); 

% Solve (does not accept any argument)
mixSolver.solve();

% Axial and temporal plots
mixSolver.plotz(1);
mixSolver.plotz(mixSolver.NTIME);
%mixSolver.plott(mixSolver.NZ,'solveMode','STEADY')
%mixSolver.plott(mixSolver.NZ)
%mixSolver.plott([1 floor(mixSolver.NZ./8.*(2:8))])

% Save results
mixSolver.saveResults(saveFormat="MAT");

%return

%% Three-field

import Solvers.ThreeField.*

% Create the three-field solver
tfSolver = ThreeFieldSolver(inputSet,mixSolver);
tfSolver.plotz(1);                                                         % Plot initialization state (dep and ent set to 0 but calculated value is plotted instead)

% tfSolver is initialized at construction. Here, it is explicitly initialized for clarity.
tfSolver.initializeSolver(); 

% Solve (does not accept any argument)
tfSolver.solve();

% Axial and temporal plots
tfSolver.plotz(1);
tfSolver.plotz(tfSolver.NTIME);

% Save results
tfSolver.saveResults(saveFormat="MAT");

%% Four-field

import Solvers.FourField.*

% Create the three-field solver
ffSolver = FourFieldSolver(inputSet,mixSolver);
ffSolver.plotz(1);                                                         % Plot initialization state (dep and ent set to 0 but calculated value is plotted instead)

% tfSolver is initialized at construction. Here, it is explicitly initialized for clarity.
ffSolver.initializeSolver(); 

% Solve (does not accept any argument)
ffSolver.solve();

% Axial and temporal plots
ffSolver.plotz(1);
ffSolver.plotz(ffSolver.NTIME);

% Save results
ffSolver.saveResults(saveFormat="MAT");

% Check
% mix  = tfSolver.mixture;
% film = tfSolver.film;
% drop = tfSolver.drop;
% 
% for tIdx = 1:tfSolver.NTIME
%     fprintf('\nTime index %d and time %.2f [s]\n',tIdx,tfSolver.TIME(tIdx))
%     fprintf('Onset of annular flow at node %d and elevation %.3f [m]\n',mix(tIdx).OAFIDX,mix(tIdx).OAFZ)
%     fprintf('Film mass flow ratio at onset of annular flow = %.3f\n',sum(film(tIdx).W(mix(tIdx).OAFIDX,:))./mix(tIdx).liquid.W(mix(tIdx).OAFIDX))
%     fprintf('Drop mass flow ratio at onset of annular flow = %.3f\n',drop(tIdx).W(mix(tIdx).OAFIDX)./mix(tIdx).liquid.W(mix(tIdx).OAFIDX))
% end