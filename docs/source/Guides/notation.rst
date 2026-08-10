Notation
========

This page summarizes the notation conventions used in the OpenSTREAM documentation. The goal is to keep the theory pages, solver descriptions, closure model documentation, and implementation notes consistent across the mixture, two-fluid, three-field, and four-field formulations.

General conventions
-------------------

OpenSTREAM uses one-dimensional, cross-section-averaged conservation equations. Unless otherwise stated, the independent variables are time and the axial coordinate:

.. math::

   t \quad \text{and} \quad z

where :math:`t` is time and :math:`z` is the axial coordinate along the flow channel.

The following conventions are recommended throughout the documentation:

* Use :math:`z` for the axial coordinate.
* Use :math:`t` for time.
* Use :math:`k` as a generic field or phase index when no specific constituent is intended.
* Use subscripts to identify phases, fields, interfaces, and walls.
* Use superscripts for time levels, iteration counters, or model-specific states only when needed.
* Define all symbols immediately after the equation in which they first appear.

Primary variables
-----------------

.. list-table::
   :header-rows: 1
   :widths: 20 25 55

   * - Symbol
     - Suggested name
     - Meaning
   * - :math:`t`
     - time
     - Time coordinate.
   * - :math:`z`
     - axial coordinate
     - One-dimensional spatial coordinate along the flow path.
   * - :math:`A`
     - flow area
     - Cross-sectional flow area.
   * - :math:`P_w`
     - wetted perimeter
     - Wall perimeter in contact with the fluid or liquid film.
   * - :math:`D_h`
     - hydraulic diameter
     - Hydraulic diameter of the channel.
   * - :math:`\alpha_k`
     - volume fraction
     - Volume fraction of field or phase :math:`k`.
   * - :math:`\rho_k`
     - density
     - Density of field or phase :math:`k`.
   * - :math:`u_k`
     - velocity
     - Axial velocity of field or phase :math:`k`.
   * - :math:`p`
     - pressure
     - Pressure. In most one-dimensional formulations, pressure is shared among fields.
   * - :math:`T_k`
     - temperature
     - Temperature of field or phase :math:`k`.
   * - :math:`h_k`
     - specific enthalpy
     - Specific enthalpy of field or phase :math:`k`.
   * - :math:`e_k`
     - specific internal energy
     - Specific internal energy of field or phase :math:`k`.
   * - :math:`E_k`
     - total specific energy
     - Total specific energy of field or phase :math:`k`, if used.
   * - :math:`x`
     - vapor quality
     - Vapor mass fraction in a two-phase mixture. Use only when this definition is intended.
   * - :math:`q''_w`
     - wall heat flux
     - Heat flux imposed at, or transferred through, the wall.
   * - :math:`g`
     - gravitational acceleration
     - Gravitational acceleration projected along the relevant direction.

Units
-----

SI units are used consistently unless a specific model, correlation, or input file requires otherwise.

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - Quantity
     - Unit
     - Notes
   * - Length
     - m
     - Use for :math:`z`, hydraulic diameter, and channel dimensions.
   * - Time
     - s
     - Use for :math:`t`, time steps, and relaxation times.
   * - Pressure
     - Pa
     - Use for absolute pressure unless otherwise stated.
   * - Temperature
     - K
     - Use kelvin in equations. Celsius may be used in user-facing examples if clearly stated.
   * - Density
     - kg/m\ :sup:`3`
     - Use for phase, field, and mixture density.
   * - Velocity
     - m/s
     - Use for axial velocities.
   * - Mass flow rate
     - kg/s
     - Use for total or field-specific mass flow rates.
   * - Mass flux
     - kg/m\ :sup:`2`/s
     - Use for area-normalized mass flow rate.
   * - Heat flux
     - W/m\ :sup:`2`
     - Use for wall heat flux.
   * - Specific enthalpy
     - J/kg
     - Use for phase or field enthalpy.

Phase and field subscripts
-------------------------

The notation distinguishes between thermodynamic phases and computational fields. A phase is a physical state of matter, such as liquid or vapor. A field is a computationally resolved constituent with its own transported variables.

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - Subscript
     - Meaning
     - Notes
   * - :math:`l`
     - liquid phase
     - Used for iquid phase.
   * - :math:`g`
     - vapor phase
     - Used consistently for vapor or gas.
   * - :math:`f`
     - liquid film
     - Used for the wall liquid-film field in annular flow models.
   * - :math:`d`
     - droplets
     - Used for entrained liquid droplets in the vapor core.
   * - :math:`wall`
     - wall
     - Used for wall quantities, such as :math:`T_{wall}` or :math:`q''_{wall}`.
   * - :math:`i`
     - interface
     - Used for interfacial quantities, such as :math:`a_i` or :math:`htc_i`.
   * - :math:`w`
     - disturbance wave
     - Use for disturbance wave quantities when a compact subscript is needed.

Source-term notation
--------------------------------

Source terms make it clear which conserved quantity is affected and which interaction is represented.

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - Symbol
     - Name
     - Meaning
   * - :math:`\Gamma_k`
     - mass source
     - Net mass source to field or phase :math:`k`.
   * - :math:`M_k`
     - momentum source
     - Net momentum source to field or phase :math:`k`.
   * - :math:`Q_k`
     - energy source
     - Net energy source to field or phase :math:`k`.
   * - :math:`\Gamma_{a \rightarrow b}`
     - mass transfer rate
     - Mass transferred from field :math:`a` to field :math:`b`.
   * - :math:`M_{a \rightarrow b}`
     - momentum transfer
     - Momentum transferred from field :math:`a` to field :math:`b`.
   * - :math:`Q_{a \rightarrow b}`
     - heat or energy transfer
     - Energy transferred from field :math:`a` to field :math:`b`.

Conservation equation structure
---------------------------------

A generic one-dimensional conservation equation may be written as:

.. math::
   :label: eq-generic-conservation

   \frac{\partial \mathbf{U}}{\partial t}
   + \frac{\partial \mathbf{F}}{\partial z}
   = \mathbf{S}

where :math:`\mathbf{U}` is the vector of conserved variables, :math:`\mathbf{F}` is the flux vector, and :math:`\mathbf{S}` is the source-term vector.

Mass balance
~~~~~~~~~~~~

A generic field mass balance is written as:

.. math::
   :label: eq-generic-field-mass

   \frac{\partial}{\partial t}\left(\alpha_k \rho_k\right)
   + \frac{\partial}{\partial z}\left(\alpha_k \rho_k u_k\right)
   = \Gamma_k

where :math:`\Gamma_k` is the net mass source to field :math:`k`.

Momentum balance
~~~~~~~~~~~~~~~~

A generic field momentum balance is written as:

.. math::
   :label: eq-generic-field-momentum

   \frac{\partial}{\partial t}\left(\alpha_k \rho_k u_k\right)
   + \frac{\partial}{\partial z}\left(\alpha_k \rho_k u_k^2\right)
   = -\alpha_k \frac{\partial p}{\partial z} + M_k

where :math:`M_k` represents the net momentum source to field :math:`k`, including the effects that are retained in the selected model.

Energy balance
~~~~~~~~~~~~~~

A generic field energy balance is written as:

.. math::
   :label: eq-generic-field-energy

   \frac{\partial}{\partial t}\left(\alpha_k \rho_k h_k\right)
   + \frac{\partial}{\partial z}\left(\alpha_k \rho_k u_k h_k\right)
   = Q_k

where :math:`Q_k` is the net energy source to field :math:`k`.

These generic equations are intended as notation examples. Solver-specific theory pages should provide the actual equations used by each formulation.

Closure model notation
----------------------

Closure models use notation that clearly identifies the modeled process. Examples include:

.. list-table::
   :header-rows: 1
   :widths: 25 35 40

   * - Symbol
     - Suggested meaning
     - Typical use
   * - :math:`C_D`
     - drag coefficient
     - Interfacial or droplet drag model.
   * - :math:`f_{wall}`
     - wall friction factor
     - Wall momentum loss.
   * - :math:`htc_{wall}`
     - Wall heat-transfer coefficient
     - Wall heat transfer.
   * - :math:`htc_i`
     - Interfacial heat-transfer coefficient
     - Interfacial heat transfer.
   * - :math:`a_i`
     - interfacial area concentration
     - Interfacial transfer models.
   * - :math:`\tau_{wall}`
     - wall shear stress
     - Wall friction and pressure drop.
   * - :math:`\tau_i`
     - interfacial shear stress
     - Momentum exchange between fields.
   * - :math:`\t_{relax}`
     - relaxation time
     - Relaxation models.
