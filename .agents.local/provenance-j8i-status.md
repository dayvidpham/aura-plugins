# Provenance J8I Execution Report

Updated: 2026-07-25

## Scope

This report tracks the local, unpushed Provenance v0.0.4 atomic-journal work
and its relationship to Aura/Pasture Proposal 57. It distinguishes Beads
lifecycle state, local Git integration, and unresolved architecture decisions.

No branch described here has been pushed or merged through an upstream PR.

## Current Summary

- Proposal 61 (`aura-plugins-v8594`) is ratified. Plan UAT selected the
  implementation-level consumer gate and confirmed its validation cases.
- Corrective context persistence (`providence-d29s`) reached a final clean
  0/0/0 review round, integrated locally at `bd5814f`, and is closed.
- Bounded `Journal().Facts()` remediation (`providence-j8i.1.4`) reached a
  final clean 0/0/0 review round, integrated locally at `8de83b4`, and is
  closed.
- The local integration branch `feat/atomic-journal-primitives` is at
  `8de83b4`, five commits ahead of its remote, with no push performed.
- Provenance already had a substantial embedded DBOS adapter before `.1.3`.
  `.1.3` is an incremental parity candidate, not a greenfield DBOS integration.
- Local `.1.3` candidate `9927cdb` has parent `8de83b4`, is green, and has been
  resumed in parallel through a separate review-first agent team.
- The user selected the current split transaction architecture for delivery.
  The fused DBOS-owned design is deferred because the required
  Zombiezen-to-modernc migration is substantial.
- Pasture `EpochHumanService` WIP resumes against accepted Provenance `8de83b4`
  using direct `Journal().Apply` plus the required exact replay/attach behavior.
- DBOS v0.20 upgrade tracking: <https://github.com/dayvidpham/provenance/issues/22>.
- Fused architecture tracking: <https://github.com/dayvidpham/provenance/issues/23>.

## Aura Program Context

| Aura Beads ID | Scope | State | Relationship |
|---|---|---|---|
| `aura-plugins-tekqb` | Proposal 57 epoch aggregate and lifecycle adapters | open, ratified | Primary lifecycle proposal. |
| `aura-plugins-w76i1` | Proposal 57 implementation plan | in progress | Owns five Pasture vertical slices. |
| `aura-plugins-v8594` | Proposal 61 bounded fact-query substrate | open, ratified | Provenance storage/query prerequisites are now accepted locally. |
| `aura-plugins-zyemi` | Proposal-57 Epoch human-decision slice | open | WIP checkpoint exists; production write boundary is under review. |
| `aura-plugins-pvxx5` | Live review and decision command blocker | in progress | Current WIP uses direct `Apply`; remediation resumed after the split decision. |
| `aura-plugins-jdj2x` | Proposal 50 preserved baseline | open, ratified | Retains unique delivery work outside Proposal 57 amendments. |
| `aura-plugins-fxwwv` | Proposal 50 implementation plan | in progress | Explicitly blocked by Proposal 57 plus other open Proposal-50 slices. |

Proposal 50 is not globally superseded. Proposal 57 amends its lifecycle/CLI
boundary while preserving unrelated runtime, distribution, activation, and
Home Manager work.

## Requirements Evidence

| Proposal | Evidence | Consequence |
|---|---|---|
| Proposal 50 | `aura-plugins-ydhf9`, `aura-plugins-jdfxx`, `aura-plugins-hznvh`, `aura-plugins-0oh7l` | Preserve unaffected requirements and active delivery work. |
| Proposal 57 | `aura-plugins-tekqb`, `aura-plugins-hznvh`, `aura-plugins-vk87j` | Typed lifecycle/CLI amendment over one Provenance journal. |
| Proposal 61 | `aura-plugins-k5pfq`, `aura-plugins-jtyga`, `aura-plugins-dej32`, `aura-plugins-zy3cj` | Same-store bounded fact reads, exact contexts, deterministic snapshots, fail-closed corruption, and borrowed liveness. |

Proposal 61 uses public `Tracker.Journal().Facts()` with type name `Journal`,
not `JournalAPI`. It excludes a second store, task-event scans, generic search,
DBOS mutation behavior, and lifecycle/CLI implementation.

## Beads Inventory

This section retains every Beads identifier referenced by the previous report
and adds the review, UAT, and implementation records created since then.

### Aura Requests, Requirements, And Proposals

| Beads ID | Current state | Purpose / current disposition |
|---|---|---|
| `aura-plugins-ydhf9` | in progress | Original Proposal-50 request evidence. |
| `aura-plugins-jdfxx` | open | Original Proposal-50 elicitation evidence. |
| `aura-plugins-hznvh` | open | Proposal-50/57 requirements document. |
| `aura-plugins-0oh7l` | closed | Proposal-50 approval evidence. |
| `aura-plugins-jdj2x` | open, ratified | Proposal 50 preserved baseline; not globally superseded. |
| `aura-plugins-fxwwv` | in progress | Proposal-50 implementation plan; waits on Proposal 57 plus its own open slices. |
| `aura-plugins-tekqb` | open, ratified | Proposal 57 lifecycle proposal. |
| `aura-plugins-vk87j` | closed | Proposal-57 Plan UAT amendment. |
| `aura-plugins-w76i1` | in progress | Proposal-57 implementation plan. |
| `aura-plugins-k5pfq` | open request chain | Request for the minimal fact-query substrate. |
| `aura-plugins-jtyga` | open request chain | Fact-query elicitation; active proposal edge moved to Proposal 61. |
| `aura-plugins-dej32` | open living URD | Fact-query requirements, naming, and UAT amendments. |
| `aura-plugins-i1lc4` | open, superseded history | Proposal 58; removed from active dependency chain because reviewer-owned records remain open. |
| `aura-plugins-z1nuq` | closed, superseded | Proposal 59. |
| `aura-plugins-d6pkn` | closed, superseded | Proposal 60; replaced after Axis-B requested two test requirements. |
| `aura-plugins-v8594` | open, ratified | Proposal 61; current fact-query plan. |
| `aura-plugins-zy3cj` | closed, accepted | Proposal-61 Plan UAT; user selected the implementation-level consumer gate. |
| `aura-plugins-nnn19` | closed, ACCEPT | Proposal-61 correctness review. |
| `aura-plugins-mc5dc` | closed, ACCEPT | Proposal-61 test-quality review. |
| `aura-plugins-d93qp` | closed, ACCEPT | Proposal-61 elegance review. |

### Aura Proposal-57 Implementation

| Beads ID | Current state | Purpose / current disposition |
|---|---|---|
| `aura-plugins-zyemi` | open | Epoch human-decision aggregate. |
| `aura-plugins-weepb` | closed | Frozen EpochService API and contract tests. |
| `aura-plugins-pvxx5` | in progress | HumanEpochService resumed under the selected split architecture. |
| `aura-plugins-8cus8` | open, blocked by `pvxx5` | Replay, attribution, and race proofs. |
| `aura-plugins-xl4f8` | open | Assignment-controlled aggregate; waits on `zyemi`. |
| `aura-plugins-njyhk` | open | CLI/migration/hidden adapter; waits on S57.1/S57.2. |
| `aura-plugins-dcu2d` | open | Generated harness adapters; waits on CLI contract. |
| `aura-plugins-yi7ls` | open | Executable acceptance gates. |
| `aura-plugins-ioes8` | closed | Acceptance corpus/store-reader foundation. |
| `aura-plugins-3zi47` | open | Built-binary exact-delta/restart/race corpus. |
| `aura-plugins-5vgpi` | open | Authentic pinned loaders and shared gates. |

### Provenance Plan And Verticals

| Beads ID | Current state | Integrated/current evidence |
|---|---|---|
| `providence-j8i` | in progress | Parent atomic-journal epoch. |
| `providence-j8i.1` | open | v0.0.4 implementation plan; `.1.3` and architecture decision remain. |
| `providence-j8i.1.1` | closed | Canonical contracts at `88d4d9a`. |
| `providence-j8i.1.2` | closed | Transactional pooled Apply at `338a336`. |
| `providence-d29s` | closed | Corrective context storage, clean 0/0/0, integrated at `bd5814f`. |
| `providence-j8i.1.4` | closed | Bounded fact queries, clean 0/0/0, integrated at `8de83b4`. |
| `providence-j8i.1.3` | in progress | Incremental DBOS parity candidate `9927cdb`; separate review-first team active. |

### Corrective d29s Plan And Code Reviews

| Beads ID | State | Result |
|---|---|---|
| `providence-ldwv` | closed | Round-1 plan correctness REVISE, addressed. |
| `providence-66sb` | closed | Round-1 plan test-quality REVISE, addressed. |
| `providence-fp7x` | closed | Round-1 plan elegance REVISE, addressed. |
| `providence-w5lt` | closed | Round-2 plan correctness ACCEPT. |
| `providence-vzwk` | closed | Round-2 plan test-quality ACCEPT. |
| `providence-jts8` | closed | Round-2 plan elegance ACCEPT. |
| `providence-x0xb` | closed | Code-review correctness round 1 REVISE. |
| `providence-nho5` | closed | Code-review test quality round 1 ACCEPT with finding. |
| `providence-66nl` | closed | Code-review elegance round 1 REVISE. |
| `providence-8owa` | closed | Final correctness review, 0/0/0. |
| `providence-app7` | closed | Final test-quality review, 0/0/0. |
| `providence-kfmt` | closed | Final elegance review, 0/0/0. |

Resolved d29s findings: `providence-koje`, `providence-7f9p`,
`providence-x8xz`, `providence-j0hl`, `providence-xrz3`, `providence-92k3`,
`providence-a6bq`, `providence-pfmk`, and `providence-v722`. All are closed
after independent final verification.

### Fact-Query Reviews And Findings

| Beads ID | State | Result |
|---|---|---|
| `providence-bxdu` | closed | Initial correctness REVISE; superseded findings resolved. |
| `providence-cmp3` | closed | Initial test-quality REVISE; superseded findings resolved. |
| `providence-jj85` | closed | Initial elegance REVISE; superseded findings resolved. |
| `providence-vm4t` | closed | Remediation correctness review, ACCEPT with IMPORTANT findings. |
| `providence-bdov` | closed | Remediation test review, REVISE. |
| `providence-h3uo` | closed | Remediation elegance review, ACCEPT with IMPORTANT finding. |
| `providence-3yin` | closed | Round-3 correctness, 0/0/0. |
| `providence-wum1` | closed | Round-3 test quality, 0/0/0. |
| `providence-zc0m` | closed | Round-3 elegance, metadata REVISE. |
| `providence-07p6` | closed | Final correctness, 0/0/0. |
| `providence-wxsz` | closed | Final test quality, 0/0/0. |
| `providence-uxox` | closed | Final elegance, 0/0/0. |

Resolved original `.1.4` findings: `providence-si1s`, `providence-24hu`,
`providence-by9r`, `providence-kx5s`, `providence-ur6a`, `providence-m10f`,
`providence-nevn`, `providence-9s6f`, `providence-daf9`, `providence-g1i0`,
and `providence-oig7`.

Resolved remediation findings: `providence-w4bd`, `providence-u575`,
`providence-0ve6`, `providence-8udf`, `providence-7nol`, `providence-egha`,
`providence-cwji`, `providence-8v0m`, `providence-s7lq`, and
`providence-elvb`.

### Deferred Provenance Records

| Beads ID | State | Purpose |
|---|---|---|
| `providence-28y3` | deferred/open | Result-slot cross-reopen coverage. |
| `providence-591i` | deferred/open | Malformed result-slot binding matrix. |
| `providence-xp4p` | deferred/open | Malformed legacy migration coverage. |
| `providence-n999` | deferred/open | Shared-base `borrowConnScope` cleanup. |
| `providence-4c5g` | deferred/open | Formatting cleanup overlapping downstream files. |

## Local Git State

| Repository/worktree | Branch | Commit | State |
|---|---|---|---|
| Provenance integration | `feat/atomic-journal-primitives` | `8de83b4` | Clean, ahead of remote by 5, unpushed. |
| Provenance d29s | `fix/d29s-context-persistence` | `bd5814f` | Clean, reviewed 0/0/0, locally integrated. |
| Provenance query | `fix/j8i-1-4-query-remediation` | `8de83b4` | Clean, reviewed 0/0/0, locally integrated. |
| Provenance DBOS parity | `fix/j8i-1-3-dbos-parity` | `9927cdb` | Clean, parent is `8de83b4`, resumed for independent review. |
| Pasture nested WIP | `feat/codex-codegen` | `4a2c00a` | WIP Epoch human decisions; unpushed. |
| Aura outer WIP | `feat/codex-codegen` | `12cc010` | Records Pasture submodule pointer; Beads backups remain unstaged. |

## Worktree And Branch Inventory

### Active Integration And Architecture Worktrees

| Location | Repository | Branch | HEAD | Purpose / state |
|---|---|---|---|---|
| `/home/minttea/codebases/dayvidpham/provenance` | Provenance | `main` | `7bbf7f0` | Root worktree; Beads coordination only, not the implementation base. |
| `/home/minttea/codebases/dayvidpham/provenance/worktree/atomic-journal-primitives` | Provenance | `feat/atomic-journal-primitives` | `8de83b4` | Local integration branch; accepted d29s + `.1.4`, unpushed. |
| `/home/minttea/codebases/dayvidpham/provenance/worktree/d29s-context-persistence` | Provenance | `fix/d29s-context-persistence` | `bd5814f` | Closed corrective storage slice. |
| `/home/minttea/codebases/dayvidpham/provenance/worktree/j8i-1-4-query-remediation` | Provenance | `fix/j8i-1-4-query-remediation` | `8de83b4` | Closed fact-query remediation slice. |
| `/home/minttea/codebases/dayvidpham/provenance/worktree/j8i-1-3-dbos-parity` | Provenance | `fix/j8i-1-3-dbos-parity` | `9927cdb` | Paused DBOS parity candidate; parent is `8de83b4`; unreviewed. |
| `/home/minttea/codebases/dayvidpham/aura-plugins` | Aura | `main` | `4e7a16c` | Beads/program coordination and this report; pre-existing Beads, `AGENTS.md`, and untracked files remain unstaged. |
| `/home/minttea/codebases/dayvidpham/aura-plugins/worktree/codex-codegen` | Aura | `feat/codex-codegen` | `12cc010` | Outer Proposal-57 WIP checkpoint and Pasture submodule pointer. |
| `/home/minttea/codebases/dayvidpham/aura-plugins/worktree/codex-codegen/pasture` | Pasture | `feat/codex-codegen` | `4a2c00a` | Nested EpochHumanService WIP; split-architecture remediation active. |

The dependent branches were created from implementation integration points:

```text
feat/atomic-journal-primitives @ bd5814f
  -> fix/j8i-1-4-query-remediation
       -> integrated as 8de83b4
            -> fix/j8i-1-3-dbos-parity @ 9927cdb
```

No dependent branch was created from `main` or `develop`.

### Historical `.1.2` Audit Worktrees

These worktrees contain completed checkpoints from the pooled Apply sequence.
They are retained for audit and should not be used as new downstream bases.

| Location suffix under `provenance/worktree/` | Branch | Recorded HEAD / role |
|---|---|---|
| `j8i-1-2-a1-activity` | `fix/j8i-1-2-a1-activity` | `d573ce2`, activity remediation checkpoint. |
| `j8i-1-2-a2-fact-conditions` | `fix/j8i-1-2-a2-fact-conditions` | `e160553`, fact-condition checkpoint. |
| `j8i-1-2-a3-apply-replay` | `fix/j8i-1-2-a3-apply-replay` | `19afc0f`, Apply/replay checkpoint. |
| `j8i-1-2-p1-identity-activity` | `fix/j8i-1-2-p1-identity-activity` | `4993cf8`, identity/activity CRUD. |
| `j8i-1-2-p1-migration-replay` | `fix/j8i-1-2-p1-migration-replay` | `2d9208b`, migration/replay checkpoint. |
| `j8i-1-2-p1-task-graph-crud` | `fix/j8i-1-2-p1-task-graph-crud` | `4de7d51`, task/graph CRUD. |
| `j8i-1-2-p2-apply-scope` | `fix/j8i-1-2-p2-apply-scope` | `ee3d2c6`, Apply scope extraction. |
| `j8i-1-2-p2-benchmark-policy` | `fix/j8i-1-2-p2-benchmark-policy` | `ef60879`, race benchmarks. |
| `j8i-1-2-p2-foundation` | `fix/j8i-1-2-p2-foundation` | `9f1fb18`, pooled scope foundation. |
| `j8i-1-2-p2-internal-tests` | `fix/j8i-1-2-p2-internal-tests` | `c2b4bd6`, internal test scope. |
| `j8i-1-2-p2-migration-scope` | `fix/j8i-1-2-p2-migration-scope` | `f5c3d9e`, migration scope extraction. |
| `j8i-1-2-p2-pool-finalize` | `fix/j8i-1-2-p2-pool-finalize` | `9b044b4`, integrated pooled seam removal. |
| `j8i-1-2-p2-root-tests` | `fix/j8i-1-2-p2-root-tests` | `ac2c0bd`, root SQL fixture isolation. |

Other older Provenance issue worktrees exist, but they are not part of the
current J8I dependency path and must not be used as integration bases.

## Accepted Provenance Integration Chain

```text
88d4d9a  canonical operation contracts (.1.1)
   |
338a336  transactional pooled SQLite Apply (.1.2)
   |
e66e433  initial Journal().Facts() implementation (rejected evidence)
   |
42061b3  persist decision/evidence contexts
   |
80c5b19  close d29s code-review findings
   |
bd5814f  DBOS durable-table inventory integration; d29s clean 0/0/0
   |
44bab44  initial .1.4 query remediation
   |
8de83b4  consolidated .1.4 findings; final clean 0/0/0
   |
9927cdb  incremental DBOS Apply parity candidate (review resumed, unintegrated)
```

## Corrective Context Storage (`providence-d29s`)

State: closed and locally integrated at `bd5814f`.

Delivered:

- Static subtype-owned `journal_decision_contexts` and
  `journal_evidence_contexts` relations.
- Atomic Apply persistence, exact replay, rollback, legacy backfill, reopen,
  and fail-closed integrity behavior.
- Canonical selected-fact context verification.
- Shared bounded fact matcher/page-binding contract.
- Bounded condition-time validation rather than full-history scans.
- Immutable failed-open tests for missing, extra, opaque, malformed, and
  cross-subtype corruption.
- Full race, vet, CGO-disabled build, ast-grep, Nix no-build, and diff gates.

The final Round-2 implementation reviews were:

- Axis A: `providence-8owa`, 0/0/0.
- Axis B: `providence-app7`, 0/0/0.
- Axis C: `providence-kfmt`, 0/0/0.

## Bounded Fact Queries (`providence-j8i.1.4`)

State: closed and locally integrated at `8de83b4`.

Delivered:

- Decision/evidence pages consume the shared d29s matcher and subtype context
  relations; no task-event context scan remains.
- Exact canonical returned contexts and ALL/required-subset matching.
- Candidate/page-bounded topology diagnostics that fail closed rather than
  silently omitting corrupt facts.
- Committed snapshot validation, exclusive cursors, Limit+1 pagination, and
  deterministic lease-boundary reader/writer tests.
- Exact public standalone/reopen/borrowed assertions through
  `Tracker.Journal().Facts()`.
- Complete scope, kind, actor, operation, subtype, and context decoy matrices.
- Malformed-input-before-SQL and immutable query-corruption matrices.
- Corrected `.1.4` and `.1.3` authoritative ownership/fork metadata.

The final Round-4 reviews were:

- Axis A: `providence-07p6`, 0/0/0.
- Axis B: `providence-wxsz`, 0/0/0.
- Axis C: `providence-uxox`, 0/0/0.

All historical `.1.4` findings and severity groups were closed only after this
clean final round.

## Existing DBOS Integration

Provenance already contains an embedded, local, SQLite-backed DBOS adapter.
Relevant existing history includes:

- `9021fd7`: initial DBOS durable-execution adapter.
- `298d1a2`: borrowed-session/retry integration.
- `de39a56`, `4924acf`, `00f4aef`, `b0f7b19`: replay, codec, and durable
  contract remediation.

The accepted `8de83b4` tree already contains `DBOSAdapter.Apply`, smoke tests,
retry classification, cancellation, crash-gap recovery, borrowed shared-store
support, workflow identity, checkpoint outcome handling, and replay checks.

Therefore `.1.3` is not "add DBOS." Local candidate `9927cdb` incrementally
adds newer Apply contract parity: complete input/outcome transport and focused
typed-result tests. It changes seven DBOS-owned files, has parent `8de83b4`, and
   passes all gates. It is deferred before review and remains unintegrated.

## DBOS/Apply Architecture Discovery

DBOS in this system is an embedded API over local SQLite. It is entirely
offline and invoked on demand; it is not a network service or independently
operated daemon.

Current boundaries are:

```text
Direct Pasture path
  EpochHumanService
    -> tracker.prov.Journal().Apply(OperationInput)

Durable Provenance path
  DBOSAdapter.Apply(context, OperationInput)
    -> DBOS workflow/checkpoint/recovery
    -> tracker.Journal().Apply(OperationInput)
```

Evidence: Pasture WIP `internal/tasks/epoch_human_service.go:331` calls direct
`Journal().Apply`. The DBOS adapter's workflow fold calls the same domain Apply.

The current design has two distinct guarantee layers:

- DBOS: durable invocation, workflow identity, retries, checkpoints, recovery.
- Apply: domain transaction, canonical validation, conditions, conflicts,
  result slots, projections, and operation replay.

Conditions, typed conflicts, and journal invariants are irreducible domain
behavior. Replay/checkpoint ownership overlaps because Apply commits separately
from the DBOS checkpoint. The crash gap is:

```text
Apply commits domain rows
  -> process stops before DBOS checkpoint
  -> DBOS retries
  -> Apply exact replay prevents duplicate domain writes
```

The possible fused design is:

```text
EpochHumanService
  -> narrow durable OperationExecutor
  -> DBOS-owned SQLite transaction
       -> Provenance ApplyTx domain kernel
       -> DBOS checkpoint/result
  -> one commit
```

Potential benefits:

- One transaction and replay owner for production lifecycle writes.
- No domain-commit/checkpoint crash gap.
- Less workflow lookup, fingerprint reconciliation, and replay code.
- Human lifecycle services consistently use the durable path.
- Direct Apply can become a thin standalone/library wrapper rather than an
  equal Pasture production path.

Verified DBOS v0.16 behavior:

- DBOS already implements the required fused transaction internally.
- Private `runAsTxn` in upstream `dbos/workflow.go:1754-1865` begins one
  transaction, invokes the application callback with that transaction, writes
  the `operation_outputs` checkpoint through the same transaction, and commits
  both together.
- Upstream `dbos/dbq.go:23-50,209-276` defines the SQL-like `Querier`, `Tx`,
  and SQLite `*sql.Tx` wrapper needed by an application callback.
- The required callback is not public in v0.16: `runAsTxn` and its `txn[R]`
  callback are unexported, while public `RunAsStep` executes the callback and
  checkpoint in separate transactions.
- DBOS workflow-ID reuse does not compare stored semantic input. A fused design
  should include a stable canonical input fingerprint in the workflow ID while
  retaining Provenance `OperationID` as the domain conflict identity.

The two immediate technical blockers are:

1. Upgrade to stable DBOS Go v0.20.0 and use its public `NewDataSource` plus
   `RunAsTransaction` with the exact system `*sql.DB` handle. Reflection,
   `go:linkname`, private SQL, and copied DBOS internals are rejected.
2. Reconcile transaction APIs: Provenance currently writes through zombiezen
   SQLite connections while DBOS owns a modernc `database/sql` transaction.
   Sharing a SQLite file/WAL is not sharing one transaction.

The recommended kernel remains DBOS-independent:

```go
type OperationApplier interface {
    Apply(context.Context, OperationInput) (CommittedResult, error)
}

// Internal domain kernel; does not begin, commit, or roll back the outer tx.
ApplyTx(context.Context, SQLTx, OperationInput) (CommittedResult, error)
```

DBOS should own workflow execution, retry scheduling, recovery, checkpointing,
and the outer transaction. Provenance must retain canonical operation identity,
conditions, typed conflicts, authority rules, ordered effects, result-slot
integrity, journal invariants, projections, and committed-result reconstruction.
The journal operation tables are domain identity/audit state, not merely a
duplicate DBOS checkpoint ledger.

Original unaccepted deletion projection from the fused survey:

| Area | Current physical LOC | Projected LOC | Estimated change |
|---|---:|---:|---:|
| Provenance DBOS production | 2,563 | 500-850 | -1,713 to -2,063 |
| Provenance DBOS tests | 4,928 | 1,200-1,600 | -3,328 to -3,728 |
| Public DBOS transaction API/tests | 0 | 120-220 | +120 to +220 |
| Provenance SQL transaction kernel/seam | 0 | 300-700 | +300 to +700 |
| Pasture human service/wiring | 694 | 560-680 | -14 to -134 |
| **Estimated net** | **8,185 relevant LOC** | **2,680-4,050** | **about -4,100 to -5,500** |

Independent review rejected using this projection as implementation evidence.
The measured migration surface is:

- Minimal fused path: about 3,118 Apply-reachable LOC across 132 functions and
  99 direct Zombiezen/sqlitex call sites; conservative 15-file production
  envelope; 8-14 focused engineer-days.
- Complete migration: 23 production files/10,578 LOC/333 direct sites plus 22
  test files/12,789 LOC/174 direct sites; 22-38 focused engineer-days total.
- Highest-risk areas: transaction ownership/savepoints, generated journal IDs,
  pool lifecycle, connection PRAGMAs, startup backup/clone, TEMP replay tables,
  cancellation, and WAL concurrency.

No fused-architecture change has been ratified or implemented. Persisted DBOS
and journal state must be treated as potentially present; no runtime database
inventory has yet proven otherwise.

No fused-architecture change has been ratified or implemented.

## Architecture Research Status

1. Fused-design survey: complete and deferred after independent review.
   - Research recommendation was fusion; the user selected the split
     architecture for current delivery.
   - Keep `8de83b4` as accepted domain/query foundation.
   - Treat `9927cdb` as reusable parity evidence but mostly superseded adapter
     implementation if fusion proceeds.
   - Keep policy, material-event, validation, and identity work from `4a2c00a`;
     retain direct Apply and narrow replay/attach behavior for current delivery
     while replacing rejected unbounded event scans with `Journal().Facts()`.
   - Proposed verticals: expose DBOS transaction callback; extract Provenance
     `ApplyTx`; share one SQL transaction handle; replace the durable adapter;
     wire Pasture human decisions through `OperationApplier`; optionally fuse
     engine projection/audit writes; inventory old workflow state and delete
     obsolete code.

2. DBOS release/timing survey: complete.
   - Stable `v0.20.0` is Go proxy `@latest`; `v1.0.0-rc.1` is prerelease.
   - Public transaction datasources first shipped in v0.19; v0.20 retains them
     with additional SQLite cancellation, deadlock, and checkpoint fixes.
   - Exact shared-system-handle use dispatches to `runAsTxn`, atomically
     committing application writes and `operation_outputs`.
   - Temporary v0.20 dependency bumps passed Provenance `8de83b4` and Pasture
     `4a2c00a` tests without production source changes.
   - v0.16 to v0.20 SQLite migrations 36, 37, 40, and 41 are additive, but
     in-flight workflow, downgrade, and mixed-version behavior remain unproved.
   - The v0.20 dependency upgrade is tracked independently in GitHub issue #22.

3. Independent review: all three axes returned `REVISE`.
   - Correctness: generated IDs, immediate locking, replay observability, typed
     failures, old workflow cutover, and Pasture write ownership need revision.
   - Tests/migration: real v0.16 fixtures, ambiguity/rollback/cancellation
     matrices, mixed-version exclusion, and production wiring are required.
   - Elegance: retain service replay while input depends on mutable state,
     inventory the SQL seam before defining it, and delete only proven
     redundancy.

4. GitHub tracking:
   - DBOS v0.20 upgrade: <https://github.com/dayvidpham/provenance/issues/22>.
   - Deferred fusion: <https://github.com/dayvidpham/provenance/issues/23>.
   - Migration sizing: <https://github.com/dayvidpham/provenance/issues/23#issuecomment-5079603479>.

## Pasture Proposal-57 WIP

The Codex worktree contains a WIP `EpochHumanService` implementation covering
interaction mode, Plan UAT, ratification, Implementation UAT, landing, material
events, policy descriptors, reopen/replay tests, actor validation, and barrier
seams.

WIP commits:

- Pasture `4a2c00a`: `wip(tasks): checkpoint epoch human decisions`.
- Aura outer `12cc010`: records the submodule pointer.

Both commits carry Beads provenance headers for request `aura-plugins-ydhf9`,
Proposal 57, implementation plan `aura-plugins-w76i1`, slice
`aura-plugins-zyemi`, and blocker `aura-plugins-pvxx5`.

This WIP is not ready to land. It was checkpointed before resolving prior
REVISE findings. The write-boundary decision is now resolved in favor of the
split architecture, and one `worker-mini` is remediating the HumanEpochService
vertical against accepted Provenance `8de83b4`.

## Current Dependency Flow

```text
Proposal 61 [ratified]
  |
  +-> d29s context persistence [closed, integrated bd5814f]
  |
  +-> .1.4 Journal().Facts() [closed, integrated 8de83b4]
  |
  +-> consumer implementation gate [technically unblocked]

Provenance v0.0.4 plan
  |
  +-> .1.3 DBOS parity candidate 9927cdb [parallel review team active]
  |
  +-> fused architecture [deferred to provenance#23]
  |
  +-> cross-slice validation and human UAT

Proposal 57
  |
  +-> pvxx5 / zyemi HumanEpochService WIP [split architecture; in progress]
  +-> assignment aggregate
  +-> CLI and hidden adapter
  +-> generated harness adapters
  +-> executable acceptance corpus
  +-> Phase 11 human UAT
```

## Deferred Follow-Ups

The following earlier user-deferred `.1.2` UAT leaves remain non-critical:

- `providence-28y3`: result-slot cross-reopen coverage.
- `providence-591i`: malformed result-slot binding matrix.
- `providence-xp4p`: malformed legacy migration coverage.

Additional historical follow-ups:

- `providence-n999`: shared-base `borrowConnScope` cleanup.
- `providence-4c5g`: formatting cleanup overlapping downstream-owned files.

## Current Decision

- Continue the split architecture and downstream HumanEpochService work.
- Review and remediate `providence-j8i.1.3` in parallel through its separate
  agent team; integrate only after a clean independent round.
- Track DBOS v0.20 compatibility in provenance#22 and any future fused
  transaction migration in provenance#23.
- Complete `aura-plugins-pvxx5`, run independent code review, then continue the
  original Proposal-57 dependency plan.
- No push or upstream PR merge is authorized.
