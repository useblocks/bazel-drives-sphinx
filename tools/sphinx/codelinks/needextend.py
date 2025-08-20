import sys

from sphinx_codelinks.cmd import bridge
from pathlib import Path

def main():

    args = {
        'jsonpath': Path(sys.argv[1]),
        'outdir': Path(sys.argv[2]),
        'remote_url_field': sys.argv[3] if len(sys.argv) > 2 else 'source_trace'
    }
    bridge(**args)


if __name__ == "__main__":
    main()
