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

# -- Options for LaTex output ------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-latex-output
latex_engine = 'pdflatex'
#latex_toplevel_sectioning = 'section'
latex_documents = [('index_latex', f'{project}.tex', f"{project} Documentation", author, 'manual')]
latex_table_style = ['booktabs']

latex_elements = {
    'printindex': r'\def\twocolumn[#1]{#1}\printindex',
    'maketitle': r'''
    \begin{titlepage}
    \centering
    \makeatletter
    \vspace*{3cm}
    {\Huge\bfseries \@title \par}
    \vspace{1.5cm}
    {\Large \py@authoraddress \par}
    \vspace{0.5cm}
    {\large \@author \par}
    \vspace{0.5cm}
    {\large \@date \par}
    \vfill
    \includegraphics[width=0.35\textwidth]{logo-transparent.png}
    \vspace{2cm}
    \makeatother
    \end{titlepage}
    \clearpage
    ''',
}