Theory overview
===============

This page provides a high-level overview of the theoretical foundations
of the simulation frameworks implemented in **OpenSTREAM**, together with
the relevant references.

The frameworks are designed to simulate one-dimensional, two-phase flow
in straight channels. They provide increasing levels of physical
resolution, from a mixture formulation to the explicit representation of
liquid films, entrained droplets, and disturbance waves.

The appropriate framework depends on the flow regime, quantities of
interest, and assumptions acceptable for the intended application.
Detailed equations, derivations, assumptions, and implementation notes are
provided on the individual theory pages linked below.

Solver capabilities
-------------------

.. list-table::
   :header-rows: 1
   :widths: 16 25 23 16 20

   * - Framework
     - Principal fields
     - Thermal treatment
     - Time dependence
     - Principal applications
   * - Mixture
     - Mixture, with liquid and vapor properties
     - Thermal equilibrium or nonequilibrium
     - Steady-state and transient
     - Initialization, system-level boiling, CHF, and post-CHF calculations
   * - Two-fluid
     - Separate liquid and vapor fields
     - Thermal equilibrium or nonequilibrium
     - Steady-state and transient
     - Separate-phase transport and interfacial exchange
   * - Three-field
     - Vapor, liquid film, and entrained droplets
     - Thermal equilibrium in the current annular-flow formulation
     - Steady-state and transient
     - Annular flow, film transport, entrainment, deposition, and dryout
   * - Four-field
     - Vapor, base film, disturbance waves, and entrained droplets
     - Thermal equilibrium in the current annular-flow formulation
     - Steady-state and transient
     - Wave-resolved annular flow and developing wave behavior

The table summarizes the current solver formulations. Availability of a
solver framework does not imply that every physical model, closure
relation, flow regime, or application has been comprehensively validated.

OpenSTREAM is primarily intended for fundamental model development,
assessment, and validation in one-dimensional straight-channel
configurations. The applicability of a calculation depends on the selected
closure models, their validity ranges, the numerical settings, and the
conditions under consideration.

For a broader discussion of geometric, physical, numerical, and validation
limitations, see :doc:`Intended scope and limitations
<../scope_and_limitations>`.

Detailed theory pages
---------------------

:doc:`Mixture model <Mixture_Model_Theory>`
   * **Purpose:** Provide initialization and robust predictions under
     relevant simplifications.
   * **Assumptions:** Represent the flow using a single mixture field, with
     optional hydrodynamic and thermal nonequilibrium models.
   * **Equations:** Conserve mixture mass, momentum, and energy.
     Optionally (MRM), conserve vapor mass and energy.

:doc:`Two-fluid model <TwoFluid_Model_Theory>`
   * **Purpose:** Resolve hydrodynamic and thermal nonequilibrium between
     the liquid and vapor phases.
   * **Assumptions:** Represent the liquid and vapor as separate fields
     coupled through interfacial exchange models.
   * **Equations:** Conserve mass, momentum, and energy separately for the
     liquid and vapor phases.

:doc:`Three-field model <ThreeField_Model_Theory>`
   * **Purpose:** Model annular two-phase flow using separate vapor,
     liquid-film, and entrained-droplet fields.
   * **Assumptions:** Apply the current annular-flow formulation under
     thermal-equilibrium conditions up to liquid-film dryout.
   * **Equations:** Conserve mass and momentum for the liquid film and
     entrained droplets together with the mixture-model vapor solution.

:doc:`Four-field model <FourField_Model_Theory>`
   * **Purpose:** Resolve the continuous base film and disturbance waves as
     separate liquid fields in annular flow.
   * **Assumptions:** Apply the current annular-flow formulation under
     thermal-equilibrium conditions up to liquid-film dryout.
   * **Equations:** Conserve mass and momentum for the base film,
     disturbance waves, and entrained droplets together with the
     mixture-model vapor solution and a disturbance-wave number-density
     transport equation.

Select one of the theory pages above for the detailed formulation,
implemented assumptions, closure relations, and references.

.. toctree::
   :maxdepth: 1
   :hidden:

   Mixture_Model_Theory
   TwoFluid_Model_Theory
   ThreeField_Model_Theory
   FourField_Model_Theory
