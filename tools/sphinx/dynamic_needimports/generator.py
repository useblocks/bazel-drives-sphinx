import argparse
import os
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
    output_dir: Path,
    needs_json_paths: list[Path],
    needs_json_short_paths: list[Path],
    title="Need imports",
):
    """
    Generate a needimports directory with separate files for each needimport and an index.rst with toctree.
    
    :param output_dir: Output directory for the generated needimport RST parts
    :param needs_json_paths: List of Bazel paths to dirs containing needs.json files
    :param needs_json_short_paths: List of Bazel short_paths to dirs containing needs.json files
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate separate files for each needimport
    toctree_entries = []
    created_files = []

    assert len(needs_json_paths) == len(needs_json_short_paths), (
        "needs_json_paths and needs_json_short_paths must have the same length"
    )

    cwd = Path(os.getcwd())
    if needs_json_paths:
        for idx, needs_json_file in enumerate(needs_json_paths):
            # Extract the relative path for the needimport directive
            needs_json_path = Path(needs_json_file)
            needs_json_short_path = Path(needs_json_short_paths[idx])

            # Construct a file name for the target needs.json
            # Remove commonly existing trailing parts that are not useful for the filename.
            # e.g. projects/webapp/docs_needs/_build/needs -> projects/webapp/docs_needs
            path_parts = needs_json_short_path.parts
            to_rm_from_end_items = ["needs", "_build"]
            for to_rm in to_rm_from_end_items:
                if path_parts and path_parts[-1] == to_rm:
                    path_parts = path_parts[:-1]
            project_file_name = "_".join(path_parts)

            # Remove characters that should not exist in filenames
            invalid_chars = ' <>:"/\\|?*'
            for char in invalid_chars:
                project_file_name = project_file_name.replace(char, "_")
            # Ensure the filename isn't empty
            assert project_file_name, (
                f"Could not determine a valid filename from {needs_json_short_path}"
            )

            # Look for the pattern that indicates this is a needs build output
            # Create filename for this project's needs
            needs_filename = f"{project_file_name}.rst"
            needs_rst_output_path = output_dir / needs_filename

            # Relative path to the needs.json file using short_path
            # Find common root path between needs_json_path and output_dir
            needs_json_abs = cwd / needs_json_path
            output_dir_abs = cwd / output_dir

            # Find common path
            try:
                common_path = Path(
                    os.path.commonpath([needs_json_abs, output_dir_abs])
                )
            except ValueError:
                # No common path (e.g., different drives on Windows), use absolute path
                common_path = Path("/")

            # Calculate steps back from output_dir to common_path
            output_rel_to_common = output_dir_abs.relative_to(common_path)
            steps_back = len(output_rel_to_common.parts)
            back_path = "/".join([".."] * steps_back) if steps_back > 0 else "."

            # Calculate path from common_path to needs.json
            needs_rel_to_common = needs_json_abs.relative_to(common_path)
            forward_path = str(needs_rel_to_common) if needs_rel_to_common.parts else ""

            # Combine back path and forward path
            if back_path == "." and not forward_path:
                relative_path = "needs.json"
            elif back_path == "." and forward_path:
                relative_path = f"{forward_path}/needs.json"
            elif forward_path:
                relative_path = f"{back_path}/{forward_path}/needs.json"
            else:
                relative_path = f"{back_path}/needs.json"

            # raise ValueError(
            #     f"\n  {cwd=}"
            #     f"\n  {needs_json_path=}"
            #     f"\n  {needs_json_short_path=}"
            #     f"\n  {output_dir=}"
            #     f"\n  {output_dir_abs=}"
            #     # f"\n  {needs_file_path_abs=}"
            #     # f"\n  {relative_dir=}"
            #     f"\n  {relative_path=}"
            #     f"\n  {path_parts=}"
            #     f"\n  {needs_file_path=}"
            #     f"\n  {project_file_name=}"
            # )

            # Project title for the needs file
            project_title = f"Project {'/'.join(path_parts)}"
            underline = "=" * len(project_title)

            # Generate the needs file content
            needs_content = NEEDS_FILE_TEMPLATE.replace(
                "{{ project_title }}", project_title
            )
            needs_content = needs_content.replace("{{ underline }}", underline)
            needs_content = needs_content.replace("{{ relative_path }}", relative_path)

            # Write the needs file
            with open(needs_rst_output_path, "w") as f:
                f.write(needs_content)

            # Add to toctree (without .rst extension)
            toctree_entries.append(f"   {project_file_name}")
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
    index_path = output_dir / "index.rst"
    with open(index_path, "w") as f:
        f.write(index_content)

    print(f"Generated needimports project in {output_dir}")
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
        "--needs-json-path",
        action="append",
        default=[],
        help="needs.json files path (can be specified multiple times)",
    )
    parser.add_argument(
        "--needs-json-short-path",
        action="append",
        default=[],
        help="needs.json files short_path (can be specified multiple times)",
    )

    args = parser.parse_args()

    print(f"Output directory: {args.output_dir}")
    print(f"Project title: '{args.title}'")
    print(f"Needs JSON paths: {args.needs_json_path}")
    print(f"Needs JSON short paths: {args.needs_json_short_path}")

    generate_needimports_structure(
        Path(args.output_dir),
        [Path(x) for x in args.needs_json_path],
        [Path(x) for x in args.needs_json_short_path],
        args.title,
    )
