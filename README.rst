Let Bazel drive Sphinx
======================

This project demonstrates how to use Bazel to collect reStructuredText (RST) files from various components
and generate a Sphinx documentation project with multi-project support and cross-project traceability.

That enables modular requirement tracing with `Sphinx-Needs <https://sphinx-needs.readthedocs.io>`__ in
large scale build setups in which Bazel decides about the inclusion or exclusion of components to the overall build.
Bazel effectively replaces the build system part of Sphinx.

Goals

- Bazel decides which single RSTs or groups of RSTs to build across multiple projects
- Bazel ``build`` targets are used for isolation (instead of ``run`` targets)
- Sphinx is used to generate the documentation from the collected RST files
- The collected RST files do not contain ``.. toctree::`` directives as those are provided by a rule programmatically.
  While users could do that, there is a danger that Bazel decides to exclude toctree RST files so Sphinx will complain.
- Sphinx will run the build and safely complain if there are missing files or references.
- Sphinx-Needs is used and works in the setup with cross-project traceability.
- The new schema validation feature of Sphinx-Needs is used to ensure that the documentation schema is valid.
- Dedicated Bazel goal for a fast schema validation with Sphinx-Needs based on the new ``schema`` builder.
- The original file structure of RSTs is kept, so that the docname variable is not affected.
  This is helpful when needs schema validation is done based on the contained folder structure.
- The needs.json file is generated along the Sphinx output for each builder and can be imported across projects.
- Cross-project need imports enable integration testing and overall system documentation.

The solution assumes a safe subset of Sphinx/Sphinx-Needs features are used (to be documented).
E.g. linking to a headline in a Bazel excluded file will naturally fail or linking to a need that is not included.
But these are all expected failures and Sphinx should be called with ``-W`` to fail on any warnings.
Sphinx can also be configured to suppress certain warning types that commonly appear in such a setup.

Behind the scenes
-----------------

Sphinx itself is a build system. It has some mechanism for the inclusion and exclusion of files, but the logic
is maintained in the Python file ``conf.py`` which does not integrate well with build systems.
Sphinx also requires all files to be part of the build root, which is not always the case in large projects.

The idea of this demo is to delegate the dependency management inside a Sphinx project to Bazel.
That includes the collection of RST files and other assets from different components,
which are organized in a Bazel workspace or Bazel module.
That way documentation and requirements can be selected the same way features are selected for code
components.
In this approach Bazel can also pass on tags to the Sphinx ``sphinx-build`` CLI which can be used for
variant management or other dynamic behavior in Sphinx-Needs.

The original file/folder structure of the docs sources is kept,
as it can affect the documentation generation process, e.g. because the docname is examined by Sphinx extensions.

Getting Started
---------------

To get started with this project, ensure you have `Bazelisk <https://github.com/bazelbuild/bazelisk>`__ installed.
It will get the correct version of Bazel. It also install a symlink ``bazel`` to the ``bazelisk`` binary which
can be used as a drop-in replacement for ``bazel``.

You can then build the documentation by running the appropriate Bazel commands.

Project Structure
-----------------

The project is organized to demonstrate modular documentation management with Bazel across multiple projects::

  bazel-drives-sphinx/
  ├── MODULE.bazel                    # Bazel module configuration
  ├── BUILD.bazel                     # Root build file
  ├── README.rst                      # This file
  ├── cfg_bazel/                      # Component configuration system
  │   ├── BUILD.bazel                 # Config generation rules
  │   └── config.bzl                  # Dynamic component selection logic
  ├── projects/                       # Multi-project structure
  │   ├── acdc/                       # ACDC project (AC/DC components)
  │   │   ├── BUILD.bazel             # Project build configuration
  │   │   ├── conf.py                 # Sphinx configuration
  │   │   ├── schemas.json            # Project-specific schema definitions
  │   │   ├── ubproject.toml          # Sphinx-Needs project configuration
  │   │   ├── ac/                     # AC component
  │   │   │   └── docs/               # AC documentation
  │   │   │       ├── BUILD.bazel     # Component docs filegroups
  │   │   │       └── lots_of_ac.rst
  │   │   └── dc/                     # DC component
  │   │       └── docs/               # DC documentation
  │   │           ├── BUILD.bazel     # Component docs filegroups
  │   │           └── lots_of_dc.rst
  │   ├── webapp/                     # Web application project
  │   │   ├── BUILD.bazel             # Project build configuration
  │   │   ├── conf.py                 # Sphinx configuration
  │   │   ├── schemas.json            # Project-specific schema definitions
  │   │   ├── ubproject.toml          # Sphinx-Needs project configuration
  │   │   ├── api/                    # API component
  │   │   │   └── docs/               # API documentation
  │   │   │       ├── BUILD.bazel     # Component docs filegroups
  │   │   │       ├── responses.rst
  │   │   │       └── endpoints/
  │   │   │           └── endpoints.rst
  │   │   ├── auth/                   # Authentication component
  │   │   │   └── docs/               # Auth documentation
  │   │   │       ├── BUILD.bazel     # Component docs filegroups
  │   │   │       ├── index.rst
  │   │   │       ├── intro.rst
  │   │   │       └── trace/          # Traceability artifacts
  │   │   │           ├── authentication.rst
  │   │   │           └── authorization.rst
  │   │   └── schema_fail/            # Example with validation errors
  │   │       └── docs/
  │   │           ├── BUILD.bazel
  │   │           └── index.rst
  │   └── integration/                # Integration project
  │       ├── BUILD.bazel             # Cross-project integration
  │       ├── conf.py                 # Sphinx configuration
  │       ├── schemas.json            # Integration schema definitions
  │       ├── ubproject.toml          # Sphinx-Needs project configuration
  │       └── overall/                # Overall integration component
  │           └── docs/
  │               ├── BUILD.bazel
  │               └── index.rst       # Cross-project needs tables
  └── tools/                          # Build tooling
      ├── sphinx/                     # Sphinx build configuration
      │   ├── BUILD.bazel             # Sphinx build binary and requirements
      │   ├── requirements.in         # Python dependencies specification
      │   ├── requirements.txt        # Locked Python dependencies
      │   └── dynamic_project/        # Dynamic Sphinx project generation
      │       ├── BUILD.bazel         # Generator targets
      │       ├── generate.bzl        # Custom Bazel rule for project generation
      │       ├── generator.py        # Python script for project assembly
      │       └── index.rst.template  # Index template with toctree and needimport placeholders
      └── generate_project/           # Legacy project generator
          ├── BUILD.bazel             # Legacy generator targets
          ├── generate.bzl            # Legacy custom Bazel rule
          └── generate_project.py     # Legacy Python script

**Key Components:**

- **Multi-Project Architecture**: Each project (``acdc``, ``webapp``, ``integration``) has its own Sphinx configuration,
  schema definitions, and component structure
- **Component Selection**: `cfg_bazel/config.bzl`_ provides dynamic component selection with
  ``--define`` flags for including/excluding components and trace-only builds
- **Dynamic Generation**: `tools/sphinx/dynamic_project/generator.py`_ script collects selected RST files and
  generates complete Sphinx project structures with proper toctree directives and needimport statements
- **Cross-Project Traceability**: The integration project demonstrates importing needs.json files from other projects
  using the ``needs_json_labels`` attribute in `tools/sphinx/dynamic_project/generate.bzl`_
- **Build Variants**: Each project supports multiple build formats (``docs_html``, ``docs_schema``, ``docs_needs``)
  for different validation and output requirements
- **Modular Dependencies**: Each component has separate ``docs_all`` and ``docs_trace`` filegroups, allowing
  selective inclusion of full documentation or trace-only artifacts
- **Schema Validation**: Project-specific `schemas.json`_ files define validation rules for Sphinx-Needs

**Needs.json Integration:**

The system supports cross-project need imports through a sophisticated mechanism:

1. **Generation**: Each project can generate a ``needs.json`` file using the ``docs_needs`` target (e.g., ``//projects/webapp:docs_needs``)
2. **Import**: Other projects can reference these needs.json files via the ``needs_json_labels`` attribute
3. **Template Integration**: The `index.rst.template`_ includes a ``{{ needimports }}`` placeholder
4. **Automatic Directives**: The generator automatically creates ``.. needimport::`` directives for cross-project traceability

This enables integration projects like `projects/integration`_ to import and display needs from multiple source projects,
creating comprehensive traceability matrices and cross-project validation.

This structure enables selective documentation builds where Bazel determines which components to include, while Sphinx handles the actual documentation generation with full markup, validation and cross-referencing capabilities across multiple projects.

Building Documentation
----------------------

**Single Project Builds:**

Build the ACDC project documentation::

  bazel build //projects/acdc:docs_html

Build the webapp project documentation::

  bazel build //projects/webapp:docs_html

Build the integration project (with cross-project imports)::

  bazel build //projects/integration:docs_html

**Component Selection:**

Use bit-mode to build only specific components within a project::

  # Build only the 'api' component from webapp
  bazel build //projects/webapp:docs_html --define=use_incl_bits=true --define=incl_webapp_api=true

  # Build only the 'ac' component from acdc
  bazel build //projects/acdc:docs_html --define=use_incl_bits=true --define=incl_acdc_ac=true

  # Build multiple components
  bazel build //projects/webapp:docs_html --define=use_incl_bits=true --define=incl_webapp_api=true --define=incl_webapp_auth=true

**Trace-Only Builds:**

Build only traceability artifacts (faster for validation)::

  bazel build //projects/webapp:docs_html --define=trace_only=true

**Schema Validation:**

Run fast schema validation without generating HTML::

  bazel build //projects/webapp:docs_schema
  bazel build //projects/acdc:docs_schema

**Needs.json Generation:**

Generate needs.json files for cross-project import::

  bazel build //projects/webapp:docs_needs
  bazel build //projects/acdc:docs_needs

**Legacy Component Selection (tools/generate_project):**

The legacy system still supports the original component selection mechanism::

  bazel build //tools/generate_project:generate --define=docs_group=api
  bazel build //tools/generate_project:generate --define=docs_group=auth
  bazel build //tools/generate_project:generate --define=docs_group=schema_fail

Observe how the build fails for schema_fail as validation errors are present.
Sphinx runs with ``-W`` which makes the build fail on each warning.

Updating dependencies
---------------------

1. Modify tools/sphinx/requirements.in
2. Run ``bazel run //tools/sphinx:requirements.update``

.. _cfg_bazel/config.bzl: cfg_bazel/config.bzl
.. _tools/sphinx/dynamic_project/generator.py: tools/sphinx/dynamic_project/generator.py
.. _tools/sphinx/dynamic_project/generate.bzl: tools/sphinx/dynamic_project/generate.bzl
.. _schemas.json: projects/webapp/schemas.json
.. _index.rst.template: tools/sphinx/dynamic_project/index.rst.template
.. _projects/integration: projects/integration/BUILD.bazel
