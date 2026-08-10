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

Recommended phase and field subscripts
--------------------------------------

The notation should distinguish between thermodynamic phases and computational fields. A phase is a physical state of matter, such as liquid or vapor. A field is a computationally resolved constituent with its own transported variables.

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - Subscript
     - Suggested meaning
     - Notes
   * - :math:`l`
     - liquid phase
     - Use for the liquid phase when the liquid is not split into several fields.
   * - :math:`g`
     - vapor phase
     - Use consistently for vapor or gas. Avoid switching between :math:`g` and :math:`v` unless required by a specific model.
   * - :math:`f`
     - liquid film
     - Use for the wall liquid-film field in annular-flow models.
   * - :math:`d`
     - droplets
     - Use for entrained liquid droplets in the vapor core.
   * - :math:`w`
     - wall
     - Use for wall quantities, such as :math:`T_w` or :math:`q''_w`.
   * - :math:`i`
     - interface
     - Use for interfacial quantities, such as :math:`a_i` or :math:`h_i`.
   * - :math:`m`
     - mixture
     - Use for mixture-averaged quantities.
   * - :math:`dw`
     - disturbance wave
     - Use for disturbance-wave quantities when a compact subscript is needed.

Recommended source-term notation
--------------------------------

Source terms should make clear which conserved quantity is affected and which interaction is represented.

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - Symbol
     - Suggested name
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

When source terms are written as net terms, the sign convention should be stated explicitly. A recommended convention is:

.. math::

   \Gamma_k > 0

for net mass added to field :math:`k`, and

.. math::

   \Gamma_k < 0

for net mass removed from field :math:`k`.

If pairwise transfer notation is used, the direction should be included in the subscript, for example:

.. math::

   \Gamma_{l \rightarrow g}

for evaporation from liquid to vapor, and

.. math::

   \Gamma_{g \rightarrow l}

for condensation from vapor to liquid.

Mixture quantities
------------------

Mixture quantities are typically denoted with the subscript :math:`m`. For example:

.. math::

   \rho_m = \sum_k \alpha_k \rho_k

where :math:`\rho_m` is the mixture density, :math:`\alpha_k` is the volume fraction of field or phase :math:`k`, and :math:`\rho_k` is the corresponding density.

A mass-weighted mixture velocity may be written as:

.. math::

   u_m = \frac{\sum_k \alpha_k \rho_k u_k}{\rho_m}

where :math:`u_m` is the mixture velocity and :math:`u_k` is the velocity of field or phase :math:`k`.

If a different averaging convention is used in a specific solver, define it locally in the corresponding theory page.

Common balance-equation structure
---------------------------------

A generic one-dimensional conservation equation may be written as:

.. math::
   :label: eq-generic-conservation

   \frac{\partial \mathbf{U}}{\partial t}
   + \frac{\partial \mathbf{F}}{\partial z}
   = \mathbf{S}

where :math:`\mathbf{U}` is the vector of conserved variables, :math:`\mathbf{F}` is the flux vector, and :math:`\mathbf{S}` is the source-term vector.

When referring to this equation from another page, use:

.. code-block:: rst

   Equation :eq:`eq-generic-conservation`

rather than manually typing the equation number.

Mass balance
~~~~~~~~~~~~

A generic field mass balance can be written as:

.. math::
   :label: eq-generic-field-mass

   \frac{\partial}{\partial t}\left(\alpha_k \rho_k\right)
   + \frac{\partial}{\partial z}\left(\alpha_k \rho_k u_k\right)
   = \Gamma_k

where :math:`\Gamma_k` is the net mass source to field :math:`k`.

Momentum balance
~~~~~~~~~~~~~~~~

A generic field momentum balance can be written as:

.. math::
   :label: eq-generic-field-momentum

   \frac{\partial}{\partial t}\left(\alpha_k \rho_k u_k\right)
   + \frac{\partial}{\partial z}\left(\alpha_k \rho_k u_k^2\right)
   = -\alpha_k \frac{\partial p}{\partial z} + M_k

where :math:`M_k` represents the net momentum source to field :math:`k`, including the effects that are retained in the selected model.

Energy balance
~~~~~~~~~~~~~~

A generic field energy balance can be written as:

.. math::
   :label: eq-generic-field-energy

   \frac{\partial}{\partial t}\left(\alpha_k \rho_k h_k\right)
   + \frac{\partial}{\partial z}\left(\alpha_k \rho_k u_k h_k\right)
   = Q_k

where :math:`Q_k` is the net energy source to field :math:`k`.

These generic equations are intended as notation examples. Solver-specific theory pages should provide the actual equations used by each formulation.

Closure-model notation
----------------------

Closure models should use notation that clearly identifies the modeled process. Recommended examples include:

.. list-table::
   :header-rows: 1
   :widths: 25 35 40

   * - Symbol
     - Suggested meaning
     - Typical use
   * - :math:`C_D`
     - drag coefficient
     - Interfacial or droplet drag model.
   * - :math:`f_w`
     - wall friction factor
     - Wall momentum loss.
   * - :math:`h_{tc}`
     - heat-transfer coefficient
     - Wall or interfacial heat transfer.
   * - :math:`a_i`
     - interfacial area concentration
     - Interfacial transfer models.
   * - :math:`\tau_w`
     - wall shear stress
     - Wall friction and pressure drop.
   * - :math:`\tau_i`
     - interfacial shear stress
     - Momentum exchange between fields.
   * - :math:`\tau_r`
     - relaxation time
     - Relaxation models.

Avoid using the same symbol for unrelated closures in different theory pages. If reuse is unavoidable, define the symbol locally and explicitly.

Relaxation notation
-------------------

Relaxation models are often written as:

.. math::
   :label: eq-generic-relaxation

   \frac{d \phi}{d t} = \frac{\phi^{eq} - \phi}{\tau_r}

where :math:`\phi` is the relaxing variable, :math:`\phi^{eq}` is its equilibrium or target value, and :math:`\tau_r` is the relaxation time.

For discretized forms, use notation that distinguishes the old, new, and equilibrium states. For example:

.. math::

   \phi^{n+1} = \phi^n + \Delta t \frac{\phi^{eq} - \phi^n}{\tau_r}

where :math:`n` and :math:`n+1` denote time levels and :math:`\Delta t` is the time-step size.

If both explicit Euler and exponential relaxation updates are documented, use consistent names such as:

* explicit Euler relaxation update
* exponential relaxation update

Equation labels and cross references
------------------------------------

All displayed equations that are referenced in the text should be labeled using the Sphinx ``:label:`` option:

.. code-block:: rst

   .. math::
      :label: eq-mixture-mass

      \frac{\partial \rho_m}{\partial t}
      + \frac{\partial}{\partial z}\left(\rho_m u_m\right)
      = 0

Then refer to the equation using:

.. code-block:: rst

   Equation :eq:`eq-mixture-mass`

Do not manually type equation numbers such as ``Equation (12)`` in the text, because the numbering may change when equations are added, removed, or reordered.

Recommended equation-label prefixes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Prefix
     - Use for
   * - ``eq-mixture-``
     - Mixture-model equations.
   * - ``eq-twofluid-``
     - Two-fluid-model equations.
   * - ``eq-threefield-``
     - Three-field-model equations.
   * - ``eq-fourfield-``
     - Four-field-model equations.
   * - ``eq-closure-``
     - Closure-model equations.
   * - ``eq-relaxation-``
     - Relaxation-model equations.
   * - ``eq-numerics-``
     - Numerical-method equations.

Examples:

.. code-block:: rst

   :label: eq-mixture-mass
   :label: eq-twofluid-vapor-momentum
   :label: eq-threefield-film-mass
   :label: eq-fourfield-wave-number-density
   :label: eq-relaxation-exponential-update

Cross-reference conventions
---------------------------

Use Sphinx roles consistently:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Role
     - Recommended use
   * - ``:doc:``
     - Link to another documentation page.
   * - ``:ref:``
     - Link to a labeled section, figure, table, or paragraph.
   * - ``:eq:``
     - Link to a labeled equation.
   * - ``:term:``
     - Link to a glossary entry.
   * - ``:class:``
     - Link to an API-documented class, when available.
   * - ``:meth:``
     - Link to an API-documented method, when available.
   * - ``:attr:``
     - Link to an API-documented property or attribute, when available.

Examples:

.. code-block:: rst

   See :doc:`theory/index` for the theory overview.

   The distinction between :term:`phase` and :term:`field` is important in multi-field models.

   The generic conservation form is given by Equation :eq:`eq-generic-conservation`.

   The implementation is documented in :class:`Solvers.AbstractSolver`.

Section-label conventions
~~~~~~~~~~~~~~~~~~~~~~~~~

Use explicit section labels for pages and major subsections that are referenced elsewhere:

.. code-block:: rst

   .. _notation-source-terms:

   Recommended source-term notation
   --------------------------------

Then refer to the section using:

.. code-block:: rst

   See :ref:`notation-source-terms`.

Recommended label prefixes include:

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Prefix
     - Use for
   * - ``notation-``
     - Sections in this notation page.
   * - ``theory-``
     - General theory sections.
   * - ``mixture-``
     - Mixture-model sections.
   * - ``twofluid-``
     - Two-fluid-model sections.
   * - ``threefield-``
     - Three-field-model sections.
   * - ``fourfield-``
     - Four-field-model sections.
   * - ``closure-``
     - Closure-model sections.
   * - ``numerics-``
     - Numerical-method sections.

Units
-----

Use SI units consistently unless a specific model, correlation, or input file requires otherwise. Define units in text or tables when variables are introduced.

.. list-table::
   :header-rows: 1
   :widths: 20 30 50

   * - Quantity
     - Typical unit
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

Style recommendations
---------------------

* Use roman text in equations for descriptive labels only when needed, for example :math:`\phi^{eq}` for equilibrium value.
* Use italic mathematical symbols for variables.
* Avoid changing notation between theory pages unless a model-specific reason exists.
* Avoid using the same symbol for both a field index and a physical variable.
* Prefer descriptive equation labels over numbered labels.
* Define every symbol near its first use, even if it also appears in this notation page.
* Use :term:`closure model` consistently when referring to implemented model components.
* Use :term:`thermal non-equilibrium` and :term:`hydrodynamic non-equilibrium` consistently.
* Use :term:`field` and :term:`phase` according to their distinct meanings.

Suggested toctree entry
-----------------------

If this file is placed under ``Guides``, add it to the relevant ``toctree`` as follows:

.. code-block:: rst

   .. toctree::
      :maxdepth: 2

      theory/index
      tutorials
      glossary
      notation
