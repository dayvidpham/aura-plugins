---
references:
  request: aura-plugins-j9c88
  elicit: aura-plugins-pcnhq
  urd: aura-plugins-dr2ps
  ratified_proposal: aura-plugins-kf87g
  superseded_proposal: aura-plugins-9z5wg
  handoff: aura-plugins-79ysg
  uat_plan: aura-plugins-n3ecv
  proposal_artifact: docs/proposals/PROPOSAL-2-pasture-workflow-record.md
  related_pasture_urd: aura-plugins-jbnx3
  related_pasture_proposal_ratified: aura-plugins-wab79
  related_providence_urd: aura-plugins-f85gw
  related_providence_proposal_ratified: aura-plugins-5k40z
---

# IMPL_PLAN: Unified Pasture workflow record + observability (PROPOSAL-2)

Phase 8 implementation plan derived from architect handoff `aura-plugins-79ysg` and ratified PROPOSAL-2 (`aura-plugins-kf87g`, artifact at `docs/proposals/PROPOSAL-2-pasture-workflow-record.md`, 945 lines).

This plan decomposes the 11 PROPOSAL-2 slices (S1–S11) into a buildable, dependency-ordered, BDD-scenario-mapped wave plan that workers can execute in parallel where possible. The PROPOSAL artifact remains the source of truth; this plan is the operational coordination document.

---

## §1. Cross-cutting concerns

### §1.1 Package layout (UAT-1 placement direction binding)

| Concern | Location | Visibility |
|---|---|---|
| `TaskTracker` interface (Go embedding of `provenance.Tracker` + 4 inline audit methods + 6 pasture-only methods (audit methods inlined to break import cycle)) | `pasture/pkg/protocol/tasktracker.go` | **public** (importable by other dayvidpham modules) |
| `OpenTaskTracker(dbPath string) (TaskTracker, error)` constructor | `pasture/pkg/protocol/tasktracker.go` | **public** |
| `AutomatonRole` enum (6 values: `None`, `ConstraintChecker`, `TransitionGate`, `HookHandler`, `ConsensusReached`, `CreateFollowup`) | `pasture/pkg/protocol/agent_categories.go` (new file) | **public** |
| `PastureRole` enum (5 values) | `pasture/pkg/protocol/agent_categories.go` | **public** |
| `ContextKind` enum (8 values incl. `None`) | `pasture/pkg/protocol/context_kind.go` (new file) | **public** |
| `Context` struct `{Kind, ContextID}` | `pasture/pkg/protocol/context_kind.go` | **public** |
| `TaskTracker` implementation | `pasture/internal/tasks/tracker.go` (new) | **private** |
| Audit migration framework + migrators v1→v2→v3→v4 | `pasture/internal/audit/migrate.go` (new), `migrate_v1_v2.go`, `migrate_v2_v3.go`, `migrate_v3_v4.go` | **private** |
| `audit_schema_meta` table reads/writes | `pasture/internal/audit/schema_meta.go` (new) | **private** |
| `pasture_well_known_agents` startup registration | `pasture/internal/tasks/well_known.go` (new) | **private** |
| `CategoryStorage` (exit code 5) addition | `pasture/internal/errors/errors.go` (modify) | **public-ish** (errors package consumed by all CLIs) |
| New CLI subcommands `pasture task events / timeline / contexts / agents` | `pasture/cmd/pasture/task_events.go`, `task_timeline.go`, `task_contexts.go`, `task_agents.go` (new) | n/a (cmd) |
| Top-level CLI `pasture migrate` | `pasture/cmd/pasture/migrate.go` (new) | n/a |
| Handler functions for new CLI subcommands | `pasture/internal/handlers/task_events.go`, etc. (new) | **private** |

### §1.2 Migration testing strategy (binding)

- **All file-backed integration tests use `t.TempDir()`**, not `/tmp` or in-memory SQLite. Rationale (PROPOSAL-2 §10.3, handoff §7): in-memory SQLite bypasses WAL, busy_timeout, and fsync — the exact mechanisms D11 (low write contention is fine) and the `BEGIN IMMEDIATE` transactional semantics rely on.
- **Checked-in fixture `pasture/testdata/legacy_audit_v1.db`** (Scenario 4, BLOCKER B5, fixture composition specified row-for-row in PROPOSAL-2 §11 Scenario 4): 1024 rows, 7 distinct roles, 12 phases + ~100 NULL phase rows, payload edge cases (empty objects, deeply-nested, UTF-8 `café`, >8KB, top-level arrays), epoch_id shapes (768 valid TaskIDs, 192 free strings, 64 duplicates). Tests **copy** this fixture to `t.TempDir() / "<scenario>.db"` before migrating — never mutate the checked-in file.
- **Crash test mechanism (Scenario 11)**: A dedicated test-only binary `cmd/pasture-migrate-crash/main.go` that performs the v2→v3 migration but is wired to `os.Exit(137)` after `INSERT INTO audit_schema_meta (version=3, ...)` but before `tx.Commit()`. Built with the standard `go build` toolchain and invoked from S3's test code via `os/exec.Cmd`. Do NOT use a build-tag-gated alternative — handoff §7 specifies the dedicated binary mechanism.
- **Concurrent-migrator test mechanism (Scenario 12)**: Two `os/exec.Cmd` processes spawning `pastured --db <race.db> --idle-after-migrate=1s` simultaneously, aligned via shared OS-level synchronisation (e.g., a sentinel file each process polls before issuing `BEGIN IMMEDIATE`). The `--idle-after-migrate` flag is added in S7 to let the test observe steady-state row counts before the daemon would otherwise begin work.

### §1.3 Race testing strategy (binding)

- Per PROPOSAL-2 §10.3 (BLOCKER B3): file-backed cross-subsystem race test in `pasture/internal/tasks/tracker_race_test.go` (S5) with `tempDir + filepath.Join("race.db")`, `N=64` goroutines each randomly invoking one of `{audit.Trail.RecordEvent, protocol.TaskTracker.AttachContext, provenance.Tracker.CreateTask, provenance.Tracker.StartActivity}`, `>1000` iterations under `go test -race`.
- Assertions: zero un-retried `SQLITE_BUSY`, zero `SQLITE_LOCKED`, all rows present in their expected tables, `PRAGMA integrity_check = "ok"`.
- This single race test proves D11 (low write contention is fine) AND C5 (single SQLite file across two subsystems works).

### §1.4 Error shape policy (binding)

- All errors raised by **new** code (S1–S11) MUST be `*pasterrors.StructuredError{Category, What, Why, Impact, Fix}` per `pasture/internal/errors/errors.go`. **Plain `fmt.Errorf` is forbidden in new code** per pasture/CLAUDE.md "Actionable Errors" convention and PROPOSAL-2 BLOCKER A3.
- New `CategoryStorage` value (PROPOSAL-2 §7.10.5) lands in S1; exit code 5; used by all migration / open / version-mismatch failures.
- `OpenTaskTracker` returns `CategoryConnection` (open failures), `CategoryStorage` (migration failures), `CategoryValidation` (newer-schema-than-binary rejection).
- Workflow start path (`cmd/pasture-msg/epoch.go`) and `Activities.RecordTransition` reject malformed epoch-IDs with `CategoryValidation` per §7.12.
- Existing code using `fmt.Errorf` is **preserved as-is** (don't rewrite for the sake of consistency); new code paths follow the StructuredError convention.

### §1.5 Provenance no-modification compliance (C4 binding)

- **No commits to `github.com/dayvidpham/provenance` are permitted as part of this work.** Verified per Scenario 3 (`git log --oneline ../../../../provenance` shows no implementation-epoch commits).
- Where idempotency requires `(namespace, name)` lookups against `agents_software` (S3 v3 backfill, S7 well-known agent registration), the audit migrator opens its own `*sql.DB` against the same shared SQLite file and runs raw SQL queries that match the SQL shape Provenance uses internally. This is C4-compliant because:
  1. Same file, same process — `BEGIN IMMEDIATE` on the migrator's `*sql.DB` serialises against any concurrent Provenance writer in the same process.
  2. No Provenance Go API change.
  3. The find-or-create raw-SQL pattern uses the same `INSERT INTO agents (id, kind_id) VALUES (?, 2); INSERT INTO agents_software (agent_id, name, version, source) VALUES (?, ?, ?, ?)` shape Provenance uses internally (see PROPOSAL-2 §7.10.2).
- The audit migrator's raw-SQL access is **read-mostly + matches Provenance's INSERT shape exactly**; reviewer must verify no schema deviation in code review.
- The Provenance source is at `~/codebases/dayvidpham/provenance/` for reference (NOT to be modified). Worker S5 must read `provenance/tracker.go` for the canonical `Tracker` interface signature to embed correctly.

### §1.6 Quality gates (binding pre-commit)

Per `pasture/CLAUDE.md`:

```bash
make fmt    # gofmt — fails if any file needs formatting
make lint   # go vet ./...
make test   # go test -race ./...
make build  # CGO_ENABLED=0 go build ./...
```

All four MUST pass before each `git agent-commit`. The `-race` flag is mandatory on every test run.

Additional gate: `nix flake check --no-build 2>&1` per pasture/CLAUDE.md "Validation" section — though the pasture flake itself is independent of the aura-protocol flake; workers should verify the pasture-internal flake is unaffected by their changes.

### §1.7 Commit convention (binding)

- Workers commit via `git agent-commit -m "..."`, NOT `git commit`. Per `~/.claude/CLAUDE.md` C-agent-commit constraint and pasture/CLAUDE.md.
- Conventional Commits format: `feat(pastured): ...`, `feat(pasture): ...`, `feat(audit): ...`, `fix(pasture-msg): ...`, `chore: ...`. Per pasture/CLAUDE.md "Commit Convention" section.
- Atomic commits per slice — prefer one commit per leaf task (L1: types, L2: tests, L3: impl) rather than batching multiple slices into one commit.
- Workers do NOT push (`git push`) — Phase 12 landing is owned by the team-lead user, not the supervisor or workers.

### §1.8 Dependency policy (binding)

- Approved external dependencies only: `spf13/cobra`, `spf13/viper`, `go.temporal.io/sdk`, `modernc.org/sqlite`, plus the existing `github.com/dayvidpham/provenance` (already in `go.mod`).
- **No `mattn/go-sqlite3`** — pure-Go SQLite via `modernc.org/sqlite` is mandatory (CGO_ENABLED=0 binary requirement).
- New dependencies require supervisor approval; workers may NOT add to `go.mod` without escalating via beads comment first.

### §1.9 Module + Go version

- Module: `github.com/dayvidpham/pasture`.
- Go 1.23+.
- CGO disabled (`CGO_ENABLED=0`).
- All build commands set `CGO_ENABLED=0` (already in `Makefile`).

---

## §2. Dependency order between slices

```
                   ┌─────────────┐
                   │ S1: Schema  │  (audit_schema_meta + version-detection +
                   │  migration  │   migrator scaffold + CategoryStorage)
                   │ foundation  │
                   └──────┬──────┘
                          │
                          ▼
                   ┌─────────────┐
                   │ S2: New     │  (context_edges, pasture_agent_categories,
                   │  tables     │   pasture_well_known_agents schemas; v2→v3)
                   └──┬──────────┘
                      │
        ┌─────────────┼─────────────┐──────────────────────┐
        ▼             ▼             ▼                      │
   ┌─────────┐  ┌──────────┐  ┌──────────┐                │
   │ S3:     │  │ S5:      │  │ S9: Free-│  ┌──────────┐  │
   │ AgentID │  │ Tracker  │  │ floating │  │ S7: Well-│  │
   │ attrib. │  │ interface│  │  events  │  │  known   │  │
   │ (v3)    │  │  + impl  │  │  record. │  │  agents  │  │
   └────┬────┘  └────┬─────┘  └──────────┘  └────┬─────┘  │
        │            │                            │        │
        ▼            ▼ ▼ ▼                        │        │
   ┌─────────┐    [S5 enables S6, S7, S8, S9, S10]│        │
   │ S4:     │                                    │        │
   │ Epoch   │     ┌────────┐ ┌────────┐ ┌──────┐ │        │
   │ Context │     │ S6:    │ │ S8:    │ │ S10: │ │        │
   │ migr.   │     │ CLI    │ │Workflow│ │ cmd  │◄┘        │
   │ (v4)    │     │subcmds │ │ integ. │ │ wire │          │
   └─────────┘     │+migrate│ │+§7.12  │ │      │          │
                   └────┬───┘ └────────┘ └──────┘          │
                        │                                  │
                        ▼                                  │
                   ┌──────────────────────────────────────┘
                   │
                   ▼
              ┌─────────────┐
              │ S11: Docs   │
              │  + ADR      │
              └─────────────┘
```

**Sequential chain (forced):** S1 → S2 → S3 → S4. The migration framework, then table additions, then column additions/backfills, then column drops MUST happen in version order; no other ordering preserves the v1→v2→v3→v4 invariant.

**Parallel-eligible (after S2 lands):**
- S5 (TaskTracker interface + impl) — different package (`pkg/protocol`, `internal/tasks`); only depends on existing `provenance.Tracker` and `audit.Trail` types.
- S7 (well-known agents at startup) — needs `pasture_well_known_agents` table from S2; independent of S3/S4.
- S9 (free-floating event recording) — needs `context_edges` table from S2 and `protocol.TaskTracker` from S5.

**S6 (CLI) depends on S5** — new subcommands route through `protocol.TaskTracker`.

**S8 (workflow integration) depends on S5 + S7** — Activities call `protocol.TaskTracker.RecordEvent` then `AttachContext`; needs S7's well-known agent IDs cached for activity attribution.

**S10 (cmd/pasture wiring) depends on S5 + S6** — `cmd/pasture` re-routes through `protocol.TaskTracker` (S5); the new subcommands (S6) wire into the same root.

**S11 (docs) is last** — references S1–S10 file locations; finalises the ADR.

### §2.1 Wave-based dispatch plan (Phase 9)

| Wave | Slices in parallel | Blocker for next wave |
|------|--------------------|------------------------|
| 1 | S1, S5 | S2 needs S1 (sequential); S6/S7/S8/S9/S10 need S5 |
| 2 | S2, S6 | S3/S7/S9 need S2 |
| 3 | S3, S7, S9 | S4 needs S3; S8 needs S7 |
| 4 | S4, S8, S10 | S11 needs all |
| 5 | S11 | (terminal) |

S5 starts in Wave 1 alongside S1: it touches different packages (`pkg/protocol`, `internal/tasks`) and only depends on existing public types. Worker S5 may stub the `OpenTaskTracker` migration call until S1 lands `audit.Migrate(db)` — this is a small integration point (see §1.10 below).

### §2.2 Layer Integration Points (per C-integration-points)

| Integration Point | Owning slice | Consuming slices | Shared contract | Merge timing |
|---|---|---|---|---|
| `audit.Migrate(db *sql.DB) error` (the migrator entry point) | S1 (scaffold), S2 (v2→v3), S3 (v2→v3 backfill), S4 (v3→v4) | S5 (`OpenTaskTracker` calls it), S6 (`pasture migrate` calls it) | Function signature: `func Migrate(db *sql.DB) error` returning `*pasterrors.StructuredError` on failure | Must be importable from S5 by end of Wave 2 |
| `protocol.TaskTracker` interface | S5 | S6, S7, S8, S9, S10 | Interface declaration in `pkg/protocol/tasktracker.go` | Must be exported by end of Wave 1 |
| `protocol.AutomatonRole`, `PastureRole`, `ContextKind` enums | S5 | S6 (CLI display), S7 (registration), S8 (activity attribution), S9 (free-floating context kinds) | Enum constants in `pkg/protocol/agent_categories.go`, `context_kind.go` | Must be exported by end of Wave 1 |
| `pasture_well_known_agents` table schema | S2 (creates table), S7 (writes rows) | S8 (reads cached AgentIDs for activity attribution) | DDL in `internal/audit/migrate_v2_v3.go`; row shape `(agent_id PK, name UNIQUE)` per UAT-1 schema inversion | S2 by end of Wave 2; S7 by end of Wave 3 |
| `context_edges` table schema | S2 | S5 (`AttachContext` writes), S6 (`pasture task contexts` reads), S8 (epoch attachment), S9 (free-floating contexts) | DDL `(event_id, context_kind, context_id) PRIMARY KEY (event_id, context_kind, context_id)` BCNF | S2 by end of Wave 2 |
| `pasterrors.CategoryStorage` constant | S1 | All slices that raise migration / storage errors | `Category` constant + exit code 5 mapping | S1 by end of Wave 1 |
| Test-only binary `pasture-migrate-crash` | S3 | S3 (Scenario 11 test) | `cmd/pasture-migrate-crash/main.go` builds with the standard toolchain | S3 by end of Wave 3 |
| `--idle-after-migrate <duration>` flag on `pastured` | S7 | S7 (Scenario 12 concurrent migrator test) | `pastured` flag plumbing in `cmd/pastured/main.go` | S7 by end of Wave 3 |

---

## §3. Slice-by-slice plan

Each slice references the PROPOSAL-2 §8 row, the §10 validation entries it satisfies, and the §11 BDD scenarios it owns. Workers MUST read the PROPOSAL-2 artifact before starting — this plan is a coordination aid, not a substitute for the source-of-truth proposal.

### S1 — Schema migration foundation

- **PROPOSAL-2 reference:** §8 S1, §7.10.1 (migration table v1→v2), §7.10.5 (CategoryStorage), §10.1 + §10.2 entries on actionable error shape.
- **Scope:** Add `audit_schema_meta(version PK, applied_at)` table to `internal/audit/sqlite.go`'s `ensureSchema`. Add the migrator scaffold at `internal/audit/migrate.go` exposing `audit.Migrate(db *sql.DB) error` that reads the current version, runs forward migrations in order, and bumps the version. v1→v2 is the only migration in this slice (a no-op besides creating `audit_schema_meta` itself and seeding `(version=2, applied_at=<now>)` via `INSERT OR IGNORE`). Add `CategoryStorage` to `internal/errors/errors.go` (exit code 5; `ExitCode` switch updated). Wire `NewSqliteAuditTrail` to call `audit.Migrate(db)` after `ensureSchema`. **Newer-schema rejection** is implemented here (Scenario 5) since it lives in the migrator's version-detection logic.
- **Files to create:**
  - `pasture/internal/audit/migrate.go` — `Migrate(db *sql.DB) error`, version constant `MaxKnownSchemaVersion = 2` (will bump in S2/S3/S4), helper `currentSchemaVersion(db) (int, error)`.
  - `pasture/internal/audit/schema_meta.go` — DDL for `audit_schema_meta`, helpers `readVersion(db) (int, error)`, `writeVersion(tx, v int) error`.
  - `pasture/internal/audit/migrate_v1_v2.go` — `migrateV1toV2(tx) error`.
  - `pasture/internal/audit/migrate_test.go` — round-trip test (open empty DB → version 2; reopen → still version 2).
  - `pasture/internal/audit/schema_meta_test.go` — read/write helpers tested under `-race`.
- **Files to modify:**
  - `pasture/internal/audit/sqlite.go` — add `audit.Migrate(db)` invocation after `ensureSchema` in `NewSqliteAuditTrail`; keep WAL + busy_timeout pragmas unchanged.
  - `pasture/internal/errors/errors.go` — add `CategoryStorage Category = "storage error"`; add case in `ExitCode` returning 5.
  - `pasture/internal/errors/errors_test.go` — add ExitCode test for `CategoryStorage` → 5.
- **Tests to write (BDD style):**
  - **Scenario 5 (newer-schema rejection)**: file-backed `t.TempDir()` test inserting `audit_schema_meta(version=99, applied_at=...)` into a fresh DB, then calling `NewSqliteAuditTrail(dbPath)` and asserting the returned error has `Category == CategoryStorage`, `What == "audit database schema version 99 is newer than supported version 2"` (or whatever `MaxKnownSchemaVersion` is at S1 time — bump expected `What` substring as later slices land), `Why == "this binary was built before the schema was bumped"`, `Impact == "no events can be read or written until the binary is upgraded"`, `Fix` containing `"upgrade pasture to a version that supports schema v99"`, AND `pasterrors.ExitCode(err) == 5`.
  - Round-trip: open empty DB → migrate to v2; reopen; assert `currentSchemaVersion == 2`.
  - Idempotent re-run: call `Migrate` twice; row count in `audit_schema_meta` stays equal to 1 entry (or whatever `INSERT OR IGNORE` semantics yield).
- **Exit criteria:**
  - `NewSqliteAuditTrail` reads and writes `audit_schema_meta` cleanly.
  - v1→v2 migration is idempotent (test-verified).
  - `CategoryStorage` exists in `errors.go`; `ExitCode(CategoryStorage) == 5`; error tests cover the new case.
  - Newer-schema rejection (Scenario 5) returns a properly-shaped `*StructuredError` with the exact field values asserted in the test.
  - All quality gates (`make fmt && make lint && make test && make build`) pass.
- **BDD scenarios owned:** **Scenario 5** (newer-schema rejection — partial; `MaxKnownSchemaVersion` will land at 4 after S4, but the rejection mechanism lives in S1).
- **Worker model:** opus.

### S2 — New tables (`context_edges`, `pasture_agent_categories`, `pasture_well_known_agents`)

- **PROPOSAL-2 reference:** §7.2 (table DDL, including UAT-1 column ordering for `pasture_well_known_agents` as `(agent_id PK, name UNIQUE)`), §7.7.1 (table contracts), §7.8 (BCNF rationale for `context_edges`), §8 S2.
- **Scope:** Create the three new tables via the v2→v3 migration in `internal/audit/migrate_v2_v3.go`. Old `audit_events` rows are untouched in this slice (S3 handles the `agent_id` add+backfill+role-drop). Schema is registered via `audit.Migrate`'s framework from S1; `MaxKnownSchemaVersion` bumps to 3 in this slice. Indexes per §7.2: `idx_context_edges_lookup ON context_edges (context_kind, context_id)`, `idx_context_edges_event ON context_edges (event_id)`. Note: the `audit_events.agent_id` column is added in S3 alongside the backfill, NOT here, since the `(create column → backfill → drop role)` triple lives in one transaction per BLOCKER A1.
- **Files to create:**
  - `pasture/internal/audit/migrate_v2_v3.go` — `migrateV2toV3(tx) error` creating the three tables (without yet altering `audit_events`).
  - `pasture/internal/audit/migrate_v2_v3_test.go` — table-existence + index-existence assertions; old rows still readable; new rows insertable via raw SQL (e.g., insert a `context_edges` row referencing `audit_events.id=1` after seeding one event).
- **Files to modify:**
  - `pasture/internal/audit/migrate.go` — register `migrateV2toV3` in the dispatch table; bump `MaxKnownSchemaVersion = 3`.
- **Tests to write (BDD style):**
  - File-backed: open a v1 DB (manually seeded with old-shape rows), call `Migrate`, assert tables exist (`PRAGMA table_info(context_edges)`, etc.), old rows still readable, can insert into new tables via raw SQL.
  - Index existence: `SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='context_edges'` shows both expected indexes.
  - BCNF inspection: `context_edges` has exactly 3 columns; primary key is the composite `(event_id, context_kind, context_id)`; no other columns.
- **Exit criteria:**
  - Tables exist post-migration; correct columns, correct indexes.
  - Old `audit_events` rows still readable (no destructive changes in this slice).
  - New tables insertable via raw SQL in tests.
  - `MaxKnownSchemaVersion = 3`; v1 DB end-state after migrate is at v3.
  - All quality gates pass.
- **BDD scenarios owned:** Schema-only assertions for **Scenarios 6, 7** (their `context_edges` rows depend on this table existing); contributes to **Scenario 4** (post-migration table existence checks).
- **Worker model:** opus.

### S3 — AgentID attribution in `audit_events` (v3 backfill)

- **PROPOSAL-2 reference:** §7.10.2 (full v3 pseudocode + idempotency rationale + C4 compliance), §7.10.3 (concurrent migrator race), §11 Scenario 11 (crash mid-migration), §11 Scenario 12 (concurrent migrator race), §11 Scenario 4 (legacy fixture migration).
- **Scope:** v3 migration: `ALTER TABLE audit_events ADD COLUMN agent_id TEXT` (nullable during transition); SELECT DISTINCT roles; for each role, find-or-create a SoftwareAgent via raw SQL on `agents_software` (matching Provenance's INSERT shape); UPDATE audit_events SET agent_id by role; SQLite table-rebuild to drop the `role` column (CREATE NEW TABLE → INSERT SELECT → DROP OLD → RENAME → recreate indexes). The whole step including the `audit_schema_meta` bump from 2 to 3 lives in **one** `BEGIN IMMEDIATE` transaction. Concurrent-migrator handling per §7.10.3 (BUSY retry up to 30s exponential backoff, then `*StructuredError{CategoryStorage, ...}`). Build the test-only `cmd/pasture-migrate-crash/main.go` binary for Scenario 11. Construct the `pasture/testdata/legacy_audit_v1.db` fixture per the row composition in PROPOSAL-2 §11 Scenario 4 (1024 rows, 7 distinct roles, 12 phases + NULL, 5 payload edge cases incl. UTF-8 + >8KB, 3 epoch_id shapes); see §5 of this IMPL_PLAN for fixture preparation guidance.
- **Files to create:**
  - `pasture/internal/audit/migrate_v2_v3.go` — extend with the v3 backfill + table rebuild (or split out as `migrate_v3_backfill.go` for review clarity).
  - `pasture/internal/audit/migrate_v2_v3_test.go` — extend with idempotency, crash, and concurrent-race assertions.
  - `pasture/cmd/pasture-migrate-crash/main.go` — test-only binary; takes `<dbPath>` arg; performs v2→v3 migration but `os.Exit(137)` after `INSERT INTO audit_schema_meta (version=3, ...)` and **before** `tx.Commit()`. Built with normal `go build` (no build-tag gating per handoff §7).
  - `pasture/testdata/legacy_audit_v1.db` — checked-in SQLite fixture; row composition in §5 below.
  - `pasture/testdata/README.md` — describes the fixture, its origin (hand-curated for Scenario 4 diversity), and how to regenerate (a small Go program at `internal/audit/testdata/build_fixture.go` is acceptable but the .db file is the canonical artifact).
- **Files to modify:**
  - `pasture/Makefile` — add `pasture-migrate-crash` to the build target list (alongside `pastured`, `pasture-msg`, `pasture-release`, `pasture`).
- **Tests to write (BDD style):**
  - **Scenario 4** (auto-migration with checked-in fixture): copy `pasture/testdata/legacy_audit_v1.db` to `t.TempDir() / "legacy.db"`; call `protocol.OpenTaskTracker(<path>)`; assert v=3 (or v=4 after S4), every event has non-NULL `agent_id`, every distinct legacy role produced exactly one `agents_software` row (idempotency proof), `PRAGMA integrity_check = "ok"`, `SELECT COUNT(*) FROM audit_events == 1024`.
  - **Scenario 11** (crash mid-migration): copy fixture to `t.TempDir() / "crash.db"`; spawn `pasture-migrate-crash` via `os/exec.Cmd`; observe non-zero exit; reopen via `protocol.OpenTaskTracker`; assert either `MAX(version)=2` (rolled back, then re-migrated cleanly) or `MAX(version)=3` (WAL flushed before kill); never half-migrated state (`MAX(version)=3` AND any audit_events row with NULL `agent_id` would FAIL); assert no orphan rows in `pasture_well_known_agents`.
  - **Scenario 12** (concurrent-migrator race): `t.TempDir() / "race.db"` from fixture; two `os/exec.Cmd` processes spawning `pastured --db <race.db> --idle-after-migrate=1s --audit-trail=sqlite` simultaneously (note: `--idle-after-migrate` flag lands in S7); shared sentinel-file synchronisation; assert exactly one performs migration (verified via `SELECT COUNT(*) FROM agents_software WHERE name LIKE 'pasture/legacy-role/%'` equals exactly the distinct-role count from the fixture, NOT 2× that count); the other either no-ops or returns the actionable `*StructuredError` from §7.10.3.
  - Idempotency: re-run `Migrate` on a v3 DB; row counts unchanged in `agents`, `agents_software`, `audit_events`.
  - Idempotency after kill-9: spawn `pasture-migrate-crash`, re-run normal `Migrate`, assert no duplicate agents (`SELECT COUNT(*) FROM agents_software WHERE name LIKE 'pasture/legacy-role/%' GROUP BY name HAVING COUNT(*) > 1` returns no rows).
- **Exit criteria:**
  - New rows write `agent_id`; legacy rows have `agent_id` populated post-migration.
  - Idempotent on re-run after kill-9 (no duplicate agents).
  - All `BEGIN IMMEDIATE` semantics validated by tests.
  - Fixture committed; Scenario 4 passes; Scenario 11 passes; Scenario 12 passes.
  - All quality gates pass.
- **BDD scenarios owned:** **Scenarios 4, 11, 12** (full ownership); contributes assertions to Scenarios 14 (no duplicate `agents_software` rows for the same name).
- **Note on S12 dependency:** Scenario 12 invokes `pastured --idle-after-migrate=1s`; the flag is added in S7. S3 may stub the test with `t.Skip("requires --idle-after-migrate from S7")` and unskip after S7 lands, OR coordinate via beads comment for S7 to land the flag first. Recommended: S3 worker writes the test scaffold with the skip, S7 worker removes the skip when the flag is wired.
- **Worker model:** opus.

### S4 — EpochContext migration (v4)

- **PROPOSAL-2 reference:** §7.10.1 v3→v4 row + the `audit_events.epoch_id` column drop, §11 Scenario 4 (post-v4 invariants), §11 Scenario 7 (multi-context attachment uses `context_edges` populated here for legacy rows).
- **Scope:** v3→v4 migration in `internal/audit/migrate_v3_v4.go`: for every row in `audit_events` with non-NULL `epoch_id`, INSERT a `context_edges (event_id, 'EpochContext', epoch_id)` row; then SQLite table-rebuild to drop the `epoch_id` column. Whole step in one `BEGIN IMMEDIATE`. Same crash-safety guarantees as S3. **Note from PROPOSAL-2 §7.12 migration note:** legacy free-string `epoch_id` values are migrated as-is regardless of TaskID parseability — they are historical records and rejecting them would lose data. The §7.12 validation applies only to **new** workflow starts post-migration.
- **Files to create:**
  - `pasture/internal/audit/migrate_v3_v4.go` — `migrateV3toV4(tx) error` doing the EpochContext backfill + epoch_id drop.
  - `pasture/internal/audit/migrate_v3_v4_test.go` — file-backed tests using a v3 fixture (or migrate the v1 fixture all the way to v3 first, then test v3→v4 in isolation by re-opening).
- **Files to modify:**
  - `pasture/internal/audit/migrate.go` — register `migrateV3toV4`; bump `MaxKnownSchemaVersion = 4`.
- **Tests to write (BDD style):**
  - File-backed: copy `legacy_audit_v1.db` to `t.TempDir() / "v4.db"`, call `Migrate`; assert every original event with non-NULL `epoch_id` has a `context_edges (event_id, 'EpochContext', <id>)` row; `audit_events.epoch_id` column is gone (`PRAGMA table_info` doesn't list it); 1024 rows preserved.
  - Free-string epoch_id preservation: rows with legacy free-string IDs are present in `context_edges` exactly as-is (not rejected). Validates the §7.12 migration-note guarantee.
  - Idempotent re-run on v4 DB.
- **Exit criteria:**
  - All historical events queryable via `context_edges JOIN audit_events`.
  - `audit_events.epoch_id` column is gone post-migration.
  - Legacy free-string epoch_ids preserved unchanged.
  - All quality gates pass.
- **BDD scenarios owned:** Completes **Scenario 4** invariants for the v4 final state; supports **Scenario 7** (multi-context attachment) by guaranteeing the `context_edges` table is populated.
- **Worker model:** opus.

### S5 — `protocol.TaskTracker` interface + implementation

- **PROPOSAL-2 reference:** §7.4 (interface declaration + `OpenTaskTracker` constructor + UAT-1 placement), §7.6 (actor model), §7.5 (`ContextKind` enum), §10.3 (race test), §8 S5.
- **Scope:** Declare the `TaskTracker` interface in `pasture/pkg/protocol/tasktracker.go` using Go embedding (`provenance.Tracker + audit.Trail + 6 pasture-only methods`). Declare `AutomatonRole` (6 values), `PastureRole` (5 values), `ContextKind` (8 values incl. `None`), `Context` struct in `pasture/pkg/protocol/agent_categories.go` and `context_kind.go`. Implement the interface in `pasture/internal/tasks/tracker.go` wrapping `provenance.Tracker` + `audit.Trail` opened against the same SQLite file. Implement `OpenTaskTracker(dbPath string) (TaskTracker, error)` that opens both subsystems against the same file, runs `audit.Migrate(db)` from S1, and returns the wrapped tracker. Errors are `*pasterrors.StructuredError` with appropriate categories (Connection / Storage / Validation).
- **Files to create:**
  - `pasture/pkg/protocol/tasktracker.go` — interface declaration with Go embedding; `OpenTaskTracker` signature + doc comment per §7.4.
  - `pasture/pkg/protocol/agent_categories.go` — `AutomatonRole` enum (6 values), `PastureRole` enum (5 values), `IsValid()` methods, `AllAutomatonRoles` / `AllPastureRoles` slices for iteration.
  - `pasture/pkg/protocol/context_kind.go` — `ContextKind` enum (8 values), `Context` struct, `IsValid()`, `AllContextKinds`.
  - `pasture/pkg/protocol/agent_categories_test.go` — enum validation tests.
  - `pasture/pkg/protocol/context_kind_test.go` — enum validation tests.
  - `pasture/internal/tasks/tracker.go` — implementation struct wrapping `provenance.Tracker` + `audit.Trail`; methods `SetAgentCategories`, `AgentCategories`, `AttachContext`, `EventContexts`, `Timeline`, `Close`. Embeds the wrapped interfaces so all 32 upstream methods promote without re-declaration.
  - `pasture/internal/tasks/tracker_test.go` — unit tests with mocked `provenance.Tracker` and mocked `audit.Trail` (system under test = the wrapper; mocks = the dependencies, per CLAUDE.md test conventions).
  - `pasture/internal/tasks/tracker_race_test.go` — file-backed cross-subsystem race test per §10.3 / BLOCKER B3.
  - `pasture/internal/tasks/open_unified.go` — `OpenTaskTracker` impl (or extend `open.go` if cleaner).
- **Files to modify:**
  - `pasture/internal/tasks/open.go` — keep `OpenTracker` (legacy Provenance-only path) for back-compat; add a doc comment that `OpenTaskTracker` is the preferred entry point going forward.
- **Tests to write (BDD style):**
  - **Scenario 1** (single .db file with epoch alignment): full integration test using `OpenTaskTracker`, `CreateTask` (REQUEST), then `RecordEvent` + `AttachContext(ContextEpoch, <task-id-string>)`; assert tasks/activities/audit_events/context_edges all populated in the same SQLite file; no separate audit.db or provenance.db file exists.
  - **Scenario 7** (multi-context attachment): record one event, call `AttachContext` twice (once with `ContextEpoch`, once with `ContextSlice`); assert both queries return the event.
  - **Scenario 10** (researcher's notes excluded — partial): assert `ContextKind` enum has exactly 8 values; `ResearcherNoteContext` is NOT a member; `IsValid("ResearcherNoteContext") == false`.
  - **§10.3 race test (BLOCKER B3)**: `t.TempDir() + "/race.db"`, N=64 goroutines, >1000 iterations, mix of 4 op types, `-race`, assertions per §10.3.
  - Mocked-dependency unit tests for the 6 pasture-only methods.
- **Exit criteria:**
  - All `pasture task <verb>` CLI commands (existing and new) can route through `protocol.TaskTracker` (S6 + S10 actually do the wiring; S5 makes it possible).
  - Tests mock `provenance.Tracker` and `audit.Trail` separately (system under test = the wrapper, NOT mocked).
  - Race test passes under `-race` with no `SQLITE_BUSY` / `SQLITE_LOCKED`.
  - Scenario 1 + 7 + 10 (partial) pass.
  - All quality gates pass.
- **BDD scenarios owned:** **Scenarios 1, 7, 10** (10 = enum-membership assertion only; full Scenario 10 is a code-review check).
- **Worker model:** opus.

### S6 — New CLI subcommands + `pasture migrate`

- **PROPOSAL-2 reference:** §7.9 (CLI surface), §11 Scenario 15 (explicit `pasture migrate`), §8 S6.
- **Scope:** Add 4 new subcommands under `pasture task`: `events`, `timeline`, `contexts`, `agents` (with sub-verbs `list` and `show`). Add 1 new top-level command: `pasture migrate [--dry-run]` (NOT under `pasture task` — it is db-level). Each routes through `protocol.TaskTracker`. The `pasture migrate` command and `OpenTaskTracker`'s auto-on-open path share **one** `audit.Migrate` implementation (no duplicate code). Use the existing handler-pattern (`cmd/<verb>.go` Cobra `RunE` thin wrapper → `internal/handlers/<verb>.go` standalone function) per `pasture/CLAUDE.md`. Subprocess CLI tests (the existing `cmd/pasture/main_test.go` style) cover happy + error paths.
- **Files to create:**
  - `pasture/cmd/pasture/task_events.go`, `pasture/internal/handlers/task_events.go`
  - `pasture/cmd/pasture/task_timeline.go`, `pasture/internal/handlers/task_timeline.go`
  - `pasture/cmd/pasture/task_contexts.go`, `pasture/internal/handlers/task_contexts.go`
  - `pasture/cmd/pasture/task_agents.go`, `pasture/internal/handlers/task_agents.go`
  - `pasture/cmd/pasture/migrate.go`, `pasture/internal/handlers/migrate.go`
  - `pasture/cmd/pasture/task_events_test.go` and equivalents — subprocess CLI tests.
  - `pasture/internal/formatters/events.go` — text + JSON formatters for the new event/context shapes.
- **Files to modify:**
  - `pasture/cmd/pasture/task.go` — register the four new `task <verb>` subcommands.
  - `pasture/cmd/pasture/root.go` — register the top-level `migrate` command.
- **Tests to write (BDD style):**
  - **Scenario 15** (explicit `pasture migrate` command): subprocess test running `pasture migrate --db <fixture-copy> --dry-run`, assert SHA-256 of file unchanged + planned migrations printed to stdout + exit code 0. Then run `pasture migrate --db <fixture-copy>`, assert v4 + invariants per Scenario 4. Then re-run, assert idempotent no-op + `migrated <db-path> from v4 to v4` printed.
  - Convergence test: file A migrated via `OpenTaskTracker` (auto-on-open), file B migrated via `pasture migrate`; both starting from copies of the fixture; final content compared modulo SQLite's WAL ordering (use `sqlite3 .dump` and compare).
  - `pasture task events --epoch-id <id>` returns events for that epoch (uses `context_edges` JOIN).
  - `pasture task events --context-kind=GitContext --context-id=<sha>` returns the right events.
  - `pasture task timeline <task-id>` returns events ordered by timestamp.
  - `pasture task contexts <event-id>` returns all contexts for an event.
  - `pasture task agents list` returns all registered agents with their categories.
  - `pasture task agents show <id>` returns one agent with its categories.
  - Error paths: missing `--epoch-id` returns CategoryValidation exit code 1; nonexistent DB returns CategoryConnection exit code 2.
- **Exit criteria:**
  - Subprocess tests pass; happy + error paths covered.
  - `pasture migrate --dry-run` does not modify the file (SHA-256 unchanged).
  - `pasture migrate` is idempotent on already-migrated DB.
  - Auto-on-open and explicit-command paths converge to identical state.
  - All quality gates pass.
- **BDD scenarios owned:** **Scenarios 6** (free-floating git event recording — assertion is via `pasture task events --context-kind=GitContext`; the free-floating writer side lives in S9), **Scenario 15** (full).
- **Worker model:** opus.

### S7 — Automaton agent registration at `pastured` startup

- **PROPOSAL-2 reference:** §7.7.2 (well-known names, 15 entries), §7.7.3 (idempotent startup pseudocode), §11 Scenario 14 (two-restart idempotency), §11 Scenarios 8a–8e (automaton attribution).
- **Scope:** At `pastured` startup, for each well-known name in §7.7.2, run the `ensureWellKnownAgent` flow: lookup-by-name in `pasture_well_known_agents`; if absent, call `provenance.Tracker.RegisterSoftwareAgent("pasture", <name>, <version>, <source>)`; insert into `pasture_well_known_agents` and `pasture_agent_categories` (with the corresponding `automaton_role` and `pasture_role=None`). All in one transaction on the audit `*sql.DB`. Cache resulting AgentIDs in memory (a `map[string]provenance.AgentID` keyed by well-known name) for use by S8's activities. Drop `AutomatonRoleDerivation` (per UAT-1 C3); register `consensus-reached` (`AutomatonRoleConsensusReached`) and `create-followup` (`AutomatonRoleCreateFollowup`) as concrete first-class instances. The 9 hook names are drawn from PROPOSAL-2 §7.7.2's enumeration (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Notification`, `Stop`, `SubagentStop`, `PreCompact`, `SessionEnd`) — these are **Claude Code hook events** per Pasture URD D7, NOT pasture's internal `hooks.HookEvent` set (`HookPhaseTransition` etc.; those are different concept). Worker S7 may cross-check Pasture URD D7 (`aura-plugins-jbnx3`) for the canonical Claude Code hook names list.
- **Files to create:**
  - `pasture/internal/tasks/well_known.go` — `ensureWellKnownAgent(tx, tracker, name, role, version, source) (provenance.AgentID, error)` per §7.7.3 pseudocode.
  - `pasture/internal/tasks/well_known_registry.go` — the canonical 15-entry list as a slice of `(name, AutomatonRole)` pairs.
  - `pasture/internal/tasks/well_known_test.go` — unit tests with file-backed `t.TempDir()` SQLite + a real Provenance tracker (no mocking — the system under test is the registration flow, dependencies are real Provenance + audit instances).
  - `pasture/internal/tasks/well_known_cache.go` — in-memory `WellKnownAgentCache` struct holding `map[string]provenance.AgentID`; loaded at daemon startup; consulted by S8.
- **Files to modify:**
  - `pasture/cmd/pastured/main.go` — after `initAuditTrail`, call `tasks.RegisterWellKnownAgents(tracker, cache)` to mint or load all 15 well-known agents; pass the `cache` into `Activities` (new field `Activities.WellKnownAgents *WellKnownAgentCache`).
  - `pasture/cmd/pastured/main.go` — add `--idle-after-migrate <duration>` flag for Scenario 12 (default `0` = disabled). When set, after migration completes, the daemon idles for the duration before starting the worker. This unblocks S3's Scenario 12 test.
  - `pasture/internal/temporal/activities.go` — add `WellKnownAgents *tasks.WellKnownAgentCache` field to `Activities` struct. (Activities use this cache in S8.)
- **Tests to write (BDD style):**
  - **Scenario 14** (two-restart idempotency): start `pastured` against a fresh v4 DB via the `cmd/pastured/main_test.go` machinery (or direct in-process call); shut down; restart; assert row counts in `agents`, `agents_software`, `pasture_well_known_agents`, `pasture_agent_categories` are equal between starts; assert AgentIDs in `pasture_well_known_agents` are pointwise identical across the two startups.
  - **Scenario 8a–8e** (parameterised over 5 concrete `AutomatonRole` values): each sub-scenario fires the corresponding agent (via direct call in S7 unit tests, or via the actual workflow path in S8 integration tests), asserts the recorded event's `agent_id` resolves through the JOIN to the correct `automaton_role` and the correct `pasture_well_known_agents.name`. S7 owns the **registration-side** assertions (all 15 names exist with correct roles); S8 owns the **emission-side** assertions (events fire with the right agent_id during workflow runs).
- **Exit criteria:**
  - All 15 well-known agents visible via `pasture task agents list` after first `pastured` startup.
  - Two-restart row counts identical (Scenario 14).
  - `--idle-after-migrate` flag wired and working.
  - In-memory `WellKnownAgentCache` populated correctly; lookups by well-known name return the right `AgentID`.
  - All quality gates pass.
- **BDD scenarios owned:** **Scenario 14** (full), **Scenarios 8a–8e** (registration-side assertions; emission-side in S8).
- **Worker model:** opus.

### S8 — Workflow integration + §7.12 epoch-ID validation

- **PROPOSAL-2 reference:** §7.11 (workflow integration), §7.12 (epoch-ID validation policy), §11 Scenario 2 (R13 SA dual-write), §11 Scenarios 8a–8e (emission-side), §11 Scenario 13 (malformed epoch-ID rejection).
- **Scope:** `Activities.RecordTransition` and `Activities.RecordAuditEvent` change internally: instead of calling `audit.Trail.RecordEvent(...)` directly, they call `protocol.TaskTracker.RecordEvent(...) → returns event_id`, then `protocol.TaskTracker.AttachContext(ctx, event_id, ContextEpoch, epochID)` to record the epoch correlation. The `workflow.UpsertSearchAttributes(...)` call in `internal/temporal/workflow.go` is **byte-identical** to today's (R13 preserved). The Activities also pick up the right `agent_id` from the `WellKnownAgentCache` (S7) based on which automaton fires (e.g., `CheckConstraints` uses the `pasture/automaton/check-constraints` AgentID; `RecordTransition` uses an appropriate agent for the transition gate that fired). For `consensus-reached` and `create-followup` (UAT-1 first-class agents), wire emission points where consensus checks succeed and where follow-up epics get created (these may be only stubbed if no caller exists yet — but the agents are registered and emission tests verify the path). Add §7.12 epoch-ID validation: in `cmd/pasture-msg/epoch.go` (the CLI entry point) and in `internal/temporal/activities.go`'s `RecordTransition`, call `provenance.ParseTaskID(epochID)` before any signal/workflow start; reject malformed with `*StructuredError{CategoryValidation, ...}` per the §7.12 example.
- **Files to create:**
  - `pasture/internal/temporal/activities_test.go` — extend with integration test running `EpochWorkflow` start → advance → end, asserting (a) `activities` table has phase brackets, (b) `audit_events` has events, (c) `context_edges` has epoch attachments, (d) Temporal SAs are upserted byte-identically to a captured baseline, (e) malformed epoch-id rejected per Scenario 13.
- **Files to modify:**
  - `pasture/internal/temporal/activities.go` — modify `RecordTransition`, `RecordAuditEvent` to use `protocol.TaskTracker.RecordEvent` + `AttachContext`; pick agent_id from `WellKnownAgentCache`. Add §7.12 validation to `RecordTransition`.
  - `pasture/cmd/pastured/main.go` — wire `protocol.TaskTracker` instead of bare `audit.Trail` into `Activities`. (The `Activities.Trail audit.Trail` field may be replaced with `Activities.Tracker protocol.TaskTracker`, OR keep both fields with `Tracker` taking precedence for new code paths.)
  - `pasture/cmd/pasture-msg/epoch.go` — add `provenance.ParseTaskID(epochID)` validation in `epochStartCmd.RunE`; reject with `CategoryValidation` per §7.12 example.
  - `pasture/internal/handlers/epoch_start.go` (if it exists) or equivalent — same validation enforcement at handler boundary.
- **Tests to write (BDD style):**
  - **Scenario 2** (R13 SA dual-write preserved): run an EpochWorkflow phase transition via the existing `temporal_test.go` machinery; capture the SA values (`SA_EPOCH_ID`, `SA_PHASE`, `SA_ROLE`, `SA_STATUS`, `SA_DOMAIN`, `SA_LAST_EVENT_TYPE`); compare against a recorded baseline (a checked-in JSON snapshot of pre-implementation SA values) — must be byte-identical.
  - **Scenarios 8a–8e** (emission-side): for each AutomatonRole, run the workflow path that fires it; assert the resulting event row in `audit_events` has `agent_id` matching the cached well-known agent for that role, AND `pasture_agent_categories.automaton_role` matches.
  - **Scenario 13** (malformed epoch-id rejection): subprocess test `pasture-msg epoch start --epoch-id "not-a-task-id"`; assert exit code 1 (CategoryValidation), stderr contains a `*StructuredError` with `What` containing `"not a valid Provenance TaskID"`, `Fix` containing `"pasture task create REQUEST"`. Also test the activity-side: invoke `Activities.RecordTransition` with a malformed `epochID`; assert same StructuredError shape; no rows in `audit_events`, `context_edges`, or `tasks` for the malformed ID.
  - Full integration: workflow start → advance → end; assert all 4 layers (activities, audit_events, context_edges, SAs) populated correctly.
- **Exit criteria:**
  - SA dual-write preserved byte-identically (snapshot diff passes).
  - All 5 automaton roles emit events with correct agent attribution.
  - Malformed epoch-IDs rejected at both CLI and activity entry; no rows leak.
  - Integration test passes end-to-end.
  - All quality gates pass.
- **BDD scenarios owned:** **Scenarios 2, 13** (full), **Scenarios 8a–8e** (emission-side).
- **Worker model:** opus.

### S9 — Free-floating event recording

- **PROPOSAL-2 reference:** §7.5 (`ContextKind` enum incl. `GitContext`, `SkillContext`, `SessionContext`), §11 Scenario 6 (free-floating git event), §8 S9.
- **Scope:** Hook handlers and skill-invocation entry points record events with non-epoch contexts via `protocol.TaskTracker.AttachContext`. Specifically: a git commit hook (e.g., a Claude Code `Stop` hook fired after `git agent-commit`) calls `tracker.RecordEvent(AuditEvent{event_type: "GitCommit", payload: {sha: "abc123"}})`, gets back `event_id`, then `tracker.AttachContext(ctx, event_id, ContextGit, "abc123")`. Skill invocations outside epochs do likewise with `ContextSkill`. The wiring for the actual hook handlers is whatever exists in `internal/hooks/` already; S9 adds the recording path. If the actual hook-fires-at-commit machinery doesn't exist yet, S9 provides the recording functions and a stub hook handler that demonstrates the wiring + a unit test of the wire.
- **Files to create:**
  - `pasture/internal/tasks/free_floating.go` — helper `RecordGitEvent(tracker, sha, ...)`, `RecordSkillEvent(tracker, skillRunID, ...)`, etc. Each takes a `protocol.TaskTracker` and writes the event + context_edge row.
  - `pasture/internal/tasks/free_floating_test.go` — unit tests with a real `OpenTaskTracker` instance against `t.TempDir()`.
  - `pasture/internal/hooks/git_recorder.go` — a hook handler that calls `RecordGitEvent` when fired (registered conditionally by `pastured` if a free-floating event recorder is configured).
- **Files to modify:**
  - `pasture/cmd/pastured/main.go` — register the `git_recorder` hook handler in the hooks Manager.
- **Tests to write (BDD style):**
  - **Scenario 6** (free-floating git event recording): with no active EpochWorkflow, fire a git commit hook (or directly call `RecordGitEvent`); assert `pasture task events --context-kind=GitContext --context-id=abc123` returns the recorded event; assert no `context_edges` row of `kind=EpochContext` exists for this event.
  - Free-floating event without epoch: ensure no error is raised by absent epoch context.
- **Exit criteria:**
  - A git commit triggered by `pasture-msg` hooks (or simulated) records into `audit_events` with `context_kind=GitContext`.
  - Free-floating event recording works without an active epoch.
  - `pasture task events --context-kind=GitContext` returns the right events.
  - All quality gates pass.
- **BDD scenarios owned:** **Scenario 6** (full).
- **Worker model:** opus.

### S10 — `pasture-msg` + `cmd/pasture` wiring

- **PROPOSAL-2 reference:** §7.11 (workflow integration carrier), §11 Scenario 9 (hjsdt CLI continues to work), §8 S10.
- **Scope:** Update `cmd/pasture` (the hjsdt-built binary) to use `protocol.TaskTracker` (via `OpenTaskTracker`) instead of importing `provenance` directly. Update `cmd/pastured` to open the unified DB via `OpenTaskTracker` and construct the wrapper that flows into `Activities`. `pasture-msg` is **unchanged** for now (per j9c88 deferral of binary umbrella unification — see PROPOSAL-2 §12). The migration uses `OpenTaskTracker` so the auto-on-open migrator runs on first invocation. Existing hjsdt CLI tests must continue to pass byte-identically (Scenario 9). The DB path may need to be unified: today `cmd/pasture` defaults to `~/.local/share/pasture/provenance.db` and `cmd/pastured` defaults to `~/.local/share/pasture/audit.db`. Per PROPOSAL-2 §7.1, the unified path is `~/.local/share/pasture/pasture.db`. Workers must update both default paths AND keep backward-compatible aliases (`--audit-db-path` becomes an alias for `--db` with a deprecation warning).
- **Files to modify:**
  - `pasture/cmd/pasture/root.go` — change default for `--db` to `~/.local/share/pasture/pasture.db`; update env var if needed (PASTURE_DB_PATH already documented).
  - `pasture/cmd/pasture/task_crud.go` (and other `task_*.go`) — re-route through `protocol.TaskTracker.OpenTaskTracker` instead of `tasks.OpenTracker`.
  - `pasture/internal/handlers/task_*.go` — update `OpenTracker` callers to `OpenTaskTracker`; access via the embedded `provenance.Tracker` interface (Go embedding makes all 28 Provenance methods available on `protocol.TaskTracker`).
  - `pasture/cmd/pastured/main.go` — change default `--audit-db-path` to point at `~/.local/share/pasture/pasture.db`; keep the existing flag name as an alias; emit deprecation warning if both `--db` and `--audit-db-path` are set with different values (per PROPOSAL-2 §7.1).
  - `pasture/internal/tasks/paths.go` — update `DefaultDBPath` to return the unified path.
  - `pasture/internal/tasks/paths_test.go` — update tests.
- **Tests to write (BDD style):**
  - **Scenario 9** (hjsdt CLI continues to work): re-run all existing `cmd/pasture/main_test.go` subprocess tests (`pasture task create / show / update / close / list / ready / blocked / dep add / dep tree / label add / comment add`); assert all behave identically (same output formats, exit codes, error messages). NO changes to the existing test bodies; only the harness setup may change to use the unified DB path.
  - Verify via `sqlite3 ~/.local/share/pasture/pasture.db ".tables"` (in test scaffolding) that `pasture` CLI now writes to the unified file.
- **Exit criteria:**
  - All existing hjsdt CLI tests still pass byte-identically.
  - `pasture` CLI writes to `pasture.db` (unified) instead of separate files.
  - Backward-compat aliases work; deprecation warnings emitted as documented.
  - All quality gates pass.
- **BDD scenarios owned:** **Scenario 9** (full).
- **Worker model:** opus.

### S11 — Documentation + ADR finalisation

- **PROPOSAL-2 reference:** §8 S11.
- **Scope:** Update `pasture/CLAUDE.md` (currently a symlink to `pasture/AGENTS.md`) and `pasture/AGENTS.md` to reference `protocol.TaskTracker` as the canonical entry point for task + audit operations. Document the unified `pasture.db` file location. Document the new `pasture migrate` command. Finalise the ADR at `docs/adr/0001-pasture-toolkit-integration-architecture.md` (mark `Status: Accepted`, add the implementation epoch reference, commit). Update URD `aura-plugins-dr2ps` with implementation links via `bd update --notes`. Optionally: update `pasture/README.md` if user-facing.
- **Files to modify:**
  - `pasture/AGENTS.md` (and the `CLAUDE.md` symlink) — add `protocol.TaskTracker` reference, unified DB path, `pasture migrate` command.
  - `aura-plugins/docs/adr/0001-pasture-toolkit-integration-architecture.md` — mark `Status: Accepted`; commit.
- **Tests to write:** None — docs only. Reviewer verifies prose accuracy.
- **Exit criteria:**
  - Docs reviewed (Phase 10 review covers them).
  - ADR committed with `Status: Accepted`.
  - URD `aura-plugins-dr2ps` updated with implementation links.
- **BDD scenarios owned:** None directly; supports **Scenario 10** (researcher's notes excluded — code-review enforcement aided by docs).
- **Worker model:** haiku (docs only, no logic).

---

## §4. BDD scenario assignment table (15 scenarios)

| # | Scenario name (PROPOSAL-2 §11) | Owning slice(s) | Notes |
|---|---|---|---|
| 1 | Single .db file with epoch alignment | **S5** (writer side) + **S8** (emits epoch-tied events from workflow) | Integration test; OpenTaskTracker + RecordEvent + AttachContext path |
| 2 | R13 SA dual-write preserved | **S8** | Snapshot-diff against pre-implementation SA values; workflow boundary unchanged |
| 3 | Provenance library is unmodified | **All slices** (global invariant) | Verified by `git log` inspection in code review; no per-slice test |
| 4 | Auto-migration on open with checked-in fixture | **S3** (v3 backfill) + **S4** (v4 EpochContext); fixture committed in **S3** | 1024-row fixture per §5 below |
| 5 | Newer-schema rejection (StructuredError shape) | **S1** | Tests the `*StructuredError` field-by-field per §7.10.4 |
| 6 | Free-floating git event recording | **S9** (writer) + **S6** (`pasture task events --context-kind=GitContext` reader) | |
| 7 | Multi-context attachment | **S5** | One event, two `AttachContext` calls, both queries return it |
| 8a | Automaton attribution — ConstraintChecker | **S7** (registration) + **S8** (emission via `CheckConstraints` activity) | |
| 8b | Automaton attribution — TransitionGate (×3) | **S7** + **S8** | 3 sub-cases per gate kind |
| 8c | Automaton attribution — HookHandler (×9) | **S7** + **S8** | 9 sub-cases per Claude Code hook event in §7.7.2 |
| 8d | Automaton attribution — ConsensusReached | **S7** + **S8** | UAT-1 first-class |
| 8e | Automaton attribution — CreateFollowup | **S7** + **S8** | UAT-1 first-class |
| 9 | hjsdt CLI continues to work | **S10** | Existing `cmd/pasture/main_test.go` tests must pass byte-identically |
| 10 | Researcher's notes excluded | **S5** (enum-membership assertion) + **all slices** (code-review check that no `ResearcherNoteContext` value is added) | |
| 11 | Crash mid-migration recovery | **S3** | Test-only `cmd/pasture-migrate-crash` binary |
| 12 | Concurrent-migrator race | **S3** (test) + **S7** (`--idle-after-migrate` flag dependency) | Two `os/exec.Cmd` processes |
| 13 | Malformed epoch-ID rejection | **S8** (validation in CLI + activity) | §7.12 enforcement |
| 14 | Two-restart idempotency for well-known agents | **S7** | Row-count equality across two startups |
| 15 | Explicit `pasture migrate` command (dry-run + apply + idempotent) | **S6** | Convergence with auto-on-open path verified |

**Coverage check:** every PROPOSAL-2 §11 scenario has at least one owning slice; cross-slice scenarios (1, 4, 6, 8a–8e, 12) explicitly note the joint ownership so workers don't drop integration assertions.

---

## §5. Fixture preparation plan (`pasture/testdata/legacy_audit_v1.db`)

This fixture is **owned by S3** and consumed by S3 (Scenario 4 + 11), S4 (Scenario 4 v4 invariants), and S6 (Scenario 15).

### §5.1 Composition (verbatim from PROPOSAL-2 §11 Scenario 4)

- **Total rows in `audit_events`:** 1024.
- **Schema:** legacy v1 (`epoch_id, phase, role, event_type, payload, timestamp`; **no `audit_schema_meta` table**).
- **Role distribution (sums to 1024):** `architect` (256), `supervisor` (192), `worker` (192), `reviewer` (192), `automaton-checker` (96), `human-david` (64), `unknown-legacy` (32). 7 distinct roles.
- **Phase distribution:** covers all 12 PhaseId values; ~100 rows of NULL `phase` (free-floating events under v1's NULL-permissive shape — these will need a slight test-side adjustment because v1 schema has `phase TEXT NOT NULL`; either set `phase = ''` for these "free-floating" rows OR accept that the fixture only covers the 12 named phases and skip the NULL bucket).
- **Payload JSON edge cases:**
  - 64 rows with empty object `{}`.
  - 32 rows with deeply-nested objects (depth 4: `{"a": {"b": {"c": {"d": "value"}}}}`).
  - 16 rows with embedded UTF-8 (e.g., `{"note": "café"}`).
  - 16 rows with payloads >8 KB (large stringified data, exercises the JSON column's TEXT capacity).
  - 4 rows with arrays at the top level (`[1,2,3]` — exercises the JSON unmarshal path's tolerance for non-object roots; `audit_events.payload` is stored as TEXT so this round-trips, but the JSON unmarshaler currently expects `map[string]any` per `pkg/protocol/types.go:294`; the fixture validates that the migration preserves the data even if a future query path can't deserialise it).
- **`epoch_id` shapes:**
  - 768 rows with valid Provenance TaskIDs (`<namespace>--<uuid>`, e.g. `aura-plugins--01968a3c-1234-5678-9abc-def012345678`).
  - 192 rows with legacy free strings (e.g., `epoch-2026-04-22-mvp`).
  - 64 rows with `epoch_id` matching another row's (exercises the EpochContext de-duplication pass during S4's migration; v3→v4 should produce 1024 - 64 = 960 distinct `(event_id, EpochContext, epoch_id)` rows? — actually 1024 because each event gets its own row, even if `epoch_id` is shared; the dedup remark is about the `context_edges` PK which is `(event_id, context_kind, context_id)` so duplicates on `epoch_id` alone are fine).

### §5.2 Construction approach

S3 worker creates a Go program at `pasture/internal/audit/testdata/build_fixture.go` (build-tag-gated, e.g. `//go:build fixture`) that:

1. Opens a fresh SQLite file at `pasture/testdata/legacy_audit_v1.db`.
2. Runs the v1 `ensureSchema` (the pre-this-proposal version — it can be inlined or extracted to a helper).
3. Inserts 1024 rows per the composition above using `database/sql` directly.
4. Commits and closes.

The `.db` file is then **committed to the repo** as the canonical fixture (binary file; ~100KB or so). The build program is committed alongside for reproducibility but is not in the default test path (build-tag-gated).

S3 worker must verify the fixture's row composition with assertions in the build program itself: `SELECT COUNT(*) FROM audit_events == 1024`, `SELECT COUNT(DISTINCT role) == 7`, etc. before committing.

### §5.3 Fixture maintenance policy

- The fixture is **immutable** once committed. Future schema changes that require a different legacy state get their own fixture (e.g., `legacy_audit_v2.db` if a v2-shaped fixture is ever needed).
- Tests **copy** the fixture to `t.TempDir()` before mutating; never operate on the checked-in file.
- If the fixture's binary content needs to change (e.g., a row composition error is discovered), the build program is re-run and the new `.db` checked in with a commit message documenting the change.

---

## §6. Worker dispatch instructions (Phase 9 prep)

When dispatching workers in Phase 9, the supervisor MUST include in each prompt:

1. `Skill(/aura:worker)` — first action.
2. HANDOFF task ID: `aura-plugins-79ysg` (worker reads via `bd show aura-plugins-79ysg --allow-stale`).
3. PROPOSAL-2 artifact path: `/home/minttea/codebases/dayvidpham/aura-plugins/worktree/aura-protocol/docs/proposals/PROPOSAL-2-pasture-workflow-record.md`.
4. The SLICE task ID the worker owns (e.g., `aura-plugins-XXXXX` for SLICE-N).
5. The IMPL_PLAN task ID (this task).
6. The §11 BDD scenarios the worker implements (per §4 above).
7. Coding conventions reminder: opus model, `git agent-commit`, `make fmt && make lint && make test && make build` pre-commit, errors as `*pasterrors.StructuredError`, no `mattn/go-sqlite3`.
8. Cross-slice integration points the worker depends on (per §2.2 above).

Per memory feedback `feedback_opus_model.md`: **all workers run on the OPUS model**, not sonnet (even for trivial slices like S11 — though S11 was marked haiku in §3, the opus default per memory feedback overrides; supervisor should confirm with team-lead if conflicts).

Per memory feedback `feedback_parallelize_fixes.md`: in Phase 10 fix cycles, **group fix workers by file ownership** so multiple BLOCKER/IMPORTANT findings against different files can be fixed in parallel.

Per memory feedback `feedback_review_all_three.md`: **every Phase 10 review round re-launches all 3 reviewers fresh**, even if some accepted in a prior round.

Per memory feedback `feedback_no_aura_swarm.md`: **use Agent (subagent) tool with `team_name: "pasture-workflow-record"`**, NOT `aura-swarm`. Workers added to the team via TeamCreate; reviewers spawned as ephemeral subagents.

---

## §7. Phase 10 review plan (3 reviewers per round; per-slice severity tree; max 3 cycles per slice)

After all 11 slices land:

1. For **each slice**, eagerly create 3 severity-group tasks: `<slice-id>-BLOCKER`, `<slice-id>-IMPORTANT`, `<slice-id>-MINOR` — even if empty. Empty groups close immediately.
2. **Per round, spawn 3 reviewer subagents TOTAL** — one per axis (A=Correctness, B=Test quality, C=Elegance). Each reviewer reviews **all slices that need reviewing in that round**, NOT a separate trio per slice. So a Phase 10 wave covering all 11 slices = 3 ephemeral subagent spawns (not 33). Spawn pattern: `Agent({subagent_type: "general-purpose", model: "opus", run_in_background: true, prompt: "Skill(/aura:reviewer) — code review along axis A across slices [SLICE-N, SLICE-M, ...]..."})`. Reviewers are **NOT teammates** — they are short-lived subagents per project convention (CLAUDE.md "Subagents / TeamCreate" section).
3. Per round: each of the 3 reviewers files findings as leaf tasks under the appropriate per-slice severity group (`bd create --deps blocked-by:<severity-group-id>`); per-slice severity grouping preserves per-slice routing of fixes and per-slice cycle counters.
4. Workers (still on the team from Phase 9) apply fixes, grouped by file ownership for parallelism (per memory feedback `feedback_parallelize_fixes.md`).
5. **Re-spawn ALL 3 reviewers fresh** for each round even if one accepted in a prior round (per memory feedback `feedback_review_all_three.md`).
6. **Per-slice fix-cycle counter:** max 3 cycles per slice. A slice clean-exits when 0 BLOCKERs + 0 IMPORTANTs from ALL 3 reviewers in a round. After cycle 3, escalate to architect for re-planning if BLOCKERs or IMPORTANTs remain on that slice (per `aura:supervisor` skill).
7. After all slices clear Phase 10: if ANY IMPORTANT or MINOR findings exist (NOT gated on BLOCKER resolution), **create a follow-up epic** (label `aura:epic-followup`) per `C-followup-timing` constraint.

---

## §8. Phase 11 STOP condition

Once Phase 10 reaches consensus across all slices:
- Supervisor posts a comment to this IMPL_PLAN task summarising the work (slices landed, scenarios passing, follow-up epic ID if any).
- Supervisor SendMessages the team-lead that Phase 11 UAT is ready.
- Supervisor STOPS. Does NOT execute Phase 11. Does NOT push code. Does NOT execute Phase 12 landing.

User owns Phase 11 (UAT) and Phase 12 (landing).

---

## §9. Open items / risks

1. **Hook event count drift.** PROPOSAL-2 §7.7.2 lists 9 Claude Code hook names; pasture's existing `internal/hooks/hooks.go` has 12 internal hook events (different concept). Worker S7 must consult Pasture URD `aura-plugins-jbnx3` D7 for the canonical Claude Code hook list. If D7 lists more than 9, the §7.7.2 enumeration extends accordingly (the table allows for 9-12 per scenario 8c).
2. **Race test stability.** §10.3's `N=64 goroutines × >1000 iterations` race test may be CI-flaky if the `modernc.org/sqlite` busy_timeout interacts poorly with the goroutine scheduler. S5 worker should size N down if necessary (e.g., N=16) while keeping iteration count high; document the chosen size in the test comment.
3. **Fixture binary file size.** A 1024-row SQLite database with diverse payloads may exceed 100KB. Acceptable per project convention (no checked binary size limit), but document in `testdata/README.md`.
4. **`audit_events.phase NOT NULL` in v1 schema vs §11 Scenario 4 "~100 rows of NULL phase".** The v1 schema (per `pasture/internal/audit/sqlite.go`) has `phase TEXT NOT NULL`. The fixture cannot have NULL phases unless we relax this constraint. **Resolution:** the fixture uses `phase = ''` (empty string) for the "free-floating" 100 rows; the v3→v4 migration treats empty phase as effectively unscoped. S3 worker should confirm and document.
5. **`audit_events.role NOT NULL` in v1 schema.** Same constraint exists. The fixture uses non-empty role strings for all rows (the 7-role distribution above is non-NULL).

---

This plan is the operational coordination document for Phase 8. It is dependency-aware, BDD-mapped, integration-point-aware, and aligned with all binding constraints (C1–C5, UAT-1 placement / schema / enum / migrate edits, BLOCKERs A1–A4 + B1–B5, R1–R14, D1–D12, R13 SA dual-write preserved). Workers MUST read PROPOSAL-2 in full before implementing; this plan is a navigation aid.

End of IMPL_PLAN.
