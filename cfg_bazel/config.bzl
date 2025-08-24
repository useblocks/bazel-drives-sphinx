"""Generate component-specific config_settings and file selections."""

load("@rules_python//sphinxdocs:sphinx.bzl", "sphinx_docs")
load("//tools/sphinx/dynamic_needextends:generate.bzl", "generate_needextends_structure")
load("//tools/sphinx/dynamic_needimports:generate.bzl", "generate_needimports_structure")

def generate_sphinx_docs(name, targets = {}, needs_json_labels = [], needextends_labels = []):
    """
    Generate sphinx_docs targets for a project.

    Generates targets based on the targets dictionary keys:
    For each key in targets, creates:
    - docs_html_{key}: HTML documentation
    - docs_needs_{key}: needs.json generation
    - docs_schema_{key}: schema validation

    Args:
        name: rule invocation name - unused
        targets: dictionary with keys as target suffixes and values as lists of file targets
                Example: {'all': ["//path:docs_all"], 'trace': ["//path:docs_trace"]}
        needs_json_labels: list of labels for needs.json files to generate needimports directives
        needextends_labels: list of labels for needextends.rst files to generate needextend directives
    """

    # Generate needimports directory for needs.json files

    if needs_json_labels:
        generate_needimports_structure(
            name = "generate_needimports",
            title = "Need imports",
            needs_json_labels = needs_json_labels,
        )
    else:
        # Create empty filegroup when no needs_json_labels are provided
        native.filegroup(
            name = "generate_needimports",
            srcs = [],
            visibility = ["//visibility:public"],
        )

    # Generate needimports directory for needs.json files
    if needextends_labels:
        generate_needextends_structure(
            name = "generate_needextends",
            title = "# CodeLinks",
            needextends_labels = needextends_labels,
        )
    else:
        # Create empty filegroup when no needs_json_labels are provided
        native.filegroup(
            name = "generate_needextends",
            srcs = [],
            visibility = ["//visibility:public"],
        )

    # Common configuration
    base_srcs = [
        "ubproject.toml",
        "schemas.json",
        "index.rst",  # Project's main index.rst with toctree :glob: **/index
    ]

    common_opts = [
        "-W",
        "--keep-going",
        "-d",
        "doctrees-throw-away",  # no incremental build, don't store those in the output
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

    # Generate targets for each key in the targets dictionary
    for target_key, file_targets in targets.items():
        target_srcs = base_srcs + file_targets + [":generate_needimports", ":generate_needextends"]

        # HTML targets
        sphinx_docs(
            name = "docs_html_" + target_key,
            srcs = target_srcs + needs_json_labels,
            formats = ["html"],
            **default_fields
        )

        # Schema validation targets
        sphinx_docs(
            name = "docs_schema_" + target_key,
            srcs = target_srcs + needs_json_labels,
            formats = ["schema"],
            **default_fields
        )

        # Needs.json generation targets
        sphinx_docs(
            name = "docs_needs_" + target_key,
            srcs = target_srcs + needs_json_labels,
            formats = ["needs"],
            **default_fields
        )
