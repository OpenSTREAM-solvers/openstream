Mixture Model Theory
=====================

The Mixture Model in OpenSTREAM is a simplified three-equation framework used for initialization and robust steady-state predictions.

Governing Equations
-------------------

- **Mass Conservation**:
  :math:`\frac{\partial W}{\partial t} + \frac{\partial (\rho u A)}{\partial z} = 0`

- **Momentum Conservation**:
  :math:`\frac{\partial p}{\partial t} + \frac{\partial (\rho u^2 A)}{\partial z} = -\tau_{wall} - K + \rho g \cos(\theta)`

- **Energy Conservation**:
  :math:`\frac{\partial h}{\partial t} + \frac{\partial (\rho u h A)}{\partial z} = \sum_n q''_{wall,n}`

Features
--------

- Supports subcooled boiling via constitutive relations.
- Slip and drift flux models can be added.
- Used to initialize pressure gradient for all other solvers.

Related Class
-------------

- :class:`MixtureSolver`
- :meth:`MixtureSolver.solve_mass_conservation`
- :attr:`MixtureSolver.wallHeatFlux`

