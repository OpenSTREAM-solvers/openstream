Application projects
====================

OpenSTREAM-database includes MATLAB Live Script projects that accompany
OpenSTREAM publications and document their principal computational
workflows.

The project source files are located in the OpenSTREAM-database
``projects`` folder:

.. code-block:: text

   projects/
   ├── NURETH21.mlx
   └── NUTHOS15_MRM.mlx

Each Live Script combines explanatory text, model selections, executable
OpenSTREAM calculations, figures, convergence information, and
interpretation.

The MATLAB Live Scripts are the authoritative executable versions of the
projects. Completed executions may also be provided as static HTML exports
that include the calculated output and figures and can be viewed without
MATLAB.

Before running a project:

- Install OpenSTREAM and OpenSTREAM-database separately and make both
  repository roots available on the MATLAB path.
- Review the associated dataset documentation and original publications.
- Review the selected cases, generated inputs, model selections, and
  numerical settings.
- Confirm that the calculations converge as documented.
- Record the OpenSTREAM and OpenSTREAM-database versions or commits used.

Further installation and configuration information is provided on the
:doc:`OpenSTREAM-database <database>` page.

OpenSTREAM-database does not currently include an automated test suite.
Project workflows are therefore verified through reproducible execution
and documented review.

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

The workflow reproduces the principal OpenSTREAM calculations presented in
the paper:

- Figures 3 and 4: comparison of the mixture, two-fluid, three-field, and
  four-field solver frameworks.
- Figure 6: validation of fully developed base-film and disturbance-wave
  properties using the ``Wurtz1978`` dataset.
- Figure 7: validation of developing disturbance-wave behavior using the
  ``Sawai1989`` dataset.

The demonstration case also illustrates the lightweight
OpenSTREAM-database workflow. The case is defined using a one-row MATLAB
table and passed directly to lightweight ``Dataset`` objects, without
requiring an XML or JSON source file.

A completed execution of the workflow is available as an HTML export:

`Open the NURETH21 companion workflow
<https://openstream-solvers.github.io/openstream/_static/html/project_NURETH21.html>`_

NUTHOS15_MRM
------------

The NUTHOS15_MRM project is provided as a MATLAB Live Script:

.. code-block:: text

   projects/NUTHOS15_MRM.mlx

The Live Script will provide a reproducible computational companion to the
corresponding NUTHOS-15 publication. It will document the OpenSTREAM
calculations used to apply and evaluate the MRM model, including the model
selections, numerical settings, figures, convergence information, and
interpretation of the results.

The completed workflow and its HTML export will be linked from this page
after they have been reviewed.