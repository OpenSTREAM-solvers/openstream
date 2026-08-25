Testing and verification
========================

OpenSTREAM includes an automated testing framework to support code verification,
numerical consistency, and software environment compatibility.

The test suite is intended to:

- Detect regressions when modifying existing functionality.
- Verify representative solver workflows against reference solutions.
- Confirm that required external dependencies are available and functional.
- Support reproducible development.

The current test suite focuses primarily on core infrastructure and a
subset of solver capabilities. Additional tests will be added over time
to improve coverage of numerical models, closure laws, input processing,
and post-processing functionality.

.. note::

   OpenSTREAM's automated test suite is under active development.

   The current tests verify selected functionality, solver workflows,
   numerical results, and software dependencies, but do not provide
   comprehensive coverage of the complete OpenSTREAM code base or every
   implemented physical model and numerical option.

   Passing all tests indicates that the covered functionality behaves as
   expected for the tested cases. It should not be interpreted as complete
   verification or validation of OpenSTREAM.

Test organization
-----------------

The OpenSTREAM tests are organized into three categories:

.. list-table::
   :header-rows: 1

   * - Folder
     - Purpose
   * - ``tests/environment``
     - Verification of the MATLAB-Python environment and required external
       packages, including basic CoolProp functionality.
   * - ``tests/unit``
     - Focused tests of individual OpenSTREAM classes, methods, and
       utilities.
   * - ``tests/integration``
     - End-to-end solver workflows, physical consistency checks, numerical
       regression comparisons, and solver persistence tests.

Unit tests should execute quickly and focus on individual components.
Integration tests construct and solve representative OpenSTREAM cases
and compare selected calculated quantities with approved reference
solutions.

Running all tests
-----------------

The recommended way to execute the complete test suite is to run
``runOpenSTREAMTests.m`` from the ``tests`` folder:

.. code-block:: matlab

   runOpenSTREAMTests

The test runner:

- Recursively discovers test classes in the ``tests`` folder and its
  subfolders.
- Executes the environment, unit, and integration tests, including the
  numerical regression comparisons.
- Displays detailed progress and failure diagnostics.
- Displays a summary table containing the test class, test method, and
  result.
- Reports the total execution time of the complete test suite.
- Raises an error if any test fails or does not complete.

After execution, the MATLAB test results and generated summary table are
available in the workspace as ``testResults`` and ``testSummary``.

A successful run finishes without errors and reports all tests as passed.

Running individual test categories
----------------------------------

Individual test categories can also be run separately from the ``tests``
folder.

Environment validation tests:

.. code-block:: matlab

   suite = matlab.unittest.TestSuite.fromFolder('environment');
   runner = matlab.unittest.TestRunner.withTextOutput;
   results = runner.run(suite);

Unit tests:

.. code-block:: matlab

   suite = matlab.unittest.TestSuite.fromFolder('unit');
   runner = matlab.unittest.TestRunner.withTextOutput;
   results = runner.run(suite);

Integration tests:

.. code-block:: matlab

   suite = matlab.unittest.TestSuite.fromFolder('integration');
   runner = matlab.unittest.TestRunner.withTextOutput;
   results = runner.run(suite);

The command ``results = runner.run(suite)`` returns an array of
``matlab.unittest.TestResult`` objects, with one element for each test
method executed. Each element records the test name, pass, failure, and
incomplete status, execution duration, and additional framework details.

The results can be inspected directly or converted to a table:

.. code-block:: matlab

   disp(results)
   resultTable = table(results);
   disp(resultTable)

Failed or incomplete tests can be identified using:

.. code-block:: matlab

   failed = results([results.Failed]);
   incomplete = results([results.Incomplete]);
   notPassed = results(~[results.Passed]);

Continuous integration
----------------------

The complete available test suite is executed automatically by the MATLAB
CI workflow when changes are pushed to the repository.

After pushing a change, review the MATLAB CI result in GitHub Actions.
The workflow fails if any automated test fails or does not complete.

The documentation build and MATLAB CI are separate workflows. A successful
documentation build or GitHub Pages deployment does not indicate that the
MATLAB tests passed. The status of each workflow should therefore be
reviewed independently.

When MATLAB CI fails:

#. Open the failed MATLAB CI workflow.
#. Identify the failing test class and test method in the diagnostics.
#. Reproduce the failure locally using ``runOpenSTREAMTests``.
#. Determine whether the failure results from a software defect, an
   unintended numerical change, a changed environment, or an intentional
   modification that requires an approved update to the test or reference
   solution.
#. Run the complete test suite locally before pushing the correction.

Reference solutions
-------------------

Integration tests compare selected generated results with approved
reference solutions.

Reference data are stored under:

.. code-block:: text

   tests/integration/references/<session-directory>/

The reference solutions represent the expected solver behavior for defined
test cases. They are version-controlled and form part of the approved
regression baseline.

Reference solutions should only be updated when:

- A defect has been corrected.
- A model formulation has intentionally changed.
- Numerical behavior has been intentionally modified and reviewed.
- The approved test environment has changed in a way that justifiably
  changes the calculated reference results.

Reference solutions should **not** be updated merely to make a failing
test pass. Before replacing a reference solution, the numerical
differences and their cause should be understood and reviewed.

Adding new tests
----------------

When introducing new functionality:

#. Add unit tests whenever possible.
#. Add integration tests if the change affects solver results.
#. Verify that all existing tests continue to pass.
#. Update the documentation if user-visible behavior changes.

As a general rule:

- New testable classes and methods should have focused unit tests.
- New numerical and closure models should have unit tests where possible
  and integration tests demonstrating their solver-level behavior.
- New external dependencies should have environment tests.

Unit test guidelines
--------------------

Unit tests should:

- Focus on a single class or function.
- Use small and deterministic inputs.
- Avoid unnecessary file I/O.
- Execute quickly.
- Be independent of one another.

A good unit test verifies one piece of behavior and has a clear failure mode.

Integration test guidelines
---------------------------

Integration tests should, where practical:

- Exercise representative solver workflows.
- Use representative and reproducible input files.
- Verify that solvers reach their expected states.
- Verify propagation of prescribed boundary conditions.
- Check relevant conservation or physical-consistency relationships.
- Compare important calculated quantities with approved reference values.
- Verify that saved solver objects can be reloaded consistently.
- Produce deterministic results suitable for automated execution.

The current solver integration tests verify selected behavior including:

- Final solver states.
- Mixture-solver inlet boundary conditions.
- The mixture steady-state energy balance.
- Transfer of the final pseudo-time initialization state to the first
  stored physical state.
- Field mass flow rate distributions.
- Field velocity distributions.
- Field enthalpy distributions.
- Solver save-and-load behavior.

Calculated field distributions are compared with the approved reference
values using a strict relative tolerance. This avoids false failures caused
by insignificant floating-point differences while retaining sensitivity
to numerical regressions. Reference values equal to zero remain subject to
exact comparison because no absolute tolerance is currently applied.

Future integration tests may additionally verify pressures, void
fractions, film thicknesses, exchange terms, transition locations, and
other solver-specific quantities.

Not all quantities, solver options, model combinations, physical regimes,
error conditions, or post-processing capabilities are currently tested.

Environment validation
----------------------

Environment tests verify external software requirements.

The current environment tests verify:

- Python availability through MATLAB.
- Python-version accessibility.
- Installation and import of required Python packages.
- Basic CoolProp functionality.

Environment tests help identify installation problems before running larger
simulations.

Generated outputs
-----------------

Some tests generate temporary files, session directories, logs, and saved
solver objects.

Generated outputs are stored in category-specific ``outputs`` directories,
including:

.. code-block:: text

   tests/unit/outputs/
   tests/integration/outputs/

Unit-test artifacts are removed automatically during test teardown.
Integration-test outputs are retained after execution to support
inspection and troubleshooting, and are recreated or replaced by a
subsequent test run.

Generated outputs should not normally be committed to the repository.
Repository ``.gitignore`` rules exclude directories named ``outputs`` from
version control.

Approved reference solutions are stored separately under
``tests/integration/references`` and remain version-controlled as part of
the regression baseline.

Troubleshooting
---------------

A test failure does not necessarily indicate a software defect.

When a test fails:

#. Read the diagnostic message carefully.
#. Identify the failing test class and method.
#. Determine whether the failure is caused by:

   - A coding error.
   - An unintended numerical change.
   - An intentional model or numerical change.
   - An outdated or inappropriate reference solution.
   - A software-environment or dependency problem.
   - A platform-dependent floating-point difference.

#. Re-run the failing test class or test category locally.
#. Inspect generated outputs and compare the actual and expected values.
#. Verify the expected behavior manually when needed.
#. Update reference solutions only when the change is intentional,
   understood, justified, and reviewed.
#. Run the complete test suite before pushing the correction.

Contributor checklist
---------------------

Before submitting a pull request:

- The complete local test suite passes.
- New or modified functionality includes appropriate tests.
- Numerical differences from approved references have been reviewed.
- Reference solutions have been updated only when justified.
- Documentation has been updated when user-visible behavior changes.
- Generated outputs are not committed.
- The MATLAB CI workflow passes after the changes are pushed.