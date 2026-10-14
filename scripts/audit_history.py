"""Inspect real Git history without rewriting it. Meaningfulness needs human review."""
import argparse
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
LOGIN = "LuoYunze-nuist"
EMAIL = "280011106+LuoYunze-nuist@users.noreply.github.com"

def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True, encoding="utf-8").strip()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--minimum-nonempty", type=int, default=20)
    args = parser.parse_args()
    errors = []
    nonempty = 0
    commits = git("rev-list", "--reverse", "HEAD").splitlines()
    for sha in commits:
        fields = git("show", "-s", "--format=%an%n%ae%n%cn%n%ce%n%s", sha).splitlines()
        if fields[:4] != [LOGIN, EMAIL, LOGIN, EMAIL]:
            errors.append("author or committer differs from bound repository identity: " + sha)
        paths = git("diff-tree", "--root", "--no-commit-id", "--name-only", "-r", sha).splitlines()
        if not paths:
            errors.append("empty commit: " + sha)
        else:
            nonempty += 1
        print(sha + " " + fields[-1] + " [" + ", ".join(paths) + "]")
    print(f"Raw commits: {len(commits)}; nonempty: {nonempty}. Independent engineering value is reviewed in docs/history-review.md.")
    if nonempty < args.minimum_nonempty:
        errors.append("nonempty history below required threshold")
    for error in errors:
        print("ERROR: " + error)
    return bool(errors)

if __name__ == "__main__":
    raise SystemExit(main())
