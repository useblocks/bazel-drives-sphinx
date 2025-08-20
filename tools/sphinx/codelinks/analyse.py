import sys

from sphinx_codelinks.cmd import analyse
from pathlib import Path

def main():
    analyse(config=Path(sys.argv[1]), outdir=Path(sys.argv[2]))


if __name__ == "__main__":
    main()
