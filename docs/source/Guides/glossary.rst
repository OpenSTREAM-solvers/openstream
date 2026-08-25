Glossary
========

This glossary defines terminology used throughout the **OpenSTREAM** documentation. The intent is to make the documentation more consistent and to clarify the distinction between closely related concepts used in one-dimensional, multi-field, two-phase flow modeling.

.. glossary::
   :sorted:

   Annular flow
      A two-phase flow regime in which a continuous vapor core is surrounded by a liquid film along the wall. Liquid droplets may also be entrained in the vapor core. In OpenSTREAM, annular flow models may represent vapor, droplets, liquid film, and, in advanced formulations, disturbance waves as separate fields.

   Boundary condition
      A prescribed condition imposed at the boundary of the computational domain. Typical boundary conditions specify inlet flow properties (mass flow, enthalpy), outlet pressure, and wall heat flux.

   Closure model
      A model used to close the system of conservation equations by providing relationships for physical processes that are not resolved directly. Examples include wall heat transfer, interfacial drag, interfacial heat transfer, phase change, entrainment, deposition, and wall friction.

   Conservation equation
      A governing equation expressing the conservation of a physical quantity, such as mass, momentum, or energy. In OpenSTREAM, conservation equations are formulated for the mixture, phase, or field variables depending on the selected solver.

   Deposition
      The transfer of liquid droplets from the vapor core back to the wall film. Deposition is typically represented through a closure model in annular flow formulations.

   Disturbance wave
      A coherent liquid structure traveling along the liquid film in annular flow. Disturbance waves can influence wall wetting, film mass transport, entrainment, deposition, and interfacial momentum transfer.

   Droplet field
      A dispersed liquid field representing entrained droplets transported within the vapor core. In annular flow modeling, the droplet field is distinct from the wall liquid film field.

   Entrainment
      The transfer of liquid from the wall film into the vapor core as droplets. Entrainment is typically represented through a closure model in annular flow formulations.

   Field
      A computationally resolved constituent with its own set of transported variables or conservation equations. A field is not always identical to a thermodynamic phase. For example, liquid droplets and a wall liquid film are both liquid phase constituents, but they may be represented as separate fields.

   Film dryout
      The disappearance of the continuous wall liquid film. In annular flow modeling, film dryout marks the loss of wall wetting by the liquid film and is often associated with a change in heat transfer behavior.

   Four-field model
      A multi-field model for annular two-phase flow in which vapor, droplets, liquid film, and disturbance waves are represented explicitly.

   Governing equation
      A mathematical equation describing the evolution of a conserved quantity or transported variable. Governing equations in OpenSTREAM are based on one-dimensional conservation laws with source terms.

   Hydrodynamic equilibrium
      A modeling assumption in which the phases or fields share the same velocity, or in which relative motion is neglected. When hydrodynamic non-equilibrium is considered, different phases or fields may have different velocities.

   Hydrodynamic non-equilibrium
      A condition in which two or more phases or fields have different velocities or momentum balances. Two-fluid and multi-field formulations commonly account for hydrodynamic non-equilibrium.

   Interfacial area
      The area of contact between phases or fields per unit volume. Interfacial area appears in closure models for interfacial transfer of mass, momentum, and energy.

   Interfacial transfer
      Exchange of mass, momentum, or energy between phases or fields. Examples include evaporation, condensation, interfacial drag, and interfacial heat transfer.

   Liquid film
      A continuous liquid layer flowing along the wall in annular flow. The liquid film is treated separately from entrained liquid droplets in multi-field annular flow models.

   Mixture model
      A reduced two-phase flow model in which the phases are represented through mixture quantities. Depending on the implementation, the mixture model may include additional relations to account for thermal non-equilibrium.

   Multi-field model
      A model in which different constituents of the flow are represented as separate computational fields. Multi-field models allow different phases or flow structures, such as vapor, droplets, liquid film, and disturbance waves, to be described with different transported variables.

   Multi-wall channel
      A channel representation that may include more than one heated or unheated wall surface. This allows wall-specific thermal or hydraulic conditions to be represented in the model formulation.

   Non-equilibrium
      A condition in which one or more variables are not shared among phases or fields. Non-equilibrium may be thermal, hydrodynamic, mechanical, or chemical depending on the variables considered.

   One-dimensional model
      A model in which flow variables vary primarily along one spatial coordinate, usually the axial direction. Cross-sectional effects are represented through averaged quantities and closure models rather than resolved explicitly.

   Phase
      A physically distinct thermodynamic state of matter, such as liquid or vapor. A phase may be represented by one or more fields in a multi-field model.

   Phase change
      Conversion of mass from one phase to another, such as evaporation or condensation. In two-phase thermal-hydraulic models, phase change is usually represented as an interfacial or wall source term.

   Relaxation model
      A model that drives a variable toward an equilibrium or target state over a characteristic relaxation time. Relaxation models are often used to represent unresolved non-equilibrium processes in a numerically robust way.

   Relaxation time
      A characteristic timescale over which a variable approaches an equilibrium or target value in a relaxation model. Smaller relaxation times correspond to faster return toward the target state.

   Solver
      A computational implementation of a mathematical model and numerical method used to solve a specific set of governing equations. In OpenSTREAM, different solvers correspond to different levels of physical detail and modeling assumptions.

   Source term
      A term in a conservation or transport equation representing production, destruction, or exchange of a quantity. Source terms may arise from wall interaction, interfacial transfer, external forces, or phase change.

   Straight channel
      A flow path without geometric bends or complex three-dimensional features. In one-dimensional modeling, a straight channel is represented along a single axial coordinate.

   Thermal equilibrium
      A modeling assumption in which phases or fields share the same temperature, or in which temperature differences are neglected.

   Thermal non-equilibrium
      A condition in which two or more phases or fields may have different temperatures or energy balances. Thermal non-equilibrium is important when heat transfer and phase change cannot be represented accurately by a single shared temperature.

   Three-field model
      A multi-field model for annular two-phase flow in which vapor, droplets, and liquid film are represented as separate fields.

   Two-fluid model
      A model in which the liquid and vapor phases are described by separate conservation equations. Two-fluid models can represent hydrodynamic and thermal non-equilibrium between phases.

   Two-phase flow
      Flow involving two thermodynamic phases, commonly liquid and vapor in the context of thermal-hydraulic applications.

   Wall boiling
      Boiling that occurs at a heated wall. Wall boiling models typically include mechanisms such as nucleation, evaporation, convection, quenching, and associated wall heat partitioning, depending on the level of model detail.

   Wall friction
      Momentum loss associated with shear stress at the wall. Wall friction is usually represented by a closure model or friction factor correlation.

   Wall heat flux
      The heat flux imposed at, or transferred through, a wall boundary. In heated channel simulations, wall heat flux is a key input or result depending on the problem formulation.

Recommended terminology
-----------------------

For consistency across the documentation, the following preferred terms are recommended:

.. list-table::
   :header-rows: 1
   :widths: 30 35 35

   * - Preferred term
     - Use when referring to
     - Avoid or use only with care
   * - OpenSTREAM
     - The project, code, and documentation set
     - OpenStream, openstream
   * - two-phase flow
     - Liquid-vapor flow modeled by OpenSTREAM
     - multiphase flow, unless more than two phases are intended
   * - field
     - Computationally resolved constituent
     - phase, when the distinction is important
   * - phase
     - Thermodynamic state, such as liquid or vapor
     - field, when referring to physical state
   * - closure model
     - Implemented model used to close governing equations
     - closure law, correlation, constitutive law, unless a specific distinction is intended
   * - thermal non-equilibrium
     - Different temperatures or energy balances among phases or fields
     - thermal disequilibrium, nonequilibrium thermal effects
   * - hydrodynamic non-equilibrium
     - Different velocities or momentum balances among phases or fields
     - velocity slip, unless specifically referring to relative velocity
   * - source term
     - Additive term in a conservation or transport equation
     - forcing term, production term, unless more specific
   * - straight channel
     - One-dimensional channel without bends or complex 3D geometry
     - straight geometry, if channel-specific wording is clearer

Style notes
-----------

* Use ``OpenSTREAM`` consistently as the project name.
* Use ``two-phase flow`` when referring specifically to liquid-vapor applications.
* Use ``multi-field`` with a hyphen when it modifies a noun, for example ``multi-field model``.
* Use ``one-dimensional`` with a hyphen when it modifies a noun, for example ``one-dimensional solver``.
* Use ``thermal non-equilibrium`` and ``hydrodynamic non-equilibrium`` consistently.
* Prefer ``closure model`` for implemented models and reserve ``constitutive relation`` for broader physical relationships.
* Distinguish carefully between ``phase`` and ``field`` in theory pages.
