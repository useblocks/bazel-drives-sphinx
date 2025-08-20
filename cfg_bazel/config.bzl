"""Generate component-specific config_settings and file selections."""

load("//tools/sphinx/dynamic_needimports:generate.bzl", "generate_sphinx_project")
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

    Args:
        name: rule invocation name - unused
        project: project name (e.g., 'myproject')
        components: List of component names (e.g., ['api', 'auth', 'schema_fail'])
    """

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

    # Keep legacy 'files' target pointing to all files for backward compatibility
    native.filegroup(
        name = "files",
        srcs = [":component_all_files"],
    )

def generate_sphinx_docs(name, targets = {}, needs_json_labels = []):
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
        needs_json_labels: list of labels for needs.json files to generate needimports directory
    """
    
    # Generate needimports directory for needs.json files
    if needs_json_labels:
        generate_sphinx_project(
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
        target_srcs = base_srcs + file_targets + [":generate_needimports"]
        
        # HTML targets
        sphinx_docs(
            name = "docs_html_" + target_key,
            srcs = target_srcs + needs_json_labels,
            formats = ["html"],
            **default_fields,
        )
        
        # Schema validation targets
        sphinx_docs(
            name = "docs_schema_" + target_key,
            srcs = target_srcs,
            formats = ["schema"],
            **default_fields,
        )
        
        # Needs.json generation targets
        sphinx_docs(
            name = "docs_needs_" + target_key,
            srcs = target_srcs,
            formats = ["needs"],
            **default_fields,
        )

def generate_needimports_project(name, title, needs_json_labels = []):
    """Generate a needimports directory with index.rst containing needimport directives."""
    
    if needs_json_labels:
        native.genrule(
            name = name,
            srcs = needs_json_labels,
            outs = ["needimports/index.rst"],
            cmd = """
            mkdir -p $(RULEDIR)/needimports
            cat > $(RULEDIR)/needimports/index.rst << 'EOF'
{title}
{underline}

{needimports}
EOF
            """.format(
                title = title,
                underline = "=" * len(title),
                needimports = "\\n".join([
                    ".. needimport:: ../{}.json".format(label.replace(":", "/").replace("//", ""))
                    for label in needs_json_labels
                ])
            ),
            visibility = ["//visibility:public"],
        )
    else:
        # Create empty filegroup when no needs_json_labels are provided
        native.filegroup(
            name = name,
            srcs = [],
            visibility = ["//visibility:public"],
        )
