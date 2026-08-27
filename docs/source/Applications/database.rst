OpenSTREAM-database
===================

OpenSTREAM-database provides an application and validation environment for
**OpenSTREAM**, enabling users to configure, run, and evaluate OpenSTREAM
solvers using publicly available experimental datasets.

OpenSTREAM-database complements the core OpenSTREAM repository:

- **OpenSTREAM** provides the solver frameworks, physical and closure
  models, numerical methods, input handling, visualization capabilities,
  tutorials, documentation, and core automated tests.

- **OpenSTREAM-database** provides dataset implementations, application
  workflows, calculated-versus-measured comparisons, and an environment
  for model assessment and validation.

The two repositories are maintained separately. OpenSTREAM is not included
as a Git submodule of OpenSTREAM-database. A compatible OpenSTREAM working
copy must be installed independently and made available on the MATLAB path.

Purpose
-------

OpenSTREAM-database supports:

- Application of OpenSTREAM solvers to experimental cases.
- Reproducible generation of OpenSTREAM input files from dataset
  definitions.
- Execution of individual cases or selected groups of cases.
- Comparison of calculated and measured quantities.
- Development and assessment of physical and closure models.
- Numerical sensitivity and uncertainty studies.
- Documentation of dataset provenance, assumptions, and processing.
- Application- and validation-oriented research and solver development.

Separating the application datasets from the core solver repository allows
OpenSTREAM and OpenSTREAM-database to evolve independently while retaining
a common application interface.

Repository organization
-----------------------

The principal repository structure is:

.. code-block:: text

   openstream-database/
   ├── +DatasetName/
   ├── @Dataset/
   ├── projects/
   ├── README.md
   └── functionSignatures.json

Each dataset is implemented as a MATLAB package that generally contains:

.. code-block:: text

   +DatasetName/
   ├── +src/
   ├── @DatasetName/
   │   ├── DatasetName.m
   │   └── plotResults.m
   └── README.md

The package components have the following roles:

``+src``
   Contains the structured experimental data and the information required
   to define OpenSTREAM cases. XML and JSON source files are supported.

``@DatasetName``
   Contains the dataset-specific class and associated methods.

``plotResults.m``
   Provides dataset-specific visualization and
   calculated-versus-measured comparison functionality.

``README.md``
   Documents the original experimental source, implemented data, units,
   uncertainties, assumptions, and supported workflows.

The generic ``Dataset`` class provides functionality shared by the
individual dataset implementations, including source-data handling,
OpenSTREAM input generation, and case execution.

Dataset source files
--------------------

Experimental cases and associated information are stored in structured XML
or JSON files under each dataset package's ``+src`` directory.

Each case can contain two categories of information:

#. **OpenSTREAM case-definition information**, whose field names follow a
   strict naming convention so that the generic ``Dataset`` functionality
   can identify the boundary conditions and other information passed to
   OpenSTREAM.

#. **Dataset-specific information**, whose field names and contents can be
   defined according to the needs of the dataset implementation.

Dataset-specific information can include experimental measurements,
metadata, classifications, uncertainties, derived quantities, and other
information used by the dataset class or application workflows. For
example, a dataset-specific ``plotResults`` method can use these fields to
construct calculated-versus-measured comparisons.

The reserved OpenSTREAM field names are case-sensitive and must use the
spelling expected by the input-generation implementation. Other fields can
be added freely, provided that they do not conflict with the reserved
names and are interpreted consistently by the corresponding dataset class.

XML and JSON are alternative representations of the same logical dataset
information. Dataset classes should expose equivalent information
regardless of the source-file format.

Scalar quantities are stored as individual values. Array quantities are
represented by repeated XML elements or JSON arrays. Related arrays should
have compatible lengths and ordering.

Detailed source-file conventions should be documented in the corresponding
dataset README and class implementation.

Units
-----

OpenSTREAM uses SI units for all inputs, calculated quantities, and stored
results.

OpenSTREAM-database follows the same convention. All numerical data stored
in dataset source files under the ``+src`` directories are expressed in SI
units, including data converted from other unit systems used in the
original experimental sources.

The original publications should be consulted for the reported quantities,
measurement definitions, original units, and experimental uncertainties.
Any conversion to SI units should be documented in the corresponding
dataset README or implementation.

Application projects
--------------------

The ``projects`` folder contains MATLAB scripts and Live Scripts that
demonstrate dataset-specific application and validation workflows.

A typical project selects experimental cases, generates the corresponding
OpenSTREAM inputs, runs selected solver and model configurations, extracts
calculated quantities, and compares the results with experimental
measurements.

As Live Script projects are developed, reviewed, and documented, exported
HTML versions may be included in the OpenSTREAM Applications documentation.

Requirements
------------

OpenSTREAM-database requires:

- A compatible MATLAB installation.
- A working OpenSTREAM installation.
- The Python and CoolProp environment required by OpenSTREAM.
- Access to the OpenSTREAM-database repository.

OpenSTREAM is maintained as a separate repository and must be installed
independently. Consult the
`OpenSTREAM installation guide
<https://openstream-solvers.github.io/openstream/Usage/gettingStarted.html>`_
for the current MATLAB, Python, CoolProp, and installation requirements.

Installation
------------

Clone OpenSTREAM and OpenSTREAM-database as separate repositories.

A convenient local organization is:

.. code-block:: text

   projects/
   ├── openstream/
   └── openstream-database/

The repositories do not need to share the same parent directory, provided
that both repository roots are available on the MATLAB path.

MATLAB setup
------------

Add both repository roots to the MATLAB path:

.. code-block:: matlab

   addpath('<path-to-openstream>')
   addpath('<path-to-openstream-database>')

Verify that MATLAB can locate functionality from both repositories:

.. code-block:: matlab

   which Inputs.InputSet
   which Dataset

The returned paths should refer to the intended OpenSTREAM and
OpenSTREAM-database working copies.

Typical workflow
----------------

A typical application workflow consists of:

#. Constructing a dataset-specific object.
#. Reading the corresponding XML or JSON source file.
#. Selecting one or more experimental cases.
#. Selecting an OpenSTREAM solver and model configuration.
#. Generating the corresponding OpenSTREAM input files.
#. Running the selected calculations.
#. Extracting calculated quantities.
#. Comparing calculated and measured results.
#. Visualizing and evaluating the comparison.

The exact workflow depends on the selected dataset. Consult the
corresponding dataset README and project file before running an
application.

Generated files
---------------

OpenSTREAM-database may generate package directories and output folders
containing OpenSTREAM input files, solver results, logs, saved solver
objects, processed comparisons, figures, and other post-processing
outputs.

Generated artifacts are excluded from version control through the
repository ``.gitignore`` rules. Source-data files, MATLAB classes, project
source files, and documentation remain version-controlled.

Data provenance and citation
----------------------------

The datasets implemented in OpenSTREAM-database are derived from publicly
available experimental sources.

When using a dataset:

- Consult and cite the original experimental publication.
- Review the experimental conditions, measurement definitions, original
  units, and reported uncertainties.
- Review any conversion, transcription, processing, interpolation,
  filtering, reconstruction, or assumptions introduced by the
  implementation.
- Cite OpenSTREAM and OpenSTREAM-database as appropriate.

Use of an OpenSTREAM-database implementation does not replace citation of
the original experimental source.

Validation and interpretation
-----------------------------

Inclusion of a dataset or application does not imply that every
OpenSTREAM solver, model combination, or calculated quantity has been
comprehensively verified or validated against that dataset.

Users remain responsible for evaluating:

- The applicability and quality of the experimental data.
- The assumptions and validity ranges of the selected models.
- Numerical convergence and discretization sensitivity.
- Experimental, model, parameter, and numerical uncertainty.
- The suitability of the selected comparison quantities and metrics.
- The interpretation of calculated-versus-measured differences.

A favorable comparison for one case, quantity, or model selection should
not be interpreted as general validation outside the conditions examined.

Testing and verification
------------------------

OpenSTREAM-database does not currently include an automated test suite.

Dataset implementations and application workflows should therefore be
verified through documented and reproducible execution of the affected
cases. Detailed verification requirements are provided in the
:doc:`contribution guidelines <contributing>`.

Development of an automated testing and regression framework is a planned
improvement.

Development status
------------------

OpenSTREAM-database and its application workflows are under active
development. Dataset implementations, source-file formats, application
projects, comparison methods, documentation, and verification capabilities
may continue to evolve.

Users should review the dataset-specific documentation and repository
history when reproducing earlier calculations.

Contributing
------------

Contributions of new datasets, corrections, application workflows,
documentation, comparison methods, and verification capabilities are
welcome.

Before contributing, review the
:doc:`OpenSTREAM-database contribution guidelines <contributing>`.