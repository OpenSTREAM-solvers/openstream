%% OpenSTREAM sandbox example
%
% This script provides a starting point for exploratory OpenSTREAM
% calculations. Copy and rename this file before modifying it.
%
% The example uses the standard OpenSTREAM input files and runs a mixture
% solver calculation. Adjust the selected input identifiers, physical
% models, numerical options, and post-processing commands as needed.

%% Setup

% Clear the existing workspace and close open figures.
clearvars
close all

% Add the OpenSTREAM repository root to the MATLAB search path.
openstreamPath = '..';
addpath(openstreamPath)

% Import the input and mixture-solver packages.
import Inputs.*
import Solvers.Mixture.*

%% Input selection

% Define the standard OpenSTREAM input files.
modelFilePath    = fullfile(openstreamPath,'inputs','models.inp');
optionsFilePath  = fullfile(openstreamPath,'inputs','options.inp');
geometryFilePath = fullfile(openstreamPath,'inputs','geom.inp');
boundaryConditionFilePath = fullfile(openstreamPath,'inputs','tutorial1.inp');

% Select the model, option, and geometry identifiers.
modelID    = 'TUTORIAL2A';
optionsID  = 'DEFAULT';
geometryID = 'TUTORIAL1';

%% Input set

% Construct the OpenSTREAM input set and allow previous session replacement.
inputSet = InputSet( ...
    modelFilePath = modelFilePath, ...
    modelID = modelID, ...
    optionsFilePath = optionsFilePath, ...
    optionsID = optionsID, ...
    geometryFilePath = geometryFilePath, ...
    geometryID = geometryID, ...
    bcFilePath = boundaryConditionFilePath, ...
    sessionParentDir = fullfile(pwd,'outputs'), ...
    overwriteSessionFiles = true, ...
    LOGMODE = 'BOTH');

%% Calculation

% Construct and run the mixture solver.
solver = MixtureSolver(inputSet);
solver.solve();

%% Verification

% Display the final solver state for convergence review.
disp(solver.STATE)

%% Post-processing

% Plot representative axial distributions.
solver.plotz('display',{'HFLUX','DP','VR'});

% Retain direct access to the calculated mixture field.
mixture = solver.mixture;
