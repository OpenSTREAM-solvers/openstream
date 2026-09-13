Application projects
====================

OpenSTREAM-database includes MATLAB Live Script projects that accompany
OpenSTREAM publications and illustrate the principal computational
workflows and selected results presented in those publications.

The project source files are located in the OpenSTREAM-database
``projects`` folder:

.. code-block:: text

   projects/
   ├── NURETH21.mlx
   └── NUTHOS15_MRM.mlx

Each Live Script combines explanatory text, model selections, executable
OpenSTREAM calculations, convergence information, figures, and
interpretation. The objective is to provide a transparent and reproducible
workflow for the selected calculations and results presented in the
corresponding publication.

The companion workflows do not represent the complete research activities
supporting the publications. Model development and qualification generally
involve additional experimental cases, closure-model evaluations,
sensitivity studies, numerical investigations, and intermediate analyses
that are not included in the published figures or companion Live Scripts.

The MATLAB Live Scripts are the authoritative executable versions of the
published companion workflows. Completed executions may also be provided
as static HTML exports containing the calculated output and figures. The
HTML exports can be viewed without MATLAB, although interactive Live
Editor features may not be preserved.

Before running or extending a project:

- Install OpenSTREAM and OpenSTREAM-database separately and make both
  repository roots available on the MATLAB path.
- Review the corresponding publication and associated dataset
  documentation.
- Review the selected experimental cases and generated OpenSTREAM inputs.
- Review the physical-model and numerical-option selections.
- Confirm that the calculations converge as documented.
- Distinguish direct experimental measurements from derived quantities.
- Record the OpenSTREAM and OpenSTREAM-database versions or commits used.

Further installation and configuration information is provided on the
:doc:`OpenSTREAM-database <database>` page.

For calculations used in publications or technical reports, follow the
:doc:`reproducibility guidance <../Guides/scope_and_limitations>`.

OpenSTREAM-database does not currently include an automated test suite.
Project workflows are therefore verified through reproducible execution,
review of convergence, and documented comparison of calculated and
experimental quantities.

NURETH21
--------

The NURETH21 project is provided as a MATLAB Live Script:

.. code-block:: text

   projects/NURETH21.mlx

The Live Script is a reproducible computational companion to the
NURETH-21 publication:

.. bibliography::
   :filter: False

   LeCorre2025OpenSTREAM

The workflow reproduces selected OpenSTREAM calculations and results
presented in the paper:

- Figures 3 and 4: comparison of the mixture, two-fluid, three-field, and
  four-field solver frameworks.
- Figure 6: validation of fully developed base-film and disturbance-wave
  properties using the ``Wurtz1978`` dataset.
- Figure 7: validation of developing disturbance-wave behavior using the
  ``Sawai1989`` dataset.

The demonstration case also illustrates the lightweight
OpenSTREAM-database workflow. The geometry, boundary conditions, and
heating conditions are defined in a one-row MATLAB table and passed
directly to lightweight ``Dataset`` objects. No XML or JSON source-data
file is required.

The validation calculations use the dataset packages to select
experimental cases, generate OpenSTREAM inputs, run the FourField solver,
check convergence, and compare calculated and measured annular-flow
properties.

The Live Script focuses on the calculations required to illustrate the
figures and conclusions presented in the publication. It does not include
all cases, model-development activities, closure-model evaluations,
sensitivity studies, or numerical investigations performed during the
underlying research.

Figure 5 is not reproduced because the TRACE reference results required
for that comparison are not included in the companion workflow.

A completed execution of the workflow is available as an HTML export:

`Open the completed NURETH21 companion workflow
<https://openstream-solvers.github.io/openstream/_static/html/project_NURETH21.html>`_

NUTHOS15_MRM
------------

The NUTHOS15_MRM project is provided as a MATLAB Live Script:

.. code-block:: text

   projects/NUTHOS15_MRM.mlx

The Live Script is a reproducible computational companion to the
NUTHOS-15 publication:

.. bibliography::
   :filter: False

   LeCorre2026MRM

The workflow reproduces OpenSTREAM calculations and results presented in
the paper:

- Figures 1 and 2: detailed Mixture Relaxation Model results for two
  subcooled-boiling cases from the ``Bartolomey`` dataset.
- Figure 3: comparison of the Mixture Relaxation Model with the thermal-
  equilibrium and frozen limits for the selected subcooled-boiling cases.
- Figures 4 and 5: detailed Mixture Relaxation Model results for two
  post-boiling-transition cases from the ``Becker1983`` dataset.
- Figure 6: comparison of the Mixture Relaxation Model with the thermal-
  equilibrium and frozen limits for the selected post-boiling-transition
  cases.

The subcooled-boiling calculations use measured void-fraction data from
the ``Bartolomey`` dataset to assess the relaxation-based representation
of vapor generation, condensation, and thermal nonequilibrium.

The post-boiling-transition calculations use measured wall-temperature
data and boiling-transition elevations from the ``Becker1983`` dataset to
assess the relaxation-based representation of vapor superheating,
interfacial exchange, and post-transition wall heat transfer.

For both applications, the Mixture Relaxation Model is compared with two
limiting thermal treatments:

- the thermal-equilibrium limit, in which the phases remain at the same
  temperature;
- the frozen limit, in which interfacial thermal relaxation is strongly
  suppressed.

The effective vapor and liquid characteristic lengths used by the
relaxation models are calibrated model parameters. They represent lumped
interfacial exchange scales and should not be interpreted as direct
measurements of bubble or droplet diameters.

The Live Script focuses on the calculations required to illustrate the
figures and conclusions presented in the publication. It does not include
all cases, model-development activities, parameter evaluations,
sensitivity studies, or numerical investigations performed during the
underlying research.

A completed execution of the workflow is available as an HTML export:

`Open the completed NUTHOS15_MRM companion workflow
<https://openstream-solvers.github.io/openstream/_static/html/project_NUTHOS15_MRM.html>`_
