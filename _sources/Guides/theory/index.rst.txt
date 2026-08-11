Theory overview
===============

This page gives you a high-level overview of the theoretical foundations behind the simulation frameworks implemented in **OpenSTREAM**, along with relevant references. Each model is designed to simulate one-dimensional, two-phase flow in straight channels, with increasing levels of complexity and physical resolution.

Whether you're just getting started or diving deep into advanced simulations, this guide will help you understand the purpose, assumptions, and structure behind each solver.

For detailed equations, derivations, and implementation notes, check out the individual theory pages linked below. 


.. toctree::
   :maxdepth: 1
   :hidden:

   Mixture_Model_Theory
   TwoFluid_Model_Theory
   ThreeField_Model_Theory
   FourField_Model_Theory

:doc:`Mixture model <Mixture_Model_Theory>`
   * Purpose: Initialization and robust predictions under relevant simplifications.
   * Assumptions: Single mixture field with or without thermal non-equilibrium capabilities.
   * Equations: Conservation of mass, momentum, and energy for the mixture.

:doc:`Two-fluid model <TwoFluid_Model_Theory>`
   * Purpose: Captures hydrodynamic and thermal non-equilibrium between phases.
   * Assumptions: Separate conservation equations for liquid and vapor.
   * Equations: Conservation of mass, momentum, and energy for each phase (six-equation model).

:doc:`Three-field model <ThreeField_Model_Theory>`
   * Purpose: Modeling annular two-phase flow with separate vapor, droplets, and liquid film fields.
   * Assumptions: Thermal equilibrium (for now), valid up to film dryout.
   * Equations: Conservation of mass and momentum for the three fields.

:doc:`Four-field model <FourField_Model_Theory>`
   * Purpose: Advanced annular flow modeling with explicit representation of disturbance waves, including non-equilibrium dynamics.
   * Assumptions: Thermal equilibrium (for now).
   * Equations: Conservation of mass and momentum for the four fields + wave number density transport.

Ready to dive deeper? Pick a model and start exploring!
