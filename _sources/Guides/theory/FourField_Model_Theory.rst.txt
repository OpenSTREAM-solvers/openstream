Four-field model
================

The four-field simulation framework in **OpenSTREAM** extends the traditional three-field model by explicitly representing disturbance waves, in addition to vapor, droplets, and the base liquid film. This modeling approach was originally developed in :cite:t:LECORREMODEL and :cite:t:LeCorre2022NURETH19. It provides improved resolution of annular two-phase flow dynamics, enabling more accurate and detailed simulations.

The four-field model serves several key roles within OpenSTREAM:

- Wave-resolved modeling: Separates the liquid film into base film and disturbance waves, capturing their distinct transport behaviors and interactions.
- Non-equilibrium dynamics: Includes a Boltzmann-type wave number density transport equation to simulate wave formation, merging, and dissipation.
- Enhanced predictive capability: Enables detailed simulation of film dryout, wave-driven mass transport, and hydrodynamic transitions in developing annular flow.

By explicitly modeling disturbance waves and their interactions with other flow fields, the four-field framework offers state-of-the-art capabilities for simulating complex annular flow phenomena, including intermittent film dryout.

An overview of the four-field model implemented in OpenSTREAM is provided below. A more detailed derivation and theoretical background can be found in :cite:t:LeCorre2025OpenSTREAM and :cite:t:LECORREMODEL.

Governing equations
-------------------

**1. Mass conservation**

Base Film: :math:`\frac{\partial}{\partial t}(W_b^n u_b^n) + \frac{\partial W_b^n}{\partial z} = \Pi_p^n D_b^n - \Gamma_{wb,b}^n + \Psi_w^n - \Psi_b^n`

Disturbance Waves: :math:`\frac{\partial}{\partial t}(W_w^n u_w^n) + \frac{\partial W_w^n}{\partial z} = \Pi_p^n D_w^n - E^n - \Gamma_{wb,w}^n - \Psi_w^n + \Psi_b^n`

where:

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

where:

- :math:`N_w^n` is wave number density
- :math:`N_w^{eq,n}` is equilibrium wave number density
- :math:`t_w^{Relax}` is relaxation time

Closure relations
-----------------

To complete the conservation equations, several closure relations are required:

- Same closure relations as for the three-field model
- 

The selected closure models are defined in the OpenSTREAM model file, chosen from the available options listed in :mod:`InputEnums`. If not explicitly specified by the user, default models are applied as defined in :class:`Inputs.Model`. All closure relations are implemented in :class:`Solvers.FourField.Wave` and :class:`Solvers.FourField.Base`, which the users can modify to suit specific simulation needs.

The thermodynamic properties for each phase are computed using `CoolProp <https://coolprop.org/>`_, an open-source thermophysical property library that provides accurate equations of state and transport properties for a wide range of fluids.

Features and assumptions
------------------------

- Models intermittent wave transport and non-equilibrium wave dynamics
- Assumes thermal equilibrium for energy equations
- Includes wave-film exchange and wave number density evolution

Role in OpenSTREAM
------------------

The four-field model provides state-of-the-art simulation capabilities for annular two-phase flow, especially in developing flow regions. It captures wave dynamics and their impact on mass and momentum transfer, validated against experimental data.

----

Implementation notes
--------------------

Package

- :mod:`Solvers`

Module

- :mod:`Solvers.FourField`

Four-field solver class

- :class:`Solvers.FourField.FourFieldSolver`

Field classes

- :class:`Solvers.FourField.Wave`
- :class:`Solvers.FourField.Base`
- :class:`Solvers.FourField.Drop`

Key solver methods

- :meth:`Solvers.FourField.FourFieldSolver.solve()`

Key field properties:

- :attr:`Solvers.FourField.Wave.W`
- :attr:`Solvers.FourField.Wave.U`
- :attr:`Solvers.FourField.Wave.FREQUENCY`
- :attr:`Solvers.FourField.Base.W`
- :attr:`Solvers.FourField.Base.U`
- :attr:`Solvers.FourField.Drop.W`
- :attr:`Solvers.FourField.Drop.U`
