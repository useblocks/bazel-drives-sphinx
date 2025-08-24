import argparse
import os
import sys
from pathlib import Path

# Internal template content
INDEX_TEMPLATE = """{{ title }}

Included needextends files from the following code parts:

{{ project_sections }}
"""


def generate_needextends_structure(
    output_dir,
    needextends_paths: list[str],
    needextends_short_paths: list[str],
    title="CodeLinks references",
):
    """Generate a needextends directory with separate files for each needextends file and an index.rst with toctree."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Collect all project sections
    project_sections = []

    assert len(needextends_paths) == len(needextends_short_paths), (
        "needextends_path and needextends_short_path must have the same length"
    )
    cwd = os.getcwd()
    for idx, needextends_path in enumerate(needextends_paths):
        # Extract project path from file path
        # The project path is the directory containing the needextends.rst file
        needextends_path = Path(needextends_path)
        needextends_short_path = Path(needextends_short_paths[idx])

        needextends_abs_path = cwd / needextends_path

        # Get the parent directory of the needextends.rst file as the project path
        project_path = needextends_short_path.parent

        # Project title for the section
        project_title = f"**{project_path}**"
        # underline = "-" * len(project_title)

        # Read the needextends file content
        needextends_content = ""
        try:
            with needextends_abs_path.open("r") as f:
                file_content = f.read().strip()
                needextends_content = f"{file_content}\n"
                needextends_content += "\n.. code-block:: rst\n\n"
                # Indent each line with 4 spaces for the code block
                for line in file_content.split("\n"):
                    needextends_content += f"    {line}\n"
        except FileNotFoundError:
            needextends_content = f"File not found: {needextends_abs_path}"
        except Exception as e:
            needextends_content = f"Error reading file: {e}"

        # Create the project section
        section = f"{project_title}\n\n{needextends_content}\n"
        project_sections.append(section)

    # Generate index.rst with all project sections
    sections_content = (
        "\n".join(project_sections)
        if project_sections
        else "No needextends files configured"
    )

    index_content = INDEX_TEMPLATE.replace("{{ project_sections }}", sections_content)
    index_content = index_content.replace("{{ title }}", f"{title}\n{len(title) * '='}")

    # Write index.rst
    index_path = output_path / "index.rst"
    with open(index_path, "w") as f:
        f.write(index_content)

    print(f"Generated needextends project in {output_path}")
    print(f"Project title: '{title}'")
    print(f"Project sections: {len(project_sections)}")


if __name__ == "__main__":
    print("Arguments:", sys.argv)

    parser = argparse.ArgumentParser(
        description="Generate needextends project structure"
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
        "--needextends-path",
        action="append",
        required=True,
        help="needextends.rst bazel path (can be specified multiple times)",
    )
    parser.add_argument(
        "--needextends-short-path",
        action="append",
        required=True,
        help="needextends.rst bazel short_path (can be specified multiple times)",
    )

    args = parser.parse_args()

    print(f"Output directory: {args.output_dir}")
    print(f"Project title: '{args.title}'")
    print(f"needextends.rst path: {args.needextends_path}")
    print(f"needextends.rst short_paths: {args.needextends_short_path}")

    generate_needextends_structure(
        output_dir=args.output_dir,
        needextends_paths=args.needextends_path,
        needextends_short_paths=args.needextends_short_path,
        title=args.title,
    )
