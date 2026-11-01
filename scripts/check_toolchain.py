#!/usr/bin/env python3
"""Reject missing, unrecognized, or older MoonBit compilers before validation."""
import re
import subprocess
import sys

MINIMUM = (0, 10, 16)


def main():
    try:
        result = subprocess.run(
            ["moon", "version", "--all"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            encoding="utf-8",
            errors="replace",
            timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        print("Cannot inspect MoonBit toolchain: " + str(exc), file=sys.stderr)
        return 1
    print(result.stdout, end="")
    if result.returncode:
        print(result.stderr, end="", file=sys.stderr)
        return 1
    match = re.search(r"^moonc v(\d+)\.(\d+)\.(\d+)(?=[+\s]|$)", result.stdout, re.MULTILINE)
    if match is None:
        print("Cannot verify moonc version; need >= 0.10.16.", file=sys.stderr)
        return 1
    version = tuple(int(part) for part in match.groups())
    if version < MINIMUM:
        print("moonc >= 0.10.16 is required; found " + ".".join(match.groups()), file=sys.stderr)
        return 1
    print("Compiler requirement satisfied: moonc >= 0.10.16")
    return 0


if __name__ == "__main__":
    sys.exit(main())
