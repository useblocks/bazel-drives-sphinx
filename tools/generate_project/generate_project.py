import argparse
import os
import shutil
import sys
from pathlib import Path


def collect_rst_files(components_dir: Path):
    rst_files = []
    for root, _, files in os.walk(components_dir):
        for file in files:
            if file.endswith(".rst"):
                rst_files.append(os.path.join(root, file))
    return rst_files


def generate_sphinx_structure(
    output_dir: Path,
    schema: Path,
    ubproject: Path,
    template_file: Path,
    doc_files: list[Path],
):
    """Generate a proper Sphinx project structure."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Copy schema and ubproject files
    shutil.copy2(schema, output_path / "schemas.json")
    shutil.copy2(ubproject, output_path / "ubproject.toml")

    # Generate index.rst from template
    with open(template_file, "r") as f:
        template_content = f.read()

    # Create toctree entries from RST files only
    toctree_entries = []

    for doc_file in doc_files:
        # Strip 'docs/' prefix if present
        if str(doc_file).startswith("docs/"):
            rel_path = Path(str(doc_file)[5:])
        else:
            rel_path = doc_file

        doc_path = Path(doc_file).resolve()

        # Create destination path preserving structure
        dest_path = output_path / rel_path
        dest_path.parent.mkdir(parents=True, exist_ok=True)

        # Copy the file to output directory
        shutil.copy2(doc_file, dest_path)

        # Add to toctree only if it's an RST file (without .rst extension)
        if doc_path.suffix == ".rst":
            just_name = rel_path.with_suffix("")
            toctree_entries.append(f"{just_name} <{just_name}>")

    # Replace placeholder in template
    toctree_content = "\n   ".join(toctree_entries)
    index_content = template_content.replace("{{ toctree }}", toctree_content)

    # Write index.rst
    with open(output_path / "index.rst", "w") as f:
        f.write(index_content)


if __name__ == "__main__":
    print("Arguments:", sys.argv)

    parser = argparse.ArgumentParser(description="Generate Sphinx project structure")
    parser.add_argument(
        "--output-dir", required=True, help="Output directory for the generated project"
    )
    parser.add_argument("--schema", required=True, help="schemas.json file path")
    parser.add_argument("--ubproject", required=True, help="ubproject.toml file path")
    # parser.add_argument("--conf", required=True, help="Configuration file path")
    parser.add_argument(
        "--index-template", required=True, help="index.rst template file path"
    )
    parser.add_argument(
        "--doc",
        action="append",
        required=True,
        help="Documentation files (can be specified multiple times), also assets",
    )

    args = parser.parse_args()

    print(f"Output directory: {args.output_dir}")
    print(f"Schema: {args.schema}")
    print(f"ubproject.toml: {args.ubproject}")
    # print(f"Config: {args.conf}")
    print(f"Template: {args.index_template}")
    print(f"Docs: {args.doc}")

    generate_sphinx_structure(
        Path(args.output_dir),
        Path(args.schema),
        Path(args.ubproject),
        Path(args.index_template),
        [Path(x) for x in args.doc],
    )
