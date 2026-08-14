OpenSTREAM FAQ
==============

This page answers common questions about installing, configuring, running,
and extending **OpenSTREAM**. Click a question to display its answer.

Getting started
---------------

.. dropdown:: What is OpenSTREAM?
   :animate: fade-in-slide-down
   :chevron: right-down

   **OpenSTREAM**, short for *Open Solvers for Two-phase flow Research,
   Engineering Analysis and Modeling*, is an open-source, object-oriented
   MATLAB environment for simulating one-dimensional, multi-field,
   liquid-vapor two-phase flows in straight channels.

   OpenSTREAM includes four solver frameworks:

   * a mixture solver;
   * a two-fluid solver;
   * a three-field solver for annular two-phase flow;
   * a four-field solver that separates the liquid film into base-film and
     disturbance-wave fields.

.. dropdown:: What should I read first?
   :animate: fade-in-slide-down
   :chevron: right-down

   A suggested learning path is:

   #. Follow the installation instructions in the Usage section.
   #. Run **Tutorial #1: OpenSTREAM Quick Start**.
   #. Continue with the solver-specific tutorial that matches your needs.
   #. Consult the theory pages for governing equations and assumptions.
   #. Use the package reference for available model options and methods.

.. dropdown:: How do I make OpenSTREAM available in MATLAB?
   :animate: fade-in-slide-down
   :chevron: right-down

   Add the OpenSTREAM root folder to the MATLAB search path. When running
   a tutorial from the ``tutorials`` folder:

   .. code-block:: matlab

      osp = './..';
      addpath(osp);

   You can check whether MATLAB finds the relevant classes with:

   .. code-block:: matlab

      which Inputs.InputSet
      which Solvers.Mixture.MixtureSolver







This page answers common questions about installing, configuring, running,and extending **OpenSTREAM**. For a first simulation, begin with :ref:`Tutorial #1 <tutorials>`. For mathematical details and model assumptions, consult the theory overview and the individual solver pages.

Getting started
---------------

What is OpenSTREAM?
~~~~~~~~~~~~~~~~~~~

**OpenSTREAM**, short for *Open Solvers for Two-phase flow Research,
Engineering Analysis and Modeling*, is an open-source, object-oriented
MATLAB environment for simulating one-dimensional, multi-field,
liquid-vapor two-phase flows in straight channels.

OpenSTREAM includes four solver frameworks:

* a mixture solver;
* a two-fluid solver;
* a three-field solver for annular two-phase flow;
* a four-field solver that separates the liquid film into base-film and
  disturbance-wave fields.

The solvers provide different levels of physical detail and are intended
to support education, model development, performance evaluation, and
validation.

What should I read first?
~~~~~~~~~~~~~~~~~~~~~~~~~

A suggested learning path is:

#. Follow the installation instructions in the :doc:`Usage <../usage>`
   section.
#. Run **Tutorial #1: OpenSTREAM Quick Start**.
#. Continue with the solver-specific tutorial that matches your needs:

   * Tutorial #2 for the mixture solver;
   * Tutorial #3 for the two-fluid solver;
   * Tutorial #4 for the three-field solver;
   * Tutorial #5 for the four-field solver.

#. Use the theory pages to understand the governing equations and
   assumptions.
#. Use the package reference to inspect available model options, object
   properties, and methods.

The tutorials are MATLAB Live Scripts and are intended to be run
interactively.

How do I make OpenSTREAM available in MATLAB?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add the OpenSTREAM root folder to the MATLAB search path. For example,
when running a tutorial from the ``tutorials`` folder:

.. code-block:: matlab

   osp = './..';
   addpath(osp);

If MATLAB cannot find a class such as ``InputSet`` or ``MixtureSolver``,
verify that:

* the OpenSTREAM root folder is the expected folder;
* the repository was cloned completely;
* required submodules are present;
* the current MATLAB path includes the OpenSTREAM root folder.

You can inspect the resolved location of a class with:

.. code-block:: matlab

   which Inputs.InputSet
   which Solvers.Mixture.MixtureSolver

Why does OpenSTREAM require Python?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OpenSTREAM uses the Python version of **CoolProp** to calculate fluid
thermophysical properties. ``CoolPropWrapper`` provides the interface
between MATLAB and Python.

MATLAB must therefore be configured to use a compatible Python
installation. Check the active Python environment with:

.. code-block:: matlab

   pyenv

You can test the property interface with:

.. code-block:: matlab

   cp = CoolPropWrapper.CoolPropWrapper();

If Python or CoolProp cannot be loaded, follow the MATLAB-Python
compatibility and CoolPropWrapper setup instructions in the installation
section.

Which MATLAB version should I use?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use a MATLAB release compatible with the code version and with a supported
Python version. The documentation build and distributed tutorials should
state the MATLAB release used for their preparation.

When reproducing or reporting a result, record the MATLAB release with:

.. code-block:: matlab

   version('-release')

Also record the Python and CoolProp versions when fluid-property behavior
is relevant.

Running simulations
-------------------

What is the minimum workflow for running a case?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A basic mixture-solver calculation consists of four steps:

#. import the required packages;
#. construct an ``InputSet``;
#. construct the solver;
#. call ``solve``.

For example:

.. code-block:: matlab

   import Inputs.*
   import Solvers.*
   import Solvers.Mixture.*

   inputSet = InputSet( ...
       modelFilePath          = './inputs/models.inp', ...
       modelID                = 'TUTORIAL1', ...
       optionsFilePath        = './inputs/options.inp', ...
       optionsID              = 'DEFAULT', ...
       geometryFilePath       = './inputs/geom.inp', ...
       geometryID             = 'TUTORIAL1', ...
       bcFilePath             = './inputs/tutorial1.inp', ...
       sessionParentDir       = fullfile(pwd,'outputs'), ...
       overwriteSessionFiles = true, ...
       LOGMODE                = 'BOTH');

   mixSolver = MixtureSolver(inputSet);
   mixSolver.solve();
   mixSolver.plotz();

The supplied tutorials contain complete examples for every solver.

How are OpenSTREAM inputs organized?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An OpenSTREAM case is assembled from separate input categories:

* **Model inputs** select physical models and closure models.
* **Numerical options** control time steps, iterations, relaxation factors,
  and convergence criteria.
* **Geometry inputs** define the channel length, flow area, wall
  perimeters, and orientation.
* **Boundary conditions** define pressure, inlet enthalpy, mass flow,
  power, and axial power distribution.

A file may contain several sets of inputs. An identifier such as
``TUTORIAL1`` or ``DEFAULT`` selects the required set.

This separation makes it possible to reuse one geometry with several
physical-model or boundary-condition configurations.

What happens if I do not specify a model or numerical option?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Unspecified entries use the default values defined by the corresponding
input class, principally ``Inputs.Model`` and ``Inputs.Options``.

Default values make simple cases easier to configure, but they should not
be treated as universally appropriate. For research or validation work,
review and document all influential model and numerical selections.

Why does MATLAB print many default-value warnings?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The warnings identify input properties that were not explicitly specified
and therefore use their class defaults.

These messages are useful when developing or reviewing a case. Tutorials
may temporarily suppress them to keep the displayed output concise:

.. code-block:: matlab

   warning off
   inputSet = InputSet(...);
   warning on

Do not suppress warnings routinely until the input configuration has been
reviewed. An unexpected warning can reveal a misspelled, unsupported, or
omitted input.

Why does OpenSTREAM report that an input entry was not used?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The input parser can report entries that remain after recognized
properties have been processed. Common causes include:

* a misspelled keyword;
* a keyword that does not belong to the selected input class;
* an obsolete keyword;
* an entry intended for another model configuration.

Check the spelling against ``Inputs.Model``, ``Inputs.Options``,
``Inputs.Geometry``, or the relevant package-reference page. Do not assume
that an unused entry affected the simulation.

How do I define a steady-state calculation?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A boundary-condition file containing a single time entry defines a
steady-state case.

The solver obtains the steady-state solution through pseudo-time
advancement. The pseudo-time sequence is a numerical procedure used to
approach a stationary solution and should not be interpreted as a physical
transient.

How do I define a transient calculation?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Provide boundary-condition values at multiple physical times. Depending on
the boundary-condition interface, pressure, inlet enthalpy, inlet mass flow,
power, and axial power distribution can vary with time.

The solver first calculates the initial steady state. The physical
transient proceeds only after the initial solution has converged.

The physical time step is controlled through the numerical options. A
time-step sensitivity study is recommended when transient timing or peak
values are important.

Why is the mixture solver run before the other solvers?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The two-fluid, three-field, and four-field solvers use a solved mixture
solution for initialization. They also reuse information from the mixture
solution, including the pressure-gradient solution.

A solved mixture solver can be passed explicitly:

.. code-block:: matlab

   mixSolver = MixtureSolver(inputSet);
   mixSolver.solve();

   twfSolver = TwoFluidSolver(inputSet, mixSolver);
   tfSolver  = ThreeFieldSolver(inputSet, mixSolver);
   ffSolver  = FourFieldSolver(inputSet, mixSolver);

If a mixture solver is not supplied, the advanced solver constructor
creates one and solves it when required. Passing an existing solved object
avoids repeating the same mixture calculation.

Can I call ``solve`` more than once on the same solver object?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A solver object is intended to represent a specific initialized
calculation. Calling ``solve`` again on an already solved object can produce
an error indicating that the solver must be reinitialized.

For a new calculation, construct a new ``InputSet`` and solver object. This
also keeps the simulation configuration and stored results clearly
separated.

Choosing a solver
-----------------

Which solver should I use?
~~~~~~~~~~~~~~~~~~~~~~~~~~

The appropriate solver depends on the physical phenomena and level of
detail required.

**Mixture solver**
   Use for robust initialization, efficient calculations with mixture
   quantities, hydrodynamically coupled phases, and mixture-based thermal
   non-equilibrium models.

**Two-fluid solver**
   Use when separate liquid and vapor mass, momentum, and energy behavior
   is needed. The solver can represent different phase velocities,
   enthalpies, and temperatures.

**Three-field solver**
   Use for annular two-phase flow when the liquid distribution between a
   wall film and entrained droplets is important.

**Four-field solver**
   Use for annular two-phase flow when the liquid film must be separated
   into base-film and disturbance-wave fields and wave transport is part of
   the analysis.

Increasing the number of fields does not automatically make a simulation
more accurate. Every solver has assumptions and closure models that must be
appropriate for the application.

What is the difference between a phase and a field?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A **phase** is a thermodynamic state of matter, such as liquid or vapor.

A **field** is a computationally resolved constituent with its own
transported variables or conservation equations. One phase can be
represented by more than one field. For example, the three-field solver
represents the liquid phase through a wall-film field and a droplet field.

The four-field solver further divides the wall film into a base-film field
and a disturbance-wave field.

Are the three-field and four-field solvers thermal
non-equilibrium models?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The current three-field and four-field formulations assume thermal
equilibrium. Their additional detail concerns the hydrodynamic distribution
and transport of the liquid fields.

Use the mixture relaxation model or the two-fluid solver when separate
thermal behavior is required, subject to the assumptions and implemented
closure models of the selected framework.

Where do the three-field and four-field equations begin?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The separate annular-flow field equations are solved from the predicted
onset of annular flow. Upstream of that location, mixture-solver results
are used to initialize the field quantities.

The onset model, the initial film-droplet split, and, for the four-field
solver, the initial base-wave split can therefore influence the solution
near the transition.

Why can results near the onset of annular flow be sensitive?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The initial liquid distribution among film, droplets, base film, and waves
depends on selected onset and field-splitting models. Entrainment and
deposition then redistribute liquid as the solution develops downstream.

When the region near annular-flow onset is important, examine sensitivity
to:

* the onset-of-annular-flow model;
* the initial entrained-droplet fraction;
* the initial base-film and wave split;
* entrainment and deposition models;
* spatial resolution.

The selected assumptions and sensitivity results should be documented.

Should entrainment and deposition models be selected together?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Yes. Entrainment and deposition are coupled processes that exchange liquid
between the film and droplet fields. When available, use a consistent
entrainment and deposition model family unless there is a documented reason
to combine different models.

Numerical convergence
---------------------

What is the difference between point convergence and steady-state
convergence?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

At each axial node and time step, OpenSTREAM performs local point
iterations for the nonlinear equations. **Point convergence** refers to the
change in solved variables between these local iterations.

For a steady-state calculation, OpenSTREAM also compares solutions between
successive pseudo-time steps. **Steady-state convergence** refers to these
temporal changes becoming smaller than the specified steady-state
criteria.

A calculation therefore needs adequately converged local iterations and an
adequately converged pseudo-time solution.

What does ``solveMode='NULL'`` mean in plotting methods?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``NULL`` solve mode displays the pseudo-time history used to obtain the
initial steady-state solution. It does not represent the physical
transient.

For example:

.. code-block:: matlab

   solver.plott( ...
       solver.NZ, ...
       'display', {'W','U'}, ...
       'solveMode', 'NULL');

Use the regular or ``REAL`` mode for the stored physical solution.

What should I do if the steady-state calculation does not converge?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Start with the information printed by the solver:

* identify the node with the largest point-iteration count;
* identify which variable has the largest residual;
* inspect the final solver state;
* plot the pseudo-time history with ``solveMode='NULL'``;
* check the model, geometry, and boundary-condition warnings;
* verify that units and input values are physically reasonable.

Numerical options that may affect convergence include:

* maximum point iterations;
* maximum steady-state pseudo-time iterations;
* pseudo-time step;
* variable-specific relaxation factors;
* pointwise convergence criteria;
* steady-state convergence criteria.

Change one numerical setting at a time. After convergence improves, verify
that the converged physical result has not changed materially.

Why was my transient skipped?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The physical transient is not calculated when the initial steady-state
solution fails to converge. The solver log indicates that the transient is
being skipped.

Inspect the initial pseudo-time solution, correct any input or model
problems, and obtain a converged initial state before interpreting transient
results.

Can a converged calculation still be inaccurate?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Yes. Numerical convergence indicates that the implemented discrete
equations have been solved to the selected tolerances. It does not establish
that:

* the spatial mesh is sufficiently refined;
* the physical time step is sufficiently small;
* the selected closure models are valid for the conditions;
* the one-dimensional assumptions are appropriate;
* the model has been validated for the application.

Mesh sensitivity, time-step sensitivity, conservation checks, and
comparison with appropriate reference data remain necessary.

Results and post-processing
---------------------------

How do I display results?
~~~~~~~~~~~~~~~~~~~~~~~~~

The solver classes provide plotting methods for common result types.

``plotz``
   Plots axial distributions. Multiple physical time indices can produce an
   animated axial plot.

``plott``
   Plots time histories at a selected axial location.

``plotzt``
   Plots time-elevation distributions where implemented.

For example:

.. code-block:: matlab

   mixSolver.plotz( ...
       'display', {'W','VR'}, ...
       'arrangement', 'horizontal', ...
       'resize', 1);

The available display names depend on the selected solver. Consult the
corresponding solver class in the package reference.

Why are Live Script outputs shown beside the code?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MATLAB Live Editor can display output either beside the code or inline
below it. The OpenSTREAM tutorials are designed for **inline output**, so
that figures and results appear immediately below the code that generates
them.

In the MATLAB Live Editor, select the output-layout option that places
output below the code, then save the Live Script.

Can I access the results without using the built-in plots?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Yes. Solver objects retain their solution objects and arrays. Examples
include:

* mixture variables in ``mixSolver.mixture``;
* liquid and vapor variables in ``twfSolver.liquid`` and
  ``twfSolver.vapor``;
* film and droplet variables in ``tfSolver.film`` and
  ``tfSolver.drop``;
* base-film and wave variables through the four-field film object.

The package reference lists the available properties and methods. Check the
dimensions of a property before processing it because arrays may vary over
axial position, time, and wall index.

How do I save a solver object?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the solver ``save`` method:

.. code-block:: matlab

   mixSolver.save( ...
       'name', 'mixSolver', ...
       'showpath', true);

The solver object contains the imported inputs, solution objects, and
associated simulation information. Saving the object allows later
post-processing without repeating the calculation.

Where are simulation outputs stored?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``sessionParentDir`` argument defines the parent output folder. Each
solver uses its session infrastructure to store logs and requested results.

For example:

.. code-block:: matlab

   sessionParentDir = fullfile(pwd,'outputs');

Use a separate session directory or case name for parameter studies. Be
careful with:

.. code-block:: matlab

   overwriteSessionFiles = true

because existing files for the corresponding session may be replaced.

Why do my plots show results only from the onset of annular flow?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The three-field and four-field plotting functions can restrict
field-specific results to the annular-flow region. This is appropriate
because the separate film, droplet, base-film, and wave equations apply from
the onset of annular flow.

Where supported, set the ``annular`` plotting option to ``false`` to inspect
initialization outside that region:

.. code-block:: matlab

   solver.plotz( ...
       'display', 'W', ...
       'annular', false);

Interpret pre-annular field values as initialization quantities rather than
as a complete pre-annular multi-field model.

Physical scope and limitations
------------------------------

What geometries can OpenSTREAM represent?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OpenSTREAM represents one-dimensional flow in straight channels.
Cross-sectional geometry is described through averaged quantities such as
flow area and wall perimeter.

The formulation supports multi-wall channel representations, allowing
different wall surfaces and heating distributions to be considered.
Examples may include tubes, annuli, rectangular channels, and simplified
small rod-bundle representations when the one-dimensional approximation is
appropriate.

OpenSTREAM does not resolve bends, crossflow, or detailed three-dimensional
velocity and temperature distributions.

What units should I use?
~~~~~~~~~~~~~~~~~~~~~~~~

OpenSTREAM uses SI units unless a specific input or model explicitly states
otherwise. Common units include:

* length in metres;
* time in seconds;
* pressure in pascals;
* temperature in kelvin;
* mass flow rate in kilograms per second;
* velocity in metres per second;
* specific enthalpy in joules per kilogram;
* wall heat flux in watts per square metre.

Check the comments in example input files and the relevant property
documentation before entering a value.

Can OpenSTREAM be used directly for safety or licensing analysis?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OpenSTREAM is intended for transparent research, education, model
development, performance evaluation, and validation. Suitability for a
specific engineering, safety, or licensing application depends on the
selected solver, closure models, numerical verification, validation
evidence, quality-assurance requirements, and application-specific review.

Do not assume that availability of a model implies validation for every
fluid, geometry, pressure, flow regime, or operating condition.

How are fluid properties calculated?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Fluid properties are calculated using CoolProp through CoolPropWrapper.
The property assumptions are selected through the model inputs. Review the
fluid identifier and property option used by the case, particularly when
the simulation includes thermal non-equilibrium.

Extending OpenSTREAM
--------------------

How do I select another closure model?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Closure models are selected in the physical-model input file. Valid values
are defined by classes in the ``InputEnums`` package.

For example, model selections may control:

* void fraction;
* wall friction;
* interfacial heat transfer;
* phase momentum;
* entrainment and deposition;
* onset of annular flow;
* base-film thickness;
* disturbance-wave frequency.

Consult the relevant ``InputEnums`` class and ``Inputs.Model`` property
before adding an entry. If a selection is not explicitly provided, the
documented default is used.

How do I add a new closure model?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Adding a closure model normally requires coordinated changes to:

#. the relevant ``InputEnums`` class;
#. any new model properties and defaults in ``Inputs.Model``;
#. the solver or field method that evaluates the closure;
#. model documentation and references;
#. input examples;
#. verification and regression tests.

The implementation should clearly document equations, units, assumptions,
validity range, and source references. Verify the closure independently
before using it in model validation or engineering analysis.

Where should I report a bug or request a feature?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the OpenSTREAM GitHub issue tracker:

* https://github.com/OpenSTREAM-solvers/openstream/issues

Before opening an issue:

* search for an existing report;
* provide the OpenSTREAM revision;
* provide the MATLAB, Python, and CoolProp versions;
* include the smallest input case that reproduces the problem;
* include the complete error message and stack trace;
* distinguish unexpected code behavior from a model-validity question.

How can I contribute?
~~~~~~~~~~~~~~~~~~~~~

Fork the repository, create a focused branch, implement and test the change,
and submit a pull request. Follow the coding, testing, documentation, and
code-of-conduct 