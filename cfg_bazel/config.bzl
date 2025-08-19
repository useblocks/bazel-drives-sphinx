"""Generate component-specific config_settings and file selections."""

load("//tools/sphinx/dynamic_project:generate.bzl", "generate_sphinx_project")
load("@rules_python//sphinxdocs:sphinx.bzl", "sphinx_docs")

def generate_component_config(name, project, components):
    """
    Generate component specific config_settings and selectors.

    The function relies on the directory structure projects/<project>/<component>.
    It also relies on the existence of 2 file groups in each component:
    docs_trace and docs_all. docs_trace only contains need items and not much more.
    docs_all must contain all documentation for the component, including docs_trace.
    The goal is to split the traceability docs from all docs for a fast traceability
    validation (aka. ontology check or schema validation).

    Bazel --define options:

    - use_incl_bits=true: enable incl_<project>_<component> selection
      (if false or not given, all components are selected)
    - incl_<project>_<component>=true: an enable flag per component
    - trace_only=true: if true, only the file groups docs_trace are selected for fast
      traceability validations

    Args:
        name: rule invocation name - unused
        project: project name (e.g., 'myproject')
        components: List of component names (e.g., ['api', 'auth', 'schema_fail'])
    """

    # Switch to include trace-only files
    native.config_setting(
        name = "trace_only_true",
        define_values = {"trace_only": "true"},
    )

    # Enable bit-mode: only include components explicitly set via incl_* flags
    native.config_setting(
        name = "use_incl_bits_true",
        define_values = {"use_incl_bits": "true"},
    )

    # One config_setting per component bit: --define=incl_<project>_<component>=true
    for component in components:
        native.config_setting(
            name = "incl_%s_%s_true" % (project, component),
            define_values = {"incl_%s_%s" % (project, component): "true"},
        )

    # Default (no bit-mode): include all components
    default_all = ["//projects/%s/%s/docs:docs_all" % (project, c) for c in components]
    default_trace = ["//projects/%s/%s/docs:docs_trace" % (project, c) for c in components]

    # Bit-mode: include only components explicitly enabled
    bitmode_all = []
    bitmode_trace = []
    for c in components:
        bitmode_all += select({
            ":incl_%s_%s_true" % (project, c): ["//projects/%s/%s/docs:docs_all" % (project, c)],
            "//conditions:default": [],
        })
        bitmode_trace += select({
            ":incl_%s_%s_true" % (project, c): ["//projects/%s/%s/docs:docs_trace" % (project, c)],
            "//conditions:default": [],
        })

    native.filegroup(
        name = "bitmode_all_files",
        srcs = bitmode_all,
    )

    native.filegroup(
        name = "bitmode_trace_files",
        srcs = bitmode_trace,
    )

    native.filegroup(
        name = "component_all_files",
        srcs = select({
            ":use_incl_bits_true": [":bitmode_all_files"],
            "//conditions:default": default_all,
        }),
    )

    native.filegroup(
        name = "component_trace_files",
        srcs = select({
            ":use_incl_bits_true": [":bitmode_trace_files"],
            "//conditions:default": default_trace,
        }),
    )

    native.filegroup(
        name = "files",
        srcs = select({
            ":trace_only_true": [":component_trace_files"],
            "//conditions:default": [":component_all_files"],
        }),
        # visibility = ["//tools/sphinx/dynamic_project:__pkg__"],
    )

def generate_sphinx_docs(name, title):
    """
    Generate sphinx_docs targets for a project.
    
    Generates the following targets:
    - docs_html: HTML documentation (respects trace_only setting)
    - docs_html_trace: HTML documentation (trace-only files)
    - docs_needs: needs.json generation (respects trace_only setting)
    - docs_needs_trace: needs.json generation (trace-only files)
    - docs_schema: schema validation (respects trace_only setting)
    - docs_schema_trace: schema validation (trace-only files)
    
    Args:
        name: rule invocation name - unused
        title: project title for the generated Sphinx project
    """
    
    # Generate both regular and trace-only sphinx projects
    generate_sphinx_project(
        name = "generate_sphinx",
        title = title,
        all_docs = ":files",
        strip_prefix = native.package_name() + "/",
        generate_script = "//tools/sphinx/dynamic_project:generator",
        index_template = "//tools/sphinx/dynamic_project:index_template",
    )
    
    generate_sphinx_project(
        name = "generate_sphinx_trace",
        title = title + " (trace only)",
        all_docs = ":component_trace_files",
        strip_prefix = native.package_name() + "/",
        generate_script = "//tools/sphinx/dynamic_project:generator",
        index_template = "//tools/sphinx/dynamic_project:index_template",
    )
    
    # Common configuration
    base_srcs = [
        "ubproject.toml",
        "schemas.json",
    ]
    
    common_opts = [
        "-W",
        "--keep-going",
        "-d",
        "doctrees-throw-away",
    ]
    
    default_fields = {
        "config": "conf.py",
        "extra_opts": common_opts,
        "deps": [],
        "renamed_srcs": {},
        "sphinx": "//tools/sphinx:sphinx_build",
        "tags": [],
        "tools": ["//tools/sphinx:plantuml"],
        "visibility": ["//visibility:public"],
    }

    # HTML targets
    sphinx_docs(
        name = "docs_html",
        srcs = base_srcs + select({
            ":trace_only_true": [":generate_sphinx_trace"],
            "//conditions:default": [":files", "index.rst"],
        }),
        formats = ["html"],
        **default_fields,
    )
    
    sphinx_docs(
        name = "docs_html_trace",
        srcs = base_srcs + [":generate_sphinx_trace"],
        deps = [],
        renamed_srcs = {},
        config = "conf.py",
        extra_opts = common_opts + ["-D", "master_doc=docs_generated/index"],
        formats = ["html"],
        sphinx = "//tools/sphinx:sphinx_build",
        tags = [],
        tools = ["//tools/sphinx:plantuml"],
        visibility = ["//visibility:public"],
    )
    
    # Schema validation targets
    sphinx_docs(
        name = "docs_schema",
        srcs = base_srcs + select({
            ":trace_only_true": [":generate_sphinx_trace"],
            "//conditions:default": [":files", "index.rst"],
        }),
        deps = [],
        renamed_srcs = {},
        config = "conf.py",
        extra_opts = common_opts + select({
            ":trace_only_true": ["-D", "master_doc=docs_generated/index"],
            "//conditions:default": [],
        }),
        formats = ["schema"],
        sphinx = "//tools/sphinx:sphinx_build",
        tags = [],
        tools = ["//tools/sphinx:plantuml"],
        visibility = ["//visibility:public"],
    )
    
    sphinx_docs(
        name = "docs_schema_trace",
        srcs = base_srcs + [":generate_sphinx_trace"],
        deps = [],
        renamed_srcs = {},
        config = "conf.py",
        extra_opts = common_opts + ["-D", "master_doc=docs_generated/index"],
        formats = ["schema"],
        sphinx = "//tools/sphinx:sphinx_build",
        tags = [],
        tools = ["//tools/sphinx:plantuml"],
        visibility = ["//visibility:public"],
    )
    
    # Needs.json generation targets
    sphinx_docs(
        name = "docs_needs",
        srcs = base_srcs + select({
            ":trace_only_true": [":generate_sphinx_trace"],
            "//conditions:default": [":files", "index.rst"],
        }),
        deps = [],
        renamed_srcs = {},
        config = "conf.py",
        extra_opts = common_opts + select({
            ":trace_only_true": ["-D", "master_doc=docs_generated/index"],
            "//conditions:default": [],
        }),
        formats = ["needs"],
        sphinx = "//tools/sphinx:sphinx_build",
        tags = [],
        tools = ["//tools/sphinx:plantuml"],
        visibility = ["//visibility:public"],
    )
    
    sphinx_docs(
        name = "docs_needs_trace",
        srcs = base_srcs + [":generate_sphinx_trace"],
        deps = [],
        renamed_srcs = {},
        config = "conf.py",
        extra_opts = common_opts + ["-D", "master_doc=docs_generated/index"],
        formats = ["needs"],
        sphinx = "//tools/sphinx:sphinx_build",
        tags = [],
        tools = ["//tools/sphinx:plantuml"],
        visibility = ["//visibility:public"],
    )
