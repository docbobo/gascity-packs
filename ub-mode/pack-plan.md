# Plan: a Methodology pack for ub-mode

## The core constraint first

A pack's skills land in the shared `.agents/skills/` directory and are visible to every agent running in that cwd. So "only design/dev clients get it" cannot be enforced at skill-discovery level. It can only be enforced at the **prompt/formula level**: the skill is installed, but only the design/dev prompts and build steps tell the agent to use it. Everything below assumes that. If you want hard isolation (other agents literally cannot read the skill), that needs a separate cwd/settings dir per agent – a bigger change, not a pack.

## Objective

Ship a reusable pack that (a) vendors the ub-mode skill, (b) binds it to design and development work through the build formulas, and (c) leaves review/other lanes uninstructed. Publishable, versioned, importable.

The pack lives in the already-created multi-pack repo `docbobo-gascity-packs`, in the `ub-mode/` pack directory.

## Update: scope expanded to the whole user-facing build family

The first cut shipped only `ub-mode-build` (extends `build-basic`). The pack now
ships one variant per user-facing build mode: `ub-mode-build` (from scratch),
`ub-mode-build-from-requirements`, `ub-mode-build-from-plan`,
`ub-mode-build-from-decompose` and `ub-mode-build-from-convoy`. Each extends its
matching `build-*` base and overrides the `plan` step (when the base has one) plus
`implement` and `implement-same-session`. The variant id is threaded into the plan
artifact front matter through the `ub_mode_formula` variable. Everything else in
this plan still holds; the decisions below describe the single `build-basic` case
and read as the first variant of the family.

## Decisions to make (with recommendations)

**1. Pack shape.** Methodology pack. [decided]
Chosen: **methodology pack** – skill + a build formula (or formula fragment) + README. A skills-only pack has no binding, so it doesn't satisfy "others don't."

**2. Home.** Own multi-pack repo. [decided]
The home is the existing `docbobo-gascity-packs` repo. Keep it minimal: a plain multi-pack repo with one directory per pack plus a top-level `README.md`. No `registry.toml`, `Makefile`, `validate_registry.py`, `scripts/`, `.github/`, or CI – packs are imported directly by URL (see Phase 5), so there is no registry to publish into. (Repo currently holds only the empty `ub-mode/` dir plus a fresh git init.)

**3. Gating mechanism.** Three options (A chosen):
- **A. Step-description injection** – pack ships a `ub-mode-build` formula that `extends = ["build-basic"]`, targets the city's existing `design-author` and `implementation-worker` roles, and whose step `description_file`s say "apply ub-mode." Light, no duplicate agents. Couples to the city's agent names.
- **B. Pack-owned agents + formula** – superpowers model: ship `ub-mode.design-author` and `ub-mode.implementation-worker` agents, a formula targeting them, and the skill. Portable, role-gated, but duplicates agents and drifts from the city's own.
- **C. Template fragment only** – ship a `ub-mode.template.md` fragment; consuming city includes it in its agent prompts. Smallest pack, but requires city-side edits and no formula.

Chosen: **A** – step-description injection for this city now. If reuse across cities later needs portability, upgrade to **B**.

**`build-base` vs `build-basic`:** `build-base` is the abstract 11-step contract (`internal = true`); `build-basic` extends it and fills every step with concrete agents/checks. `bmad`/`gstack` extend `build-base` because they *replace* the whole methodology. To *add* ub-mode to the default build while leaving review/publish untouched, extend `build-basic` and override only the design/implementation steps. `extends` replaces a step whole, so each override restates its `needs`, `condition` and `metadata`.

**4. Companion tools.** The skill tells agents to run `crapper`, `dryer`, `mutator` (named in the upstream ub-mode README: github.com/unclebob/crapper, /dryer, /mutator, all MIT). They are **Python tools, not Go**: you `git clone` each one and run its `./crapper` / `./dryer` / `./mutator` launcher. The first run creates a `.venv` and installs itself (needs `python3` with `venv`). `mutator` needs crapper checked out next to it (`../crapper`). They run from the project root and write to `.metrics/`. If they are absent, the agent can't comply.
Decided: **doctor installs.** One check per tool (`doctor/crapper/run.sh`, `doctor/dryer/run.sh`, `doctor/mutator/run.sh`). Each one:
- passes if the tool is present and runnable;
- otherwise `git clone`s it into `~/.gc/cache/ub-mode/<tool>` (fixed path, no env-var override, so the hardcoded paths in the skill stay valid), keeping `crapper` and `mutator` as siblings, then runs it once to create the `.venv`;
- writes a launcher at `~/.gc/cache/bin/<tool>` (a small script that `exec`s the real launcher, avoiding the untested symlink case);
- pins a commit per tool (recorded in the script) so installs are reproducible, and fails with a clear message if `git` or `python3` is missing.

Why `~/.gc/cache`: gc only uses `~/.gc/cache/repos` and `~/.gc/cache/registry-release-repos`, so a sibling `ub-mode/` and `bin/` are untouched and survive imports; it also keeps the tools out of the global `~/.local/bin`. The downside is it is **not on `PATH`**, so the skill and the formula step descriptions call the tools by **absolute path** (`~/.gc/cache/bin/crapper`), not by bare name. Do not vendor the tools into the pack. Also soften the skill's tool references to "if installed" so a missing tool doesn't block a build. `uml-viewer` is a fourth upstream tool; ub-mode doesn't require it, so skip it.

**5. Naming.** Pack `ub-mode` → skill key `ub-mode.ub-mode` (redundant). Alternative pack name `ub` → `ub.ub-mode`.
Decided: pack name **`ub-mode`**, skill frontmatter `name = "ub-mode"` in `skills/ub-mode/SKILL.md` (the provider registers it by frontmatter name, so that is the name agents see). The redundant `ub-mode.ub-mode` key in the ownership file is cosmetic. Confirm the real sink path at Phase 6.

**6. Licensing.** ub-mode is MIT, © 2026 Robert C. Martin. Decided: ship under **MIT** – vendor the upstream `LICENSE` verbatim at `ub-mode/LICENSE`, keep the upstream copyright line, add a provenance note (source URL + pinned commit). The skill file is a *modified* copy (tool references softened to "if installed"), so record that in the README ("vendored from unclebob/ub-mode@<commit>; tool references adjusted") rather than passing it off as verbatim.

## Work breakdown (bead-sized)

**Phase 0 – Decide and scaffold**
- Confirm decisions 1–4 above; record in the pack README as "Decisions."
- Scaffold repo-level: `README.md` only (no registry/Makefile/CI – see decision 2).
- Scaffold the pack dir `ub-mode/`: `pack.toml`, `README.md`, `skills/`, `formulas/`, `assets/workflows/`, `doctor/`, `tests/`, `LICENSE`.

**Phase 1 – Vendor the skill**
- Copy `SKILL.md` from upstream into `skills/ub-mode/SKILL.md`.
- Copy upstream `LICENSE`; add a provenance header (URL + commit hash).
- Add a short "Companion tools" section noting crapper/dryer/mutator are optional and where to get them, plus a `doctor/<tool>/run.sh` check per tool.

**Phase 2 – Pack metadata**
- `pack.toml`: name, version `0.1.0`, description, metadata. Import the base pack by URL (see Phase 5); `source = "../gascity"` only works when the pack is a sibling of `gascity/`, which it is not in this repo.
- README: what it does, how to import, how to run, gating model, tool caveat.

**Phase 3 – Wiring**
- Add `formulas/ub-mode-build.formula.toml` extending `build-basic`, with `[catalog]` and a `[metadata.gc.methodology]` block; override only the `plan` (design) and `implement`/`implement-same-session` steps. Reusing the whole `build-basic` skeleton means we don't reinvent agent routing, checks or the review/publish tail.
- Step description files (`assets/workflows/ub-mode-build/<step>.md`) that instruct design/implementation steps to apply ub-mode; leave review/verify steps without it.
- If going with option B, add `agents/ub-mode.design-author/` and `agents/ub-mode.implementation-worker/` with `agent.toml` + `prompt.template.md`, and point the formula's `gc.run_target` at them.

**Phase 4 – Tests / checks**
- `tests/verify.sh`: pack.toml parses; skill file exists and is non-empty; formula parses and extends `build-basic`; every referenced `description_file` exists; license present.
- Follow the formulas skill: validate with `gc formula show ub-mode-build` (new formulas declare `[requires] formula_compiler`, not the deprecated `contract = "graph.v2"`).
- Invocation is caller-selected, not a config default: `gc sling gc.run-operator <bead-id> --on ub-mode-build`. Document that line in the README and use it in Phase 6.
- Optional: a script that greps the installed skill symlink after import.
- Run `tests/verify.sh` directly (there is no Makefile); document that command in the README.

**Phase 5 – Publish**
- Commit/push `docbobo-gascity-packs`; tag the release `ub-mode/v0.1.0` (or the repo's chosen scheme); release notes carry the upstream commit and the tool caveat.
- No registry step: with no `registry.toml`, the pack is consumed by URL (`https://github.com/docbobo/gascity-packs/tree/main/ub-mode`). The base pack imports as `source = "https://github.com/gastownhall/gascity-packs/tree/main/gascity"` – the form used throughout the gc docs. Verify at build time that `extends = ["build-basic"]` resolves through a URL-imported pack.

**Phase 6 – Import and verify in this city**
- `gc import add <url> --name ub-mode --version ^0.1.0` (verify exact syntax when we get there).
- Confirm the skill symlink for the active provider sink (claude → `.claude/skills/ub-mode`; codex/pi → `.agents/skills/ub-mode`) and the `.gc-skill-ownership.json` entry. Decide the skill-key question in decision 5 deliberately.
- Run a design or dev build with the ub-mode formula; confirm review steps don't mention ub-mode.
- (No PR – self-owned repo; record the commit hash instead.)

## Acceptance criteria

- Pack imports cleanly; the skill is discoverable as `ub-mode` (ownership file may key it `ub-mode.ub-mode`).
- A design/dev build runs the ub-mode steps and the review step does not.
- Doctor installs a missing companion tool; if the install fails (no `git`/`python3`, no network) it warns and the build continues.
- `tests/verify.sh` passes; license and provenance are present.
- README states the gating limitation plainly.

## Risks / open questions

- **Hard isolation is impossible** in a shared cwd. Confirm the "others don't" requirement means "not instructed," not "cannot read."
- **Tool dependency**: resolved by decision 4 (doctor clones and bootstraps crapper/dryer/mutator under `~/.gc/cache`). Still open: pinned commits per tool, and confirming the launchers run correctly when invoked by absolute path from an arbitrary cwd.
- **Absolute tool paths**: `~/.gc/cache/bin` is not on `PATH`, so the skill text and step descriptions call `~/.gc/cache/bin/<tool>`. Decided: no env-var override, so those paths are always correct.
- **Formula coupling**: option A assumes the city's `design-author`/`implementation-worker` role names. If those change, the formula breaks. Option B avoids that at the cost of duplicate agents.
- **Import resolution**: `../gascity` only works if the pack is a sibling of `gascity/`. In this repo it isn't, so the pack imports the base pack by URL: `https://github.com/gastownhall/gascity-packs/tree/main/gascity`. Verify `extends = ["build-basic"]` resolves through a URL import at build time.
- **Skill registration**: resolved – frontmatter `name = "ub-mode"` (decision 5). The ownership file may still list `ub-mode.ub-mode`; that is cosmetic.

Still to confirm with a real import (Phase 6): how a URL-imported pack's skills land in the sink, inferred so far from the core pack's ownership json.

## Status

Phases 0–4 done and verified against a scratch city (`gc init --template gascity`,
pack imported by path): the formula compiles through the URL-imported `gascity`
base pack (37 steps), `plan` and `implement` resolve to the ub-mode prompts while
`plan-review` stays inline `build-basic` text, the skill lands as
`ub-mode.ub-mode -> ub-mode/skills/ub-mode`, and `gc doctor` reports
`ub-mode:crapper|dryer|mutator` green after installing each pinned checkout.

Left: Phase 5 (commit and push; the repo has no commits yet) and Phase 6 (import
by URL into the real city and run a live build).
