Theory overview
===============

This page provides a high-level summary of the theoretical foundations behind the simulation frameworks implemented in OpenSTREAM. Each model is designed to simulate one-dimensional, two-phase flow in straight channels, with increasing complexity and resolution.


Mixture Model
-------------

- Purpose: Initialization and robust steady-state predictions.
- Assumptions: Homogeneous equilibrium, single mixture phase.
- Equations: Mass, momentum, and energy conservation.
- Link: `Mixture Model Theory <Guides/Mixture_Model_Theory.html>`_

Two-Fluid Model
---------------

- Purpose: Captures hydrodynamic and thermal non-equilibrium.
- Assumptions: Separate conservation equations for liquid and vapor phases.
- Equations: Six-equation model (mass, momentum, energy for each phase).
- Link: `Two-Fluid Model Theory <Guides/TwoFluid_Model_Theory.html>`_

Three-Field Model
-----------------

- Purpose: Simulates annular flow with vapor, droplets, and liquid film.
- Assumptions: Thermal equilibrium, applicable up to film dryout.
- Equations: Nine-equation model for mass and momentum conservation.
- Link: `Three-Field Model Theory <Guides/ThreeField_Model_Theory.html>`_

Four-Field Model
----------------

- Purpose: Advanced modeling of disturbance waves in annular flow.
- Assumptions: Thermal equilibrium, wave transport and non-equilibrium dynamics.
- Equations: Extended conservation equations + wave number density transport.
- Link: `Four-Field Model Theory <Guides/FourField_Model_Theory.html>`_

----

For detailed equations and implementation notes, refer to the individual theory pages linked above.

