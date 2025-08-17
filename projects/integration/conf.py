"""Configuration file for the Sphinx documentation builder."""

import time

project = "Bazel Drives Sphinx: Integration"
author = "ubmarco"
release = "0.1"

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.viewcode",
    "sphinx_needs",
]

master_doc = "docs_generated/index"

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


def setup(app):

    def wait_on_build_finished(app, exception):
        """
        Wait after the build is finished to debug the Bazel sandbox.
        """
        print(f"{app.srcdir=} - {app.outdir=}")
        time.sleep(120)

    # app.connect("build-finished", wait_on_build_finished, priority=1000)
