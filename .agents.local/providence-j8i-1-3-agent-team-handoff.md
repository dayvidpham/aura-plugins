# Proposal 57 And Provenance Parallel Execution Handoff

Date: 2026-07-25

## Program Mission

Continue the ratified Proposal-57 implementation under the selected split
Provenance/DBOS architecture, with two independent active streams:

1. Remediate and review Pasture HumanEpochService (`aura-plugins-pvxx5`) against
   accepted Provenance `8de83b4`.
2. Review, remediate, and locally integrate the existing Provenance DBOS v0.16
   parity candidate (`providence-j8i.1.3`, `9927cdb`).

Use Task-tool subagents only:

- `worker-mini` for implementation and focused remediation.
- `reviewer-mini` for independent review rounds.

Do not use `aura-swarm`; it is deprecated for this work. Do not launch tmux
supervisors or external orchestration sessions.

## Current Delivery Decision

The user selected the existing split architecture for current delivery because
fusing DBOS and Provenance would require a substantial Zombiezen-to-modernc
transaction refactor.

Current production boundary:

```text
Pasture HumanEpochService
  -> Provenance Journal.Apply owns one domain transaction and exact replay

DBOSAdapter
  -> DBOS owns durable invocation/checkpoint/recovery
  -> invokes the same independently committing Journal.Apply
  -> Apply exact replay closes the commit/checkpoint crash gap
```

Deferred work:

- DBOS v0.20 upgrade: <https://github.com/dayvidpham/provenance/issues/22>.
- DBOS-owned fused transaction proposal:
  <https://github.com/dayvidpham/provenance/issues/23>.
- Measured migration surface:
  <https://github.com/dayvidpham/provenance/issues/23#issuecomment-5079603479>.

The minimal fused path was measured at about 3,118 Apply-reachable LOC, 132
functions, and 99 direct Zombiezen/sqlitex sites, or 8-14 focused engineer-days.
The complete migration covers 23 production files and 22 directly coupled test
files, estimated at 22-38 focused engineer-days. Neither migration is part of
the active implementation.

## Completed Foundations

- Proposal 61 `aura-plugins-v8594` is ratified.
- Corrective context persistence `providence-d29s` is closed, clean-reviewed,
  and locally integrated at `bd5814f`.
- Bounded `Tracker.Journal().Facts()` remediation `providence-j8i.1.4` is
  closed, clean-reviewed, and locally integrated at `8de83b4`.
- Provenance integration branch `feat/atomic-journal-primitives` is at
  `8de83b4`, unpushed.
- Pasture contract and acceptance foundations are at `87e6912` and `269c838`.
- HumanEpochService WIP checkpoint is `4a2c00a`.
- No branch has been pushed or merged through an upstream PR.

## Plan And Proposal Relationship

Arrows point from a prerequisite to the work that consumes it. The Beads
dependency command is expressed in the opposite reading direction: the
consumer is `--blocked-by` the prerequisite.

```text
 [Proposal 50: preserved Pasture baseline]
 [aura-plugins-jdj2x]
                 |
                 | lifecycle/CLI amendment
                 v
 [Proposal 57: epoch lifecycle delivery]
 [aura-plugins-tekqb]
                 |
                 +-----------------------------> [Proposal-57 implementation plan]
                 |                               [aura-plugins-w76i1]
                 |                                             |
                 | requires bounded journal reads              |
                 v                                             |
 [Proposal 61: fact-query substrate]                            |
 [aura-plugins-v8594]                                          |
                 |                                             |
                 | scopes context/query prerequisites          |
                 v                                             |
 [Provenance atomic-journal epic: providence-j8i]               |
                 |                                             |
                 v                                             |
 [Parent v0.0.4 implementation plan: providence-j8i.1]          |
                 |                                             |
                 v                                             |
 [.1.1 canonical contracts]                                    |
 [88d4d9a]                                                      |
                 |                                             |
                 v                                             |
 [.1.2 transactional SQLite Apply]                              |
 [338a336]                                                      |
                 |                                             |
                 v                                             |
 [d29s corrective context persistence]                          |
 [bd5814f]                                                      |
                 |                                             |
                 v                                             |
 [.1.4 bounded Journal().Facts()]                               |
 [accepted integration base: 8de83b4]                           |
                 |                                             |
                 +------------------------------+--------------+
                                                |
                         accepted 8de83b4        | accepted 8de83b4
                         is parent/base          | is consumed by Pasture
                                                |
                 +------------------------------+------------------------------+
                 |                                                             |
                 v                                                             v
 [.1.3 DBOS v0.16 parity]                                      [pvxx5 HumanEpochService]
 [candidate 9927cdb]                                           [split architecture]
 [review/remediation active]                                   [implementation active]
                 |                                                             |
                 v                                                             v
 [providence-j8i.1 cross-slice validation]                     [8cus8 replay/race proofs]
 [release UAT and v0.0.4 completion]                            |
                                                               v
                                              [zyemi Slice 57.1 integration]
                                                               |
                                                               v
                                              [xl4f8 Slice 57.2 assignment]
                                                               |
                                                               v
                                              [njyhk Slice 57.3 CLI/adapter]
                                                               |
                                                               v
                                              [dcu2d Slice 57.4 harnesses]
                                                               |
                                                               v
                                              [yi7ls Slice 57.5 acceptance]
                                                               |
                                                               v
                                              [Phase 11 user Implementation UAT]
```

Key interpretation:

- Proposal 50 remains the preserved product baseline; Proposal 57 amends its
  epoch lifecycle and CLI boundary rather than superseding all Proposal-50
  work.
- Proposal 61 supplied the bounded Provenance query/context prerequisite needed
  by Proposal-57 HumanEpochService. It did not define DBOS transport behavior.
- `.1.3` belongs to parent Provenance implementation plan
  `providence-j8i.1`. Its candidate starts from the accepted Proposal-61 query
  integration commit `8de83b4` so its DBOS gates include the final durable-table
  inventory and public journal shape.
- `.1.3` and `pvxx5` now run in parallel, but `pvxx5` consumes `8de83b4`, not
  unreviewed candidate `9927cdb`. Neither stream edits the other stream's files.

## Active Stream A: Pasture HumanEpochService

Task and plan:

- Leaf: `aura-plugins-pvxx5`, status `in_progress`.
- Slice: `aura-plugins-zyemi`.
- Implementation plan: `aura-plugins-w76i1`.
- Proposal: `aura-plugins-tekqb`.
- URD: `aura-plugins-hznvh`.

Worktree:

`/home/minttea/codebases/dayvidpham/aura-plugins/worktree/codex-codegen/pasture`

Current checkpoint: `4a2c00a` on `feat/codex-codegen`.

One `worker-mini` already owns this stream. Do not launch another worker against
the same files. Its required corrections are:

- Consume accepted local Provenance `8de83b4`, never `.1.3` candidate
  `9927cdb`.
- Persist a real `EffectActivityCreate`; do not represent activity only as an
  event.
- Use canonical decisions/evidence rather than duplicate event payload
  authority.
- Use bounded `Journal().Facts()` for authoritative reconstruction instead of
  unbounded subject-event scans.
- Put stale eligibility checks into transaction-local Provenance Fact
  conditions, not preflight alone.
- Preserve direct-Apply exact replay and `DecisionResult.Replayed` after reopen.
- Keep exact zero-write rejection for missing, unknown, ML, software, and
  reserved-system actors.
- Keep ratify and land as first-class user decisions with exact prerequisite
  bindings.
- Do not add a second graph, FSM, ledger, store, public operation ID, report
  file, expected revision, or payload codec.

The worker owns HumanEpochService and its focused tests plus narrowly required
tracker/open construction wiring. It does not own CLI handlers, runtime
mappings, generated adapters, assignment aggregate, candidate flows,
`internal/provadapter/**`, or acceptance leaf `aura-plugins-8cus8`.

If the unpushed Provenance commit is unavailable from the Go proxy, a temporary
local module replacement may be used for validation, but no absolute-path
`replace` directive or machine-local workspace artifact may remain in a commit.

After implementation:

1. Run independent A/B/C `reviewer-mini` code reviews.
2. Send findings to a `worker-mini`; reviewers retain finding closure authority.
3. Reach a clean review round.
4. Locally integrate at the declared Pasture integration point.
5. Continue `aura-plugins-8cus8`, then complete Slice `zyemi`.

## Active Stream B: Provenance J8I.1.3

### Mission

Take the existing Provenance `.1.3` candidate through independent review,
focused remediation if required, full validation, and local integration under
the currently selected split DBOS/Provenance architecture.

User direction:

> Wait a second. Let's actually work on .1.3 in parallel, in addition to
> aura-plugins-pvxx5. But let's pass this to a new agent team. Give them a good
> handoff message.

This supersedes only the immediately preceding decision to defer `.1.3`.
HumanEpochService work remains active in parallel under a separate worker and
separate repository/worktree.

### Exact State

- Beads task: `providence-j8i.1.3`.
- Parent plan: `providence-j8i.1`.
- Accepted integration base: `8de83b419e54eb7ffc01d062d892a0c690f25abc`.
- Candidate: `9927cdbfe4ac116227caaaad9b282925cb14844e`.
- Candidate branch: `fix/j8i-1-3-dbos-parity`.
- Candidate worktree:
  `/home/minttea/codebases/dayvidpham/provenance/worktree/j8i-1-3-dbos-parity`.
- Local integration branch/worktree:
  `feat/atomic-journal-primitives` at
  `/home/minttea/codebases/dayvidpham/provenance/worktree/atomic-journal-primitives`.
- `9927cdb` has exactly `8de83b4` as its parent and was green before being
  paused. It has not received independent code review and is not integrated.
- No push or upstream PR merge is authorized.

### Architecture Boundary

Implement and review the current split architecture only:

```text
DBOS v0.16 durable workflow/checkpoint/recovery
  -> one canonical Provenance OperationInput transport
  -> existing transaction-owning Journal.Apply
  -> exact Apply replay closes the domain-commit/checkpoint crash gap
```

Do not implement:

- DBOS v0.20 dependency migration.
- `NewDataSource` or `RunAsTransaction`.
- A DBOS-owned fused SQLite transaction.
- A Zombiezen-to-modernc migration.
- `ApplyTx` or a new SQL transaction abstraction.
- Changes motivated solely by the deferred fused architecture.

Future DBOS v0.20 work is tracked at
<https://github.com/dayvidpham/provenance/issues/22>. Future fusion is tracked
at <https://github.com/dayvidpham/provenance/issues/23>.

### Required Behavior

The candidate must preserve one semantic authority:

- `Canonicalize(OperationInput)` owns canonical input semantics.
- SQLite `Journal.Apply` owns conditions, typed conflicts, ordered effects,
  Activity creation, result slots, projections, exact replay, and commit.
- DBOS owns durable invocation, transport, retry classification, checkpointing,
  cancellation, crash recovery, and terminal retrieval.
- DBOS must not add a second canonicalizer, condition evaluator, replay
  comparator, transaction protocol, or ledger.

Required parity:

- Complete canonical `OperationInput`, including Conditions and ActivityID.
- Complete committed results and every result-slot arm.
- Typed `OperationConflict`, `ConditionFailure`, and `ActivityConflict`
  metadata before and after checkpoint/restart.
- Direct Apply, first durable delivery, and recovered delivery equivalence.
- Terminal domain failures do not retry.
- Initial SQLite BUSY/LOCKED acquisition remains retryable infrastructure.
- Cancellation remains distinct from domain rejection and retry exhaustion.
- Crash seams before Apply, after Apply commit/before DBOS checkpoint, and
  after checkpoint/before workflow completion produce one committed operation.
- Malformed or unknown input/outcome/slot data fails closed before trusted
  effects.

### Exclusive Ownership

Production files owned by `.1.3`:

- `dbos_contract.go`
- `dbos_wire.go`
- `dbos_outcome.go`
- `dbos_adapter.go`
- `go.mod`
- `go.sum`

Tests and fixtures owned by `.1.3`:

- DBOS transport, retry, recovery, crash-gap, cancellation, matrix, fixture,
  and durable-workflow files under `dbos_*`.
- `testdata/contract/dbos_*`.

Do not edit:

- `dbos_store.go` or borrowed fact forwarding.
- `journal_api.go` or public fact-query contracts.
- `internal/sqlite/**` query, schema, migration, replay, matcher, or mutation
  implementation.
- `docs/journal-relational-contract.md`.
- Pasture or Aura source files.

There are no hunk loans. If a blocker appears outside this ownership, report it
through Beads before broadening scope.

### Subagent Workflow

1. Read raw Beads records
   for `providence-j8i.1.3`, `providence-j8i.1`, `.1.2`, and `.1.4`.
2. Verify the candidate ancestry and inspect the complete `8de83b4..9927cdb`
   diff before assigning work.
3. Run a review-first cycle using three genuinely independent `reviewer-mini`
   subagents:
   correctness, test/recovery quality, and elegance/proportionality.
4. Reviewers must inspect source and tests, run relevant gates, and use the
   Phase-10 EAGER BLOCKER/IMPORTANT/MINOR Beads structure. No simulated reviews
   or supervisor self-approval.
5. If findings exist, assign disjoint production/test files to workers. Each
   file has exactly one owner. Prefer small remediation commits and independent
   re-review. Maximum three review-fix cycles before escalation.
6. Preserve reviewer ownership of finding verification and closure. Workers
   report fixes but do not self-close review findings.
7. Reach a clean 0 BLOCKER / 0 IMPORTANT / 0 MINOR independent round before
   integration.
8. After clean review, locally integrate the reviewed candidate into
   `feat/atomic-journal-primitives`, validate the combined commit, and update
   Beads. Do not push or merge an upstream PR.

The parallel Pasture `aura-plugins-pvxx5` `worker-mini` owns HumanEpochService files.
Do not coordinate by editing its worktree. Cross-repository communication goes
through Beads comments.

## Shared Validation Policy

Follow the project race-only test policy. Every `go test` command includes
`-race`; do not duplicate it with a non-race test run.

Required gates:

```bash
CGO_ENABLED=1 go test -race -count=1 ./... 
go vet ./...
CGO_ENABLED=0 go build ./...
git diff --check
nix flake check --no-build
```

Also run focused DBOS tests with `-race`, strict wire/outcome fixtures, crash
seams, retry classifications, cancellation, direct/durable/recovered parity,
and typed-error reconstruction. Record exact commands and results in Beads.

## Dependency Order After Active Streams

Proposal-57 downstream work remains ordered by the ratified integration points:

```text
pvxx5 HumanEpochService implementation and clean review
  -> 8cus8 replay/attribution/race proofs
  -> zyemi Slice 57.1 integration
  -> xl4f8 Slice 57.2 assignment aggregate
  -> njyhk Slice 57.3 CLI and hidden envelope
  -> dcu2d Slice 57.4 generated harness adapters
  -> yi7ls Slice 57.5 executable corpus and authentic gates
  -> Phase 11 user Implementation UAT
```

`.1.3` is an independent Provenance release vertical and may complete in
parallel. It does not block HumanEpochService because that service consumes
accepted `8de83b4`, not `9927cdb`.

## Documentation And Coordination

Current local reports:

- `.agents.local/provenance-j8i-status.md`
- `.agents.local/fused-dbos-provenance-architecture.md`
- This handoff document.

Keep those reports factual when commits, reviews, statuses, or integration
points change. Use Beads comments for cross-agent coordination and exact gate
evidence. Do not reverse dependency direction: a parent is blocked by work that
must finish first.

### Beads Database Locations

The canonical Provenance Beads database is rooted at:

`/home/minttea/codebases/dayvidpham/provenance`

Its issue prefix is `providence` because of an earlier naming mistake. This is
known and accepted. Do not rename the prefix, initialize another database,
migrate records, rewrite IDs, or attempt to "correct" `providence` to
`provenance`.

Run Provenance Beads commands from the Provenance repository or one of its
registered worktrees. Examples:

```bash
bd show providence-j8i.1.3
bd update providence-j8i.1.3 --status in_progress --json
bd comments add providence-j8i.1.3 "Progress: ..."
```

The canonical Aura/Pasture coordination Beads database is rooted at:

`/home/minttea/codebases/dayvidpham/aura-plugins`

Use it for `aura-plugins-*` records such as `aura-plugins-pvxx5`,
`aura-plugins-w76i1`, and the downstream Proposal-57 slices. Do not attempt to
represent a cross-repository dependency by creating a duplicate task in the
other database. Record cross-repository coordination through comments carrying
the exact external Beads ID, commit, worktree, and GitHub issue when relevant.

The `--blocked-by` target is always the work that must finish first. Parent
plans/slices are blocked by child implementation leaves, never the reverse.

## Safety And Landing

- Never install, enable, or modify Git hooks.
- Never use destructive Git commands or rewrite accepted history.
- Preserve unrelated worktree changes.
- Use `git agent-commit` for any new commits.
- Local commits and the final local integration merge are allowed.
- Do not push, publish, or merge a GitHub PR.
- Do not alter GitHub issues #22 or #23 except to add factual cross-reference
  comments if needed.
- Stop and report if candidate behavior requires a fused architecture or a
  modernc migration; those are explicitly outside `.1.3`.

## Combined Completion Report

Return:

- Review records and votes for every round.
- Findings created, fixed, verified, and deferred.
- Exact files and commits changed.
- Exact gate commands and results.
- Candidate and integration commit IDs.
- Beads status/closure updates.
- Confirmation that no hooks, pushes, publications, or upstream merges occurred.
- HumanEpochService implementation/review/integration status.
- `.1.3` implementation/review/integration status.
- Exact next ready Proposal-57 dependency leaves.
