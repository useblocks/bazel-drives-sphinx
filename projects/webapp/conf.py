"""Configuration file for the Sphinx documentation builder."""

project = "Bazel Drives Sphinx: Web-App Project"
author = "ubmarco"
release = "0.1"

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.viewcode",
    "sphinx_needs",
]

templates_path = ["_templates"]
exclude_patterns = []

html_theme = "furo"
# html_static_path = ["_static"]

needs_build_json = True

needs_from_toml = "ubproject.toml"
needs_schema_definitions_from_json = "schemas.json"

suppress_warnings = [
    "needs.beta",
]
