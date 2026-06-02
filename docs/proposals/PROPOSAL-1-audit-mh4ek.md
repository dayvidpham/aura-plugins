---
name: PROPOSAL-1 — mh4ek coverage audit (26 Python C-* constraints ported to Go?)
status: Phase 6 RATIFIED. 3-axis ACCEPT consensus (Phase 4) + Phase 5 plan-UAT ACCEPT with verdict-vocabulary expansion (4th verdict 'untested') applied in place. Per-audit execution plan refining PROPOSAL-2 §5.5 (Coverage). → Phase 7-9 execution.
references:
  parent_audit: aura-plugins-mh4ek
  elicit: aura-plugins-vnb2l
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.5 Coverage audits"
  type: coverage
  wave: 1
  cascade: out-of-cascade (does NOT block ow0pq)
  ure_answers: "aura-plugins-vnb2l (latest comment — Q6 done-criteria, Q7 attention)"
  uat: "aura-plugins-vnb2l (Phase 5 UAT comment — 4th verdict 'untested')"
  source_of_truth: "aura-plugins/scripts/aura_protocol/constraints.py::RuntimeConstraintChecker"
  go_target: "pasture/internal/temporal/ActivityCheckConstraints + dependents"
---

# PROPOSAL-1 — `mh4ek` coverage audit

> Delta over PROPOSAL-2 §5.5. The Coverage type template (Cv1–Cv5 /
> Cv-A1/Cv-A2/Cv-A3) is **referenced, not restated** — read §5.5. This doc locks
> the URE answers, the Phase-5 UAT 4-verdict expansion, and the deliverable schema.

## §0. Provenance + revision log

- **Type template:** PROPOSAL-2 §5.5 (Coverage). Standard URE/UAT: §4.
- **URE answers (locked):** `aura-plugins-vnb2l`, latest comment.
- **Out-of-cascade:** does NOT block `ow0pq` / `jbnx3`. Wave-1 for parallelism.
- **Plan, not audit.** The cross-reference is Phase 9 work.

| Stage | Outcome | Changes |
|---|---|---|
| Phase 4 | 3-axis ACCEPT (consensus) | Cosmetic minors only; left as-is. |
| Phase 5 UAT | **ACCEPT + vocab expansion** | User verbatim (`vnb2l`): "Distinct untested verdict (4th category)". §3 vocabulary expanded from 3 → **4 verdicts**: `ported / missing / divergent / untested`. Separates test-debt (`untested`) from impl-debt (`missing`). Applied to §3/§4/§5/§6/§8. |

## §1. Objective

Verify that **every** Python `RuntimeConstraintChecker` C-* constraint is both
**present in Go AND exercised by a Go test** — and explicitly distinguish
present-but-untested (`untested`), absent (`missing`), and semantically
divergent (`divergent`) — so the post-deprecation Go validator's parity gaps are
separated into test-debt vs impl-debt.

## §2. Scope — source vs target

- **Source of truth (Cv2):** `aura-plugins/scripts/aura_protocol/constraints.py`
  `::RuntimeConstraintChecker` — canonical list of **26 C-* IDs** (per
  `aura-plugins/CLAUDE.md`). The enumeration step **confirms the count** (a
  coverage audit establishes its own denominator; if the live source shows ≠26,
  the table records the true count and notes the discrepancy).
- **Target:** Go `pasture/internal/temporal/ActivityCheckConstraints` + dependents.

## §3. Verdict vocabulary (Phase-5 UAT — 4 verdicts)

`ported` / `missing` / `divergent` / **`untested`**. Exactly one per constraint.

- **`ported`** — present in Go **AND** a Go test exercises it.
- **`untested`** — present in Go but **no Go test** exercises it (test-debt).
- **`missing`** — absent from Go (impl-debt).
- **`divergent`** — present in Go but returns semantically different results
  from Python for the same input.

(The old "present-but-untested → `missing` with a nuance note" collapsing is
**replaced** by the first-class `untested` verdict.)

## §4. Methodology (execution steps for Phase 9)

1. **Enumerate** the C-* IDs from `constraints.py::RuntimeConstraintChecker`
   (the canonical denominator). Confirm count.
2. For **each** constraint: locate its Go implementation path and the Go test
   that exercises it; assign one of the **4** §3 verdicts.
3. **Treat all 26 uniformly** (URE Q7 — no constraint pre-flagged).
4. **Gap-handling (Cv4) — routed by verdict:** for every non-`ported` constraint
   file a `bd` task `discovered-from:aura-plugins-mh4ek` under `cmvu5` §4
   (`aura:residual`):
   - `untested` → **"write test"** task (test-debt).
   - `missing` → **"write implementation"** task (impl-debt).
   - `divergent` → **"reconcile divergence"** task.
   **Do not implement fixes during the audit** — audit is read-and-verdict only.

## §5. Done criteria (URE Q6 — Cv5 FULL, default accepted)

Done when **all 26** (or the confirmed true count) constraints are verdicted from
the 4-verdict set **AND** every non-`ported` constraint (`missing` / `divergent`
/ `untested`) has a follow-up `bd` task filed. Not "verdicted-only with deferred
gap-filing."

## §6. Gap / residual policy

Non-`ported` → `bd` tasks (`discovered-from:aura-plugins-mh4ek`, filed under
`cmvu5` §4, `aura:residual`), routed per §4.4 (test-debt / impl-debt /
divergence). Recorded in the coverage table's `gap-task-id` column.

## §7. Verbatim-attention (URE Q7 — none)

No constraint pre-flagged. All treated uniformly.

## §8. Deliverable

`docs/audits/mh4ek-constraint-coverage.md` containing:

- **Cv-A1 coverage table** — one row per constraint:
  `[item-id | source-canonical | go-impl-path | tested? | verdict (4-set) | gap-task-id?]`.
  (The `tested?` column + the `untested` verdict make test-debt explicit.)
- **Cv-A2:** every constraint from the source list appears **exactly once**.
- **Cv-A3:** every `missing` / `divergent` / `untested` row has a non-empty
  `gap-task-id`.

## §9. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.5 Cv-A1 / Cv-A2 / Cv-A3 (Cv-A3 now spans the
3 non-`ported` verdicts). **No R-row verdict line** (out-of-cascade).

## §10. Phase 10 (code review) applicability

**SKIP** — rationale on the slice: "enumerate-and-verdict, no interpretive
judgment beyond Phase 11 UAT." Gap *fixes* are deferred to follow-up tasks
(separately reviewed). **Escalation:** if a `ported`/`divergent`/`untested` call
needs non-trivial semantic judgment, promote that slice to full Phase 10 and
notify team-lead first.

## §11. Open questions for UAT

Resolved at Phase 5 UAT (ACCEPT + the 4-verdict expansion). No open items.
