"""Physical substantive MoonBit inventory; tests/examples/generated sources excluded.
Comments and blanks are included in physical count, never accepted as substance by
this script alone. Human review of each implementation remains required.
"""
import argparse
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDE = {"examples", "benchmarks", "vendor", "generated", "_build", ".mooncakes", "_reference-lark"}

def inventory():
    files = []
    for path in sorted(ROOT.rglob("*.mbt")):
        rel = path.relative_to(ROOT)
        if any(part in EXCLUDE for part in rel.parts):
            continue
        if path.name.endswith(("_test.mbt", "_wbtest.mbt")):
            continue
        lines = path.read_text(encoding="utf-8-sig").splitlines()
        substance = sum(bool(line.strip()) and not line.lstrip().startswith("//") for line in lines)
        files.append({"path": rel.as_posix(), "physical": len(lines), "nonblank_noncomment": substance})
    return files

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-production", type=int, default=0)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    files = inventory()
    physical = sum(f["physical"] for f in files)
    substance = sum(f["nonblank_noncomment"] for f in files)
    result = {"method": "physical .mbt excluding tests/examples/vendor/generated", "production": files,
              "physical_lines": physical, "nonblank_noncomment_lines": substance}
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        for f in files:
            print(f'{f["path"]}: {f["physical"]} physical / {f["nonblank_noncomment"]} nonblank noncomment')
        print(f"TOTAL {physical} physical / {substance} nonblank noncomment production lines")
    return 0 if physical >= args.require_production else 1

if __name__ == "__main__":
    raise SystemExit(main())
