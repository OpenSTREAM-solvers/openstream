Four-Field Model Theory
========================

The Four-Field Model extends the Three-Field Model by separating the liquid film into base film and disturbance waves.

Governing Equations
-------------------

- **Mass Conservation**:
  :math:`\frac{\partial W_b}{\partial t} = D_b - E_b + \omega`
  :math:`\frac{\partial W_w}{\partial t} = D_w - E_w - \omega`

- **Momentum Conservation**:
  :math:`\frac{\partial u_b}{\partial t} = -\tau_{wall,b} - \tau_{v,b} - \tau_{w,b}`
  :math:`\frac{\partial u_w}{\partial t} = -\tau_{v,w} + \tau_{w,b}`

- **Energy Conservation**:
  :math:`\frac{\partial h_b}{\partial t} = q''_{wall,b}`
  :math:`\frac{\partial h_w}{\partial t} = q''_{wall,w}`

- **Wave Number Density Transport**:
  :math:`\frac{\partial N_w}{\partial t} = \frac{N_w^{eq} - N_w}{\tau_{relax}}`

Features
--------

- Models wave transport and intermittency.
- Captures non-equilibrium wave dynamics.

Related Class
-------------

- :class:`FourFieldSolver`
- :meth:`FourFieldSolver.solve_wave_transport`
- :attr:`FourFieldSolver.waveFrequency`
