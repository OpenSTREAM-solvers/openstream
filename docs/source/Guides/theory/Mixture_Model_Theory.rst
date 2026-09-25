Mixture model
=============

The mixture simulation framework in **OpenSTREAM** provides a simplified yet powerful approach to modeling two-phase flows. Based on a three-equation formulation, it treats the phases as a single continuum with averaged properties. This abstraction enables efficient simulation of systems where phase separation is minimal or where a fully resolved multi-field model is not required.

The mixture model serves two key roles within OpenSTREAM:

- **Robust initialization** for more complex solvers, ensuring robust starting conditions.
- **Efficient simulation** of flows with hydrodynamically well-coupled phases, where the mixture approximation remains physically meaningful.
- **Industry relevance** due to its simplicity and robustness, offering a practical approach for simulating averaged flow behavior in complex thermal-hydraulic systems.

In addition, a Mixture Relaxation Model (MRM) is available (:cite:t:`LeCorre2026MRM`). This extended formulation introduces vapor mass and energy conservation equations, allowing for thermal non-equilibrium between phases and expanding the model’s applicability to more dynamic flow regimes.

By reducing complexity while preserving essential dynamics, the mixture model offers a practical entry point for both model development and exploratory analysis in thermal-hydraulic systems.

An overview of the mixture model implemented in OpenSTREAM is provided below. A more detailed derivation and theoretical background can be found in :cite:t:`LeCorre2025OpenSTREAM`.

Governing equations
-------------------

The mixture model solves the following conservation equations:

**1. Mass conservation**

:math:`\frac{\partial}{\partial t}(\frac{W}{u}) + \frac{\partial W}{\partial z} = 0`

where:

- :math:`W` is the mixture mass flow rate
- :math:`u` is the mixture (static) velocity

**2. Momentum conservation**

:math:`\frac{\partial W}{\partial t} + \frac{\partial}{\partial z}(u^+ \cdot W) = -A \cdot (\frac{\partial p}{\partial z} + \frac{\partial p_K}{\partial z} + \cos\theta \cdot g \cdot \rho) - \sum \Pi_{wall}^n \cdot {\tau}_{wall}^n`

where:

- :math:`\rho` is the mixture density
- :math:`u^+` is mixture (advection) velocity
- :math:`A` is the cross-sectional area
- :math:`p` is the pressure
- :math:`K` relates to obstruction form loss
- :math:`\theta` is the inclination angle
- :math:`g` is the gravitational acceleration
- :math:`n` is the wall index
- :math:`\Pi_{wall}^n` is the wall perimeter for wall index :math:`n`
- :math:`\tau_{wall}^n` is the wall shear stress for wall index :math:`n`

**3. Energy conservation**

:math:`\frac{\partial}{\partial t}(h \cdot \frac{W}{u}) + \frac{\partial}{\partial z}(h^+ \cdot W) = \sum \Pi_{wall}^n \cdot {q^{\prime\prime}}_{wall}^n`

where:

- :math:`h` is the mixture (static) specific enthalpy
- :math:`h^+` is the mixture (advection) specific enthalpy
- :math:`{q^{\prime\prime}}_{wall}^n` is the wall heat flux for wall index :math:`n`

Mixture relaxation model
----------------------------

When selecting the Mixture Relaxation Model (MRM), two supplementary conservation equations are solved for the vapor phase. These equations provide the information required to determine the vapor mass fraction and vapor enthalpy while accounting for delayed interfacial heat and mass transfer. The resulting five-equation framework remains computationally efficient while allowing departures from thermodynamic equilibrium in subcooled boiling, saturated boiling, and post-boiling transition conditions.

**1. Vapor mass conservation**

:math:`\frac{\partial}{\partial t}(\frac{W_v}{u_v}) + \frac{\partial W_v}{\partial z} = A \cdot a_i \cdot (\Gamma - \Lambda) + \sum \Pi_{wall}^n \cdot {\Gamma}_{wb}^n`

where:

- :math:`W_v` is the vapor mass flow rate
- :math:`u_v` is the vapor velocity
- :math:`a_i`, is the volumetric interfacial area
- :math:`\Gamma` is the interfacial evaporation mass flux
- :math:`\Lambda` is the interfacial condensation mass flux
- :math:`\Gamma_{wb}^n` is the wall boiling mass flux for wall index :math:`n`

**2. Vapor energy conservation**

:math:`\frac{W_v}{u_v} \cdot \frac{\partial}{\partial t}(h_v) + W_v \cdot \frac{\partial}{\partial z}(h_v) = A \cdot a_i \cdot (h_l - h_v)\cdot {\Gamma} + \sum \Pi_{wall}^n \cdot {q^{\prime\prime}}_{wall,v}^n`

where:

- :math:`h_v` is the vapor specific enthalpy
- :math:`{q^{\prime\prime}}_{wall,v}^n` is the wall heat flux transferred to the vapor for wall index :math:`n`

**3. Time relaxation approximation**

The fundamental assumption of the MRM is to consider that the interfacial mass exchanges are governed by the deviation from thermal equilibrium under a time relaxation principle:

:math:`A \cdot a_i \cdot (\Gamma - \Lambda) = \frac{x_{eq} \cdot W - W_v}{u_v \cdot t_{Relax}}`

where:

- :math:`x_{eq}` is the thermodynamic equilibrium quality
- :math:`t_{Relax}` is the relaxation time for the interfacial mass transfer (evaporation or condensation)


Closure models
--------------

To complete the conservation equations, several closure models are required:

- Wall shear stress: :math:`\tau_w^n`
- Form pressure losses: :math:`\frac{\partial p_K}{\partial z}`
- Wall heat transfer models
- Relaxation time for the interfacial mass transfer (required for the MRM model only): :math:`t_{Relax}`

For each simulation, the selected closure models are defined in the OpenSTREAM model file, chosen from the available options listed in :mod:`InputEnums`. If not explicitly specified by the user, default models are applied as defined in :class:`Inputs.Model`. All relevant closure models are implemented in :class:`Solvers.Mixture.Mixture`, which users can modify to suit specific simulation needs.

In addition, the thermodynamic properties for each phase are computed using `CoolProp <https://coolprop.org/>`_, an open-source thermophysical property library that provides accurate equations of state and transport properties for a wide range of fluids.

Features and assumptions
------------------------

- Supports both steady-state and transient simulations in straight channels
- Supports uniform and nonuniform wall heat flux distribution
- Can include thermal non-equilibrium modeling (subcooled boiling or post Critical Heat Flux) via closure models or MRM
- Allows phase velocity slip using drift flux models
- Neglects minor contributions such as frictional heating and temporal pressure gradient contributions

Role in OpenSTREAM
------------------

The mixture model provides a robust tool for simulating homogeneous two-phase flow, including cases with thermal non-equilibrium. It also provides an initialization framework for more complex solvers (i.e., two-fluid, three-field, four-field). Currently, its pressure gradient solution is reused across all solver frameworks to enhance robustness and numerical stability.

----

Implementation notes
--------------------

Package

- :mod:`Solvers`

Module

- :mod:`Solvers.Mixture`

Mixture solver class

- :class:`Solvers.Mixture.MixtureSolver`

Field and phase classes:

- :class:`Solvers.Mixture.Mixture`
- :class:`Solvers.Mixture.Liquid`
- :class:`Solvers.Mixture.Vapor`

Key solver methods

- :meth:`Solvers.Mixture.MixtureSolver.solve()`

Key field properties:

- :attr:`Solvers.Mixture.Mixture.W`
- :attr:`Solvers.Mixture.Mixture.P`
- :attr:`Solvers.Mixture.Mixture.H`
