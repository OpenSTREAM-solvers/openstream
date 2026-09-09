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

Contributions related to experimental datasets and their application,
assessment, validation, or publication companion workflows belong in
OpenSTREAM-database.

Types of contributions
----------------------

Contributions may include:

- New publicly available experimental datasets.
- Additional cases from datasets already implemented.
- Corrections to source-data transcription, digitization, conversion, or
  metadata.
- Improved dataset documentation and bibliographic information.
- Additional OpenSTREAM solver or model configurations.
- New calculated-versus-measured comparisons.
- Experimental uncertainty information.
- Validation metrics and statistical analyses.
- Improved visualization and post-processing methods.
- MATLAB Live Script application and publication companion projects.
- Corrections to existing application workflows.
- Tests and verification capabilities.
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

Additional dataset-specific methods may be included when required. For
example:

.. code-block:: text

   +DatasetName/
   ├── +src/
   │   └── DatasetName.xml
   ├── @DatasetName/
   │   ├── DatasetName.m
   │   ├── plotResults.m
   │   └── plotTrends.m
   └── README.md

The package components have the following roles:

``+src``
   Contains the authoritative XML or JSON source-data representation. All
   stored numerical values must use SI units, with absolute temperatures
   expressed in kelvin.

``@DatasetName``
   Contains the dataset-specific class and separately implemented methods.

``DatasetName.m``
   Defines the dataset-specific class, which inherits from the generic
   ``Dataset`` class.

``plotResults.m``
   Provides dataset-specific plotting and calculated-versus-measured
   comparison functionality.

``README.md``
   Documents the original experimental source, implemented data, units,
   uncertainty, assumptions, processing, usage, verification, attribution,
   and limitations.

A dataset package should normally maintain only one authoritative
machine-readable source file. If XML and JSON representations are both
retained, the dataset README must identify the authoritative
representation, explain how the alternative representation is generated,
and describe how consistency is verified.

The dataset-specific class should inherit from the generic ``Dataset``
class and use the shared dataset interface where practical.

Dataset template
----------------

OpenSTREAM-database includes a ``+Template`` package that provides the
starting structure for a new dataset implementation.

The template contains:

- A ``+src`` folder containing guidance for adding the authoritative XML
  or JSON source-data file.
- An ``@Template`` class folder.
- A template ``Template.m`` class that inherits from the generic
  ``Dataset`` class.
- A template ``plotResults.m`` method.
- A template ``README.md`` containing the expected dataset documentation
  structure.

The template follows this organization:

.. code-block:: text

   +Template/
   ├── +src/
   │   └── README.md
   ├── @Template/
   │   ├── Template.m
   │   └── plotResults.m
   └── README.md

To begin implementing a new dataset:

#. Copy the complete ``+Template`` package.
#. Select a valid dataset name following the naming convention described
   below.
#. Rename the package folder, class folder, and MATLAB class file
   consistently.
#. Update the class definition, ``addPath`` method, comments, and
   documentation.
#. Add the authoritative XML or JSON source-data file under ``+src``.
#. Add all fields required by each supported experimental case.
#. Add and document any required dataset-specific fields.
#. Complete the dataset-specific properties and methods.
#. Complete the dataset README using the template headings.
#. Implement dataset-specific result plotting where applicable.
#. Verify source-data loading, input generation, case execution, and
   post-processing.

The template supplies the expected structure and documentation
placeholders. Contributors remain responsible for completing and verifying
all dataset-specific source data, metadata, methods, assumptions, unit
conversions, uncertainties, plotting functionality, and application
workflows.

Naming convention
-----------------

Dataset packages follow a strict naming convention. The package folder,
class folder, class file, class definition, dataset name, and source-data
filename must use consistent names.

For a dataset named ``AuthorYear``, the expected structure is:

.. code-block:: text

   +AuthorYear/
   ├── +src/
   │   └── AuthorYear.xml
   ├── @AuthorYear/
   │   ├── AuthorYear.m
   │   └── plotResults.m
   └── README.md

The following names must agree:

.. list-table::
   :header-rows: 1
   :widths: 45 55

   * - Element
     - Required form
   * - MATLAB package folder
     - ``+AuthorYear``
   * - MATLAB class folder
     - ``@AuthorYear``
   * - MATLAB class file
     - ``AuthorYear.m``
   * - MATLAB class definition
     - ``classdef AuthorYear < Dataset``
   * - Dataset name assigned in ``addPath``
     - ``data.name = 'AuthorYear'``
   * - Source-data filename
     - ``AuthorYear.xml``
   * - Source-data location
     - ``+AuthorYear/+src/AuthorYear.xml``

The leading ``+`` and ``@`` characters are part of MATLAB package and
class-folder syntax:

- ``+AuthorYear`` defines the MATLAB package.
- ``@AuthorYear`` defines the class folder within that package.
- ``AuthorYear.m`` contains the class definition.
- The class is referenced using the package-qualified name
  ``AuthorYear.AuthorYear``.

For publication-based datasets, the package name should generally combine
the surname of the first author and the four-digit publication year,
following the convention used by existing dataset packages.

If this combination is already used by another package, add a concise
qualifier that unambiguously identifies the publication. Prefer the second
author's surname or a short title keyword, for example
``AuthorCoauthor2020`` or ``Author2020CHF``.

The suffixes ``a``, ``b``, and so forth may be used when closely related
publications are conventionally cited as ``Author2020a``,
``Author2020b``, and so forth. The assignment of these suffixes must be
documented and remain stable.

The capitalization of author names and title keywords must be used
consistently throughout the package name, class name, source filename, and
documentation. For example, do not mix ``Author2020``, ``author2020``,
and ``AUTHOR2020``.

The dataset name must be a valid MATLAB identifier. Spaces, hyphens,
punctuation, and other invalid identifier characters must not be used.

When copying the template, update every occurrence of ``Template`` in:

#. The package-folder name.
#. The class-folder name.
#. The class filename.
#. The ``classdef`` declaration.
#. ``data.name`` in ``addPath``.
#. The source-data filename.
#. Code examples and headings in ``README.md``.
#. Project scripts that construct or refer to the dataset class.

For example:

.. code-block:: matlab

   classdef AuthorYear < Dataset
       % AUTHORYEAR Dataset implementation for Author et al. (Year).

       methods

           function addPath(data)
               % ADDPATH Define the dataset name and source-data file.

               data.name = 'AuthorYear';
               data.path = ...
                   data.getSourceFilePath('AuthorYear.xml');
           end

       end

   end

Use ``getSourceFilePath`` rather than a hard-coded relative or absolute
path. This allows the dataset package to locate its source file
independently of the current MATLAB working directory.

Separately implemented methods in the ``@AuthorYear`` folder do not need
redundant declarations in the main class file.

The resulting object is constructed using the package-qualified class
name:

.. code-block:: matlab

   data = AuthorYear.AuthorYear(...);

A mismatch between package, class, or source-data names may prevent MATLAB
from locating the class or may cause the dataset implementation to
reference the wrong source-data file.

Source data
-----------

Dataset source files are stored under the package ``+src`` directory.

XML and JSON are supported source formats. A dataset package should
normally maintain only one authoritative machine-readable source
representation.

If XML and JSON representations are both retained, the dataset README must
state:

- Which representation is authoritative.
- How the alternative representation is generated.
- Whether contributors may edit the alternative representation.
- How consistency between the representations is verified.

Equivalent XML and JSON files should not be maintained independently
without a documented synchronization and verification procedure.

All numerical data stored in OpenSTREAM-database source files must use SI
units. Absolute temperatures must be expressed in kelvin. This requirement
applies even when the original experimental publication reports data using
another system of units.

The source-data implementation should preserve the original experimental
information as faithfully as possible. Any transcription, correction,
character recognition, digitization, filtering, interpolation,
reconstruction, unit conversion, or derivation must be documented.

Missing numerical information must be represented explicitly and must not
be interpreted as zero unless zero is the reported experimental value. The
missing-value convention must be documented in the dataset README and
handled explicitly by the dataset-specific implementation.

The dataset object reads and interprets the corresponding XML or JSON
source file during construction. Reading the source file is therefore part
of dataset-object construction and is not a separate step in the
application workflow.

Lightweight datasets
--------------------

OpenSTREAM-database can also be used without an XML or JSON source-data
file.

A case can be defined directly using a one-row MATLAB table and passed to
a lightweight ``Dataset`` object:

.. code-block:: matlab

   data = Dataset( ...
       1, ...
       'isLightWeight',true, ...
       'lightWeightEntryData',entryData);

This workflow is suitable for:

- Publication demonstration cases.
- Concise examples and tutorials.
- Exploratory calculations.
- User-defined cases that do not require a maintained dataset package.
- Comparisons of several OpenSTREAM solver frameworks using a common case
  definition.

The table must contain the geometry, boundary-condition, wall-heating, and
fluid information required by the selected OpenSTREAM workflow. All
numerical values must follow the same SI-unit convention as file-based
datasets.

A lightweight case should not replace a maintained dataset package when
experimental provenance, measurement uncertainty, repeated case
selection, or long-term reuse must be documented.

Dataset fields
--------------

Each experimental case in the XML or JSON source file must define the
fields required by its intended OpenSTREAM workflow. Additional
dataset-specific fields may be added when required to represent the
available experimental information.

Mandatory fields
~~~~~~~~~~~~~~~~

The following fields are normally required for a complete heated-channel
case:

.. list-table::
   :header-rows: 1
   :widths: 25 55 20

   * - Field
     - Description
     - SI unit
   * - ``Fluid``
     - Working-fluid identifier used by OpenSTREAM.
     - Not applicable
   * - ``Pressure``
     - System pressure.
     - Pa
   * - ``MassFlow``
     - Inlet mass flow rate.
     - kg/s
   * - ``InletEnthalpy``
     - Inlet specific enthalpy.
     - J/kg
   * - ``Length``
     - Axial length of the modeled channel.
     - m
   * - ``Area``
     - Channel flow area.
     - m²
   * - ``Perimeter``
     - Channel perimeter used by the OpenSTREAM geometry.
     - m
   * - ``Power``
     - Total applied power.
     - W
   * - ``WallMesh``
     - Axial wall-interval lengths associated with the wall-power
       distribution.
     - m
   * - ``WallPower``
     - Relative axial wall-power distribution.
     - Dimensionless

Field names are case-sensitive and must be written exactly as expected by
the input-generation implementation.

The mandatory fields must satisfy the following requirements:

- Every supported case must define the fields required by its workflow.
- All numerical values must use SI units.
- Absolute temperatures must be expressed in kelvin.
- ``Fluid`` must use an identifier supported by the OpenSTREAM
  fluid-property interface.
- ``WallMesh`` and ``WallPower`` must have compatible lengths and
  ordering.
- The sum of ``WallMesh`` must be consistent with the modeled channel
  length.
- Geometry fields must represent the channel modeled by OpenSTREAM.
- Boundary-condition fields must represent the intended experimental case.
- Any conversion, reconstruction, or interpretation used to obtain a field
  must be documented in the dataset README.

Fields that are not required for a particular workflow may be omitted only
when the generic input-generation implementation and dataset-specific
methods support their absence.

Dataset-specific fields
~~~~~~~~~~~~~~~~~~~~~~~

Additional fields may be included when required to represent information
specific to the dataset.

Dataset-specific fields may describe:

- Measured quantities.
- Instrument and measurement locations.
- Experimental uncertainties.
- Facility or test-section characteristics not represented by the
  mandatory geometry fields.
- Inlet, outlet, or local experimental conditions.
- Flow-regime or transition information.
- Dataset-specific case classifications.
- Information required for calculated-versus-measured comparisons.
- Quantities derived during source-data preparation or post-processing.

Each dataset-specific field must be documented in the dataset README. The
documentation should state:

- The exact field name.
- The physical meaning of the field.
- Whether the field is required or optional.
- Confirmation that all numerical data use SI units.
- The unit used for the implemented quantity whenever clarification is
  useful.
- The unit reported in the original experimental source, when different.
- The source table, figure, page, appendix, or data file.
- Any unit conversion, transcription, character recognition,
  digitization, interpolation, derivation, or other processing applied.
- The reported measurement uncertainty, where available.
- The behavior when the field is absent or unavailable.
- Whether the quantity is measured, prescribed, transcribed, digitized,
  reconstructed, derived, or calculated.

A general SI-unit statement is sufficient where the representation is
unambiguous. Units must be stated explicitly where clarification is
needed. Absolute temperatures must be identified as being expressed in
kelvin.

A field name must not imply an incorrect physical unit. For example, a
field named ``InletSubcooling`` may represent an enthalpy difference in
J/kg rather than a temperature difference. Such conventions must be stated
explicitly.

Dataset-specific fields must not replace, rename, or change the meaning of
the mandatory fields.

When the same physical quantity is represented by several dataset
implementations, a common field name and representation should be used
where practical.

Source-file requirements
~~~~~~~~~~~~~~~~~~~~~~~~

The XML or JSON source representation should use a consistent structure
across all implemented cases.

Before completing a dataset implementation, confirm that:

- Every supported case contains the fields required by its workflow.
- Mandatory and dataset-specific field names are used consistently.
- Numerical fields contain valid SI values.
- Absolute temperatures are expressed in kelvin.
- Related array dimensions and ordering are mutually consistent.
- ``WallMesh`` and ``WallPower`` describe compatible axial distributions.
- Case identifiers are unique.
- Missing experimental information is represented explicitly.
- Missing numerical information is not represented as zero unless zero is
  the reported value.
- Undocumented replacement values are not introduced.
- Derived, reconstructed, or calculated fields are identified and
  documented.
- Unsupported or incomplete cases are identified clearly.

The dataset class should validate the fields required by its implementation
and report missing, inconsistent, or unsupported data with a clear
diagnostic.

Data provenance
---------------

Every dataset contribution must identify the authoritative experimental
source.

The dataset README should include:

- The complete bibliographic reference.
- A link to the publication or public data source, when available.
- A description of the experimental facility.
- The relevant test section and geometry.
- The measured and prescribed quantities.
- The range of experimental conditions.
- Confirmation that all stored numerical data use SI units, with absolute
  temperatures expressed in kelvin.
- The reported measurement uncertainties.
- Known limitations or qualifications of the data.
- The relationship between the original data and the implemented
  source-data file.
- Any licensing, redistribution, attribution, or citation requirements.

The source-data preparation method must be stated explicitly. Applicable
methods include:

- Manual transcription from publication tables.
- Character recognition from scanned reports.
- Figure digitization.
- Import from publicly available machine-readable data.
- Unit conversion.
- Interpolation or reconstruction.
- Derivation of additional quantities required for OpenSTREAM input
  generation or post-processing.

Where applicable, document the checks performed to improve accuracy and
internal consistency, including:

- Geometry consistency.
- Mass-flow, mass-flux, and area consistency.
- Power reconstruction.
- Energy-balance checks.
- Unit-conversion checks.
- Array-length and ordering checks.
- Comparison of repeated or related cases.
- Review against the original tables or figures.

The original publication or public data source remains authoritative for
the experimental configuration, measurements, uncertainties, and
interpretation.

The OpenSTREAM-database implementation must not imply greater accuracy,
completeness, or certainty than is supported by the published information.

Dataset class
-------------

The dataset-specific MATLAB class should:

- Inherit from the generic ``Dataset`` class.
- Read and interpret its source-data representation during object
  construction.
- Define its package name and source-data file through ``addPath``.
- Use ``getSourceFilePath`` to locate the authoritative source file.
- Preserve the generic dataset interface where practical.
- Identify the available experimental cases and quantities.
- Generate valid OpenSTREAM inputs.
- Operate consistently using SI units.
- Handle missing experimental values explicitly.
- Avoid hard-coded local file-system paths.
- Avoid redundant declarations for methods already implemented separately
  in the ``@DatasetName`` folder.
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

Dataset implementations and application projects should rely on the
required OpenSTREAM classes being available on the MATLAB path. They
should not assume a fixed relative directory arrangement between the two
repositories.

Installation and MATLAB path instructions are provided on the
:doc:`OpenSTREAM-database <database>` page.

Application projects
--------------------

Application projects are stored under the repository ``projects`` folder.
They may use a dataset package or a lightweight in-memory ``Dataset``
object.

A contributed project should provide a reproducible workflow for:

#. Constructing a dataset-specific object, which reads and interprets the
   corresponding XML or JSON source file, or constructing a lightweight
   ``Dataset`` object from an in-memory table.
#. Selecting one or more experimental or demonstration cases.
#. Selecting an OpenSTREAM solver and model configuration.
#. Generating the required OpenSTREAM input files.
#. Running the selected cases.
#. Reviewing solver convergence.
#. Extracting calculated and measured quantities.
#. Comparing the results.
#. Visualizing and interpreting the comparison.
#. Documenting assumptions, numerical settings, and limitations.

Projects should avoid hard-coded local paths and should state the expected
working directory or MATLAB path configuration clearly.

MATLAB Live Scripts are recommended when explanatory text, executable
code, figures, calculated results, convergence information, and
interpretation form part of the documented application workflow.

Projects intended to support publications or technical reports should
follow the reproducibility guidance provided in the
:doc:`OpenSTREAM scope and limitations
<../Guides/scope_and_limitations>` page.

Publication companion workflows
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A publication companion Live Script should reproduce or illustrate
selected calculations, figures, and results presented in the corresponding
publication.

The companion workflow must not be described as a complete record of the
research programme. Research activities generally include additional test
cases, closure-model development, sensitivity studies, uncertainty
analysis, numerical investigations, intermediate results, and unsuccessful
model variants that are not included in the published figures.

The project documentation should identify:

- The corresponding publication.
- The figures or results reproduced.
- The experimental datasets used.
- Important nondefault physical and numerical settings.
- Calculations or comparisons from the publication that are not
  reproduced.
- The limitations of the companion workflow.

The MATLAB Live Script is the authoritative executable version. A
completed execution may also be exported to HTML for viewing without
MATLAB. Interactive Live Editor features may not be preserved in the HTML
export.

Comparison and validation
-------------------------

Calculated-versus-measured comparisons should identify:

- The experimental quantity being compared.
- Whether the experimental value is directly measured or derived.
- The corresponding OpenSTREAM quantity.
- The location and time associated with the comparison.
- The SI unit used for the comparison.
- The selected solver and physical models.
- The numerical settings.
- The spatial and temporal discretization.
- The experimental uncertainty, where available.
- The comparison metric, where applicable.
- Any filtering, averaging, smoothing, interpolation, or alignment
  procedure.

A favorable comparison for one case, quantity, dataset, or model selection
must not be described as general validation outside the investigated
conditions.

Contributors should distinguish between:

- Verification that an implementation behaves as intended.
- Validation against experimental observations.
- Numerical sensitivity to mesh, time step, convergence settings, and
  solver options.
- Sensitivity to closure-model and parameter selections.
- Experimental, model, parameter, and numerical uncertainty.

Plotting and post-processing
----------------------------

Dataset-specific plotting methods should:

- Use SI units.
- Use kelvin for absolute temperatures.
- Identify measured, derived, and calculated quantities clearly.
- Include readable axis labels, units, legends, and captions.
- Distinguish solvers and model configurations consistently.
- Represent experimental uncertainty when available and relevant.
- Avoid implying agreement beyond the precision or uncertainty of the
  available data.
- Support reproducible use from the corresponding application project.
- Ensure that smoothing used for visualization does not modify the stored
  source data.
- Keep original measurement points visible or otherwise traceable when
  smoothed curves are shown.

Common plotting or comparison behavior should be implemented in shared
functionality where practical.

Testing and verification
------------------------

OpenSTREAM-database does not currently include an automated test suite.

Until automated testing is implemented, contributors should verify changes
using reproducible checks appropriate to the contribution.

These checks should include, where applicable:

- Confirming that the source-data files can be loaded correctly.
- Confirming that required fields are present.
- Confirming that all numerical source data use SI units.
- Confirming that absolute temperatures use kelvin.
- Reviewing unit conversions against the original experimental source.
- Comparing manually transcribed, character-recognized, or digitized
  values against the original source.
- Performing relevant geometry, power, unit, and energy-balance checks.
- Verifying that the intended experimental cases can be selected.
- Reviewing the generated OpenSTREAM input files.
- Running the affected application cases.
- Confirming that the selected OpenSTREAM calculations complete and
  converge as expected.
- Comparing calculated and measured quantities.
- Confirming that missing measurements are not interpreted as zeros.
- Confirming that direct measurements and derived quantities are
  distinguished.
- Reviewing generated figures and post-processing results.
- Confirming that existing application workflows are not adversely
  affected.
- Comparing results with previous approved executions, when available.

The verification procedure and its results should be described in the
pull request.

Automated testing is a planned improvement. Future tests may cover:

- Source-data parsing.
- SI-unit conversion.
- Dataset metadata.
- Required-field validation.
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
- The mandatory and dataset-specific fields.
- Confirmation that all numerical data use SI units.
- Confirmation that absolute temperatures use kelvin.
- Any unit conversions, manual transcription, character recognition,
  digitization, interpolation, filtering, reconstruction, or other data
  processing.
- Any sanity checks or consistency checks performed.
- The reported measurement uncertainties, where available.
- Known limitations, ambiguities, or missing information.
- Supported OpenSTREAM application workflows.
- A minimal reproducible usage example.
- Citation, licensing, attribution, and redistribution requirements.

User-visible changes should also be reflected in the OpenSTREAM
Applications documentation when they affect:

- The OpenSTREAM-database description.
- Available datasets.
- Publication companion workflows.
- Exported project workflows.
- Publications.
- Installation or path requirements.
- Recommended application procedures.

Commit messages
---------------

Commit messages must follow the conventions documented in the
`OpenSTREAM commit message style guide
<https://github.com/OpenSTREAM-solvers/openstream/wiki>`_.

Contributors should organize changes into focused commits. Source-data
corrections should normally be committed separately from code and
documentation changes so that their provenance and verification remain
clear in the repository history.

Submitting a contribution
-------------------------

Before submitting a contribution:

#. Confirm that OpenSTREAM and OpenSTREAM-database are both available on
   the MATLAB path.
#. Perform the relevant reproducible verification checks.
#. Run the affected application projects.
#. Review generated OpenSTREAM inputs and calculated results.
#. Confirm that all numerical source data use SI units.
#. Confirm that absolute temperatures use kelvin.
#. Review unit conversions and retained numerical precision.
#. Verify bibliographic references and dataset provenance.
#. Review applicable licensing, attribution, and redistribution
   conditions.
#. Identify one authoritative machine-readable source representation for
   each dataset package.
#. Confirm that generated outputs are not included in the commit.
#. Confirm that source PDFs and other copyrighted publications are not
   included unless redistribution is explicitly permitted.
#. Remove MATLAB autosave files, obsolete copies, generated outputs, local
   sandbox scripts, and temporary processing files.
#. Update the documentation and project exports when required.
#. Describe intentional numerical changes in the pull request.
#. Organize changes into focused commits using the required message style.

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
- The strict naming convention is followed.
- ``getSourceFilePath`` is used to locate the dataset source file.
- One authoritative machine-readable source representation is identified.
- The original experimental source is identified and cited.
- Applicable licensing and redistribution conditions have been reviewed.
- Source PDFs and other copyrighted publications are not unintentionally
  committed.
- Every implemented case defines the fields required by its supported
  workflow.
- Generic field names use the exact required spelling and capitalization.
- All mandatory and dataset-specific numerical fields use SI units.
- Absolute temperatures use kelvin.
- ``WallMesh`` and ``WallPower`` are mutually consistent.
- Dataset-specific fields are documented in the dataset README.
- Dataset-specific fields do not replace or rename mandatory fields.
- Measured, prescribed, transcribed, digitized, reconstructed, derived,
  and calculated quantities are distinguished.
- Unit conversions are documented.
- Source-data preparation methods are documented.
- Measurement uncertainties are included where available.
- Dataset assumptions and processing steps are documented.
- Relevant sanity checks and consistency checks have been performed.
- Missing numerical information is not interpreted as zero.
- The affected dataset and application workflows have been verified.
- The verification procedure and results are documented.
- Generated OpenSTREAM inputs and calculated results have been reviewed.
- Any numerical differences from previous results are understood and
  justified.
- Documentation and application projects have been updated.
- Publication companion workflows are not presented as complete research
  records.
- Generated input, result, session, and output directories are not
  committed.
- Temporary files, MATLAB autosaves, obsolete copies, local scripts, and
  processing files are not committed.
- Commit messages follow the OpenSTREAM style guide.