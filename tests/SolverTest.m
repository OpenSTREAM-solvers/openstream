classdef SolverTest < matlab.unittest.TestCase

    properties (TestParameter)

        

    end
    
    methods (TestClassSetup)
        % Shared setup for the entire test class
        function makeInputFiles()
            
            % Currently assumes openstream-database is in parent directory
            %   TODO: improve this configuration setting. Maybe we can use
            %   some kind of configuration file... YAML?
            addpath('../openstream-database')

            % Demo inputs
            entryData = table;
            entryData.Pressure      = 6E6;                                     % [Pa]   System pressure
            entryData.MassFlow      = 0.07;                                    % [kg/s] Mass flow arte
            entryData.InletEnthalpy = 1.1394E6;                                % [J/kg] Inlet enthalpy
            entryData.Power         = 87500;                                   % [W]    Power
            entryData.WallMesh      = [1.75 1.75 2];                           % [-]    Relative power distribution(s)
            entryData.WallPower     = [1.0  1.0  0];                           % [-]    Relative power distribution(s) - Last 2 meters non-heated
            entryData.Perimeter     = 0.0276;                                  % [m]    Perimeter
            entryData.Area          = 6.0821e-05;                              % [m^2]  Coolant area
            entryData.Length        = 5.5;                                     % [m]    Length
            entryData.Fluid         = 'water';                                 %        Fluid

        end
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % Test methods

        function solverTest(testCase)
            testCase.verifyFail("Unimplemented test");
        end
    end

end