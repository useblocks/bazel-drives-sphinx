def generate_component_config(name, components):
    """Generate component-specific config_settings and file selections.
    
    Args:
        name: unused
        components: List of component names (e.g., ['api', 'auth', 'schema_fail'])
    """

    native.config_setting(
        name = "trace_only_true",
        define_values = {"trace_only": "true"},
    )

    # Generate config_setting for each component
    for component in components:
        native.config_setting(
            name = "component_" + component,
            define_values = {"component": component},
        )

    # Generate the all_files filegroup with select
    all_files_select = {}
    trace_files_select = {}
    
    # Default case - all components
    default_all_files = []
    default_trace_files = []
    
    for component in components:
        # Add individual component selections
        all_files_select[":component_" + component] = ["//docs/components/" + component + ":docs_all"]
        trace_files_select[":component_" + component] = ["//docs/components/" + component + ":docs_trace"]
        
        # Add to default (all components)
        default_all_files.append("//docs/components/" + component + ":docs_all")
        default_trace_files.append("//docs/components/" + component + ":docs_trace")
    
    # Use //conditions:default instead of creating an invalid config_setting
    all_files_select["//conditions:default"] = default_all_files
    trace_files_select["//conditions:default"] = default_trace_files
    
    # Create filegroups for the selections
    native.filegroup(
        name = "component_all_files",
        srcs = select(all_files_select),
    )
    
    native.filegroup(
        name = "component_trace_files", 
        srcs = select(trace_files_select),
    )
    
    # Create the final files selection
    native.filegroup(
        name = "files",
        srcs = select({
            ":trace_only_true": [":component_trace_files"],
            "//conditions:default": [":component_all_files"],
        }),
        visibility = ["//tools/sphinx/dynamic_project:__pkg__"],
    )
