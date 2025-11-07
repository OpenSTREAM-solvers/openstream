Mixture solver
==============

The :mod:`Mixture Solver <Solvers.Mixture>` module in openSTREAM provides tools and classes for simulating multiphase flows using a mixture approach. This method treats the phases as a single continuum with averaged properties, making it suitable for cases where phase separation is minimal or not explicitly resolved.

This module includes:

- Solver class for mixture-based flow simulations: :class:`Solvers.Mixture.MixtureSolver`
- Mixture field class: :class:`Solvers.Mixture.Mixture`
- Phase classes: :class:`Solvers.Mixture.Liquid`, :class:`Solvers.Mixture.Vapor`
- Mixture primary properties: :attr:`Solvers.Mixture.Mixture.W`, :attr:`Solvers.Mixture.Mixture.P`, :attr:`Solvers.Mixture.Mixture.H`
- Solver class methods: :meth:`Solvers.Mixture.MixtureSolver.initializeSolver <Solvers.Mixture.MixtureSolver.MixtureSolver.initializeSolver>`, :meth:`Solvers.Mixture.MixtureSolver.solve`, :meth:`Solvers.Mixture.MixtureSolver.plotz <Solvers.Mixture.MixtureSolver.MixtureSolver.plotz>`
- Field class methods for calculating secondary mixture and phase parameters.

----

.. automodule:: Solvers.Mixture.MixtureSolver
   :show-inheritance:
   :members:

----

.. automodule:: Solvers.Mixture
   :show-inheritance:
   :members:
.. :exclude-members: 

----