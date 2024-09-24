%close all;
% clearvars

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
            modelFilePath         = './inputs/models.inp',  modelID    = 'TEST', ...
            optionsFilePath       = './inputs/options.inp', optionsID  = 'DEFAULT', ...
            geometryFilePath      = './inputs/geom.inp',    geometryID = 'TESTING', ...
            bcFilePath            = './inputs/bc_transient_test.inp', ...
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
%mixSolver.plotz(1);
%mixSolver.plotz(mixSolver.NTIME);
%mixSolver.plott(mixSolver.NZ,'solveMode','STEADY')
mixSolver.plotzt(mixSolver.NZ, 'solveMode', 'TRANSIENT')
%mixSolver.plott(mixSolver.NZ)
%mixSolver.plott([1 floor(mixSolver.NZ./8.*(2:8))])

% Save results
mixSolver.saveResults(saveFormat="MAT");

%return
