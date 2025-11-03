Mixture model
=============

The Mixture Simulation Framework in **OpenSTREAM** provides a simplified yet powerful approach to modeling two-phase flows. Based on a three-equation formulation, it treats the phases as a single continuum with averaged properties. This abstraction enables efficient simulation of systems where phase separation is minimal or where a fully resolved multi-field model is not required.

The mixture model serves two key roles within OpenSTREAM:

- Robust initialization for more complex solvers, ensuring robust starting conditions.
- Efficient simulation of flows with hydrodynamically well-coupled phases, where the mixture approximation remains physically meaningful.

In addition, a Homogeneous Relaxation Model (HRM) is currently under development. This extended formulation introduces vapor mass and energy conservation equations, allowing for thermal non-equilibrium between phases and expanding the model’s applicability to more dynamic flow regimes.

By reducing complexity while preserving essential dynamics, the mixture model offers a practical entry point for both model development and exploratory analysis in thermal-hydraulic systems.


Governing equations
-------------------

The mixture model solves the following conservation equations:

**1. Mass conservation**

:math:`\frac{\partial}{\partial t}(\frac{W}{u}) + \frac{\partial W}{\partial z} = 0`

where:

- :math:`W` is the mixture mass flow rate
- :math:`u` is the mixture velocity

**2. Momentum conservation**

:math:`\rho A (\frac{\partial u}{\partial t} + u \frac{\partial u}{\partial z}) = -A (\frac{\partial p}{\partial z} + \frac{\partial p_K}{\partial z} + \cos\theta g \rho) - \sum \Pi_w^n {\tau}_w^n`

where:

- :math:`\rho` is the mixture density
- :math:`A` is the cross-sectional area
- :math:`p` is the pressure
- :math:`K` relates to obstruction form loss
- :math:`\theta` is the inclination angle
- :math:`g` is the gravitational acceleration
- :math:`n` is the wall index
- :math:`\Pi_w^n` is the wall perimeter for wall index :math:`n`
- :math:`\tau_w^n` is wall shear stress for wall index :math:`n`

**3. Energy conservation**

:math:`\rho A (\frac{\partial h}{\partial t} + u \frac{\partial h}{\partial z}) = \sum \Pi_p^n {q^{\prime\prime}}_w^n`

where:

- :math:`h` is the mixture enthalpy
- :math:`{q^{\prime\prime}}_w^n` is the wall heat flux for wall index :math:`n`

**4. Homogeneous relaxation model**

*Coming soon*

Features and Assumptions
------------------------

- Supports both steady-state and transient simulations
- Can include thermal non-equilibrium modeling (subcooled boiling or post Critical Heat Flux) via constitutive models or HRM
- Allows phase velocity slip using drift flux models
- Neglects minor contributions such as frictional heating and temporal pressure gradient contributions 

Implementation Notes
--------------------

Package

- :mod:`Solvers`

Module

- :mod:`Solvers.Mixture`

Mixture solver class

- :class:`Solvers.Mixture.MixtureSolver`

Field and phases classes:

- :class:`Solvers.Mixture.Mixture`
- :class:`Solvers.Mixture.Liquid`
- :class:`Solvers.Mixture.Vapor`

Key solver methods

- :meth:`Solvers.Mixture.MixtureSolver.Mixture.solve()`

Key field properties:

- :attr:`Solvers.Mixture.MixtureSolver.Mixture.W`
- :attr:`Solvers.Mixture.MixtureSolver.Mixture.P`
- :attr:`Solvers.Mixture.MixtureSolver.Mixture.H`

Role in OpenSTREAM
------------------

The mixture model provides a robust initialization framework for more complex solvers (i.e., two-fluid, three-field, four-field). For now, its pressure gradient solution is reused across all frameworks to enhance robusness and numerical stability.

----
