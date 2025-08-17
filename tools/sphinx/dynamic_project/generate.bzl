"""Directory output."""

def _generate_sphinx_project_impl(ctx):
    # Create output directory relative to the current package
    output_dir = ctx.actions.declare_directory("docs_generated")

    args = ctx.actions.args()
    args.add("--title", ctx.attr.title)
    args.add("--output-dir", output_dir.path)
    args.add("--index-template", ctx.file.index_template.path)
    
    # Add strip_prefix if provided
    if ctx.attr.strip_prefix:
        args.add("--strip-prefix", ctx.attr.strip_prefix)
    
    # Set prefix to "generated" so RST files go into the generated/ subdirectory
    if ctx.attr.prefix:
        args.add("--prefix", ctx.attr.prefix)

    # Add all docs files
    for doc in ctx.files.all_docs:
        args.add("--doc", doc.path)

    ctx.actions.run(
        inputs = [ctx.file.index_template] + ctx.files.all_docs,
        outputs = [output_dir],
        executable = ctx.executable.generate_script,
        arguments = [args],
        mnemonic = "GenerateDynamicSphinxProject",
    )

    return [DefaultInfo(files = depset([output_dir]))]

generate_sphinx_project = rule(
    implementation = _generate_sphinx_project_impl,
    attrs = {
        "title": attr.string(mandatory = True, doc = "Root index.rst title of the generated project"),
        "generate_script": attr.label(executable = True, cfg = "exec"),
        "index_template": attr.label(allow_single_file = True),
        "all_docs": attr.label(),
        "strip_prefix": attr.string(
            doc = "Prefix to strip from document paths when generating toctree entries and copying files",
            default = "",
        ),
        "prefix": attr.string(
            doc = "Prefix to add to all document paths in the generated project structure",
            default = "",
        ),
    },
)
