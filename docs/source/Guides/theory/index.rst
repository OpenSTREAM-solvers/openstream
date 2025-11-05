Theory overview
===============

Welcome to the theory section! This page gives you a high-level overview of the theoretical foundations behind the simulation frameworks implemented in **OpenSTREAM**, along with relevant references. Each model is designed to simulate one-dimensional, two-phase flow in straight channels, with increasing levels of complexity and physical resolution.

Whether you're just getting started or diving deep into advanced simulations, this guide will help you understand the purpose, assumptions, and structure behind each solver.

Model summaries
---------------

**Mixture model**

- Purpose: Initialization and robust predictions under relevant simplifications.
- Assumptions: Single mixture field with or without thermal non-equilibrium capabilities.
- Equations: Conservation of mass, momentum, and energy for the mixture.

**Two-fluid model**

- Purpose: Captures hydrodynamic and thermal non-equilibrium between phases.
- Assumptions: Separate conservation equations for liquid and vapor.
- Equations: Conservation of mass, momentum, and energy for each phase (six-equation model).

**Three-field model**

- Purpose: Design for annular flow with vapor, droplets, and liquid film.
- Assumptions: Thermal equilibrium (for now), valid up to film dryout.
- Equations: Conservation of mass and momentum for the three fields.

**Four-field model**

- Purpose: Advanced modeling of disturbance waves in annular flow, including non-equilibrium dynamics.
- Assumptions: Thermal equilibrium (for now).
- Equations: Conservation of mass and momentum for the four fields + wave number density transport.

Implemented models
------------------

Explore the theory behing each solver:

.. toctree::
   :maxdepth: 1

   Mixture_Model_Theory
   TwoFluid_Model_Theory
   ThreeField_Model_Theory
   FourField_Model_Theory

For detailed equations, derivations, and implementation notes, check out the individual theory pages linked above. Ready to dive deeper? Pick a model and start exploring!
