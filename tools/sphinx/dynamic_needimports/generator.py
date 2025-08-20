import argparse
import sys
from pathlib import Path

# Internal template content
INDEX_TEMPLATE = """{{ title }}

{{ needimports }}
"""


def generate_needimports_structure(
    output_dir, needs_json_files=None, title="Need imports"
):
    """Generate a needimports directory with index.rst containing needimport directives."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Generate needimport directives from needs.json files
    needimport_entries = []
    if needs_json_files:
        for needs_json_file in needs_json_files:
            # Extract the relative path for the needimport directive
            needs_json_path = Path(needs_json_file)

            # Find the needs.json file in the path and construct relative path
            # Example: projects/webapp/docs_needs/_build/needs/needs.json -> ../webapp/docs_needs/_build/needs/needs.json
            path_parts = needs_json_path.parts

            # Look for the pattern that indicates this is a needs build output
            if "_build" in path_parts and "needs" in path_parts:
                # Find the project name (e.g., 'webapp', 'acdc')
                project_idx = None
                for i, part in enumerate(path_parts):
                    if part == "projects" and i + 1 < len(path_parts):
                        project_idx = i + 1
                        break

                relative_dir = f"../../../../{needs_json_path}"
                relative_path = f"{relative_dir}/needs.json"

                if project_idx:
                    import_title = f"Project {path_parts[project_idx]}"
                else:
                    import_title = f"{needs_json_file}/needs.json"

                needimport_entries.append(f"{import_title}")
                needimport_entries.append("-" * len(import_title) + "\n")
                needimport_entries.append(f".. needimport:: {relative_path}\n")

    # Replace placeholders in template
    needimport_content = (
        "\n".join(needimport_entries)
        if needimport_entries
        else "No need imports configured."
    )

    index_content = INDEX_TEMPLATE.replace("{{ needimports }}", needimport_content)
    final_title = title or "Need imports"
    index_content = index_content.replace(
        "{{ title }}", f"{final_title}\n{len(final_title) * '='}"
    )

    # Write index.rst
    index_path = output_path / "index.rst"
    with open(index_path, "w") as f:
        f.write(index_content)

    print(f"Generated needimports project in {output_path}")
    print(f"Project title: '{title}'")
    print(f"Needimport entries: {needimport_entries}")


if __name__ == "__main__":
    print("Arguments:", sys.argv)

    parser = argparse.ArgumentParser(
        description="Generate needimports project structure"
    )
    parser.add_argument(
        "--output-dir", required=True, help="Output directory for the generated project"
    )
    parser.add_argument(
        "--title",
        default="Need imports",
        help="Title of the project to use in the documentation",
    )
    parser.add_argument(
        "--needs-json",
        action="append",
        default=[],
        help="needs.json files (can be specified multiple times)",
    )

    args = parser.parse_args()

    print(f"Output directory: {args.output_dir}")
    print(f"Project title: '{args.title}'")
    print(f"Needs JSON: {args.needs_json}")

    generate_needimports_structure(
        args.output_dir,
        args.needs_json,
        args.title,
    )
