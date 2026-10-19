---
title: "DBOS Go changes since v1.2.0"
date: 2026-10-17
status: source-research-not-an-upgrade-plan
baseline: v1.2.0
latest_release: v1.7.0
references:
  task: https://github.com/dayvidpham/aura-plugins/01a148ea-8d12-7b6d-8d3c-fb32c97a4d2d
  upstream: https://github.com/dbos-inc/dbos-transact-golang
---

# DBOS Go changes since v1.2.0

## 1. Executive summary

As of **October 17, 2026**, the latest stable release of
`dbos-inc/dbos-transact-golang` is **v1.7.0**, published October 15. Compared with
v1.2.0, it contains **32 commits across five releases**. The largest changes are:

- **Messaging:** atomic `SendBulk`, caller-owned transactions for `Send` and
  `Enqueue`, and optional delivery to a workflow's recursive forks.
- **Repair and replay:** rewind a terminal workflow under its existing ID;
  fork with a timeout and replacement child-workflow references.
- **Execution correctness:** fencing tokens, durable timeout monitoring, panic
  handling, improved transactional-error handling, and a queue-concurrency fix.
- **Storage and operations:** separate workflow payload tables, database-clock
  timestamps, explicit partition limits, and separately managed migrations.
- **Compatibility:** the deprecated admin server is removed, priority scheduling
  no longer needs an enable flag, and **Conductor now requires a separate
  commercial extension module**.

**Recommendation:** evaluate v1.7.0 in staging rather than stopping at v1.6.0.
It includes correctness fixes missing from the earlier release. Treat this as a
database/runtime upgrade, not just a dependency bump. Audit Conductor usage,
admin-server configuration, schema consumers, and replay side effects first.
This report does not authorize or perform an upgrade.

## 2. Scope and evidence

This report covers the **Go SDK**, not all DBOS language SDKs or every DBOS Cloud
change. It combines upstream GitHub release notes with source inspection in
`/home/minttea/codebases/dbos-transact-golang`. Remote refs and tags were refreshed;
the checkout was not switched to a different revision.

| Reference | Pinned commit | Meaning |
|---|---|---|
| v1.2.0 | `fe1d839f0664210189b196f3a1fa9ae1a13024de` | Comparison baseline |
| v1.7.0 | `339705771d7e198c5bac9e213903820c0575e6c1` | Latest published stable release |
| Observed `origin/main` | `c94a80274cef2eb687df90065992e725545ac477` | One commit beyond v1.7.0 |

Unless noted otherwise, code citations below refer to **v1.7.0**. Release dates
come from GitHub's `published_at`, not commit dates. Diff size is 99 files changed,
9,551 insertions and 11,063 deletions; that includes tests and the removal of the
in-tree Conductor implementation, so it is not a measure of feature count.

The earlier conversation called v1.6.0 the latest release. That was accurate at
the time of that comparison; the three then-unreleased changes (#498–500) are now
in v1.7.0. One additional change remains unreleased in the snapshot above (§8).

**Evidence limits:** this is source research. No DBOS tests, performance
benchmarks, migration rehearsals, or downstream application compatibility tests
were run. Recommendations are assessments, not verified deployment guarantees.

## 3. Release-by-release inventory

### v1.3.0 — September 2, 2026 — 7 commits

| PR | Change | Practical significance |
|---|---|---|
| [#453](https://github.com/dbos-inc/dbos-transact-golang/pull/453) | Caller-owned transactions for `Enqueue` and `Send` | Commit workflow submission or messaging atomically with other writes in the same system database. |
| [#454](https://github.com/dbos-inc/dbos-transact-golang/pull/454) | Optimized dequeue dispatch | Dispatches workflows already claimed by the queue without repeating the status-insert path. |
| [#455](https://github.com/dbos-inc/dbos-transact-golang/pull/455) | Skip automatic migrations | Supports a privileged migration phase separate from application runtime; standalone clients verify rather than migrate the schema. |
| [#456](https://github.com/dbos-inc/dbos-transact-golang/pull/456) | Completion-based retention | Retention thresholds use completion time, not workflow creation time; introduces batched collection support. |
| [#457](https://github.com/dbos-inc/dbos-transact-golang/pull/457) | Fork execution timeout | Bounds a fork's execution; the timeout clock starts when dequeued. |
| [#458](https://github.com/dbos-inc/dbos-transact-golang/pull/458) | Replacement children when forking | Redirects copied child-workflow checkpoints to replacement workflow IDs. |
| [#462](https://github.com/dbos-inc/dbos-transact-golang/pull/462) | Application-name validation | Conductor/cloud applications must have valid names; self-hosted applications receive a warning instead. |

### v1.4.0 — September 16, 2026 — 6 commits

| PR | Change | Practical significance |
|---|---|---|
| [#463](https://github.com/dbos-inc/dbos-transact-golang/pull/463) | Explicit partition queue limits | Enforce per-partition limits alongside queue-wide limits. |
| [#459](https://github.com/dbos-inc/dbos-transact-golang/pull/459) | `SendBulk` | Persist many messages atomically as one durable workflow step. |
| [#468](https://github.com/dbos-inc/dbos-transact-golang/pull/468) | Resource cleanup | Closes the gzip writer on an export error path and query rows in fork tests. |
| [#471](https://github.com/dbos-inc/dbos-transact-golang/pull/471) | Root-only runtime lifecycle | Rejects launching or shutting down derived contexts. |
| [#470](https://github.com/dbos-inc/dbos-transact-golang/pull/470) | Workflow payload tables | Separates inputs and outputs from workflow status metadata. |
| [#473](https://github.com/dbos-inc/dbos-transact-golang/pull/473) | Database timestamps | Uses database-clock expressions for relevant durable timing writes instead of executor clocks. |

### v1.5.0 — September 29, 2026 — 5 commits

| PR | Change | Practical significance |
|---|---|---|
| [#476](https://github.com/dbos-inc/dbos-transact-golang/pull/476) | `RewindWorkflow` | Discard history from a cut point and replay under the same workflow ID. |
| [#480](https://github.com/dbos-inc/dbos-transact-golang/pull/480) | Remove deprecated admin server | `Config.AdminServer` and `Config.AdminServerPort` are gone, along with the HTTP implementation. |
| [#482](https://github.com/dbos-inc/dbos-transact-golang/pull/482) | Remove Docker Go dependencies | The local Postgres CLI helper now invokes the `docker` executable; Docker support itself is not removed. |
| [#481](https://github.com/dbos-inc/dbos-transact-golang/pull/481) | Deprecate `WithPriorityEnabled` | All queues dequeue in priority order; lower priority numbers run first. |
| [#484](https://github.com/dbos-inc/dbos-transact-golang/pull/484) | Handle workflow panics | Converts panics on DBOS-owned workflow execution goroutines into workflow errors. |

### v1.6.0 — October 7, 2026 — 10 commits

| PR | Change | Practical significance |
|---|---|---|
| [#485](https://github.com/dbos-inc/dbos-transact-golang/pull/485) | Conductor owns recovery when configured | Local startup does not independently recover pending workflows in that mode. |
| [#486](https://github.com/dbos-inc/dbos-transact-golang/pull/486) | Child deadline inheritance fix | Corrects propagation of parent deadlines. |
| [#487](https://github.com/dbos-inc/dbos-transact-golang/pull/487) | Centralized timeout monitor | Durably cancels expired workflows through a batched database monitor. |
| [#488](https://github.com/dbos-inc/dbos-transact-golang/pull/488) | Fork/non-fork filtering | Adds `WithFilterIsFork(bool)` for workflow queries. |
| [#489](https://github.com/dbos-inc/dbos-transact-golang/pull/489) | Fencing tokens | Prevents a superseded execution from writing the authoritative outcome or cancelling its successor through a stale context. |
| [#492](https://github.com/dbos-inc/dbos-transact-golang/pull/492) | Workflow ID reuse policies | Keep the default return-existing behavior or explicitly reject an existing ID. |
| [#490](https://github.com/dbos-inc/dbos-transact-golang/pull/490) | `WithSendToForks` | Delivers to the target and its currently visible recursive fork descendants. |
| [#494](https://github.com/dbos-inc/dbos-transact-golang/pull/494) | `GetAuthenticatedUser` | Reads the identity attached to the workflow, including from a step. |
| [#496](https://github.com/dbos-inc/dbos-transact-golang/pull/496) | Local Conductor metadata-only setting | Requests metadata-only operation through `Config.ConductorMetadataOnlyMode`. |
| [#493](https://github.com/dbos-inc/dbos-transact-golang/pull/493) | Data-source migrations | Versions DBOS transaction-checkpoint schemas and adds explicit migration/verification APIs. |

### v1.7.0 — October 15, 2026 — 4 commits

| PR | Change | Practical significance |
|---|---|---|
| [#498](https://github.com/dbos-inc/dbos-transact-golang/pull/498) | Enterprise extension boundary | Moves Conductor out of the core SDK; connecting now needs `go.dbos.dev/dbos-enterprise-go`. |
| [#499](https://github.com/dbos-inc/dbos-transact-golang/pull/499) | Explicit `INT4` notification step ID | Corrects the migration's CockroachDB column type for cross-SDK readers; does not rewrite an already-created column. |
| [#500](https://github.com/dbos-inc/dbos-transact-golang/pull/500) | Transient transactional DB errors | Restarts the transaction rather than checkpointing a transient error as the durable step result. |
| [#503](https://github.com/dbos-inc/dbos-transact-golang/pull/503) | Preserve worker slot until outcome write finishes | Avoids claiming a replacement while the completed body still has a pending database outcome. |

## 4. Messaging: Send and SendBulk

### What they do

Think of these APIs as durable messages addressed to an **existing workflow's
mailbox**, not HTTP requests or new workflow submissions. The sender identifies
the destination workflow and a topic. The destination receives on that topic
with `dbos.Recv[T](ctx, topic, timeout)`. Successful sending means persistence,
not that the receiving workflow has processed the message.

`Send` already existed in v1.2.0. The additions are caller transactions in v1.3.0,
`SendBulk` in v1.4.0, and fork delivery in v1.6.0.

```go
// Illustrative call inside an existing workflow or from an external Client.
err := dbos.Send(ctx, "approval-workflow-42", "approved", "decision",
    dbos.WithIdempotencyKey("approval-event-42"))
if err != nil {
    return err
}

// Both messages persist, or neither does. Both destinations must exist.
err = dbos.SendBulk(ctx, []dbos.SendMessage{
    {DestinationID: "order-42", Message: "confirmed", Topic: "orders",
        IdempotencyKey: "confirm-42"},
    {DestinationID: "inventory-42", Message: "reserve", Topic: "stock",
        IdempotencyKey: "reserve-42"},
})
```

| Property | `Send` | `SendBulk` |
|---|---|---|
| Scope | One message to one destination | Up to 10,000 input messages; destinations/topics can differ |
| Atomicity | One persisted message | Whole batch; an invalid destination fails the batch |
| Inside a workflow | One durable `DBOS.send` step | One durable `DBOS.sendBulk` step |
| External retry deduplication | `WithIdempotencyKey(key)` | `SendMessage.IdempotencyKey` on each entry |
| Fork delivery | Optional `WithSendToForks()` | Same option for the whole batch |
| Caller transaction | `WithSendTransaction(tx)` | Same option for the whole batch |

Important boundaries:

- Normal recovery replays recorded send steps without inserting again.
  **Explicit rewind is different**: discarded send history can cause a second
  delivery (§5). Do not equate durable messaging with exactly-once external effects.
- Outside a workflow, use stable idempotency keys when retrying an event. Keys
  are scoped per destination, but a bulk call additionally rejects duplicate
  nonempty keys **even when the destinations differ**.
- Both APIs are rejected inside a step body. Call them directly from the workflow,
  not inside `RunAsStep`.
- A caller-owned transaction must use the **DBOS system database**; the caller
  commits or rolls back. This option is unavailable inside a workflow. It cannot
  atomically couple writes in an unrelated application database.
- `WithSendToForks` targets descendants visible at lookup time, not future forks.
  Fan-out can insert more than 10,000 rows even though the input batch is capped.
- `WithPortableSend()` selects portable JSON for cross-language interoperability;
  it is not new in this comparison.

**Sources:** [`dbos/workflow.go:3301–3526`][messaging] and the system database's
[`Send` implementation][send-storage]. For `Enqueue`, the analogous option is
`WithEnqueueTransaction`; it cannot be combined with
`DeduplicationPolicyReturnExisting`, whose collision-retry behavior conflicts
with caller-owned transactions ([`workflow.go:2041–2061`][enqueue-transaction]).

**Assessment:** adopt bulk sending for all-or-nothing workflow notifications;
adapt caller transactions only where the writes genuinely share the system
database. Do not replace an external broker merely because this API exists.

## 5. Workflow repair, ownership, and execution

### Rewind is not resume, fork, or compensation

| Operation | Workflow identity | History behavior |
|---|---|---|
| Resume | Same ID | Reuses recorded steps; completed workflows are a no-op |
| Fork | New ID | Copies history before the cut point into a new workflow |
| Rewind | Same ID | Drops history from the cut point onward and replays it |

`RewindWorkflow[R]` defaults to step 0, discarding all step history. It is intended
for terminal workflows, including successful ones. Cancel an active workflow
first. Keeping the ID preserves the address used by peers and deterministic child
references; already-successful children can be adopted instead of rerun.

The side-effect rules are essential:

- Events at/after the cut revert to their previous recorded values or disappear.
- Messages consumed by the discarded portion are deleted. **All unconsumed
  messages are also deleted**, including ones sent before the rewind. Send new
  messages only after rewind returns.
- Registered data-source checkpoints are dropped so their transactions run again.
  A standalone `Client` must supply those sources via `WithRewindDataSources`.
- A discarded stream close is undone, but stream entries retain their offsets.
- A replayed send can deliver another copy to another workflow's mailbox.

Deleting a checkpoint does **not** undo its business writes, an HTTP request,
or another external effect. Rewind requires application-level idempotency or
compensation. The source describes these boundaries explicitly in
[`workflow.go:5355–5407`][rewind]. Fork options also add `Timeout` and
`ReplacementChildren` ([fork input and examples][fork]).

### Ownership and deadlines

Fencing associates an execution with an ownership token. Outcome writes require
both `PENDING` status and the matching `owner_xid`; an old execution cannot simply
overwrite a successor's result. Stale-context cancellation is fenced too.
This protects DBOS ownership decisions; it does **not** fence arbitrary external
services contacted by user code. See [the outcome update][outcome] and
[execution cancellation/ownership handling][execution].

The timeout monitor checks the application's durable deadlines on a one-second
interval, processing batches of up to 1,000. It can durably cancel expired work
regardless of the executor running it. These are polling settings, not a hard
one-second cancellation-latency guarantee ([`workflow.go:1828–1875`][timeouts]).

For duplicate IDs, the default remains `WorkflowIDReusePolicyReturnExisting`.
Use `WorkflowIDReusePolicyReject` through `WithWorkflowIDReusePolicy` or
`WithEnqueueWorkflowIDReusePolicy` to return `ErrWorkflowIDInUse` instead.
This differs from queue deduplication policy ([policy definitions][reuse]).

### v1.7.0 correctness fixes

[#500](https://github.com/dbos-inc/dbos-transact-golang/pull/500) separates
retryable transaction/database failures from durable step outcomes: it restarts
with a fresh transaction without spending the ordinary step-retry budget on those
failures. It does not make arbitrary side effects safe to repeat.

[#503](https://github.com/dbos-inc/dbos-transact-golang/pull/503) removes an
execution from the active set only after the outcome-write attempt finishes.
Its regression test stalls that write to verify that another queued workflow
does not take the still-occupied worker slot. This is a concrete reason to prefer
evaluating v1.7.0 over v1.6.0 for concurrency-sensitive workloads.

Panic recovery covers the goroutine DBOS owns; it is not a blanket recovery
mechanism for goroutines created by application code
([`workflow.go:1816–1825`][panic]).

## 6. Storage, migrations, and queue behavior

### Payload and retention changes

New writes place payloads in `workflow_input` and `workflow_output`, separating
them from status metadata. Read paths use `COALESCE` with legacy
`workflow_status` columns for older rows. This is **not** evidence that every old
payload was eagerly backfilled or that old readers understand new writes.
Review direct SQL dashboards, exports, and mixed-version deployments.

Retention changed from creation-time to completion-time thresholds. The payload
split also adds retention timestamps and indexes and removes the step-output
foreign key, supporting payload cleanup independently of status-row deletion.
Do not assume a configured retention cutoff has the same operational meaning
as it did in v1.2.0.

**Sources:** [#456](https://github.com/dbos-inc/dbos-transact-golang/pull/456),
[#470](https://github.com/dbos-inc/dbos-transact-golang/pull/470),
[payload schema][payload-schema], and [legacy-compatible payload reads][payload-read].

### Migrations can be separated from runtime

The relevant controls are:

- `Config.SkipMigrations`: verify the system schema instead of creating or
  migrating it. `NewClient` now uses verification automatically.
- `dbos.Migrate`: migrate the system database without launching the runtime.
- `dbos.MigrateDataSource`: migrate **DBOS's checkpoint schema** in a data-source
  database; this is not a general application/business-schema migration runner.
- `WithDataSourceSkipMigrations`: verify a data source's checkpoint schema.
- `WithMigrateApplicationRole`: grant runtime access after privileged migration.

An application can therefore use a deployment-time privileged migration step
and run with a lower-privilege identity afterward. System and data-source
migrations are separate; skipping one does not prepare the other. Legacy
data-source checkpoint tables also need the new version bookkeeping before
skip/verify mode will accept them.

The system grants helper grants broad privileges inside the DBOS system schema;
do not describe it as a per-operation minimal grant policy. Data-source grants
are narrower and cover checkpoint/version tables. Sources:
[`dbos/migrations.go:22–109`][migrations],
[`datasource_migrations.go:195–292`][datasource-migrations], and
[`dbos/dbos.go:787–824`][client].

System migrations now include **108–123**, covering partition limits, payload
tables and retention/index work, rewind bookkeeping, deadline indexing, and
creator identity. PostgreSQL migration SQL includes concurrent index operations;
generated scripts must not be blindly wrapped in a transaction block
([`MigrationStatements` documentation][migration-statements]). Rehearse the actual
backend's migration path rather than assuming PostgreSQL, CockroachDB, and SQLite
have identical DDL behavior.

**CockroachDB caveat:** #499 changes migration 121 to create
`notifications.consumed_by_function_id` as `INT4`, not `INTEGER` (which defaults
to `INT8` on CockroachDB). It uses `ADD COLUMN IF NOT EXISTS`, so a column already
created as `INT8` **stays INT8**. Inspect existing installations separately if
cross-SDK readers expect a 32-bit value. No automatic corrective migration is
claimed by this release ([commit explanation][int4]).

### Queue limits and priorities

New `WithPartitionConcurrency`, `WithPartitionWorkerConcurrency`, and
`WithPartitionRateLimiter` options distinguish partition-wide, per-executor,
and rate limits from queue-wide limits. Setting a partition limit enables
partitioning. The old `WithPartitionQueue` mode is deprecated; its queue-wide
settings apply per partition, unlike the new explicit model.

`WithPriorityEnabled` remains as a deprecated option but no longer changes
scheduling. All queues use priority order, with lower numbers first. Audit
workloads that previously depended on priority being disabled rather than
treating this as documentation-only deprecation
([`queue.go:335–388`][queue]).

## 7. Compatibility and operational changes

| Area | Verified change | Upgrade action |
|---|---|---|
| Admin HTTP server | Removed, including `Config` fields | Remove old configuration and replace any health/admin endpoint integrations explicitly. |
| Conductor | Requires the commercial `go.dbos.dev/dbos-enterprise-go` module | If used, add its blank import and align its minor version with the core SDK; verify commercial terms separately. |
| Standalone runtime | Core operation does not require that import when Conductor is not configured | Do not add the extension unnecessarily. |
| Recovery | A configured Conductor drives recovery instead of local self-recovery | Exercise executor restart/recovery in the actual deployment mode. |
| Derived contexts | `Launch` and `Shutdown` reject derived contexts | Retain the root context returned by `NewContext` for lifecycle calls. |
| Application names | 3–256 lowercase letters, digits, hyphens, or underscores | Fix invalid cloud/Conductor names; self-hosted deployments warn. |
| Postgres idle transactions | SDK-created connections default to a one-minute idle-in-transaction timeout | Review long-idle transactions; negative `SystemDBIdleTransactionTimeout` preserves the server setting. |
| Auth identity | `GetAuthenticatedUser` reads attached/inherited workflow identity | Treat it as metadata retrieval, not authentication or authorization enforcement. |
| Local Postgres helper | Invokes the Docker CLI instead of the Docker Go SDK | Ensure the `docker` executable is available when using the helper. |
| Go version | `go 1.25.0` unchanged; toolchain directive moves from `go1.25.13` to `go1.26.9` | Check CI/toolchain selection; do not confuse the preferred toolchain with the declared language minimum. |

The enterprise source explicitly documents:

```go
import _ "go.dbos.dev/dbos-enterprise-go"
```

Without a registered extension, configuring a Conductor connection returns an
initialization error explaining the requirement. This is not just a renamed
package inside the original module. The commercial extension's implementation,
licensing terms, and runtime behavior were **not** audited in this report.

**Sources:** [enterprise contract][enterprise], [runtime configuration][config],
[root lifecycle and recovery][lifecycle], [authenticated-user API][auth],
[Docker CLI helper][docker], and [Go module metadata][gomod].

## 8. Unreleased change after v1.7.0

The observed `origin/main` contains one extra commit:
[`c94a802` / #502](https://github.com/dbos-inc/dbos-transact-golang/commit/c94a80274cef2eb687df90065992e725545ac477),
**`WithMergeAttributes` for `SetWorkflowAttributes`**.

It shallow-merges top-level keys instead of replacing the whole attributes map.
Unrelated keys survive; matching nested objects are replaced, not recursively
merged. A nil value is JSON null; a nil map is rejected. The implementation uses
a single database update. This option is **not available in v1.7.0** and is not
part of the released-change count above. Do not base a v1.7.0 upgrade on it.

## 9. Recommended evaluation and acceptance checklist

| Priority | Recommendation | Rationale |
|---|---|---|
| First | Audit compatibility and schema access before changing the dependency | Admin removal and the Conductor module split can break existing integrations. |
| First | Rehearse system and data-source migrations on a restored copy | Payload storage and checkpoint bookkeeping changed; rollback/mixed-version safety is not established here. |
| Next | Evaluate v1.7.0 with actual recovery/concurrency workloads | Includes transient-transaction and worker-slot fixes. |
| Selective adoption | Use bulk messages and explicit partition limits where needed | Useful new contracts without requiring every workflow to change. |
| Restricted operation | Treat rewind as a controlled repair procedure | It discards history and can repeat effects, not undo them. |
| Defer | Attribute merging from main | Unreleased at the pinned snapshot. |

Suggested downstream acceptance cases, **not executed for this report**:

- [ ] Existing application compiles without removed admin-server fields;
  custom `Client`/`Context` implementations or mocks satisfy the expanded interfaces.
- [ ] Runtime and standalone client start after separately managed migrations;
  verify-only mode fails clearly against an outdated schema.
- [ ] Old workflow inputs/results remain readable after migration; custom SQL
  consumers read payloads correctly for both old and new workflows.
- [ ] A send batch with one missing destination persists no messages; retrying
  with stable idempotency keys does not duplicate inserts.
- [ ] A caller-transaction send/enqueue becomes visible only on commit and
  disappears on rollback.
- [ ] Restart and ownership-transfer scenarios do not let stale executions
  overwrite outcomes; queue limits hold while outcome writes are delayed.
- [ ] Child deadlines, timeouts, panics, and transient transaction failures follow
  the application's intended retry/failure policy.
- [ ] Rewind behavior is checked with consumed/unconsumed messages, successful
  children, data-source writes, streams, and externally visible effects.
- [ ] Conductor connectivity, recovery, and metadata-only settings are verified
  with the actual extension when that integration is used.
- [ ] Existing CockroachDB notification column types and cross-language readers
  are checked rather than assumed repaired by #499.

## 10. Sources and reproduction

Release notes:
[v1.3.0](https://github.com/dbos-inc/dbos-transact-golang/releases/tag/v1.3.0),
[v1.4.0](https://github.com/dbos-inc/dbos-transact-golang/releases/tag/v1.4.0),
[v1.5.0](https://github.com/dbos-inc/dbos-transact-golang/releases/tag/v1.5.0),
[v1.6.0](https://github.com/dbos-inc/dbos-transact-golang/releases/tag/v1.6.0),
[v1.7.0](https://github.com/dbos-inc/dbos-transact-golang/releases/tag/v1.7.0).
Full released comparison:
[v1.2.0…v1.7.0](https://github.com/dbos-inc/dbos-transact-golang/compare/v1.2.0...v1.7.0).

Read-only inspection after fetching refs, from the local DBOS clone:

```sh
git rev-parse 'v1.2.0^{}' 'v1.7.0^{}' origin/main
git rev-list --count v1.2.0..v1.7.0
git log --oneline v1.2.0..v1.7.0
git diff --stat v1.2.0 v1.7.0
git log --oneline v1.7.0..origin/main
git show v1.7.0:dbos/workflow.go
git show v1.7.0:dbos/enterprise.go
```

The source links below use immutable commit IDs so later releases do not silently
change the cited contracts.

[messaging]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L3301-L3526
[send-storage]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/internal/sysdb/system_database.go#L4289
[enqueue-transaction]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L2041-L2061
[rewind]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L5355-L5407
[fork]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L5424-L5565
[outcome]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/internal/sysdb/system_database.go#L2045
[execution]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L1590-L1813
[timeouts]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L1828-L1875
[reuse]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L851-L896
[panic]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L1816-L1825
[payload-schema]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/internal/sysdb/migrations/109_create_workflow_payload_tables.sql
[payload-read]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/internal/sysdb/system_database.go#L1625-L1652
[migrations]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/migrations.go#L22-L109
[datasource-migrations]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/datasource_migrations.go#L195-L292
[client]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/dbos.go#L787-L824
[migration-statements]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/migrations.go#L121-L139
[int4]: https://github.com/dbos-inc/dbos-transact-golang/commit/d64de28d11c841f5918eb6667683e7fee30a1a87
[queue]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/queue.go#L335-L388
[enterprise]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/enterprise.go#L3-L70
[config]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/dbos.go#L41-L154
[lifecycle]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/dbos.go#L857-L984
[auth]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/dbos/workflow.go#L4715-L4739
[docker]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/cmd/dbos/postgres.go#L54-L89
[gomod]: https://github.com/dbos-inc/dbos-transact-golang/blob/339705771d7e198c5bac9e213903820c0575e6c1/go.mod#L1-L5
