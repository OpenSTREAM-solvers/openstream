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

.. dropdown:: Why should I use OpenSTREAM instead of another available code?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM is not intended to replace any existing thermal-hydraulic
   code. It is designed primarily as an open, transparent, and extensible
   environment for education, fundamental model development, implementation
   of closure models, controlled numerical experiments, and validation of
   one-dimensional two-phase flow formulations.

   OpenSTREAM may be particularly useful when you need:

   * **Full access to the source code.** The governing equations, closure
     models, numerical algorithms, input processing, and post-processing
     methods can be inspected and modified directly.

   * **A transparent modeling environment.** Primary variables, secondary
     quantities, source terms, field exchanges, and convergence histories
     are accessible through the MATLAB solver objects. This facilitates
     interpretation, debugging, and conservation checks.

   * **Several solver frameworks within a common architecture.** OpenSTREAM
     includes mixture, two-fluid, three-field, and four-field formulations.
     The same geometry, boundary conditions, fluid-property interface, and
     general workflow can therefore be used to compare different levels of
     physical resolution.

   * **Detailed annular-flow modeling.** The three-field solver separates
     the liquid into wall-film and entrained-droplet fields. The four-field
     solver further separates the liquid film into base-film and
     disturbance-wave fields and includes wave-frequency transport.

   * **A practical platform for closure-model development.** Physical models
     are selected through documented input enumerations and implemented in
     dedicated phase or field classes. A developer can add, modify, test,
     and compare closure models without working within a large proprietary
     code base.

   * **Rapid prototyping in MATLAB.** MATLAB provides an interactive
     environment for inspecting objects, modifying equations, visualizing
     results, performing parameter studies, and developing new models.

   * **Reproducible research and education.** Input sets, tutorials,
     documentation, references, and source code can be distributed together,
     allowing users to inspect the assumptions behind a calculation and
     reproduce the workflow.

   * **A computationally efficient one-dimensional model.** OpenSTREAM is
     useful when cross-section-averaged axial behavior is sufficient and
     the computational expense and geometric detail of a multidimensional
     CFD calculation are not required.

   Other codes may be more appropriate when the application requires:

   * qualified or extensively validated models for a specific industrial
     application;
   * complete reactor-system or plant-network simulation;
   * dedicated component models for pumps, valves, vessels, separators, or
     heat exchangers;
   * multidimensional CFD resolution;
   * complex geometry, crossflow, or connected flow networks;
   * compressible pressure-wave dynamics;
   * multi-component fluids or non-condensable gases;
   * safety or licensing analysis.

   The appropriate code therefore depends on the purpose of the analysis.
   OpenSTREAM is especially well suited to understanding, developing, and
   evaluating models in a transparent one-dimensional framework. A more
   established application code may be preferable when a broad component
   library, an application-specific validation basis, or a qualified
   engineering workflow is required.

   Selecting OpenSTREAM does not remove the need for numerical verification,
   closure-model assessment, applicability review, and validation against
   appropriate reference data.

.. dropdown:: What is unique about OpenSTREAM, and what are its main strengths?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM combines advanced one-dimensional two-phase flow models with
   an open, modern, and extensible software architecture. Its purpose is not
   only to perform simulations, but also to make the governing equations,
   closure models, numerical methods, and calculated source terms accessible
   for inspection, modification, and collaborative development.

   Its main distinctive features and strengths include:

   * **Advanced models rarely available in open-source thermal-hydraulic
     codes.** To the best of the developers' knowledge, OpenSTREAM provides
     the only openly available implementations of its four-field annular-flow
     model and Mixture Relaxation Model within a general two-phase flow
     simulation environment.

     The four-field model explicitly represents vapor, entrained droplets,
     the base liquid film, and disturbance waves. It also includes transport
     of wave frequency, allowing the evolution of disturbance-wave behavior
     to be studied. The model therefore provides a level of annular-flow
     detail that is not commonly available in open-source one-dimensional
     thermal-hydraulic codes.

     The Mixture Relaxation Model extends the conventional mixture
     formulation by solving additional vapor mass and energy conservation
     equations. It provides a computationally efficient framework for
     representing thermal non-equilibrium through relaxation of interfacial
     mass and energy transfer.

   * **Several solver frameworks within one consistent environment.**
     OpenSTREAM includes mixture, two-fluid, three-field, and four-field
     solvers. These frameworks share the same general input system,
     geometry definition, fluid-property interface, session management, and
     post-processing approach.

     This common structure allows users to compare different levels of
     physical resolution without moving between unrelated codes or
     reconstructing the complete simulation workflow.

   * **A modern object-oriented architecture.** OpenSTREAM is implemented
     using MATLAB classes that represent solvers, phases, fields, inputs,
     fluid properties, sessions, and plotting utilities. Shared behavior is
     organized through inheritance and common base classes, while
     solver-specific behavior is implemented in dedicated modules.

     This architecture supports modular development and helps isolate
     changes to a particular physical model, field, or solver. It also makes
     primary variables, secondary quantities, source terms, and solver
     methods directly accessible through the corresponding objects.

   * **Direct access to primary and secondary variables.** Users can inspect
     the primary solution variables, such as mass flow rate, pressure,
     velocity, and enthalpy, together with derived quantities such as void
     fraction, film thickness, interfacial area, flow regime, and
     disturbance-wave frequency, where applicable to the selected solver.

     The stored pseudo-time convergence histories also allow users to examine
     how the steady-state solution was obtained. This level of access is
     useful for interpretation, debugging, numerical diagnostics, and
     verification.

   * **Direct access to field exchange terms.** The mass, momentum, and
     energy exchange terms calculated by the selected solver are readily
     accessible through the corresponding phase and field objects.

     This includes wall and interfacial transfer terms, such as evaporation,
     condensation, entrainment, deposition, drag, shear, and heat transfer,
     where applicable to the selected solver. Access to the individual
     contributions facilitates interpretation of the governing equations,
     conservation checks, closure-model evaluation, and debugging.

   * **Direct access to pressure-drop contributions.** The individual
     pressure-drop components calculated by the mixture solver are readily
     available for inspection and post-processing.

     These contributions can be examined separately to determine the
     relative effects of gravity, wall friction, spatial acceleration,
     temporal acceleration, and local pressure losses, as applicable to the
     simulated case. This decomposition helps users understand the physical
     origin of the calculated pressure distribution.

   * **Integrated plotting and animation capabilities.** Each solver
     provides dedicated methods for visualizing its principal variables and
     calculated exchange terms. Axial distributions, time histories, and,
     where implemented, time-elevation distributions can be generated
     directly from the solver object.

     The plotting methods support solver-specific quantities, selected axial
     and time indices, multiple plot arrangements, and animation of transient
     results. This allows users to inspect a calculation interactively
     without first developing separate post-processing routines.

   * **Designed for model development and comparison.** Physical models are
     selected through documented input options and implemented in dedicated
     phase or field classes. New closure models can therefore be introduced,
     verified, and compared with existing models without modifying an
     opaque or monolithic code base.

     The shared solver architecture is particularly useful for studying how
     assumptions made at the mixture, phase, or field level influence the
     calculated results.

   * **Comprehensive and integrated documentation.** The OpenSTREAM
     documentation includes installation instructions, theory descriptions,
     governing equations, notation, a glossary, package and class
     references, tutorials, publications, contribution guidance, and this
     FAQ.

     Solver-specific MATLAB Live Scripts provide executable examples that
     users can inspect and modify. The documentation is generated from the
     same repository as the source code, helping to keep implementation
     details and user guidance together.

   * **Interactive MATLAB workflow.** MATLAB provides an environment in
     which users can run a case, inspect solver objects, modify models,
     visualize intermediate quantities, perform parameter studies, and
     develop post-processing routines interactively.

     MATLAB Live Scripts combine formatted explanations, executable code,
     figures, and calculated output in a single document, making them useful
     for education, demonstrations, and reproducible technical studies.

   * **Open and modifiable source code.** OpenSTREAM is distributed under
     the MIT License. Users can inspect, use, modify, and redistribute the
     code in accordance with the license terms.

     Open development enables independent scrutiny of the modeling basis and
     supports collaboration among researchers and institutions. The source
     code, documentation, input cases, and references can be considered
     together when evaluating a model.

   * **Computational efficiency.** The one-dimensional formulation and
     streamlined numerical methods provide a computationally efficient
     framework for steady-state and transient calculations.

     This efficiency facilitates rapid model development, repeated
     calculations, closure-model comparisons, parameter studies,
     sensitivity analyses, and validation exercises.

   These strengths do not mean that OpenSTREAM is more appropriate than
   every other thermal-hydraulic code. Established system, subchannel, and
   CFD codes may provide broader component libraries, more complex
   geometries, multidimensional resolution, or a more extensive validation
   basis for particular applications.

   OpenSTREAM is most distinctive when transparency, access to the governing
   models, advanced annular-flow modeling, thermal non-equilibrium model
   development, and controlled comparison of solver frameworks are central
   to the objective of the study.

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

.. dropdown:: What are the main simplifications in OpenSTREAM, and why are they considered reasonable?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM uses several deliberate simplifications to provide a
   transparent, computationally efficient, and numerically robust environment
   for developing and evaluating one-dimensional two-phase flow models.
   These simplifications define the intended scope of the code and must be
   considered when interpreting its results.

   The main simplifications are:

   * **One-dimensional, cross-section-averaged flow.** Flow variables vary
     only along the channel axis. Radial, azimuthal, and other local
     distributions are not resolved explicitly and must instead be
     represented through averaged quantities and closure models.

     This approximation is reasonable for straight channels when axial
     transport dominates and detailed multidimensional effects, such as
     crossflow, flow separation, or strongly asymmetric mixing, are not
     essential to the quantity being studied. It also makes OpenSTREAM
     suitable for rapid model development, sensitivity studies, and
     comparison of closure models.

   * **Straight channels with constant cross-sectional area.** The current
     geometry represents a straight flow path with constant flow area.
     Multiple wall perimeters and non-uniform wall heating can be defined,
     and local perturbations can be represented through dedicated models,
     but continuous geometric variation is not resolved.

     This approximation covers many experimental channels and idealized
     thermal-hydraulic problems, including tubes, annuli, rectangular
     channels, and simplified small rod-bundle representations. It enables
     investigation of axial two-phase flow behavior without introducing
     additional geometric effects.

   * **Mixture-based pressure-gradient solution.** The pressure-gradient
     solution obtained from the mixture solver is reused by the two-fluid,
     three-field, and four-field solvers rather than independently solving a
     fully coupled pressure-velocity system in each framework.

     This treatment significantly improves numerical stability and provides
     a consistent pressure field for comparisons among the solver
     frameworks. It introduces some inconsistency between the pressure
     solution and the separate field momentum equations, but the available
     OpenSTREAM publications report that this inconsistency is negligible
     for many applications. Its acceptability must nevertheless be assessed
     for each new application.

   * **Neglect of surface-tension forces in the conservation equations.**
     Surface tension may be used in closure quantities, but explicit
     surface-tension force contributions are neglected in the governing
     momentum equations.

     This simplification is considered reasonable for the high-pressure
     channel-flow conditions targeted by the current implementations, where
     the retained pressure, inertia, gravity, and wall and interfacial
     momentum-transfer terms are generally more important at the
     one-dimensional field scale. It may not be appropriate for
     capillary-dominated flows, very small channels, or problems controlled
     by interface curvature.

   * **Neglect of heating caused by friction.** Mechanical energy dissipated
     by wall or interfacial friction is not added explicitly to the fluid
     energy equations.

     This contribution is considered small relative to the imposed wall
     heating and phase-change energy transfer for the high-pressure boiling
     applications for which the current models were developed. It should not
     be neglected without assessment in applications involving exceptionally
     large pressure losses or little external heating.

   * **Neglect of temporal pressure-gradient contributions.** The current
     formulations omit minor energy or momentum contributions associated
     with the temporal pressure gradient.

     This approximation is considered reasonable for the operational
     transients targeted by the current high-pressure Light Water Reactor
     applications. It is not appropriate for rapid pressure-wave,
     depressurization, water-hammer, choking, or shock-wave problems, which
     are outside the intended scope of OpenSTREAM.

   * **Neglect of spatial gradients of saturated-fluid enthalpies.** Spatial
     changes in saturated liquid and vapor enthalpies associated with the
     pressure distribution are neglected in the simplified conservation
     equations.

     This approximation is considered reasonable for the high-pressure
     conditions and operational transients targeted by the current
     OpenSTREAM frameworks. Its adequacy should be reconsidered for cases
     with large pressure variations or strong depressurization.

   * **Simplified flow-regime and interfacial-topology transitions.** The
     current two-fluid solver uses simplified assumptions to identify flow
     regimes and select the corresponding closure models.

     This approach provides a practical framework for implementing and
     testing separate-phase conservation equations, but it limits the
     physical realism of complex transients involving repeated or strongly
     evolving changes in interfacial topology. The two-fluid results should
     therefore be interpreted according to the maturity and validation range
     of the selected transition and closure models.

   * **Thermal equilibrium in the three-field and four-field solvers.** The
     film, droplet, base-film, disturbance-wave, and vapor fields are assumed
     to share the applicable saturation thermodynamic state. The solvers
     resolve hydrodynamic non-equilibrium among the fields but do not solve
     separate field energy equations for thermal non-equilibrium.

     This approximation is reasonable for saturated annular-flow studies in
     which liquid-field mass and momentum transport, entrainment,
     deposition, film depletion, and disturbance-wave behavior are the
     primary phenomena of interest. It is not appropriate when separate
     field temperatures or post-dryout thermal non-equilibrium are essential.

   * **First-order numerical discretization.** The conservation equations
     are solved using first-order upwind spatial discretization and fully
     implicit backward Euler time integration. Nonlinear source terms and
     field couplings are treated through fixed-point iterations.

     These methods are comparatively simple and numerically robust, which is
     useful for an open model-development platform and for obtaining
     steady-state solutions through pseudo-time advancement. Their numerical
     diffusion and first-order accuracy make mesh- and time-step-sensitivity
     studies necessary when spatial gradients, transient timing, or peak
     values are important.

   These simplifications are reasonable only within the intended application
   domain and for quantities that are not controlled by the neglected
   phenomena. They make the governing equations easier to understand,
   modify, test, and compare while reducing computational cost and improving
   numerical robustness.

   A simplification must not be interpreted as universally negligible.
   Before using OpenSTREAM for a new fluid, geometry, flow regime, or
   transient, assess whether the neglected terms and unresolved phenomena
   could materially affect the quantities of interest. Numerical
   convergence, sensitivity studies, conservation checks, and comparison
   with suitable reference data remain necessary.

.. dropdown:: What are the current limitations of OpenSTREAM?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM is under active development. The current implementation is
   intended for one-dimensional, thermally expandable, single-component,
   liquid-vapor boiling flows in straight channels. The thermally expandable
   formulation accounts for changes in fluid properties with the local
   thermodynamic state, but it is not a general compressible-flow
   formulation.

   The principal current limitations include:

   * **No general compressible-flow or pressure-wave formulation.**
     OpenSTREAM accounts for thermodynamic density changes associated with
     heating, cooling, pressure variation, and phase change. This
     thermally expandable treatment is suitable for the intended boiling-flow
     applications, but it is not a fully compressible-flow formulation.

     In particular, the current implementation is not intended to resolve
     acoustic-wave propagation, rapid pressure waves, shock waves, expansion
     waves, choked flow, water hammer, or other phenomena for which
     compressible pressure-wave dynamics are essential.

   * **No wall condensation model.** OpenSTREAM can represent interfacial
     condensation within the fluid, where supported by the selected solver
     and closure models, but it does not currently calculate condensation
     caused by heat transfer to a cooled wall.

   * **No counter-current flow.** The current solution algorithms and
     boundary-condition treatment are intended for co-current flow in a
     single axial direction.

   In addition, OpenSTREAM does not currently support:

   * multi-component fluid mixtures;
   * non-condensable gases;
   * wall heat conduction or conjugate heat transfer;
   * continuously varying channel area;
   * bends, junctions, plena, or connected flow networks;
   * crossflow between neighboring channels;
   * multidimensional flow resolution;
   * general-purpose component models such as pumps, valves, tanks, or heat exchangers;
   * thermal non-equilibrium in the three-field and four-field solvers;
   * fully coupled pressure-velocity solution in the advanced solvers;
   * safety or licensing analysis.

   Some currently unsupported capabilities may be considered for future development.

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

.. dropdown:: Which fluids can be simulated with OpenSTREAM?
   :animate: fade-in-slide-down
   :chevron: right-down

   OpenSTREAM is designed for single-component, liquid-vapor fluids whose
   required thermophysical properties are available through CoolProp. The
   fluid is selected using its CoolProp identifier in the ``FLUID`` model
   input.

   The CoolProp interface can be tested in MATLAB before constructing a
   complete simulation:

   .. code-block:: matlab

      cp = CoolPropWrapper.CoolPropWrapper('WATER');

   CoolProp compatibility alone does not demonstrate that an OpenSTREAM
   calculation is physically applicable or validated. The selected closure
   models must also be appropriate for the fluid and operating conditions.
   Many current models and example cases have been developed or evaluated
   primarily for boiling water and steam.

   OpenSTREAM does not currently support multi-component fluid mixtures or
   non-condensable gases. Pseudo-pure fluids, predefined mixtures, and
   incompressible solutions available in CoolProp must not be assumed to be
   compatible without verification of the full property and model
   requirements.

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
