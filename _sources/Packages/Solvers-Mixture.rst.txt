Mixture solver
==============

The :mod:`Solvers.Mixture` module in **OpenSTREAM** provides classes and tools for simulating two-phase flows using a mixture approach. In this method, all phases are treated as a single continuum with averaged properties, making it suitable for cases where phase separation is minimal or not explicitly resolved. Additionally, the solver supports a Mixture Relaxation Model (MRM), which introduces thermal non-equilibrium between phases by solving separate mass and energy conservation equations for the vapor phase.

This module includes:

- Solver class for mixture-based flow simulations: :class:`Solvers.Mixture.MixtureSolver`
- Mixture field class: :class:`Solvers.Mixture.Mixture`
- Phase classes: :class:`Solvers.Mixture.Liquid`, :class:`Solvers.Mixture.Vapor`
- Mixture primary properties: :attr:`Solvers.Mixture.Mixture.W`, :attr:`Solvers.Mixture.Mixture.P`, :attr:`Solvers.Mixture.Mixture.H`
- Key solver class methods: :meth:`Solvers.Mixture.MixtureSolver.initializeSolver <Solvers.Mixture.MixtureSolver.MixtureSolver.initializeSolver>`, :meth:`Solvers.Mixture.MixtureSolver.solve`, :meth:`Solvers.Mixture.MixtureSolver.plotz <Solvers.Mixture.MixtureSolver.MixtureSolver.plotz>`
- Field class methods for calculating secondary mixture and phase parameters.

----

.. autoclass:: Solvers.Mixture.MixtureSolver
   :show-inheritance:
   :members:

----

.. automodule:: Solvers.Mixture
   :show-inheritance:
   :members:
.. :exclude-members: 
