OpenSTREAM-database
===================

**OpenSTREAM-database** provides an application and validation environment for
**OpenSTREAM**, enabling users to configure, run, and evaluate OpenSTREAM
solvers using publicly available experimental datasets.

OpenSTREAM-database complements the core OpenSTREAM repository:

- **OpenSTREAM** provides the solver frameworks, physical and closure
  models, numerical methods, input handling, visualization capabilities,
  tutorials, documentation, and core automated tests.

- **OpenSTREAM-database** provides dataset-specific implementations,
  application cases, calculated-versus-measured comparisons, and
  validation workflows.

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

Available datasets
------------------

OpenSTREAM-database currently contains implementations based on the
following publicly available datasets:

- Adamsson et al. (2006).
- Bennett et al. (1967).
- Groeneveld et al. (2019).
- Sawai et al. (1989).
- Wurtz (1978).

Each dataset is implemented as a MATLAB package containing source data, a
dataset-specific class, plotting functionality, and supporting
documentation.

The original publications remain the authoritative sources for the
experimental facilities, instrumentation, test conditions, measurement
uncertainties, and interpretation of the data. Consult the README file
within each dataset package before using the corresponding cases.

Repository organization
-----------------------

The main repository structure is:

.. code-block:: text

   openstream-database/
   ├── +Adamsson2006/
   ├── +Bennett1967/
   ├── +Groeneveld2019/
   ├── +Sawai1989/
   ├── +Wurtz1978/
   ├── @Dataset/
   ├── projects/
   ├── README.md
   └── functionSignatures.json

Dataset packages
~~~~~~~~~~~~~~~~

Each dataset package generally follows this organization:

.. code-block:: text

   +DatasetName/
   ├── +src/
   │   └── DatasetName.xml
   ├── @DatasetName/
   │   ├── DatasetName.m
   │   └── plotResults.m
   └── README.md

The package components have the following roles:

``+src``
   Contains the source-data representation used by the dataset
   implementation. All numerical data in these files are stored in SI
   units.

``@DatasetName``
   Contains the dataset-specific class and associated methods.

``plotResults.m``
   Provides dataset-specific visualization and comparison functionality.

``README.md``
   Documents the dataset, original experimental source, implementation,
   and information required to interpret and use the available cases.

Common dataset functionality
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``@Dataset`` folder contains functionality shared by the
dataset-specific implementations:

.. code-block:: text

   @Dataset/
   ├── Dataset.m
   ├── makeInputFiles.m
   └── runCase.m

The common dataset interface supports operations such as generating
OpenSTREAM input files and running selected application cases. The
available options and calculated quantities depend on the selected dataset
and solver configuration.

Units
-----

OpenSTREAM uses SI units for all inputs, calculated quantities, and stored
results.

OpenSTREAM-database follows the same convention. All numerical data stored
in the dataset source files under the ``+src`` directories are expressed
in SI units, including data that were reported using other systems of units
in the original experimental publications.

Dataset-specific classes therefore use SI quantities when generating
OpenSTREAM inputs, running application cases, and comparing calculated and
experimental results.

The original publications should nevertheless be consulted to confirm the
reported quantities, measurement definitions, original units, and
experimental uncertainties. Any conversion from the units reported in an
original source to the SI values stored by OpenSTREAM-database should be
documented in the corresponding dataset README or implementation.

Application projects
--------------------

The ``projects`` folder contains MATLAB scripts and Live Scripts that
demonstrate dataset-specific application and validation workflows:

.. code-block:: text

   projects/
   ├── Adamsson.m
   ├── Bennett.mlx
   ├── Groeneveld.m
   ├── NURETH21.m
   ├── Sawai.m
   └── Wurtz.m

As project workflows are developed, reviewed, and exported, their HTML
versions are made available on the
:doc:`application projects <projects>` page.

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
that both repository roots are made available on the MATLAB path.

OpenSTREAM-database does not use OpenSTREAM as a Git submodule.

MATLAB setup
------------

Add both repository roots to the MATLAB path:

.. code-block:: matlab

   addpath('<path-to-openstream>')
   addpath('<path-to-openstream-database>')

For example, when MATLAB is started from a parent folder containing both
repositories:

.. code-block:: matlab

   addpath(fullfile(pwd,'openstream'))
   addpath(fullfile(pwd,'openstream-database'))

Verify that MATLAB can locate functionality from both repositories:

.. code-block:: matlab

   which Inputs.InputSet
   which Dataset

The returned paths should refer to the intended OpenSTREAM and
OpenSTREAM-database working copies.

The OpenSTREAM-database implementation should rely on the required
OpenSTREAM classes being available on the MATLAB path rather than on a
fixed relative directory arrangement.

Typical workflow
----------------

A typical application workflow consists of:

#. Constructing a dataset-specific object.
#. Selecting one or more experimental cases.
#. Selecting an OpenSTREAM solver and model configuration.
#. Generating the corresponding OpenSTREAM input files.
#. Running the selected cases.
#. Extracting calculated quantities.
#. Comparing calculated and measured results.
#. Visualizing and evaluating the comparison.

The exact workflow depends on the selected dataset. Consult the
dataset-specific README and corresponding project file before running an
application.

Generated files
---------------

OpenSTREAM-database may generate package directories and output folders
containing:

- OpenSTREAM input files.
- Solver results.
- Logs and session files.
- Saved solver objects.
- Processed comparison results.
- Figures and other post-processing outputs.

Generated artifacts are excluded from version control through the
repository ``.gitignore`` rules.

Source datasets, MATLAB classes, project source files, and documentation
remain version-controlled.

Data provenance and citation
----------------------------

The datasets implemented in OpenSTREAM-database are derived from publicly
available experimental sources. All numerical data stored under the
OpenSTREAM-database ``+src`` directories use SI units, consistently with
the OpenSTREAM input and result conventions.

When using a dataset:

- Consult and cite the original experimental publication.
- Confirm the experimental conditions, measurement definitions, and units
  reported in the original publication.
- Review the documented measurement uncertainties.
- Review any conversion from the units reported in the original
  publication to the SI values stored by OpenSTREAM-database.
- Identify any transcription, processing, interpolation, filtering, or
  assumptions introduced by the implementation.
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

Changes to dataset implementations and application workflows should be
verified using reproducible checks appropriate to the modification. These
checks should include, where applicable:

- Confirming that source-data files can be loaded correctly.
- Confirming that all numerical source data are stored in SI units.
- Reviewing unit conversions against the original experimental sources.
- Verifying that the intended experimental cases can be selected.
- Reviewing generated OpenSTREAM input files.
- Running the affected application cases.
- Confirming that the selected OpenSTREAM calculations complete as
  expected.
- Comparing calculated and measured quantities.
- Reviewing generated figures and post-processing results.
- Confirming that existing application workflows are not adversely
  affected.

Automated testing is a planned improvement for OpenSTREAM-database.
Potential future tests may cover source-data parsing, unit conversion,
dataset metadata, case selection, input generation, plotting and
comparison methods, application workflows, and numerical regression.

Development status
------------------

OpenSTREAM-database and its application workflows are under active
development.

Additional datasets, solver configurations, comparison quantities,
validation metrics, documentation, application projects, and verification
capabilities may be added as the repository evolves.

Users should review the dataset-specific documentation and repository
history when reproducing earlier calculations.

Contributing
------------

Contributions of new datasets, application cases, validation methods,
documentation, project workflows, and verification capabilities are
welcome.

Before contributing, review the
:doc:`OpenSTREAM-database contribution guidelines <contributing>`,
including the requirements for:

- Dataset organization.
- Source-data provenance.
- SI units and unit conversion.
- Measurement uncertainty.
- Reproducibility.
- Documentation.
- Verification of affected application workflows.