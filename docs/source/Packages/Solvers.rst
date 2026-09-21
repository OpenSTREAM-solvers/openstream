Solver
=======

The :mod:`Solvers` package defines the **OpenSTREAM** core solver modules and their associated superclasses. Each solver is tailored to simulate specific regimes of one-dimensional, two-phase flow, with increasing levels of physical detail and complexity.

Explore the available solver frameworks:

.. toctree::
   :maxdepth: 1
   :glob:
   
   Solvers-*

The following is a list of associated superclasses, each with its respective properties and methods. These foundational components provide shared functionality and structure across solver implementations.

- Abstract solver: :class:`Solvers.AbstractSolver`
- Abstract field: :class:`Solvers.AbstractField`
- Abstract phase: :class:`Solvers.AbstractPhase`
- Abstract film: :class:`Solvers.AbstractFilm`
- Solver plotter: :class:`Solvers.SolverPlotter`
- Solver state: :class:`Solvers.SolverState`

----

.. automodule:: Solvers
   :show-inheritance:
   :members: 
   :private-members:
.. :exclude-members: 
