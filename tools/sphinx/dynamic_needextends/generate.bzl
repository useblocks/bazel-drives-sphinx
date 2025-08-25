"""Generate needimports directory with index.rst for needs.json files."""

def _generate_needextends_structure_impl(ctx):
    # Create output directory relative to the current package
    output_dir = ctx.actions.declare_directory("codelinks/docs")

    args = ctx.actions.args()
    args.add("--title", ctx.attr.title)
    args.add("--output-dir", output_dir.path)

    # Add needextends.rst files
    for needextends_label in ctx.files.needextends_labels:
        args.add("--needextends-path", needextends_label.path)
        args.add("--needextends-short-path", needextends_label.short_path)

    # Only needs_json_labels are inputs now
    inputs = ctx.files.needextends_labels

    ctx.actions.run(
        inputs = inputs,
        outputs = [output_dir],
        executable = ctx.executable._generate_script,
        arguments = [args],
        mnemonic = "GenerateNeedExtendsRst",
    )

    return [DefaultInfo(files = depset([output_dir]))]

generate_needextends_structure = rule(
    implementation = _generate_needextends_structure_impl,
    attrs = {
        "title": attr.string(mandatory = True, doc = "Root index.rst title of the generated project"),
        "needextends_labels": attr.label_list(
            doc = "List of labels that produce needextends.rst files",
            allow_empty = False,
        ),
        "_generate_script": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//tools/sphinx/dynamic_needextends:generator"),
        ),
    },
)
