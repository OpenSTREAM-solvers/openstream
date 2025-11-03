Mixture solver
==============

The :mod:`Mixture Solver <Solvers.Mixture>` module in openSTREAM provides tools and classes for simulating multiphase flows using a mixture approach. This method treats the phases as a single continuum with averaged properties, making it suitable for cases where phase separation is minimal or not explicitly resolved.

This module includes:

- Solver (:class:`Solvers.Mixture.MixtureSolver`) class for mixture-based flow simulations.
- Field (:class:`Solvers.Mixture.Mixture`) and phase (:class:`Solvers.Mixture.Liquid`, :class:`Solvers.Mixture.Vapor`) class definitions.
- Parameter definitions for mixture properties like :attr:`mass flow rate <Solvers.Mixture.Mixture.W>`, :attr:`pressure <Solvers.Mixture.Mixture.P>`, and :attr:`enthalpy <Solvers.Mixture.Mixture.H>`.
- Solver class methods to :meth:`initialize <Solvers.Mixture.MixtureSolver.initializeSolver>`, :meth:`solve <Solvers.Mixture.MixtureSolver.solve>` mixture equations and to :meth:`plot <Solvers.Mixture.MixtureSolver.plotz>` results.
- Field class methods for calculating secondary mixture and phase parameters.

----

.. automodule:: Solvers.Mixture
   :show-inheritance:
   :members:
.. :exclude-members: 