Release numbering and versioning
================================

OpenSTREAM uses a hybrid calendar-based and semantic version-numbering
scheme. Release identifiers have the following general form:

.. code-block:: text

   vYYYY.N

where ``YYYY`` identifies the release year and ``N`` identifies the
successive release within that year.

Examples include:

- ``v2026.0``: the first principal OpenSTREAM release associated with
  2026.
- ``v2026.1``: a subsequent OpenSTREAM release published in 2026.
- ``v2026.1-alpha``: an alpha prerelease associated with the planned
  ``v2026.1`` release.

Principal releases collect reviewed code, model, interface, testing, and
documentation changes. Releases are published when justified by the
accumulated changes rather than according to a fixed schedule.

Release identifiers
-------------------

The release-year component identifies when a version is published. It does
not indicate the validity range of the implemented physical models or the
software environment required to run the release.

The successive-release component is incremented when an additional release
is published within the same year.

The version number does not by itself distinguish among feature,
correction, documentation, or compatibility releases. The nature and scope
of a release are described in its release notes.

Prerelease identifiers
----------------------

A suffix may be added when a version is made available before its final
release. For example:

.. code-block:: text

   v2026.1-alpha

identifies an alpha prerelease associated with the planned ``v2026.1``
release.

Prerelease identifiers may include:

``alpha``
   Identifies an early prerelease that may contain incomplete,
   experimental, or insufficiently tested functionality.

``beta``
   Identifies a prerelease whose principal functionality is available but
   may still require broader testing and correction.

``rc``
   Identifies a release candidate intended for final verification before
   publication of the corresponding stable release.

A numerical suffix may be added when several prereleases of the same type
are published:

.. code-block:: text

   v2026.1-alpha.1
   v2026.1-beta.1
   v2026.1-rc.1

Prerelease versions must not be interpreted as stable releases. Their
interfaces, defaults, numerical behavior, documentation, and reference
solutions may change before the corresponding final release.

Stable and development versions
-------------------------------

A tagged release without a prerelease suffix is considered a stable
OpenSTREAM release.

The development branch may contain changes that are not available in the
latest stable release. These changes may include:

- New or modified solver capabilities.
- New physical and closure models.
- Changes to input parameters or accepted values.
- Changes to default models or numerical options.
- Corrections affecting calculated results.
- Changes to saved-object formats.
- Updated tests and numerical reference solutions.
- Documentation for functionality not available in the latest release.

Users working from a development branch should record the complete Git
commit identifier rather than referring only to the branch name. A branch
name can refer to different source revisions over time, whereas a commit
identifier identifies a specific repository state.

The active source revision can be obtained using:

.. code-block:: bash

   git rev-parse HEAD

A concise source description can be obtained using:

.. code-block:: bash

   git describe --tags --always --dirty

The ``dirty`` suffix indicates that the working tree contains local changes
that are not included in the identified commit. Results obtained from a
modified working tree should be reported accordingly.

Release documentation
---------------------

Each released OpenSTREAM version should be accompanied by release notes
summarizing, as applicable:

- New solver and physical-model capabilities.
- Corrections to existing implementations.
- Changes to governing equations or closure relations.
- Changes to input parameters or accepted values.
- Changes to default physical models or numerical options.
- Numerical-method changes.
- Changes affecting calculated results.
- Changes to saved solver objects or persisted results.
- Added or modified automated tests.
- Changes to approved numerical reference solutions.
- Documentation and tutorial updates.
- Tested MATLAB, Python, and CoolProp configurations.
- Known limitations and unresolved issues.
- Migration information for existing input files or user-developed
  models.
- Compatibility considerations for OpenSTREAM-database.

A correction that changes numerical results should be identified
explicitly. The release notes should distinguish intentional physical or
numerical changes from differences caused only by formatting,
documentation, or repository maintenance.

Compatibility status
--------------------

OpenSTREAM depends on MATLAB and, for thermophysical properties, a
compatible Python and CoolProp environment.

Compatibility information should distinguish among:

``Tested``
   The configuration is exercised by automated continuous integration or
   by a documented release-verification procedure.

``Supported``
   The configuration is expected to be usable and is within the intended
   support range, although every combination of functionality may not be
   exercised automatically.

``Untested``
   The configuration has not been included in the documented verification
   process. It may work, but compatibility has not been established.

``Incompatible``
   The configuration is known not to satisfy the OpenSTREAM requirements
   or to produce a documented compatibility failure.

Absence from the tested configuration matrix should be interpreted as
untested rather than automatically incompatible.

Tested configurations
---------------------

Each release should identify the MATLAB, Python, and CoolProp
configurations included in its verification process.

The compatibility table should be maintained with the released
documentation using the following structure:

.. list-table::
   :header-rows: 1
   :widths: 18 18 18 18 28

   * - OpenSTREAM version
     - MATLAB
     - Python
     - CoolProp
     - Status
   * - Current release
     - See release notes
     - See release notes
     - See release notes
     - Tested configurations are listed with the release

The release notes and continuous-integration configuration are the
authoritative sources for the combinations tested for a particular
release.

A successful test result for one MATLAB, Python, and CoolProp combination
does not establish compatibility for every possible combination of those
components.

Inspecting the active environment
---------------------------------

Users should record the software environment used for calculations that
support publications, technical reports, validation studies, or numerical
reference solutions.

The MATLAB version can be displayed using:

.. code-block:: matlab

   version

The complete MATLAB product information can be displayed using:

.. code-block:: matlab

   ver

The Python environment selected by MATLAB can be inspected using:

.. code-block:: matlab

   pyenv

The Python version can be displayed using:

.. code-block:: matlab

   py.sys.version

The active CoolProp version can be displayed using:

.. code-block:: matlab

   py.CoolProp.CoolProp.get_global_param_string('version')

The reported environment should include, as applicable:

- OpenSTREAM release or Git commit.
- MATLAB release.
- Python version.
- CoolProp version.
- Operating system.
- OpenSTREAM-database release or Git commit.
- Local modifications affecting the calculation.

Continuous integration
----------------------

OpenSTREAM uses continuous integration to exercise selected software
environments and run the available automated test suite.

The continuous-integration configuration provides evidence for the tested
combinations associated with the corresponding source revision. It does
not demonstrate compatibility with configurations that are not included in
the workflow.

The automated tests also do not exercise every:

- Solver path.
- Physical or closure model.
- Input combination.
- Transient application.
- Error condition.
- Post-processing capability.
- MATLAB, Python, and CoolProp combination.

A successful continuous-integration run therefore confirms that the
implemented tests passed in the tested environments. It does not constitute
complete verification or validation of OpenSTREAM.

OpenSTREAM-database compatibility
---------------------------------

OpenSTREAM and OpenSTREAM-database are maintained as separate repositories.

An OpenSTREAM-database calculation should use an OpenSTREAM version
compatible with the dataset classes, project workflows, input fields, and
solver interfaces used by the calculation.

Publication and validation workflows should record both repository
versions or commits:

.. code-block:: text

   OpenSTREAM:          <release or commit>
   OpenSTREAM-database: <release or commit>

A project that runs with the current development versions of both
repositories may not run unchanged with an earlier release if public
interfaces, input options, result structures, or model identifiers have
changed.

When compatibility between specific releases is important, the compatible
OpenSTREAM and OpenSTREAM-database versions should be identified in the
project documentation or release notes.

Saved objects and persisted results
-----------------------------------

Saved solver objects and persisted result structures can depend on the
OpenSTREAM, MATLAB, Python, and CoolProp versions used to create them.

Changes to any of the following can affect compatibility:

- MATLAB class definitions.
- Property names and access rules.
- Enumeration values.
- Result-object organization.
- Input-object organization.
- Python object references.
- CoolProp interfaces.
- Serialization behavior.

Saved objects should not be treated as the only reproducibility record for
a calculation.

For long-term reproducibility, retain:

- The original input files or dataset records.
- The solver and model selections.
- Nondefault model parameters.
- Numerical options.
- The OpenSTREAM version or commit.
- The OpenSTREAM-database version or commit, when applicable.
- The MATLAB, Python, and CoolProp versions.
- The script or Live Script required to regenerate the result.

When loading objects created with an earlier version, review the resulting
warnings and verify that the object structure and calculated quantities
remain consistent with the current implementation.

Backward compatibility
----------------------

OpenSTREAM aims to preserve existing user workflows where practical.
However, backward compatibility is not guaranteed for every development or
prerelease revision.

An incompatible change may be necessary when:

- Correcting an erroneous implementation.
- Improving an established public interface.
- Replacing an ambiguous input convention.
- Changing a model formulation.
- Updating a dependency interface.
- Restructuring saved results or solver objects.
- Removing obsolete functionality.

Incompatible changes should be documented in the release notes together
with migration guidance where practical.

Deprecation
-----------

Functionality intended for removal should, where practical, be deprecated
before being removed from a stable release.

A deprecation notice should identify:

- The deprecated functionality.
- The recommended replacement.
- Any required migration steps.
- The release in which the deprecation is introduced.
- The planned removal release, when known.

Users should update deprecated workflows before relying on a later
OpenSTREAM release.

Reproducibility
---------------

When citing, distributing, or reproducing an OpenSTREAM calculation,
record the release identifier or complete source revision used for the
calculation.

For reported numerical results, also record:

- The OpenSTREAM-database version or commit, when used.
- The MATLAB version.
- The Python version.
- The CoolProp version.
- The selected solver framework.
- The input files, identifiers, dataset records, or in-memory case
  definition.
- The selected physical and closure models.
- Nondefault model parameters.
- Numerical options.
- Mesh and time-step settings.
- Convergence criteria and final convergence status.
- Post-processing procedures.
- Any local source modifications.

A release identifier is preferable when the calculation uses an unmodified
stable release. A complete Git commit should be reported when the
calculation uses a development revision or a commit that is not associated
with a release.

The wider reproducibility requirements for reported calculations are
described in the :doc:`Intended scope and limitations
<Guides/scope_and_limitations>` page.

Citing a release
----------------

A publication should cite the relevant OpenSTREAM publication and identify
the software release or source revision used.

A release-based statement can use the following form:

.. code-block:: text

   Calculations were performed using OpenSTREAM vYYYY.N.

A development-revision statement can use:

.. code-block:: text

   Calculations were performed using OpenSTREAM commit <commit-id>.

When OpenSTREAM-database is used, identify its release or commit
separately.

The repository release archive or assigned persistent identifier should be
used when available so that the cited software version remains findable.

Migration between versions
--------------------------

Before reproducing an earlier calculation using a newer OpenSTREAM
version:

#. Review the release notes for every intervening release.
#. Identify changes to inputs, defaults, models, numerical methods, and
   result structures.
#. Confirm that the original physical-model configuration remains
   available.
#. Regenerate the OpenSTREAM inputs from the authoritative source.
#. Run the calculation using the documented numerical settings.
#. Confirm convergence.
#. Compare the new and original calculated results.
#. Investigate and document any numerical differences.

Updating a calculation to a newer software version creates a new
computational result. Agreement with the earlier result should be checked
rather than assumed.

Development and release responsibilities
----------------------------------------

Before publishing a release, maintainers should:

- Confirm that the intended source revision is identified by the release
  tag.
- Run the complete available automated test suite.
- Review continuous-integration results.
- Build and review the HTML documentation.
- Build and review the PDF documentation.
- Confirm that documentation corresponds to the released source.
- Review dependency and compatibility information.
- Review changes to approved numerical reference solutions.
- Prepare release notes.
- Document known limitations and migration requirements.
- Confirm that generated outputs and temporary files are not included.
- Confirm that the release archive contains the required licensing and
  citation information.

Users should rely on the released documentation corresponding to the
selected version rather than assuming that the current online
documentation describes an earlier release.