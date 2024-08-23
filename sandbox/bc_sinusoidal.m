
% BC input file location
filename = 'inputs/bc_barc_sinePower.inp';

% Time array [s]
times = 0:0.01:5;

% Pressure [Pa]
p = 6000000;

% Inlet enthalpy [J/kg]
hin = 1.1394E6;

% Mass flow rate [kg/s]
mflow = 0.07;

% Relative power node size(length) [m]
WMESH = [1.75 1.75 2];
% Relative power distribution [-]
WPOWER = [1.0 1.0 0.0];

% Wall total power [W] (maximum, frequency)
powerMax = 87500;
powerFreq = 1; % [Hz]
powers = powerMax/2.*(1+sin(2*pi*times.*powerFreq));

% build bc file entries
for idx = 1:length(times)
    time = times(idx);
    power = powers(idx);
    Inputs.BoundaryConditions.writeInputFile( ...
        filename, time, p, hin, mflow, "POWER",power, "WMESH", WMESH, "WPOWER", WPOWER)
end