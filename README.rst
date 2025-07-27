Let Bazel drive Sphinx
======================

This project demonstrates how to use Bazel to collect reStructuredText (RST) files from various components
and generate a Sphinx documentation project.

That enables modular requirement tracing with `Sphinx-Needs <https://sphinx-needs.readthedocs.io>`__ in
large scale build setups in which Bazel decides about the inclusion or exclusion of components to the overall build.
Bazel effectively replaces the build system part of Sphinx.

Goals

- Bazel decides which single RSTs or groups of RSTs to build
- Bazel ``build`` targets are used for isolation (instead of ``run`` targets)
- Sphinx is used to generate the documentation from the collected RST files
- The collected RST files do not contain ``.. toctree::`` directives as those are provided by a rule programmatically.
  While users could do that, there is a danger that Bazel decides to exclude toctree RST files so Sphinx will complain.
- Sphinx will run the build and safely complain if there are missing files or references.
- Sphinx-Needs is used and works in the setup.
- The new schema validation feature of Sphinx-Needs is used to ensure that the documentation schema is valid.
- Dedicated Bazel goal for a fast schema validation with Sphinx-Needs based on the new ``schema`` builder.
- The original file structure of RSTs is kept, so that the docname variable is not affected.
  This is helpful when needs schema validation is done based on the contained folder structure.
- The needs.json file is generated along the Sphinx output for each builder.

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
It will get the correct version of Bazel.

You can then build the documentation by running the appropriate Bazel commands.

Project Structure
-----------------

The project is organized to demonstrate modular documentation management with Bazel::

  bazel-drives-sphinx/
  ├── MODULE.bazel                    # Bazel module configuration
  ├── BUILD.bazel                     # Root build file
  ├── README.rst                      # This file
  ├── docs/                           # Documentation source components
  │   └── components/                 # Modular documentation components
  │       ├── BUILD.bazel             # Aggregation of component groups
  │       ├── api/                    # API documentation
  │       │   ├── BUILD.bazel         # API docs filegroup
  │       │   ├── endpoints/
  │       │   │   └── endpoints.rst
  │       │   └── responses.rst
  │       ├── auth/                   # Authentication documentation
  │       │   ├── BUILD.bazel         # Auth docs filegroup
  │       │   ├── authentication.rst
  │       │   └── authorization.rst
  │       └── schema_fail/            # Example with validation errors
  │           ├── BUILD.bazel
  │           └── index.rst
  └── tools/                          # Build tooling
      ├── generate_project/           # Sphinx project generation
      │   ├── BUILD.bazel             # Generator targets with config_setting
      │   ├── generate.bzl            # Custom Bazel rule
      │   ├── generate_project.py     # Python script for project assembly
      │   ├── conf.py                 # Sphinx configuration template
      │   ├── index.rst.template      # Index template with toctree placeholder
      │   ├── schemas.json            # Sphinx-Needs schema definitions
      │   └── ubproject.toml          # Project-specific Sphinx-Needs config
      └── sphinx/                     # Sphinx build configuration
          ├── BUILD.bazel             # sphinx_docs targets for HTML and schema
          ├── requirements.in         # Python dependencies specification
          └── requirements.txt        # Locked Python dependencies

**Key Components:**

- **Component Selection**: ``docs/components/BUILD.bazel`` defines filegroups for different documentation sets
  (``all``, ``api``, ``auth``, ``minimal``, ``schema_fail``)
- **Dynamic Generation**: ``tools/generate_project/generate_project.py`` script collects selected RST files and
  generates a complete Sphinx project structure with proper toctree directives
- **Build Variants**: ``tools/generate_project/BUILD.bazel`` uses ``config_setting`` and ``select()``
  to switch between documentation sets based on command-line flags
- **Sphinx Integration**: ``tools/sphinx/BUILD.bazel`` contains ``sphinx_docs`` rules that process the generated
  project structure with both HTML and schema validation builders
- **Modular Dependencies**: Each component in ``docs/components/`` has its own BUILD file, allowing Bazel to
  track dependencies and only rebuild what's necessary

This structure enables selective documentation builds where Bazel determines which components to include, while Sphinx handles the actual documentation generation with full markup, validation and cross-referencing capabilities.

Building Documentation
----------------------

For the repo root, build the documentation of all components with::

  bazelisk build //tools/sphinx:docs_html

Make it explicit to build all (above command uses the default value ``docs_group=all``)::

  bazelisk build //tools/sphinx:docs_html --define=docs_group=all

Only build the docs for the ``api`` component::

  bazelisk build //tools/sphinx:docs_html --define=docs_group=api

Only build the docs for the ``auth`` component::

  bazelisk build //tools/sphinx:docs_html --define=docs_group=auth

Only build the docs for one file of the ``api`` component::

  bazelisk build //tools/sphinx:docs_html --define=docs_group=minimal

To see the schema validation fail for network links while also building the HTML::

  bazelisk build //tools/sphinx:docs_html --define=docs_group=schema_fail

To see the schema validation fail for network links without emitting HTML (much faster)::

  bazelisk build //tools/sphinx:docs_schema --define=docs_group=schema_fail

Observe how the build fails for the last one as a headline reference is missing.
Sphinx runs with ``-W`` which makes the build fail on each warning.

Updating dependencies
---------------------

1. Modify tools/sphinx/requirements.in
2. Run ``bazel run //tools/sphinx:requirements.update``
