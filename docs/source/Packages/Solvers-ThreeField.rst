Three-field solver
==================

The :mod:`Solvers.ThreeField` module in **OpenSTREAM** provides classes and tools for simulating annular two-phase flows using a three-field approach. In this method, the two liquid fields (film and droplets) are treated separately, each governed by its own set of conservation equations for mass and momentum, while the current formulation assumes thermal equilibrium. The vapor phase is solved using the :mod:`Solvers.Mixture` module. This framework enables explicit modeling of interactions between the film and droplet liquid fields, slip velocities, and hydrodynamic non-equilibrium effects, making it well-suited for applications involving annular boiling two-phase flow regimes where field separation and interfacial dynamics are significant.

This module includes:

- Solver class for three-field-based flow simulations: :class:`Solvers.ThreeField.ThreeFieldSolver`
- Film and drop field classes: :class:`Solvers.ThreeField.Film`, :class:`Solvers.ThreeField.Drop`
- Three-field primary properties: :attr:`Solvers.ThreeField.Film.W`, :attr:`Solvers.ThreeField.Film.U`, :attr:`Solvers.ThreeField.Film.H`, :attr:`Solvers.ThreeField.Drop.W`, :attr:`Solvers.ThreeField.Drop.U`, :attr:`Solvers.ThreeField.Drop.H`
- Key solver class methods: :meth:`Solvers.ThreeField.ThreeFieldSolver.initializeSolver <Solvers.ThreeField.ThreeFieldSolver.ThreeFieldSolver.initializeSolver>`, :meth:`Solvers.ThreeField.ThreeFieldSolver.solve`, :meth:`Solvers.ThreeField.ThreeFieldSolver.plotz <Solvers.ThreeField.ThreeFieldSolver.ThreeFieldSolver.plotz>`
- Field class methods for calculating secondary three-field parameters.

----   

.. autoclass:: Solvers.ThreeField.ThreeFieldSolver
   :show-inheritance:
   :members:

----

.. automodule:: Solvers.ThreeField
   :show-inheritance:
   :members:
.. :exclude-members: 
