import sys
import os

# Allow imports from project root
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core.cli import main as cli_main


def main():
    sys.exit(cli_main())


if __name__ == "__main__":
    main()
