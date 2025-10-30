Four-field model
================

The Four-Field Simulation Framework in OpenSTREAM extends the three-field model by explicitly modeling disturbance waves in addition to vapor, droplets, and base liquid film. This framework provides enhanced resolution of annular two-phase flow dynamics.

Governing Equations
-------------------

1. Mass Conservation

Base Film: :math:\frac{\partial}{\partial t}(W_b^n u_b^n) + \frac{\partial W_b^n}{\partial z} = \Pi_p^n D_b^n - \Gamma_{wb,b}^n + \Psi_w^n - \Psi_b^n

Disturbance Waves: :math:\frac{\partial}{\partial t}(W_w^n u_w^n) + \frac{\partial W_w^n}{\partial z} = \Pi_p^n D_w^n - E^n - \Gamma_{wb,w}^n - \Psi_w^n + \Psi_b^n

Where:

:math:W_b^n, :math:W_w^n are base film and wave mass flow rates
:math:u_b^n, :math:u_w^n are velocities
:math:D_b^n, :math:D_w^n are deposition fluxes
:math:\Gamma_{wb,b}^n, :math:\Gamma_{wb,w}^n are wall boiling fluxes
:math:\Psi_w^n, :math:\Psi_b^n are exchange fluxes between film and waves

2. Momentum Conservation

Base Film: :math:\rho_{ls} \delta_b^n \frac{\partial u_b^n}{\partial t} + u_b^n \frac{\partial u_b^n}{\partial z} = D_b^n (u_d - u_b^n) + \Psi_w^n (u_w^n - u_b^n) - \delta_b^n \frac{\partial p}{\partial z} + g \rho_{ls} + \beta_b^n \tau_{v,b}^n + (1 - \beta_b^n) \tau_{w,b}^n - \tau_{wall,b}^n

Disturbance Waves: :math:\rho_{ls} \delta_w^n \frac{\partial u_w^n}{\partial t} + u_w^n \frac{\partial u_w^n}{\partial z} = D_w^n (u_d - u_w^n) + \Psi_b^n (u_b^n - u_w^n) - \delta_w^n \frac{\partial p}{\partial z} + g \rho_{ls} + (1 - \beta_b^n) \tau_{v,w}^n - \tau_{w,b}^n

3. Energy Conservation

Base Film: :math:\Gamma_{wb,b}^n = \frac{q''_{wall,b}^n}{h_{vs} - h_{ls}}

Disturbance Waves: :math:\Gamma_{wb,w}^n = \frac{q''_{wall,w}^n}{h_{vs} - h_{ls}}

4. Wave Number Density Transport

:math:\frac{\partial N_w^n}{\partial t} + \frac{\partial}{\partial z}(u_w^n N_w^n) = \frac{N_{w,eq}^n - N_w^n}{t_{wRelax}}
Where:

:math:N_w^n is wave number density
:math:N_{w,eq}^n is equilibrium wave number density
:math:t_{wRelax} is relaxation time

Features and Assumptions
------------------------

Models intermittent wave transport and non-equilibrium wave dynamics
Assumes thermal equilibrium for energy equations
Includes wave-film exchange and wave number density evolution

Implementation Notes
--------------------

Implemented in the class:
FourFieldSolver
Key methods:
FourFieldSolver.solve_mass_conservation()
FourFieldSolver.solve_momentum_conservation()
FourFieldSolver.solve_energy_conservation()
FourFieldSolver.solve_wave_density_transport()
Properties:
FourFieldSolver.mass_flow_rate_base_film
FourFieldSolver.mass_flow_rate_waves
FourFieldSolver.velocity_base_film
FourFieldSolver.velocity_waves
FourFieldSolver.wave_number_density

Role in OpenSTREAM
------------------

The four-field model provides state-of-the-art simulation capabilities for annular two-phase flow, especially in developing flow regions. It captures wave dynamics and their impact on mass and momentum transfer, validated against experimental data.


End of theory section.
