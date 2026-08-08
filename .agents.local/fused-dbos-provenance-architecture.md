# Fused DBOS And Provenance Transaction Architecture

Status: Deferred research proposal; independent review returned REVISE

Date: 2026-07-25

## Delivery Decision And Tracking

The user selected the existing split transaction architecture for current
delivery because the Zombiezen-to-modernc transaction seam makes fusion a large
refactor. This document remains design and sizing evidence for future work; it
is not the active Proposal-57 implementation plan.

- DBOS v0.20 upgrade: <https://github.com/dayvidpham/provenance/issues/22>
- Deferred fused architecture: <https://github.com/dayvidpham/provenance/issues/23>
- Measured migration comment:
  <https://github.com/dayvidpham/provenance/issues/23#issuecomment-5079603479>
- `providence-j8i.1.3` and candidate `9927cdb` have resumed as a separate
  review-first split-architecture effort. They remain unintegrated.
- `aura-plugins-pvxx5` HumanEpochService work resumes against accepted
  Provenance `8de83b4` using the split architecture.
- No push or upstream PR merge is authorized.

## Research Recommendation

Adopt a DBOS-owned SQLite step transaction that invokes a transaction-scoped
Provenance domain kernel.

The target commit boundary atomically contains:

1. Provenance journal anchor, effects, result slots, and projections.
2. The corresponding DBOS `operation_outputs` step checkpoint.
3. One SQLite `COMMIT` owned by DBOS.

Do not treat the current `DBOSAdapter.Apply` design as the final architecture.
It defensively closes a real domain-commit/checkpoint crash gap, but most of its
workflow lookup, input fingerprint reconciliation, post-validation, replay, and
crash-gap test machinery exists because the two commits are separate.

The recommended route is:

1. Upgrade the embedded DBOS Go dependency from v0.16.0 to stable v0.20.0 and
   use its public `NewDataSource` plus `RunAsTransaction` API with the exact
   system `*sql.DB` handle.
2. Refactor the Provenance reducer into an `ApplyTx` domain kernel over a small
   transaction abstraction.
3. Keep standalone `Journal.Apply` as a thin transaction-owning wrapper for
   independent-library, bootstrap, migration, admin, and test consumers.
4. Route Pasture production lifecycle writes through a narrow durable
   `OperationApplier` implemented by the fused DBOS adapter.
5. Delete only split-boundary symbols proven redundant after compatibility
   inventory and fused recovery tests pass. A narrow service replay/attach path
   remains necessary unless the public `Replayed`/`ShortCircuited` contract is
   replaced and state-dependent canonicalization is eliminated.

## Inspected States

| Repository state | Commit | Worktree |
|---|---|---|
| Provenance accepted integration | `8de83b419e54eb7ffc01d062d892a0c690f25abc` | `/home/minttea/codebases/dayvidpham/provenance/worktree/atomic-journal-primitives` |
| Provenance DBOS parity candidate | `9927cdbfe4ac116227caaaad9b282925cb14844e` | `/home/minttea/codebases/dayvidpham/provenance/worktree/j8i-1-3-dbos-parity` |
| Pasture Proposal-57 WIP | `4a2c00aa26a1360fdd28822827883268009447e2` | `/home/minttea/codebases/dayvidpham/aura-plugins/worktree/codex-codegen/pasture` |

DBOS v0.16.0 was inspected from a detached source clone under
`/tmp/opencode/dbos-transact-golang-v0.16.0`, tag `v0.16.0`, commit
`e7847d0dbcf1f4bcb587b735bc26c17c9401b4c5`.

## Verified DBOS v0.16 Capability

### Private Fused Transaction Primitive

DBOS v0.16 already implements the required fused transaction internally:

- `dbos/workflow.go:1397-1402` defines private transaction callback types.
- `dbos/workflow.go:1754-1865` implements private `runAsTxn`.
- `dbos/workflow.go:1811-1822` begins one transaction and checks the existing
  step checkpoint through it.
- `dbos/workflow.go:1830` passes the same transaction to the application
  callback.
- `dbos/workflow.go:1843-1854` writes the DBOS `operation_outputs` checkpoint
  through that transaction.
- `dbos/workflow.go:1861-1864` commits application writes and checkpoint
  together.
- `dbos/dbq.go:23-50` exports SQL-like `Querier`, `Tx`, and `TxOptions`
  interfaces.
- `dbos/dbq.go:209-276` shows SQLite `dbos.Tx` wraps a real `*sql.Tx`.

This proves the implementation can atomically include arbitrary application
table writes in the same SQLite transaction as a DBOS step checkpoint.

The workflow terminal `SUCCESS` update remains a later transaction at
`dbos/workflow.go:1315-1378`. That does not reintroduce the application write
gap: recovery reads the committed step checkpoint, skips the application
callback, and then records terminal success.

### Missing Public API In v0.16

The required primitive is not public in v0.16:

- `runAsTxn` is unexported.
- Its generic transaction callback type is unexported.
- `DBOSContext` exposes `RunAsStep`, but no public transaction callback:
  `dbos/dbos.go:138-168`.
- Public `RunAsStep` executes the application callback first and writes the
  checkpoint later through a separate transaction:
  `dbos/workflow.go:1655-1751`.

Therefore the supported v0.16 public API cannot implement the fused boundary.
This limitation is resolved by stable DBOS v0.19 and v0.20, described below.

Rejected techniques:

- Reflection.
- `go:linkname`.
- Private DBOS SQL writes.
- Copying DBOS transaction/checkpoint internals into Provenance.

## DBOS Release And Upgrade Appendix

Research cutoff: 2026-07-25.

### Current Releases

| Category | Version | Status |
|---|---:|---|
| Go proxy `@latest` | `v0.20.0` | Newest non-prerelease release, published 2026-07-15 |
| Newest release/tag | `v1.0.0-rc.1` | Prerelease, published 2026-07-22 |
| Current local pin | `v0.16.0` | Released 2026-06-01 |

Authoritative references:

- <https://github.com/dbos-inc/dbos-transact-golang/releases>
- <https://github.com/dbos-inc/dbos-transact-golang/releases/tag/v0.20.0>
- <https://github.com/dbos-inc/dbos-transact-golang/releases/tag/v1.0.0-rc.1>
- <https://proxy.golang.org/github.com/dbos-inc/dbos-transact-golang/@latest>
- <https://proxy.golang.org/github.com/dbos-inc/dbos-transact-golang/@v/list>

Go v0.x modules do not promise compatibility between minor versions even when
the GitHub release is not marked prerelease.

### Relevant Changes Since v0.16

| Release | Relevant changes |
|---|---|
| `v0.17.0` | Retry predicates, workflow filters/step aggregates, queue deduplication, auth propagation, SQLite migrations 36-37. No public application transaction callback. |
| `v0.18.0` | Consolidated retries, database-backed queues, workflow-step pagination, metrics, SQLite migration 40, dependency updates. No public application transaction callback. |
| `v0.19.0` | First public `NewDataSource` and `RunAsTransaction`; shared-system-handle transaction fusion; child cancellation; preemptible sleep; workflow attributes. Includes savepoint correction for callback-error rollback. |
| `v0.20.0` | Retains public transaction datasource API; improves SQLite cancellation/deadlock/error propagation; transactional special steps; ambiguous checkpoint retry handling; SQLite migration 41. |
| `v1.0.0-rc.1` | Retains transaction API but introduces broad API renames and migration caveats; not recommended for this refactor while prerelease. |

### Public Fused API

Public application transactions first shipped in v0.19:

```go
ds, err := dbos.NewDataSource(dbosCtx, db)

result, err := dbos.RunAsTransaction(
    workflowCtx,
    ds,
    func(ctx context.Context, tx dbos.Tx) (Result, error) {
        // Application SQL through tx.
    },
)
```

Verified behavior in v0.20:

- `NewDataSource` accepts SQLite `*sql.DB`.
- The callback receives public `dbos.Tx`.
- `RunAsTransaction` must execute inside a workflow.
- Nested transactions are rejected.
- If the datasource is the exact same engine handle as the DBOS system
  database, DBOS dispatches to `runAsTxn`; application writes and
  `operation_outputs` commit in one transaction.
- Same file name, DSN, or WAL through a different handle does not activate the
  fused path. Detection uses handle identity.
- A separate datasource gets transaction-completion semantics but does not put
  application writes and system `operation_outputs` in one physical transaction.

Source references:

- <https://github.com/dbos-inc/dbos-transact-golang/blob/v0.20.0/dbos/datasource.go#L68-L145>
- <https://github.com/dbos-inc/dbos-transact-golang/blob/v0.20.0/dbos/datasource.go#L309-L381>
- <https://github.com/dbos-inc/dbos-transact-golang/blob/v0.20.0/dbos/workflow.go#L2157-L2333>
- <https://github.com/dbos-inc/dbos-transact-golang/blob/v0.20.0/dbos/internal/sysdb/dbq.go#L263-L275>
- <https://github.com/dbos-inc/dbos-transact-golang/blob/v0.20.0/dbos/datasource_test.go#L853-L1074>

The v0.19 callback-error savepoint fix is documented by upstream PRs 369 and
371 and is included in v0.19.0. v0.20 adds further SQLite cancellation and
checkpoint correctness fixes.

### Upgrade Compatibility

Temporary copies under `/tmp/opencode` were bumped from v0.16.0 to v0.20.0:

| Local state | Result |
|---|---|
| Provenance `8de83b4` | `go test ./...` passed |
| Pasture `4a2c00a` | `GOFLAGS=-buildvcs=false go test ./...` passed |

The plain dependency bump required no production source changes. Observed
changes were limited to `go.mod`/`go.sum` and transitive dependency versions.
Adopting `RunAsTransaction` is a separate architecture change affecting DBOS
adapter code, the Provenance SQL boundary, Pasture engine/tracker construction,
and lifecycle write wiring.

### DBOS SQLite Migrations

Upgrading a v0.16 SQLite system database (migration level 35) through v0.20
adds:

| Migration | Effect |
|---:|---|
| 36 | Nullable `workflow_status.completed_at` |
| 37 | `started_at` query index |
| 40 | Nullable `workflow_status.attributes` |
| 41 | Nullable `workflow_status.schedule_name` |

These migrations are additive and do not rewrite workflow IDs, inputs,
outputs, `operation_outputs`, step IDs, application versions, or queue rows.
Fresh-database tests do not prove upgrade/downgrade behavior for a real
persisted v0.16 database.

Remaining upgrade risks:

- Changed behavior for in-flight v0.16 cancellation and special steps.
- Recovery changes if an existing workflow changes from `RunAsStep` to
  `RunAsTransaction` under the same application version.
- Old domain-commit/checkpoint crash-gap states need explicit inventory and
  recovery tests.
- Downgrade after v0.20 migrations is unverified.
- Mixed v0.16/v0.20 executors against one SQLite file are unverified.
- Persisted custom errors/outcomes require fixture compatibility tests.

### Workflow Input Identity Limitation

DBOS does not compare stored semantic input when the same workflow ID is reused:

- `dbos/system_database.go:948-986` leaves stored inputs unchanged on workflow
  ID conflict.
- `dbos/system_database.go:1067-1072` checks workflow name and queue conflicts,
  not semantic input equality.

A fused design should include a stable semantic input fingerprint in its
workflow ID. Provenance `OperationID` remains the domain identity and final
typed conflict authority.

## Current Architecture

```text
Pasture EpochHumanService
    |
    | service-level LookupCommitted/event replay
    v
Journal().Apply(OperationInput)
    |
    | zombiezen connection
    | BEGIN IMMEDIATE
    | journal + effects + result slots + projections
    v
COMMIT domain state

Separately, when DBOSAdapter is used:

DBOS workflow
    |
    v
RunAsStep callback
    |
    v
Journal().Apply() -------- COMMIT domain state
    |
    | crash gap
    v
DBOS operation_outputs --- COMMIT checkpoint
    |
    v
postValidate / LookupCommitted / reconstruct / compare
```

The current architecture is correct only because Provenance independently
handles exact replay and current DBOS code validates workflow input, journal
identity, and checkpoint/domain result parity.

## Current Ownership Map

### DBOS Owns Today

- Workflow identity and status.
- Input/output persistence.
- Step retries and backoff.
- Pending-workflow recovery.
- Step checkpoint replay.
- Terminal workflow lookup and result retrieval.
- Durable cancellation state.

### Provenance Owns Today

- Canonical operation encoding and digest.
- `OperationID` domain identity.
- Exact domain replay and changed-input conflicts.
- Actor, authority, command, condition, and effect semantics.
- Transaction-local condition evaluation.
- Ordered effect folding and projections.
- Result-slot ownership and typed binding.
- Journal subtype/integrity checks.
- Committed-result reconstruction.
- The domain transaction and commit.

### Pasture Owns Today

- Human actor selection and policy validation.
- Service-level replay through `LookupCommitted` plus event scans.
- Direct calls to `Journal().Apply`.
- Deterministic decision/activity/event identities.
- Separate audit/projection deduplication for other engine paths.

## Target Architecture

```text
EpochHumanService
    |
    | OperationApplier only
    v
Provenance durable adapter
    |
    | semantic workflow identity
    v
DBOS RunAsTransaction
    |
    | one DBOS-owned SQLite transaction
    |
    +--> Provenance ApplyTx
    |       +-- canonical/domain identity
    |       +-- conditions
    |       +-- journal anchor and effects
    |       +-- result slots and projections
    |       `-- typed domain outcome
    |
    +--> DBOS operation_outputs checkpoint
    |
    `--> COMMIT both together

Later DBOS workflow_status -> SUCCESS

If the process stops before terminal SUCCESS, recovery reads operation_outputs,
does not call ApplyTx again, and completes the workflow status.
```

## Proposed APIs

### DBOS Public Transaction Callback

The smallest upstream/fork addition should delegate to existing `runAsTxn`:

```go
package dbos

type Transaction[R any] func(context.Context, Tx) (R, error)

func RunAsTransaction[R any](
    ctx DBOSContext,
    fn Transaction[R],
    opts ...StepOption,
) (R, error)
```

The final API name and option type must follow upstream conventions. Its
required semantic contract is one application callback and one step checkpoint
in the same transaction.

### Provenance Transaction-Scoped Kernel

Provenance should not import DBOS in its domain kernel:

```go
type SQLResult interface {
    RowsAffected() (int64, error)
}

type SQLRow interface {
    Scan(...any) error
}

type SQLRows interface {
    Next() bool
    Scan(...any) error
    Err() error
    Close() error
}

type SQLTx interface {
    Exec(context.Context, string, ...any) (SQLResult, error)
    Query(context.Context, string, ...any) (SQLRows, error)
    QueryRow(context.Context, string, ...any) SQLRow
}

type txJournal interface {
    ApplyTx(
        context.Context,
        SQLTx,
        OperationInput,
    ) (CommittedResult, error)
}
```

`ApplyTx` must not begin, commit, or roll back the outer transaction. A
savepoint may be required so a typed domain rejection leaves no partial domain
writes before DBOS checkpoints the failure outcome.

### Pasture/Durable Surface

Pasture should depend on a narrow interface, not DBOS implementation details:

```go
type OperationApplier interface {
    Apply(
        context.Context,
        OperationInput,
    ) (CommittedResult, error)
}
```

The concrete fused adapter remains inside Provenance:

```go
func NewDurableApplier(
    root dbos.DBOSContext,
    tracker Tracker,
    cfg DurableConfig,
) (OperationApplier, error)
```

`EpochHumanService` must not know workflow IDs, query DBOS status, or retrieve
workflow results directly.

### Standalone Wrapper

Standalone `Journal.Apply` remains public but becomes a thin transaction owner:

```go
func (db *DB) Apply(in OperationInput) (CommittedResult, error) {
    tx, err := db.beginWriteTx(context.Background())
    if err != nil {
        return CommittedResult{}, err
    }

    result, err := db.ApplyTx(context.Background(), tx, in)
    if err != nil {
        _ = tx.Rollback()
        return CommittedResult{}, err
    }
    if err := tx.Commit(); err != nil {
        return CommittedResult{}, err
    }
    return result, nil
}
```

Standalone Apply remains useful for independent library consumers, bootstrap,
migration, admin/repair tools, tests, and alternate orchestration systems. It
must not remain a second implementation.

## Workflow Identity

Recommended identity:

```text
workflow ID =
  "provenance.apply-tx/v1/" +
  SHA256(
    application contract +
    OperationID +
    actor +
    authority +
    command digest +
    canonical conditions/effects with provisional allocation IDs normalized
  )
```

Exclude `RecordedAt`; Provenance treats it as audit/display data, not replay
identity.

Expected behavior:

- Exact retry: same workflow ID; DBOS returns the checkpoint.
- Changed semantic input: different workflow ID; `ApplyTx` returns typed
  `OperationConflict` against the existing domain operation.
- Concurrent changed inputs: separate workflows serialize through SQLite; one
  commits and the other checkpoints a typed conflict.
- Allocated-create retries: semantic normalization prevents provisional UUIDs
  from changing workflow identity.

## Semantic Ownership After Fusion

DBOS should own:

- Workflow execution identity.
- Step sequencing.
- Retry scheduling and recovery.
- Step checkpointing and result retrieval.
- Durable cancellation between steps.
- The outer SQLite transaction.

Provenance must retain:

- `OperationID` as a domain/audit identity.
- Canonical mutation encoding and digest.
- Actor, authority, and command identity.
- Typed changed-input conflicts.
- Condition evaluation in the write snapshot.
- Genesis and authority rules.
- Ordered effect folding.
- Result-slot integrity.
- Journal and actor-placement invariants.
- Projection derivation.
- Committed-result reconstruction.
- Standalone transaction support.

The journal operation tables remain domain identity and audit provenance. They
are not deleted as duplicate execution checkpoints.

## Option Comparison

| Option | Correctness | Deletion | Operational model | Verdict |
|---|---|---:|---|---|
| A. Current split and dual replay | Correct through extensive reconciliation | None | Multiple replay/checkpoint owners | Reject as final design |
| B. Current DBOSAdapter with independently committing Apply | Defensively correct; retains crash gap | Small | Same file, separate transactions | Temporary fallback only |
| C. DBOS transaction plus Provenance ApplyTx | Atomic domain/checkpoint commit | Largest | One durable transaction owner | Recommend |

## Deletion Plan

| Current area | Proposed treatment | Approximate deletion |
|---|---|---:|
| `dbos_adapter.go` workflow lookup, input decoding, terminal diagnostics, post-validation | Replace with thin registration/run/await shell | 600-700 LOC |
| `dbos_contract.go` custom diagnostics and snapshots | Retain configuration and stable identity constants only | 200-250 LOC |
| `dbos_outcome.go` duplicate result transport/comparison | Replace with compact typed outcome | 450-550 LOC |
| `dbos_wire.go` duplicate context framing | Pass one canonical durable DTO | 180-230 LOC |
| `dbos_store.go` zombiezen same-file bridge | Delete after shared modernc handle adoption | 400-469 LOC |
| Workflow listed-input decoder/fingerprint reconciliation | Delete | 200+ LOC |
| Checkpoint post-validation/result divergence reconstruction | Delete | 185+ LOC |
| Pasture `epochHumanService.replay` | Delete | About 38 LOC |
| Human-service pre-commit replay branches | Delete/simplify | 15-25 LOC |
| Crash-gap hooks and large crash-gap matrices | Replace with transaction fault points | Large test reduction |

Retain:

- Journal operation tables.
- Domain identity comparison.
- Canonicalization and conditions.
- Result slots and projections.
- One committed-result reconstruction path in the kernel.
- Pasture audit deduplication initially for compatibility.

## LOC Estimate

Physical line counts include comments and blank lines because deletion removes
the associated documentation and test scaffolding.

Reproducible current counts:

```bash
wc -l dbos_adapter.go dbos_contract.go dbos_outcome.go dbos_store.go dbos_wire.go
# 2,563

git ls-files 'dbos*_test.go' | xargs wc -l
# 4,928

wc -l internal/tasks/epoch_human_service.go \
  internal/tasks/epoch_human_service_test.go
# 694
```

| Area | Current | Projected | Change |
|---|---:|---:|---:|
| Provenance DBOS production | 2,563 | 500-850 | -1,713 to -2,063 |
| Provenance DBOS tests | 4,928 | 1,200-1,600 | -3,328 to -3,728 |
| DBOS public transaction API/tests | 0 | 120-220 | +120 to +220 |
| Provenance transaction abstraction/kernel seam | 0 | 300-700 | +300 to +700 |
| Pasture human service/wiring | 694 | 560-680 | -14 to -134 |
| **Estimated net** | **8,185 relevant LOC** | **2,680-4,050** | **about -4,100 to -5,500** |

The original deletion projection above was not accepted by independent review
and must not be used as a delivery estimate. A subsequent call-graph and driver
inventory measured the migration directly:

| Scope | Production surface | Test surface | Focused effort estimate |
|---|---|---|---:|
| Minimal fused `ApplyTx` | About 3,118 reachable LOC, 132 functions, 99 direct Zombiezen/sqlitex sites; conservative 15-file/9,291-LOC envelope | 15 DBOS files/4,771 LOC; about 1,200-2,200 LOC expected edits | 8-14 engineer-days |
| Complete modernc migration | 23 production files, 10,578 LOC, about 333 direct driver sites | 22 files, 12,789 LOC, about 174 direct driver sites | 22-38 engineer-days total |

The high-risk full-migration areas are pool/open/close lifecycle, per-connection
PRAGMAs, in-memory keepalive, startup backup/clone replacement, TEMP/shadow
replay connection affinity, cancellation, and multi-handle WAL concurrency.

## Persistence Compatibility

No deployed runtime database was supplied or inspected. Persisted journal and
DBOS state must be treated as potentially present.

### Journal State

Keep unchanged:

- `journal_operations`.
- Canonical mutation bytes and encoding version.
- `journal_operation_result_slots`.
- Produced journal rows and projections.

The fused kernel should operate over these rows without a destructive journal
migration.

### DBOS State

Keep existing DBOS system tables. Do not rewrite or delete old workflow rows.

Use a new workflow prefix such as `provenance.apply-tx/v1/`. This avoids
interpreting old independent-commit checkpoints as fused checkpoints.

Existing terminal workflows remain inert. If the new path receives an already
committed `OperationID`, `ApplyTx` validates exact identity, reconstructs the
committed result, and atomically checkpoints that result under the new workflow
identity.

### In-Flight Workflow Cutover

Before cutover, inventory old workflow status read-only. The exact table name
must be confirmed against the configured DBOS schema.

For each old-prefix in-flight workflow:

- No journal row: restart through the fused path.
- Exact journal row: checkpoint the reconstructed result through the fused path.
- Conflicting journal row: stop for manual review.
- Never run old and fused adapters concurrently for the same operation set.

Deleting old DBOS rows is acceptable only for explicitly disposable
development databases after backup and user approval.

## Incremental Implementation Plan

| Slice | Vertical outcome | Acceptance criteria |
|---|---|---|
| 1. DBOS transaction capability | Public v0.20 `NewDataSource`/`RunAsTransaction` using the exact system handle | Success commits application rows and `operation_outputs` together; callback/domain rejection rolls back domain rows but durably records the intended typed error checkpoint; infrastructure failure and ambiguity follow explicit tested outcomes |
| 2. Provenance ApplyTx kernel | Existing reducer executes inside caller transaction | Direct Apply parity; conditions/effects share snapshot; typed conflicts unchanged; kernel never commits |
| 3. Shared SQL handle | Provenance adopts the DBOS modernc transaction/handle | No zombiezen transaction bridge; migrations remain idempotent; same exact transaction object is proven |
| 4. Fused durable adapter | Thin workflow around ApplyTx | Exact replay enters kernel once; changed input yields typed conflict; no workflow-list preflight/post-validation |
| 5. Pasture human decisions | EpochHumanService uses injected OperationApplier | No direct production Apply; no service event-scan replay; exact result bindings preserved |
| 6. Engine application writes | Projection/audit/activity writes optionally join transaction steps | Projection and audit cannot exist without checkpoint; recovery no longer needs crash-gap dedup |
| 7. Compatibility and deletion | Old workflow state inventoried; obsolete code removed | Old journal rows reopen; terminal old DBOS rows remain inert; no in-flight workflow is silently abandoned |

Local integration points should occur after each reviewed vertical. Dependent
work must branch from the accepted local integration commit, not `main` or
`develop`.

## Test Strategy

Retain domain tests for:

- Canonicalization.
- Conditions.
- Typed conflicts.
- Result slots.
- Projection replay.
- Existing-operation reconstruction.
- Concurrent writers.
- Bootstrap and migration.

Replace adapter crash-gap matrices with three core integration proofs:

1. Failure before fused commit leaves neither domain rows nor DBOS checkpoint.
2. Success commits both domain rows and DBOS checkpoint.
3. Process stop after fused commit but before workflow terminal update recovers
   without entering ApplyTx again.

Retain focused cancellation coverage proving caller wait cancellation does not
cancel durable local work and explicit DBOS cancellation does not interrupt an
executing transaction.

## Rollback Strategy

- Keep journal schema backward-readable.
- Introduce a new workflow prefix; do not repurpose old IDs.
- Quiesce and inventory old-prefix in-flight workflows before enabling fusion.
- Keep old adapter code until migration inventory and fused recovery tests pass.
- Roll back by deploying the old binary against unchanged journal tables.
- New-prefix DBOS rows may remain unused by the old binary.
- Do not drop DBOS or journal tables in this refactor.

## Existing Commit Disposition

| Commit | Classification | Treatment |
|---|---|---|
| `8de83b4` | Accepted foundation | Keep journal primitives, conditions, canonicalization, result slots, projections, conflict semantics, and query remediation |
| `9927cdb` | Active DBOS v0.16 parity candidate | Review and remediate under the split architecture; do not import v0.20 or fused-transaction scope |
| `4a2c00a` | Active split-architecture HumanEpochService WIP | Keep policies, event mapping, identities, validation, domain flow, direct Apply, and required replay/attach behavior; remediate prior correctness findings against `8de83b4` |

One integration mismatch must be resolved: Pasture `4a2c00a` pins an older
Provenance pseudo-version and references historical public naming. It cannot be
pointed at `8de83b4` without reconciling the `Journal` API and dependency pin.

## Fallback If DBOS v0.20 Cannot Be Adopted

Preference order:

1. Use stable DBOS v0.20.0 public `NewDataSource` and `RunAsTransaction` with
   the exact system `*sql.DB` handle.
2. If the dependency upgrade is prohibited, carry a minimal pinned v0.16 fork
   exposing existing `runAsTxn` behavior.
3. If neither is permitted, retain the current adapter with Provenance as domain
   commit owner and explicitly accept dual replay.

A Provenance-owned outbox is inferior here. It adds another dispatcher and
eventual-delivery state while still not atomically committing DBOS's own
checkpoint. Use it only if modifying or upgrading DBOS is prohibited.

## Superseded Timing Recommendation

The following was the survey recommendation before migration sizing and user
decision. It is retained as historical rationale only. The current decision is
to continue split-architecture production writes and defer fusion to GitHub
issue #23.

The fused architecture should block production write wiring, not all work.

Pause:

- `pvxx5` production writes.
- `EpochHumanService` direct Apply/replay implementation.
- Assignment/candidate/publication write paths using the same boundary.
- CLI/adapters wired to direct writes.
- Persisted-delta, crash, replay, and race acceptance fixtures for lifecycle
  mutations.

Continue in parallel:

- Public typed contracts and results.
- Actor, policy, assignment, and role validation.
- Canonical command/effect construction.
- Material-event mappings.
- Read-only projections and queries.
- CLI grammar, strict input parsing, and validate-before-open behavior.
- Harness classification, envelopes, schemas, and non-mutating translation.
- Corpus loaders, mutation operators, report formats, and generic snapshot
  readers.

This gate no longer blocks Proposal-57. If issue #23 is resumed later, a
production spike must still prove the exact shared-handle transaction before
any split-boundary code is deleted.

## Independent Review Outcome

Three independent plan reviewers returned `REVISE`:

- Axis A, correctness: exact-handle fusion is real, but generated journal IDs,
  immediate write ownership, typed failure checkpoints, replay observability,
  old workflow cutover, and Pasture write ownership were underspecified.
- Axis B, tests/migration: require the actual v0.20 datasource signature,
  callback/domain versus infrastructure failure matrices, real v0.16 fixtures,
  ambiguous-commit and rollback drills, mixed-version exclusion, and mandatory
  production-path Pasture wiring.
- Axis C, elegance: deleting service replay is unsafe while canonical input
  depends on mutable state; the SQL abstraction needs a complete reducer
  inventory; migration and deletion estimates must be measured separately; and
  only proven split-boundary redundancy should be removed.

These findings are incorporated into GitHub issue #23 acceptance criteria. No
fused proposal has been accepted or ratified.

## Review Questions

Independent reviewers should answer:

1. Do the cited DBOS internals actually guarantee one atomic application and
   checkpoint transaction?
2. Is the proposed SQL transaction abstraction sufficient for existing
   Provenance invariants without recreating a second storage layer?
3. Are any proposed deletions semantically unsafe?
4. Is workflow identity correct for exact retry, changed semantic input, and
   allocated-create reconciliation?
5. Is persistence cutover safe for existing terminal and in-flight workflows?
6. Are the LOC estimates reproducible and credible?
7. Should fusion block current write-bearing Proposal-57 work at the stated
   boundary?
