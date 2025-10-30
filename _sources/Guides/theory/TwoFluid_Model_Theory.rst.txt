Two-Fluid Model
===============

The Two-Fluid Simulation Framework in OpenSTREAM is based on a six-equation model that separately tracks the conservation of mass, momentum, and energy for both liquid and vapor phases. This model captures hydrodynamic and thermal non-equilibrium effects and is widely used in nuclear reactor system codes.

Governing equations
-------------------

**1. Mass conservation**

Liquid: :math:`\frac{\partial W_l u_l}{\partial t} + \frac{\partial W_l}{\partial z} = -A a_i (\Gamma - \Lambda) - \sum \Pi_p^n \Gamma_{wb}^n`

Vapor: :math:`\frac{\partial W_v u_v}{\partial t} + \frac{\partial W_v}{\partial z} = A a_i (\Gamma - \Lambda) + \sum \Pi_p^n \Gamma_{wb}^n`

Where:

- :math:`W_l`, :math:`W_v` are liquid and vapor mass flow rates
- :math:`u_l`, :math:`u_v` are phase velocities
- :math:`\Gamma` is interfacial mass transfer
- :math:`\Lambda` is condensation
- :math:`\Gamma_{wb}^n` is wall boiling mass flux

**2. Momentum conservation**

Liquid: :math:`\rho_l A_l \frac{\partial u_l}{\partial t} + u_l \frac{\partial u_l}{\partial z} = -A a_i \Lambda (u_l - u_v) - A_l \frac{\partial p}{\partial z} + \cos\theta g \rho_l + A a_i \tau_{v,l} - \Pi_p \tau_{wall,l}`

Vapor: :math:`\rho_v A_v \frac{\partial u_v}{\partial t} + u_v \frac{\partial u_v}{\partial z} = A a_i \Gamma (u_l - u_v) - A_v \frac{\partial p}{\partial z} + \cos\theta g \rho_v - A a_i \tau_{v,l} - \Pi_p \tau_{wall,v}`

**3. Energy conservation**

Liquid: :math:`\rho_l A_l \frac{\partial h_l}{\partial t} + u_l \frac{\partial h_l}{\partial z} = -A a_i (h_l - h_v) \Lambda + \sum \Pi_p^n {q^{\prime\prime}}_{wall,l}^n - (h_v - h_l) \Gamma_{wb}^n`

Vapor: :math:`\rho_v A_v \frac{\partial h_v}{\partial t} + u_v \frac{\partial h_v}{\partial z} = A a_i (h_l - h_v) \Gamma + \sum \Pi_p^n {q^{\prime\prime}}_{wall,v}^n`

Features and assumptions
------------------------

- Captures phase-specific velocities and temperatures
- Includes interfacial mass, momentum, and energy exchange
- Supports wall boiling and condensation
- Assumes straight channel geometry and single-component fluid

Implementation notes
--------------------

- Implemented in the class:
    - :attr:`Solvers.TwoFluidSolver`
- Key methods:
    - :attr:`Solvers.TwoFluidSolver.solve()`
- Key properties:
    - :attr:`Solvers.TwoFluidSolver.liquid.W`
    - :attr:`Solvers.TwoFluidSolver.vapor.W`
    - :attr:`Solvers.TwoFluidSolver.liquid.U`
    - :attr:`Solvers.TwoFluidSolver.vapor.U`
    - :attr:`Solvers.TwoFluidSolver.liquid.H`
    - :attr:`Solvers.TwoFluidSolver.vapor.H`

Role in OpenSTREAM
------------------

The two-fluid model is the core framework for simulating non-equilibrium two-phase flows. It is validated against system codes like TRACE and supports both steady-state and transient simulations.

----
