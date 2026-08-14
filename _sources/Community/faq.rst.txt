OpenSTREAM FAQ
==============

This page provides concise answers to common questions about installing,
configuring, running, troubleshooting, and extending **OpenSTREAM**.
Select a question to display its answer.

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

   The solvers provide different levels of physical detail and support
   education, model development, performance evaluation, and validation.

.. dropdown:: What should I read first?
   :animate: fade-in-slide-down
   :chevron: right-down

   A suggested learning path is:

   #. Follow the installation instructions in the Usage section.
   #. Run **Tutorial #1: OpenSTREAM Quick Start**.
   #. Continue with the solver-specific tutorial that matches your needs:

      * Tutorial #2 for the mixture solver;
      * Tutorial #3 for the two-fluid solver;
      * Tutorial #4 for the three-field solver;
      * Tutorial #5 for the four-field solver.

   #. Consult the theory pages for governing equations and assumptions.
   #. Use the package reference to inspect model options, object properties,
      and methods.

.. dropdown:: How do I make OpenSTREAM available in MATLAB?
   :animate: fade-in-slide-down
   :chevron: right-down

   Add the OpenSTREAM root folder to the MATLAB search path. For example,
   when running a tutorial from the ``tutorials`` folder:

   .. code-block:: matlab

      osp = './..';
      addpath(osp);

   If MATLAB cannot find a class such as ``InputSet`` or
   ``MixtureSolver``, verify that the OpenSTREAM root folder is correct and
   present on the MATLAB path.

   You can inspect the resolved location of a class with:

   .. code-block:: matlab

      which Inputs.InputSet
      which Solvers.Mixture.MixtureSolver

.. dropdown:: Why does OpenSTREAM require Python?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM uses the Python version of **CoolProp** to calculate fluid
   thermophysical properties. ``CoolPropWrapper`` provides the interface
   between MATLAB and Python.

   MATLAB must therefore use a compatible Python installation. Check the
   active Python environment with:

   .. code-block:: matlab

      pyenv

   You can test the property interface with:

   .. code-block:: matlab

      cp = CoolPropWrapper.CoolPropWrapper();

   If Python or CoolProp cannot be loaded, follow the MATLAB-Python
   compatibility and CoolPropWrapper setup instructions in the installation
   section.

.. dropdown:: Which MATLAB version should I use?
   :animate: fade-in-slide-down
   :chevron: right-down

   Use a MATLAB release compatible with the OpenSTREAM code version and
   with a supported Python version. The documentation and tutorials should
   state the MATLAB release used for their preparation.

   When reproducing or reporting a result, record the MATLAB release with:

   .. code-block:: matlab

      version('-release')

   Also record the Python and CoolProp versions when fluid-property behavior
   is relevant.

.. dropdown:: Where can I find working examples?
   :animate: fade-in-slide-down
   :chevron: right-down

   The ``tutorials`` folder contains MATLAB Live Scripts that can be run and
   modified directly. The documentation also provides completed HTML
   versions for reference.

   Start with **Tutorial #1: OpenSTREAM Quick Start**, then continue with
   the solver-specific tutorial that matches your application.

Running simulations
-------------------

.. dropdown:: What is the minimum workflow for running a case?
   :animate: fade-in-slide-down
   :chevron: right-down

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

.. dropdown:: How are OpenSTREAM inputs organized?
   :animate: fade-in-slide-down
   :chevron: right-down

   An OpenSTREAM case is assembled from separate input categories:

   * **Model inputs** select physical models and closure models.
   * **Numerical options** control time steps, iterations, relaxation
     factors, and convergence criteria.
   * **Geometry inputs** define channel length, flow area, wall perimeters,
     and orientation.
   * **Boundary conditions** define pressure, inlet enthalpy, mass flow,
     power, and axial power distribution.

   A file may contain several input sets. An identifier such as
   ``TUTORIAL1`` or ``DEFAULT`` selects the required set. This organization
   allows one geometry or option set to be reused in several simulations.

.. dropdown:: What input-file formats are supported?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM examples use the native ``.inp`` format. The input framework
   can also read equivalent JSON input.

   Use one format consistently within a case and verify that the selected
   IDs and imported property values are identical when comparing formats.

.. dropdown:: What happens if I do not specify a model or numerical option?
   :animate: fade-in-slide-down
   :chevron: right-down

   Unspecified entries use the default values defined by the corresponding
   input class, principally ``Inputs.Model`` and ``Inputs.Options``.

   Defaults make basic cases easier to configure, but they should not be
   treated as universally appropriate. For research or validation work,
   review and document all influential physical and numerical selections.

.. dropdown:: Why does MATLAB print many default-value warnings?
   :animate: fade-in-slide-down
   :chevron: right-down

   The warnings identify properties that were not explicitly specified and
   therefore use their class defaults.

   These messages are useful while developing or reviewing a case.
   Tutorials may temporarily suppress them to keep the displayed output
   concise:

   .. code-block:: matlab

      warning off
      inputSet = InputSet(...);
      warning on

   Do not suppress warnings routinely until the configuration has been
   reviewed. An unexpected warning can reveal an omitted or unsupported
   input.

.. dropdown:: Why does OpenSTREAM report that an input entry was not used?
   :animate: fade-in-slide-down
   :chevron: right-down

   Common causes include:

   * a misspelled keyword;
   * a keyword that does not belong to the selected input class;
   * an obsolete keyword;
   * an entry intended for another model configuration.

   Check the spelling against ``Inputs.Model``, ``Inputs.Options``,
   ``Inputs.Geometry``, or the relevant package-reference page. Do not
   assume that an unused entry affected the simulation.

.. dropdown:: How do I define a steady-state calculation?
   :animate: fade-in-slide-down
   :chevron: right-down

   A boundary-condition file containing a single time entry defines a
   steady-state case.

   The solver obtains the steady-state solution through pseudo-time
   advancement. The pseudo-time sequence is a numerical procedure used to
   approach a stationary solution and should not be interpreted as a
   physical transient.

.. dropdown:: How do I define a transient calculation?
   :animate: fade-in-slide-down
   :chevron: right-down

   Provide boundary-condition values at multiple physical times. Depending
   on the boundary-condition interface, pressure, inlet enthalpy, inlet
   mass flow, power, and axial power distribution can vary with time.

   The solver first calculates the initial steady state. The physical
   transient proceeds only after the initial solution has converged.

   The physical time step is controlled through the numerical options. A
   time-step sensitivity study is recommended when transient timing or peak
   values are important.

.. dropdown:: Why is the mixture solver run before the other solvers?
   :animate: fade-in-slide-down
   :chevron: right-down

   The two-fluid, three-field, and four-field solvers require a solved
   mixture solution for initialization. They also reuse information from
   the mixture solution, including the pressure-gradient solution.

   A solved mixture solver can be passed explicitly:

   .. code-block:: matlab

      mixSolver = MixtureSolver(inputSet);
      mixSolver.solve();

      twfSolver = TwoFluidSolver(inputSet, mixSolver);
      tfSolver  = ThreeFieldSolver(inputSet, mixSolver);
      ffSolver  = FourFieldSolver(inputSet, mixSolver);

   If a mixture solver is not supplied, the advanced solver constructor
   creates and solves one when required. Passing an existing solved object
   avoids repeating the same mixture calculation.

.. dropdown:: Can I call solve more than once on the same solver object?
   :animate: fade-in-slide-down
   :chevron: right-down

   A solver object represents a specific initialized calculation. Calling
   ``solve`` again on an already solved object produces an error stating
   that the solver must be reinitialized.

   For a new calculation, construct a new ``InputSet`` and solver object.
   This keeps each simulation configuration and its stored results clearly
   separated.

.. dropdown:: How do I reduce the amount of information printed in the MATLAB Command Window?
   :animate: fade-in-slide-down
   :chevron: right-down

   Set ``LOGMODE`` to ``'LOGTOFILEONLY'`` when constructing the
   ``InputSet``:

   .. code-block:: matlab

      inputSet = InputSet( ...
          ...
          LOGMODE = 'LOGTOFILEONLY');

   Solver progress remains available in the session log while most Command
   Window output is suppressed.

Choosing a solver
-----------------

.. dropdown:: Which solver should I use?
   :animate: fade-in-slide-down
   :chevron: right-down

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
      into base-film and disturbance-wave fields and wave transport is part
      of the analysis.

   Increasing the number of fields does not automatically make a simulation
   more accurate. The selected solver assumptions and closure models must
   be appropriate for the application.

.. dropdown:: What is the difference between a phase and a field?
   :animate: fade-in-slide-down
   :chevron: right-down

   A **phase** is a thermodynamic state of matter, such as liquid or vapor.

   A **field** is a computationally resolved constituent with its own
   transported variables or conservation equations. One phase can be
   represented by more than one field. For example:

   * the three-field solver represents the liquid phase through a wall-film
   field and a droplet field;
   * the four-field solver further divides the wall film into a base-film
   field and a disturbance-wave field.

.. dropdown:: Are the three-field and four-field solvers thermal non-equilibrium models?
   :animate: fade-in-slide-down
   :chevron: right-down

   The current three-field and four-field formulations assume thermal
   equilibrium. Their additional detail concerns the hydrodynamic
   distribution and transport of liquid fields.

   Use the mixture relaxation model or the two-fluid solver when separate
   thermal behavior is required, subject to the assumptions and implemented
   closure models of the selected framework.

.. dropdown:: Where are the three-field and four-field equations applied?
   :animate: fade-in-slide-down
   :chevron: right-down

   Although the separate annular-flow field equations are numerically solved
   from the channel inlet, their results are physically meaningful only from
   the onset of annular flow. Upstream of this location, the conservation
   equations are formulated so that the annular-flow field variables evolve
   smoothly toward the prescribed conditions at the onset of annular flow.

   Solving the field equations upstream of the onset of annular flow ensures
   that all required field variables are available at the preceding time
   step if the onset location moves upstream during a transient calculation.

   The onset-of-annular-flow model, the initial film-droplet split, and, for
   the four-field solver, the initial base-film and disturbance-wave split
   can therefore influence the solution near the transition.

.. dropdown:: Why can results near the onset of annular flow be sensitive?
   :animate: fade-in-slide-down
   :chevron: right-down

   The initial liquid distribution among film, droplets, base film, and
   waves depends on the selected onset and field-splitting models.
   Entrainment and deposition then redistribute liquid as the solution
   develops downstream.

   When the region near annular-flow onset is important, examine
   sensitivity to:

   * the onset-of-annular-flow model;
   * the initial entrained-droplet fraction;
   * the initial base-film and wave split;
   * entrainment and deposition models;
   * spatial resolution.

.. dropdown:: Should entrainment and deposition models be selected together?
   :animate: fade-in-slide-down
   :chevron: right-down

   Yes. Entrainment and deposition are coupled processes that exchange
   liquid between the film and droplet fields. When available, use a
   consistent entrainment and deposition model family unless there is a
   documented reason to combine different models.

Numerical convergence
---------------------

.. dropdown:: What is the difference between point convergence and steady-state convergence?
   :animate: fade-in-slide-down
   :chevron: right-down

   At each axial node and time step, OpenSTREAM performs local point
   iterations for the nonlinear equations. **Point convergence** refers to
   the change in solved variables between these local iterations.

   For a steady-state calculation, OpenSTREAM also compares solutions
   between successive pseudo-time steps. **Steady-state convergence** refers
   to these temporal changes becoming smaller than the specified
   steady-state criteria.

   A calculation therefore needs adequately converged local iterations and
   an adequately converged pseudo-time solution.

.. dropdown:: What does solveMode='NULL' mean in plotting methods?
   :animate: fade-in-slide-down
   :chevron: right-down

   The ``NULL`` solve mode displays the pseudo-time history used to obtain
   the initial steady-state solution. It does not represent the physical
   transient.

   For example:

   .. code-block:: matlab

      solver.plott( ...
          solver.NZ, ...
          'display', {'W','U'}, ...
          'solveMode', 'NULL');

   Use the regular or ``REAL`` mode for the stored physical solution.

.. dropdown:: What should I do if the steady-state calculation does not converge?
   :animate: fade-in-slide-down
   :chevron: right-down

   Start with the information printed by the solver:

   * identify the node with the largest point-iteration count;
   * identify which variable has the largest residual;
   * inspect the final solver state;
   * plot the pseudo-time history with ``solveMode='NULL'``;
   * check model, geometry, and boundary-condition warnings;
   * verify that input values and units are physically reasonable.

   Numerical options that may affect convergence include:

   * maximum point iterations;
   * maximum steady-state pseudo-time iterations;
   * pseudo-time step;
   * variable-specific relaxation factors;
   * pointwise convergence criteria;
   * steady-state convergence criteria.

   Change one numerical setting at a time. After convergence improves,
   verify that the converged physical result has not changed materially.

.. dropdown:: Why was my transient skipped?
   :animate: fade-in-slide-down
   :chevron: right-down

   The physical transient is not calculated when the initial steady-state
   solution fails to converge. The solver log indicates that the transient
   is being skipped.

   Inspect the initial pseudo-time solution, correct any input or model
   problems, and obtain a converged initial state before interpreting
   transient results.

.. dropdown:: Can a converged calculation still be inaccurate?
   :animate: fade-in-slide-down
   :chevron: right-down

   Yes. Numerical convergence indicates that the implemented discrete
   equations have been solved to the selected tolerances. It does not
   establish that:

   * the spatial mesh is sufficiently refined;
   * the physical time step is sufficiently small;
   * the selected closure models are valid for the conditions;
   * the one-dimensional assumptions are appropriate;
   * the model has been validated for the application.

   Mesh sensitivity, time-step sensitivity, conservation checks, and
   comparison with appropriate reference data remain necessary.

.. dropdown:: Which numerical options control steady-state convergence?
   :animate: fade-in-slide-down
   :chevron: right-down

   Relevant options include the pseudo-time step, the maximum number of
   steady-state iterations, variable-specific relaxation factors, local
   point-iteration tolerances, and steady-state temporal convergence
   criteria.

   The exact property names and defaults are listed in ``Inputs.Options``.
   Use the solver-specific tutorials and package reference when changing
   these values.

Results and post-processing
---------------------------

.. dropdown:: How do I display results?
   :animate: fade-in-slide-down
   :chevron: right-down

   The solver classes provide plotting methods for common result types.

   ``plotz``
      Plots axial distributions. Multiple physical time indices can produce
      an animated axial plot.

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

   Available display names depend on the selected solver. Consult the
   corresponding solver class in the package reference.

.. dropdown:: Why are Live Script outputs shown beside the code?
   :animate: fade-in-slide-down
   :chevron: right-down

   MATLAB Live Editor can display output either beside the code or inline
   below it. The OpenSTREAM tutorials are designed for **inline output**, so
   that figures and results appear immediately below the code that generates
   them.

   In the MATLAB Live Editor, select the output-layout option that places
   output below the code, then save the Live Script.

.. dropdown:: Can I access results without using the built-in plots?
   :animate: fade-in-slide-down
   :chevron: right-down

   Yes. Solver objects retain their solution objects and arrays. Examples
   include:

   * mixture variables in ``mixSolver.mixture``;
   * liquid and vapor variables in ``twfSolver.liquid`` and
     ``twfSolver.vapor``;
   * film and droplet variables in ``tfSolver.film`` and ``tfSolver.drop``;
   * base-film and wave variables through the four-field film object.

   The package reference lists the available properties and methods. Check
   property dimensions before processing because arrays may vary over axial
   position, time, and wall index.

.. dropdown:: How do I save a solver object?
   :animate: fade-in-slide-down
   :chevron: right-down

   Use the solver ``save`` method:

   .. code-block:: matlab

      mixSolver.save( ...
          'name', 'mixSolver', ...
          'showpath', true);

   The solver object contains the imported inputs, solution objects, and
   associated simulation information. Saving it allows later post-processing
   without repeating the calculation.

.. dropdown:: Where are simulation outputs stored?
   :animate: fade-in-slide-down
   :chevron: right-down

   The ``sessionParentDir`` argument defines the parent output folder. Each
   solver uses the session infrastructure to store logs and requested
   results.

   For example:

   .. code-block:: matlab

      sessionParentDir = fullfile(pwd,'outputs');

   Use a separate session directory or case name for parameter studies. Be
   careful with:

   .. code-block:: matlab

      overwriteSessionFiles = true

   because existing files for the corresponding session may be replaced.

.. dropdown:: Why do my plots show results only from the onset of annular flow?
   :animate: fade-in-slide-down
   :chevron: right-down

   The three-field and four-field plotting functions can restrict
   field-specific results to the annular-flow region. This is appropriate
   because separate film, droplet, base-film, and wave equations apply from
   the onset of annular flow.

   Where supported, set the ``annular`` plotting option to ``false`` to
   inspect initialization outside that region:

   .. code-block:: matlab

      solver.plotz( ...
          'display', 'W', ...
          'annular', false);

   Interpret pre-annular field values as initialization quantities rather
   than as a complete pre-annular multi-field model.

.. dropdown:: How do I plot only part of the channel or selected times?
   :animate: fade-in-slide-down
   :chevron: right-down

   Use the solver plotting options for selected axial indices and time
   indices. For example, ``zIdx`` limits the plotted axial range and the
   first positional plot argument can identify one or more stored time
   indices.

   Check the signature of the selected solver's ``plotz`` or ``plott``
   method because supported options vary by solver.

.. dropdown:: How do I compare several model configurations?
   :animate: fade-in-slide-down
   :chevron: right-down

   Create one ``InputSet`` and solver object per model ID, store each object
   separately, and extract the same comparison quantities from every case.

   Use distinct session directories to avoid overwriting results. A compact
   MATLAB table is useful for comparing scalar metrics, while solver objects
   can be retained separately for detailed post-processing.

Physical scope and limitations
------------------------------

.. dropdown:: What geometries can OpenSTREAM represent?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM represents one-dimensional flow in straight channels.
   Cross-sectional geometry is described through averaged quantities such
   as flow area and wall perimeter.

   The formulation supports multi-wall channel representations, allowing
   different wall surfaces and heating distributions to be considered.
   Examples may include tubes, annuli, rectangular channels, and simplified
   small rod-bundle representations when the one-dimensional approximation
   is appropriate.

   OpenSTREAM does not resolve bends, crossflow, or detailed
   three-dimensional velocity and temperature distributions.

.. dropdown:: What units should I use?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM uses SI units unless a specific model or input explicitly
   states otherwise. Common units include:

   * length in metres;
   * time in seconds;
   * pressure in pascals;
   * temperature in kelvin;
   * mass flow rate in kilograms per second;
   * velocity in metres per second;
   * specific enthalpy in joules per kilogram;
   * wall heat flux in watts per square metre.

   Check comments in the example input files and the relevant property
   documentation before entering a value.

.. dropdown:: Can OpenSTREAM be used for safety or licensing analysis?
   :animate: fade-in-slide-down
   :chevron: right-down

   No. **OpenSTREAM must not be used for safety or licensing analysis.**

   OpenSTREAM is intended for research, education, model development,
   performance evaluation, and validation activities. It is not a licensed
   safety-analysis code and has not been qualified for use in regulatory or
   licensing applications.
 
   Results produced with OpenSTREAM must not be used as the basis for safety
   decisions, licensing submissions, regulatory compliance demonstrations,
   or the operation of safety-related systems.

.. dropdown:: How are fluid properties calculated?
   :animate: fade-in-slide-down
   :chevron: right-down

   Fluid properties are calculated using CoolProp through CoolPropWrapper.
   Property assumptions are selected through the model inputs. Review the
   fluid identifier and property option used by the case, particularly when
   the simulation includes thermal non-equilibrium.

.. dropdown:: Does a more detailed solver always give a better result?
   :animate: fade-in-slide-down
   :chevron: right-down

   No. Greater field resolution introduces additional equations, closure
   models, numerical parameters, and applicability limits. A more detailed
   solver is useful only when its modeled phenomena and validation basis
   match the application.

   Select the simplest solver that represents the required physics and
   document the sensitivity to influential assumptions.

.. dropdown:: What should I verify before trusting a result?
   :animate: fade-in-slide-down
   :chevron: right-down

   At minimum, check:

   * input values, IDs, units, and warnings;
   * point and steady-state convergence;
   * mass and energy consistency;
   * spatial-mesh sensitivity;
   * physical time-step sensitivity for transients;
   * sensitivity to influential closure models;
   * applicability and validation of the selected models.

Extending and contributing
--------------------------

.. dropdown:: How do I select another closure model?
   :animate: fade-in-slide-down
   :chevron: right-down

   Closure models are selected in the physical-model input file. Valid
   values are defined by classes in the ``InputEnums`` package.

   Model selections may control, for example:

   * void fraction;
   * wall friction;
   * interfacial heat transfer;
   * phase or field momentum;
   * entrainment and deposition;
   * onset of annular flow;
   * base-film thickness;
   * disturbance-wave frequency.

   Consult the relevant ``InputEnums`` class and ``Inputs.Model`` property
   before adding an entry. If a selection is not explicitly provided, the
   documented default is used.

.. dropdown:: How do I add a new closure model?
   :animate: fade-in-slide-down
   :chevron: right-down

   Adding a closure model normally requires coordinated changes to:

   #. the relevant ``InputEnums`` class;
   #. any new model properties and defaults in ``Inputs.Model``;
   #. the solver or field method that evaluates the closure;
   #. model documentation and references;
   #. input examples;
   #. verification and regression tests.

   The implementation should document equations, units, assumptions,
   validity range, and source references. Verify the closure independently
   before using it in validation or engineering analysis.

.. dropdown:: How should I report a bug?
   :animate: fade-in-slide-down
   :chevron: right-down

   Use the OpenSTREAM GitHub issue tracker. Before opening an issue:

   * search for an existing report;
   * provide the OpenSTREAM revision;
   * provide the MATLAB, Python, and CoolProp versions;
   * include the smallest input case that reproduces the problem;
   * include the complete error message and stack trace;
   * distinguish unexpected code behavior from a model-validity question.

   Issue tracker:

   * https://github.com/OpenSTREAM-solvers/openstream/issues

.. dropdown:: How can I request a feature?
   :animate: fade-in-slide-down
   :chevron: right-down

   Open a GitHub issue describing:

   * the use case and physical or workflow need;
   * the proposed behavior;
   * which solver or package is affected;
   * any relevant equations, references, or examples;
   * how the feature could be verified.

   Search existing issues first to avoid duplicating an active request.

.. dropdown:: How can I contribute?
   :animate: fade-in-slide-down
   :chevron: right-down

   Fork the repository, create a focused branch, implement and test the
   change, and submit a pull request. Follow the coding, testing,
   documentation, and code-of-conduct guidance in the Community section.

   Keep changes focused and include documentation and tests when behavior or
   interfaces change.

.. dropdown:: How do I contribute to the documentation?
   :animate: fade-in-slide-down
   :chevron: right-down

   Edit the reStructuredText source files, build the documentation locally
   when possible, and verify both HTML and PDF outputs. Add or update links,
   references, examples, and package documentation as needed.

   The FAQ dropdowns use the ``sphinx-design`` extension. The extension must
   remain listed in the documentation requirements and in ``conf.py``.

.. dropdown:: Where can I get additional help?
   :animate: fade-in-slide-down
   :chevron: right-down

   Consult, in this order:

   #. the Quick Start and solver-specific tutorials;
   #. the theory overview;
   #. the glossary and notation guide;
   #. the package reference;
   #. existing GitHub issues;
   #. the GitHub issue tracker for a new question or reproducible problem.

   When requesting help, include enough information for another user to
   reproduce the calculation.
