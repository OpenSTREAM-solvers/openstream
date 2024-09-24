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

%% Two-fluid

import Solvers.TwoFluid.*

% Create the two-fluid solver
twfSolver = TwoFluidSolver(inputSet, mixSolver);
twfSolver.plotz(1);                                                         % Plot initialization state (dep and ent set to 0 but calculated value is plotted instead)

% tfSolver is initialized at construction. Here, it is explicitly initialized for clarity.
twfSolver.initializeSolver(); 

% Solve (does not accept any argument)
twfSolver.solve();

% Axial and temporal plots
twfSolver.plotz(1);
twfSolver.plotz(twfSolver.NTIME);
%twfSolver.plott(twfSolver.NZ)
%twfSolver.plotzt(twfSolver.NZ, 'solveMode', 'TRANSIENT')

% Save results
twfSolver.saveResults(saveFormat="MAT");
