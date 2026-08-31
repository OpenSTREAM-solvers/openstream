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

The package components have the following roles:

``+src``
   Contains the XML or JSON source-data representation. All numerical data
   stored in these files must use SI units.

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
   uncertainty, assumptions, processing, usage, and limitations.

The dataset-specific class should inherit from the generic ``Dataset``
class and use the shared dataset interface where practical.

Dataset template
----------------

OpenSTREAM-database includes a ``+Template`` folder that provides the
starting structure for a new dataset implementation.

The template contains:

- An empty ``+src`` folder for the XML or JSON source-data file.
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
   ├── @Template/
   │   ├── Template.m
   │   └── plotResults.m
   └── README.md

To begin implementing a new dataset:

#. Copy the complete ``+Template`` folder.
#. Select a valid dataset name following the naming convention described
   below.
#. Rename the package folder, class folder, and MATLAB class file
   consistently.
#. Update the class definition, ``addPath`` method, comments, and
   documentation.
#. Add the corresponding XML or JSON source-data file under ``+src``.
#. Add all mandatory fields to every implemented experimental case.
#. Add and document any required dataset-specific fields.
#. Complete the dataset-specific properties and methods.
#. Complete the dataset README using the template headings.
#. Implement dataset-specific result plotting where applicable.
#. Verify the dataset implementation and associated application workflow.

The template supplies the expected structure and documentation
placeholders. Contributors remain responsible for completing and verifying
all dataset-specific source data, metadata, methods, assumptions, unit
conversions, uncertainties, plotting functionality, and application
workflows.

Naming convention
-----------------

Dataset packages follow a strict naming convention. The package folder,
class folder, class file, class definition, dataset name, and source-data
path must use consistent names.

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
   * - Source-data path
     - ``+AuthorYear/+src/AuthorYear.xml``

The leading ``+`` and ``@`` characters are part of MATLAB package and
class-folder syntax:

- ``+AuthorYear`` defines the MATLAB package.
- ``@AuthorYear`` defines the class folder within that package.
- ``AuthorYear.m`` contains the class definition.
- The class is referenced using the package-qualified name
  ``AuthorYear.AuthorYear``.

Names and capitalization must be consistent. Do not mix forms such as
``AuthorYear``, ``Authoryear``, and ``authoryear``.

For publication-based datasets, the package name should generally combine
the surname of the first author and the four-digit publication year,
following the convention used by the existing dataset packages.

The dataset name must be a valid MATLAB identifier. Spaces, hyphens,
punctuation, and other invalid identifier characters must not be used.

When copying the template, update every occurrence of ``Template`` in:

#. The package-folder name.
#. The class-folder name.
#. The class filename.
#. The ``classdef`` declaration.
#. ``data.name`` in ``addPath``.
#. The source-data filename.
#. ``data.path`` in ``addPath``.
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

               data.path = fullfile( ...
                   ['+' data.name], ...
                   '+src', ...
                   'AuthorYear.xml');

           end

           plotResults(data)

       end

   end

The resulting object is constructed using the package-qualified class
name:

.. code-block:: matlab

   dataset = AuthorYear.AuthorYear(...);

A mismatch between these names may prevent MATLAB from locating the class
or may cause the dataset implementation to reference the wrong source-data
file.

Source data
-----------

Dataset source files are stored under the package ``+src`` directory.

All numerical data stored in OpenSTREAM-database source files must use SI
units. This requirement applies even when the original experimental
publication reports data using another system of units.

The source-data implementation should preserve the original experimental
information as faithfully as possible. Any transcription, correction,
digitization, filtering, interpolation, reconstruction, or unit conversion
must be documented.

The dataset-specific constructor reads and interprets the corresponding
XML or JSON source file when the dataset object is created. Reading the
source file is therefore part of dataset-object construction and is not a
separate step in the application workflow.

Dataset fields
--------------

Each experimental case in the XML or JSON source file must define a common
set of mandatory fields. Additional dataset-specific fields may be added
when required to represent the available experimental information.

Mandatory fields
~~~~~~~~~~~~~~~~

The following fields are required for every implemented experimental case:

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
     - Axial coordinates associated with the wall-power and heat-flux
       distributions.
     - m
   * - ``WallPower``
     - Axial wall-power distribution.
     - W

Field names are case-sensitive and must be written exactly as shown.

The mandatory fields must satisfy the following requirements:

- Every implemented case must define all mandatory fields.
- All numerical values must use SI units.
- ``Fluid`` must use an identifier supported by the OpenSTREAM
  fluid-property interface.
- ``WallMesh`` must be consistent with the corresponding ``WallPower``
  distribution.
- Geometry fields must represent the channel modeled by OpenSTREAM.
- Boundary-condition fields must represent the intended experimental case.
- Any conversion, reconstruction, or interpretation used to obtain a
  mandatory field must be documented in the dataset README.

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

Each dataset-specific field must be documented in the dataset README. The
documentation should state:

- The exact field name.
- The physical meaning of the field.
- Whether the field is required or optional.
- The SI unit used in OpenSTREAM-database.
- The unit reported in the original experimental source.
- The source table, figure, page, appendix, or data file.
- Any unit conversion or other processing applied.
- The reported measurement uncertainty, where available.
- The behavior when the field is absent or unavailable.

Dataset-specific fields must not replace, rename, or change the meaning of
the mandatory fields.

When the same physical quantity is used by several dataset
implementations, a common field name and representation should be used
where practical.

Source-file requirements
~~~~~~~~~~~~~~~~~~~~~~~~

The XML or JSON source representation should use a consistent structure
across all implemented cases.

Before completing a dataset implementation, confirm that:

- Every case contains all mandatory fields.
- Mandatory and dataset-specific field names are used consistently.
- Numerical fields contain valid SI values.
- Array dimensions are mutually consistent.
- ``WallMesh`` and ``WallPower`` describe compatible axial distributions.
- Case identifiers are unique.
- Missing experimental information is identified explicitly.
- Undocumented replacement values are not introduced.
- Derived or reconstructed fields are documented.
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
- The units reported in the original source.
- The SI units used in OpenSTREAM-database.
- The reported measurement uncertainties.
- Known limitations or qualifications of the data.
- The relationship between the original data and the implemented
  source-data files.
- Any licensing, redistribution, attribution, or citation requirements.

The original publication remains the authoritative source for the
experimental configuration, measurements, uncertainties, and
interpretation.

The OpenSTREAM-database implementation must not imply greater accuracy,
completeness, or certainty than is supported by the published information.

Dataset class
-------------

The dataset-specific MATLAB class should:

- Inherit from the generic ``Dataset`` class.
- Read and interpret the corresponding source-data representation during
  object construction.
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

Dataset implementations and application projects should rely on the
required OpenSTREAM classes being available on the MATLAB path. They
should not assume a fixed relative directory arrangement between the two
repositories.

Installation and MATLAB path instructions are provided on the
:doc:`OpenSTREAM-database <database>` page.

Application projects
--------------------

Application projects are stored under the repository ``projects`` folder.

A contributed project should provide a reproducible workflow for:

#. Constructing a dataset-specific object, which reads and interprets the
   corresponding XML or JSON source file.
#. Selecting one or more experimental cases.
#. Selecting an OpenSTREAM solver and model configuration.
#. Generating the required OpenSTREAM input files.
#. Running the selected cases.
#. Extracting calculated and measured quantities.
#. Comparing the results.
#. Visualizing and interpreting the comparison.
#. Documenting assumptions, numerical settings, and limitations.

Projects should avoid hard-coded local paths and should state the expected
working directory or path configuration clearly.

MATLAB Live Scripts are recommended when explanatory text, executable
code, figures, and calculated results form part of the documented
application workflow.

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
- Distinguish solvers and model configurations consistently.
- Represent experimental uncertainty when available and relevant.
- Avoid implying agreement beyond the precision or uncertainty of the
  available data.
- Support reproducible use from the corresponding application project.

Common plotting or comparison behavior should be implemented in shared
functionality where practical.

Testing and verification
------------------------

OpenSTREAM-database does not currently include an automated test suite.

Until automated testing is implemented, contributors should verify changes
using reproducible checks appropriate to the contribution.

These checks should include, where applicable:

- Confirming that the source-data files can be loaded correctly.
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
- Comparing results with previous executions, when available.

The verification procedure and its results should be described in the
pull request.

Automated testing is a planned improvement. Future tests may cover:

- Source-data parsing.
- SI-unit conversion.
- Dataset metadata.
- Mandatory-field validation.
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
#. Run the affected application projects.
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
- The strict naming convention is followed.
- The original experimental source is identified and cited.
- Applicable licensing and redistribution conditions have been reviewed.
- Every implemented case defines all mandatory dataset fields using the
  exact required names.
- All mandatory and dataset-specific numerical fields use SI units.
- ``WallMesh`` and ``WallPower`` are mutually consistent.
- Dataset-specific fields are documented in the dataset README.
- Dataset-specific fields do not replace or rename mandatory fields.
- Unit conversions are documented.
- Measurement uncertainties are included where available.
- Dataset assumptions and processing steps are documented.
- The affected dataset and application workflows have been verified.
- The verification procedure and results are documented.
- Generated OpenSTREAM inputs and calculated results have been reviewed.
- Any numerical differences from previous results are understood and
  justified.
- Documentation and application projects have been updated.
- Generated input, result, and output directories are not committed.