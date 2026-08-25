Getting started
===============

**OpenSTREAM** is a MATLAB program for simulating one-dimensional two-phase
flows. Fluid properties are calculated using the Python version of
`CoolProp <http://www.coolprop.org>`_ through
`CoolPropWrapper <https://github.com/mfval/CoolPropWrapper>`_, a MATLAB
interface to CoolProp.

This guide explains how to obtain OpenSTREAM, configure MATLAB and Python,
install the required dependencies, and verify the installation.

Prerequisites
-------------

Before installing and configuring OpenSTREAM, ensure that the following
software is available:

- MATLAB.
- A Python version compatible with the installed MATLAB release.
- Git or GitHub Desktop.

CoolProp and its associated Python dependencies are installed later in
this guide.

No additional MathWorks toolbox is currently required by the core
OpenSTREAM solver frameworks.

Install OpenSTREAM
------------------

OpenSTREAM is hosted in the
`OpenSTREAM GitHub repository
<https://github.com/OpenSTREAM-solvers/openstream>`_.

There are two principal ways to obtain and maintain a local copy of the
repository:

- The `Git command-line interface
  <https://docs.github.com/en/get-started/getting-started-with-git/set-up-git>`_.
- `GitHub Desktop <https://desktop.github.com/>`_.

Install using the Git command-line interface
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Clone the repository and its submodules using SSH:

.. code-block:: bash

   git clone --recursive git@github.com:OpenSTREAM-solvers/openstream.git

Alternatively, clone the repository using HTTPS:

.. code-block:: bash

   git clone --recursive https://github.com/OpenSTREAM-solvers/openstream.git

The ``--recursive`` option also clones the repository submodules,
including
`CoolPropWrapper <https://github.com/mfval/CoolPropWrapper>`_.

For information about authentication, see:

- `Connecting to GitHub with SSH
  <https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent>`_.
- `Caching GitHub credentials
  <https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git>`_.
- `Working with Git submodules
  <https://git-scm.com/book/en/v2/Git-Tools-Submodules>`_.

Enter the cloned repository:

.. code-block:: bash

   cd openstream

Install using GitHub Desktop
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open GitHub Desktop, sign in, and select **Clone repository**. Select the
OpenSTREAM repository and choose the local destination folder.

After cloning, verify that the ``CoolPropWrapper`` submodule contains its
expected files. If the submodule is empty, initialize it from a terminal
opened in the repository root:

.. code-block:: bash

   git submodule update --init --recursive

MATLAB and Python compatibility
-------------------------------

OpenSTREAM requires MATLAB. No additional MathWorks toolbox is currently
required by the core solver frameworks. Fluid properties are calculated
externally using the Python version of CoolProp through CoolPropWrapper.

OpenSTREAM is tested with selected MATLAB and Python version combinations
through its continuous-integration workflow.

.. list-table:: CI-tested MATLAB and Python configurations
   :header-rows: 1
   :widths: 40 30

   * - MATLAB release
     - Python version
   * - R2024b
     - 3.11
   * - R2025b
     - 3.12
   * - R2026a
     - 3.13

These combinations represent configurations tested by the OpenSTREAM
continuous-integration workflow. Other MATLAB and Python combinations may
work but are not necessarily tested. Python 3.14 is not currently included
in the tested CI configuration.

The tested software configurations apply to the OpenSTREAM version or
development revision documented on this site. See
:doc:`Release numbering and versioning <../Usage/versioning>` for the
project versioning convention.

Compatibility policy
~~~~~~~~~~~~~~~~~~~~

OpenSTREAM distinguishes between tested and untested software
configurations. A tested configuration is a combination of MATLAB, Python,
CoolProp, and associated dependencies that is exercised by the OpenSTREAM
continuous-integration workflow.

The configurations listed above represent the environments tested for the
current OpenSTREAM development version or release. Other software
combinations may work but are not guaranteed and may not be covered by
automated testing.

Compatibility information may change as new MATLAB, Python, and CoolProp
versions become available. Consult the compatibility information
corresponding to the OpenSTREAM version being used.

Configure MATLAB and Python
---------------------------

Before using OpenSTREAM, verify that a suitable Python version is installed
and that MATLAB is configured to use the corresponding Python executable.

The general compatibility requirements are available in the
`MathWorks Python compatibility table
<https://www.mathworks.com/support/requirements/python-compatibility.html>`_.
The **MATLAB Interface** column identifies the Python versions supported by
each MATLAB release.

The following configuration instructions are adapted from the
`CoolPropWrapper repository
<https://github.com/mfval/CoolPropWrapper>`_.

Inspect the configured Python environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In MATLAB, inspect the current Python environment:

.. code-block:: matlab

   pythonEnvironment = pyenv;
   disp(pythonEnvironment)

If no Python environment is configured, or if the configured version is
not suitable for the installed MATLAB release, install a compatible Python
version and configure MATLAB to use it.

Install a compatible Python version
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Windows**

Download the required version from
`Python.org <https://www.python.org/downloads/>`_ and follow the
installation instructions.

**Linux**

Check whether Python is already available:

.. code-block:: bash

   python3 --version

If necessary, install an appropriate version using the operating-system
package manager. For example, on a Debian-based distribution:

.. code-block:: bash

   sudo apt-get install python3.x

Replace ``x`` with the required minor version.

**macOS**

Check the available Python version:

.. code-block:: bash

   python3 --version

If an appropriate version is not available, install one using Homebrew:

.. code-block:: bash

   brew install python

Alternatively, download the required version from
`Python.org <https://www.python.org/downloads/>`_.

Configure the Python executable in MATLAB
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure MATLAB to use the required Python executable:

.. code-block:: matlab

   pyenv('Version','<path-to-python-executable>')

Replace ``<path-to-python-executable>`` with the complete path to the
Python executable.

Typical locations include:

- **Windows:** ``C:\Users\Username\AppData\Local\Programs\Python\Python311\python.exe``
- **Linux:** ``/usr/bin/python3.11``
- **macOS:** ``/usr/local/bin/python3`` or ``/opt/homebrew/bin/python3``

On Linux and macOS, commands such as ``which python3`` can help locate the
executable.

Install the Python dependencies
-------------------------------

The recommended approach is to install the dependencies from the
requirements file supplied with CoolPropWrapper.

Alternatively, install the dependencies used by the current
continuous-integration environment directly:

.. code-block:: console

   python -m pip install CoolProp==8.0.0 nanobind

In the commands above, ``python`` must refer to the same Python executable
configured through ``pyenv``. If necessary, replace ``python`` with the
complete path to that executable.

The current OpenSTREAM continuous-integration environment installs
``CoolProp==8.0.0`` together with ``nanobind``. Other CoolProp versions
may work but are not necessarily tested.

When several Python installations are available, ensure that the
dependencies are installed using the same Python executable configured in
MATLAB.

Verify the installation
-----------------------

After configuring MATLAB and Python, verify that MATLAB is using the
intended Python environment and that CoolProp is accessible through
CoolPropWrapper.

Inspect the Python environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: matlab

   pythonEnvironment = pyenv;
   disp(pythonEnvironment)

Confirm that the reported executable and Python version correspond to the
intended installation.

Verify the Python packages
~~~~~~~~~~~~~~~~~~~~~~~~~~

From a terminal, use the same Python executable configured in MATLAB:

.. code-block:: console

   python -m pip show CoolProp
   python -m pip show nanobind

Create a CoolPropWrapper object
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In MATLAB, create a fluid-property object:

.. code-block:: matlab

   fluidProperties = ...
       CoolPropWrapper.CoolPropWrapper('WATER');

Successful construction confirms that MATLAB can access Python, import
CoolProp, and initialize the requested fluid.

Evaluate a representative fluid property
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Evaluate the saturation temperature of water at 6 MPa:

.. code-block:: matlab

   saturationTemperature = ...
       fluidProperties.temperature('P',6.0e6,'Q',0);

   disp(saturationTemperature)

A finite numerical result confirms that the MATLAB-Python-CoolProp
interface is functioning.

Run the automated tests
~~~~~~~~~~~~~~~~~~~~~~~

From the OpenSTREAM ``tests`` folder, run the complete automated test
suite:

.. code-block:: matlab

   runOpenSTREAMTests

The complete suite includes environment, unit, and integration tests. The
environment tests verify Python availability, package installation, and
basic CoolProp functionality. The same complete test suite is executed by
the MATLAB continuous-integration workflow when changes are pushed to the
repository.

Run the sample script
~~~~~~~~~~~~~~~~~~~~~

Run the :doc:`sample script <../Usage/runSampleScript>` to perform a
complete OpenSTREAM calculation and confirm that the installation is
functioning correctly.

The sample calculation uses the mixture solver to simulate boiling
two-phase flow in a uniformly heated tube followed by an adiabatic
section. It constructs the required input objects, evaluates the fluid
properties, solves the case, generates representative axial plots, and
saves the solver object.

Run the commands from the OpenSTREAM repository root, as described on the
sample-script page.

Next steps
----------

Congratulations! At this point, you should have a local copy of OpenSTREAM
and a functioning MATLAB, Python, and CoolProp configuration.

Continue with the :doc:`OpenSTREAM tutorials <../Guides/tutorials>`,
beginning with Tutorial 1: Quick Start. Tutorial 1 constructs the input
objects, runs the example case with the mixture, two-fluid, three-field,
and four-field solver frameworks, generates representative plots, and
saves the solver objects.

You can then continue with the solver-specific and workflow-oriented
tutorials according to your interests.