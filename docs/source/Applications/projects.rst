Application projects
====================

OpenSTREAM-database includes MATLAB Live Script projects that accompany
selected OpenSTREAM publications and illustrate the principal computational
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

NURETH-21
---------

The ``NURETH21.mlx`` Live Script is a reproducible computational companion
to the NURETH-21 OpenSTREAM publication :cite:p:`LeCorre2025OpenSTREAM`.

The workflow reproduces selected calculations and results from the paper:

- Figures 3 and 4: comparison of the four OpenSTREAM solver frameworks.
- Figure 6: fully developed base-film and disturbance-wave validation using
  ``Wurtz1978``.
- Figure 7: developing disturbance-wave validation using ``Sawai1989``.

`Open the completed NURETH21 companion workflow
<https://openstream-solvers.github.io/openstream/_static/html/project_NURETH21.html>`_


NUTHOS-15 MRM
-------------

The ``NUTHOS15_MRM.mlx`` Live Script is a reproducible computational
companion to the NUTHOS-15 publication introducing the Mixture Relaxation
Model :cite:p:`LeCorre2026MRM`.

The workflow reproduces selected calculations and results from the paper:

- Figures 1 and 2: MRM results for two ``Bartolomey`` subcooled-boiling
  cases.
- Figure 3: comparison with thermal-equilibrium and frozen limits.
- Figures 4 to 6: MRM results and limiting-model comparisons for two
  ``Becker1983`` post-boiling-transition cases.

`Open the completed NUTHOS15_MRM companion workflow
<https://openstream-solvers.github.io/openstream/_static/html/project_NUTHOS15_MRM.html>`_

----

OpenSTREAM-database does not currently include an automated test suite.
Project workflows are therefore verified through reproducible execution,
review of convergence, and documented comparison of calculated and
experimental quantities.
