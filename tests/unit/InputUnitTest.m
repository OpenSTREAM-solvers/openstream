classdef InputUnitTest < matlab.unittest.TestCase
    % INPUTUNITTEST
    %
    % Unit tests for the OpenSTREAM input classes.
    %
    % The class verifies that:
    %
    %   1. Physical-model input sets are read correctly.
    %   2. Numerical-option input sets are read correctly.
    %   3. Geometry input sets are read correctly.
    %   4. Boundary-condition files are read correctly.
    %   5. InputSet combines the requested input objects correctly.
    %
    % This class does not construct or run any OpenSTREAM solver.

    properties (SetAccess = private)

        testFolder        % Folder containing this test class.
        testRoot          % Root folder containing all automated tests.
        openstreamRoot    % OpenSTREAM repository root.
        inputFolder       % OpenSTREAM input-file folder.
        outputFolder      % Folder for temporary test artifacts.

    end

    methods (TestClassSetup)

        function configureTestEnvironment(testCase)
            % CONFIGURETESTENVIRONMENT
            %
            % Locate the OpenSTREAM repository, add it temporarily to the
            % MATLAB path, and verify that the required folders and input
            % files are available.

            % Obtain the full path to this test-class file.
            testFile = mfilename('fullpath');

            % The test-class folder is the unit, environment, or integration
            % subfolder containing this file.
            testCase.testFolder = fileparts(testFile);

            % The common test root is the parent of the category folder.
            testCase.testRoot = fileparts(testCase.testFolder);

            % The OpenSTREAM repository root is the parent of the test root.
            testCase.openstreamRoot = fileparts(testCase.testRoot);

            % Define the OpenSTREAM input-file folder.
            testCase.inputFolder = fullfile(testCase.openstreamRoot,'inputs');

            % Define a dedicated output folder for this test class.
            testCase.outputFolder = fullfile(testCase.testFolder,'outputs','InputUnitTest');

            % Add OpenSTREAM to the MATLAB path for the duration of this
            % test class.
            import matlab.unittest.fixtures.PathFixture

            testCase.applyFixture( ...
                PathFixture(testCase.openstreamRoot));

            % Verify that the input folder exists.
            testCase.assertTrue( ...
                isfolder(testCase.inputFolder), ...
                "Input folder not found: " + ...
                testCase.inputFolder);

            % Verify that the required input files exist.
            requiredInputFiles = [ ...
                "models.inp", ...
                "options.inp", ...
                "geom.inp", ...
                "tutorial1.inp"];

            for inputFileName = requiredInputFiles

                inputFilePath = fullfile( ...
                    testCase.inputFolder, ...
                    inputFileName);

                testCase.assertTrue( ...
                    isfile(inputFilePath), ...
                    "Required input file not found: " + ...
                    inputFilePath);

            end

            % Recreate the temporary output folder.
            if isfolder(testCase.outputFolder)
                rmdir(testCase.outputFolder,'s');
            end

            mkdir(testCase.outputFolder);

        end

    end

    methods (Test)

        function modelInput(testCase)
            % MODELINPUT
            %
            % Verify that the TUTORIAL1 physical-model input set is read
            % correctly.

            import Inputs.*

            % Construct the physical-model input object.
            model = Model( ...
                fullfile( ...
                testCase.inputFolder, ...
                'models.inp'), ...
                'TUTORIAL1');

            % Verify the selected input-set identifier.
            testCase.verifyEqual( ...
                string(model.ID), ...
                "TUTORIAL1", ...
                "Unexpected physical-model input-set ID.");

            % Verify representative explicitly specified properties.
            testCase.verifyEqual( ...
                model.NNODES, ...
                100, ...
                "Unexpected number of axial nodes.");

            testCase.verifyEqual( ...
                string(model.FLUID), ...
                "WATER", ...
                "Unexpected working fluid.");

        end

        function numericalOptionsInput(testCase)
            % NUMERICALOPTIONSINPUT
            %
            % Verify that the DEFAULT numerical-option input set is read
            % correctly.

            import Inputs.*

            % Construct the numerical-option input object.
            options = Options( ...
                fullfile( ...
                testCase.inputFolder, ...
                'options.inp'), ...
                'DEFAULT');

            % Verify the selected input-set identifier.
            testCase.verifyEqual( ...
                string(options.ID), ...
                "DEFAULT", ...
                "Unexpected numerical-option input-set ID.");

            % Verify representative numerical settings.
            testCase.verifyEqual( ...
                options.TSTEP, ...
                0.1, ...
                "Unexpected physical time step.");

            testCase.verifyEqual( ...
                options.SSTSTEP, ...
                1, ...
                "Unexpected steady-state pseudo-time step.");

        end

        function geometryInput(testCase)
            % GEOMETRYINPUT
            %
            % Verify that the TUTORIAL1 geometry input set is read
            % correctly.

            import Inputs.*

            % Construct the geometry input object.
            geometry = Geometry( ...
                fullfile( ...
                testCase.inputFolder, ...
                'geom.inp'), ...
                'TUTORIAL1');

            % Verify the selected input-set identifier.
            testCase.verifyEqual( ...
                string(geometry.ID), ...
                "TUTORIAL1", ...
                "Unexpected geometry input-set ID.");

            % Verify representative geometry properties.
            testCase.verifyEqual( ...
                geometry.LENGTH, ...
                5.5, ...
                "Unexpected channel length.");

            testCase.verifyEqual( ...
                geometry.AREA, ...
                6.0821e-05, ...
                "Unexpected channel flow area.");

            testCase.verifyEqual( ...
                geometry.PERIM, ...
                0.0276, ...
                "Unexpected wall perimeter.");

        end

        function boundaryConditionInput(testCase)
            % BOUNDARYCONDITIONINPUT
            %
            % Verify that the initial TUTORIAL1 boundary conditions are
            % read correctly.

            % Construct the complete input set with warnings suppressed.
            inputSet = testCase.constructTutorialInputSet();

            % Verify that boundary conditions were imported.
            testCase.assertNotEmpty( ...
                inputSet.bc, ...
                "No boundary-condition states were imported.");

            % Retrieve the initial boundary-condition state.
            boundaryConditions = inputSet.bc(1);

            % Verify representative prescribed values.
            testCase.verifyEqual( ...
                boundaryConditions.TIME, ...
                0, ...
                "Unexpected initial physical time.");

            testCase.verifyEqual( ...
                boundaryConditions.PRESSURE, ...
                6.0e6, ...
                "Unexpected system pressure.");

            testCase.verifyEqual( ...
                boundaryConditions.MFLOW, ...
                0.07, ...
                "Unexpected inlet mass flow rate.");

            testCase.verifyEqual( ...
                boundaryConditions.HIN, ...
                1.1394e6, ...
                "Unexpected inlet enthalpy.");

            testCase.verifyEqual( ...
                boundaryConditions.POWER, ...
                87500, ...
                "Unexpected total power.");

        end

        function completeInputSet(testCase)
            % COMPLETEINPUTSET
            %
            % Verify that InputSet combines the requested physical-model,
            % numerical-option, geometry, and boundary-condition inputs.

            % Construct the complete input set with warnings suppressed.
            inputSet = testCase.constructTutorialInputSet();

            % Verify the imported object classes.
            testCase.verifyEqual( ...
                class(inputSet.model), ...
                'Inputs.Model', ...
                "Unexpected physical-model object class.");

            testCase.verifyEqual( ...
                class(inputSet.options), ...
                'Inputs.Options', ...
                "Unexpected numerical-option object class.");

            testCase.verifyEqual( ...
                class(inputSet.geometry), ...
                'Inputs.Geometry', ...
                "Unexpected geometry object class.");

            % Verify the selected input-set identifiers.
            testCase.verifyEqual( ...
                string(inputSet.model.ID), ...
                "TUTORIAL1", ...
                "Unexpected physical-model input-set ID.");

            testCase.verifyEqual( ...
                string(inputSet.options.ID), ...
                "DEFAULT", ...
                "Unexpected numerical-option input-set ID.");

            testCase.verifyEqual( ...
                string(inputSet.geometry.ID), ...
                "TUTORIAL1", ...
                "Unexpected geometry input-set ID.");

            % Verify that boundary conditions are available.
            testCase.assertNotEmpty( ...
                inputSet.bc, ...
                "The complete input set contains no boundary conditions.");

        end

    end

    methods (TestClassTeardown)

        function removeGeneratedOutputs(testCase)
            % REMOVEGENERATEDOUTPUTS
            %
            % Remove temporary files and session directories generated
            % while constructing InputSet objects.

            if isfolder(testCase.outputFolder)
                rmdir(testCase.outputFolder,'s');
            end

        end

    end

    methods (Access = private)

        function inputSet = constructTutorialInputSet(testCase)
            % CONSTRUCTTUTORIALINPUTSET
            %
            % Construct the TUTORIAL1 input set while temporarily
            % suppressing warnings generated for input properties that
            % retain their documented default values.
            %
            % The previous MATLAB warning configuration is restored
            % automatically, including when InputSet construction fails.

            import Inputs.*

            % Preserve the complete MATLAB warning configuration.
            warningState = warning;

            % Restore the original warning configuration when this helper
            % completes or exits because of an exception.
            warningCleanup = onCleanup( ...
                @() warning(warningState));

            % Suppress warnings during InputSet construction.
            warning('off','all');

            % Construct the complete input set.
            inputSet = InputSet( ...
                modelFilePath         = fullfile(testCase.inputFolder,'models.inp'), ...
                modelID               = 'TUTORIAL1', ...
                optionsFilePath       = fullfile(testCase.inputFolder,'options.inp'), ...
                optionsID             = 'DEFAULT', ...
                geometryFilePath      = fullfile(testCase.inputFolder,'geom.inp'), ...
                geometryID            = 'TUTORIAL1', ...
                bcFilePath            = fullfile(testCase.inputFolder,'tutorial1.inp'), ...
                sessionParentDir      = testCase.outputFolder, ...
                overwriteSessionFiles = true, ...
                LOGMODE = 'LOGTOCONSOLEONLY');

            % Deleting the cleanup object invokes its callback and restores
            % the original warning configuration immediately.
            clear warningCleanup

        end

    end

end