Three-field model
=================

The Three-Field Simulation Framework in OpenSTREAM is designed for annular two-phase flow under thermal equilibrium conditions. It explicitly models three distinct flow fields: vapor, entrained droplets, and liquid film.

Governing equations
-------------------

**1. Mass conservation**

:math:`\frac{\partial}{\partial t}(W_f^n u_f^n) + \frac{\partial W_f^n}{\partial z} = \Pi_p^n D - E^n - \Gamma_{wb}^n`

Where:

- :math:`W_f^n` is the liquid film mass flow rate
- :math:`u_f^n` is the film velocity
- :math:`D` is drop deposition mass flux
- :math:`E` is film entrainment mass flux
- :math:`\Gamma_{wb}^n` is wall boiling mass flux

**2. Momentum conservation**

Liquid Film: :math:`\rho_{ls} \delta_f^n \frac{\partial u_f^n}{\partial t} + u_f^n \frac{\partial u_f^n}{\partial z} = (u_d - u_f^n) D - \delta_f^n \frac{\partial p}{\partial z} + \cos\theta g \rho_{ls} + \tau_{v,f}^n - \tau_{wall,f}^n`

Droplets: :math:`\rho_{ls} \frac{\partial u_d}{\partial t} + u_d \frac{\partial u_d}{\partial z} = \sum \Pi_p^n (u_f^n - u_d) E^n - \frac{\partial p}{\partial z} + \cos\theta g \rho_{ls} + A_d V_d \tau_{v,d}`

**3. Energy conservation**

Under thermal equilibrium: :math:`\Gamma_{wb}^n = \frac{{q^{\prime\prime}}_{wall}^n}{h_{vs} - h_{ls}}`

Where:

- :math:`\delta_f^n` is film thickness
- :math:`\tau_{v,f}^n`, :math:`\tau_{wall,f}^n` are interfacial and wall shear stresses
- :math:`A_d`, :math:`V_d` are drop interfacial area and volume
- :math:`h_{vs}`, :math:`h_{ls}` are saturated vapor and liquid enthalpies

Features and assumptions
------------------------

- Assumes thermal equilibrium (no temperature difference between phases)
- Applicable up to film dryout
- Models drop deposition and film entrainment
- Supports multi-wall geometries (e.g., annuli)

Implementation notes
--------------------

Implemented in the class:
    - :attr:`ThreeFieldSolver`
Key methods:
    - :attr:`ThreeFieldSolver.solve()`
Key properties:
    - :attr:`ThreeFieldSolver.film.W`
    - :attr:`ThreeFieldSolver.film.U`
    - :attr:`ThreeFieldSolver.drop.W`
    - :attr:`ThreeFieldSolver.drop.U`

Role in OpenSTREAM
------------------

The three-field model is used for advanced boiling water reactor (BWR) simulations and subchannel analysis. It provides detailed modeling of liquid film and droplet dynamics in annular flow regimes.

----
