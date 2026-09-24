Tutorials
=========

Ready to get hands-on with **OpenSTREAM**? These tutorials introduce the
principal solver frameworks, input formats, numerical workflows, and
post-processing capabilities of OpenSTREAM, progressing from a basic
example to more advanced simulation and analysis tasks.

Each tutorial is provided as a MATLAB Live Script in the OpenSTREAM
``tutorials`` folder. The Live Scripts can be executed, modified, and
extended directly in MATLAB. Exported HTML versions are also available
through the links below.

.. note::

   The tutorials are intended to be executed interactively as MATLAB Live
   Scripts. Some tutorials include animations and interactive figures that
   are displayed in separate pop-up windows when run from the MATLAB Live
   Editor. These interactive features and their controls are generally not
   available in the exported HTML versions.


1. Quick Start
--------------

`Open Tutorial 1: Quick Start
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial01_quick_start.html>`_

Run a provided OpenSTREAM case using the mixture, two-fluid, three-field,
and four-field solver frameworks. This tutorial introduces input loading,
solver construction, basic axial plots, inspection of selected results,
and saving solver objects. It is the recommended starting point for new
users.


2. Mixture Solver Capabilities
------------------------------

`Open Tutorial 2: Mixture Solver Capabilities
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial02_mixture.html>`_

Explore homogeneous and nonhomogeneous mixture formulations, including
fixed-slip and drift-flux models. The tutorial also introduces empirical
and relaxation-based thermal-non-equilibrium models, pressure-drop
components, wall-friction and local-loss options, and a physical transient
calculation.


3. Two-Fluid Solver Capabilities
--------------------------------

`Open Tutorial 3: Two-Fluid Solver Capabilities
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial03_twofluid.html>`_

Construct and run two-fluid calculations with separate liquid and vapor
fields. Examine phase mass flow rates, velocities, enthalpies,
temperatures, hydrodynamic and thermal non-equilibrium, interfacial area,
flow-regime indicators, phase exchange terms, pseudo-time convergence,
and physical transient behavior.


4. Three-Field Solver Capabilities
----------------------------------

`Open Tutorial 4: Three-Field Solver Capabilities
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial04_threefield.html>`_

Model annular flow using separate liquid-film and entrained-droplet fields
together with the mixture-model vapor solution. Compare onset-of-annular-
flow initialization methods, momentum formulations, entrainment and
deposition closures, film thickness, mass and momentum exchange terms,
pseudo-time convergence, and transient behavior.


5. Four-Field Solver Capabilities
---------------------------------

`Open Tutorial 5: Four-Field Solver Capabilities
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial05_fourfield.html>`_

Extend the three-field formulation by separating the liquid film into
base-film and disturbance-wave fields. Examine film decomposition, wave
geometry and frequency, field fractions, onset-of-annular-flow splitting,
equilibrium and relaxation models, momentum formulations, field exchange
terms, pseudo-time convergence, and a physical transient calculation.


6. Input Files
--------------

`Open Tutorial 6: Input Files
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial06_inputfiles.html>`_

Learn how OpenSTREAM cases are assembled from physical-model, numerical-
option, geometry, and boundary-condition inputs. This tutorial demonstrates
input-set selection, inspection of imported objects, loading equivalent
model definitions from INP and JSON files, and conversion of native input
files to JSON.


7. Numerical Convergence and Solver Diagnostics
-----------------------------------------------

`Open Tutorial 7: Numerical Convergence and Solver Diagnostics
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial07_convergence.html>`_

Distinguish local pointwise convergence, pseudo-time convergence, and
physical-time advancement. Inspect solver states and initialization
histories, examine the influence of relaxation factors and the pseudo-time
step, troubleshoot convergence difficulties, and assess whether a
converged solution is numerically consistent.


8. Mesh and Time-Step Sensitivity
---------------------------------

`Open Tutorial 8: Mesh and Time-Step Sensitivity
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial08_meshandtimestep.html>`_

Evaluate the sensitivity of mixture-solver results to spatial and temporal
discretization. Compare steady-state solutions calculated with different
axial meshes and transient responses calculated with different physical
time steps. The tutorial also discusses local resolution, peak values,
transition timing, computational effort, and the distinction between a
sensitivity assessment and a systematic convergence study.


9. Advanced Visualization and Post-Processing
---------------------------------------------

`Open Tutorial 9: Advanced Visualization and Post-Processing
<https://openstream.readthedocs.io/en/latest/_static/html/tutorial09_visualization.html>`_

Apply the principal OpenSTREAM visualization and post-processing
capabilities to a transient solution. Generate animated axial
distributions, time histories at selected elevations, and time-elevation
surfaces. Extract calculated quantities, assemble MATLAB tables, export
selected results to CSV, and save and reload solver objects for additional
analysis.


.. warning::

   The physical models, closure relations, numerical settings, and solver
   options selected throughout these tutorials are intended for educational
   and demonstration purposes.

   Their use in a tutorial does not imply that they are appropriate,
   recommended, calibrated, verified, or validated for a particular
   application. Before applying OpenSTREAM to a technical study, assess the
   assumptions, applicability range, calibration basis, numerical
   sensitivity, and validation evidence associated with every selected
   model.