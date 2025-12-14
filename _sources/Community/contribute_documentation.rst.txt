Contribute to the documentation
===============================

This documentation is made with `Sphinx <https://www.sphinx-doc.org/>`_ using the `Read the Docs <https://sphinx-rtd-theme.readthedocs.io/>`_ theme. 
The goal of this section is to help you implement a workflow for contributing to this documentation.

* Setup Sublime Text as text editor
* Configure Python to compile the documentation
  
The contents of this guide is partially taken from `here <https://sublime-and-sphinx-guide.readthedocs.io/en/latest/create_project.html>`_.

Setup Sublime Text as text editor
---------------------------------
Any text editor, such as Vi, Nano, Sublime Text, and Visual Studio Code, or integrated development environment(IDE) software, such as Visual Studio, can be used to write and manage the files needed to create this documentation. For convenience, Sublime Text will be used for this guide. 

#. Download and install `Sublime Text <https://www.sublimetext.com/download>`_.

#. Open Sublime Text.

#. Install `Package Control`. On the top menu bar, select `Tools > Command Palette`, or press `Ctrl+shift+p` (Win, Linux), `cmd+shift+p` (Mac). In the search bar that pops up, type `Install Package Control`. Select the matching item that is listed, or press `Enter`. The installation progress will be shown on the bottom left corner of the window. 

#. Package Control is driven by the Command Palette. To open the palette, press `ctrl+shift+p` (Win, Linux) or `cmd+shift+p` (Mac). All Package Control commands begin with Package Control:, so start by typing `Package`. Select `Install Package`, and install the following packages:

   * `RestructuredText Improved`: syntax highlighting
   * `OmniMarkupPreviewer`: preview RST in a web browser
   * `Sublime RST Completion`: convenient group of snippets and commands to facilitate writing restructuredText with SublimeText


Configure Python and Sphinx
---------------------------

You need Python and Sphinx (a Python package) to build this documentation.

Setup Python
************

To build your document in HTML (or other formats) on your computer, you must
install Sphinx.

See `Sphinx Overview <http://www.sphinx-doc.org/en/stable/>`_ for background reading. Then follow the steps below.

#. If you are using Windows, you might need to `Install Python <https://www.python.org/downloads/>`_.

   Depending on your Windows setup, after installation you might need to manually add the Python directory to your path. Try the `Python Windows Install <https://www.youtube.com/watch?v=L5t5U0XnSew>`_ for help.

   If you are using a Mac, it's probably installed.

#. `Install PIP <https://pip.pypa.io/en/stable/installation/>`_.

   Depending on your Windows setup, after installation you might need to manually add the PIP directory to your path.

#. Install `virtualenv`
   
   It is generally a good idea to use a `Virtual environment` to contain all the required dependencies of the project. This way, different versions of the same Python package can be used for each project contained within their respective `Virtual environment`. On the command line, enter::

   $ pip install virtualenv

   On Windows, `virtualenv.exe` will likely now be found in your python installation directory under the Scripts subdirectory.

#. Create a Virtual Python Environment
   
   `cd` to the `docs` folder::

   $ cd C:\Path\to\openstream\docs

   Use the `virtualenv` command to create a virtual environment directory called `venv`::

   $ virtualenv venv

.. note:: A `.gitignore` file should be automatically added to the `venv` folder. This way everything within it should be ignored by Git later on. 

#. Activate the Environment
   
   Now that we have a virtual environment, we need to activate it.::

   $ source .\.venv\Scripts\activate

   After you activate the environment, your command prompt will be modified to reflect the change.

Install Sphinx and dependencies
*******************************

Use PIP to install Sphinx and dependencies. On the command line, enter::

   $ pip install -r ./source/requirements.txt

This process may take a minute.

.. note:: If you are using Windows, this might be a frustrating task. If you get stuck, share the error messages and ask for help.

Start writing
-------------

This documentation is written in reStructuredText and compiled using Sphinx, both of which offers extensive options and customizabilities that can be difficult to master quickly. reStructuredText is similar to Markdown, which is the format used for GitHub `README.md` files. It is recommended that you go through `this quick tutorial <https://sphinx-tutorial.readthedocs.io/step-1/>`_ to familiarize yourself with the syntax. Sphinx-doc also offers a `great tutorial <https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html#rst-primer>`_. Some useful cheatsheets can be found `here <https://sphinx-tutorial.readthedocs.io/cheatsheet/>`_.

Build the documentation
-----------------------

This section assumes you are using the `build` function of Sublime Text to build the documentation. 

Quick preview
*************

For a quick preview of the document you are currently working on, use `ctrl+alt+o`(Win/Linux) or `cmd+opt+o`(Mac). Alternatively, open the `Command Palette` and select `OmniMarkupPreviewer: Preview Current Markup in Browser`. This functionality requires the `OmniMarkupPreviewer` package mentioned in :ref:`Setup Sublime Text as text editor`, and does not use `Sphinx`. 

Full build
**********
For a full build of the project, `Sphinx` needs to be called. More specifically, `sphinx-build` is the program that is run.

----

As to why this combination of schemes are used to create this documentation, here's an excerpt from the Sphinx website:

.. epigraph::

	Sphinx makes it easy to create intelligent and beautiful documentation.

	Here are some of Sphinx’s major features:

	* Output formats: HTML (including Windows HTML Help), LaTeX (for printable PDF versions), ePub, Texinfo, manual pages, plain text
	* Extensive cross-references: semantic markup and automatic links for functions, classes, citations, glossary terms and similar pieces of information
	* Hierarchical structure: easy definition of a document tree, with automatic links to siblings, parents and children
	* Automatic indices: general index as well as a language-specific module indices
	* Code handling: automatic highlighting using the Pygments highlighter
	* Extensions: automatic testing of code snippets, inclusion of docstrings from Python modules (API docs) via built-in extensions, and much more functionality via third-party extensions.
	* Themes: modify the look and feel of outputs via creating themes, and reuse many third-party themes.
	* Contributed extensions: dozens of extensions contributed by users; most of them installable from PyPI.

	Sphinx uses the reStructuredText markup language by default, and can read MyST markdown via third-party extensions. Both of these are powerful and straightforward to use, and have functionality for complex documentation and publishing workflows. They both build upon Docutils to parse and write documents.
