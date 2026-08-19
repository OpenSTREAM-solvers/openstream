Four-field solver
=================

The :mod:`Solvers.FourField` module in **OpenSTREAM** provides tools and classes for simulating annular two-phase flows using a four-field approach. In this method, the liquid phase is represented by three distinct fields (base film, disturbance waves, and droplets), each governed by its own set of conservation equations for mass, momentum, and energy. The vapor phase is solved using the :mod:`Solvers.Mixture` module. This framework enables detailed modeling of liquid film structures, interfacial interactions, slip velocities, and hydrodynamic non-equilibrium effects, making it particularly suitable for annular boiling two-phase flow regimes where field separation and wave dynamics play a significant role.

This module includes:

- Solver class for four-field-based flow simulations: :class:`Solvers.FourField.FourFieldSolver`
- Base film, wave and drop field classes: :class:`Solvers.FourField.Base`, :class:`Solvers.FourField.Wave`, :class:`Solvers.FourField.Drop`
- Film class: :class:`Solvers.FourField.Film`
- Four-field primary properties: :attr:`Solvers.FourField.Base.W`, :attr:`Solvers.FourField.Base.U`, :attr:`Solvers.FourField.Base.H`, :attr:`Solvers.FourField.Wave.W`, :attr:`Solvers.FourField.Wave.U`, :attr:`Solvers.FourField.Wave.H`
- Key solver class methods: :meth:`Solvers.FourField.FourFieldSolver.initializeSolver <Solvers.FourField.FourFieldSolver.FourFieldSolver.initializeSolver>`, :meth:`Solvers.FourField.FourFieldSolver.solve`, :meth:`Solvers.FourField.FourFieldSolver.plotz <Solvers.FourField.FourFieldSolver.FourFieldSolver.plotz>`
- Field class methods for calculating secondary four-field parameters.

----   

.. autoclass:: Solvers.FourField.FourFieldSolver
   :show-inheritance:
   :members:

----

.. automodule:: Solvers.FourField
   :show-inheritance:
   :members:
.. :exclude-members: 

----