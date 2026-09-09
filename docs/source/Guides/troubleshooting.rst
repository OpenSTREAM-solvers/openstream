Troubleshooting
===============

This page provides initial diagnostic guidance for common OpenSTREAM setup,
execution, convergence, output, plotting, testing, and documentation
problems.

OpenSTREAM calculations depend on several interacting components:

- The OpenSTREAM source revision.
- MATLAB and its active search path.
- The MATLAB-Python interface.
- Python and CoolProp.
- OpenSTREAM input files and selected identifiers.
- The selected solver framework and physical models.
- Numerical settings and convergence criteria.
- Session-directory and file-system permissions.

When investigating a problem, record the relevant error message, software
versions, input selections, solver state, and steps required to reproduce
the behavior.

Initial diagnostic checklist
----------------------------

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

The ``dirty`` suffix indicates that the working tree contains local changes
that are not part of the identified commit.

MATLAB cannot locate OpenSTREAM
-------------------------------

Typical symptoms include:

- MATLAB reports an undefined package, class, function, or variable.
- ``Inputs.InputSet`` cannot be found.
- A solver class cannot be constructed.
- MATLAB resolves a class from an unintended repository copy.

Add the OpenSTREAM repository root to the MATLAB path:

.. code-block:: matlab

   addpath('<path-to-openstream>')

Then verify the resolved location:

.. code-block:: matlab

   which Inputs.InputSet
   which Solvers.Mixture.MixtureSolver

The returned paths should refer to the intended OpenSTREAM working copy.

If an unexpected copy is found:

#. Inspect the MATLAB search path.
#. Remove obsolete or duplicate repository paths.
#. Add the intended repository root.
#. Run ``rehash`` if recently added or renamed files are not detected.
#. Restart MATLAB if cached class definitions remain inconsistent with the
   source files.

Multiple OpenSTREAM copies on the MATLAB path can produce confusing
behavior when classes from different revisions are loaded together.

MATLAB cannot locate OpenSTREAM-database
---------------------------------------

OpenSTREAM-database is maintained as a separate repository. Both
repository roots must be available on the MATLAB path.

.. code-block:: matlab

   addpath('<path-to-openstream>')
   addpath('<path-to-openstream-database>')

Verify the generic dataset class:

.. code-block:: matlab

   which Dataset

Verify a dataset-specific class using its package-qualified name:

.. code-block:: matlab

   which Wurtz1978.Wurtz1978

The returned locations should refer to the intended
OpenSTREAM-database working copy.

A dataset package should locate its authoritative source file using
``getSourceFilePath`` rather than relying on the current MATLAB working
directory.

Python cannot be loaded
-----------------------

Inspect the Python environment selected by MATLAB:

.. code-block:: matlab

   pyenv

Display the active Python version:

.. code-block:: matlab

   py.sys.version

If the selected Python environment is not the intended environment, review
the OpenSTREAM installation instructions and the MATLAB documentation for
configuring ``pyenv``.

After changing the Python environment, MATLAB may need to be restarted
before the new environment is used consistently.

Record both the Python executable and version when reporting an
environment problem.

CoolProp cannot be imported
---------------------------

Test whether MATLAB can import CoolProp:

.. code-block:: matlab

   py.importlib.import_module('CoolProp');

Display the active CoolProp version:

.. code-block:: matlab

   py.CoolProp.CoolProp.get_global_param_string('version')

If the import fails:

- Confirm that CoolProp is installed in the Python environment selected by
  MATLAB.
- Confirm that the installation uses a Python version compatible with the
  selected OpenSTREAM environment.
- Confirm that MATLAB is not connected to another Python environment.
- Restart MATLAB after changing the Python installation.
- Run the OpenSTREAM environment tests.

A working Python installation does not by itself confirm that CoolProp is
installed in the same environment.

Environment tests fail
----------------------

Run the complete available test suite from the ``tests`` folder:

.. code-block:: matlab

   runOpenSTREAMTests

If an environment test fails:

#. Review the reported MATLAB, Python, and CoolProp versions.
#. Confirm that MATLAB uses the intended Python executable.
#. Test the failing dependency directly.
#. Compare the active environment with the configurations documented for
   the selected OpenSTREAM release.
#. Review the continuous-integration configuration for tested
   combinations.

A configuration that is not included in the tested environment matrix
should be treated as untested rather than automatically incompatible.

An input file cannot be read
----------------------------

Confirm that the complete file path exists:

.. code-block:: matlab

   isfile(modelFilePath)
   isfile(optionsFilePath)
   isfile(geometryFilePath)
   isfile(bcFilePath)

Avoid relying on the current working directory. Construct paths using
``fullfile`` and known repository or project roots:

.. code-block:: matlab

   modelFilePath = fullfile( ...
       openstreamPath, ...
       'inputs', ...
       'models.inp');

Review:

- File spelling and capitalization.
- File extensions.
- Access permissions.
- Network-drive availability.
- Whether the file is empty or incomplete.
- Whether the path refers to a file from another branch or repository
  copy.

If the file was generated by another workflow, review that workflow for
errors before modifying the OpenSTREAM reader.

An input identifier cannot be found
-----------------------------------

OpenSTREAM input files can contain several named input sets. Confirm that
the selected identifier exists in the corresponding file.

Review each file and identifier independently:

- Model file and model identifier.
- Numerical-option file and option identifier.
- Geometry file and geometry identifier.
- Boundary-condition file and case identifier.

An identifier from one file revision may not exist in another revision.
Confirm that the source code, documentation, tutorials, and input files
belong to compatible OpenSTREAM revisions.

OpenSTREAM reports inconsistent or missing inputs
-------------------------------------------------

Review the generated or maintained input files before changing the solver.

Confirm that:

- Required geometry quantities are present.
- Boundary conditions use SI units.
- Absolute temperatures use kelvin.
- Wall meshes and wall-power distributions have compatible lengths.
- The sum of the wall-mesh intervals is consistent with the modeled
  length.
- Selected models are valid identifiers.
- Numerical options contain valid values.
- Multi-wall inputs contain consistent information for each wall.

When using OpenSTREAM-database, also review the selected dataset record and
the generated input files.

A source-data implementation can load successfully while still containing
a physically inconsistent geometry, power, unit conversion, or boundary
condition.

A session directory already exists
----------------------------------

An existing session can prevent a new calculation from using the same
location.

The ``overwriteSessionFiles`` setting controls whether existing session
files can be replaced:

.. code-block:: matlab

   inputSetOpts = { ...
       'overwriteSessionFiles',true, ...
       'LOGMODE','BOTH'};

Use overwriting only when the existing output can be replaced safely.

If previous results must be retained: