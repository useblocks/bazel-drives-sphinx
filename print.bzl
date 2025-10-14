# Reference: https://bazel.build/extending/aspects

def _print_aspect_impl(target, ctx):
    
    print("+ print_aspect_impl")
    print("Target: " + str(target.label))
    print(ctx.rule.kind)
    target_kind = getattr(ctx.attr, "target_kind", "")
    print("Target kind from attr: " + target_kind)
    # Make sure the rule has a srcs attribute.
    if target_kind != ctx.rule.kind:
       return []

    if hasattr(ctx.rule.attr, 'srcs'):
        # Iterate through the files that make up the sources and
        # print their paths.
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                print(f.path)
    print("- print_aspect_impl")
    return []

print_aspect = aspect(
    implementation = _print_aspect_impl,
    attr_aspects = ['srcs'],    # the edge to track
    attrs = {
        'target_kind': attr.string(
            default = 'codelinks_analyse',),
    }
    # required_providers = [CcInfo],
)