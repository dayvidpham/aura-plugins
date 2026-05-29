---
name: PROPOSAL-1 — mh4ek coverage audit (26 Python C-* constraints ported to Go?)
status: Phase 3 PROPOSAL. Per-audit execution plan refining PROPOSAL-2 §5.5 (Coverage) with the URE answers locked on the ELICIT task. Submitted to the 3-reviewer cycle (correctness / coverage / elegance). ACCEPT consensus → batched Phase 5 UAT.
references:
  parent_audit: aura-plugins-mh4ek
  elicit: aura-plugins-vnb2l
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.5 Coverage audits"
  type: coverage
  wave: 1
  cascade: out-of-cascade (does NOT block ow0pq)
  ure_answers: "aura-plugins-vnb2l (latest comment — Q6 done-criteria, Q7 attention)"
  source_of_truth: "aura-plugins/scripts/aura_protocol/constraints.py::RuntimeConstraintChecker"
  go_target: "pasture/internal/temporal/ActivityCheckConstraints + dependents"
---

# PROPOSAL-1 — `mh4ek` coverage audit

> Delta over PROPOSAL-2 §5.5. The Coverage type template (Cv1–Cv5 /
> Cv-A1/Cv-A2/Cv-A3) is not restated — read §5.5. This locks URE answers,
> methodology, and the deliverable schema.

## §0. Provenance

- **Type template:** PROPOSAL-2 §5.5 (Coverage). Standard URE/UAT: PROPOSAL-2 §4.
- **URE answers (locked):** `aura-plugins-vnb2l`, latest comment.
- **Out-of-cascade:** does NOT block `ow0pq` / `jbnx3` closure. Runs in Wave 1
  for parallelism only. Defense-in-depth / post-deprecation parity confirmation.
- **Plan, not audit.** The 26-way cross-reference is Phase 9 work.

## §1. Objective

Verify that **every** Python `RuntimeConstraintChecker` C-* constraint is both
**present in Go AND exercised by a Go test** — and flag any that are `missing`
or `divergent` — so the post-deprecation Go validator has confirmed parity with
the Python source of truth.

## §2. Scope — source vs target

- **Source of truth (Cv2):** `aura-plugins/scripts/aura_protocol/constraints.py`
  `::RuntimeConstraintChecker` — canonical list of **26 C-* IDs** (per
  `aura-plugins/CLAUDE.md`). The enumeration step **confirms the count** (a
  coverage audit must establish its own denominator; if the live source shows
  ≠26, the table records the true count and notes the discrepancy).
- **Target:** Go `pasture/internal/temporal/ActivityCheckConstraints` + its
  dependents.

## §3. Verdict vocabulary (locked — Cv1 default)

`ported` / `missing` / `divergent`. Exactly one per constraint.

- `ported` requires **both** (Cv3): (a) the constraint exists in Go, **and**
  (b) a Go unit/integration test exercises it.
- `divergent` if the Go validator returns semantically different results from
  Python for the same input.
- `missing` if absent from Go (or present but untested → `missing` on the
  test-coverage limb, recorded with that nuance).

## §4. Methodology (execution steps for Phase 9)

1. **Enumerate** the C-* IDs from `constraints.py::RuntimeConstraintChecker`
   (the canonical denominator). Confirm count.
2. For **each** constraint: locate its Go implementation path and the Go test
   that exercises it; assign one §3 verdict.
3. **Treat all 26 uniformly** (URE Q7 — no constraint pre-flagged for deeper
   dive).
4. **Gap-handling (Cv4):** for every `missing` / `divergent`, file a `bd` task
   `discovered-from:aura-plugins-mh4ek` under `cmvu5` §4 (discoveries). **Do not
   implement fixes during the audit** — audit is read-and-verdict only.

## §5. Done criteria (URE Q6 — Cv5 FULL, default accepted)

Done when **all 26** (or the confirmed true count) constraints are verdicted
`ported`/`missing`/`divergent` **AND** every `missing`/`divergent` has a
follow-up `bd` task filed. Not "verdicted-only with deferred gap-filing."

## §6. Gap / residual policy

`missing` / `divergent` → `bd` tasks (`discovered-from:aura-plugins-mh4ek`,
filed under `cmvu5` §4 discoveries, `aura:residual` label). Recorded in the
coverage table's `gap-task-id` column.

## §7. Verbatim-attention (URE Q7 — none)

No constraint pre-flagged. All treated uniformly.

## §8. Deliverable

`docs/audits/mh4ek-constraint-coverage.md` containing:

- **Cv-A1 coverage table** — one row per constraint:
  `[item-id | source-canonical | go-impl-path | tested? | verdict | gap-task-id?]`.
- **Cv-A2:** every constraint from the source list appears **exactly once**.
- **Cv-A3:** every `missing`/`divergent` row has a non-empty `gap-task-id`.

## §9. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.5 Cv-A1 / Cv-A2 / Cv-A3. **No R-row verdict
line** (out-of-cascade; confirmed in ELICIT in-use overrides).

## §10. Phase 10 (code review) applicability

**SKIP** — rationale to be recorded on the slice: "enumerate-and-verdict, no
interpretive judgment beyond Phase 11 UAT." The audit reads Python + Go +
tests and records a verdict; it writes no production code (gap *fixes* are
deferred to follow-up tasks, separately reviewed). **Escalation rule:** if the
`ported`/`divergent` call requires non-trivial semantic judgment that a reviewer
should sanity-check (e.g. a subtly divergent validator), promote that slice to
full Phase 10 and notify team-lead first.

## §11. Open questions for UAT

None material — defaults locked at §5.5 + the two captured answers (Cv5 full;
no pre-flagged constraints). The denominator-confirmation in §4.1 is a
methodology note, not an open decision.
