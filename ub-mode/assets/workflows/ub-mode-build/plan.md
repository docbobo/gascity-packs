# Plan: design under ub-mode

Write the implementation plan, applying the `ub-mode` skill. Load it first
(`/ub-mode`, or read the `ub-mode` skill). This stage is where the design
decisions get made, so the ub-mode design rules apply now, not at review time.

## ub-mode requirements for this artifact

- **Model the domain.** Make illegal states impossible in the structure you
  propose. Name the domain terms you use.
- **Boundary discipline.** Say where untrusted data is parsed and validated. Inside
  the boundary, the plan should trust it.
- **Type system discipline.** Prefer types that cannot express the wrong value.
  Never plan to silence the compiler.
- **Separate before serializing shared state.** If two parts do not need the same
  mutable thing, plan separate state; if they do, plan one writer and enforce it in
  the structure.
- **Foundational thinking.** Get the data shape right before planning logic. Do
  first whatever helps every later stage.
- **Redesign from first principles.** Do not bolt the requirement onto the old
  design. Ask what you would have built if it had been there from the start, then
  deliver it in pieces.
- **Subtract before you add.** Remove complexity before proposing anything new.
- **Sequence work into verifiable units.** The plan's decomposition hints must be
  checkable one unit at a time.
- **TDD, up front.** Each proposed unit names the test that will fail first.

Do not run crapper, dryer or mutator at this stage; there is no code yet. They
run in the implementation stage.

## Artifact contract

Create the implementation plan at the path recorded on the workflow root bead
as `gc.build.plan_path` (fallback `gc.var.plan_path`). The artifact must be
Markdown with YAML front matter, not JSON. Its front matter must declare
`schema: gc.build.plan.v1`, the workflow id/formula, the methodology pack/name,
the producer formula/stage/attempt, `status`, and `trace` with upstream and
coverage entries. Include a Markdown coverage table whose ID/status pairs
exactly match `trace.coverage`.
The validator only recognizes a Markdown table with an `ID` column and a
`Status` column. Use this shape:

| ID | Status |
| --- | --- |
| REQ-001 | covered |

Use mapping objects for front matter; do not use scalar shortcuts such as
`workflow: {{ub_mode_formula}}`. The top-level YAML shape must be:

- `schema: gc.build.plan.v1`
- `workflow: {id: <workflow-root-id>, formula: {{ub_mode_formula}}}`
- `methodology: {pack: ub-mode, name: {{ub_mode_formula}}}`
- `producer: {formula: {{ub_mode_formula}}, stage: plan, attempt: <positive integer>}`
- `status: approved` or another schema-allowed status
- `trace: {upstream: [...], coverage: [...]}`

Trace front matter must use the validator shape exactly:

- `trace.upstream[]` entries must include `path` and `hash`; do not use
  `id`/`title`/`type` entries as the upstream shape.
- For the requirements artifact, use its recorded path and a scheme-qualified
  hash such as `sha256:<digest>` or `git:<revision>`.
- If an upstream entry lists `ids`, every listed id must appear exactly once in
  `trace.coverage` and in the Markdown coverage table with the same status.
- Coverage statuses are not artifact statuses. Use `covered` for satisfied
  requirements; do not use `approved` in `trace.coverage[].status` or the
  Markdown coverage table.

Ground the plan in the generated requirements and repository conventions.
Include the required schema sections:

- Summary
- Current System
- Proposed Implementation
- Non-Goals
- Verification

Record the implementation plan path on the workflow root bead before closing.
Use `gc bd update "<workflow-root-id>" --set-metadata "gc.build.plan_path=<absolute path>"`.
Do not use `gc bd update --metadata 'key=value'`; `--metadata` only accepts a JSON
object.
Before closing this step, set the claimed step outcome with
`gc bd update "<claimed-step-id>" --set-metadata "gc.outcome=pass"`, then close
with `gc bd close "<claimed-step-id>" --reason "<concise reason>"`. Do not pass
`--metadata` or `--set-metadata` to `gc bd close`.

Artifact validation: this stage is gated by the pack-owned `build-artifact-valid.sh` check, which validates the artifact recorded at `gc.build.plan_path` (fallback `gc.var.plan_path`) against schema `gc.build.plan.v1`. On repair attempts (`gc.attempt` greater than 1), read the validator errors from `gc.attempt_log` on the validation loop control bead (the dependent of this step bead) and repair the artifact in place instead of rewriting it. Two bounded repair attempts follow the first failure; exhausting them closes this stage with `gc.outcome=fail` and machine-readable validation errors that block downstream stages. Never ask questions in headless mode; record unresolved ambiguity inside the artifact.
