Two-fluid solver
================

The :mod:`Solvers.TwoFluid` module in **openSTREAM** provides tools and classes for simulating multiphase flows using a two-fluid approach. This method treats each phase (liquid and vapor) as a separate interpenetrating continuum, with its own set of conservation equations for mass, momentum, and energy. This allows for explicit resolution of phase interactions, slip velocities, and non-equilibrium effects, making it suitable for applications where phase separation, interfacial dynamics, or transient boiling phenomena are significant.

This module includes:

- Solver class for mixture-based flow simulations: :class:`Solvers.TwoFluid.TwoFluidSolver`
- Liquid and vapor field classes: :class:`Solvers.TwoFluid.Liquid`, :class:`Solvers.TwoFluid.Vapor`
- Mixture class: :class:`Solvers.TwoFluid.Mixture`
- Mixture primary properties: :attr:`Solvers.TwoFluid.Liquid.W`, :attr:`Solvers.TwoFluid.Liquid.U`, :attr:`Solvers.TwoFluid.Liquid.H`, :attr:`Solvers.TwoFluid.Vapor.W`, :attr:`Solvers.TwoFluid.Vapor.U`, :attr:`Solvers.TwoFluid.Vapor.H`
- Key solver class methods: :meth:`Solvers.TwoFluid.TwoFluidSolver.initializeSolver <Solvers.TwoFluid.TwoFluidSolver.TwoFluidSolver.initializeSolver>`, :meth:`Solvers.TwoFluid.TwoFluidSolver.solve`, :meth:`Solvers.TwoFluid.TwoFluidSolver.plotz <Solvers.TwoFluid.TwoFluidSolver.TwoFluidSolver.plotz>`
- Field class methods for calculating secondary mixture and phase parameters.

----   

.. automodule:: Solvers.TwoFluid.TwoFluidSolver
   :show-inheritance:
   :members:

----

.. automodule:: Solvers.TwoFluid
   :show-inheritance:
   :members:
.. :exclude-members: 

----