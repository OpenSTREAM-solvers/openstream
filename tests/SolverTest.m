classdef SolverTest < matlab.unittest.TestCase

    % properties (TestParameter)
    % 
    %     testInputFiles
    % 
    % end
    
    properties
        testInputFile
        dataset
    end

    methods (TestClassSetup)

        % Shared setup for the entire test class
        function makeTestInputFiles(testCase)
            
            % Currently assumes openstream-database is in parent directory
            %   TODO: improve this configuration setting. Maybe we can use
            %   some kind of configuration file... YAML?
            %   TODO: create parameterized files
            %
            addpath('../../openstream-database')
            addpath('../../openstream')

            % Remove existing files
            rmdir('./+*','s');
            
            % Some session options
            inputSetOpts = {'overwriteSessionFiles', true, 'LOGMODE', 'BOTH'};
            saveResultsToFile = false;

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
            
            % Create a Dataset
            testCase.dataset = Dataset(1,'isLightWeight',true,'lightWeightEntryData',entryData);
            
            % inputOptions
            opts = testCase.dataset.inputOptions();
            opts.options.AXIALINTERP = 'NEXT';                                 % Axial power interpolation method
    
            % Generate the input files
            testCase.testInputFile = testCase.dataset.makeInputFiles(opts);

            % Run the mixture solver
            testCase.dataset.runCase('Mixture','inputSetOpts',inputSetOpts,'saveResultsToFile',saveResultsToFile);

        end
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % Test methods

        function solverInitialConditionsTest(testCase)
            
            % solver results
            results = testCase.dataset.results;

            % Check solver state is INITIALSTEPCONVERGED
            testCase.verifyEqual( ...
                results.STATE, ...
                Solvers.SolverState.INITIALSTEPCONVERGED ...
                )

            % Check inlet pressure matches to 0.1% of expected
            testCase.verifyEqual( ...
                results.mixtureInit(end).P(1), ...
                6E6, ...
                "Initial inlet pressure mismatch", ...
                RelTol=0.001)

            % Check inlet mass flow rate matches to 0.1% of expected
            testCase.verifyEqual( ...
                results.mixtureInit(end).W(1), ...
                0.07, ...
                "Initial inlet mass flow rate mismatch", ...
                RelTol=0.001)

            % Check steady state and 1st time step solver properties are
            % the same
            mixtureSteady = results.mixtureInit(end);
            mixtureStep = results.mixture(1);
            
            % List of property names, in column shape for looping
            solverProperties = properties(mixtureSteady);
            solverProperties = reshape(solverProperties,1,[]);

            % Iterate through double and struct properties.
            % Time-related properties are expected to be different, so skip
            for solverProperty=solverProperties
                propertyType = class(mixtureSteady.(solverProperty{1}));
                if ismember(string(solverProperty{1}), ["NTIME","TIME","DT","TIDX"])
                    continue;
                elseif ismember(string(propertyType),["double","struct"])
                    testCase.verifyEqual( ...
                        mixtureStep.(solverProperty{1}), ...
                        mixtureSteady.(solverProperty{1}), ...
                        sprintf("Property %s does not match.\n", solverProperty{1}) ...
                        );
                else
                    continue;
                end
            end

        end
    end

    methods (TestClassTeardown)
        
    end

end