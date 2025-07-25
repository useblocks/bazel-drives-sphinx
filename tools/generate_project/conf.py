"""Configuration file for the Sphinx documentation builder."""

project = "Bazel Drives Sphinx Demo"
author = "ubmarco"
release = "0.1"

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.viewcode",
    "sphinx_needs",
]

master_doc = "src/index"

templates_path = ["_templates"]
exclude_patterns = []

html_theme = "furo"
# html_static_path = ["_static"]

needs_build_json = True

needs_from_toml = 'src/ubproject.toml'
needs_schema_definitions_from_json = 'src/schemas.json'

suppress_warnings = [
    "needs.beta",
]
