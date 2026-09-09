Contribute to the documentation
===============================

The OpenSTREAM documentation is created using
`Sphinx <https://www.sphinx-doc.org/>`_ with the
`Read the Docs theme <https://sphinx-rtd-theme.readthedocs.io/>`_.

This guide explains how to prepare a local documentation environment,
write and review reStructuredText content, build the documentation, and
submit documentation changes.

Any suitable text editor or integrated development environment can be
used. This guide includes optional instructions for configuring Sublime
Text, but contributors may instead use Visual Studio Code, Vi, Nano, or
another preferred editor.

Parts of the editor setup guidance are based on the
`Sublime Text and Sphinx guide
<https://sublime-and-sphinx-guide.readthedocs.io/en/latest/create_project.html>`_.

.. _setup-sublime-text-as-text-editor:

Set up Sublime Text as a text editor
------------------------------------

Any text editor, such as Vi, Nano, Sublime Text, or Visual Studio Code, or
integrated development environment can be used to write and manage the
documentation source files.

For convenience, Sublime Text is used in this section.

#. Download and install
   `Sublime Text <https://www.sublimetext.com/download>`_.

#. Open Sublime Text.

#. Install Package Control.

   On the top menu bar, select **Tools > Command Palette**, or press
   ``Ctrl+Shift+P`` on Windows or Linux, or ``Cmd+Shift+P`` on macOS.

   Enter ``Install Package Control`` and select the matching command.

#. Open the Command Palette again and select
   **Package Control: Install Package**.

#. Install the following packages, when useful:

   - ``RestructuredText Improved`` for syntax highlighting.
   - ``OmniMarkupPreviewer`` for quick browser previews.
   - ``Sublime RST Completion`` for reStructuredText snippets and
     completion.

A quick editor preview can be useful while writing, but it does not replace
a complete Sphinx build. Sphinx directives, cross-references, citations,
generated API documentation, and the complete navigation structure must be
reviewed using the actual documentation build.

Configure Python and Sphinx
---------------------------

Python and the required Sphinx packages must be installed before building
the documentation locally.

Set up Python
~~~~~~~~~~~~~

Install a supported Python version from the
`official Python website <https://www.python.org/downloads/>`_.

Depending on the operating system and installation method, the Python
installation directory and its ``Scripts`` directory may need to be added
to the system path.

Verify the installation:

.. code-block:: bash

   python --version
   python -m pip --version

Use ``python3`` instead of ``python`` if required by the local operating
system or Python installation.

Create a virtual environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A virtual environment isolates the documentation dependencies from other
Python projects.

Change to the OpenSTREAM ``docs`` folder:

.. code-block:: bash

   cd <path-to-openstream>/docs

Create a virtual environment named ``.venv``:

.. code-block:: bash

   python -m venv .venv

The ``.venv`` directory is local generated content and must not be
committed.

Activate the environment
~~~~~~~~~~~~~~~~~~~~~~~~

On Windows Command Prompt:

.. code-block:: bat

   .venv\Scripts\activate

On Windows PowerShell:

.. code-block:: powershell

   .\.venv\Scripts\Activate.ps1

On Git Bash, Linux, or macOS:

.. code-block:: bash

   source .venv/Scripts/activate

On Linux or macOS, the activation path may instead be:

.. code-block:: bash

   source .venv/bin/activate

After activation, the command prompt normally indicates that the virtual
environment is active.

Install Sphinx and dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install the documentation dependencies from the requirements file:

.. code-block:: bash

   python -m pip install --upgrade pip
   python -m pip install -r source/requirements.txt

The requirements file should contain the Sphinx version and extensions
needed to reproduce the documentation build.

If installation fails, retain the complete error message and record:

- The operating system.
- The Python version.
- The pip version.
- The failing package and version.
- The command used to install the requirements.

Start writing
-------------

The documentation is written in reStructuredText and compiled using
Sphinx.

Useful references include:

- The
  `Sphinx reStructuredText primer
  <https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html>`_.
- The
  `Sphinx tutorial <https://sphinx-tutorial.readthedocs.io/step-1/>`_.
- The
  `reStructuredText cheat sheet
  <https://sphinx-tutorial.readthedocs.io/cheatsheet/>`_.

Documentation source files should use the established OpenSTREAM structure,
terminology, and formatting conventions.

Writing guidelines
------------------

Use clear, concise technical language. Documentation should distinguish
among:

- Implemented software capability.
- Theoretical assumptions.
- Numerical behavior.
- Verification evidence.
- Experimental validation.
- Known limitations.
- Recommended user practice.

Avoid statements that imply broader validation or applicability than is
supported by the available evidence.

Terminology
~~~~~~~~~~~

Use terminology consistently across theory pages, tutorials, package
references, application projects, and publications.

In particular, distinguish between:

- OpenSTREAM and OpenSTREAM-database.
- A physical model and the solver implementing that model.
- The mixture model and the ``Mixture`` solver.
- The two-fluid model and the ``TwoFluid`` solver.
- The three-field model and the ``ThreeField`` solver.
- The four-field model and the ``FourField`` solver.
- Pointwise convergence, pseudo-time convergence, and physical-time
  advancement.
- Direct experimental measurements, derived quantities, and calculated
  quantities.
- Boiling transition, critical heat flux, dryout, and film depletion.
- Thermal nonequilibrium and hydrodynamic nonequilibrium.

Use lowercase descriptive forms when discussing physical formulations and
code-style names when referring to specific software interfaces.

Units
~~~~~

Use SI units throughout the documentation unless original units are
required to explain an experimental source or conversion.

Absolute temperatures must be expressed in kelvin in OpenSTREAM inputs and
stored results.

When original experimental units are presented, state the corresponding SI
representation and document the conversion.

Code examples
~~~~~~~~~~~~~

Code examples should:

- Reflect the current public interface.
- Use clear and descriptive variable names.
- Avoid hard-coded local paths.
- Use ``fullfile`` for constructed file-system paths.
- Include only the options relevant to the example.
- Use comments above logical sections.
- State any nondefault physical or numerical settings.
- Identify required working-directory or MATLAB-path assumptions.
- Avoid including generated session paths from an individual computer.

MATLAB code blocks should use:

.. code-block:: rst

   .. code-block:: matlab

      inputSet = Inputs.InputSet(...);

Shell commands should use:

.. code-block:: rst

   .. code-block:: bash

      git status

Links
~~~~~

Use standard reStructuredText links:

.. code-block:: rst

   `OpenSTREAM repository
   <https://github.com/OpenSTREAM-solvers/openstream>`_

Do not paste HTML elements such as ``<a href=...>`` into reStructuredText
files.

Prefer internal Sphinx cross-references for pages within the documentation:

.. code-block:: rst

   :doc:`getting-started guide <../Usage/gettingStarted>`

Use descriptive link text rather than displaying a long URL.

Headings
~~~~~~~~

Use a consistent heading hierarchy within each file.

A typical hierarchy is:

.. code-block:: rst

   Page title
   ==========

   Main section
   ------------

   Subsection
   ~~~~~~~~~~

   Lower-level section
   ^^^^^^^^^^^^^^^^^^^

The underline must be at least as long as the heading text.

Avoid adding unnecessary intermediate headings when the main topics can be
represented directly as page sections.

Lists and directives
~~~~~~~~~~~~~~~~~~~~

Leave a blank line before and after lists, code blocks, directives, tables,
and other block-level elements.

Indent directive content consistently. For example:

.. code-block:: rst

   .. note::

      This text belongs to the note directive.

For list tables:

.. code-block:: rst

   .. list-table::
      :header-rows: 1
      :widths: 30 70

      * - Column one
        - Column two
      * - Value one
        - Value two

Cross-references and navigation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When adding a new page:

#. Add the source file under the appropriate documentation folder.
#. Add the page to the relevant ``toctree``.
#. Add cross-references from related pages where useful.
#. Confirm that the page appears at the intended navigation level.
#. Confirm that the page title and navigation label are appropriate.
#. Avoid duplicating substantial guidance already maintained elsewhere.

Use one authoritative location for detailed guidance and link to it from
related pages.

Citations and bibliographies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the configured BibTeX file and Sphinx citation roles for publications.

An inline citation can use:

.. code-block:: rst

   :cite:p:`CitationKey`

To display a specific full reference in a page:

.. code-block:: rst

   .. bibliography::
      :filter: False

      CitationKey

Confirm that:

- The citation key exists in the configured BibTeX file.
- The bibliography is rendered correctly.
- Duplicate citation warnings are understood and resolved.
- The bibliographic information matches the authoritative publication.
- Publication links are valid.

Images and figures
~~~~~~~~~~~~~~~~~~

Images should:

- Contribute directly to the explanation.
- Be legible at the rendered page width.
- Include meaningful alternative text where supported.
- Use descriptive filenames.
- Be stored in the appropriate static-image folder.
- Have documented origin and reuse permission.
- Avoid including confidential, proprietary, or copyrighted material
  without permission.

Figure captions should identify the quantities, conditions, relevant model
configuration, and source where appropriate.

Generated figures included in the documentation should be reproducible
from a maintained script, tutorial, test, or project workflow whenever
practical.

Build the documentation
-----------------------

A quick editor preview is useful for basic reStructuredText formatting, but
a complete Sphinx build is required before submitting a documentation
change.

Quick preview
~~~~~~~~~~~~~

When using Sublime Text with OmniMarkupPreviewer, preview the current
document using ``Ctrl+Alt+O`` on Windows or Linux, or ``Cmd+Option+O`` on
macOS.

Alternatively, open the Command Palette and select
**OmniMarkupPreviewer: Preview Current Markup in Browser**.

This preview does not process the complete Sphinx configuration,
``toctree`` entries, API references, citations, or all Sphinx directives.

Full HTML build
~~~~~~~~~~~~~~~

Build the complete HTML documentation using the repository's established
Sphinx build command.

When invoking ``sphinx-build`` directly, the general command structure is:

.. code-block:: bash

   sphinx-build -b html source build/html

Review the actual source and output paths configured by the repository
before running the command.

A clean build is useful after adding, renaming, or removing pages:

.. code-block:: bash

   sphinx-build -E -a -b html source build/html

The ``-E`` option rebuilds the Sphinx environment, and ``-a`` writes all
output files.

Open the generated HTML entry page in a browser and review the affected
pages in the complete site context.

PDF build
~~~~~~~~~

When a change affects content included in the printable documentation,
build and review the PDF documentation using the repository's established
PDF build procedure.

The PDF build can expose issues not visible in HTML, including:

- Overwide tables.
- Long code lines.
- Poor page breaks.
- Misplaced figures.
- Citation or bibliography placement.
- Heading and navigation inconsistencies.
- Unsupported interactive content.

A successful HTML build does not guarantee a successful or readable PDF
build.

Warnings
~~~~~~~~

Review all Sphinx warnings.

Do not ignore a warning solely because the generated page appears
acceptable. Warnings can indicate:

- Broken cross-references.
- Duplicate labels.
- Missing files.
- Missing citations.
- Invalid directives.
- Documents not included in a ``toctree``.
- Malformed tables.
- Inconsistent indentation.
- Unsupported markup.

If an existing warning is unrelated to the contribution, confirm that the
change does not introduce additional warnings and document the existing
condition in the pull request when relevant.

Documentation-maintenance checklist
-----------------------------------

Use the following checklist when adding or revising OpenSTREAM
documentation.

Source review
~~~~~~~~~~~~~

- Confirm that the change is made in the authoritative source file.
- Confirm that generated HTML, LaTeX, or PDF files are not edited directly.
- Review related pages for duplicated, conflicting, or outdated
  information.
- Use one authoritative location for detailed guidance and add
  cross-references elsewhere.
- Confirm that terminology and capitalization match the current
  OpenSTREAM conventions.
- Confirm that solver, model, property, method, and option names match the
  current source code.
- Confirm that filenames, folder names, and repository paths are current.
- Remove copied interface markup, malformed links, and obsolete comments.

Technical accuracy
~~~~~~~~~~~~~~~~~~

- Confirm that capability statements match the current implementation.
- Distinguish software capability from verification and validation.
- State assumptions and limitations where they affect interpretation.
- Confirm that physical-model descriptions match the corresponding theory
  and implementation.
- Confirm that default and nondefault settings are identified correctly.
- Confirm that units are correct and consistently expressed.
- Use kelvin for absolute temperatures.
- Distinguish direct measurements, derived quantities, and calculated
  quantities.
- Avoid implying general validation from a limited set of comparisons.
- Confirm that publication companion workflows are not presented as
  complete records of the underlying research activities.

Code and command review
~~~~~~~~~~~~~~~~~~~~~~~

- Confirm that MATLAB examples follow the current public interface.
- Confirm that command-line examples use valid syntax.
- Confirm that paths are portable and do not identify a local computer or
  network location.
- Use ``fullfile`` in MATLAB path-construction examples.
- Avoid unreviewed ``git add .`` examples.
- Confirm that generated outputs, session directories, and local sandbox
  files are not presented as maintained repository content.
- Run representative examples when practical.
- Confirm that example output is consistent with the documented command.

Structure and navigation
~~~~~~~~~~~~~~~~~~~~~~~~

- Confirm that heading levels are consistent.
- Confirm that heading underlines are long enough.
- Confirm that new pages are included in the correct ``toctree``.
- Confirm that renamed or moved pages have updated cross-references.
- Confirm that navigation labels are concise and unambiguous.
- Check that no page is unintentionally orphaned.
- Confirm that internal ``:doc:`` and ``:ref:`` links resolve.
- Confirm that page titles are consistent with existing navigation and do
  not change unnecessarily.

Links and citations
~~~~~~~~~~~~~~~~~~~

- Check all added or modified external links.
- Use standard reStructuredText links rather than embedded HTML.
- Confirm that internal links use appropriate Sphinx cross-references.
- Confirm that BibTeX keys exist.
- Confirm that citations render in both HTML and PDF where applicable.
- Review duplicate-citation and duplicate-label warnings.
- Confirm that bibliographic details match the authoritative source.
- Confirm that publication PDFs and other copyrighted materials are linked
  or cited appropriately and are not redistributed without permission.

Figures and tables
~~~~~~~~~~~~~~~~~~

- Confirm that figures are legible in the HTML build.
- Confirm that figures are legible and correctly placed in the PDF build.
- Check figure captions, labels, units, and source attribution.
- Confirm that generated figures can be reproduced from a maintained
  workflow where practical.
- Check that tables fit within the rendered page width.
- Review list-table column widths in both HTML and PDF.
- Confirm that long code lines and equations do not extend beyond the
  printable page.
- Confirm that static exports do not imply preservation of unsupported
  interactive behavior.

HTML review
~~~~~~~~~~~

- Build the complete HTML documentation.
- Review all modified pages in a browser.
- Check the navigation hierarchy and previous or next page links.
- Check headings, lists, notes, tables, code blocks, figures, and
  citations.
- Review pages at a narrow browser width for avoidable layout problems.
- Confirm that external links open the intended destination.
- Confirm that code can be copied without interface-generated markup.
- Confirm that no local file paths or temporary build information appear
  in the rendered pages.

PDF review
~~~~~~~~~~

- Build the complete PDF documentation when the changed content is
  included in the printable version.
- Review the table of contents and section hierarchy.
- Check page breaks, table widths, figure placement, and code wrapping.
- Confirm that citations and bibliography entries are present.
- Confirm that links and cross-references are understandable in print.
- Confirm that interactive-only content is described appropriately.
- Check that no blank or nearly blank pages are introduced unnecessarily.

Build diagnostics
~~~~~~~~~~~~~~~~~

- Review the complete Sphinx output.
- Resolve warnings introduced by the change.
- Confirm that the build does not rely on untracked or ignored local
  files.
- Perform a clean build after adding, renaming, or deleting pages.
- Confirm that generated API documentation remains synchronized with the
  source code.
- Confirm that the documentation build works from a clean repository
  checkout when practical.

Final repository review
~~~~~~~~~~~~~~~~~~~~~~~

- Review ``git status`` before committing.
- Review the staged diff.
- Confirm that only intended source files are staged.
- Confirm that generated build directories are not staged.
- Confirm that the local virtual environment is not staged.
- Confirm that temporary files, editor backups, and MATLAB autosave files
  are not staged.
- Confirm that source PDFs or copyrighted publications are not included
  unintentionally.
- Organize documentation and unrelated functional changes into focused
  commits where practical.
- Follow the
  `OpenSTREAM commit message style guide
  <https://github.com/OpenSTREAM-solvers/openstream/wiki>`_.

Submitting documentation changes
--------------------------------

Documentation contributions follow the same fork, branch, commit, and pull
request workflow as code contributions.

Before committing:

.. code-block:: bash

   git status
   git diff
   git diff --cached

Stage only the intended source files:

.. code-block:: bash

   git add <documentation-files>

Commit messages must follow the
`OpenSTREAM commit message style guide
<https://github.com/OpenSTREAM-solvers/openstream/wiki>`_.

The pull-request description should identify:

- The purpose of the documentation change.
- The pages added, removed, or revised.
- Related code, interface, solver, model, or workflow changes.
- The HTML and PDF builds performed.
- Sphinx warnings introduced or resolved.
- Links, citations, tutorials, or examples reviewed.
- Any remaining documentation limitations or follow-up work.

Documentation-only changes should normally use the ``docs`` commit type as
described in the OpenSTREAM commit-message guidance.

Continuous integration
----------------------

The documentation build can be executed automatically when changes are
pushed to the repository.

After pushing a documentation change:

#. Open the corresponding GitHub Actions run.
#. Confirm that the documentation workflow completes successfully.
#. Review the complete diagnostic output.
#. Correct warnings or errors introduced by the change.
#. Confirm that the deployed documentation corresponds to the intended
   branch and source revision.

The documentation build and MATLAB continuous-integration workflow are
separate. A successful documentation build does not indicate that the
MATLAB tests passed, and a successful MATLAB test run does not indicate
that the documentation built correctly.

When a contribution changes both code and documentation, review both
workflow results.

Reporting documentation issues
------------------------------

Use the
`OpenSTREAM issue tracker
<https://github.com/OpenSTREAM-solvers/openstream/issues>`_
to report documentation errors, outdated examples, missing explanations,
broken links, build failures, or navigation problems.

A documentation issue should include, where applicable:

- The page title and link.
- A description of the problem.
- The expected correction or clarification.
- The relevant OpenSTREAM version or commit.
- A screenshot or copied