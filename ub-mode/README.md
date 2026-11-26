# ub-mode pack

Uncle Bob's [ub-mode](https://github.com/unclebob/ub-mode) as a Gas City pack: the
skill, the three quality gates it names, and a `build-basic` variant that applies
ub-mode to design and implementation.

## What it contains

| Piece | What it does |
| --- | --- |
| `skills/ub-mode/SKILL.md` | The reduced principles, vendored from upstream. Registers as `ub-mode`. |
| `formulas/ub-mode-build.toml` | `build-basic` with its `plan`, `implement`, and `implement-same-session` steps replaced so they apply ub-mode. |
| `assets/workflows/ub-mode-build/` | The replacement step prompts. |
| `doctor/{crapper,dryer,mutator}/` | Install the Python gates at fixed paths and report them in `gc doctor`. |
| `assets/scripts/install-ub-tool.sh` | Shared installer behind the three doctor checks. |

## Gating model

`ub-mode-build` extends `build-basic` and overrides exactly three steps:

- `plan` – design under ub-mode (domain model, boundary, types, shared state,
  first principles, subtraction, TDD up front).
- `implement` and `implement-same-session` – per-unit TDD plus the crapper, dryer
  and mutator gates.

Every other step is inherited unchanged, so requirements, design review,
decomposition, review, verify and publish behave like plain `build-basic`. Review
steps do not mention ub-mode.

This is instruction gating, not isolation. Agents in the build are told to apply
ub-mode and their prompts carry the rules; nothing stops another agent in the same
city from writing code that ignores it.

## Install

The pack imports the public `gascity` base pack by URL, so it needs no sibling
checkout:

```toml
[imports.ub-mode]
source = "https://github.com/docbobo/gascity-packs/tree/main/ub-mode"
version = "^0.1"
```

Then install the tools once:

```sh
gc doctor
```

`ub-mode:crapper`, `ub-mode:dryer` and `ub-mode:mutator` each install into
`~/.gc/cache/ub-mode/<tool>` from a pinned commit and write a launcher at
`~/.gc/cache/bin/<tool>`. That layout is deliberately fixed (no env-var override)
so the absolute paths in the skill and step prompts always resolve. gc's own
`~/.gc/cache/repos` is untouched.

The install needs `git`, `python3` (3.11+) and network access once. If it cannot
install, the doctor check fails with the reason, and the build continues without
that gate; the agent is told to say the gate did not run rather than claim it
passed.

## Run

Invocation is caller-selected, not a city default:

```sh
gc sling gc.run-operator <bead-id> --on ub-mode-build
```

The formula takes the standard `build-basic` variables (`artifact_root`,
`drain_policy`, `implementation_target`, `interaction_mode`, `push`, `open_pr`,
…). `drain_policy` is `separate` or `same-session`.

## Verify

```sh
./tests/verify.sh
```

Static checks: `pack.toml` parses, schema 2, imports the base pack; the skill
declares `name: ub-mode` with a description; the formula extends `build-basic`,
declares `[requires] formula_compiler`, has a catalog and methodology block, and
overrides the three steps; every `description_file` exists; the MIT license keeps
the upstream copyright line. When run inside a city that imports the pack it also
compiles the formula with `gc formula show ub-mode-build`.

## Provenance

Vendored from [`unclebob/ub-mode`](https://github.com/unclebob/ub-mode) at commit
`3da62bf3fcfd2034de41f30d920d2739e566171f` (MIT, © 2026 Robert C. Martin; see
`LICENSE`, kept verbatim).

The upstream skill is a modified copy: the description gained the build-step
trigger, and a "Tool locations in this pack" section was appended with the fixed
`~/.gc/cache/bin/<tool>` paths. Everything else is upstream text.

The three gate tools are separate upstream projects, cloned at run time by the
doctor checks, not vendored:

| Tool | Repo | Pinned commit |
| --- | --- | --- |
| crapper | `unclebob/crapper` | `fdd0c01387e4211c74b23c2cdd11c06d90883838` |
| dryer | `unclebob/dryer` | `ad371d460854b937039410d2c3889a4da94a753a` |
| mutator | `unclebob/mutator` | `264dc965fa79b60942018143e7e323b517635a69` |

Known upstream issue to keep in mind: mutator's `bugs/python-tests-run-with-mutators-virtualenv.md`
says Python tests run inside mutator's own virtualenv, which can distort results
in a project with a different one.

## Decisions

1. **Naming.** Pack `ub-mode`; skill frontmatter `name = "ub-mode"`, which is the
   name agents see. The skill sink may key it `ub-mode.ub-mode` (gc derives the key
   from the binding plus the skill directory); that is cosmetic and harmless for
   providers that register by frontmatter name.
2. **Scope.** Skill plus a `build-basic`-derived formula plus doctor checks. No
   agents of its own: the formula reuses the city's `design-author` and
   implementation roles. If those role names change, the formula needs the same
   change.
3. **Packaging.** One pack directory in this repo; import by URL; no
   `registry.toml`, Makefile or CI.
4. **Tools.** Cloned by the doctor checks into a fixed `~/.gc/cache` layout, not
   installed inside the pack checkout, and never a build precondition.
5. **License.** MIT, vendored verbatim with provenance recorded here.
