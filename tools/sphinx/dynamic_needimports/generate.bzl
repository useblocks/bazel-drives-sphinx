"""Generate needimports directory with index.rst for needs.json files."""

def _generate_needimports_structure_impl(ctx):
    # Create output directory relative to the current package
    output_dir = ctx.actions.declare_directory("needimports/docs")

    args = ctx.actions.args()
    args.add("--title", ctx.attr.title)
    args.add("--output-dir", output_dir.path)

    # Add needs.json files with both path and short_path
    for needs_json in ctx.files.needs_json_labels:
        args.add("--needs-json-path", needs_json.path)
        args.add("--needs-json-short-path", needs_json.short_path)

    # Only needs_json_labels are inputs now
    inputs = ctx.files.needs_json_labels

    ctx.actions.run(
        inputs = inputs,
        outputs = [output_dir],
        executable = ctx.executable._generate_script,
        arguments = [args],
        mnemonic = "GenerateNeedImportsRst",
    )

    return [DefaultInfo(files = depset([output_dir]))]

generate_needimports_structure = rule(
    implementation = _generate_needimports_structure_impl,
    attrs = {
        "title": attr.string(mandatory = True, doc = "Root index.rst title of the generated project"),
        "needs_json_labels": attr.label_list(
            doc = "List of labels that produce needs.json files",
            default = [],
        ),
        "_generate_script": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//tools/sphinx/dynamic_needimports:generator"),
        ),
    },
)
