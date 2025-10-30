Theory overview
===============

This page provides a high-level summary of the theoretical foundations behind the simulation frameworks implemented in OpenSTREAM. Each model is designed to simulate one-dimensional, two-phase flow in straight channels, with increasing complexity and resolution.


The following models are covered:


.. toctree::
   :maxdepth: 1

   Mixture_Model_Theory
   TwoFluid_Model_Theory
   ThreeField_Model_Theory
   FourField_Model_Theory


Model summaries
---------------

**Mixture model**

- Purpose: Initialization and robust steady-state predictions.
- Assumptions: Homogeneous equilibrium, single mixture phase.
- Equations: Mass, momentum, and energy conservation.

**Two-fluid model**

- Purpose: Captures hydrodynamic and thermal non-equilibrium.
- Assumptions: Separate conservation equations for liquid and vapor phases.
- Equations: Six-equation model (mass, momentum, energy for each phase).

**Three-field model**

- Purpose: Simulates annular flow with vapor, droplets, and liquid film.
- Assumptions: Thermal equilibrium, applicable up to film dryout.
- Equations: Nine-equation model for mass and momentum conservation.

**Four-field model**

- Purpose: Advanced modeling of disturbance waves in annular flow.
- Assumptions: Thermal equilibrium, wave transport and non-equilibrium dynamics.
- Equations: Extended conservation equations + wave number density transport.

----

For detailed equations and implementation notes, refer to the individual theory pages listed above.

