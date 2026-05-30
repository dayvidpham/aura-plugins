---
audit: aura-plugins-mh4ek
type: coverage
wave: 1
cascade: out-of-cascade
ratified_proposal: docs/proposals/PROPOSAL-1-audit-mh4ek.md
meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md §5.5
source_of_truth: scripts/aura_protocol/constraints.py::RuntimeConstraintChecker
go_target: pasture/internal/temporal/ (ActivityCheckConstraints + dependents)
executed: 2026-05-29
status: complete
---

# Coverage Audit — `mh4ek` C-* Constraint Coverage

## §1. Scope and Count Discrepancy

**Source of truth:** `scripts/aura_protocol/constraints.py::RuntimeConstraintChecker`

**True constraint count (enumerated from SoT):** **27 unique C-* IDs** with runtime check methods in `constraints.py`.

**Count discrepancy (notable findings):**

| Source | Count | Notes |
|---|---|---|
| `constraints.py` docstring | 22 | Stale; not updated as constraints were added |
| `CLAUDE.md` / audit task description | 26 | Also stale |
| **Actual unique C-* IDs in `constraints.py`** | **27** | **Enumerated from `constraint_id=` literals — canonical denominator** |
| `CONSTRAINT_SPECS` catalog in `types.py` | 28 | Includes `C-actionable-errors` which has NO `check_*` method in `constraints.py` |

**Discrepancy summary:**
- The docstring and CLAUDE.md both undercount. The live SoT has **27 constraints** with validators.
- `C-actionable-errors` appears in the `CONSTRAINT_SPECS` catalog (`types.py`) but has **no `check_actionable_errors()` method** in `constraints.py`. It is documentation-only / enforcement-by-convention in Python.
- The audit table uses **27** as the canonical denominator (from `constraints.py::RuntimeConstraintChecker`). `C-actionable-errors` is included as an **addendum row** (#28) to record its catalog-only status. The tally below reflects the 27-denominator.

## §2. Verdict Vocabulary (4-set, ratified at UAT)

- `ported` — present in Go AND a Go test exercises it
- `untested` — present in Go but NO Go test exercises it (test-debt)
- `missing` — absent from Go runtime validators (impl-debt)
- `divergent` — present in Go but semantically different results from Python for the same input

## §3. Key Structural Finding

The Go `ActivityCheckConstraints` (in `pasture/internal/temporal/activities.go`) delegates entirely to `EpochStateMachine.ValidateAdvance()` (in `state_machine.go`). `ValidateAdvance()` implements:

1. Phase transition table lookup (not a named C-* constraint)
2. Consensus gate → partially covers **C-review-consensus** (tested)
3. Blocker gate → partially covers **C-worker-gates** blocker aspect (tested)

All C-* constraint IDs appear in `pasture/internal/codegen/` as **schema metadata** for code generation (SKILL.md generation, context injection). The codegen package is NOT a runtime constraint validator — it defines constraint specs for generating documentation and prompts.

**Audit scope caveat:** This audit targets `pasture/internal/temporal/ActivityCheckConstraints + dependents` — the Temporal workflow runtime checker. Several Python validators check bd-task structure (dep-direction, slice-leaf-tasks, blocker-dual-parent, ure-verbatim) that in Go would be enforced in the CLI layer (`internal/tasks`, `pasture task` commands) — outside the temporal checker's dependency graph. The `missing` verdicts below mean "absent from the `ActivityCheckConstraints` runtime checker," not necessarily "absent from Go entirely." The gap tasks filed are scoped accordingly: implement validators in the temporal package. If some constraints are better enforced at the CLI layer, the gap-fix implementer should assess that during implementation.

**Result:** 24 of 27 C-* runtime validators from the canonical SoT are **absent** from Go `internal/temporal/`. One (`C-review-consensus`) is `ported`. One (`C-worker-gates`) is `divergent` (blocker gate present and tested, quality gates absent). One (`C-review-binary`) is `divergent` (enforced via Go type system rather than explicit runtime check). See §4 for full table.

`C-actionable-errors` (catalog-only, no Python runtime validator) is also `missing` in Go.

## §4. Cv-A1 Coverage Table

One row per constraint. `source-canonical` = Python method(s) in `constraints.py`. `go-impl-path` = Go location of equivalent logic (or `—` if absent). `tested?` = whether a Go test in `internal/temporal/*_test.go` exercises that logic.

| # | item-id | source-canonical | go-impl-path | tested? | verdict | gap-task-id |
|---|---|---|---|---|---|---|
| 1 | C-actionable-errors | *(catalog-only — no check_actionable_errors() in constraints.py)* | — | No | missing | aura-plugins-vxvt1 |
| 2 | C-agent-commit | `check_agent_commit()` L1008 | `internal/codegen/` (schema metadata only, not runtime) | No | missing | aura-plugins-rfqkm |
| 3 | C-audit-dep-chain | `check_audit_trail()` L652 (triggers `C-audit-dep-chain` violations) | — | No | missing | aura-plugins-c91i2 |
| 4 | C-audit-never-delete | `check_audit_trail()` L652 (triggers `C-audit-never-delete` violations) | — | No | missing | aura-plugins-8mj6v |
| 5 | C-autonomous-progression | `check_autonomous_progression()` L1483 | — | No | missing | aura-plugins-nakvo |
| 6 | C-blocker-dual-parent | `check_blocker_dual_parent()` L782 | — | No | missing | aura-plugins-p2nq2 |
| 7 | C-clean-review-exit | `check_clean_review_exit()` L1441 | — | No | missing | aura-plugins-gxdlh |
| 8 | C-dep-direction | `check_dep_direction()` L472 | — | No | missing | aura-plugins-8giwl |
| 9 | C-followup-leaf-adoption | `check_followup_leaf_adoption()` L1135 | — | No | missing | aura-plugins-fd1g4 |
| 10 | C-followup-lifecycle | `check_followup_lifecycle()` L1101 | `internal/codegen/` (schema metadata only) | No | missing | aura-plugins-6r3hx |
| 11 | C-followup-timing | `check_followup_timing()` L977 | — | No | missing | aura-plugins-nzp41 |
| 12 | C-frontmatter-refs | `check_frontmatter_refs()` L1035 | `internal/codegen/` (schema metadata only) | No | missing | aura-plugins-3gxlt |
| 13 | C-handoff-skill-invocation | `check_handoff_required()` L584 | — | No | missing | aura-plugins-g3s5o |
| 14 | C-integration-points | `check_integration_points()` L1272 | — | No | missing | aura-plugins-gtfpm |
| 15 | C-max-review-cycles | `check_max_review_cycles()` L1348 | — | No | missing | aura-plugins-lwm3m |
| 16 | C-proposal-naming | `check_proposal_naming()` L854 | — | No | missing | aura-plugins-nnnzg |
| 17 | C-review-binary | `check_review_binary()` L758 | Go `VoteType` typed enum in `internal/types/` prevents structurally invalid vote values at compile time; `RecordVote()` validates axis via `axis.IsValid()`. Same constraint intent enforced via different mechanism (type system vs string-check) — different semantics for callers passing raw strings | No (no explicit runtime string-validator with this C-* ID) | divergent | aura-plugins-apz6j |
| 18 | C-review-consensus | `check_review_consensus()` L423 | `EpochStateMachine.ValidateAdvance()` — consensus gate L213: `consensusGated[key] && !sm.HasConsensus()` in `state_machine.go` | Yes | ported | — |
| 19 | C-review-naming | `check_review_naming()` L877 | — | No | missing | aura-plugins-41gqs |
| 20 | C-severity-eager | `check_severity_tree()` L522 (p10 branch) | — | No | missing | aura-plugins-l3dxz |
| 21 | C-severity-not-plan | `check_severity_tree()` L522 (p4 branch) | — | No | missing | aura-plugins-1ag61 |
| 22 | C-slice-leaf-tasks | `check_slice_has_leaf_tasks()` L901 | `internal/codegen/` (schema metadata only) | No | missing | aura-plugins-oeufm |
| 23 | C-slice-review-before-close | `check_slice_review_before_close()` L1300 | — | No | missing | aura-plugins-l0w6v |
| 24 | C-supervisor-explore-ephemeral | `check_supervisor_explore_ephemeral()` L1238 | `internal/codegen/` (schema metadata only) | No | missing | aura-plugins-1w2hb |
| 25 | C-supervisor-no-impl | `check_supervisor_no_impl()` L1069 | `internal/codegen/` (schema metadata only) | No | missing | aura-plugins-kfp41 |
| 26 | C-ure-verbatim | `check_ure_verbatim()` L926 | — | No | missing | aura-plugins-hyceu |
| 27 | C-vertical-slices | `check_vertical_slices()` L1380 + `check_role_ownership()` L721 | `internal/codegen/` (schema metadata only); `check_role_ownership()` checks role string validity only | No | missing | aura-plugins-gmmyz |
| 28 | C-worker-gates | `check_blocker_gate()` L626 + `check_worker_gates()` L1183 | `EpochStateMachine.ValidateAdvance()` — blocker gate L226: `blockerGated[key] && sm.state.BlockerCount > 0` in `state_machine.go`; quality gates (has_todos, tests_pass, typecheck_pass) ABSENT | Yes (blocker gate only) | divergent | aura-plugins-fkmwt |

## §5. Verdict Tally

Canonical denominator: **27** (from `constraints.py::RuntimeConstraintChecker`). Addendum row (`C-actionable-errors`) not counted in canonical tally.

| Verdict | Count (of 27) | IDs |
|---|---|---|
| `ported` | **1** | C-review-consensus |
| `untested` | **0** | — |
| `missing` | **24** | C-actionable-errors†, C-agent-commit, C-audit-dep-chain, C-audit-never-delete, C-autonomous-progression, C-blocker-dual-parent, C-clean-review-exit, C-dep-direction, C-followup-leaf-adoption, C-followup-lifecycle, C-followup-timing, C-frontmatter-refs, C-handoff-skill-invocation, C-integration-points, C-max-review-cycles, C-proposal-naming, C-review-naming, C-severity-eager, C-severity-not-plan, C-slice-leaf-tasks, C-slice-review-before-close, C-supervisor-explore-ephemeral, C-supervisor-no-impl, C-ure-verbatim, C-vertical-slices |
| `divergent` | **2** | C-worker-gates, C-review-binary |
| **Total (27 canonical)** | **27** | |

† `C-actionable-errors` is the addendum row (catalog-only in Python, no check method): its gap task (aura-plugins-vxvt1) is included in Cv-A3.

**Escalation note (per PROPOSAL-1 §10):** Two `divergent` verdicts required non-trivial semantic judgment — notified team-lead per §10 protocol:
- **C-review-binary**: Python enforces via string-level check; Go enforces via type system. Same constraint intent, different mechanism. Gap task is to determine if explicit runtime check is needed.
- **C-worker-gates**: Spans two Python methods (`check_blocker_gate` + `check_worker_gates`). Go only implements blocker gate. Quality gates (has_todos, tests_pass, typecheck_pass) are absent.

## §6. Cv-A2 Verification

Every constraint from the source list appears exactly once in §4. Table: 28 rows = **27 C-* IDs with validators in `constraints.py` (canonical)** + **1 addendum row** (`C-actionable-errors`, catalog-only). Each appears exactly once. Cv-A2 satisfied.

## §7. Cv-A3 Verification

Every `missing` and `divergent` row has a non-empty `gap-task-id`:

| gap-task-id | constraint | verdict |
|---|---|---|
| aura-plugins-vxvt1 | C-actionable-errors | missing |
| aura-plugins-rfqkm | C-agent-commit | missing |
| aura-plugins-c91i2 | C-audit-dep-chain | missing |
| aura-plugins-8mj6v | C-audit-never-delete | missing |
| aura-plugins-nakvo | C-autonomous-progression | missing |
| aura-plugins-p2nq2 | C-blocker-dual-parent | missing |
| aura-plugins-gxdlh | C-clean-review-exit | missing |
| aura-plugins-8giwl | C-dep-direction | missing |
| aura-plugins-fd1g4 | C-followup-leaf-adoption | missing |
| aura-plugins-6r3hx | C-followup-lifecycle | missing |
| aura-plugins-nzp41 | C-followup-timing | missing |
| aura-plugins-3gxlt | C-frontmatter-refs | missing |
| aura-plugins-g3s5o | C-handoff-skill-invocation | missing |
| aura-plugins-gtfpm | C-integration-points | missing |
| aura-plugins-lwm3m | C-max-review-cycles | missing |
| aura-plugins-nnnzg | C-proposal-naming | missing |
| aura-plugins-apz6j | C-review-binary | divergent |
| aura-plugins-41gqs | C-review-naming | missing |
| aura-plugins-l3dxz | C-severity-eager | missing |
| aura-plugins-1ag61 | C-severity-not-plan | missing |
| aura-plugins-oeufm | C-slice-leaf-tasks | missing |
| aura-plugins-l0w6v | C-slice-review-before-close | missing |
| aura-plugins-1w2hb | C-supervisor-explore-ephemeral | missing |
| aura-plugins-kfp41 | C-supervisor-no-impl | missing |
| aura-plugins-hyceu | C-ure-verbatim | missing |
| aura-plugins-gmmyz | C-vertical-slices | missing |
| aura-plugins-fkmwt | C-worker-gates | divergent |

All 27 non-`ported` rows have gap-task-ids. Cv-A3 satisfied.

## §8. Surprises and Notable Findings

1. **Count discrepancy confirmed:** `constraints.py` docstring says "22", `CLAUDE.md` says "26", actual is **27** (with validators) or **28** (including catalog-only `C-actionable-errors`). This is a documentation staleness issue.

2. **Codegen ≠ runtime validator:** All C-* IDs appear in `pasture/internal/codegen/` as schema metadata for generating SKILL.md and role context prompts. This is NOT equivalent to runtime constraint enforcement. An audit reader could mistake codegen data for Go constraint implementations — they are categorically different.

3. **No Go `RuntimeConstraintChecker` equivalent:** The Python `RuntimeConstraintChecker` class with 22+ named validator methods has no direct Go port. The Go `ActivityCheckConstraints` is a much narrower runtime gate: only phase transitions + consensus + blocker gates.

4. **`C-actionable-errors` is catalog-only in Python:** It is in `CONSTRAINT_SPECS` but has no `check_actionable_errors()` method. Python enforces it by convention. The same approach applies in Go (the `pasterrors.StructuredError` type in `internal/errors/` is the convention enforcement mechanism).

5. **`C-worker-gates` spans two Python methods:** `check_blocker_gate()` and `check_worker_gates()` both emit C-worker-gates violations. Go's `ValidateAdvance()` only implements the blocker gate aspect. The quality gates (has_todos, tests_pass, typecheck_pass) are entirely absent from Go runtime validation. This is `divergent`.

6. **No Go-only constraints found:** The reverse-check confirms no constraint IDs appear in Go `internal/temporal/*.go` that are absent from the Python source. The gap is entirely Python→Go.

## §9. Gap Task Summary

**27 gap tasks filed** (all `discovered-from:aura-plugins-mh4ek`, label `aura:residual`) — **REFRAMED** per Phase-5/6 decision C (`implement C-X` → `verify C-X is enforced by its intended layer`; label `aura:mh4ek-investigation`):
- 24 `missing` (canonical) + 1 `missing` addendum (`C-actionable-errors`) → **verify** whether enforced by the intended layer (hook/SKILL.md/schema/codegen/runtime); implement only if confirmed a genuine runtime-enforcement gap
- 2 `divergent` → reconcile Go-vs-Python semantics (C-worker-gates quality gates; C-review-binary type-system-vs-string-check)
- 0 `untested` — no implementation-present-but-untested gaps found
- **Disposition (gap-vs-design) follows investigation `aura-plugins-vji97`.** Count: 24 + 1 + 2 = **27** (consistent with §3/§5/Cv-A3).

---

## Phase-5/6 UAT Resolution — architectural finding (2026-05-30)

**User decision C: verdict stays `QUALIFIED` / PROVISIONAL — gap-vs-design interpretation DEFERRED pending investigation.**

- **Investigation task** [`aura-plugins-vji97`](beads://aura-plugins-vji97) (`discovered-from:aura-plugins-mh4ek`): (a) grep bd history for `RuntimeConstraintChecker` — was Go's no-runtime-checker a known/decided choice during the port? (b) locate where each of the ~25 constraints is actually enforced now (hooks / SKILL.md / schema / codegen / agent-behavioral). The per-constraint gap-vs-design verdict follows from this.
- **27 provisional gap tasks REFRAMED**: `implement C-X in Go runtime` → **`verify C-X is enforced by its intended layer`** (labeled `aura:mh4ek-investigation`). Disposition — close confirmed-enforced, keep only genuine enforcement gaps — follows the investigation.
- **Count:** the hardcoded C-* count is being **REMOVED** from `aura-plugins/CLAUDE.md` (+ other docs) rather than corrected 26→27 — task [`aura-plugins-t7x6e`](beads://aura-plugins-t7x6e) (volatile, low-value). No separate count residual; folded here.
- **Phase 10:** `mh4ek` is **PROMOTED to a full Phase-10 review** (per the skip-audit-complexity escalation rule).
- **Out-of-cascade:** does NOT block `ow0pq` / `jbnx3`.

---

## Phase-11 Impl UAT — RESOLVED (2026-05-30)

**Verdict: `QUALIFIED` — RESOLVED** (was PROVISIONAL). The gap-vs-design question deferred to `vji97` was answered by an interactive per-constraint walk with the user, mapping each constraint's *true* enforcement locus across the whole `pasture/` codebase (not just `internal/temporal/`).

### Key finding: the two-worlds architecture

The audit's "missing from `internal/temporal/`" verdicts were misleading — almost no constraint is *absent from Go*; they are enforced at a **different layer**. `pasture` has two largely-disconnected halves:

- **Orchestrator** (`pastured` + `pasture-msg` + `internal/temporal/`) — real runtime enforcement (consensus gate, blocker gate, `VoteType` enum). But **no skill invokes it**, and there is **no bridge** from the bd tasks agents actually use (free-text `bd comments add "VOTE: ACCEPT"`, `skills/reviewer/SKILL.md:278`) to the Temporal `RecordVote` signal. `workflow_review.go` does not read bd tasks.
- **Skill+bd layer** (`internal/codegen` → `skills/*/SKILL.md` + `bd`) — what agents actually execute.

**Architecture decision (user, verbatim):** *"The current skills / agents / schema are the prioritized, near-term driver. Once we have all of the generators for these ported to Golang, the multi-agent orchestrator should be the primary driver, integrated with running agents via skills + hooks."* → skill+bd is the near-term primary model; the orchestrator's `①/②` enforcement is a **future phase**.

### 6-layer enforcement model (user taxonomy)

`①/②/③` was too coarse. Enforcement has distinct layers:
- **L1** — rule text in the skill/prompt (`SKILL.md`); agent reads & complies. Not tested.
- **L2** — the **generator** guarantees L1 is present & consistent across the right roles/phases (`internal/codegen`). **Tested.**
- **L3** — the **orchestrator**, via: **L4** CLI validation (`pasture task`) · **L5** Temporal workflows · **L6** FSM/state-machine (`ValidateAdvance`).

Most constraints are currently enforced at **L1+L2** (a real, tested layer). The vote/consensus/type guarantees live in the orchestrator (L5/L6), which the agent path does not yet invoke.

### Per-constraint dispositions (27 verify-tasks; `C-review-consensus` is `ported`, no task)

**CLOSED — confirmed enforced / by-design (13):**
- *Enforced now (type system):* `C-actionable-errors` (`StructuredError`, `vxvt1`), `C-review-binary` (`VoteType` enum, `apz6j`).
- *By-design at L1+L2 (11 agent-judgment):* `autonomous-progression` (`nakvo`), `handoff-skill-invocation` (`g3s5o`), `supervisor-explore-ephemeral` (`1w2hb`), `vertical-slices` (`gmmyz`), `ure-verbatim` (`hyceu`), `followup-leaf-adoption` (`fd1g4`), `followup-timing` (`nzp41`), `followup-lifecycle` (`6r3hx`), `integration-points` (`gtfpm`), `severity-eager` (`l3dxz`), `severity-not-plan` (`1ag61`).
- `C-review-consensus` — FSM consensus gate built (L6); no verify-task.

**DEFERRED — machine-enforcement epic `aura-plugins-y5fps` + GitHub issue [`dayvidpham/pasture#3`](https://github.com/dayvidpham/pasture/issues/3) (14, verify-tasks stay open):**
- *CLI (L4) — 9:* `dep-direction` (`8giwl`), `proposal-naming` (`nnnzg`), `review-naming` (`41gqs`), `slice-leaf-tasks` (`oeufm`), `slice-review-before-close` (`l0w6v`), `audit-never-delete` (`8mj6v`), `audit-dep-chain` (`c91i2`), `blocker-dual-parent` (`p2nq2`), `frontmatter-refs` (`3gxlt`).
- *Claude Code PreToolUse hooks — 2:* `agent-commit` (`rfqkm`), `supervisor-no-impl` (`kfp41`).
- *Orchestrator FSM gate completion (L5/L6) — 3:* `worker-gates` quality gates (`fkmwt`), `clean-review-exit` IMPORTANT gate (`gxdlh`), `max-review-cycles` (`lwm3m`).

**Correction applied:** `C-slice-leaf-tasks` requires only **≥1 leaf task** (slice is decomposed), NOT a fixed L1/L2/L3 set — per `check_slice_has_leaf_tasks` (`constraints.py:901`) and user correction. Earlier "L1/L2/L3" phrasing was illustrative.

**`vji97`** is effectively answered by this walk (the per-constraint enforcement loci are now documented); it remains open only as the pointer to the deferred epic.
