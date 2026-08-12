
Welcome
=======

OpenSTREAM (**Open** **S**\olvers for **T**\wo-phase flow **R**\esearch, **E**\ngineering **A**\nalysis and **M**\odeling) is an open-source, object-oriented computational environment designed for simulating one-dimensional, multi-field, two-phase flows in straight geometries (:cite:t:`LeCorre2025OpenSTREAM`) (:cite:t:`LeCorre2025ICMF`). It supports phenomena such as wall boiling, phase interactions and non-equilibrium effects, making it a relevant tool for researchers working in thermal-hydraulics and two-phase flow systems. 

What's inside?
--------------

OpenSTREAM offers a suite of solver frameworks tailored to different modeling needs:

- A **mixture solver** – with thermal non-equilibrium capabilities
- A generic **two-fluid solver** – for generic separate-phase modeling
- A **three-field solver** – for annular two-phase flow
- An advanced **four-field solver** – for annular two-phase flow explicitly capturing disturbance waves

These solvers are designed to simulate single-component, thermally expandable, steady-state and transient boiling two-phase flows in straight multi-wall channels, which may be uniformly or non-uniformly heated. The implementation relies on a set of reasonable simplifying assumptions to ensure computational efficiency and stability. Each solver includes a set of baseline closure models, which can be customized by modifying the corresponding class methods in the source code.

Why OpenSTREAM?
---------------

OpenSTREAM is built to support open, transparent research and to lower the barrier to entry for developing and validating fundamental models in two-phase flow simulations. Its goal is to make advanced thermal-hydraulic modeling more accessible to engineers, scientists, and students alike. Whether you're conducting research or learning the fundamentals, OpenSTREAM provides a collaborative and extensible environment for model development, performance evaluation, and cross-institutional validation, advancing the state of the art in thermal-hydraulic simulation.

Links
-----
 
OpenSTREAM is developed openly on GitHub:

- **Source code:** `OpenSTREAM-solvers/openstream <https://github.com/OpenSTREAM-solvers/openstream>`_
- **Report an issue:** `Issue tracker <https://github.com/OpenSTREAM-solvers/openstream/issues>`_
- **Contribute:** see the :doc:`Community </Community/index>` section

About this documentation
------------------------

This guide will walk you through:

- Installation and setup instructions
- The design philosophy behind OpenSTREAM
- How to run simulations and interpret results
- Example applications and use cases
- How to contribute

.. only:: html

   Looking for a printable version? You can download the full documentation here: `OpenSTREAM.pdf <./files/OpenSTREAM.pdf>`_


----

.. bibliography:: 
   :list: enumerated
   :filter: docname in docnames
