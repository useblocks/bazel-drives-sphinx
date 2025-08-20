import argparse
import sys
from pathlib import Path

# Internal template content
INDEX_TEMPLATE = """{{ title }}

.. toctree::
   :maxdepth: 2

{{ toctree_entries }}
"""

NEEDS_FILE_TEMPLATE = """{{ project_title }}
{{ underline }}

.. needimport:: {{ relative_path }}
"""


def generate_needimports_structure(
    output_dir, needs_json_files=None, title="Need imports"
):
    """Generate a needimports directory with separate files for each needimport and an index.rst with toctree."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Generate separate files for each needimport
    toctree_entries = []
    created_files = []

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
                project_name = None
                for i, part in enumerate(path_parts):
                    if part == "projects" and i + 1 < len(path_parts):
                        project_name = path_parts[i + 1]
                        break

                if project_name:
                    # Create filename for this project's needs
                    needs_filename = f"{project_name}_needs.rst"
                    needs_file_path = output_path / needs_filename

                    # Relative path to the needs.json file
                    relative_dir = f"../../../../{needs_json_path}"
                    relative_path = f"{relative_dir}/needs.json"

                    # Project title for the needs file
                    project_title = f"Project {project_name}"
                    underline = "=" * len(project_title)

                    # Generate the needs file content
                    needs_content = NEEDS_FILE_TEMPLATE.replace(
                        "{{ project_title }}", project_title
                    )
                    needs_content = needs_content.replace("{{ underline }}", underline)
                    needs_content = needs_content.replace(
                        "{{ relative_path }}", relative_path
                    )

                    # Write the needs file
                    with open(needs_file_path, "w") as f:
                        f.write(needs_content)

                    # Add to toctree (without .rst extension)
                    toctree_entries.append(f"   {project_name}_needs")
                    created_files.append(needs_filename)

    # Generate index.rst with toctree
    toctree_content = (
        "\n".join(toctree_entries)
        if toctree_entries
        else "   No need imports configured"
    )

    index_content = INDEX_TEMPLATE.replace("{{ toctree_entries }}", toctree_content)
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
    print(f"Created files: {created_files}")
    print(f"Toctree entries: {toctree_entries}")


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
