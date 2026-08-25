Contribute to the code
======================

Contributions to the OpenSTREAM solvers, documentation, tutorials, tests,
and examples are welcome. Following the guidelines below helps ensure that
changes can be reviewed, tested, and integrated efficiently.

How to contribute
-----------------

#. **Fork the repository**

   Open the `OpenSTREAM repository
   <https://github.com/OpenSTREAM-solvers/openstream>`_ and select
   **Fork** to create a copy under your GitHub account.

#. **Clone your fork**

   .. code-block:: bash

      git clone https://github.com/<your-username>/openstream.git
      cd openstream

#. **Create a development branch**

   Create a branch with a concise name describing the intended change:

   .. code-block:: bash

      git checkout -b feature/my-new-feature

   Other appropriate prefixes may include ``fix/``, ``docs/``, and
   ``test/``.

#. **Make your changes**

   - Follow the coding and documentation standards described below.
   - Add or update tests when functionality or numerical behavior changes.
   - Update user documentation when the change affects visible behavior,
     inputs, outputs, workflows, or examples.
   - Avoid committing generated output files.

#. **Run the automated tests**

   From the ``tests`` folder, run:

   .. code-block:: matlab

      runOpenSTREAMTests

   Confirm that the complete available test suite passes before pushing
   the change.

#. **Commit and push the changes**

   Use a concise and descriptive commit message:

   .. code-block:: bash

      git add .
      git commit -m "Add feature: description"
      git push origin feature/my-new-feature

   Review the staged files before committing to ensure that generated
   outputs, temporary files, and unrelated changes are not included.

#. **Open a pull request**

   Open a pull request against the original OpenSTREAM repository.

   The pull-request description should:

   - Explain the purpose of the change.
   - Summarize the implementation.
   - Identify affected models, solvers, inputs, tests, or documentation.
   - Describe any intentional numerical changes.
   - Explain and justify any changes to approved reference solutions.
   - Reference related issues when applicable.

Coding standards
----------------

MATLAB
~~~~~~

- Use clear and descriptive variable, property, method, and class names.
- Follow the existing OpenSTREAM package and class organization.
- Document public classes, properties, functions, and methods.
- Add comments where they clarify numerical methods, physical assumptions,
  or non-obvious implementation choices.
- Avoid hard-coded repository paths.
- Use ``fullfile`` when constructing file-system paths.
- Preserve the existing coding style unless a broader refactoring is part
  of the proposed change.
- Avoid unrelated formatting changes in the same commit as a functional
  modification.

Python
~~~~~~

- Follow PEP 8 conventions where practical.
- Document externally visible functions and classes.
- Keep interactions between MATLAB and Python explicit and reproducible.
- Update dependency specifications when adding or modifying Python package
  requirements.

General practices
~~~~~~~~~~~~~~~~~

- Keep commits focused and descriptive.
- Prefer automated tests over manual verification whenever practical.
- Avoid duplicating existing functionality.
- Preserve backward compatibility unless an incompatible change is
  intentional, documented, and reviewed.
- Separate functional changes from large documentation or formatting
  changes when practical.

Documentation
-------------

Update the documentation when a contribution changes:

- User-visible functionality.
- Input parameters or accepted values.
- Default model or numerical selections.
- Solver behavior or calculated outputs.
- Public classes, methods, or properties.
- Installation or dependency requirements.
- Tutorials or recommended workflows.
- File names, links, or repository organization.

Documentation changes should be reviewed in both the generated website and
PDF documentation when the affected content is included in both formats.

Testing
-------

OpenSTREAM includes automated environment, unit, integration, and
regression verification. The tests are organized under:

.. code-block:: text

   tests/environment/
   tests/unit/
   tests/integration/

The complete available test suite can be run from the ``tests`` folder:

.. code-block:: matlab

   runOpenSTREAMTests

The runner recursively discovers the available test classes, displays
detailed diagnostics, produces a summary table, reports the total
test-suite execution time, and raises an error if any test fails or does
not complete.

After execution, the MATLAB test results and generated summary table are
available in the workspace as ``testResults`` and ``testSummary``.

The current test categories include:

- Environment tests that verify the MATLAB-Python interface, required
  Python packages, and basic CoolProp functionality.
- Unit tests that verify focused OpenSTREAM components, currently
  including input handling.
- Integration tests that construct and solve representative OpenSTREAM
  cases, perform physical-consistency checks, compare selected numerical
  results with approved references, and verify solver persistence.

The automated test suite is under active development and does not yet
exercise every OpenSTREAM class, method, physical model, numerical option,
solver path, error condition, or post-processing capability. A successful
test run confirms that the currently implemented tests passed. It does not
constitute complete verification or validation of OpenSTREAM.

Testing contributions
~~~~~~~~~~~~~~~~~~~~~

Contributors should:

- Add focused unit tests for new testable classes, functions, and methods.
- Add integration tests when a change affects solver workflows, physical
  consistency, or numerical results.
- Add environment tests when introducing new external dependencies.
- Verify that all existing tests continue to pass.
- Review numerical differences from approved references.
- Update tests when expected behavior changes intentionally.
- Update the testing documentation when the framework, test organization,
  or execution procedure changes.

Reference solutions
~~~~~~~~~~~~~~~~~~~

Approved solver-reference objects are stored below:

.. code-block:: text

   tests/integration/references/<session-directory>/

These files form part of the numerical regression baseline and are
version-controlled.

Reference solutions should be updated only when:

- A defect has been corrected.
- A model formulation has intentionally changed.
- Numerical behavior has intentionally changed and the new behavior has
  been reviewed.
- A justified change to the approved test environment changes the
  calculated reference results.

Reference solutions should not be replaced merely to make a failing test
pass. Before updating a reference, identify and understand the numerical
differences and document why the new result is correct.

Generated outputs
~~~~~~~~~~~~~~~~~

Some tests generate temporary files, logs, session directories, CSV files,
and saved solver objects under category-specific ``outputs`` directories.

Generated outputs are excluded from version control and should not
normally be committed. Approved reference solutions are stored separately
and should be committed only as part of a justified and reviewed update to
the regression baseline.

Continuous integration
~~~~~~~~~~~~~~~~~~~~~~

The complete available test suite is executed automatically by the MATLAB
CI workflow when changes are pushed to the repository.

After pushing a change:

#. Open the corresponding GitHub Actions run.
#. Confirm that the MATLAB CI workflow completes successfully.
#. Review the diagnostic output if a test fails or does not complete.
#. Reproduce failures locally using ``runOpenSTREAMTests``.
#. Push a correction only after rerunning the complete local test suite.

The documentation build and MATLAB CI are separate workflows. A successful
documentation build or GitHub Pages deployment does not indicate that the
MATLAB tests passed. Review both workflow results independently.

Reporting issues
----------------

Use the `OpenSTREAM issue tracker
<https://github.com/OpenSTREAM-solvers/openstream/issues>`_ to report
defects, request enhancements, or propose changes.

An issue report should include, where applicable:

- A clear description of the problem.
- Steps required to reproduce the behavior.
- Expected and actual behavior.
- The relevant OpenSTREAM version or commit.
- MATLAB and Python versions.
- Relevant dependency versions.
- Input files or a minimal reproducible case.
- Solver output, logs, screenshots, or error messages.
- Any temporary workaround that has been identified.

Before opening a new issue, review existing issues to determine whether
the topic has already been reported or discussed.

Code of conduct
---------------

Contributors should communicate respectfully and constructively. Technical
disagreements should focus on the implementation, evidence, assumptions,
and expected behavior rather than on individuals.

Communication
-------------

Use `GitHub Discussions
<https://github.com/OpenSTREAM-solvers/discussions>`_ for general
questions, ideas, and community discussions.

For major changes, open an issue before beginning implementation. Early
discussion is particularly useful for:

- New solver frameworks.
- New conservation equations or closure-model families.
- Changes to established model formulations.
- Changes to public interfaces or input formats.
- Changes that affect backward compatibility.
- Changes that require substantial updates to regression references.

Contributor checklist
---------------------

Before submitting a pull request, confirm that:

- The change is limited to the intended scope.
- The code follows the existing OpenSTREAM style and organization.
- New or modified functionality includes appropriate tests.
- The complete local test suite passes.
- Numerical differences from approved references have been reviewed.
- Reference solutions have been updated only when justified.
- User-visible behavior is documented.
- Relevant tutorials or examples have been updated.
- Documentation links and cross-references remain valid.
- Generated outputs and temporary files are not committed.
- The MATLAB CI workflow passes after the changes are pushed.
- Documentation workflows pass when documentation has been modified.