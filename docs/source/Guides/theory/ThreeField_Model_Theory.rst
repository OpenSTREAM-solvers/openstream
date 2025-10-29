Three-Field Model Theory
=========================

The Three-Field Model simulates annular flow with vapor, droplets, and liquid film under thermal equilibrium.

Governing Equations
-------------------

- **Mass Conservation**:
  :math:`\frac{\partial W_f}{\partial t} = D - E`

- **Momentum Conservation**:
  :math:`\frac{\partial u_f}{\partial t} = -\tau_{wall,f} - \tau_{v,f}`
  :math:`\frac{\partial u_d}{\partial t} = -\tau_{v,d}`

- **Energy Conservation**:
  :math:`\frac{\partial h_f}{\partial t} = \sum_n q''_{wall,n}`

Features
--------

- Drop deposition and film entrainment models.
- Used for BWR subchannel analysis.

Related Class
-------------

- :class:`ThreeFieldSolver`
- :meth:`ThreeFieldSolver.solve_momentum_conservation`
- :attr:`ThreeFieldSolver.dropVelocity`
