Intended scope and limitations
==============================

**OpenSTREAM** is an open-source computational environment for the
development, assessment, and application of one-dimensional two-phase-flow
models.

The software is primarily intended to support:

- Fundamental model development.
- Implementation and assessment of closure relations.
- Comparison of alternative two-phase-flow formulations.
- Verification of numerical implementations.
- Validation against experimental data.
- Numerical sensitivity and uncertainty studies.
- Reproducible research and publication companion workflows.
- Education and collaboration in thermal-hydraulics and two-phase-flow
  modeling.

OpenSTREAM provides a flexible research environment rather than a single
fixed modeling methodology. The validity and accuracy of a calculation
depend on the selected solver framework, closure models, numerical
options, input data, and conditions under consideration.

Simulation frameworks
---------------------

OpenSTREAM includes four solver frameworks with increasing levels of
physical resolution:

- A mixture solver.
- A two-fluid solver.
- A three-field solver for annular two-phase flow.
- A four-field solver that separately represents the base film and
  disturbance waves.

The frameworks are intended for different modeling objectives. A more
detailed formulation does not necessarily provide a more accurate result
for every application. Increasing the number of fields also introduces
additional closure relations, initialization requirements, numerical
couplings, and sources of uncertainty.

A summary of the current solver capabilities is provided in the
:doc:`theory overview <theory/index>`. Detailed assumptions, governing
equations, and references are provided on the individual solver theory
pages.

Dimensional scope
-----------------

OpenSTREAM solves one-dimensional conservation equations along the
principal flow direction.

The one-dimensional formulation assumes that relevant cross-sectional
behavior can be represented using averaged quantities or closure
relations. Radial, azimuthal, and local three-dimensional effects are not
resolved directly.

The formulation is therefore most appropriate when:

- Axial transport is dominant.
- Cross-sectional quantities can be represented using averaged values.
- Local geometric effects can be represented through effective geometry,
  loss coefficients, or closure models.
- Three-dimensional flow structures are not the principal quantities of
  interest.

OpenSTREAM does not directly resolve:

- Cross-sectional velocity or void-fraction distributions.
- Local turbulent structures.
- Three-dimensional mixing between parallel channels.
- Detailed spacer-grid or obstruction flow fields.
- Local recirculation or flow separation.
- Multidimensional interface geometry.
- Computational-fluid-dynamics-scale phenomena.

The absence of these resolved effects does not necessarily prevent an
OpenSTREAM calculation, but their influence must be represented through
appropriate inputs, effective parameters, or closure relations.

Geometric scope
---------------

The current solver frameworks are designed for straight channels with one
or more wall surfaces.

Supported representations can include:

- Circular tubes.
- Annuli.
- Rectangular channels.
- Simplified rod-bundle geometries.
- Multi-wall channels with different wall-heating conditions.
- Uniformly or nonuniformly heated channels.

The separate specification of flow area, wetted or heated perimeter, wall
mesh, and wall-power distribution allows the representation of several
cross-sectional shapes within the one-dimensional formulation.

The current geometry representation does not directly model:

- Arbitrary three-dimensional flow paths.
- Branches, junctions, plena, or interconnected system networks.
- Detailed spacer-grid geometry.
- Local changes in cross-sectional shape that require multidimensional
  resolution.
- Crossflow between subchannels.
- Complex components whose behavior cannot be represented through
  one-dimensional geometry and closure relations.

Users must determine whether an effective one-dimensional representation
is adequate for the intended application.

Fluid and flow scope
--------------------

The current OpenSTREAM frameworks are primarily intended for
single-component, thermally expandable, two-phase flows.

The available models have mainly been developed and demonstrated for
co-current boiling flows under conditions relevant to thermal-hydraulic
experiments and water-cooled reactor applications.

Applicability to other fluids or operating conditions depends on:

- Availability and validity of the required thermophysical properties.
- Applicability of the selected closure relations.
- Compatibility of the flow regime with the selected solver framework.
- Numerical behavior under the investigated conditions.

A thermophysical-property calculation may be available for a fluid even
when the selected closure relations have not been assessed for that fluid.
Property availability must therefore not be interpreted as evidence that
the complete model configuration is applicable.

Flow regimes
------------

The mixture and two-fluid frameworks provide general representations of
single-phase and two-phase transport under their respective assumptions.

The three-field and four-field frameworks are intended specifically for
annular two-phase flow. Their separate liquid-film and droplet equations
are initialized at the predicted onset of annular flow using the upstream
mixture solution.

Results from the annular-flow frameworks depend on the modeling of:

- Onset of annular flow.
- Initial division of liquid between film and droplets.
- Film entrainment.
- Droplet deposition.
- Wall boiling and film evaporation.
- Field momentum transfer.
- Liquid-film dryout.
- Disturbance-wave development in the four-field framework.

The annular-flow formulations should not be assumed to apply outside the
flow regimes and conditions supported by their selected closure models.

Thermal treatment
-----------------

The mixture and two-fluid frameworks include thermal-equilibrium and
thermal-nonequilibrium capabilities, depending on the selected models.

The current three-field and four-field annular-flow formulations generally
assume thermal equilibrium while resolving hydrodynamic nonequilibrium
between the represented flow fields.

In the four-field framework, the base film and disturbance waves have
separate transport behavior. The model can represent nonequilibrium
development of disturbance-wave properties, including wave amplitude,
velocity, and frequency. This hydrodynamic nonequilibrium should not be
confused with thermal nonequilibrium between phases.

The thermal assumptions of the selected solver and closure models must be
reviewed before interpreting calculated temperatures, phase change, or
post-CHF behavior.

Closure-model dependence
------------------------

OpenSTREAM separates the conservation-equation frameworks from the
physical and closure models used to complete them.

Calculated results can depend strongly on the selected models for:

- Void fraction and phase slip.
- Wall and interfacial friction.
- Wall heat transfer.
- Thermal nonequilibrium.
- Interfacial phase change.
- Onset of annular flow.
- Film entrainment.
- Droplet deposition.
- Film and wave momentum transfer.
- Base-film equilibrium thickness.
- Disturbance-wave frequency.
- Critical boiling transition and film dryout.

The availability of a closure model in the software does not imply that
the model has been comprehensively validated for every fluid, geometry,
pressure, mass flux, flow regime, or heating condition.

Users must review:

- The theoretical basis of each selected model.
- The conditions for which the model was developed.
- The available validation evidence.
- Any empirical coefficients or nondefault parameters.
- Sensitivity of the results to alternative model selections.

A favorable result obtained using one model combination must not be
interpreted as general validation of the solver framework or of other
model combinations.

Numerical formulation
---------------------

The current governing equations are discretized using a one-dimensional
finite-volume formulation.

The standard numerical implementation uses:

- First-order upwind treatment of axial advection.
- Fully implicit backward-Euler time integration.
- Fixed-point iterations for nonlinear closures and field coupling.
- Pseudo-time advancement to obtain steady-state solutions.
- Physical-time advancement for transient calculations.

These methods are designed to provide a robust and transparent baseline
for model development and application. They also introduce limitations.

First-order spatial and temporal discretizations can introduce numerical
diffusion and can reduce the resolution of sharp gradients or rapidly
varying behavior. Results may depend on:

- Axial mesh resolution.
- Physical or pseudo-time-step selection.
- Point-iteration tolerances.
- Temporal convergence criteria.
- Under-relaxation factors.
- Interpolation options.
- Initialization and field-transition procedures.

A converged nonlinear or temporal solution is not necessarily independent
of the mesh, time step, or numerical options.

Numerical sensitivity
---------------------

Calculations used for quantitative conclusions should include numerical
sensitivity studies appropriate to the application.

Relevant studies can include:

- Axial mesh refinement.
- Physical time-step refinement.
- Pseudo-time-step sensitivity.
- Point-iteration tolerance sensitivity.
- Temporal convergence tolerance sensitivity.
- Under-relaxation sensitivity.
- Sensitivity to field initialization.
- Sensitivity to the location of modeled flow-regime transitions.
- Comparison of available interpolation or discretization options.

A calculation should not be considered numerically verified solely because
the solver reports a converged state.

Convergence
-----------

OpenSTREAM distinguishes between:

- Pointwise convergence of coupled variables at a location and time step.
- Pseudo-time convergence toward a steady-state solution.
- Physical-time advancement in a transient calculation.

Convergence difficulties can occur near:

- Onset of boiling.
- Onset of annular flow.
- Field initialization.
- Film dryout or rewetting.
- Sharp changes in wall heating.
- Strong interfacial-transfer regions.
- Discontinuities in geometry or local-loss definitions.

Under-relaxation, smaller pseudo-time steps, mesh refinement, or improved
initialization can assist convergence. Such numerical adjustments should
be documented and shown not to alter the intended converged physical
solution materially.

A calculation that does not meet the selected convergence criteria should
not be presented as a converged OpenSTREAM result.

Steady-state and transient calculations
---------------------------------------

The OpenSTREAM solver frameworks support steady-state and transient
calculations.

Steady-state solutions are generally obtained through pseudo-time
advancement. The pseudo-time history is a numerical procedure for reaching
a steady solution and should not be interpreted as physical transient
behavior.

Transient calculations use physical time and require appropriate initial
conditions, time-step selection, and time-dependent boundary conditions.

The availability of transient execution does not imply that every closure
model has been validated for transient applications. Models based on
steady-state or local-equilibrium assumptions require particular care when
used in rapidly changing conditions.

Validation status
-----------------

OpenSTREAM includes models and solver frameworks that have been compared
with selected experimental datasets and reference calculations.

Validation is necessarily limited to the investigated:

- Fluids.
- Geometries.
- Flow regimes.
- Pressures.
- Mass fluxes.
- Thermal conditions.
- Boundary conditions.
- Measured quantities.
- Solver and closure-model configurations.

Inclusion of a comparison in a publication, tutorial, dataset package, or
application project does not constitute comprehensive validation outside
the examined conditions.

The OpenSTREAM-database repository provides dataset implementations and
calculated-versus-measured workflows for model assessment. Dataset-specific
documentation should be reviewed for provenance, measurement uncertainty,
processing methods, supported comparisons, and known limitations.

Publication companion workflows reproduce or illustrate selected
calculations and figures from the corresponding publications. The
companions do not represent complete records of the underlying research
programmes. Additional cases, sensitivity studies, closure-model
development, uncertainty analyses, and intermediate investigations may
have been performed but are not necessarily included.

Verification and testing
------------------------

OpenSTREAM includes automated environment, unit, integration, and
regression tests.

The tests provide evidence that the implemented and tested functionality
behaves as expected in the tested software environments. The automated
test suite does not currently exercise every:

- Class or method.
- Solver path.
- Closure-model combination.
- Input option.
- Error condition.
- Transient application.
- Post-processing capability.

Passing the available tests does not constitute complete verification or
validation of OpenSTREAM.

Contributors and users remain responsible for performing verification
appropriate to their changes and applications.

Uncertainty
-----------

OpenSTREAM calculations can be affected by several categories of
uncertainty:

- Experimental uncertainty.
- Source-data transcription or digitization uncertainty.
- Thermophysical-property uncertainty.
- Closure-model uncertainty.
- Model-parameter uncertainty.
- Numerical uncertainty.
- Boundary-condition uncertainty.
- Geometric simplification.
- Measurement-to-calculation alignment.

Calculated-versus-measured agreement should be interpreted in relation to
the relevant uncertainties. Small numerical differences do not necessarily
indicate meaningful model differences, while apparent agreement does not
necessarily demonstrate that the underlying physical mechanisms are
represented correctly.

Open research software
----------------------

OpenSTREAM is developed as an open and extensible research platform. The
source code is available for inspection, modification, testing, and
extension.

The open implementation improves transparency but does not remove the need
for engineering judgment, verification, validation, peer review, or
documentation.

Users who modify solver equations, closure models, default parameters,
numerical methods, or reference solutions should:

- Document the changes.
- Add or update relevant tests.
- Review numerical differences.
- Reassess applicable validation evidence.
- Record the software version or commit used.
- Avoid presenting modified results as results from an unmodified
  OpenSTREAM release.

Intended use
------------

OpenSTREAM is well suited to:

- Fundamental thermal-hydraulic model development.
- Closure-model implementation and comparison.
- One-dimensional solver development.
- Experimental-data assessment.
- Reproducible calculation workflows.
- Sensitivity and uncertainty studies.
- Educational demonstrations.
- Research collaboration.
- Development of models for later integration into more comprehensive
  simulation tools.

OpenSTREAM should be used with particular caution when:

- Three-dimensional effects dominate the phenomenon.
- The geometry cannot be represented adequately as a straight channel.
- Crossflow or network behavior is important.
- The selected closure relations are applied outside their documented
  ranges.
- Experimental validation is unavailable for the conditions of interest.
- Numerical sensitivity has not been assessed.
- Results are strongly dependent on uncertain or nondefault parameters.

Reproducibility of reported results
-----------------------------------

Calculations reported in publications, technical reports, presentations,
or other research outputs should retain sufficient information to
reproduce the reported results.

The reproducibility record should identify, as applicable:

- The OpenSTREAM version, release, or commit.
- The OpenSTREAM-database version, release, or commit, when used.
- The MATLAB version.
- The Python and CoolProp versions.
- The selected OpenSTREAM solver framework.
- The input files, input identifiers, dataset records, or lightweight
  in-memory case definition.
- The selected physical and closure models.
- All nondefault model parameters.
- The selected numerical options.
- The axial mesh and physical or pseudo-time-step settings.
- The pointwise and temporal convergence criteria.
- The final convergence status.
- Any under-relaxation or initialization settings introduced to obtain
  convergence.
- The scripts or Live Scripts used to perform the calculations and
  generate the reported figures.
- Any filtering, interpolation, smoothing, averaging, or other
  post-processing applied.
- The distinction between directly measured, derived, and calculated
  quantities.
- Any experimental cases, sensitivity studies, or intermediate analyses
  intentionally omitted from the published companion workflow.

Where practical, reported results should be accompanied by an executable
script or MATLAB Live Script. The workflow should generate the reported
quantities and figures from the documented inputs rather than relying only
on stored output files.

A publication companion workflow may focus on the calculations and figures
selected for publication. It should not be presented as a complete record
of the underlying research activities, which may include additional test
cases, closure-model development, sensitivity studies, uncertainty
analyses, numerical investigations, and intermediate results.

Generated solver outputs alone are not sufficient for reproducibility.
The retained record must include the software versions, inputs, model
selections, numerical settings, convergence information, and
post-processing procedure needed to regenerate the results.

User responsibilities
---------------------

Users are responsible for:

- Selecting an appropriate solver framework.
- Selecting physically applicable closure models.
- Reviewing assumptions and validity ranges.
- Defining consistent geometry and boundary conditions.
- Confirming unit consistency.
- Reviewing generated inputs.
- Confirming numerical convergence.
- Performing appropriate mesh and time-step sensitivity studies.
- Evaluating experimental, model, parameter, and numerical uncertainty.
- Reviewing available validation evidence.
- Recording the software version or commit used.
- Documenting nondefault models, parameters, and numerical settings.
- Interpreting results within the limits of the selected formulation.

For research and publication work, users should retain sufficient
information to reproduce the calculation, including inputs, model
selections, numerical options, software versions, convergence status, and
post-processing procedures.

Further information
-------------------

For additional details, consult:

- The :doc:`theory overview <theory/index>`.
- The individual solver theory pages.
- The :doc:`tutorials <../tutorials/index>`.
- The numerical convergence tutorial.
- The OpenSTREAM package reference.
- The :doc:`OpenSTREAM-database <../Applications/database>` documentation.
- The available publications and publication companion workflows.

The detailed formulation and documented assumptions of the selected solver
and closure models take precedence over this high-level summary.