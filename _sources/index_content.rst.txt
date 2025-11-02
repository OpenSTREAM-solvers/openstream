
Welcome
=======

OpenSTREAM (**Open** **S**\olvers for **T**\wo-phase flow **R**\esearch, **E**\ngineering **A**\nalysis and **M**\odeling) is an open-source, object-oriented computational environment designed for simulating one-dimensional, multi-field, two-phase flows. It supports phenomena such as wall boiling and interfacial phase change, making it a relevant tool for researchers working in thermal-hydraulics and two-phase flow systems (:cite:t:`LeCorre2025OpenSTREAM`) (:cite:t:`LeCorre2025ICMF`). 

What's inside?
--------------

OpenSTREAM offers a suite of solver frameworks tailored to different modeling needs:

- A **mixture solver** – with thermal non-equilibrium capabilities
- A generic **two-fluid solver** – for generic separate-phase modeling
- A **three-field solver** – for annular two-phase flow
- An advanced **four-field solver** – for annular two-phase flow explicitly capturing disturbance waves (:cite:t:`LECORREMODEL`)

These solvers are designed to handle single-component, thermally expandable, steady-state and transient boiling two-phase flows in single straight channels, under a set of reasonable simplifying assumptions. Each solver comes with a set of basic closure models that can be customized by modifying the corresponding class methods in the source code.

Why OpenSTREAM?
---------------

OpenSTREAM is built to lower the barrier to entry for two-phase flow simulations and modeling. Whether you're a researcher or student, the platform supports collaborative model development, performance evaluation, and validation across institutions. It’s a flexible, extensible environment for advancing the state of the art in multiphase flow modeling.

About this documentation
------------------------

This guide will walk you through:

- The design philosophy behind OpenSTREAM
- Installation and setup instructions
- How to run simulations and interpret results
- Example applications and use cases

Looking for a printable version? You can download the full manual here: `OpenSTREAM.pdf <./files/OpenSTREAM.pdf>`_


----

.. bibliography:: 
   :filter: docname in docnames
   :style: plain

----

