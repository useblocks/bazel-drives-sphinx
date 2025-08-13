"""Directory output."""

def _generate_sphinx_project_impl(ctx):
    output_dir = ctx.actions.declare_directory("")

    args = ctx.actions.args()
    args.add("--output-dir", output_dir.path)
    # args.add("--schema", ctx.file.schema.path)
    # args.add("--ubproject", ctx.file.ubproject.path)
    args.add("--index-template", ctx.file.index_template.path)

    # Add all docs files
    for doc in ctx.files.all_docs:
        args.add("--doc", doc.path)

    ctx.actions.run(
        inputs = [ctx.file.index_template] + ctx.files.all_docs,
        outputs = [output_dir],
        executable = ctx.executable.generate_script,
        arguments = [args],
        mnemonic = "GenerateSphinxProject",
    )

    return [DefaultInfo(files = depset([output_dir]))]

generate_sphinx_project = rule(
    implementation = _generate_sphinx_project_impl,
    attrs = {
        "generate_script": attr.label(executable = True, cfg = "exec"),
        # "schema": attr.label(allow_single_file = True),
        # "ubproject": attr.label(allow_single_file = True),
        # "conf_py": attr.label(allow_single_file = True),
        "index_template": attr.label(allow_single_file = True),
        "all_docs": attr.label(),
    },
)
