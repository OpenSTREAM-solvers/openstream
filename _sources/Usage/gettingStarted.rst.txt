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

Install using Git and Github
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

MATLAB-Python compatibility
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before using OpenSTREAM, we need to make sure Python with the appropriate
version is installed, and MATLAB knows the location of the Python
executable. The following instructions are from the
`CoolPropWrapper <https://github.com/mfval/CoolPropWrapper>`_ repo.

1. Determine which versions of Python are compatible with your version
   of MATLAB: `compatibility
   list <https://www.mathworks.com/support/requirements/python-compatibility.html>`__.
   The second column, *MATLAB Interface MATLAB Engine*, shows the
   compatible Python versions.

2. Start MATLAB and verify a compatible python version is installed:

   -  Run ``pyenv()``

      -  If the results are empty or an incompatible Python version is
         shown, go to step 3.
      -  If the results are satisfactory, continue to step 5.

3. Install compatible Python3

   -  **Windows**: Go to
      `python.org <https://www.python.org/downloads/>`__ to download the
      specific version of Python you need. Follow the setup procedure.
   -  **Linux**: Chances are, you already have a version of Python
      installed. Verify the version using ``python3 --version``. If
      Python is not installed, or an incompatible version is installed,
      install appropriate version using the OS package manager. For
      Debian-based Linux distros (such as Ubuntu), use
      ``sudo apt-get install python3.x`` to install the *x* version of
      Python3.
   -  **MacOS**: Most recent versions of macOS include Python or can
      install it through Homebrew or the official Python installer.
      Verify the installed version using: ``python3 --version``. If a
      compatible version is not available, install one using Homebrew:
      ``brew install python`` or download the appropriate version directly
      from `python.org <https://www.python.org/downloads/>`__.

4. Specify Python installation location in MATLAB:

   -  Run ``pyenv('Version', 'pathtopython')``, where ``pathtopython`` is the path
      to where Python is installed. Here are some typical locations
      depending on your OS:

      -  **Windows**:
         ``C:\Users\Username\AppData\Local\Programs\Python\Python310\python.exe``,
         for version 3.10.
      -  **Linux**: ``/usr/bin/python3.10``, for version 3.10. Use
         ``whereis python3`` to find possible locations.
      -  **MacOS**: The Python executable is typically located using:
         ``which python3``. Common installation locations include:
         ``/usr/local/bin/python3`` and ``/opt/homebrew/bin/python3``.

5. Try creating an instance of CoolPropWrapper() in MATLAB:

   -  Run ``cp=CoolPropWrapper()``.

      -  If you are using the CoolPropWrapper as MATLAB Package in
         OpenSTREAM, use ``cp=CoolPropWrapper.CoolPropWrapper()``.

   -  If the CoolProp module is not installed, you will be prompted to
      do so automatically. If you prefer to do this manually, in your
      terminal, run ``python3 -m pip install --user -U CoolProp``,
      replacing ``python3`` with the specific python path as necessary.

Next steps
~~~~~~~~~~

Congrats! Hopefully, at this point, you have successfully made a copy of
this repo and installed the required programs. Next, let’s run the
sample script to make sure everything is working properly.