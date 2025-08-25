"""Write needextend directives from CodeLinks markers input."""

def _codelinks_needextend_impl(ctx):
    # Create output directory
    output_dir = ctx.actions.declare_file("needextends.rst")

    args = ctx.actions.args()

    # JSON marker file
    args.add(ctx.files.json_markers[0].path + "/marked_content.json")

    # output directory
    args.add(output_dir.path)

    # remote URL field name
    args.add(ctx.attr.remote_url_field)

    inputs = [ctx.file.json_markers]

    ctx.actions.run(
        inputs = inputs,
        outputs = [output_dir],
        executable = ctx.executable._needextend_script,
        arguments = [args],
        mnemonic = "CodeLinksWriteNeedextend",
    )

    return [DefaultInfo(files = depset([output_dir]))]

codelinks_needextend = rule(
    implementation = _codelinks_needextend_impl,
    attrs = {
        "json_markers": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "CodeLinks marker .json file",
        ),
        "remote_url_field": attr.string(
            default = "src_trace",
            doc = "Name of the field to store remote URL in",
        ),
        "_needextend_script": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//tools/sphinx/codelinks:needextend"),
        ),
    },
)
