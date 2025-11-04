Four-field model
================

The OpenSTREAM four-field simulation framework extends the traditional three-field model by explicitly representing disturbance waves, in addition to vapor, droplets, and the base liquid film. This modeling approach was originally developed in :cite:t:LECORREMODEL and :cite:t:LeCorre2022NURETH19. It provides improved resolution of annular two-phase flow dynamics, enabling more accurate and detailed simulations.

Governing equations
-------------------

**1. Mass conservation**

Base Film: :math:`\frac{\partial}{\partial t}(W_b^n u_b^n) + \frac{\partial W_b^n}{\partial z} = \Pi_p^n D_b^n - \Gamma_{wb,b}^n + \Psi_w^n - \Psi_b^n`

Disturbance Waves: :math:`\frac{\partial}{\partial t}(W_w^n u_w^n) + \frac{\partial W_w^n}{\partial z} = \Pi_p^n D_w^n - E^n - \Gamma_{wb,w}^n - \Psi_w^n + \Psi_b^n`

Where:

- :math:`W_b^n`, :math:`W_w^n` are base film and wave mass flow rates
- :math:`u_b^n`, :math:`u_w^n` are velocities
- :math:`D_b^n`, :math:`D_w^n` are deposition fluxes
- :math:`\Gamma_{wb,b}^n`, :math:`\Gamma_{wb,w}^n` are wall boiling fluxes
- :math:`\Psi_w^n`, :math:`\Psi_b^n` are exchange fluxes between film and waves

**2. Momentum conservation**

Base Film: :math:`\rho_{ls} \delta_b^n \frac{\partial u_b^n}{\partial t} + u_b^n \frac{\partial u_b^n}{\partial z} = D_b^n (u_d - u_b^n) + \Psi_w^n (u_w^n - u_b^n) - \delta_b^n \frac{\partial p}{\partial z} + g \rho_{ls} + \beta_b^n \tau_{v,b}^n + (1 - \beta_b^n) \tau_{w,b}^n - \tau_{wall,b}^n`

Disturbance Waves: :math:`\rho_{ls} \delta_w^n \frac{\partial u_w^n}{\partial t} + u_w^n \frac{\partial u_w^n}{\partial z} = D_w^n (u_d - u_w^n) + \Psi_b^n (u_b^n - u_w^n) - \delta_w^n \frac{\partial p}{\partial z} + g \rho_{ls} + (1 - \beta_b^n) \tau_{v,w}^n - \tau_{w,b}^n`

**3. Energy conservation**

Base Film: :math:`\Gamma_{wb,b}^n = \frac{{q^{\prime\prime}}_{wall,b}^n}{h_{vs} - h_{ls}}`

Disturbance Waves: :math:`\Gamma_{wb,w}^n = \frac{{q^{\prime\prime}}_{wall,w}^n}{h_{vs} - h_{ls}}`

**4. Wave number density transport**

:math:`\frac{\partial N_w^n}{\partial t} + \frac{\partial}{\partial z}(u_w^n N_w^n) = \frac{N_w^{eq,n} - N_w^n}{t_w^{Relax}}`

Where:

- :math:`N_w^n` is wave number density
- :math:`N_w^{eq,n}` is equilibrium wave number density
- :math:`t_w^{Relax}` is relaxation time

Features and assumptions
------------------------

- Models intermittent wave transport and non-equilibrium wave dynamics
- Assumes thermal equilibrium for energy equations
- Includes wave-film exchange and wave number density evolution

Implementation notes
--------------------

Implemented in the class:
    - :attr:`FourFieldSolver`
Key methods:
    - :attr:`FourFieldSolver.solve()`
Key properties:
    - :attr:`FourFieldSolver.wave.W`
    - :attr:`FourFieldSolver.wave.U`
    - :attr:`FourFieldSolver.wave.FREQUENCY`
    - :attr:`FourFieldSolver.base.W`
    - :attr:`FourFieldSolver.base.U`
    - :attr:`FourFieldSolver.drop.W`
    - :attr:`FourFieldSolver.drop.U`

Role in OpenSTREAM
------------------

The four-field model provides state-of-the-art simulation capabilities for annular two-phase flow, especially in developing flow regions. It captures wave dynamics and their impact on mass and momentum transfer, validated against experimental data.
