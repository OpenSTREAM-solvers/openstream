Release numbering and versioning
================================

OpenSTREAM uses a hybrid calendar-based and semantic version-numbering
scheme. Release identifiers have the following general form:

.. code-block:: text

   vYYYY.N

where ``YYYY`` identifies the release year and ``N`` identifies the
successive release within that year.

Examples include:

* ``v2026.0``: the first principal OpenSTREAM release associated with 2026;
* ``v2026.1``: a subsequent OpenSTREAM update released in 2026;
* ``v2026.1-alpha``: a prerelease associated with the planned
  ``v2026.1`` release.

Principal releases are intended to collect significant code, model,
interface, testing, and documentation changes. The project aims to publish
principal releases at an approximately six-month cadence when justified by
the accumulated changes. Additional releases may be published as needed.

Prerelease identifiers
----------------------

A suffix may be added when a release is made available before its final
publication. For example:

.. code-block:: text

   v2026.1-alpha

identifies an alpha prerelease associated with ``v2026.1``.

Prerelease versions may contain incomplete, experimental, or insufficiently
validated features. They should not be interpreted as stable releases.

Release documentation
---------------------

Each released OpenSTREAM version should be accompanied by release notes
summarizing, as applicable:

* new solver and physical-model capabilities;
* corrections to existing implementations;
* changes to input parameters or default values;
* numerical-method changes;
* documentation and tutorial updates;
* tested MATLAB, Python, and CoolProp configurations;
* known limitations;
* migration information for existing input files or user-developed models.

Development and released versions
---------------------------------

The development version may contain changes that are not available in the
latest released version. Users should verify that the documentation,
tutorials, and source code correspond to the same OpenSTREAM version or
source revision.

When citing, distributing, or reproducing an OpenSTREAM calculation, record
the release identifier or source revision used for the calculation.