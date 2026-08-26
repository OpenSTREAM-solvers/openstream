Contributing to OpenSTREAM-database
===================================

Contributions to **OpenSTREAM-database** are welcome. Contributions may
include new publicly available datasets, corrections to existing dataset
implementations, additional application cases, improved plotting and
comparison methods, uncertainty information, validation metrics,
documentation, and project workflows.

OpenSTREAM-database complements the core **OpenSTREAM** repository.
Contributions related to solver frameworks, physical models, closure
models, numerical methods, input handling, or other core functionality
should normally be made in the OpenSTREAM repository.

Contributions related to experimental datasets and their application or
validation workflows belong in OpenSTREAM-database.

Types of contributions
----------------------

Contributions may include:

- New publicly available experimental datasets.
- Additional cases from datasets already implemented.
- Corrections to source-data transcription or metadata.
- Improved dataset documentation and bibliographic information.
- Additional OpenSTREAM solver or model configurations.
- New calculated-versus-measured comparisons.
- Experimental uncertainty information.
- Validation metrics and statistical analyses.
- Improved visualization and post-processing methods.
- MATLAB scripts and Live Script application projects.
- Corrections to existing application workflows.
- Development of an automated testing and regression framework.

Dataset organization
--------------------

New datasets should follow the established MATLAB package organization:

.. code-block:: text

   +DatasetName/
   ├── +src/
   │   └── DatasetName.xml
   ├── @DatasetName/
   │   ├── DatasetName.m
   │   └── plotResults.m
   └── README.md

The package name should identify the dataset clearly and consistently. A
publication-based dataset name should generally combine the surname of the
first author and the publication year, following the convention used by
the existing dataset packages.

The dataset-specific class should inherit from the common ``Dataset``
class and use the shared application interface where practical.

Source data
-----------

Dataset source files are stored under the package ``+src`` directory.

All numerical data stored in OpenSTREAM-database source files must use SI
units. This requirement applies even when the original publication reports
data using another system of units.

The source-data implementation should preserve the original experimental
information as faithfully as possible. Any transcription, correction,
filtering, interpolation, reconstruction, or unit conversion should be
documented.

For every implemented quantity, document:

- The quantity name and physical meaning.
- The SI unit used in OpenSTREAM-database.
- The unit reported in the original source.
- The conversion applied, when applicable.
- The original table, figure, appendix, or data source.
- Any ambiguity or interpretation introduced during transcription.
- The available measurement uncertainty.
- Any missing or unavailable information.

Unit conversions should retain sufficient numerical precision for the
intended application and validation analyses.

Data provenance
---------------

Every dataset contribution should identify the authoritative experimental
source.

The dataset README should include:

- The complete bibliographic reference.
- A link to the publication or public data source, when available.
- A description of the experimental facility.
- The relevant test section and geometry.
- The measured and prescribed quantities.
- The range of experimental conditions.
- The units reported in the original source.
- The SI units used in OpenSTREAM-database.
- The reported measurement uncertainties.
- Known limitations or qualifications of the data.
- The relationship between the original data and the implemented source
  files.
- Any licensing, redistribution, or citation requirements.

The original publication remains the authoritative source for the
experimental configuration, measurements, uncertainties, and
interpretation. The OpenSTREAM-database implementation should not imply
greater accuracy, completeness, or certainty than is supported by the
published information.

Dataset class
-------------

The dataset-specific MATLAB class should:

- Inherit from the common ``Dataset`` class.
- Load and interpret the corresponding source-data representation.
- Preserve the common dataset interface where practical.
- Identify the available experimental cases and quantities.
- Generate valid OpenSTREAM inputs.
- Operate consistently using SI units.
- Avoid hard-coded local file-system paths.
- Use clear property and method names.
- Document assumptions and transformations.
- Validate inputs and report unsupported selections clearly.
- Support reproducible execution across the intended environments.

Functionality common to several datasets should be considered for
implementation in the common ``Dataset`` class rather than duplicated
across dataset-specific classes.

OpenSTREAM dependency
---------------------

OpenSTREAM is maintained as a separate repository and is not included as a
Git submodule of OpenSTREAM-database.

Before running or verifying an OpenSTREAM-database application, ensure
that both OpenSTREAM and OpenSTREAM-database are available on the MATLAB
path:

.. code-block:: matlab

   addpath('<path-to-openstream>')
   addpath('<path-to-openstream-database>')

The repositories may be stored in separate locations. The implementation
should rely on the required OpenSTREAM classes being available on the
MATLAB path rather than on a fixed relative directory arrangement.

Application projects
--------------------

Application projects are stored under the repository ``projects`` folder.

A project should provide a reproducible workflow for:

#. Constructing the dataset-specific object.
#. Selecting one or more experimental cases.
#. Selecting an OpenSTREAM solver and model configuration.
#. Generating the required OpenSTREAM input files.
#. Running the selected cases.
#. Extracting calculated and measured quantities.
#. Comparing the results.
#. Visualizing and interpreting the comparison.

MATLAB Live Scripts are recommended for documented application workflows
that combine explanatory text, executable code, figures, and results.

When sufficiently developed and reviewed, Live Script projects may be
exported to HTML and included on the
:doc:`application projects <projects>` page.

Projects should avoid hard-coded local paths and should state the expected
working directory or path configuration clearly.

Comparison and validation
-------------------------

Calculated-versus-measured comparisons should identify:

- The experimental quantity being compared.
- The corresponding OpenSTREAM quantity.
- The location and time associated with the comparison.
- The SI unit used for the comparison.
- The selected solver and physical models.
- The numerical settings.
- The spatial and temporal discretization.
- The experimental uncertainty, where available.
- The comparison metric, where applicable.
- Any filtering, averaging, interpolation, or alignment procedure.

A favorable comparison for one case, quantity, or model selection should
not be described as general validation outside the investigated
conditions.

Contributors should distinguish between:

- Verification that an implementation behaves as intended.
- Validation against experimental observations.
- Numerical sensitivity to mesh, time step, convergence settings, and
  solver options.
- Experimental, model, parameter, and numerical uncertainty.

Plotting and post-processing
----------------------------

Dataset-specific plotting methods should:

- Use SI units.
- Identify measured and calculated quantities clearly.
- Include readable axis labels, units, legends, and captions.
- Distinguish different solvers and model configurations consistently.
- Represent experimental uncertainty when available and relevant.
- Avoid implying agreement beyond the precision or uncertainty of the
  available data.
- Support reproducible use from the corresponding project workflow.

Common plotting or comparison behavior should be implemented in shared
functionality where practical.

Testing and verification
------------------------

OpenSTREAM-database does not currently include an automated test suite.

Until automated testing is implemented, contributors should verify changes
using reproducible checks appropriate to the contribution. These checks
should include, where applicable:

- Confirming that source-data files can be loaded correctly.
- Confirming that all numerical source data are stored in SI units.
- Reviewing unit conversions against the original experimental source.
- Verifying that the intended experimental cases can be selected.
- Reviewing the generated OpenSTREAM input files.
- Running the affected application cases.
- Confirming that the selected OpenSTREAM calculations complete as
  expected.
- Comparing calculated and measured quantities.
- Reviewing generated figures and post-processing results.
- Confirming that existing application workflows are not adversely
  affected.

The verification procedure and its results should be described in the
pull request.

Automated testing is a planned improvement. Future tests may cover:

- Source-data parsing.
- Unit conversion.
- Dataset metadata.
- Case selection.
- OpenSTREAM input generation.
- Dataset-specific plotting and comparison methods.
- Application workflows.
- Numerical regression against approved results.

Documentation requirements
--------------------------

Each new dataset contribution should include a package README describing:

- The original experimental source and complete bibliographic reference.
- The scope of the implemented data.
- The experimental facility and relevant geometry.
- The implemented experimental conditions and measured quantities.
- The units reported in the original source.
- The SI units used in OpenSTREAM-database.
- Any unit conversions, transcription steps, interpolation, filtering, or
  other data processing.
- The reported measurement uncertainties, where available.
- Known limitations, ambiguities, or missing information.
- Supported OpenSTREAM application workflows.
- A minimal reproducible usage example.
- Citation and redistribution requirements.

User-visible changes should also be reflected in the OpenSTREAM
Applications documentation when they affect:

- The OpenSTREAM-database description.
- Available datasets.
- Exported project workflows.
- Publications.
- Installation or path requirements.
- Recommended application procedures.

Submitting a contribution
-------------------------

Before submitting a contribution:

#. Confirm that OpenSTREAM and OpenSTREAM-database are both available on
   the MATLAB path.
#. Perform the relevant reproducible verification checks.
#. Run the affected project workflows.
#. Review generated OpenSTREAM inputs and calculated results.
#. Confirm that all numerical source data use SI units.
#. Review unit conversions and retained numerical precision.
#. Verify bibliographic references and dataset provenance.
#. Confirm that generated outputs are not included in the commit.
#. Update the documentation and project exports when required.
#. Describe intentional numerical changes in the pull request.

The pull-request description should identify:

- The purpose and scope of the contribution.
- The original experimental source.
- Added or modified cases and quantities.
- Data-processing and unit-conversion steps.
- Affected OpenSTREAM solvers and models.
- The verification procedure performed.
- The results of the verification.
- Numerical differences from previous results.
- Remaining limitations or unresolved questions.

Contributor checklist
---------------------

Before submitting a pull request, confirm that:

- The contribution follows the established dataset package organization.
- The original experimental source is identified and cited.
- All numerical source data stored under ``+src`` use SI units.
- Unit conversions are documented.
- Measurement uncertainties are included where available.
- Dataset assumptions and processing steps are documented.
- The affected dataset and application workflows have been verified.
- The verification procedure and results are documented.
- Generated OpenSTREAM inputs and calculated results have been reviewed.
- Any numerical differences from previous results are understood and
  justified.
- Documentation and project workflows have been updated.
- Generated input, result, and output directories are not committed.