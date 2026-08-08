# Handoff — Harness Lifecycle Compiler

**To:** a new agent team taking over the harness lifecycle work
**From:** planning session, 2026-07-30
**State:** planning complete, **implementation not started**

---

## 0. Read these first, in this order

All paths are relative to `worktree/proposal-57-integration/pasture/`.

| # | Document | Why |
|---|---|---|
| 1 | `llm/research/hooks-ir-compilers-architecture-lessons.md` | **Standing authority. Never superseded.** Compiler architecture, the narrow waist, progressive lowering, why syntax-directed generation is the failure mode. |
| 2 | `llm/plan/urd-harness-lifecycle.md` | Requirements. Every one traceable to a quoted user statement. |
| 3 | `llm/plan/proposal-11-harness-lifecycle-compiler.md` | The ratified-pending architecture. |
| 4 | `llm/plan/impl-plan-m1-claude-vertical.md` | Six slices, integration points, merge order, execution rules. |
| 5 | `AGENTS.md` | Coding standards, worktree isolation, tiered code search. |

**Do not read `llm/plan/lifecycle-ir-waist.md` as current.** It is PROPOSAL-4,
stamped superseded, retained as provenance only.

---

## 1. What this project is

Pasture compiles native harness lifecycle events (Claude Code hooks, and later
OpenCode and Codex) into typed protocol operations through a compiler-style
narrow waist:

```text
  Claude Code          OpenCode            Codex
       |                   |                 |
  [ frontend ]        [ frontend ]      [ frontend ]     native -> Level 1
       +---------+---------+-----------------+
                 |
           ===========  L1  harness dialect
           [ lowering ]                                  THE MIDDLE-END
                 |                                       operation selection
           ===========  L2  lifecycle dialect            THE NARROW WAIST
        [ legalization ]                                 authority verified here
           ===========  L3  protocol dialect
            [ backend ]
           ===========  L4  effects
```

The point is `N + M` rather than `N × M`: adding a harness is one frontend,
adding an operation is one backend rule.

**Use compiler vocabulary.** *waist, IR, Level 1-4, frontend, lowering,
middle-end, legalization, backend, pass, differential equivalence.* This is a
user ruling and it is not stylistic — see §5.

---

## 2. Current state of the tree

Branch `feat/proposal-57-integration` at `d8a91d7`, clean, pushed, all gates
green.

**Built and working:**

- append-every-delivery, no dedup anywhere (guarded)
- content-addressed blob storage; every payload body retained in SQLite
- delivery is an **ordered pair**: blob write, then row commit — orphan blob is
  reclaimable, dangling reference is corruption
- replay-derived projection, bounded readers, a guard banning direct SQL in
  production tests
- ordered timeout profiles enforced by a build-failing guard
- host descriptor generator that **emits**, with a CI drift gate
- Claude registration: `SessionStart` enabled, 29 withheld (**M1 raises this to
  five enabled / 25 withheld — see §3.1**)
- host version recorded on every delivery, never rejected
- public CLI boundary already in the ratified shape:
  `pasture hook lifecycle --harness claude-code --event SessionStart --host-version ...`

**Missing — this is M1's work:**

- `frontend` as a separate pass (currently fused into ingress capture)
- `lowering` — **the middle-end does not exist**, see §4
- `legalize` and `backend` stages
- differential equivalence (needs a second harness; M2)

---

## 3. Milestones

| Milestone | Content | Proves |
|---|---|---|
| **M1** | Claude vertical: frontend, lowering, legalization, backend, end to end, over **five events** | the pipeline works |
| **M2** | OpenCode frontend + **differential equivalence** | the waist *is* a waist |
| **M3** | Codex frontend; retire `PASTURE_ADAPTER_*` | `N + M` holds |
| M4+ | versioned interpretation, lineage, context disclosure, the write gate | — |

### 3.1 The ten M1 events, and the safety constraint they impose

| # | Event | Blocking | Failure | Identity | L2 arm |
|---|---|---|---|---|---|
| 1 | `SessionStart` | no | report | — | evidence |
| 3 | `SessionEnd` | no | report | — | evidence |
| 8 | `PreToolUse` | **yes** | **exit 2 = DENY** | `toolUseID` | gate-consultation |
| 11 | `PostToolUse` | no | report | `toolUseID` | evidence |
| 12 | `PostToolUseFailure` | no | report | `toolUseID` | evidence |
| 13 | `PostToolBatch` | **yes** | **exit 2 = DENY** | **none** | evidence |
| 25 | `PreCompact` | **yes** | **exit 2 = DENY** | — | gate-consultation |
| 26 | `PostCompact` | no | report | — | evidence |
| 29 | `Elicitation` | **yes** | **exit 2 = DENY** | `requestID` | gate-consultation |
| 30 | `ElicitationResult` | **yes** | **exit 2 = DENY** | `requestID` | **human-response** |

**All three L2 arms are reachable.** No smaller set achieves this.

**Two correlation domains:** `toolUseID` joins tool intent to result;
`requestID` joins an elicitation to its answer. That is what makes tracing
generated code back to a human signal constructible — session events alone give
session-grained provenance and nothing finer.

**`AskUserQuestion` is a tool, not a hook event** (`internal/runtime/profiles.go:228`)
— it arrives via `PreToolUse`/`PostToolUse`. Already covered.

**`ElicitationResult` is evidence-only at M1.** It is the one event that would
legitimately write protocol state once the write gate is decided (§8.1), so
proving it exercises no authority is what makes the no-authority claim
meaningful rather than vacuous.

**Capture risk:** `Elicitation`/`ElicitationResult` need an MCP server that
actually elicits. If that round-trip cannot be captured they stay **visibly
withheld** and the human-response arm goes untested. That is acceptable — **do
not synthesise a fixture to close it.** Surface it.

**The safety constraint.** Five of the ten are blocking, and the host reads
**exit 2 as deny the user's tool call**. `AGENTS.md` maps exit code 2 to
`CategoryConnection`. So an internal Pasture storage fault during `PreToolUse`
would exit 2 and silently block the user's work. SLICE-7 makes always-exit-0
**structurally enforced** and **must merge before any blocking event is
enabled**. Do not treat this as a convention.

`PreToolUse` also carries `MutationInput` — the one event permitted to rewrite
the agent's tool input. Model the axis in the IR faithfully; emit it from no
backend rule.

`PostToolBatch` binds **no identity**, so it cannot be joined to the pair. It
must emit an explicit *unresolved* correlation fact rather than infer one from
ordering or timing.

Claude first is a deliberate user decision. **Differential equivalence must not
be moved to M1** — a single-harness MVP cannot demonstrate a waist by
construction, so the gate would be vacuous and green.

---

## 4. Read this before touching the lowering pass

`internal/lifecycle/lower.go` was deleted in `43dbbf1` because a search found no
production callers. That was true, and it was the wrong criterion: it had no
callers because the slice that would have called it was never built. **The
compiler cannot distinguish unfinished from obsolete.**

The pre-deletion source is preserved at `/tmp/opencode/lowering-restore/`
(434 lines plus 601 of tests) and recoverable from
`git show 43dbbf1^:internal/lifecycle/lower.go`.

**Restoring it is a port, not a revert.** Its type substrate is gone: `Origin`,
`Semantics`, `ObservationRecord`, `ActorResolver` no longer exist, and `Event`
and `Outcome` now name unrelated types in other packages. Take the logic
(`Lower`, `lowerObservation`, `preflight`, the error shapes); drop the dedup
surface entirely; re-express against the new IR types.

**Hard constraint: the pass must be pure, with no storage dependency.** Its tests
must open no database. This is not a style preference — a stage that cannot be
tested in isolation is exactly how the previous one vanished with no test
failing.

---

## 5. Why the vocabulary ruling exists

PROPOSAL-4 spoke *waist / IR / Level 1-4 / frontend / Lower*. PROPOSAL-10 spoke
*occurrence / T1-T3 / ingress capture / interpretation* — it contains the token
`IR` twice in 4,289 lines and never writes "middle-end". A search in one dialect
could not see the other, and a live compiler stage read as unreferenced and was
deleted.

Corollary: **PROPOSAL-10's package named `lowering` performs L3→L4 effect
mapping**, which under compiler terms is backend work, not lowering. Lowering is
L1→L2. Do not inherit that name for the wrong stage.

---

## 6. The recurring defect class

Every invariant stated in prose in this epic has eventually been violated. Only
the type- or guard-enforced ones held. Confirmed instances:

- a same-package boundary asserted by comment, unenforceable by grep
- a bounded-reader rule asserted five times, guarded zero times
- `busy_timeout` at 5 s beneath callers that gave up at 1 s and 2 s — resilience
  that could never be reached
- the deadline path "covered" by a test that only counts the error while
  asserting it must never occur
- **`FixtureEvidenceAuthentic`** — a bare enum constant with no digest and no
  ref. The gate deciding whether an event may be enabled checks that the caller
  passed the constant, while its own error text demands "a verified digest" that
  nothing records or verifies. `SessionStart` is enabled behind this today.
  SLICE-5 fixes it.

**The pattern is not "prose invariants get violated." It is that things which
resemble enforcement do not get checked for whether they actually enforce.**
When you write a guard, name the mutation that must turn it red, and run it.

Related: a zero result from a search is not an absence proof. Three false
negatives so far. The compiler is the only authority on whether code is
deletable — see `AGENTS.md` §Searching the Codebase.

---

## 7. Execution rules

- **One worktree per slice**, branched off the integration branch. Workers never
  share a tree; it already caused a false gate failure.
  `git worktree add -b <name> <repo-host>/worktree/<name> feat/proposal-57-integration`
- **Merge conflicts are the orchestrator's job**, not the worker's. Ambiguous
  design choices go to the user, not into a conflict resolution.
- **Generated files are never hand-merged.** Merge the typed source, re-run
  `make generate`, verify a zero-diff regen. The CI drift job compares committed
  output against fresh codegen.
- **Review budget: 3 rounds per slice**, aiming for a fix-free round at
  0 BLOCKER / 0 IMPORTANT / 0 MINOR. On exhaustion without a clean round,
  surface outstanding findings to the user.
- **Do not fork shared machinery.** `internal/acceptance` is the corpus
  framework; `internal/lifecycle/guard` is the static-guard framework. Extend
  them. A duplicate framework has been rejected five times in this epic.
- Gates before every commit: `make fmt`, `make lint`, `make build`,
  `go test -race ./...`, zero-diff `make generate`. **`go` is not on PATH by
  default** — a `make fmt` that passes vacuously has already happened.
- Commit with `git agent-commit`, stage only owned paths, never `git add -A`.

---

## 8. Open decisions — do not invent answers

1. **The write gate.** URD R8 fixes the principle (broad automated writes before
   legalization; separately verified authority at legalization) but **not the
   mechanism**. The superseded proposal offered a capability handshake; it is
   unbuilt and explicitly not carried forward. **Deferred by the user.** M1
   legalization records evidence of consultation and answers *proceed*,
   exercising no authority. Do not build a gate.
2. **Exit-code contract.** Exit 2 means `CategoryConnection` internally and
   *deny* to the host. Must be resolved before any real deny ships. Until then
   the lifecycle command exits 0 and reports on stderr — an explicitly
   **temporary** posture, not the final contract.
3. **Harness support matrix / version skew detection** — deferred to a later
   epic. Record the observed version; never reject on it.

---

## 9. Known carried-in defects

| Defect | Where | Owner |
|---|---|---|
| `FixtureEvidenceAuthentic` has no digest | `activation/types.go:28-31,52` | SLICE-5 |
| Lifecycle command can exit non-zero; host reads that as deny | `cmd/pasture/hook_lifecycle.go` | **SLICE-7 — gates blocking events** |
| No addressable L1→L2 pass | absent | SLICE-3 |
| Mutation operators declared but not all executed | `internal/acceptance` | open |
| INV-1 status check is a hardcoded list of one entry | `lifecycle/guard` | open |
| Codex/OpenCode still on `PASTURE_ADAPTER_*` Python path | `codegen/codex_manifest.go:54,128` | **deferred** — retired at M3 |

---

## 10. Not yet done

- **Slice tracking tasks were deliberately not created.** The IMPL_PLAN is the
  authority; the incoming supervisor creates the tracking tree from it.
- PROPOSAL-11 has **not been reviewed or ratified**. It is a draft. If your
  process requires plan review before implementation, run it.
- Superseded records are labelled and commented; nothing was deleted.

---

## 11. One piece of context worth having

This epic produced ten proposals and roughly twenty-four review rounds **without
a requirements document**. From the fifth proposal onward, each justified itself
against the previous round's reviewer findings rather than against stated
requirements. That is the mechanism by which the chain produced successive
locally-reasonable but mutually incompatible architectures, deleted the
middle-end, and dropped multi-harness support from the milestone map — without
anyone deciding to do any of it.

The URD now exists. When a proposal, a review finding, or an instruction seems
to conflict with it, **the URD wins**, and the conflict is worth surfacing rather
than resolving quietly.
