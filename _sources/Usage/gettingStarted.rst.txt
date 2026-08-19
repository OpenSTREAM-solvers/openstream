Getting started
===============

Prerequisites and installation
------------------------------

**OpenSTREAM** is a MATLAB program for simulating one-dimensional two-phase flows.
The Python version of
`CoolProp <http://www.coolprop.org>`__ is
used for calculating the fluid properties.
`CoolPropWrapper <https://github.com/mfval/CoolPropWrapper>`__ is a
MATLAB interface that interacts with CoolProp through Python. Both
OpenSTREAM and CoolProp are hosted on GitHub. Making a copy
(cloning) of these programs will be our first step.

Install using Git and GitHub
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  There are two main ways of interacting with GitHub to use and
   contribute to the OpenSTREAM project: `Git Command Line Interface
   (CLI) <https://docs.github.com/en/get-started/getting-started-with-git/set-up-git>`__,
   and the `GitHub Desktop <https://desktop.github.com/>`__ program. Use
   the links to set up one of the methods.

-  After installing and setting up your Git mechanism of choice, if you
   chose to use the:

   -  **Command line interface**

      -  Clone (make a copy of) the repository using:
         ``git clone --recursive git@github.com:OpenSTREAM-solvers/openstream.git``
         (`SSH
         authentication <https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent>`__)

         or

         ``git clone --recursive https://github.com/OpenSTREAM-solvers/openstream.git``
         (`HTTPS
         authentication <https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git>`_).
         
         (The ``--recursive`` flag is needed to clone
         `submodules <https://git-scm.com/book/en/v2/Git-Tools-Submodules>`_,
         such as the
         `mfval/CoolPropWrapper <https://github.com/mfval/CoolPropWrapper>`_,
         in one command.)
      -  Then, use ``cd openstream`` to enter the newly created
         folder. You should see the newly downloaded files for the
         project.

   -  **GitHub Desktop program**

      -  Open the program, login, and **Clone repository**. Everything
         should be cloned automatically. This is part of the setup guide
         linked above.

MATLAB and Python compatibility
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OpenSTREAM requires MATLAB. No additional MathWorks toolbox is currently
required by the core solver frameworks. Fluid properties are calculated
externally using the Python version of CoolProp through CoolPropWrapper.

OpenSTREAM is tested with selected MATLAB and Python version combinations
through its continuous-integration workflow. The configurations currently
exercised by the continuous-integration workflow are listed below.

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
^^^^^^^^^^^^^^^^^^^^

OpenSTREAM distinguishes between tested and untested software
configurations. A tested configuration is a combination of MATLAB, Python,
CoolProp, and associated dependencies that is exercised by the OpenSTREAM
continuous-integration workflow.

The configurations listed above represent the environments tested for the
current OpenSTREAM development version or release. Other software
combinations may work but are not guaranteed and may not be covered by
automated testing.

The compatibility information may change as new MATLAB, Python, and
CoolProp versions become available. Users should consult the compatibility
information corresponding to the OpenSTREAM version they are using.

Configure MATLAB and Python
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Before using OpenSTREAM, verify that a suitable Python version is installed
and that MATLAB is configured to use the corresponding Python executable.
The general MATLAB-Python compatibility requirements are available in the
`MathWorks Python compatibility table
<https://www.mathworks.com/support/requirements/python-compatibility.html>`_.
The *MATLAB Interface* column identifies the Python versions supported by
each MATLAB release.

The following configuration instructions are adapted from the
`CoolPropWrapper repository
<https://github.com/mfval/CoolPropWrapper>`_.

1. Inspect the Python environment currently used by MATLAB:

   .. code-block:: matlab

      pythonEnvironment = pyenv;
      disp(pythonEnvironment)

   If no Python environment is configured, or if the configured Python
   version is unsuitable for the installed MATLAB release, continue with
   the Python installation instructions below. Otherwise, proceed to the
   dependency-installation step.

2. Install compatible Python3

   -  **Windows**: Go to
      `python.org <https://www.python.org/downloads/>`__ to download the
      specific version of Python you need. Follow the setup procedure.
   -  **Linux**: A Python installation may already be available. Verify the
      version using ``python3 --version``. If Python is not installed, or
      an incompatible version is installed, install an appropriate version
      using the OS package manager. For Debian-based Linux distros (such as
      Ubuntu), use ``sudo apt-get install python3.x`` to install the *x*
      version of Python3.
   -  **MacOS**: Most recent versions of macOS include Python or can
      install it through Homebrew or the official Python installer.
      Verify the installed version using: ``python3 --version``. If a
      compatible version is not available, install one using Homebrew:
      ``brew install python`` or download the appropriate version directly
      from `python.org <https://www.python.org/downloads/>`__.

3. Specify Python installation location in MATLAB:

   -  Run ``pyenv('Version', 'pathtopython')``, where ``pathtopython`` is the path
      to where Python is installed. Here are some typical locations
      depending on your OS:

      -  **Windows**:
         ``C:\Users\Username\AppData\Local\Programs\Python\Python311\python.exe``,
         for version 3.11.
      -  **Linux**: ``/usr/bin/python3.11``, for version 3.11. Use
         ``whereis python3`` to find possible locations.
      -  **MacOS**: The Python executable is typically located using:
         ``which python3``. Common installation locations include:
         ``/usr/local/bin/python3`` and ``/opt/homebrew/bin/python3``.

4. Install the CoolPropWrapper Python dependencies:

   * The recommended approach is to install the dependencies from the
     requirements file provided with CoolPropWrapper.

   * Alternatively, install the dependencies used by the current
     continuous-integration environment directly:

     .. code-block:: console

        python -m pip install CoolProp==8.0.0 nanobind

The current OpenSTREAM continuous-integration environment installs
``CoolProp==8.0.0`` together with ``nanobind``. Other CoolProp versions
may work but are not necessarily tested. Installing the dependencies from
the CoolPropWrapper requirements file is recommended to reproduce the
maintained configuration.

Verify the installation
~~~~~~~~~~~~~~~~~~~~~~~

After configuring MATLAB and Python, verify that MATLAB is using the
intended Python environment and that CoolProp can be accessed through
CoolPropWrapper.

1. Display the Python environment used by MATLAB:

   .. code-block:: matlab

      pythonEnvironment = pyenv;
      disp(pythonEnvironment)

   Confirm that the reported executable and Python version correspond to
   the intended installation. If MATLAB is using a different Python
   environment, configure the required executable using ``pyenv`` before
   continuing.

2. Verify the required Python packages from a terminal using the same
   Python executable configured in MATLAB:

   .. code-block:: console

      python -m pip show CoolProp
      python -m pip show nanobind

   The OpenSTREAM continuous-integration environment currently uses
   ``CoolProp==8.0.0`` together with ``nanobind``. Installing the
   dependencies from the CoolPropWrapper requirements file is recommended
   to reproduce the tested environment.

3. Create a CoolPropWrapper object in MATLAB:

   .. code-block:: matlab

      fluidProperties = ...
          CoolPropWrapper.CoolPropWrapper('WATER');

   Successful construction confirms that MATLAB can access Python,
   import CoolProp, and initialize the requested fluid.

4. Evaluate a representative fluid property:

   .. code-block:: matlab

      saturationTemperature = ...
          fluidProperties.temperature('P',6.0e6,'Q',0);

      disp(saturationTemperature)

   This call evaluates the saturation temperature of water at a pressure
   of 6 MPa. A finite numerical result confirms that the MATLAB-Python-
   CoolProp interface is functioning.

5. Run Tutorial 1 from the OpenSTREAM ``tutorials`` folder. The tutorial
   constructs the input objects, evaluates fluid properties, solves the
   example case with the available solver frameworks, and generates
   representative plots.

If any verification step fails, first confirm that MATLAB is using the
intended Python executable and that ``CoolProp`` and ``nanobind`` are
installed in that same Python environment.

Next steps
~~~~~~~~~~

Congrats! Hopefully, at this point, you have successfully made a copy of
this repo and installed the required programs. Next, let’s run the
sample script to make sure everything is working properly.