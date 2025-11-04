Two-fluid model
===============

The two-Fluid simulation framework in **OpenSTREAM** provides a detailed representation of multiphase flow by solving six conservation equations—mass, momentum, and energy for both liquid and vapor phases. This formulation enables the simulation of key non-equilibrium effects and is foundational in nuclear reactor thermal-hydraulic code systems.

The two-fluid  model serves several key roles within OpenSTREAM:

- Full separate phase treatment: Liquid and vapor are modeled as distinct continua, each with its own set of governing equations.
- Non-equilibrium dynamics: Captures both thermal and hydrodynamic non-equilibrium, essential for accurate transient and boiling flow simulations.
- Industry relevance: Commonly used in reactor system codes to simulate phenomena such as evaporation, condensation, and phase separation.

By explicitly modeling both liquid and vapor phases, the two-fluid approach preserves critical non-equilibrium dynamics while offering a flexible foundation for detailed model development and advanced thermal-hydraulic analysis.

An overview of the two-fluid model implemented in OpenSTREAM is provided below. A more detailed derivation and theoretical background can be found in :cite:t:LeCorre2025OpenSTREAM and :cite:t:Walter2024.

Governing equations
-------------------

**1. Mass conservation**

Liquid: :math:`\frac{\partial}{\partial t}(\frac{W_l}{u_l}) + \frac{\partial W_l}{\partial z} = -A a_i (\Gamma - \Lambda) - \sum \Pi_w^n \Gamma_{wb}^n`

Vapor: :math:`\frac{\partial}{\partial t}(\frac{W_v}{u_v}) + \frac{\partial W_v}{\partial z} = A a_i (\Gamma - \Lambda) + \sum \Pi_w^n \Gamma_{wb}^n`

where:

- :math:`W_l`, :math:`W_v` are the liquid and vapor mass flow rates
- :math:`u_l`, :math:`u_v` are the liquid and vapor velocities
- :math:`a_i`, is the volumetric interfacial area
- :math:`\Gamma` is the interfacial evaporation mass flux
- :math:`\Lambda` is the interfacial condensation mass flux
- :math:`\Gamma_{wb}^n` is the wall boiling mass flux for wall index :math:`n`

**2. Momentum conservation**

Liquid: :math:`\rho_l A_l (\frac{\partial u_l}{\partial t} + u_l \frac{\partial u_l}{\partial z}) = -A a_i \Lambda (u_l - u_v) - A_l (\frac{\partial p}{\partial z} + \cos\theta g \rho_l) + A a_i \tau_{v,l} - \sum \Pi_w^n \tau_{w,l}^n`

Vapor: :math:`\rho_v A_v (\frac{\partial u_v}{\partial t} + u_v \frac{\partial u_v}{\partial z}) = (A a_i \Gamma + \sum \Pi_w^n \Gamma_{wb}^n) (u_l - u_v) - A_v (\frac{\partial p}{\partial z} + \cos\theta g \rho_v) - A a_i \tau_{v,l} - \sum \Pi_w^n \tau_{w,v}^n`

where

- :math:`A_l`, :math:`A_v` are the liquid and vapor cross-sectional areas
- :math:`\tau_{v,l}` is the interfacial shear stress
- :math:`\tau_{w,l}`, :math:`\tau_{w,v}` are the liquid and vapor wall shear stresses

**3. Energy conservation**

Liquid: :math:`\rho_l A_l (\frac{\partial h_l}{\partial t} + u_l \frac{\partial h_l}{\partial z}) = -A a_i \Lambda (h_l - h_v) + \sum \Pi_w^n ({q^{\prime\prime}}_{w,l}^n - (h_v - h_l) \Gamma_{wb}^n)`

Vapor: :math:`\rho_v A_v (\frac{\partial h_v}{\partial t} + u_v \frac{\partial h_v}{\partial z}) = A a_i \Gamma (h_l - h_v) + \sum \Pi_w^n {q^{\prime\prime}}_{w,v}^n`

where

- :math:`h_l`, :math:`h_v` are the liquid and vapor specific enthalpies
- :math:`{q^{\prime\prime}}_{w,l}^n`, :math:`{q^{\prime\prime}}_{w,v}^n` are the wall heat flux to liquid and vapor for wall index :math:`n`

Closure relations
-----------------

To complete the conservation equations, several closure relations are required:

- Volumetric interfacial area: :math:`a_i`
- Interfacial evaporation and condensation mass fluxes
- Wall boiling mass flux
- Interfacial shears stress
- Wall shear stress for each phase
- Wall heat flux for for each phase
- Equations of state: Appropriate thermodynamic properties for each phase

These relations depend on the local flow regime, which is determined by an additional flow regime identification model. 

The selected closure models are defined in the OpenSTREAM model file, chosen from the available options listed in :mod:`InputEnums`. If not explicitly specified by the user, default models are applied as defined in :class:`Inputs.Model`. All closure relations are implemented in :class:`Solvers.TwoFluid.Liquid` and :class:`Solvers.TwoFluid.Vapor`, which the users can modify to suit specific simulation needs.

The thermodynamic properties for each phase are computed using `CoolProp <https://coolprop.org/>`_, an open-source thermophysical property library that provides accurate equations of state and transport properties for a wide range of fluids.

Features and assumptions
------------------------

- Captures phase-specific velocities and temperatures
- Includes interfacial mass, momentum, and energy exchange
- Supports wall boiling and condensation
- Assumes straight channel geometry and single-component fluid

Role in OpenSTREAM
------------------

The two-fluid model is the legacy framework for simulating non-equilibrium two-phase flows. It is validated against system codes like TRACE and supports both steady-state and transient simulations.

----

Implementation notes
--------------------

Package

- :mod:`Solvers`

Module

- :mod:`Solvers.TwoFluid`

Two-fluid solver class

- :class:`Solvers.TwoFluid.TwoFluidSolver`

Phase classes

- :class:`Solvers.TwoFluid.Liquid`
- :class:`Solvers.TwoFluid.Vapor`

Flow regime enumeration class

- :class:`Solvers.TwoFluid.REGIMES`

Key solver methods

- :meth:`Solvers.TwoFluid.TwoFluidSolver.solve()`

Key field properties:

- :attr:`Solvers.TwoFluid.Liquid.W`
- :attr:`Solvers.TwoFluid.Liquid.U`
- :attr:`Solvers.TwoFluid.Liquid.H`
- :attr:`Solvers.TwoFluid.Vapor.W`
- :attr:`Solvers.TwoFluid.Vapor.U`
- :attr:`Solvers.TwoFluid.Vapor.H`
