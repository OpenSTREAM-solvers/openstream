Mixture Model Theory
=====================

The Mixture Simulation Framework in OpenSTREAM is based on a simplified three-equation model that assumes a single mixture phase with averaged properties. It is primarily used for initialization and robust steady-state predictions under homogeneous equilibrium assumptions.
Governing Equations
-------------------

The mixture model solves the following conservation equations:

1. Mass Conservation

:math:\frac{\partial}{\partial t}(W u) + \frac{\partial W}{\partial z} = 0

Where:

:math:W is the mixture mass flow rate
:math:u is the mixture velocity

2. Momentum Conservation

:math:\rho A \frac{\partial u}{\partial t} + u \frac{\partial u}{\partial z} = -A \frac{\partial p}{\partial z} + \frac{\partial p K}{\partial z} + \cos\theta g \rho - \Pi_p \tau_{wall}

Where:

:math:\rho is the mixture density
:math:A is the cross-sectional area
:math:p is pressure
:math:K is obstruction factor
:math:\tau_{wall} is wall shear stress

3. Energy Conservation

:math:\rho A \frac{\partial h}{\partial t} + u \frac{\partial h}{\partial z} = \sum \Pi_p^n q''_{wall,n}

Where:

:math:h is mixture enthalpy
:math:q''_{wall,n} is wall heat flux for wall index :math:n

Features and Assumptions
------------------------

Supports steady-state and transient simulations
Can include subcooled boiling via constitutive models
Allows phase velocity slip via drift flux models
Neglects surface tension, frictional heating, and pressure gradients in saturated enthalpy

Implementation Notes
--------------------

The mixture solver is implemented in the class: MixtureSolver
Key methods:
MixtureSolver.solve_mass_conservation()
MixtureSolver.solve_momentum_conservation()
MixtureSolver.solve_energy_conservation()
Properties:
MixtureSolver.mass_flow_rate
MixtureSolver.velocity
MixtureSolver.enthalpy

Role in OpenSTREAM
------------------

The mixture model provides a robust initialization for more complex solvers (e.g., two-fluid, three-field, four-field). Its pressure gradient solution is reused across all frameworks to improve numerical stability.


Next: twofluid_model_theory.html
