# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'OpenSTREAM'
author = 'The OpenSTREAM Team'
import datetime
copyright = f'2024–{datetime.datetime.now().year}, The OpenSTREAM Team'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinxcontrib.matlab',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.viewcode',
    'sphinx.ext.intersphinx',
    'sphinx.ext.napoleon', 
    'sphinx_rtd_theme',
    'sphinx_copybutton',
    'sphinxcontrib.bibtex', 
    'sphinx_new_tab_link',
    'sphinx.ext.autosectionlabel'
]

autosectionlabel_prefix_document = True

numfig = True
numfig_format = {
    'figure': 'Figure %s',
    'table': 'Table %s',
    'code-block': 'Listing %s'
}

primary_domain = 'mat'

templates_path = ['_templates']
exclude_patterns = []

# -- BibTex configurations ---------------------------------------------------
bibtex_bibfiles = ['my_bib.bib']
bibtex_reference_style = 'author_year'

# -- MATLAB specific configurations ------------------------------------------

import os
this_dir = os.path.dirname(os.path.abspath(__file__))
matlab_src_dir = os.path.abspath(os.path.join(this_dir, '..', '..'))

matlab_short_links = False
matlab_auto_link = 'all'
matlab_show_property_default_value = True
matlab_class_signature = True
matlab_keep_private_members = True
autoclass_content = 'class'
autodoc_member_order = 'alphabetical'
autodoc_default_options = {
	'member-order': 'alphabetical'
}
toc_object_entries = True
toc_object_entries_show_parents = 'all'

autodoc_default_flags = ['members']
autosummary_generate = True

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

#html_theme = 'alabaster'
html_theme = "sphinx_rtd_theme"
html_static_path = ['_static']
html_css_files = [
    "custom.css",
]
html_logo = '_static/logo-transparent.png'
latex_logo = '_static/logo-transparent.png'
html_favicon = '_static/favicon.ico'
includehidden = True
html_theme_options = {
    "collapse_navigation": False,
    "includehidden": True,
}
html_context = {
    "display_github": True,
    "github_user": "OpenSTREAM-solvers",
    "github_repo": "openstream",
    "github_version": "main",
    "conf_py_path": "/docs/source/",
}

# -- Options for LaTex output ------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-latex-output
latex_engine = 'pdflatex'
#latex_toplevel_sectioning = 'section'
latex_documents = [('index_latex', f'{project}.tex', f"{project} Documentation", author, 'manual')]
latex_table_style = ['booktabs']

latex_elements = {
    'printindex': r'\def\twocolumn[#1]{#1}\printindex',
    'preamble': r'''
    \usepackage{xcolor}
    \definecolor{openstreamblue}{RGB}{63,66,161}      % primary  #3F42A1
    \definecolor{openstreamlight}{RGB}{120,123,200}   % lighter  ~ for subtitles/rules
    \definecolor{openstreampale}{RGB}{225,226,242}    % pale     ~ for background bands
    ''',
    'maketitle': r'''
    \begin{titlepage}
    \centering
    \makeatletter
    \vspace*{2cm}

    {\color{openstreamblue}\rule{\linewidth}{1.2pt}}\par
    \vspace{0.6cm}
    {\Huge\bfseries\color{openstreamblue} \@title \par}
    \vspace{0.4cm}
    {\large\itshape\color{openstreamlight} Open Solvers for Two-phase flow Research,\\
     Engineering Analysis and Modeling\par}
    \vspace{0.5cm}
    {\color{openstreamblue}\rule{\linewidth}{1.2pt}}\par

    \vspace{0.8cm}
    {\large \@date \par}

    \vfill

    \includegraphics[width=0.40\textwidth]{logo-transparent.png}\par
    \vspace{1cm}

    {\small\color{gray} \textcopyright\ 2024--\the\year\ The OpenSTREAM Team \\ Licensed under the MIT License \\ https://github.com/OpenSTREAM-solvers/openstream \par}
    \vspace{1cm}
    \makeatother
    \end{titlepage}
    \clearpage
    ''',
}
