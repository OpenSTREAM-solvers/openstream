close all; clear all;

%% Inputs

testid='MFVAL';
modelf = 'inputs/models.inp';
N   = 10000;                                                               % Number of run time iterations

switch testid
    case 'MFVAL'
        % MFVAL example
        P   = 0.15E6;                                                              % [Pa]
        HIN = 3.7161e+05;                                                          % [J/kg]
        modelid={'MFVALS','MFVALP'};                                               % Model ID
    case 'BWR'
        % BWR example
        P   = 7E6;                                                                 % [Pa]
        HIN = 3.7161e+05;                                                          % [J/kg]
        modelid={'WATERS','WATERP'};                                               % Model ID
end

addpath(genpath('scripts'));

%% Initialize classes

model_sat = models(modelf,modelid{1});
prop_sat  = fluidProperties(P,model_sat);

model_p   = models(modelf,modelid{2});
prop_p    = fluidProperties(P,model_p);

%% Tests

% Example of fluid property plots with saturation properties
dH=5E4;
h = prop_sat.HF/2:dH:1.5*prop_sat.HG;
plot(prop_sat,h)

% Example of fluid property plots with enthalpy dependant properties
plot(prop_p,h)

% Runtime tests
runtimetest(prop_sat,HIN,N)                                                % Saturation assumption only (fast)
runtimetest(prop_p,HIN,N)                                                  % System pressure assumption (slow)

% Test non available model ID
%model   = models(modelf,'DUMMY');


%% Sub-functions

function runtimetest(prop,HIN,N)

fprintf('\nFluid properties runtime test for option %s with %d iterations...\n',prop.PROPERTIES,N)
tic
for k=1:N
    %prop.RHOF;
    prop.RHOL(HIN);
end
toc
end