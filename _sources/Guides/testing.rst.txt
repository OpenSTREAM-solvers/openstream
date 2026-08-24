Testing and verification
========================

OpenSTREAM includes an automated testing framework to support code verification,
numerical consistency, and software environment compatibility.

The test suite is intended to:

- Detect regressions when modifying existing functionality.
- Verify representative solver workflows against reference solutions.
- Confirm that external dependencies are installed correctly.
- Support reproducible development.

The current test suite focuses primarily on core infrastructure and a
subset of solver capabilities. Additional tests will be added over time
to improve coverage of numerical models, closure laws, input processing,
and post-processing functionality.

.. note::

   OpenSTREAM's automated test suite is under active development.

   The current tests verify selected functionality, solver workflows,
   numerical results, and software dependencies, but do not yet provide
   comprehensive coverage of the OpenSTREAM code base or all physical
   models implemented in the framework.

   Passing all tests indicates that the covered functionality behaves as
   expected for the tested cases. It should not be interpreted as proof
   that all functionality has been verified or validated.

   Test coverage and verification capabilities will continue to expand
   as OpenSTREAM evolves.

Test organization
-----------------

The OpenSTREAM tests are organized into three categories:

.. list-table::
   :header-rows: 1

   * - Folder
     - Purpose
   * - ``tests/unit``
     - Fast tests of individual classes, methods, and utilities.
   * - ``tests/integration``
     - Verification of selected solver workflows against reference solutions.
   * - ``tests/environment``
     - Validation of external dependencies and software configuration.

Unit tests should execute quickly and focus on individual components.
Integration tests verify selected solver calculations and numerical results.

Running all Ttsts
-----------------

The recommended way to execute the complete test suite is:

.. code-block:: matlab

   results = runOpenSTREAMTests;

The test runner:

- Executes all configured test suites.
- Displays a summary table of the results.
- Reports test durations.
- Raises an error if any test fails.

A successful run should finish without errors and report all tests as passed.

Running individual test Suites
------------------------------

Unit tests:

.. code-block:: matlab

   suite = testsuite('tests/unit');
   runner = matlab.unittest.TestRunner.withTextOutput;
   results = runner.run(suite);

Integration tests:

.. code-block:: matlab

   suite = testsuite('tests/integration');
   runner = matlab.unittest.TestRunner.withTextOutput;
   results = runner.run(suite);

Environment validation tests:

.. code-block:: matlab

   suite = testsuite('tests/environment');
   runner = matlab.unittest.TestRunner.withTextOutput;
   results = runner.run(suite);

Reference solutions
-------------------

Integration tests compare generated results against reference solutions.

Reference data are stored in the integration-test reference directory.
The reference solutions represent the expected behavior of the solvers for a
defined set of benchmark cases.

Reference solutions are version-controlled and should be treated as part
of the verification baseline.

Reference results should only be updated when:

- A bug has been fixed.
- A model formulation has intentionally changed.
- Numerical behavior has been intentionally modified.

Reference results should **not** be updated simply to make failing tests pass.

Adding new Ttsts
----------------

When introducing new functionality:

#. Add unit tests whenever possible.
#. Add integration tests if the change affects solver results.
#. Verify that all existing tests continue to pass.
#. Update the documentation if user-visible behavior changes.

As a general rule:

- New classes should have unit tests.
- New numerical models should have integration tests.
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
- Use representative input files.
- Compare important physical quantities against reference values.
- Verify numerical consistency between solver versions.

Depending on the solver and test case, integration tests may verify quantities such as:

- Mass flow rates.
- Phase velocities.
- Enthalpies.
- Pressures.
- Void fractions.
- Film thicknesses.

Not all quantities are currently verified for all solvers.

Environment validation
----------------------

Environment tests verify external software requirements.

Current checks may include:

- MATLAB configuration.
- Python availability.
- Python package installation.
- External library accessibility.

Environment tests help identify installation problems before running larger
simulations.

Generated outputs
-----------------

Some tests generate temporary files and output directories.

The test framework automatically removes temporary files when possible.
Generated outputs should not normally be committed to the repository.

Reference solutions are stored separately and may be committed when they
form part of an approved update to the verification baseline.

Repository ``.gitignore`` rules exclude temporary test outputs from
version control.

Troubleshooting
---------------

A test failure does not necessarily indicate a software defect.

When a test fails:

#. Read the diagnostic message carefully.
#. Determine whether the failure is caused by:

- A coding error.
- An intentional model change.
- A changed reference solution.
- A software environment problem.

#. Re-run the failing test individually.
#. Verify the expected results manually if needed.
#. Update reference solutions only if the change is intentional and justified.

Contributor Checklist
---------------------

Before submitting a pull request:

- [ ] All tests pass.
- [ ] New functionality includes tests.
- [ ] Reference solutions have been reviewed if changed.
- [ ] Documentation has been updated when required.
- [ ] Generated outputs are not committed.