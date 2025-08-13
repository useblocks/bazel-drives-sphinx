"""Generate component-specific config_settings and file selections."""

def generate_component_config(name, components):
    """Generates:

      - use_incl_bits_true: enable bit-mode selection
      - incl_<component>_true: a bit per component
      - files: final selection (trace_only variant supported)

    Args:
        name: unused
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

    # One config_setting per component bit: --define=incl_<component>=true
    for component in components:
        native.config_setting(
            name = "incl_%s_true" % component,
            define_values = {"incl_%s" % component: "true"},
        )

    # Default (no bit-mode): include all components
    default_all = ["//docs/components/%s:docs_all" % c for c in components]
    default_trace = ["//docs/components/%s:docs_trace" % c for c in components]

    # Bit-mode: include only components explicitly enabled
    bitmode_all = []
    bitmode_trace = []
    for c in components:
        bitmode_all += select({
            ":incl_%s_true" % c: ["//docs/components/%s:docs_all" % c],
            "//conditions:default": [],
        })
        bitmode_trace += select({
            ":incl_%s_true" % c: ["//docs/components/%s:docs_trace" % c],
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
        visibility = ["//tools/sphinx/dynamic_project:__pkg__"],
    )
