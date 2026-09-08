# OpenSTREAM sandbox

This folder provides a local workspace for exploratory OpenSTREAM
calculations.

The sandbox can be used to:

- create and run temporary OpenSTREAM cases;
- experiment with physical models and numerical options;
- inspect solver fields, convergence behavior, and calculated results;
- test alternative model configurations;
- develop ideas before moving them to a maintained tutorial, test, or
  source package.

## Repository policy

Files created in this folder are not part of the maintained OpenSTREAM
source, tutorials, or test suite. User-created scripts, input files,
calculation results, figures, logs, session directories, and saved MATLAB
objects should not be committed to the repository.

The following files may be maintained under version control:

- this `README.md` file;
- files named `*_default.m` that provide clean starting templates.

Copy and rename a default template before modifying it. For example:

```text
example_default.m -> my_exploratory_case.m