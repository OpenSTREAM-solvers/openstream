[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Documentation](https://github.com/OpenSTREAM-solvers/openstream/actions/workflows/publishDocs.yml/badge.svg)](https://github.com/OpenSTREAM-solvers/openstream/actions/workflows/publishDocs.yml)
[![MATLAB Tests](https://github.com/OpenSTREAM-solvers/openstream/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/OpenSTREAM-solvers/openstream/actions/workflows/ci.yml)

# OpenSTREAM

OpenSTREAM (**Open** **S**olvers for **T**wo-phase flow **R**esearch,
**E**ngineering **A**nalysis and **M**odeling) is an open-source
computational environment for simulating one-dimensional, multi-field,
two-phase flows, including phase change.

OpenSTREAM is designed to support collaborative physical-model
development, implementation, assessment, and validation across users and
institutions.

OpenSTREAM includes four solver frameworks:

- A **mixture solver** with hydrodynamic and thermal nonequilibrium
  capabilities.
- A generic **two-fluid solver** with separate liquid and vapor fields.
- A **three-field solver** for annular flow with liquid-film and
  entrained-droplet fields.
- A **four-field solver** for annular flow with base-film,
  disturbance-wave, entrained-droplet, and vapor fields.

The solvers support single-component, thermally expandable, steady-state
and transient boiling two-phase flows in single straight channels under
the assumptions associated with the selected solver frameworks and
models.

OpenSTREAM includes physical and closure models, numerical methods, input
handling, visualization and post-processing capabilities, tutorials,
documentation, and automated environment, unit, integration, and
regression tests.

## Getting started

Installation, MATLAB and Python compatibility, CoolProp configuration,
and verification instructions are available in the
[Getting Started guide](https://openstream-solvers.github.io/openstream/Usage/gettingStarted.html).

After installation, run the
[sample script](https://openstream-solvers.github.io/openstream/Usage/runSampleScript.html)
to perform a complete mixture-solver calculation and confirm that the
installation is functioning correctly.

## Tutorials

The [OpenSTREAM tutorials](https://openstream-solvers.github.io/openstream/Guides/tutorials.html)
introduce the solver frameworks and principal workflows through MATLAB
Live Scripts.

The tutorials cover:

- Quick-start calculations using all four solver frameworks.
- Mixture-, two-fluid-, three-field-, and four-field solver capabilities.
- Input-file construction and management.
- Numerical convergence and solver diagnostics.
- Mesh and time-step sensitivity.
- Advanced visualization and post-processing.

## Applications and validation

The companion OpenSTREAM-database repository provides an application and
validation environment for OpenSTREAM using publicly available
experimental datasets.

OpenSTREAM and OpenSTREAM-database are maintained as separate
repositories. OpenSTREAM-database requires a compatible OpenSTREAM
installation and is not included as a Git submodule.

Further information is available on the
[OpenSTREAM-database application page](https://openstream-solvers.github.io/openstream/Applications/database.html).

## Automated testing

OpenSTREAM includes automated environment, unit, integration, and
regression tests.

From the `tests` folder, run:

```matlab
runOpenSTREAMTests
```

The test runner discovers the available test classes, displays detailed
diagnostics, produces a summary table, reports the total execution time,
and raises an error if any test fails or does not complete.

The complete available test suite is also executed by MATLAB CI when
changes are pushed to the repository.

The automated test suite is under active development and does not yet
provide comprehensive coverage of every OpenSTREAM class, model,
numerical option, solver path, or post-processing capability.

Further information is available in the
[Testing and verification guide](https://openstream-solvers.github.io/openstream/Guides/testing.html).

## Documentation

The complete [OpenSTREAM documentation](https://openstream-solvers.github.io/openstream/)
includes:

- Installation and compatibility information.
- Solver theory and mathematical models.
- Tutorials and sample calculations.
- Input and package documentation.
- Testing and contribution guidelines.
- OpenSTREAM-database applications.
- Glossary, notation, and references.

## Citing OpenSTREAM

If OpenSTREAM is used in research or published work, cite the relevant
OpenSTREAM publications:

- J.-M. Le Corre, J. Chan, E. Walter, E. T. Hurlburt, and R. W. Morse,
  “OpenSTREAM: A new open-source platform for two-phase flow model
  development,” *12th International Conference on Multiphase Flow
  (ICMF 2025)*, Toulouse, France, May 12–16, 2025.

- J.-M. Le Corre, J. Chan, E. Walter, E. T. Hurlburt, and R. W. Morse,
  “OpenSTREAM: An open-source platform for two-phase flow modeling and
  simulation,” *21st International Topical Meeting on Nuclear Reactor
  Thermal Hydraulics (NURETH-21)*, Busan, Korea,
  August 31–September 5, 2025.

When OpenSTREAM is applied to experimental data provided through
OpenSTREAM-database, the original experimental publications should also
be cited.

## Contributing

Contributions to the OpenSTREAM solvers, physical and closure models,
numerical methods, documentation, tutorials, examples, and automated tests
are welcome.

Before contributing, review the
[OpenSTREAM contribution guidelines](https://openstream-solvers.github.io/openstream/Community/contribute_code.html).

## License

OpenSTREAM is distributed under the MIT License. This permits use,
modification, and distribution of the software, provided that the original
copyright notice and license text are retained.

See the [LICENSE](LICENSE) file for the complete terms.
