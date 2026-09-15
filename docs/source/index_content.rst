
Welcome
=======

OpenSTREAM (**Open** **S**\olvers for **T**\wo-phase flow **R**\esearch,
**E**\ngineering **A**\nalysis and **M**\odeling) is an open-source,
object-oriented environment for developing, exploring, and evaluating
one-dimensional, multi-field, two-phase-flow models
:cite:p:`LeCorre2025OpenSTREAM,LeCorre2025ICMF`.

Whether you are developing, investigating, or validating a closure model,
comparing solver formulations, or learning how two-phase-flow models are
implemented, OpenSTREAM provides accessible solver frameworks that can be
inspected, modified, tested, and extended.

OpenSTREAM supports steady-state and transient simulations of
single-component two-phase flows in straight channels. Applications include
wall boiling, thermal and hydrodynamic non-equilibrium, annular-flow
modeling, liquid-film transport, entrainment and deposition, disturbance
waves, boiling transition, dryout, and post-CHF heat transfer.

The software is designed primarily for transparent model development,
verification, validation, numerical investigation, education, and
reproducible research. The validity of a calculation depends on the
selected solver, closure models, numerical options, geometry, and operating
conditions.

Explore the solver frameworks
-----------------------------

OpenSTREAM provides four complementary solver frameworks:

- A **mixture solver** for robust initialization and mixture-based
  calculations, with optional hydrodynamic and thermal non-equilibrium
  models.
- A **two-fluid solver** with separate liquid and vapor mass, momentum, and
  energy equations.
- A **three-field solver** for annular flow, representing vapor, liquid
  film, and entrained droplets under the current thermal-equilibrium
  formulation.
- A **four-field solver** for annular flow, separately representing the
  base film, disturbance waves, entrained droplets, and vapor under the
  current thermal-equilibrium formulation.

The frameworks support straight multi-wall channels with uniform or
nonuniform heating. Their modular, object-oriented implementation allows
users and developers to examine and modify the governing equations,
closure models, numerical methods, and post-processing workflows.

A more detailed framework is not necessarily more accurate for every
application. Each additional field introduces further closure relations,
initialization requirements, numerical couplings, and uncertainties.
Review the :doc:`intended scope and limitations
<Usage/scope_and_limitations>` before applying OpenSTREAM to a new problem.

Why OpenSTREAM?
---------------

Many established two-phase-flow formulations are thoroughly described in
the literature but implemented only in large or restricted computational
codes. OpenSTREAM provides a focused and transparent environment in which
fundamental models can be studied independently, compared systematically,
and developed collaboratively.

OpenSTREAM can help researchers, engineers, developers, and students:

- Develop and assess physical and closure models.
- Compare alternative two-phase-flow formulations.
- Investigate numerical methods and solver behavior.
- Evaluate calculations against experimental data.
- Perform sensitivity and uncertainty studies.
- Build reproducible computational workflows.
- Share model implementations and results across institutions.

OpenSTREAM-database
-------------------

`OpenSTREAM-database
<https://github.com/OpenSTREAM-solvers/openstream-database>`_ complements
the core solver repository with publicly available experimental datasets,
application and validation workflows, calculated-versus-measured
comparisons, and publication companion projects.

OpenSTREAM and OpenSTREAM-database are maintained as separate repositories
and must be installed independently. See the
:doc:`OpenSTREAM-database <Applications/database>` page for its dataset
structure, application interface, and documented workflows.

Get started
-----------

A good first path through the documentation is:

#. Follow the :doc:`installation and configuration guide
   <Usage/gettingStarted>`.
#. Run the :doc:`sample calculation <Usage/runSampleScript>`.
#. Explore the :doc:`OpenSTREAM tutorials <Guides/tutorials>`.
#. Review the :doc:`testing and verification guide <Guides/testing>`.
#. Consult the :doc:`intended scope and limitations
   <Usage/scope_and_limitations>` before starting a new application.

Links
-----

- **Source code:** `OpenSTREAM-solvers/openstream
  <https://github.com/OpenSTREAM-solvers/openstream>`_
- **Application and validation database:**
  `OpenSTREAM-solvers/openstream-database
  <https://github.com/OpenSTREAM-solvers/openstream-database>`_
- **Report a problem or request a feature:** `OpenSTREAM issue tracker
  <https://github.com/OpenSTREAM-solvers/openstream/issues>`_
- **Contribute:** see the :doc:`Community <Community/index>` section

About this documentation
------------------------

This documentation includes:

- Installation and environment-configuration guidance.
- Solver-framework and theory descriptions.
- Tutorials and sample calculations.
- Input, output, and numerical-workflow guidance.
- Testing, troubleshooting, and versioning information.
- OpenSTREAM-database and publication companion documentation.
- Generated class, property, and method references.
- Contribution and development guidance.

.. only:: html

   Prefer a printable format? Download the
   `OpenSTREAM documentation PDF <files/OpenSTREAM.pdf>`_.


----

.. bibliography::
   :list: enumerated
   :filter: docname in docnames