close all; clearvars

import Inputs.*
import Solvers.*
import Solvers.Mixture.*

testID='MFVAL';
modelFile = './inputs/models.inp';
N   = 10000;                                                               % Number of run time iterations

switch testID
    case 'MFVAL'
        % MFVAL example
        P   = 0.15E6;                                                              % [Pa]
        HIN = 3.7161e+05;                                                          % [J/kg]
        modelID={'MFVALS','MFVALP'};                                               % Model ID
    case 'BWR'
        % BWR example
        P   = 7E6;                                                                 % [Pa]
        HIN = 3.7161e+05;                                                          % [J/kg]
        modelID={'WATERS','WATERP'};                                               % Model ID
end

%% Initialize classes

% model_sat = Model(modelFile, modelID{1});
% prop_sat  = FluidProperties(P,model_sat);
% 
% model_p   = Model(modelFile,modelID{2});
% prop_p    = FluidProperties(P,model_p);

% The InputSet is used to organize all input files and session parameters.
% A session is the unique combination of input files.
inputSet = InputSet( ...
            modelFilePath='./inputs/models.inp', modelID='MFVALS', ...
            optionsFilePath='./inputs/options.inp', optionsID='STEADY', ...
            geometryFilePath='./inputs/geom.inp', geometryID='MFVAL', ...
            bcFilePath='./inputs/bc_mfval_steady.inp', ...
            ...
            sessionParentDir = fullfile(pwd,'outputs'), ...
            overwriteSessionFiles = true, ...
            LOGMODE='BOTH');

% Create the mixture solver
mixSolver = MixtureSolver(inputSet);

% mixSolver is initialized at construction. Here, it is explicitly
% initialized for clarity.
mixSolver.initializeSolver(); 

% Solve does not accept any other arguments
mixSolver.solve();

% Axial and temporal plotting
mixSolver.plotz(mixSolver.NTIME);
mixSolver.plott([1 floor(mixSolver.NZ./8.*(2:8))])

% Save results
mixSolver.saveResults(saveFormat="MAT");

return

%% Tests

% Example of fluid property plots with saturation properties
dH=5E4;
h = prop_sat.HF/2:dH:1.5*prop_sat.HG;
plot(prop_sat,h)

% Example of fluid property plots with enthalpy dependesnt properties
plot(prop_p,h)

% Runtime tests
runtimetest(prop_sat,HIN,N)                                                % Saturation assumption only (fast)
runtimetest(prop_p,HIN,N)                                                  % System pressure assumption (slow)

%% Sub-functions

function runtimetest(prop,HIN,N)

    fprintf('\nFluid properties runtime test for option %s with %d iterations...\n',prop.PROPERTIES,N)
    tic
    for k=1:N
        prop.RHOL(HIN);
    end
    toc
end
