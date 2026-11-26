#!/bin/sh
# Static checks for the ub-mode pack. Run directly: ./tests/verify.sh
#
# Compiling the formula needs a city that imports the pack; that pass is the
# separate `gc formula show ub-mode-build` listed in the README, and is run here
# too when the current directory is inside a city that has the pack.

set -eu
pack=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
fail=0

say() { printf '%s\n' "$*"; }
bad() { fail=1; printf 'FAIL %s\n' "$*"; }
ok() { printf 'ok   %s\n' "$*"; }

[ -f "$pack/pack.toml" ] || bad "pack.toml missing"
[ -x "$pack/assets/scripts/install-ub-tool.sh" ] || bad "assets/scripts/install-ub-tool.sh missing or not executable"
for tool in crapper dryer mutator; do
  [ -x "$pack/doctor/$tool/run.sh" ] || bad "doctor/$tool/run.sh missing or not executable"
done
[ -s "$pack/LICENSE" ] || bad "LICENSE missing"
grep -q "MIT License" "$pack/LICENSE" 2>/dev/null || bad "LICENSE is not the MIT text"
grep -q "Robert C. Martin" "$pack/LICENSE" 2>/dev/null || bad "LICENSE lost the upstream copyright line"
[ -s "$pack/skills/ub-mode/SKILL.md" ] || bad "skills/ub-mode/SKILL.md missing"

python3 - "$pack" <<'EOF' || fail=1
import sys, tomllib, pathlib, re

pack = pathlib.Path(sys.argv[1])
problems = []

def fail(msg):
    problems.append(msg)

try:
    pack_toml = tomllib.loads((pack / "pack.toml").read_text())
except Exception as exc:
    fail(f"pack.toml does not parse: {exc}")
    pack_toml = {}

name = pack_toml.get("pack", {}).get("name")
if name != "ub-mode":
    fail(f"pack.toml name is {name!r}, expected 'ub-mode'")
if pack_toml.get("pack", {}).get("schema") != 2:
    fail("pack.toml schema is not 2")
if not pack_toml.get("imports", {}).get("gc", {}).get("source"):
    fail("pack.toml does not import the gascity base pack")

skills = sorted((pack / "skills").glob("*/SKILL.md"))
if not skills:
    fail("no skills/*/SKILL.md")
for skill in skills:
    text = skill.read_text()
    m = re.search(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        fail(f"{skill.relative_to(pack)} has no frontmatter")
        continue
    head = m.group(1)
    declared = re.search(r"^name:\s*(\S+)", head, re.M)
    desc = re.search(r"^description:", head, re.M)
    if not declared:
        fail(f"{skill.relative_to(pack)} declares no name")
    if not desc:
        fail(f"{skill.relative_to(pack)} declares no description")
    if declared and declared.group(1) != "ub-mode":
        fail(f"{skill.relative_to(pack)} name is {declared.group(1)!r}, expected 'ub-mode'")

formulas = sorted((pack / "formulas").glob("*.toml"))
if not formulas:
    fail("no formulas/*.toml")
for path in formulas:
    try:
        doc = tomllib.loads(path.read_text())
    except Exception as exc:
        fail(f"{path.relative_to(pack)} does not parse: {exc}")
        continue
    rel = path.relative_to(pack)
    if not doc.get("formula"):
        fail(f"{rel} has no formula name")
    if "build-basic" not in (doc.get("extends") or []):
        fail(f"{rel} does not extend build-basic")
    if "contract" in doc:
        fail(f"{rel} uses the deprecated contract key; declare [requires] formula_compiler")
    if not (doc.get("requires") or {}).get("formula_compiler"):
        fail(f"{rel} declares no [requires] formula_compiler")
    if not (doc.get("catalog") or {}).get("name"):
        fail(f"{rel} has no [catalog] name")
    if not (doc.get("metadata") or {}).get("gc", {}).get("methodology"):
        fail(f"{rel} has no [metadata.gc.methodology] block")
    steps = {s.get("id") for s in doc.get("steps") or []}
    for want in ("plan", "implement", "implement-same-session"):
        if want not in steps:
            fail(f"{rel} does not override the {want!r} step")
    for step in doc.get("steps") or []:
        ref = step.get("description_file")
        if not ref:
            continue
        target = (path.parent / ref).resolve()
        if not target.is_file():
            fail(f"{rel} step {step.get('id')!r} description_file {ref} does not exist")

for problem in problems:
    print(f"FAIL {problem}")
sys.exit(1 if problems else 0)
EOF

if [ "$fail" -eq 0 ]; then ok "pack.toml, skills, formulas and description files"; fi

if command -v gc >/dev/null 2>&1 && gc formula show ub-mode-build >/dev/null 2>&1; then
  ok "gc formula show ub-mode-build compiles"
else
  say "skip gc formula show ub-mode-build (no city here imports the pack)"
fi

if [ "$fail" -ne 0 ]; then
  say "verify: FAILED"
  exit 1
fi
say "verify: passed"
