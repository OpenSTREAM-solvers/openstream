Troubleshooting
===============

This page provides initial diagnostic guidance for common OpenSTREAM setup,
execution, convergence, output, plotting, testing, and documentation
problems.

When investigating a problem, record the complete error message, software
versions, input selections, solver state, and steps required to reproduce
the behavior.

Start here
----------

.. dropdown:: Initial diagnostic checklist
   :animate: fade-in-slide-down
   :chevron: right-down

   Before changing physical models or numerical settings:

   #. Confirm the current MATLAB working directory.
   #. Confirm that MATLAB locates the intended OpenSTREAM installation.
   #. Confirm that the expected Python environment is active.
   #. Confirm that CoolProp can be imported.
   #. Confirm that all input files and identifiers are correct.
   #. Review the complete error message and calculation log.
   #. Confirm that generated files are written to the intended location.
   #. Check whether the problem is reproducible using an unmodified tutorial
      or sample case.
   #. Record the OpenSTREAM version, release, or Git commit.

   Useful commands include:

   .. code-block:: matlab

      pwd
      path
      which Inputs.InputSet
      which Solvers.Mixture.MixtureSolver
      version
      pyenv
      py.sys.version
      py.CoolProp.CoolProp.get_global_param_string('version')

   When using a development revision, record the Git commit:

   .. code-block:: bash

      git rev-parse HEAD
      git describe --tags --always --dirty

   The ``dirty`` suffix indicates that the working tree contains local
   changes that are not part of the identified commit.

Installation and environment
----------------------------

.. dropdown:: MATLAB cannot locate OpenSTREAM
   :animate: fade-in-slide-down
   :chevron: right-down

   Add the OpenSTREAM repository root to the MATLAB path:

   .. code-block:: matlab

      addpath('<path-to-openstream>')

   Verify the resolved location:

   .. code-block:: matlab

      which Inputs.InputSet
      which Solvers.Mixture.MixtureSolver

   The returned paths should refer to the intended OpenSTREAM working copy.
   If another copy is found, remove obsolete repository paths, add the
   intended root, run ``rehash``, and restart MATLAB if cached class
   definitions remain.

.. dropdown:: MATLAB cannot locate OpenSTREAM-database
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM-database is maintained separately. Add both repository roots:

   .. code-block:: matlab

      addpath('<path-to-openstream>')
      addpath('<path-to-openstream-database>')

   Verify the generic and dataset-specific classes:

   .. code-block:: matlab

      which Dataset
      which Wurtz1978.Wurtz1978

   A dataset package should locate its source file using
   ``getSourceFilePath`` rather than relying on the current MATLAB working
   directory.

.. dropdown:: Python cannot be loaded
   :animate: fade-in-slide-down
   :chevron: right-down

   Inspect the Python environment selected by MATLAB:

   .. code-block:: matlab

      pyenv
      py.sys.version

   If the selected environment is incorrect, review the installation
   guidance and MATLAB documentation for ``pyenv``. Restart MATLAB after
   changing the Python environment.

.. dropdown:: CoolProp cannot be imported
   :animate: fade-in-slide-down
   :chevron: right-down

   Test the import and display the version:

   .. code-block:: matlab

      py.importlib.import_module('CoolProp');
      py.CoolProp.CoolProp.get_global_param_string('version')

   If the import fails, confirm that CoolProp is installed in the Python
   environment selected by MATLAB, restart MATLAB, and run the OpenSTREAM
   environment tests.

.. dropdown:: Environment tests fail
   :animate: fade-in-slide-down
   :chevron: right-down

   Run the complete available test suite from the ``tests`` folder:

   .. code-block:: matlab

      runOpenSTREAMTests

   Review the reported MATLAB, Python, and CoolProp versions. Compare the
   active environment with the configurations documented for the selected
   OpenSTREAM release. A configuration absent from the tested matrix should
   be treated as untested rather than automatically incompatible.

Inputs and generated files
--------------------------

.. dropdown:: An input file cannot be read
   :animate: fade-in-slide-down
   :chevron: right-down

   Confirm that the complete paths exist:

   .. code-block:: matlab

      isfile(modelFilePath)
      isfile(optionsFilePath)
      isfile(geometryFilePath)
      isfile(bcFilePath)

   Review:

   - File spelling and capitalization.
   - File extensions.
   - Access permissions.
   - Network-drive availability.
   - Whether the file is empty or incomplete.
   - Whether the file belongs to the intended source revision.

   Use ``fullfile`` and explicit repository or project roots instead of
   relying on the current working directory.

.. dropdown:: An input identifier cannot be found
   :animate: fade-in-slide-down
   :chevron: right-down

   Confirm that each selected identifier exists in its corresponding file:

   - Model file and model identifier.
   - Numerical-option file and option identifier.
   - Geometry file and geometry identifier.
   - Boundary-condition file and case identifier.

   Confirm that source code, documentation, tutorials, and input files
   belong to compatible OpenSTREAM revisions.

.. dropdown:: OpenSTREAM reports inconsistent or missing inputs
   :animate: fade-in-slide-down
   :chevron: right-down

   Review the generated or maintained inputs before changing the solver.
   Confirm that:

   - Required geometry quantities are present.
   - Boundary conditions use SI units.
   - Absolute temperatures use kelvin.
   - Wall meshes and wall-power distributions have compatible lengths.
   - The wall-mesh intervals are consistent with the modeled length.
   - Selected models are valid identifiers.
   - Numerical options contain valid values.
   - Multi-wall inputs contain consistent information for each wall.

   When using OpenSTREAM-database, also review the selected dataset record
   and the generated input files.

.. dropdown:: A session directory already exists
   :animate: fade-in-slide-down
   :chevron: right-down

   The ``overwriteSessionFiles`` setting controls whether existing session
   files can be replaced:

   .. code-block:: matlab

      inputSetOpts = { ...
          'overwriteSessionFiles',true, ...
          'LOGMODE','BOTH'};

   Use overwriting only when existing output can be replaced safely. If
   previous results must be retained:

   - Select a different session location.
   - Use a different session identifier.
   - Archive the existing session before rerunning.
   - Confirm that another MATLAB process is not using the directory.

   For details, see the :doc:`generated-files guide <generated_files>`.

.. dropdown:: OpenSTREAM reports that a directory was removed
   :animate: fade-in-slide-down
   :chevron: right-down

   When ``overwriteSessionFiles`` is enabled, OpenSTREAM can remove an
   existing session directory before creating the new session. This
   confirms replacement of previous output and does not by itself indicate
   solver failure.

.. dropdown:: Generated files appear in an unexpected folder
   :animate: fade-in-slide-down
   :chevron: right-down

   Inspect:

   - The current working directory.
   - ``sessionParentDir``.
   - Paths supplied to ``Inputs.InputSet``.
   - Paths generated by OpenSTREAM-database.
   - Any use of relative paths.

   Use explicit paths built with ``fullfile``.

   Lightweight OpenSTREAM-database workflows should define an appropriate
   location for generated inputs and results so output is not created
   unexpectedly in the repository root.

Solver execution and convergence
--------------------------------

.. dropdown:: The mixture solver does not converge
   :animate: fade-in-slide-down
   :chevron: right-down

   Determine whether the difficulty concerns point iterations, pseudo-time
   convergence, a physical transient, thermophysical properties, an input
   discontinuity, or a model selection.

   Identify the controlling axial location and variable, and whether the
   error decreases, oscillates, or diverges. Possible diagnostic studies
   include:

   - Reducing the pseudo-time step.
   - Refining the axial mesh.
   - Applying targeted under-relaxation.
   - Reviewing thermophysical-property states.
   - Simplifying the model configuration.
   - Comparing with a converged tutorial case.
   - Reviewing boundary conditions and units.

   Increasing the maximum iteration count is useful only when the residual
   is decreasing consistently.

.. dropdown:: The annular-flow solver fails at its first active node
   :animate: fade-in-slide-down
   :chevron: right-down

   The ThreeField and FourField equations are initialized at the modeled
   onset of annular flow using the upstream mixture solution. Difficulties
   can be associated with onset prediction, initial field fractions and
   velocities, small field mass flow rates, strong transfer terms, or an
   abrupt transition between formulations.

   Identify the variable controlling the iterations before changing
   settings. Apply under-relaxation only to the affected field. For
   example, base-film velocity under-relaxation is controlled by
   ``RELAXUB`` in the FourField workflow.

   Changes to initial field fractions alter the physical initialization
   and should be treated as sensitivity studies, not solely numerical
   corrections.

.. dropdown:: The solution converges only with extreme relaxation
   :animate: fade-in-slide-down
   :chevron: right-down

   Very small relaxation factors can make updates appear converged.

   - Inspect actual residuals and variable changes.
   - Compare with less restrictive relaxation.
   - Tighten convergence criteria where appropriate.
   - Verify conservation and physical consistency.
   - Review mesh and time-step sensitivity.

.. dropdown:: The calculated solution contains NaN or Inf
   :animate: fade-in-slide-down
   :chevron: right-down

   Identify the first location and variable where the invalid value
   appears. Review:

   - Thermophysical-property calls.
   - Division by zero or very small quantities.
   - Missing input or experimental values.
   - Invalid interpolation ranges.
   - Negative or nonphysical state quantities.
   - Field initialization near a flow-regime transition.
   - Geometry and power inputs.
   - The log output preceding the first invalid value.

   Do not replace invalid values silently. Missing OpenSTREAM-database
   values must not be interpreted as zero unless zero is the reported
   value.

.. dropdown:: The steady-state result changes with pseudo-time settings
   :animate: fade-in-slide-down
   :chevron: right-down

   Confirm that each calculation reaches the stated convergence criteria.
   Then:

   - Compare conservation residuals.
   - Compare final axial distributions.
   - Reduce the pseudo-time step.
   - Tighten convergence criteria.
   - Refine the axial mesh.
   - Review transition and initialization behavior.

   Document settings required for reported results.

.. dropdown:: A transient result changes with the time step
   :animate: fade-in-slide-down
   :chevron: right-down

   Perform a physical-time-step sensitivity study. Compare:

   - The timing of principal events.
   - Peak and minimum quantities.
   - Integrated quantities.
   - Conservation behavior.
   - Spatial distributions at equivalent physical times.

   Numerical stability does not imply time-step independence.

.. dropdown:: A result differs from a tutorial or reference
   :animate: fade-in-slide-down
   :chevron: right-down

   Confirm that the calculations use the same:

   - OpenSTREAM and OpenSTREAM-database release or commit.
   - MATLAB, Python, and CoolProp versions.
   - Inputs and identifiers.
   - Solver and model selections.
   - Nondefault parameters and numerical options.
   - Mesh, time step, and convergence criteria.
   - Post-processing procedure.

   Review release notes and understand the difference before replacing a
   numerical reference.

Results and post-processing
---------------------------

.. dropdown:: A saved solver object cannot be loaded
   :animate: fade-in-slide-down
   :chevron: right-down

   Review:

   - The OpenSTREAM revision that created the object.
   - The current OpenSTREAM revision.
   - MATLAB version differences.
   - Renamed or removed properties.
   - Enumeration changes.
   - Python or CoolProp object references.
   - Changes to result structures.

   Where possible, regenerate the calculation from the original inputs and
   documented workflow. Saved objects should not be the only
   reproducibility record.

.. dropdown:: Plots are empty or incomplete
   :animate: fade-in-slide-down
   :chevron: right-down

   Confirm that:

   - The calculation completed.
   - The requested result fields exist.
   - The requested axial or time indices are valid.
   - The plotting method supports the selected solver.
   - The selected variables contain finite values.
   - The relevant field is active over the plotted domain.
   - Filtering has not removed all result points.

   Annular-flow fields may be active only downstream of the modeled onset
   of annular flow.

.. dropdown:: Measured and calculated data do not align
   :animate: fade-in-slide-down
   :chevron: right-down

   Review:

   - Coordinate definitions.
   - Measurement elevations.
   - Cell-center versus boundary locations.
   - Axial interpolation.
   - Time alignment.
   - Units.
   - Whether the measurement is local, averaged, or integrated.
   - Whether the experimental quantity is measured directly or derived.
   - Whether the calculated quantity has the same physical definition.

   Document all alignment and processing. Do not modify source data solely
   to improve visual agreement.

.. dropdown:: Interactive figures are missing from exported documentation
   :animate: fade-in-slide-down
   :chevron: right-down

   Live Script HTML and PDF exports may not preserve all interactive Live
   Editor behavior. The ``.mlx`` file remains the authoritative executable
   version; static exports retain supported text, code, output, and
   figures.

Testing and documentation
-------------------------

.. dropdown:: The automated tests fail
   :animate: fade-in-slide-down
   :chevron: right-down

   Run:

   .. code-block:: matlab

      runOpenSTREAMTests

   Review:

   - The first failing test.
   - The complete diagnostic output.
   - The active MATLAB, Python, and CoolProp versions.
   - Local source modifications.
   - Changes to input files.
   - Differences from approved numerical references.
   - Convergence status.
   - Generated output and session locations.

   Do not update a numerical reference solely to make a test pass.
   Determine whether the difference results from a corrected defect,
   intentional model or numerical change, environment difference,
   regression, insufficient convergence, or changed default.

.. dropdown:: Tests pass locally but fail in continuous integration
   :animate: fade-in-slide-down
   :chevron: right-down

   Compare:

   - MATLAB release.
   - Python and CoolProp versions.
   - Operating system and environment variables.
   - File-path assumptions and case sensitivity.
   - Availability of generated or local files.
   - Repository cleanliness.

   Continuous integration starts from a clean checkout. Local tests can
   depend unintentionally on ignored files, generated output, local
   dependencies, absolute paths, cached classes, or files from another
   repository.

.. dropdown:: The documentation build fails
   :animate: fade-in-slide-down
   :chevron: right-down

   Review the first Sphinx warning or error. Common causes include:

   - Invalid reStructuredText indentation.
   - Missing blank lines before or after directives.
   - Incorrect heading underlines.
   - Invalid ``toctree`` entries.
   - Broken internal cross-references.
   - Missing files or BibTeX entries.
   - Duplicate labels.
   - Copied HTML markup.
   - Malformed tables.

   Use standard reStructuredText links:

   .. code-block:: rst

      `OpenSTREAM repository
      <https://github.com/OpenSTREAM-solvers/openstream>`_

   Do not paste interface-generated ``<a href=...>`` elements into RST
   files.

.. dropdown:: A citation does not render
   :animate: fade-in-slide-down
   :chevron: right-down

   Confirm that ``sphinxcontrib-bibtex`` is enabled, the correct BibTeX
   file is listed in ``conf.py``, the citation key exists, and a
   bibliography directive is available.

   .. code-block:: rst

      :cite:p:`CitationKey`

      .. bibliography::
         :filter: False

         CitationKey

Git and repository files
------------------------

.. dropdown:: An expected file is missing after switching Git branches
   :animate: fade-in-slide-down
   :chevron: right-down

   Git does not preserve an empty directory unless it contains a tracked
   file, such as ``README.md`` or ``.gitkeep``.

   Inspect local files before switching:

   .. code-block:: bash

      git status
      git status --ignored --short

   Stash tracked and untracked files with:

   .. code-block:: bash

      git stash push -u -m "temporary work before branch switch"

   Include ignored sandbox files with:

   .. code-block:: bash

      git stash push -a -m "temporary work before branch switch"

   Use ``git stash apply`` and verify restoration before
   ``git stash drop``.

.. dropdown:: A file appears remotely but is not tracked locally
   :animate: fade-in-slide-down
   :chevron: right-down

   Confirm the current branch and update remote references:

   .. code-block:: bash

      git branch --show-current
      git fetch origin
      git status -sb

   Inspect local and remote trees:

   .. code-block:: bash

      git ls-tree -r HEAD --name-only
      git ls-tree -r origin/<branch> --name-only

   If a file should remain locally but no longer be tracked, use
   ``git rm --cached <path>``, add the path to ``.gitignore``, and commit
   the index change. ``.gitignore`` does not stop tracking a committed
   file.

Reporting unresolved problems
-----------------------------

.. dropdown:: Preparing an issue report
   :animate: fade-in-slide-down
   :chevron: right-down

   If the problem remains unresolved, include:

   - A concise problem description.
   - Expected and actual behavior.
   - Reproduction steps.
   - OpenSTREAM and OpenSTREAM-database revisions.
   - MATLAB, Python, and CoolProp versions.
   - Operating system and solver framework.
   - Inputs or a minimal reproducible case.
   - Nondefault models and numerical options.
   - Final solver state and relevant log excerpts.
   - Local source modifications.
   - Troubleshooting steps already attempted.

   Remove proprietary, confidential, or restricted information before
   attaching files to a public issue.

   Report reproducible defects through the
   `OpenSTREAM issue tracker
   <https://github.com/OpenSTREAM-solvers/openstream/issues>`_.

Further information
-------------------

For more detailed guidance, consult:

- The :doc:`getting-started guide <../Usage/gettingStarted>`.
- The :doc:`generated-files guide <generated_files>`.
- The :doc:`release numbering and versioning guide <../Usage/versioning>`.
- The :doc:`intended scope and limitations
  <../Usage/scope_and_limitations>`.
- The numerical convergence tutorial.
- The :doc:`testing <testing>` documentation.
- The :doc:`OpenSTREAM FAQ <../Community/faq>`.
- The :doc:`support page <../Community/support>`.
- The :doc:`OpenSTREAM-database <../Applications/database>` documentation.
