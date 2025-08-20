"""Analyse code links and generate marked_content.json file."""

def _codelinks_analyse_impl(ctx):
    # Create output directory
    output_dir = ctx.actions.declare_directory("codelinks_analyse")

    args = ctx.actions.args()

    # First argument: config file
    args.add(ctx.file.config.path)

    # Second argument: output directory
    args.add(output_dir.path)

    inputs = [ctx.file.config] + ctx.files.srcs

    ctx.actions.run(
        inputs = inputs,
        outputs = [output_dir],
        executable = ctx.executable._analyse_script,
        arguments = [args],
        mnemonic = "CodeLinksAnalyse",
    )

    return [DefaultInfo(files = depset([output_dir]))]

codelinks_analyse = rule(
    implementation = _codelinks_analyse_impl,
    attrs = {
        "config": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Config file to pass to the analyse script",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            default = [],
            doc = "List of source files to be analyzed",
        ),
        "_analyse_script": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//tools/sphinx/codelinks:analyse"),
        ),
    },
)
