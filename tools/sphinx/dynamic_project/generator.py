import argparse
import shutil
import sys
from pathlib import Path


def strip_path_prefix(file_path, strip_prefix):
    """Strip the specified prefix from the file path."""
    if not strip_prefix:
        return file_path

    path = Path(file_path)
    path_str = str(path)

    # Remove the strip_prefix if it exists at the start
    if path_str.startswith(strip_prefix):
        # Remove prefix and any leading slash
        stripped = path_str[len(strip_prefix) :].lstrip("/")
        return stripped if stripped else path.name

    return path.name


def add_path_prefix(file_path, prefix):
    """Add the specified prefix to the file path."""
    if not prefix:
        return file_path

    path = Path(file_path)
    prefix_path = Path(prefix)

    # Combine prefix with the file path
    return str(prefix_path / path)


def generate_sphinx_structure(
    output_dir, template_file, doc_files, strip_prefix="", prefix="", title=""
):
    """Generate a proper Sphinx project structure."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Generate index.rst from template
    with open(template_file, "r") as f:
        template_content = f.read()

    # Create toctree entries from doc files
    toctree_entries = []
    file_mapping = {}  # Track original -> destination mapping

    for doc_file in doc_files:
        # Apply strip_prefix to determine the relative path structure
        stripped_path = strip_path_prefix(doc_file, strip_prefix)

        # Apply prefix to the stripped path
        prefixed_path = add_path_prefix(stripped_path, prefix)
        dest_path = Path(prefixed_path)

        # Create the destination path in output directory
        full_dest_path = output_path / dest_path

        # Ensure destination directory exists
        full_dest_path.parent.mkdir(parents=True, exist_ok=True)

        # Copy the file
        shutil.copy2(doc_file, full_dest_path)

        # Add to toctree (without .rst extension)
        toctree_entry = f'{dest_path.with_suffix("")} <{dest_path.with_suffix("")}>'
        toctree_entries.append(toctree_entry)

        # Track mapping for debugging
        file_mapping[doc_file] = str(dest_path)

    # Sort toctree entries for consistent output
    toctree_entries.sort()

    # Replace placeholders in template
    toctree_content = "\n   ".join(toctree_entries)
    index_content = template_content.replace("{{ toctree }}", toctree_content)
    final_title = title or "Documentation"
    index_content = index_content.replace("{{ title }}", f"{final_title}\n{len(final_title) * '='}")

    # Write index.rst
    index_path = output_path / "index.rst"
    index_path.parent.mkdir(parents=True, exist_ok=True)
    with open(index_path, "w") as f:
        f.write(index_content)

    print(f"Generated Sphinx project in {output_path}")
    print(f"Project title: '{title}'")
    print(f"Strip prefix: '{strip_prefix}'")
    print(f"Add prefix: '{prefix}'")
    print("File mappings:")
    for orig, dest in file_mapping.items():
        print(f"  {orig} -> {dest}")
    print(f"Toctree entries: {toctree_entries}")


if __name__ == "__main__":
    print("Arguments:", sys.argv)

    parser = argparse.ArgumentParser(description="Generate Sphinx project structure")
    parser.add_argument(
        "--output-dir", required=True, help="Output directory for the generated project"
    )
    parser.add_argument("--index-template", required=True, help="Template file path")
    parser.add_argument(
        "--title",
        default="",
        help="Title of the project to use in the documentation",
    )
    parser.add_argument(
        "--strip-prefix",
        default="",
        help="Prefix to strip from document paths when generating structure",
    )
    parser.add_argument(
        "--prefix",
        default="",
        help="Prefix to add to all document paths in the generated structure",
    )
    parser.add_argument(
        "--doc",
        action="append",
        required=True,
        help="Documentation files (can be specified multiple times)",
    )

    args = parser.parse_args()

    print(f"Output directory: {args.output_dir}")
    print(f"Template: {args.index_template}")
    print(f"Project title: '{args.title}'")
    print(f"Strip prefix: '{args.strip_prefix}'")
    print(f"Add prefix: '{args.prefix}'")
    print(f"Docs: {args.doc}")

    generate_sphinx_structure(
        args.output_dir,
        args.index_template,
        args.doc,
        args.strip_prefix,
        args.prefix,
        args.title,
    )
