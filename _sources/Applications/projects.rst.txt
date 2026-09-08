Application projects
====================

OpenSTREAM-database includes application projects that demonstrate how
the implemented experimental datasets can be used with OpenSTREAM.

The project source files are located in the OpenSTREAM-database
``projects`` folder:

.. code-block:: text

   projects/
   ├── Adamsson.m
   ├── Bennett.mlx
   ├── Groeneveld.m
   ├── NURETH21.m
   ├── Sawai.m
   └── Wurtz.m

The projects are provided as MATLAB scripts or Live Scripts. As the
projects are developed, reviewed, and documented, Live Script projects
may be exported to HTML and made available from this page.

Before running a project, install OpenSTREAM and OpenSTREAM-database
separately and make both repository roots available on the MATLAB path.
Further information is provided on the
:doc:`OpenSTREAM-database <database>` page.

Available projects
------------------

1. Adamsson
~~~~~~~~~~~

The Adamsson project uses the dataset implementation provided by the
``Adamsson2006`` package.

The project source is available as a MATLAB script:

.. code-block:: text

   projects/Adamsson.m

The corresponding dataset package contains:

.. code-block:: text

   +Adamsson2006/
   ├── +src/
   │   └── Adamsson2006.xml
   ├── @Adamsson2006/
   │   ├── Adamsson2006.m
   │   └── plotResults.m
   └── README.md

Consult the dataset README for information about the experimental source,
implemented data, and available application cases.

2. Bennett
~~~~~~~~~~

The Bennett project uses the dataset implementation provided by the
``Bennett1967`` package.

The project source is available as a MATLAB Live Script:

.. code-block:: text

   projects/Bennett.mlx

The corresponding dataset package contains:

.. code-block:: text

   +Bennett1967/
   ├── +src/
   │   └── Bennett1967.xml
   ├── @Bennett1967/
   │   ├── Bennett1967.m
   │   └── plotResults.m
   └── README.md

An exported HTML version will be added to this section when the Live Script
has been sufficiently developed, reviewed, and documented.

Consult the dataset README for information about the experimental source,
implemented data, and available application cases.

3. Groeneveld
~~~~~~~~~~~~~

The Groeneveld project uses the dataset implementation provided by the
``Groeneveld2019`` package.

The project source is available as a MATLAB script:

.. code-block:: text

   projects/Groeneveld.m

The corresponding dataset package contains:

.. code-block:: text

   +Groeneveld2019/
   ├── +src/
   │   ├── Blind.xml
   │   └── Groeneveld2019.xml
   ├── @Groeneveld2019/
   │   ├── Groeneveld2019.m
   │   └── plotResults.m
   └── README.md

Consult the dataset README for information about the experimental source,
the purpose of the available source-data files, implemented data, and
available application cases.

4. NURETH21
~~~~~~~~~~~

The NURETH21 project is available as a MATLAB script:

.. code-block:: text

   projects/NURETH21.m

The detailed scope of this project, including its relationship with the
implemented dataset packages, should be described when the project is
reviewed and documented.

4. NURETH21
~~~~~~~~~~~

The NURETH21 project is provided as a MATLAB Live Script:

.. cod~~block:: text

   projects/NURETH21.mlx

The Live Script is a reproducible computational companion to the NURETH-21
publication :cite:p:`Lecorre2025OpenSTREAM`. It combines explanatory text,
model selections, executable OpenSTREAM calculations,figures, convergence
information, and interpretation in a single interactive document.

The workflow reproduces the principal OpenSTREAM calculations presented in
the paper:

- Figures 3 and 4: comparison of the mixture, two-fluid, three-field, and
  four-field solver frameworks.
- Figure 6: validation of fully developed base-film and disturbance-wave
  properties using the ``Wurtz1978`` dataset.
- Figure 7: validation of developing disturbance-wave behaviors

A completed execution of the Live Script, including the calculated output
and figures, is available as an HTML export:

`Open the NURETH21 companion workflow
<https://openstream-solvers.github.io/openstream/_static/html/project_NURETH21.html>`_

The MATLAB Live Script remains the authoritative executable version. The
HTML export provides a static record of the completed calculations and
does not require MATLAB to view.

5. Sawai
~~~~~~~~

The Sawai project uses the dataset implementation provided by the
``Sawai1989`` package.

The project source is available as a MATLAB script:

.. code-block:: text

   projects/Sawai.m

The corresponding dataset package contains:

.. code-block:: text

   +Sawai1989/
   ├── +src/
   │   └── Sawai1989.xml
   ├── @Sawai1989/
   │   ├── Sawai1989.m
   │   └── plotResults.m
   └── README.md

Consult the dataset README for information about the experimental source,
implemented data, and available application cases.

6. Wurtz
~~~~~~~~

The Wurtz project uses the dataset implementation provided by the
``Wurtz1978`` package.

The project source is available as a MATLAB script:

.. code-block:: text

   projects/Wurtz.m

The corresponding dataset package contains:

.. code-block:: text

   +Wurtz1978/
   ├── +src/
   │   ├── Wurtz1978.xml
   │   └── Wurtz1978HL.xml
   ├── @Wurtz1978/
   │   ├── Wurtz1978.m
   │   └── plotResults.m
   └── README.md

Consult the dataset README for information about the experimental source,
the purpose of the available source-data files, implemented data, and
available application cases.

HTML exports
------------

MATLAB Live Script projects may be exported to HTML after the workflows
have been developed and reviewed.

An exported HTML project provides a static representation of the Live
Script, including its explanatory text, code, calculated output, and
figures. Interactive figures, animations, controls, and other Live Editor
features may not be preserved in the exported version.

The MATLAB source files in OpenSTREAM-database remain the authoritative
executable versions of the projects.

Project status
--------------

The application projects are under development. Their current levels of
documentation, completeness, and verification may differ.

Before using a project for application or validation work:

- Review the corresponding dataset README.
- Consult the original experimental publication.
- Inspect the selected cases and generated OpenSTREAM inputs.
- Review the solver and model configuration.
- Verify that the project runs in the documented environment.
- Review calculated and experimental quantities before interpreting the
  comparison.

OpenSTREAM-database does not currently include an automated test suite.
Project workflows should therefore be verified through reproducible
execution and documented review.