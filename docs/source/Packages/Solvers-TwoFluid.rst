Two-fluid solver
================

The :mod:`Solvers.TwoFluid` module in **OpenSTREAM** provides classes and tools for simulating two-phase flows using a two-fluid approach. In this method, each phase (liquid and vapor) is modeled as an interpenetrating continuum with its own set of conservation equations for mass, momentum, and energy. This framework enables explicit representation of phase interactions, slip velocities, and non-equilibrium effects, making it well-suited for applications where phase separation, interfacial dynamics, and transient boiling phenomena are significant.

This module includes:

- Solver class for two-fluid-based flow simulations: :class:`Solvers.TwoFluid.TwoFluidSolver`
- Liquid and vapor field classes: :class:`Solvers.TwoFluid.Liquid`, :class:`Solvers.TwoFluid.Vapor`
- Mixture class: :class:`Solvers.TwoFluid.Mixture`
- Two-fluid primary properties: :attr:`Solvers.TwoFluid.Liquid.W`, :attr:`Solvers.TwoFluid.Liquid.U`, :attr:`Solvers.TwoFluid.Liquid.H`, :attr:`Solvers.TwoFluid.Vapor.W`, :attr:`Solvers.TwoFluid.Vapor.U`, :attr:`Solvers.TwoFluid.Vapor.H`
- Key solver class methods: :meth:`Solvers.TwoFluid.TwoFluidSolver.initializeSolver <Solvers.TwoFluid.TwoFluidSolver.TwoFluidSolver.initializeSolver>`, :meth:`Solvers.TwoFluid.TwoFluidSolver.solve`, :meth:`Solvers.TwoFluid.TwoFluidSolver.plotz <Solvers.TwoFluid.TwoFluidSolver.TwoFluidSolver.plotz>`
- Field class methods for calculating secondary two-fluid parameters.

----   

.. autoclass:: Solvers.TwoFluid.TwoFluidSolver
   :show-inheritance:
   :members:

----

.. automodule:: Solvers.TwoFluid
   :show-inheritance:
   :members:
.. :exclude-members: 
