Contributing to the database
============================

Contributions to OpenSTREAM-database are welcome. Contributions may
include new publicly available datasets, corrections to existing dataset
implementations, additional application cases, improved plotting and
comparison methods, uncertainty information, validation metrics,
documentation, and project workflows.

OpenSTREAM-database complements the core OpenSTREAM repository.
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

Dataset implementations should follow the established MATLAB package
organization:

.. code-block:: text

   +DatasetName/
   ├── +src/
   │   └── DatasetName.xml
   ├── @DatasetName/
   │   ├── DatasetName.m
   │   └── plotResults.m
   └── README.md

JSON source files can be used instead of, or alongside, XML source files.
The selected format should preserve the same logical dataset information.

The package name should identify the dataset clearly and consistently. A
publication-based dataset name should generally combine the surname of the
first author and the publication year, following the convention used by
the existing packages.

The dataset-specific class should inherit from the generic ``Dataset``
class and use the shared application interface where practical.

Dataset template
----------------

OpenSTREAM-database includes a template dataset folder that provides the
starting structure for a new dataset implementation.

The template contains:

- An empty ``+src`` folder for dataset source files.
- A dataset-class folder containing a template MATLAB class that inherits
  from the generic ``Dataset`` class.
- A template ``README.md`` containing the expected documentation
  structure.

To start a new dataset implementation:

#. Copy the complete template dataset folder.
#. Rename the package folder using the selected dataset name.
#. Rename the class folder and MATLAB class file consistently.
#. Update the class name, constructor, comments, and documentation.
#. Add the XML or JSON source files under ``+src``.
#. Complete the dataset-specific properties and methods.
#. Complete the dataset README.
#. Add dataset-specific result plotting where applicable.
#. Verify the implemented dataset and application workflow.

All numerical data added under ``+src`` must use SI units.

The template provides the expected structure and documentation
placeholders. Contributors remain responsible for completing and verifying
all dataset-specific source data, metadata, methods, assumptions, unit
conversions, uncertainty information, plotting functionality, and
application workflows.

Structured source files
-----------------------

Dataset source files are stored under the package ``+src`` directory and
can use XML or JSON.

Each case can contain:

#. OpenSTREAM case-definition information, whose field names follow the
   strict naming convention expected by the generic input-generation
   functionality.
#. Dataset-specific information used by the dataset class, plotting
   methods, and application workflows.

Reserved OpenSTREAM field names are case-sensitive and must use the
expected spelling. Renaming a reserved field, changing its capitalization,
or replacing it with a dataset-specific synonym can prevent the
corresponding information from being transferred to the generated
OpenSTREAM inputs.

Dataset-specific fields may be added freely, provided that they:

- Do not conflict with reserved OpenSTREAM field names.
- Use descriptive and unambiguous names.
- Are consistent throughout the dataset.
- Are represented consistently in XML and JSON when both formats exist.
- Are documented in the dataset README or class implementation.
- Use clearly documented SI units.
- Include uncertainty or availability information where relevant.

Scalar quantities should be represented as individual values. Array
quantities should use repeated XML elements or JSON arrays. Related arrays
must have compatible lengths and ordering.

Missing or unavailable information must be distinguishable from a physical
value of zero and handled explicitly by the dataset class.

Source data
-----------

All numerical data stored in OpenSTREAM-database source files must use SI
units. This requirement applies even when the original publication reports
data using another system of units.

The source-data implementation should preserve the original experimental
information as faithfully as possible. Any transcription, correction,
filtering, interpolation, reconstruction, or unit conversion must be
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

Data integrity
--------------

When creating or modifying a source file, verify that:

- Every case has a unique and stable identifier.
- Reserved OpenSTREAM fields use the exact expected names.
- Required fields contain valid values.
- All numerical values use SI units.
- Related arrays have compatible lengths and ordering.
- Axial wall-mesh and wall-power arrays are compatible.
- Measurement-coordinate and measured-value arrays are compatible.
- Missing information is distinguishable from a physical zero.
- XML and JSON representations contain equivalent information when both
  formats are provided.
- Unit conversions retain sufficient numerical precision.
- Dataset-specific fields are interpreted consistently by the class and
  plotting methods.

The dataset README or class implementation should identify whether a
stored quantity is reported directly, converted, digitized, reconstructed,
derived from other values, or introduced specifically for the OpenSTREAM
application.

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

- Inherit from the generic ``Dataset`` class.
- Load and interpret the corresponding XML or JSON source data.
- Preserve the generic dataset interface where practical.
- Identify the available experimental cases and quantities.
- Generate valid OpenSTREAM inputs.
- Operate consistently using SI units.
- Avoid hard-coded local file-system paths.
- Use clear property and method names.
- Document assumptions and transformations.
- Validate inputs and report unsupported selections clearly.
- Support reproducible execution across the intended environments.

Functionality common to several datasets should be considered for
implementation in the generic ``Dataset`` class rather than duplicated
across dataset-specific classes.

OpenSTREAM dependency
---------------------

OpenSTREAM is maintained as a separate repository and is not included as a
Git submodule of OpenSTREAM-database.

Dataset implementations and application projects should rely on required
OpenSTREAM classes being available on the MATLAB path. They should not
assume a fixed relative directory arrangement between the repositories.

Installation and MATLAB path instructions are provided on the
:doc:`OpenSTREAM-database <database>` page.

Application projects
--------------------

A contributed application project should provide a reproducible workflow
for:

#. Constructing the dataset-specific object.
#. Selecting one or more experimental cases.
#. Selecting an OpenSTREAM solver and model configuration.
#. Generating the required OpenSTREAM input files.
#. Running the selected cases.
#. Extracting calculated and measured quantities.
#. Comparing and visualizing the results.
#. Documenting assumptions, numerical settings, and limitations.

MATLAB Live Scripts are recommended for documented application workflows
that combine explanatory text, executable code, figures, and results.

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

- Confirming that XML and JSON source files can be loaded correctly.
- Confirming that reserved OpenSTREAM fields use the required names.
- Confirming that all numerical source data use SI units.
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

Automated testing is a planned improvement. Future tests may cover source-
data parsing, unit conversion, metadata, case selection, input generation,
plotting and comparison methods, application workflows, and numerical
regression.

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
- Citation, licensing, attribution, and redistribution requirements.

User-visible changes should also be reflected in the OpenSTREAM
Applications documentation when they affect the database description,
available datasets, exported project workflows, publications,
installation requirements, or recommended application procedures.

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
#. Review applicable licensing, attribution, and redistribution
   conditions.
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
- The dataset template was used or the equivalent required structure was
  followed.
- The original experimental source is identified and cited.
- Applicable licensing and redistribution conditions have been reviewed.
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
