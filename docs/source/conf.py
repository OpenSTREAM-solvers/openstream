# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'OpenSTREAM'
author = 'The OpenSTREAM Team'
copyright = f'2025, {author}'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
		'sphinxcontrib.matlab', 'sphinx.ext.autodoc', 'sphinx.ext.napoleon', 
		'sphinx_rtd_theme', 'sphinx_copybutton', 'sphinxcontrib.bibtex', 
		'sphinx_new_tab_link', 'sphinx.ext.autosectionlabel'
		]
primary_domain = 'mat'

templates_path = ['_templates']
exclude_patterns = []

# -- BibTex configurations ---------------------------------------------------
bibtex_bibfiles = ['my_bib.bib']
bibtex_reference_style = 'author_year'

# -- MATLAB specific configurations ------------------------------------------

matlab_src_dir = '../..'
matlab_short_links = False
matlab_auto_link = 'all'
matlab_show_property_default_value = True
matlab_class_signature = True
autoclass_content = 'class'
autodoc_member_order = 'bysource'
autodoc_default_options = {
	'member-order': 'bysource'
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
html_logo = '_static/logo-transparent.png'
html_favicon = '_static/favicon.ico'
includehidden = True

# -- Options fpr LaTex output ------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-latex-output
latex_engine = 'pdflatex'
#latex_toplevel_sectioning = 'section'
latex_documents = [('index_latex', f'{project}.tex', f"{project} Manual", author, 'manual')]