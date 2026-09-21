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
  workflows, calculated-versus-measured comparisons, publication companion
  workflows, and an environment for model assessment and validation.

The two repositories are maintained separately. OpenSTREAM is not included
as a Git submodule of OpenSTREAM-database. A compatible OpenSTREAM working
copy must be installed independently and made available on the MATLAB path.

The OpenSTREAM-database source code, dataset packages, project workflows,
and contribution history are available in the
`OpenSTREAM-database repository
<https://github.com/OpenSTREAM-solvers/openstream-database>`_.

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
- Publication companion workflows illustrating selected calculations,
  figures, and results.
- Application- and validation-oriented research and solver development.

Separating application datasets from the core solver repository allows
OpenSTREAM and OpenSTREAM-database to evolve independently while retaining
a common application interface.

Repository organization
-----------------------

The principal repository structure is:

.. code-block:: text

   openstream-database/
   ├── +DatasetName/
   ├── +Template/
   ├── @Dataset/
   ├── projects/
   ├── sandbox/
   ├── LICENSE
   ├── README.md
   └── functionSignatures.json

Each dataset is implemented as a MATLAB package that generally contains:

.. code-block:: text

   +DatasetName/
   ├── +src/
   │   └── DatasetName.xml
   ├── @DatasetName/
   │   ├── DatasetName.m
   │   └── plotResults.m
   └── README.md

Additional dataset-specific methods may be provided when required, for
example for post-processing or trend analysis.

The package components have the following roles:

``+src``
   Contains the structured experimental data and the information required
   to define OpenSTREAM cases.

``@DatasetName``
   Contains the dataset-specific class and associated methods.

``plotResults.m``
   Provides dataset-specific visualization and
   calculated-versus-measured comparison functionality.

``README.md``
   Documents the original experimental source, implemented data, units,
   uncertainties, assumptions, processing methods, supported workflows,
   and known limitations.

The generic ``Dataset`` class provides functionality shared by the
individual dataset implementations, including source-data handling,
case selection, OpenSTREAM input generation, case execution, convergence
review, and result storage.

The ``+Template`` package provides the recommended starting structure for
new dataset contributions.

The ``projects`` folder contains publication companion workflows and other
reviewed application projects.

The ``sandbox`` folder provides a local workspace for exploratory
OpenSTREAM-database calculations. Temporary sandbox scripts, generated
inputs, results, logs, figures, and saved objects are not maintained as
repository content.

Dataset source files
--------------------

Experimental cases and associated information are normally stored in a
structured XML or JSON file under the dataset package's ``+src``
directory.

XML and JSON are supported source formats. A dataset package should
normally maintain only one authoritative machine-readable source file.
If equivalent XML and JSON representations are both retained, the dataset
README must identify the authoritative source, explain how the alternative
representation is generated, and describe how consistency is verified.

Each case can contain two categories of information:

#. **OpenSTREAM case-definition information**, whose field names follow a
   strict naming convention so that the generic ``Dataset`` functionality
   can identify geometry, boundary conditions, wall heating, and other
   information passed to OpenSTREAM.

#. **Dataset-specific information**, whose field names and contents can be
   defined according to the needs of the dataset implementation.

Dataset-specific information can include experimental measurements,
metadata, classifications, uncertainties, derived quantities, and other
information used by the dataset class or application workflows. For
example, a dataset-specific ``plotResults`` method can use these fields to
construct calculated-versus-measured comparisons.

The reserved OpenSTREAM field names are case-sensitive and must use the
spelling expected by the input-generation implementation. Other fields can
be added freely, provided that they do not conflict with reserved names
and are interpreted consistently by the corresponding dataset class.

Scalar quantities are stored as individual values. Array quantities are
represented by repeated XML elements or JSON arrays. Related arrays must
have compatible lengths, ordering, and physical meaning.

Missing numerical measurements must be represented consistently and must
not be interpreted as zero. The convention used for a dataset should be
documented in its README and handled explicitly by dataset-specific
methods.

Detailed source-file conventions should be documented in the corresponding
dataset README and class implementation.

Lightweight in-memory datasets
------------------------------

OpenSTREAM-database can also be used without an XML or JSON source-data
file.

A case can be defined directly using a one-row MATLAB table and passed to
a lightweight ``Dataset`` object:

.. code-block:: matlab

   data = Dataset( ...
       1, ...
       'isLightWeight',true, ...
       'lightWeightEntryData',entryData);

This in-memory workflow is useful for:

- publication demonstration cases;
- concise examples and tutorials;
- exploratory calculations;
- user-defined cases that do not require a maintained dataset package;
- comparisons of multiple OpenSTREAM solver frameworks using a common
  case definition.

The table must contain the geometry, boundary-condition, wall-heating, and
fluid fields required by the selected OpenSTREAM workflow. Numerical values
must follow the same SI-unit conventions as file-based datasets.

A lightweight case is not a substitute for a maintained dataset package
when experimental provenance, uncertainty, repeated case selection, or
long-term reuse must be documented.

Units
-----

OpenSTREAM uses SI units for all inputs, calculated quantities, and stored
results.

OpenSTREAM-database follows the same convention. All numerical data stored
in dataset source files or supplied through lightweight in-memory records
must use SI units. Absolute temperatures are expressed in kelvin.

Data converted from other unit systems must be checked and documented.
Units may be stated explicitly for individual fields or established through
a clear dataset-wide convention. Units must be stated whenever clarification
is useful, particularly for quantities whose representation could otherwise
be ambiguous.

For example, a field called ``InletSubcooling`` may represent an enthalpy
difference in J/kg rather than a temperature difference. Such conventions
must be stated explicitly in the dataset README.

The original publications should be consulted for the reported quantities,
measurement definitions, original units, and experimental uncertainties.

Data preparation and provenance
-------------------------------

Dataset values may be obtained from publication tables, supplementary data,
public data repositories, or digitized figures.

The dataset README must document the preparation method, including, as
applicable:

- manual transcription from tables;
- character recognition from scanned reports;
- figure digitization;
- unit conversion;
- interpolation or reconstruction;
- corrections applied after review;
- derived quantities added for OpenSTREAM input generation;
- sanity checks and consistency checks.

Relevant checks can include geometry consistency, mass-flow and mass-flux
consistency, power reconstruction, energy balances, array-length checks,
unit checks, and comparison of related experimental cases.

The original publication or public data source remains authoritative.
Machine-readable dataset implementations can contain transcription,
recognition, digitization, conversion, or processing errors even after
review.

Direct measurements must be distinguished from quantities derived during
source-data preparation, calculation, or post-processing.

Application projects
--------------------

The ``projects`` folder contains reviewed MATLAB Live Scripts that
reproduce or illustrate selected calculations and results from OpenSTREAM
publications.

The Live Scripts are the authoritative executable versions. Completed
executions may also be provided as static HTML exports for viewing without
MATLAB.

Available workflows and their scope are described on the
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

.. code-block:: bash

   git clone --recursive https://github.com/OpenSTREAM-solvers/openstream.git
   git clone https://github.com/OpenSTREAM-solvers/openstream-database.git

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

A typical OpenSTREAM-database workflow consists of the following steps:

#. **Construct the dataset object.**

   Construct the dataset-specific object using its package-qualified class
   name. Calling the constructor without a case identifier loads the
   available dataset records:

   .. code-block:: matlab

      alldata = Wurtz1978.Wurtz1978();

   Other dataset packages follow the same pattern:

   .. code-block:: matlab

      alldata = Sawai1989.Sawai1989();
      alldata = Bartolomey.Bartolomey();
      alldata = Becker1983.Becker1983();

   Review the dataset-specific README and constructor documentation before
   selecting and running cases.

#. **Review and select the cases.**

   Inspect the available records through the dataset table:

   .. code-block:: matlab

      alldata.dataset

   Select the records required for the intended application. Dataset fields
   such as ``TestID`` can be used to locate particular cases:

   .. code-block:: matlab

      selectedTestIDs = [101 102];
      selectedIndexes = find(ismember(alldata.dataset.TestID',selectedTestIDs));

   Construct the selected dataset objects:

   .. code-block:: matlab

      for caseIndex = 1:numel(selectedIndexes)
          data(caseIndex) = Wurtz1978.Wurtz1978(selectedIndexes(caseIndex));
      end

   Review the geometry, boundary conditions, measured quantities, units,
   uncertainties, and derived information before running the calculations.

#. **Initialize the model and numerical options.**

   Obtain the default input-option structure associated with the dataset
   workflow:

   .. code-block:: matlab

      opts = alldata.inputOptions();

   The returned structure contains the initial physical-model selections
   under ``opts.model`` and numerical settings under ``opts.options``.

#. **Modify models and numerical options as required.**

   Change only the selections needed for the intended calculation:

   .. code-block:: matlab

      opts.model.VOID = 'BESTION';
      opts.options.AXIALINTERP = 'NEXT';

   Nondefault selections and calibrated coefficients should be documented
   with the calculation. If the same option structure is modified
   progressively, earlier selections remain active until explicitly
   replaced.

#. **Generate the OpenSTREAM input files.**

   Generate the model, numerical-option, geometry, and boundary-condition
   inputs required by OpenSTREAM:

   .. code-block:: matlab

      mixture.makeInputFiles( ...
          inputOptions=opts, ...
          ioDirectory="NURETH21/Mixture");

   The ``inputOptions`` argument specifies the options controlling input-file
   generation. The ``ioDirectory`` argument defines the working directory for
   the case. OpenSTREAM input files are generated in this directory, and
   simulation outputs are written there during execution. The path may be
   specified as either an absolute or a relative path.

   When managing multiple datasets, solver frameworks, or case groups, a
   dedicated ``ioDirectory`` for each case helps keep inputs and outputs
   organized and separated.

#. **Run the selected solver.**

   Execute the calculation using the required OpenSTREAM solver framework:

   .. code-block:: matlab

      data.runCase( ...
          'Mixture', ...
          'inputSetOpts',inputSetOpts, ...
          'saveResultsToFile',saveResultsToFile);

   The first argument specifies the OpenSTREAM solver framework to run.
   In this example, ``'Mixture'`` selects the Mixture solver. Other solver
   frameworks supported by the dataset can be selected by providing the
   corresponding framework name.

   The ``inputSetOpts`` argument specifies options used when preparing and
   executing the case. For example, these options can control whether
   existing session files are overwritten and how solver log messages are
   handled:

   .. code-block:: matlab

      inputSetOpts = { ...
         'overwriteSessionFiles',true, ...
         'LOGMODE','BOTH'};

   The ``saveResultsToFile`` argument controls whether the computed results
   are written to files in the case ``ioDirectory`` in addition to being
   returned to MATLAB. When set to ``false``, results are only returned to
   the MATLAB workspace:

   .. code-block:: matlab

      saveResultsToFile = false;

#. **Check convergence.**

   Confirm that the selected calculations reached the expected solver
   state:

   .. code-block:: matlab

      data.checkConvergence();

   Convergence should be reviewed before calculated quantities are compared
   with experimental measurements or used in subsequent analyses.

#. **Post-process and compare the results.**

   Use the dataset-specific plotting or post-processing methods to compare
   calculated and measured quantities:

   .. code-block:: matlab

      data.plotResults(...);

   The comparison should identify the measured quantity, corresponding
   calculated quantity, units, case conditions, model configuration, and
   any interpolation, filtering, or derived quantities.

#. **Record the reproducibility information.**

   Retain the selected dataset records, nondefault model parameters,
   numerical options, solver framework, output location, and the
   OpenSTREAM and OpenSTREAM-database versions or commits used.

A lightweight workflow starts by constructing a generic ``Dataset`` object
from an in-memory MATLAB table. It then follows the same option-selection,
input-generation, execution, convergence-review, and post-processing
sequence.

Examples of these workflows are provided in the MATLAB Live Scripts
described on the :doc:`application projects <projects>` page.

Generated files
---------------

OpenSTREAM-database may generate input packages and output folders
containing:

- OpenSTREAM input files;
- solver session files;
- solver results;
- convergence logs;
- saved solver objects;
- processed comparisons;
- figures;
- other post-processing outputs.

Generated artifacts are excluded from version control through the
repository ``.gitignore`` rules. Source-data files, MATLAB classes, reviewed
project source files, templates, and documentation remain
version-controlled.

Generated files should not be used as the only record of a calculation.
Reproducible work should retain the source dataset, model and numerical
configuration, software version or commit, and workflow required to
regenerate the results.

Data provenance and citation
----------------------------

The datasets implemented in OpenSTREAM-database are derived from publicly
available experimental sources.

When using a dataset:

- Consult and cite the original experimental publication or public data
  source.
- Review the experimental conditions, measurement definitions, original
  units, and reported uncertainties.
- Review any conversion, transcription, character recognition,
  digitization, processing, interpolation, filtering, reconstruction, or
  assumptions introduced by the implementation.
- Distinguish direct measurements from derived or calculated quantities.
- Identify the OpenSTREAM and OpenSTREAM-database versions or commits used.
- Cite OpenSTREAM and OpenSTREAM-database as appropriate.

Use of an OpenSTREAM-database implementation does not replace citation of
the original experimental source.

Licensing of OpenSTREAM-database software and documentation does not
supersede rights, licenses, attribution requirements, or redistribution
conditions associated with the original publications and experimental
data.

Validation and interpretation
-----------------------------

Inclusion of a dataset, comparison method, or application workflow does not
imply that every OpenSTREAM solver, closure model, model combination, or
calculated quantity has been comprehensively verified or validated against
that dataset.

Users remain responsible for evaluating:

- The applicability and quality of the experimental data.
- The assumptions and validity ranges of the selected models.
- The effects of dataset processing and derived quantities.
- Numerical convergence and discretization sensitivity.
- Sensitivity to closure-model and numerical-option selections.
- Experimental, model, parameter, and numerical uncertainty.
- The suitability of the selected comparison quantities and metrics.
- The interpretation of calculated-versus-measured differences.

A favorable comparison for one case, quantity, dataset, or model selection
must not be interpreted as general validation outside the conditions
examined.

Testing and verification
------------------------

OpenSTREAM-database does not currently include a repository-wide automated
test suite.

Dataset implementations and application workflows should therefore be
verified through documented and reproducible execution of the affected
cases. Verification should include, as applicable:

- successful loading of the source-data records;
- review of source-data provenance and processing;
- consistency checks on geometry, boundary conditions, units, and power;
- review of generated OpenSTREAM inputs;
- confirmation of solver convergence;
- comparison of calculated and experimental quantities;
- confirmation that missing measurements are not interpreted as zeros;
- confirmation that derived quantities are identified as derived;
- sensitivity to relevant physical models and numerical settings.

Detailed review and contribution requirements are provided in the
:doc:`contribution guidelines <contributing>`.

Development status
------------------

OpenSTREAM-database and its application workflows are under active
development. Dataset implementations, source-file formats, project
workflows, comparison methods, documentation, and verification
capabilities may continue to evolve.

Users reproducing earlier calculations should review:

- the dataset-specific README;
- the corresponding publication companion, when available;
- the OpenSTREAM and OpenSTREAM-database repository histories;
- the versions or commits used for the original calculation.

Contributing
------------

Contributions of new datasets, source-data corrections, application
workflows, publication companions, documentation, comparison methods, and
verification capabilities are welcome.

Before contributing, review the
:doc:`OpenSTREAM-database contribution guidelines <contributing>`.