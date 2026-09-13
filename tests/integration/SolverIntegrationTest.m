classdef SolverIntegrationTest < matlab.unittest.TestCase
    % SOLVERINTEGRATIONTEST
    %
    % Integration and regression tests for the OpenSTREAM solver frameworks.
    %
    % The class:
    %
    %   1. Constructs a common OpenSTREAM input case.
    %   2. Solves the case using the mixture, two-fluid, three-field, and
    %      four-field solver frameworks.
    %   3. Verifies that every solver reaches the expected converged state.
    %   4. Verifies propagation of the prescribed inlet boundary conditions.
    %   5. Verifies the steady-state mixture energy balance.
    %   6. Verifies consistency between the final pseudo-time initialization
    %      state and the first stored physical state.
    %   7. Compares calculated field mass flow rate, velocity, and enthalpy
    %      distributions with approved reference solutions.
    %   8. Verifies that solver objects can be saved and reloaded while
    %      retaining their class and solver state.
    %
    % The tests use the TUTORIAL1 model, numerical-option, geometry, and
    % boundary-condition input sets.
    %
    % Each solver framework is tested in an independent class-setup
    % Parameterization. The two-fluid, three-field, and four-field
    % constructors create and solve their required mixture solution.
    %
    % Approved reference solver objects are expected in:
    %   tests/integration/references/<session-directory>/
    %
    % Generated solver outputs are written to:
    %   tests/integration/outputs/<session-directory>/
    %

    properties (SetAccess = private)

        testNumber        % Numerical identifiers for the test cases.
        inputSet          % Input sets independently retained by the test class.
        solver            % OpenSTREAM solver objects.
        testFolder        % Absolute path to the folder containing this test class.
        testRoot          % Root folder containing all automated tests.
        openstreamRoot    % Absolute path to the OpenSTREAM repository root.
        inputFolder       % Absolute path to the OpenSTREAM input-file folder.
        outputFolder      % Absolute path used for generated test output.
        referenceFolder   % Absolute path containing approved reference solver objects.

    end

    properties (ClassSetupParameter)
        % Define the test cases.
        %
        % Each structure contains:
        %   Number             Numerical identifier used by the test class.
        %   ModelID            Physical-model input-set identifier.
        %   OptionsID          Numerical-option input-set identifier.
        %   GeometryID         Geometry input-set identifier.
        %   BoundaryCondition  Boundary-condition filename without the .inp extension.
        %   Constructor        Function handle to the corresponding solver constructor.

        caseOption = struct( ...
                        Mixture = ...
                            struct( ...
                            Name = "Mixture", ...
                            Number = 1, ...
                            ModelID = "TUTORIAL1", ...
                            OptionsID = "DEFAULT", ...
                            GeometryID = "TUTORIAL1", ...
                            BoundaryCondition = "tutorial1", ...
                            Constructor = @Solvers.Mixture.MixtureSolver), ...
                        TwoFluid = ...
                            struct( ...
                            Name = "TwoFluid", ...
                            Number = 2, ...
                            ModelID = "TUTORIAL1", ...
                            OptionsID = "DEFAULT", ...
                            GeometryID = "TUTORIAL1", ...
                            BoundaryCondition = "tutorial1", ...
                            Constructor = @Solvers.TwoFluid.TwoFluidSolver), ...
                        ThreeField = ...
                            struct( ...
                            Name = "ThreeField", ...
                            Number = 3, ...
                            ModelID = "TUTORIAL1", ...
                            OptionsID = "DEFAULT", ...
                            GeometryID = "TUTORIAL1", ...
                            BoundaryCondition = "tutorial1", ...
                            Constructor = @Solvers.ThreeField.ThreeFieldSolver), ...
                        FourField = ...
                            struct( ...
                            Name = "FourField", ...
                            Number = 4, ...
                            ModelID = "TUTORIAL1", ...
                            OptionsID = "DEFAULT", ...
                            GeometryID = "TUTORIAL1", ...
                            BoundaryCondition = "tutorial1", ...
                            Constructor = @Solvers.FourField.FourFieldSolver) ...
                       );

    end

    methods (TestClassSetup)

        function constructAndSolveTestCase(testCase, caseOption)
            % CONSTRUCTANDSOLVETESTCASE
            %
            % Shared setup executed once before the individual test methods.
            %
            % The method:
            %
            %   1. Determines the repository paths.
            %   2. Adds the OpenSTREAM root to the MATLAB path.
            %   3. Recreates the output directory.
            %   4. Defines the solver case.
            %   5. Constructs and solves the selected solver object.
            %
            % The solved object is retained in testCase.solver and reused by all
            % test methods for the current class-setup parameterization.

            % Determine the test and repository paths.

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
            testCase.outputFolder = fullfile(testCase.testFolder,'outputs',caseOption.Name);

            % Define the approved-reference folder.
            testCase.referenceFolder = fullfile(testCase.testFolder,'references');

            % Add OpenSTREAM to the MATLAB path.

            % The path fixture restores the previous MATLAB path when the test class has completed.
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(testCase.openstreamRoot));

            % Verify the required folders.

            testCase.assertTrue(isfolder(testCase.inputFolder), ...
                "Input folder not found: " + testCase.inputFolder);

            testCase.assertTrue(isfolder(testCase.referenceFolder), ...
                "Reference folder not found: " + testCase.referenceFolder);

            % Recreate the temporary output directory.

            % Remove results generated by an earlier test run.
            if isfolder(testCase.outputFolder)
                rmdir(testCase.outputFolder,'s');
            end

            % Create a clean output directory for this test run.
            mkdir(testCase.outputFolder);

            % Import the OpenSTREAM Inputs package.
            import Inputs.*

            % Construct and solve test case.

                % Store the test identifier.
                testCase.testNumber = caseOption.Number;

                % Preserve the current MATLAB warning configuration.
                warningState = warning;

                % Restore the original warning configuration automatically,
                % including when InputSet construction throws an exception.
                warningCleanup = onCleanup(@() warning(warningState));

                % Suppress input-default warnings during automated testing.
                % A future improvement could suppress only specific OpenSTREAM warning identifiers.
                warning('off','all');

                % Construct the input set.
                inputSet = InputSet( ...
                    modelFilePath         = fullfile(testCase.inputFolder,'models.inp'), ...
                    modelID               = caseOption.ModelID, ...
                    optionsFilePath       = fullfile(testCase.inputFolder,'options.inp'), ...
                    optionsID             = caseOption.OptionsID, ...
                    geometryFilePath      = fullfile(testCase.inputFolder,'geom.inp'), ...
                    geometryID            = caseOption.GeometryID, ...
                    bcFilePath            = fullfile(testCase.inputFolder,caseOption.BoundaryCondition + ".inp"), ...
                    sessionParentDir      = testCase.outputFolder, ...
                    overwriteSessionFiles = false, ...
                    LOGMODE = 'BOTH');
                testCase.inputSet = inputSet;

                % Clearing the cleanup object restores the original warning
                % configuration immediately after successful construction.
                clear warningCleanup

                % Construct the solver object.
                testCase.solver= caseOption.Constructor(testCase.inputSet);

                % Solve the flow fields.
                testCase.solver.solve();
            

        end

    end

    methods (Test)

        function solverStates(testCase)
            % SOLVERSTATES
            %
            % Verify that the solver reaches the expected converged state.

            % Retrieve the calculated solver object.
            result = testCase.solver;

            % Obtain the short solver-class name for the test message.
            solverName = testCase.getSolverName(result);

            % Verify the expected solver state.
            testCase.verifyEqual( ...
                result.STATE, ...
                Solvers.SolverState.INITIALSTEPCONVERGED, ...
                solverName + ...
                ": The solver did not reach the expected converged state.");

        end

        function mixtureBoundaryConditions(testCase)
            % MIXTUREBOUNDARYCONDITIONS
            %
            % Verify that the first stored physical state satisfies the prescribed
            % inlet boundary conditions without modification.

            % Assume the mixture-solver case.
            % testCase.assumeEqual( ...
            %     class(testCase.solver), ...
            %     'Solvers.Mixture.MixtureSolver', ...
            %     "this test is only for the MixtureSolver case.")
            
            if ~isa(testCase.solver, "Solvers.Mixture.MixtureSolver")
                % Retrieve the calculated mixture solver.
                results = testCase.solver.mixSolver;
            else
                % Retrieve the calculated mixture solver.
                results = testCase.solver;
            end
            
            % Obtain the short solver-class name for test messages.
            solverName = testCase.getSolverName(results);

            % Verify that a physical solution is available.
            testCase.assertNotEmpty( ...
                results.mixture, ...
                solverName + ...
                ": No stored physical solution is available.");

            % Retrieve the input set independently retained by the test class.
            suppliedInputSet = results.inputSet;

            % Retrieve the initial boundary-condition state.
            boundaryConditions = suppliedInputSet.bc(1);

            % Retrieve the first stored physical state.
            mixtureStep = results.mixture(1);

            % Verify the inlet pressure.
            testCase.verifyEqual( ...
                mixtureStep.P(1), ...
                boundaryConditions.PRESSURE, ...
                solverName + ...
                ": Initial inlet pressure mismatch.");

            % Verify the inlet mass flow rate.
            testCase.verifyEqual( ...
                mixtureStep.W(1), ...
                boundaryConditions.MFLOW, ...
                solverName + ...
                ": Initial inlet mass-flow-rate mismatch.");

            % Verify the inlet enthalpy.
            testCase.verifyEqual( ...
                mixtureStep.H(1), ...
                boundaryConditions.HIN, ...
                solverName + ...
                ": Initial inlet enthalpy mismatch.");

        end

        function mixtureEnergyBalance(testCase)
            % MIXTUREENERGYBALANCE
            %
            % Verify that the first stored physical state satisfies the prescribed
            % steady-state energy balance.

            if ~isa(testCase.solver, "Solvers.Mixture.MixtureSolver")
                % Retrieve the calculated mixture solver.
                results = testCase.solver.mixSolver;
            else
                % Retrieve the calculated mixture solver.
                results = testCase.solver;
            end

            % Obtain the short solver-class name for test messages.
            solverName = testCase.getSolverName(results);

            % Verify that a physical solution is available.
            testCase.assertNotEmpty( ...
                results.mixture, ...
                solverName + ...
                ": No stored physical solution is available.");

            % Retrieve the input set independently retained by the test class.
            suppliedInputSet = results.inputSet;

            % Retrieve the initial boundary-condition state.
            boundaryConditions = suppliedInputSet.bc(1);

            % Retrieve the first stored physical state.
            mixtureStep = results.mixture(1);

            % Calculate the expected outlet enthalpy from the imposed steady-state
            % energy balance.
            expectedOutletEnthalpy = ...
                boundaryConditions.HIN + ...
                boundaryConditions.POWER / ...
                boundaryConditions.MFLOW;

            % Verify the outlet enthalpy.
            testCase.verifyEqual( ...
                mixtureStep.H(end), ...
                expectedOutletEnthalpy, ...
                solverName + ...
                ": Initial outlet enthalpy mismatch.", ...
                RelTol = 1e-3, ...
                AbsTol = 1e-6);

        end

        function mixtureInitializationTransfer(testCase)
            % MIXTUREINITIALIZATIONTRANSFER
            %
            % Verify that selected physical properties in the final pseudo-time
            % initialization state are transferred unchanged to the first stored
            % physical state.

            if ~isa(testCase.solver, "Solvers.Mixture.MixtureSolver")
                % Retrieve the calculated mixture solver.
                results = testCase.solver.mixSolver;
            else
                % Retrieve the calculated mixture solver.
                results = testCase.solver;
            end

            % Obtain the short solver-class name for test messages.
            solverName = testCase.getSolverName(results);

            % Verify that the required states are available.
            testCase.assertNotEmpty( ...
                results.mixtureInit, ...
                solverName + ...
                ": No pseudo-time initialization states are available.");

            testCase.assertNotEmpty( ...
                results.mixture, ...
                solverName + ...
                ": No stored physical states are available.");

            % Retrieve the final pseudo-time initialization state.
            mixtureSteady = results.mixtureInit(end);

            % Retrieve the first stored physical state.
            mixtureStep = results.mixture(1);

            % Define the main properties expected to be transferred unchanged.
            propertiesToCompare = ["P","W","H","X","VF"];

            for propertyName = propertiesToCompare

                testCase.verifyEqual( ...
                    mixtureStep.(propertyName), ...
                    mixtureSteady.(propertyName), ...
                    solverName + ...
                    ": Initial physical state differs for " + ...
                    propertyName + ".");

            end

        end

        function fieldMassFlowRates(testCase)
            % FIELDMASSFLOWRATES
            %
            % Compare mass flow rates in all applicable solver fields with the
            % approved reference solutions.

            testCase.compareFieldProperty( ...
                "W", ...
                "mass flow rate");
        end

        function fieldVelocities(testCase)
            % FIELDVELOCITIES
            %
            % Compare velocities in all applicable solver fields with the approved
            % reference solutions.

            testCase.compareFieldProperty( ...
                "U", ...
                "velocity");
        end

        function fieldEnthalpies(testCase)
            % FIELDENTHALPIES
            %
            % Compare enthalpies in all applicable solver fields with the approved
            % reference solutions.

            testCase.compareFieldProperty( ...
                "H", ...
                "enthalpy");
        end

        function saveLoadRoundTrip(testCase)
            % SAVELOADROUNDTRIP
            %
            % Verify that the solver object can be saved and reloaded while
            % retaining its class and solver state.

            % Retrieve the original solver object.
            original = testCase.solver;

            % Obtain the short solver-class name used in the generated MAT-file name.
            solverName = testCase.getSolverName(original);

            % Save the solver object.
            original.save( ...
                'name', 'solver', ...
                'showpath', false);

            % Construct the expected saved-file path.
            fileName = fullfile( ...
                original.inputSet.session.parentDir, ...
                original.inputSet.session.dirName, ...
                original.inputSet.session.name + ...
                "_" + solverName + ".mat");

            % Confirm that the MAT-file was created.
            testCase.assertTrue( ...
                isfile(fileName), ...
                solverName + ...
                ": Saved solver file was not created.");

            % Reload the solver object.
            savedData = load(fileName);

            % Confirm that the selected variable name was stored in the MAT-file.
            testCase.assertTrue( ...
                isfield(savedData,'solver'), ...
                solverName + ...
                ": Saved variable 'solver' is missing.");

            restored = savedData.solver;

            % Verify the restored object.

            % Verify that the restored object has the same solver class.
            testCase.verifyEqual( ...
                class(restored), ...
                class(original), ...
                solverName + ...
                ": Restored solver class mismatch.");

            % Verify that the solver state was preserved.
            testCase.verifyEqual( ...
                restored.STATE, ...
                original.STATE, ...
                solverName + ...
                ": Restored solver state mismatch.");

        end

    end

    methods (TestClassTeardown)

    end

    methods (Access = private)

        function solverName = getSolverName(~,solver)
            % GETSOLVERNAME Return the short solver-class name.
            %
            % Example:
            %   Solvers.Mixture.MixtureSolver
            %
            % becomes:
            %   MixtureSolver

            classParts = split( ...
                string(class(solver)), ...
                ".");

            solverName = ...
                classParts(end);

        end

        function reference = loadReference(testCase,solver)
            % LOADREFERENCE Load the approved reference solver.
            %
            % The expected reference-file structure is:
            %
            %   references/
            %       <session-directory>/
            %           <session-name>_<solver-class>.mat
            %
            % The MAT-file must contain a variable named "solver".

            % Obtain the short solver-class name used by the MAT-file.
            solverName = ...
                testCase.getSolverName(solver);

            % Construct the expected reference-file path.
            referenceFile = fullfile( ...
                testCase.referenceFolder, ...
                solver.inputSet.session.dirName, ...
                solver.inputSet.session.name + ...
                "_" + solverName + ".mat");

            % Verify that the reference file exists.
            testCase.assertTrue( ...
                isfile(referenceFile), ...
                "Reference file not found: " + referenceFile);

            % Load the reference MAT-file into a structure.
            savedData = load(referenceFile);

            % Verify that the expected variable is present.
            testCase.assertTrue( ...
                isfield(savedData,'solver'), ...
                "Variable 'solver' is missing from " + ...
                referenceFile);

            % Retrieve the reference solver object.
            reference = savedData.solver;

            % Verify that the calculated and reference objects use the same
            % solver class.
            testCase.assertEqual( ...
                class(solver), ...
                class(reference), ...
                solverName + ...
                ": Solver class mismatch.");

        end

        function compareFieldProperty( ...
                testCase, ...
                propertyName, ...
                propertyDescription)
            % COMPAREFIELDPROPERTY
            %
            % Compare a selected primary field quantity with the corresponding
            % approved reference solution using a relative tolerance.
            %
            % The requested quantity may be implemented either as:
            %   * a stored or dependent property, such as W or H; or
            %   * a zero-input method, such as U for the mixture solver.
            %
            % Inputs:
            %
            %   propertyName
            %       Exact property or method name, such as "W", "U", or "H".
            %
            %   propertyDescription
            %       Human-readable description used in diagnostic messages, such
            %       as "mass flow rate", "velocity", or "enthalpy".
            %
            % Candidate field paths:
            %
            %   MixtureSolver
            %       mixture
            %       mixture.liquid
            %       mixture.vapor
            %
            %   TwoFluidSolver
            %       liquid
            %       vapor
            %
            %   ThreeFieldSolver
            %       film
            %       drop
            %
            %   FourFieldSolver
            %       film
            %       drop
            %       film.basefilm
            %       film.wave
            %
            % Field paths that do not apply to a particular solver are skipped. The
            % calculated and reference values are compared using the relative
            % tolerance defined in this method. The tolerance permits small numerical
            % differences between supported execution environments while retaining
            % sensitivity to solver regressions. When a reference value is exactly
            % zero, the calculated value must also be exactly zero because no absolute
            % tolerance is applied.
            %
            % The test requires at least one applicable field quantity for each
            % solver and at least one comparison across the complete test.

            % Define the possible field paths across all solver frameworks.
            fieldPaths = [ ...
                "mixture", ...
                "mixture.liquid", ...
                "mixture.vapor", ...
                "liquid", ...
                "vapor", ...
                "film", ...
                "drop", ...
                "film.basefilm", ...
                "film.wave"];

            % Define the regression-comparison tolerance.
            relativeTolerance = 1e-8;

            % Count the total number of property comparisons performed by this
            % test.
            numberOfVerifiedProperties = 0;

            % Retrieve the calculated solver object.
            results = testCase.solver;

            % Load the corresponding approved reference solver.
            references = testCase.loadReference(results);

            % Obtain the short solver-class name for diagnostic messages.
            solverName = testCase.getSolverName(results);

            % Count the applicable field quantities verified for this solver.
            numberOfVerifiedFields = 0;

            for fieldPath = fieldPaths

                % Retrieve the calculated field object at the first stored
                % physical state.
                [resultField,resultFieldExists] = ...
                    testCase.getFieldByPath( ...
                    results, ...
                    fieldPath);

                % Retrieve the corresponding reference field object.
                [referenceField,referenceFieldExists] = ...
                    testCase.getFieldByPath( ...
                    references, ...
                    fieldPath);

                % Verify that the calculated and reference solver structures
                % expose the same field paths.
                testCase.assertEqual( ...
                    resultFieldExists, ...
                    referenceFieldExists, ...
                    solverName + ...
                    ": Field path '" + fieldPath + ...
                    "' is not consistently available.");

                % Skip field paths that do not apply to the selected solver.
                if ~resultFieldExists
                    continue
                end

                % Retrieve the requested calculated quantity. The quantity may
                % be implemented as a property or as a zero-input method.
                [resultValue,resultValueExists] = ...
                    testCase.getFieldValue( ...
                    resultField, ...
                    propertyName);

                % Retrieve the corresponding reference quantity.
                [referenceValue,referenceValueExists] = ...
                    testCase.getFieldValue( ...
                    referenceField, ...
                    propertyName);

                % Verify that the calculated and reference field interfaces
                % expose the requested quantity consistently.
                testCase.assertEqual( ...
                    resultValueExists, ...
                    referenceValueExists, ...
                    solverName + ...
                    ": Quantity '" + propertyName + ...
                    "' is not consistently available in field '" + ...
                    fieldPath + "'.");

                % Skip fields that do not expose the requested quantity.
                if ~resultValueExists
                    continue
                end

                % Verify that the calculated quantity is not empty.
                testCase.assertNotEmpty( ...
                    resultValue, ...
                    solverName + ...
                    ": Field '" + fieldPath + ...
                    "' has an empty " + ...
                    propertyDescription + " array.");

                % Verify that the reference quantity is not empty.
                testCase.assertNotEmpty( ...
                    referenceValue, ...
                    solverName + ...
                    ": Reference field '" + fieldPath + ...
                    "' has an empty " + ...
                    propertyDescription + " array.");

                % Compare the calculated and approved reference values.
                diagnostic = sprintf( ...
                    '%s: %s %s mismatch using RelTol = %.1e.', ...
                    char(solverName), ...
                    char(fieldPath), ...
                    char(propertyDescription), ...
                    relativeTolerance);

                testCase.verifyEqual( ...
                    resultValue, ...
                    referenceValue, ...
                    diagnostic, ...
                    RelTol = relativeTolerance);

                % Record the completed comparison.
                numberOfVerifiedFields = ...
                    numberOfVerifiedFields + 1;

                numberOfVerifiedProperties = ...
                    numberOfVerifiedProperties + 1;

            end

            % Ensure that at least one applicable field quantity was verified
            % for the selected solver.
            testCase.verifyGreaterThan( ...
                numberOfVerifiedFields, ...
                0, ...
                solverName + ...
                ": No applicable " + ...
                propertyDescription + ...
                " field was found.");

            % Prevent the complete test from passing without comparing any values.
            testCase.verifyGreaterThan( ...
                numberOfVerifiedProperties, ...
                0, ...
                "No applicable field quantity '" + ...
                propertyName + "' was tested.");

        end

        function [fieldObject, fieldExists] = ...
                getFieldByPath(~,solver,fieldPath)
            % GETFIELDBYPATH
            %
            % Retrieve the first stored physical field state using a dot-separated
            % property path.
            %
            % Examples:
            %
            %   "mixture"
            %   "liquid"
            %   "film"
            %   "film.basefilm"
            %   "film.wave"
            %
            % Outputs:
            %
            %   fieldObject
            %       Retrieved field object when the complete path exists.
            %
            %   fieldExists
            %       Logical true when the complete path exists and contains a
            %       nonempty object.

            pathParts = split(fieldPath,".");

            fieldObject = solver;
            fieldExists = true;

            for pathIndex = 1:numel(pathParts)

                propertyPart = pathParts(pathIndex);

                % The current object must expose the next property.
                if ~isprop(fieldObject,propertyPart)

                    fieldObject = [];
                    fieldExists = false;
                    return

                end

                % Retrieve the next object in the path.
                fieldObject = fieldObject.(propertyPart);

                % The requested object must contain at least one stored state.
                if isempty(fieldObject)

                    fieldObject = [];
                    fieldExists = false;
                    return

                end

                % The top-level solver field is an array of stored physical states.
                % Select the first state before accessing a nested four-field object.
                if pathIndex == 1
                    fieldObject = fieldObject(1);
                end

            end

        end

        function [value,valueExists] = ...
                getFieldValue(~,fieldObject,valueName)
            % GETFIELDVALUE
            %
            % Retrieve a field quantity implemented either as a property or as a
            % zero-input method.

            value = [];
            valueExists = false;

            % Retrieve a stored or dependent property.
            if isprop(fieldObject,valueName)

                value = fieldObject.(valueName);
                valueExists = true;
                return

            end

            % Evaluate a zero-input method.
            if ismethod(fieldObject,valueName)

                try

                    value = feval( ...
                        char(valueName), ...
                        fieldObject);

                    valueExists = true;

                catch ME

                    error( ...
                        'OpenSTREAM:FieldMethodEvaluationFailed', ...
                        "Unable to evaluate method '%s' for class '%s': %s", ...
                        valueName, ...
                        class(fieldObject), ...
                        ME.message);

                end

            end

        end

    end

end