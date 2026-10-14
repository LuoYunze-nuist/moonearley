"""Compare MoonEarley against the explicitly provided pinned MIT Lark source.
No reference implementation is vendored and no generated fixture counts as code.
"""
import argparse
import subprocess
import sys
from pathlib import Path

PIN = "9a4fb9c7458e8155636773a3cded0016d52516da"
GRAMMARS = [
    'start: start start | "a"',
    'start: start "a" |',
    'start: maybe "b" maybe\nmaybe: "a" |',
    'start: left | right\nleft: "a"\nright: "a"',
]

def derivations(tree):
    if not hasattr(tree, "data"):
        return 1
    if tree.data == "_ambig":
        return sum(derivations(child) for child in tree.children)
    result = 1
    for child in tree.children:
        result *= derivations(child)
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lark-source", type=Path, required=True,
                        help="checkout of lark-parser/lark at " + PIN)
    parser.add_argument("--target", default="js", choices=["js", "wasm-gc", "wasm", "native"])
    args = parser.parse_args()
    source = args.lark_source.resolve()
    if not (source / "lark" / "__init__.py").is_file():
        parser.error("a real Lark source tree is required")
    # A Git checkout must have the exact reviewed revision. A saved archive can
    # be used locally; its provenance remains a separate audit responsibility.
    if (source / ".git").exists():
        head = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
        if head != PIN:
            parser.error("Lark revision differs from reviewed source")
    sys.path.insert(0, str(source))
    from lark import Lark, UnexpectedInput
    reference = []
    for which, grammar in enumerate(GRAMMARS):
        engine = Lark(grammar, parser="earley", ambiguity="explicit", lexer="basic")
        for length in range(6):
            for bits in range(1 << length):
                text = "".join("b" if bits >> i & 1 else "a" for i in range(length))
                try:
                    count = derivations(engine.parse(text))
                    accepted = "true"
                except UnexpectedInput:
                    count, accepted = 0, "false"
                reference.append(f"{which},{length},{bits},{accepted},{count}")
    result = subprocess.run(["moon", "run", "examples/reference", "--target", args.target],
                            cwd=Path(__file__).resolve().parents[1], capture_output=True, text=True)
    if result.returncode:
        print(result.stdout + result.stderr, file=sys.stderr)
        return 1
    actual = result.stdout.strip().splitlines()
    if actual != reference:
        for index in range(max(len(actual), len(reference))):
            a = actual[index] if index < len(actual) else "<missing>"
            e = reference[index] if index < len(reference) else "<extra>"
            if a != e:
                print(f"Mismatch {index}: MoonEarley={a}; Lark={e}", file=sys.stderr)
        return 1
    print(f"Lark {PIN}: {len(reference)}/{len(reference)} acceptance and derivation-count cases agree ({args.target}).")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
