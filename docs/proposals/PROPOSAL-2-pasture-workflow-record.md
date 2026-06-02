# PROPOSAL-2: Unified Pasture workflow record + observability

| Field | Value |
|---|---|
| **Status** | Draft (Phase 3 — Round 2 review pending) |
| **Date** | 2026-04-25 |
| **Beads task** | `aura-plugins-kf87g` |
| **REQUEST** | `aura-plugins-j9c88` |
| **ELICIT** | `aura-plugins-pcnhq` |
| **URD** | `aura-plugins-dr2ps` |
| **Supersedes** | `aura-plugins-9z5wg` (PROPOSAL-1, Round 1 REVISE on Axes A and B) |
| **Round 1 reviews** | Correctness (A): `aura-plugins-nzlob`, Test quality (B): `aura-plugins-3rdg4`, Elegance (C): `aura-plugins-zxlby` |
| **Origin** | `aura-plugins-hjsdt` UAT (`aura-plugins-dhf6q`) surfaced the unification need; ADR draft at `docs/adr/0001-pasture-toolkit-integration-architecture.md`; URE rounds 1–3 settled the design space; Round 1 review BLOCKERs against PROPOSAL-1 forced this revision. |
| **Related context** | Pasture URD `aura-plugins-jbnx3` (PROPOSAL-2 ratified `aura-plugins-wab79`), Providence URD `aura-plugins-f85gw` (proposal `aura-plugins-ygkp0`), Bestiary integration in Provenance commits `8cec1fb`, `11022a1`. |

---

## 0. Revision history vs PROPOSAL-1

PROPOSAL-2 inherits everything correct from PROPOSAL-1 (`aura-plugins-9z5wg`) and edits in-place where Round 1 BLOCKERs apply. Each revision is traceable to a reviewer comment.

| ID | Source | Resolution | Section(s) changed |
|---|---|---|---|
| **A1** | Axis A BLOCKER (`aura-plugins-nzlob`) — v3 backfill non-idempotent through Provenance public API | Audit migrator reads `agents_software` directly via raw SQL on its own `*sql.DB`, find-or-create on `(namespace, name)`. Whole v3 step (row updates + schema_meta bump) lives in one `BEGIN IMMEDIATE` / `COMMIT` on the audit `*sql.DB`. C4-compliance argued explicitly. | §7.10 (rewritten), §7.10.1 (new) |
| **A2** | Axis A BLOCKER — startup automaton registration not idempotent (every restart spawns duplicates via `RegisterSoftwareAgent`) | New `pasture_well_known_agents` table added to §7.2 with column ordering **`agent_id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE`** (UAT-1 direction: `agent_id` PK keeps the canonical-identity column consistent across `pasture_agent_categories` and `agents_software`; `name` UNIQUE preserves O(1) lookup-by-name). §7.7 startup sequence: lookup-then-register-then-insert in one transaction. Well-known names enumerated. S7 exit criteria asserts idempotency over two consecutive starts. | §7.2 (table added with UAT-1 column order), §7.7 (rewritten with well-known name list), §8 S7 (exit criteria), §11 Scenario 8/Scenario 14 |
| **A3** | Axis A BLOCKER — error shape inconsistency (§7.10 used `fmt.Errorf`, §11 Scenario 5 used `*StructuredError`) | §7.10 producer example rewritten to use `*pasterrors.StructuredError{Category, What, Why, Impact, Fix}` matching `pasture/internal/errors/errors.go`. §11 Scenario 5 assertion shape verified field-by-field against the producer. | §7.10, §11 Scenario 5 |
| **A4** | Axis A IMPORTANT — R5/D5 epoch-id alignment enforced only by user discipline | New §7.12 "Epoch-ID validation policy". `Activities.RecordTransition` and the workflow start path call `provenance.ParseTaskID` and reject malformed input with `*StructuredError{Category: CategoryValidation, ...}`. New BDD Scenario 13. | §7.12 (new), §11 Scenario 13 (new) |
| **B1** | Axis B BLOCKER (`aura-plugins-3rdg4`) — partial-migration crash recovery asserted but never tested | New BDD Scenario 11 specifies a child-process crash injection between `audit_schema_meta=2` bump and v3 backfill commit; reopen invariant: file is at v2 OR v3, never half. Test mechanism, fixture, and assertions specified. | §10.3 (test list), §11 Scenario 11 (new) |
| **B2** | Axis B BLOCKER — concurrent migrator race uncovered | New BDD Scenario 12: two `os/exec.Cmd` migrators against same v1 db. Mechanism: `BEGIN IMMEDIATE` (rationale documented). Assertion: exactly one performs migration; the other either waits and observes post-migration state or returns an actionable `*StructuredError`. | §7.10.1 (locking), §11 Scenario 12 (new) |
| **B3** | Axis B BLOCKER — §10.3 in-memory race test does not prove D11/C5 (single file, two subsystems = fine) | §10.3 race test rewritten as a file-backed integration test interleaving `audit.Trail.RecordEvent`, `protocol.TaskTracker.AttachContext`, `provenance.Tracker.CreateTask`, and `provenance.Tracker.StartActivity` from N goroutines on the same `dbPath`, >1000 iterations under `-race`. Assertion list updated. | §10.3 (rewritten) |
| **B4** | Axis B BLOCKER — Scenario 8 covered only ConstraintChecker; R10 requires all four AutomatonRole values | Scenario 8 expanded into 8a/8b/8c/8d, parameterised over the four AutomatonRole values. Concrete agents and hook events enumerated inline. | §11 Scenario 8 (expanded) |
| **B5** | Axis B BLOCKER — Scenario 4 used in-test fixture; "passes by construction" | New `pasture/testdata/legacy_audit_v1.db` checked-in fixture; Scenario 4 copies it to `t.TempDir()`. Fixture composition (row count by role, JSON edge cases, NULL columns) specified row-for-row so a reviewer can verify diversity. | §11 Scenario 4 (rewritten), §10.3 (fixture entry) |
| **C1** | Axis C non-blocking — interface bloat | §7.4 `TaskTracker` interface uses Go embedding: `interface { provenance.Tracker; audit.Trail; <6 new methods> }`. Saves ~30 lines; identical call-site ergonomics. | §7.4 (rewritten) |
| **C2** | Axis C non-blocking — constructor missing from §7.4 | `OpenTaskTracker(dbPath string) (TaskTracker, error)` listed alongside `Close()` in §7.4 surface. | §7.4 |
| **C3** | Axis C non-blocking — `AutomatonRoleDerivation` is the weakest enum value | **Drop `AutomatonRoleDerivation` generic category. Replace with two first-class enum values `AutomatonRoleConsensusReached` and `AutomatonRoleCreateFollowup`.** Per user direction in UAT-1 (`aura-plugins-n3ecv`): strongly-typed enums over stringly-typed APIs — the category IS the type, with no need for a generic parent containing exactly these two children. Future derivation-style automata get added explicitly when built. Well-known names use the simpler `pasture/automaton/<role-kebab>` pattern (no `/derivation/` middle segment). | §7.4 (enum values), §7.6 (note rewritten), §7.7.2 (well-known names rewritten), §8 S7 (instruction rewritten), §11 Scenario 8d (rewritten) |
| **UAT-placement** | UAT-1 direction (`aura-plugins-n3ecv`) — `TaskTracker` interface should be importable by other modules in the dayvidpham org | Move the `TaskTracker` interface and the `OpenTaskTracker(dbPath string) (TaskTracker, error)` constructor from `pasture/internal/tasks` to `pasture/pkg/protocol/tasktracker.go` (alongside the existing `AuditEvent`, `EventType`, `SessionEntry`, `PhaseId` public types). Also move the `AutomatonRole`, `PastureRole`, and `ContextKind` typed enums to `pkg/protocol` since they are part of the public façade. The IMPLEMENTATION still lives at `pasture/internal/tasks/tracker.go`, implementing the `protocol.TaskTracker` interface. | §7.4 (package change + rationale), §8 S5 (slice description), §9 (public interfaces consolidated) |
| **U1** | UAT-1 (`aura-plugins-n3ecv`) — explicit migrate trigger requested | Add `pasture migrate [--dry-run]` CLI command (§7.9, §11 Scenario 15). Auto-on-open path preserved unchanged; both paths share one migrator implementation. Power users and CI gain a predictable manual trigger; default behaviour for ad-hoc users is unchanged. | §7.9 (CLI surface), §7.10 (note added), §8 S6 (slice scope expanded), §11 Scenario 15 (new) |

The 14-scenario BDD set, schema column list, slice list, and design-tradeoff table are otherwise structurally identical to PROPOSAL-1 — reviewers can read this proposal section-by-section against PROPOSAL-1 to verify nothing else was disturbed.

---

## 1. Summary

Build a unified Pasture workflow record + observability surface that combines the existing PROV-O task tracker (Provenance) and the existing Temporal-integrated audit subsystem behind a single `protocol.TaskTracker` façade in pasture, backed by a single SQLite file. The Provenance library is **not modified** (URE C4); integration happens at pasture's wrapper layer. The audit subsystem expands its scope from epoch-and-session events to also cover slices, reviews, follow-ups, hooks, skills, and git events both inside and around workflows. Event–context attachment moves to a normalised `context_edges` table in BCNF.

This proposal addresses URD `aura-plugins-dr2ps` requirements R1–R14 directly. Every architectural choice in §6 is grounded in either a settled URD design choice (D1–D7) or a URE clarification/disposition (C1–C5).

---

## 2. Verbatim user direction (preserved)

The full set of user statements is preserved in the URD and the ELICIT task. Quoted here are the load-bearing directives that constrain this proposal:

> *"Provenance the repo doesn't need to know about SessionEntry. Our pasture TaskTracker would. Our pasture TaskTracker would essentially be using the provenance library to provide the more human-focused CLI, extracted so that the PROV graph aspects can be developed independently."* — sets §6 D1, D2 architectural axis.

> *"What's happening with audit.db is still useful and shouldn't require much changes. Wouldn't their unification be possible without any changes to provenance?"* — answers §6 D1: Provenance is unmodified.

> *"No, I don't want them in separate .db files. What I mean: we need the epoch IDs in both the audit and provenance to align."* — answers §6 D3 (single SQLite file) and §6 D5 (epoch ID alignment).

> *"audit.db does not ONLY have to apply to epochs and sessions within those epochs. They should incorporate all those things INSIDE and AROUND a workflow too."* — sets §6 D6 (scope of recorded events).

> *"Should be something like this, but strongly-typed categories and sub-tags on our Pasture side. No changes needed to Provenance."* — answers §6 D7 (rule-automaton modelling).

> *"should be in Boyce-Codd Normal Form."* — sets §6 D8 (`context_edges` BCNF).

> *"Shouldn't be worried about write contention. Writes occur relatively infrequently."* — sets §6 D11 (single SQLite file is acceptable; no message-queue interposition).

---

## 3. Constraints (from URE clarifications C1–C5)

These are binding; any design decision that conflicts requires re-elicitation.

| ID | Constraint | Source | Impact on this proposal |
|---|---|---|---|
| **C1** | "Researcher's notes" / "exploratory notes" are **out of scope** | ELICIT C1 — agent-introduced hypothetical; not user-endorsed | No `ResearcherNoteContext` in the `context_kind` enum; no schema or CLI accommodation |
| **C2** | Free-floating event scope = workflow-related hooks + skills + git operations (commit, push, rebase, etc.) | ELICIT C2 — verbatim user endorsement | Drives the `context_kind` enum for `GitContext`, `SkillContext`; hooks reuse `EpochContext`/`SessionContext` |
| **C3** | Granularity = two tables, joinable on `agent_id`; not collapsed | ELICIT C3 — Round 2 Q1 final | §7.2 schema keeps `activities` and `audit_events` as distinct tables |
| **C4** | Provenance the library is **not modified** | ELICIT C4 — stated by user twice | All integration is in `pasture/` packages; no PRs to `github.com/dayvidpham/provenance` for this work. Where idempotency requires `(namespace, name)` lookups (BLOCKER A1), the audit migrator uses raw SQL on its own `*sql.DB` against the same shared file — no Provenance API change. |
| **C5** | Single SQLite file (not separate audit.db + provenance.db) | ELICIT C5 — verbatim "No, I don't want them in separate .db files" | §7.1 specifies one `.db` file path opened by both subsystems |

---

## 4. URD requirements addressed

| URD Req | Description | Addressed in §… |
|---|---|---|
| R1 | Provenance unmodified | §6 D1, §10.1 validation, §7.10 (raw-SQL approach justified under C4) |
| R2 | `protocol.TaskTracker` is the unified façade | §7.4 interface (embedded) |
| R3 | Single SQLite file at `~/.local/share/pasture/<filename>.db` | §7.1 — filename: `pasture.db` |
| R4 | Two tables (activities, audit_events) joinable on `agent_id` | §7.2 schema |
| R5 | Epoch ID alignment across subsystems | §6 D5, §7.3 ID-flow diagram, §7.12 validation policy |
| R6 | Scope: workflow-internal + adjacent + free-floating | §7.5 `context_kind` enum |
| R7 | Three actor categories with PROV-O attribution | §7.6 actor model |
| R8 | Pasture-side strongly-typed agent categorisation | §7.7 `pasture_agent_categories` + `pasture_well_known_agents` |
| R9 | `context_edges` in BCNF | §7.8 schema |
| R10 | All five concrete automaton categories emit events (UAT-1: ConstraintChecker, TransitionGate, HookHandler, ConsensusReached, CreateFollowup; `None` excluded) | §8 implementation slice S7, §11 Scenario 8a–8e |
| R11 | CLI under `pasture task <verb>` | §7.9 CLI surface |
| R12 | Auto-migrate audit_events schema on open | §7.10 migration (idempotent + crash-safe + concurrent-safe) |
| R13 | R11 (Pasture URD) Temporal SA dual-write preserved | §6 D12, §10.1 validation |
| R14 | Low write contention, single file is fine | §6 D11 rationale, §10.3 race test |

---

## 5. Problem space

### Axes
- **Concurrency**: multiple writers (`pastured` workflow activities, `pasture task` CLI from a human, hook handlers, future skill-runners) into one SQLite file. Per URD R14: low frequency, WAL mode + 5 s `busy_timeout` is sufficient. Migration is the only window of true contention (binary upgrade rollouts), handled via `BEGIN IMMEDIATE` (§7.10.1).
- **Lifetime**: live workflow execution events (workflow boundary), human-protocol task entities (epoch-spanning), free-floating events (no lifecycle anchor). All co-resident; differentiated by `context_edges`.
- **Generators**: humans, ML coding agents, conventional software agents, rules-based automata. All registered as Provenance Agents; the latter two share `SoftwareAgent` kind with pasture-side categorisation.
- **Cross-machine readiness**: SQLite is single-machine. Per ADR D2, this is acceptable for now; cross-machine deployment is its own future REQUEST.

### Has-a / Is-a
- A workflow run **has-a** PROV-O REQUEST Task (ID = epoch ID = Temporal workflow ID).
- A workflow run **has-many** Activities (one per phase bracket, plus sub-Activities for nested work).
- An Activity **has-many** audit events (point-in-time records inside its time window).
- An audit event **has-many** contexts (via `context_edges`): epoch, slice, review, follow-up, git, skill, session.
- An automaton **is-a** SoftwareAgent (Provenance) **with-a** pasture-side category (constraint_checker | transition_gate | hook_handler | derivation).
- A well-known automaton (e.g. `pasture/automaton/check-constraints`) **has-a** stable logical name in `pasture_well_known_agents`, mapped to a Provenance `AgentID` minted exactly once across the lifetime of the database.

### Existing assets to preserve
- `internal/audit/{audit,memory,sqlite,activities}.go` — fully built; `Trail` interface; `SqliteAuditTrail` with WAL + `ensureSchema`.
- `provenance.Tracker` (28-method interface) — handles task CRUD, edges, labels, comments, agents, activities.
- `pkg/protocol/{types,session_entry}.go` — `AuditEvent`, `EventType`, `SessionEntry`, `PhaseId`, `PhaseRole`.
- `cmd/pasture/task_*.go` (hjsdt, commit `30dcdd6`) — `pasture task` CLI surface; will be re-routed through `protocol.TaskTracker` per R2.
- `internal/tasks/open.go` — existing `OpenTracker` helper; this proposal adds `OpenTaskTracker` alongside, returning the unified façade.
- `internal/temporal/{workflow,activities,search_attributes}.go` — `EpochWorkflow` writes audit + upserts SAs (R13); preserved unchanged at the workflow boundary.
- `internal/errors/errors.go` — `*StructuredError{Category, What, Why, Impact, Fix}` is the canonical error shape; all migration / open / validation errors in this proposal use it (BLOCKER A3).

---

## 6. Engineering tradeoffs (settled by URE)

| ID | Decision | Pros | Cons | Why we picked this |
|---|---|---|---|---|
| **D1** | Provenance the library is **not modified** | Library stays domain-pure; reusable beyond pasture; no churn in a separate repo | Pasture must wrap rather than extend; some duplication in domain naming | URE C4 — stated twice by user. Library domain purity is non-negotiable. |
| **D2** | `protocol.TaskTracker` (URD R7) is revived as the integration mechanism | One façade for CLI, workflows, and hooks; cross-cutting concerns (logging, hooks, default namespace) live here; future swap-readiness | Adds a layer; some indirection cost | URD R2; ADR D3 had deferred this without trigger — URE supplied the trigger. |
| **D3** | Single SQLite file (`~/.local/share/pasture/pasture.db`) | One backup target; epoch IDs trivially join across tables; matches user mental model | Two subsystems share WAL — small contention in theory | URE C5 — verbatim "No, I don't want them in separate .db files". URE Q3 confirmed write contention is not a real concern. |
| **D4** | Two tables (`activities` + `audit_events`); joinable on `agent_id` | Granularity preserved (phase brackets vs point events); existing schema barely changes; queries express intent clearly | Two tables vs one; query authors must know which to read | URE Round 2 Q1 — user picked "Both, separate" with the additional categorisation table. |
| **D5** | Epoch ID = Provenance REQUEST TaskID = Temporal workflow ID = `audit_events` epoch context (via `context_edges` after migration) | Single string flows through whole stack; no translation; `tctl` queries align with DB queries | Identifier shape (Provenance's `namespace--uuid`) is longer than today's free-string epoch IDs | URE direct quote: "we need the epoch IDs in both the audit and provenance to align". Enforced at workflow start by `provenance.ParseTaskID` (§7.12). |
| **D6** | Scope expands beyond epochs to include slices, reviews, follow-ups, hooks, skills, git operations | Captures the whole engineering record; supports retrospectives and cross-epoch analysis | More event types to design; larger event volume (still low per URD R14) | URE Round 1 Q1 — user picked "Workflow + adjacent + free-floating" + verbatim list of in-scope event categories. |
| **D7** | Rule automata = `SoftwareAgent` + pasture-side strongly-typed categories | No Provenance changes; type safety on the pasture side; humans/ML/conventional software stay on existing PROV-O kinds | Categorisation lives in two places (PROV-O kind + pasture category); JOINs needed for full identity | URE Round 2 Q2 + verbatim "strongly-typed categories and sub-tags on our Pasture side. No changes needed to Provenance". |
| **D8** | `context_edges(event_id, context_kind, context_id)` many-to-many; BCNF | One event can attach to multiple contexts (e.g., a git commit tied to an epoch AND a slice); schema fully normalised | Adds a JOIN to most queries vs an inline column | URE Round 3 Q2 + verbatim "should be in Boyce-Codd Normal Form". |
| **D9** | CLI verbs stay under `pasture task <verb>` | Single verb namespace for entity work AND event/timeline queries; matches what hjsdt established | `pasture task` covers more semantics than just task CRUD; subcommand list grows | URE Round 2 Q3. |
| **D10** | Auto-migrate audit_events schema on open via `audit_schema_meta` version table | Backwards-readable; no data loss; matches the bestiary pattern; opaque to callers | Migration code must be tested; schema rollbacks not supported (forward-only) | URE Round 2 Q4. |
| **D11** | Low write frequency = no message-queue interposition | Simplest possible architecture; no extra processes | If write rate ever increases, this assumption needs revisiting | URE Round 3 Q3 + verbatim "Shouldn't be worried about write contention". Race test in §10.3 proves cross-subsystem case. |
| **D12** | R11 (Pasture URD) Temporal SA dual-write preserved at workflow boundary | Native `tctl` queryability for in-flight epochs; orthogonal to substrate; zero risk during migration | Requires no change — but must be explicitly preserved during refactors | URD R13; ADR D2 cycle 3. |

---

## 7. Public interfaces and schema

### 7.1 Filesystem layout
- Default DB path: `~/.local/share/pasture/pasture.db`.
- Override: `--db <path>` flag on `pasture` and `pastured`; env `PASTURE_DB_PATH`. (`pastured`'s existing `--audit-db-path` becomes an alias for `--db` after migration; if both are set and disagree, prefer `--db` and emit a deprecation warning per Constraint C-actionable-errors.)
- Both `provenance.OpenSQLite(dbPath)` and `audit.NewSqliteAuditTrail(dbPath)` open the same file.

### 7.2 Schema (post-migration)

Tables owned by **Provenance** (unchanged — this proposal does not touch them):
- `tasks`, `edges`, `labels`, `comments`
- `agents`, `agents_human`, `agents_ml`, `agents_software`, `ml_models`, `providers`
- `activities`
- Provenance's internal lookup tables and its own schema metadata

Tables owned by **`internal/audit` / `internal/tasks`** (this proposal modifies `audit_events`, adds four new tables):

```sql
-- Reshaped from current; old `epoch_id` and `role` columns drop in favor of agent_id + context_edges.
audit_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id    TEXT NOT NULL,                 -- soft reference to provenance.agents.id; no FK constraint
    phase       TEXT,                          -- nullable for free-floating events
    event_type  TEXT NOT NULL,                 -- protocol.EventType wire string
    payload     TEXT NOT NULL,                 -- JSON, schema validated by EventType
    timestamp   INTEGER NOT NULL               -- Unix nanoseconds UTC
);
CREATE INDEX idx_audit_events_agent     ON audit_events (agent_id);
CREATE INDEX idx_audit_events_timestamp ON audit_events (timestamp);

-- Many-to-many context attachment. BCNF: 3-column composite-key, no non-key columns.
context_edges (
    event_id     INTEGER NOT NULL REFERENCES audit_events(id) ON DELETE CASCADE,
    context_kind TEXT NOT NULL,                -- ContextKind enum wire string
    context_id   TEXT NOT NULL,                -- shape varies per kind: epoch TaskID, git SHA, etc.
    PRIMARY KEY (event_id, context_kind, context_id)
);
CREATE INDEX idx_context_edges_lookup ON context_edges (context_kind, context_id);
CREATE INDEX idx_context_edges_event  ON context_edges (event_id);

-- Pasture-side typed categorisation for agents (R8).
pasture_agent_categories (
    agent_id        TEXT PRIMARY KEY,          -- soft reference to provenance.agents.id
    automaton_role  TEXT NOT NULL DEFAULT 'None',  -- AutomatonRole enum
    pasture_role    TEXT NOT NULL DEFAULT 'None'   -- PastureRole enum
);

-- Well-known automaton registry (BLOCKER A2) — provides stable logical-name → AgentID mapping
-- so daemon restarts do NOT re-register duplicates via Provenance's UUIDv7-minting RegisterSoftwareAgent.
-- UAT-1: agent_id is PK (canonical FK target across pasture_agent_categories and agents_software);
-- name is UNIQUE (still O(1) lookupable). Keeps the canonical-identity column consistent across pasture-side tables.
pasture_well_known_agents (
    agent_id  TEXT PRIMARY KEY,                -- soft reference to provenance.agents.id
    name      TEXT NOT NULL UNIQUE             -- e.g. "pasture/automaton/check-constraints"
);

-- Schema version tracking (R12) — audit's own; separate from Provenance's.
audit_schema_meta (
    version    INTEGER PRIMARY KEY,
    applied_at INTEGER NOT NULL                -- Unix nanoseconds UTC
);
```

The existing `session_entries` table is preserved unchanged (`SessionEntry` is below PROV-O granularity).

> **Note on FK constraints (Axis A non-blocking observation).** The reference from `audit_events.agent_id` to `provenance.agents.id`, and from `pasture_agent_categories.agent_id` and `pasture_well_known_agents.agent_id` to the same target, are **soft references** — no SQL `FOREIGN KEY` clause. Provenance owns its tables and is unmodified (C4); cross-table FKs would require coupling the migrators. Application code is the integrity layer here.

### 7.3 Epoch ID alignment

```
Human invokes: pasture task create REQUEST "<title>" --type=feature --phase=request
                       │
                       ▼  protocol.TaskTracker.Create() → provenance.Tracker.Create()
            req := provenance.Task{ID: TaskID{Namespace: "aura-plugins", UUID: <uuidv7>}}
                       │
                       │  epochID := req.ID.String()      ← "aura-plugins--01968a3c-..."
                       ▼
       Human invokes: pasture-msg epoch start --epoch-id <epochID>
                       │
                       ▼  client.ExecuteWorkflow(EpochWorkflow, EpochInput{EpochID: epochID, RequestTaskID: req.ID})
                          §7.12: workflow start path validates epochID via provenance.ParseTaskID
                                 — rejects malformed IDs at workflow start with *StructuredError{Category: CategoryValidation}
       Temporal workflow ID = epochID

       EpochWorkflow.Run:
                       │
                       ▼  ExecuteActivity(StartActivity, agentID=workflow-agent, phase=request, ...)
                          ↳ provenance.Tracker.StartActivity(...)
                       ▼  ExecuteActivity(RecordAuditEvent, AuditEvent{...})
                          ↳ audit.Trail.RecordEvent(...)  → INSERT INTO audit_events (returns event_id)
                          ↳ protocol.TaskTracker.AttachContext(event_id, ContextEpoch, epochID)
                                                          → INSERT INTO context_edges
                       ▼  workflow.UpsertSearchAttributes(SA_EPOCH_ID: epochID, ...)   ← R13 preserved
```

For free-floating events (no epoch context), the same flow runs but `AttachContext` uses a different `context_kind`:
- A git commit hook fires → records `AuditEvent{event_type: "GitCommit", ...}` with `context_edges(event_id, GitContext, "<sha>")`.
- A skill invocation outside an epoch → `(event_id, SkillContext, "aura:user-elicit-<run-id>")`.
- An adjacent post-epoch commit citing epoch X → two context edges: `(event_id, GitContext, "<sha>")` and `(event_id, EpochContext, "<epochID>")`.

### 7.4 `protocol.TaskTracker` interface (R2; BLOCKER C1, C2 applied; UAT-1 placement fix; import-cycle correction 2026-04-25)

The interface is composed via Go embedding from `provenance.Tracker` plus four inlined `audit.Trail` method signatures plus six genuinely new methods. Embedding `provenance.Tracker` saves ~28 lines of redeclaration and means new methods on `provenance.Tracker` propagate without churn (C1 fix). The four `audit.Trail` methods are inlined (not embedded) to break an import cycle — see the correction callout below.

> **Import-cycle correction (2026-04-25).** PROPOSAL-2 originally specified embedding both `provenance.Tracker` AND `audit.Trail` in `pkg/protocol.TaskTracker`. The S5 worker (`aura-plugins-mbkfi`) discovered this is a Go import cycle: `internal/audit` already imports `pkg/protocol` (for `AuditEvent`, `EventType`, `SessionEntry`, `PhaseId`), so `pkg/protocol` cannot import `internal/audit` to embed `audit.Trail`. **Resolution:** the four `audit.Trail` methods (`RecordEvent`, `QueryEvents`, `RecordSessionEntries`, `QuerySessionEntries`) are re-declared inline in `TaskTracker` with byte-identical signatures, so any concrete `audit.Trail` implementation still satisfies the inlined contract. The `provenance.Tracker` embedding is unaffected (different module, no cycle). Net public surface from the caller's perspective is identical (~39 methods); only the declaration mechanism changes.

> **Package placement (UAT-1 direction).** The interface declaration and the `OpenTaskTracker` constructor live in `pasture/pkg/protocol/tasktracker.go` (alongside the existing `AuditEvent`, `EventType`, `SessionEntry`, `PhaseId` public types). The IMPLEMENTATION lives in `pasture/internal/tasks/tracker.go`. Rationale: interface in `pkg/protocol` so other modules in the dayvidpham org can import it; implementation stays internal. The `AutomatonRole`, `PastureRole`, and `ContextKind` enums (defined below in §7.4 and §7.5) likewise live in `pkg/protocol` since they are part of the public façade.

```go
// Package protocol exposes the public, importable surface of the unified
// pasture workflow record. The TaskTracker interface and OpenTaskTracker
// constructor are declared here so external modules can program against the
// façade; the implementation is internal to pasture (internal/tasks).
package protocol

import (
    "context"

    "github.com/dayvidpham/provenance"
)

// TaskTracker is the unified façade. Implementations wrap a provenance.Tracker
// and an audit.Trail backed by the same SQLite file.
//
// Embeds provenance.Tracker; inlines the four audit.Trail method signatures
// (audit.Trail cannot be embedded because internal/audit imports pkg/protocol —
// see import-cycle correction callout above); adds six pasture-only methods.
type TaskTracker interface {
    provenance.Tracker     // task CRUD, edges, labels, comments, agents, activities

    // ─── Audit methods (inlined from audit.Trail to break import cycle) ──
    // Signatures are byte-identical to audit.Trail so any audit.Trail
    // implementation satisfies this contract.
    RecordEvent(ctx context.Context, event AuditEvent) error
    QueryEvents(ctx context.Context, epochID string, phase *PhaseId, role *string) ([]AuditEvent, error)
    RecordSessionEntries(ctx context.Context, entries []SessionEntry) error
    QuerySessionEntries(ctx context.Context, sessionID string) ([]SessionEntry, error)

    // ─── Pasture-side category decoration (R8) ───────────────────────────
    SetAgentCategories(id provenance.AgentID, automaton AutomatonRole, pastureRole PastureRole) error
    AgentCategories(id provenance.AgentID) (AutomatonRole, PastureRole, error)

    // ─── Context attachment (R9) ─────────────────────────────────────────
    AttachContext(ctx context.Context, eventID int64, kind ContextKind, contextID string) error
    EventContexts(ctx context.Context, eventID int64) ([]Context, error)
    Timeline(ctx context.Context, kind ContextKind, contextID string) ([]AuditEvent, error)

    // ─── Lifecycle ───────────────────────────────────────────────────────
    Close() error
}

// OpenTaskTracker opens the unified SQLite database at dbPath, runs the audit
// migrator (§7.10), and returns a TaskTracker that wraps the resulting
// provenance.Tracker and audit.Trail on the same file.
//
// Errors are *pasterrors.StructuredError with CategoryConnection (open
// failures), CategoryStorage (migration failures), or CategoryValidation
// (newer-schema rejection). Callers map to exit codes via pasterrors.ExitCode.
//
// Callers MUST call Close on the returned tracker.
func OpenTaskTracker(dbPath string) (TaskTracker, error)

// AutomatonRole is the strongly-typed pasture-side category for SoftwareAgent
// instances that represent rules-based automata (URD R8).
type AutomatonRole string

const (
    AutomatonRoleNone              AutomatonRole = "None"
    AutomatonRoleConstraintChecker AutomatonRole = "ConstraintChecker"
    AutomatonRoleTransitionGate    AutomatonRole = "TransitionGate"
    AutomatonRoleHookHandler       AutomatonRole = "HookHandler"
    AutomatonRoleConsensusReached  AutomatonRole = "ConsensusReached"
    AutomatonRoleCreateFollowup    AutomatonRole = "CreateFollowup"
)

// PastureRole mirrors PROV-O Role for non-automaton agents (humans, ML).
type PastureRole string

const (
    PastureRoleNone       PastureRole = "None"
    PastureRoleArchitect  PastureRole = "Architect"
    PastureRoleSupervisor PastureRole = "Supervisor"
    PastureRoleWorker     PastureRole = "Worker"
    PastureRoleReviewer   PastureRole = "Reviewer"
)
```

> **C1 size note.** The four inlined `audit.Trail` methods (`RecordEvent`, `QueryEvents`, `RecordSessionEntries`, `QuerySessionEntries`) plus the embedded `provenance.Tracker` (~28 methods) plus the 6 pasture-only methods plus `Close` give a public surface of ~39 methods. Architecturally identical to the user's UAT direction; only the declaration mechanism changes (inline vs embed) to break the import cycle. The implementation's pasture-specific surface is exactly 6 methods plus `Close` and `OpenTaskTracker`.

> **C2 constructor pair.** `OpenTaskTracker` and `Close` are listed in the API surface block above so the open/close pair is visible at one glance. `OpenTaskTracker` mirrors the existing `tasks.OpenTracker` (`pasture/internal/tasks/open.go`) but routes through the new façade and additionally invokes the audit migrator.

### 7.5 `ContextKind` enum (R6, R9)

```go
// ContextKind enumerates the kinds of context an audit event may attach to.
// Wire values are stable strings stored in context_edges.context_kind.
type ContextKind string

const (
    ContextNone     ContextKind = "None"
    ContextEpoch    ContextKind = "EpochContext"
    ContextSlice    ContextKind = "SliceContext"
    ContextReview   ContextKind = "ReviewContext"
    ContextFollowup ContextKind = "FollowupContext"
    ContextGit      ContextKind = "GitContext"
    ContextSkill    ContextKind = "SkillContext"
    ContextSession  ContextKind = "SessionContext"
)
```

`Context` carries a typed pair plus optional metadata:

```go
type Context struct {
    Kind      ContextKind
    ContextID string         // "<epoch-uuid>", "<git-sha>", "<skill-run-id>", etc.
}
```

### 7.6 Actor model (R7, R8)

Provenance's existing four agent kinds remain canonical:

| Provenance kind | Used for | Pasture categorisation needed? |
|---|---|---|
| `HumanAgent` | David, future contributors | `pasture_role` only |
| `MLAgent` | Claude / Gemini / OpenAI agents acting in epoch roles | `pasture_role` only (architect/supervisor/worker/reviewer) |
| `SoftwareAgent` | `pastured` workflow daemon, `pasture-msg`, `pasture` CLI, automata | both `automaton_role` and `pasture_role` (the latter `None` for non-role-bound automata) |

Concrete well-known SoftwareAgents are registered exactly once at `pastured` startup using the §7.7 lookup-then-register-then-insert flow. The well-known names listed in §7.7 are the canonical instances of each `AutomatonRole`.

> **C3 resolution (UAT-1 direction).** The earlier generic `AutomatonRoleDerivation` catch-all has been dropped. It is replaced with two first-class enum values: `AutomatonRoleConsensusReached` and `AutomatonRoleCreateFollowup`. Rationale: aligns with the project's "strongly-typed enums over stringly-typed APIs" CLAUDE.md philosophy — the category IS the type, with no need for a generic parent that contains exactly these two children. Future derivation-style automata get added to the enum explicitly when they are built. The corresponding well-known names use the simpler `pasture/automaton/<role-kebab>` pattern (no extra `/derivation/` middle segment, since the role IS the category): `pasture/automaton/consensus-reached` and `pasture/automaton/create-followup`. The actor-model categorisation now ranges over **6 enum values** (None + 5 concrete categories: ConstraintChecker, TransitionGate, HookHandler, ConsensusReached, CreateFollowup); each `SoftwareAgent` row's "Pasture categorisation" column references this 6-value enum.

### 7.7 `pasture_agent_categories` + `pasture_well_known_agents` (R8 + BLOCKER A2)

#### 7.7.1 Table contracts

- `pasture_agent_categories(agent_id PK, automaton_role, pasture_role)` — one row per registered Provenance Agent that needs typed categorisation. Inserted by `protocol.TaskTracker.SetAgentCategories(agentID, automaton, role)` immediately after `RegisterSoftwareAgent`.
- `pasture_well_known_agents(agent_id PK, name UNIQUE)` — one row per stable logical name. The startup sequence is the **only** writer of this table; CLI and workflows never insert here. The UNIQUE constraint on `name` is the idempotency anchor (lookup-by-name is O(1) via the unique index); `agent_id` is PK so the canonical-identity column matches `pasture_agent_categories` and `agents_software` (UAT-1 direction).

#### 7.7.2 Well-known logical names (canonical list)

These names are stable strings owned by pasture. They survive across restarts; their `agent_id` values are minted exactly once each, on the first daemon startup that observes their absence from `pasture_well_known_agents`.

| Name (PK in `pasture_well_known_agents`) | `automaton_role` | Registered by |
|---|---|---|
| `pasture/automaton/check-constraints` | `ConstraintChecker` | S7 startup (one row) |
| `pasture/automaton/transition-gate/consensus` | `TransitionGate` | S7 startup |
| `pasture/automaton/transition-gate/vote-threshold` | `TransitionGate` | S7 startup |
| `pasture/automaton/transition-gate/exit-condition` | `TransitionGate` | S7 startup |
| `pasture/automaton/hook/SessionStart` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/UserPromptSubmit` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/PreToolUse` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/PostToolUse` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/Notification` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/Stop` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/SubagentStop` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/PreCompact` | `HookHandler` | S7 startup |
| `pasture/automaton/hook/SessionEnd` | `HookHandler` | S7 startup |
| `pasture/automaton/consensus-reached` | `ConsensusReached` | S7 startup |
| `pasture/automaton/create-followup` | `CreateFollowup` | S7 startup |

The hook list mirrors the 9 + 3 = 12 Claude Code hook events from Pasture URD D7 (subject to that URD's authoritative list at S7 implementation time).

#### 7.7.3 Idempotent startup sequence (BLOCKER A2)

At `pastured` boot, for **each** name in §7.7.2, the daemon executes the following pseudocode in **one** transaction on the audit `*sql.DB` (the same connection that owns `pasture_well_known_agents` and `pasture_agent_categories`):

```go
// Pseudocode — actual call sites live in cmd/pastured/main.go and go through protocol.TaskTracker.
func ensureWellKnownAgent(tx *sql.Tx, tracker protocol.TaskTracker, name string,
                          role protocol.AutomatonRole, version, source string) (provenance.AgentID, error) {

    // 1. Lookup-by-name (O(1) via the UNIQUE index on `name`; PK is now agent_id per §7.2).
    var agentIDStr string
    err := tx.QueryRow(
        `SELECT agent_id FROM pasture_well_known_agents WHERE name = ?`, name,
    ).Scan(&agentIDStr)
    if err == nil {
        // already registered — no-op
        return provenance.MustParseAgentID(agentIDStr), nil
    }
    if err != sql.ErrNoRows {
        return provenance.AgentID{}, &pasterrors.StructuredError{
            Category: pasterrors.CategoryStorage,
            What:     fmt.Sprintf("could not check well-known agent registry for name=%q", name),
            Why:      err.Error(),
            Impact:   "daemon startup cannot guarantee idempotent automaton registration",
            Fix:      "verify the database file is accessible and the schema is at v3 or higher",
        }
    }

    // 2. Register through Provenance (mints one fresh UUIDv7)
    sa, err := tracker.RegisterSoftwareAgent("pasture", name, version, source)
    if err != nil {
        return provenance.AgentID{}, /* wrapped StructuredError */
    }

    // 3. Insert mapping rows in the same transaction.
    //    Column order matches §7.2 schema: agent_id (PK), name (UNIQUE).
    if _, err := tx.Exec(
        `INSERT INTO pasture_well_known_agents (agent_id, name) VALUES (?, ?)`,
        sa.ID.String(), name,
    ); err != nil { /* StructuredError */ }
    if _, err := tx.Exec(
        `INSERT INTO pasture_agent_categories (agent_id, automaton_role, pasture_role)
         VALUES (?, ?, 'None')`,
        sa.ID.String(), string(role),
    ); err != nil { /* StructuredError */ }

    return sa.ID, nil
}
```

Two consecutive `pastured` starts produce identical row counts in `agents`, `agents_software`, `pasture_well_known_agents`, and `pasture_agent_categories` — verified by §11 Scenario 14. Idempotency is independent of which column is PK in `pasture_well_known_agents`; the UAT-1 schema inversion (`agent_id` PK, `name` UNIQUE) preserves both insert-uniqueness on `name` and the lookup-by-name shape used in step 1.

### 7.8 `context_edges` design (R9)

BCNF rationale: the only non-trivial functional dependency is `(event_id, context_kind, context_id) → ∅` (the row exists or not). There are no partial or transitive deps because there are no non-key columns. The table is in 6NF, which implies BCNF.

This structure trivially supports:
- *"Show me all events for epoch X"*: `SELECT * FROM audit_events e JOIN context_edges c ON c.event_id = e.id WHERE c.context_kind = 'EpochContext' AND c.context_id = ?`
- *"Show me all contexts attached to event Y"*: `SELECT context_kind, context_id FROM context_edges WHERE event_id = ?`
- *"Show me all events tied to git commit `<sha>` AND epoch X"*: two-clause `EXISTS` over `context_edges`.

### 7.9 CLI surface (R11)

All under `pasture task`. New subcommands:

```
pasture task events    [--epoch-id E] [--phase P] [--agent A] [--type T] [--since TS]
                       [--context-kind K --context-id ID]
                       [--format json|text]                          # query audit_events with optional context filter

pasture task timeline  <task-id>                                     # all events for the task ID, ordered by timestamp
                       [--include-children] [--depth N] [--format ..]

pasture task contexts  <event-id> [--format ..]                      # list all context_edges for an event

pasture task agents    [list | show <id>] [--format ..]              # list registered agents with categories
```

Additionally, a top-level `pasture migrate` command exposes the auto-migrator for predictable manual invocation (UAT-1 direction; sits at `pasture` level, not under `pasture task`, because it is db-level, not task-level):

```
pasture migrate        [--db <path>] [--dry-run]                     # explicit migrator entry point
```

Behaviour:
- `--dry-run`: prints the planned migrations (e.g., `v1→v2: add audit_schema_meta`, `v2→v3: add new tables, backfill agent_id`, `v3→v4: drop epoch_id, write context_edges`) and exits 0 without modifying the file.
- Without `--dry-run`: runs the same code path that `NewSqliteAuditTrail` invokes on auto-on-open. Idempotent if the file is already at the highest known version.
- On success: prints `migrated <db-path> from v<from> to v<to>` and exits 0.
- On failure: emits a `*pasterrors.StructuredError{Category: CategoryStorage, ...}` and exits with the `CategoryStorage` exit code (5, per §7.10.5).

The CLI command and the auto-on-open path share **one** migrator implementation — the explicit command is an alternative entry point, not a separate code path.

Existing subcommands (`create / show / update / close / list / dep / label / comment / ready / blocked`) continue to work unchanged but route through `protocol.TaskTracker` instead of importing `provenance` directly.

### 7.10 Auto-migration (R12) — idempotent + crash-safe (BLOCKERs A1, B1, B2)

`OpenTaskTracker(dbPath)` opens the file, ensures the audit-side tables exist via a bootstrap step, then reads `audit_schema_meta` and runs forward migrations.

> **Explicit-command path (UAT-1).** Migration is also exposed as an explicit CLI command `pasture migrate` (§7.9). The CLI command and the auto-on-open path share the same migrator implementation; users who prefer predictable migration windows (e.g., CI pipelines, blue/green binary rollouts) can run `pasture migrate --dry-run` to preview and `pasture migrate` to apply, then start `pastured` against an already-migrated db. There is no behavioural divergence between the two paths.

#### 7.10.1 Migration table

| Version | Migration | Notes |
|---|---|---|
| 1 | (current shape, pre-this-proposal) | `audit_events(epoch_id, phase, role, event_type, payload, timestamp)`; no `context_edges`, `pasture_agent_categories`, `pasture_well_known_agents`, or `audit_schema_meta` tables. |
| 2 | Add `audit_schema_meta` and seed `(version=2, applied_at=<now>)`. | One-shot bootstrap; idempotent (uses `INSERT OR IGNORE`). |
| 3 | Create `pasture_agent_categories`, `pasture_well_known_agents`, `context_edges`. Add `audit_events.agent_id` column (NULLABLE during transition). **Backfill** (idempotent, see §7.10.2): for each row, find-or-create a SoftwareAgent for the legacy `role` value (keyed on `(namespace, name)` via raw SQL on the audit `*sql.DB`'s view of `agents_software`), and write that AgentID into `agent_id`. Then drop `audit_events.role` (SQLite via table-rebuild pattern). | Forward-only; no rollback. **Whole step is one `BEGIN IMMEDIATE` / `COMMIT` on the audit `*sql.DB`** — including the `audit_schema_meta` bump from 2 to 3. Crash mid-way leaves the file at v2 (the transaction is rolled back). |
| 4 | Backfill rows into `context_edges` with `kind=EpochContext` from `audit_events.epoch_id`, then drop `audit_events.epoch_id`. | Same forward-only constraint. Same `BEGIN IMMEDIATE` + `audit_schema_meta` bump-as-final-statement pattern. |

#### 7.10.2 v3 backfill idempotency (BLOCKER A1, C4-compliant)

The audit migrator owns its own `*sql.DB` opened against the same `dbPath` that Provenance opens. **No Provenance code is modified**: the migrator reads `agents_software` directly via raw SQL, exactly as Provenance does internally. This is C4-compliant because:

1. **Same file, same process.** The audit migrator and any Provenance writer in the same process run on the same SQLite file. `BEGIN IMMEDIATE` on the migrator's `*sql.DB` acquires the database write lock and serialises against any Provenance writer.
2. **No Provenance API change.** The migrator is read-only against `agents_software` for the find step, and writes only to (a) the `agents` and `agents_software` tables in the find-or-create branch (using the same SQL shape Provenance uses internally — `INSERT INTO agents (id, kind_id) VALUES (?, 2); INSERT INTO agents_software (agent_id, name, version, source) VALUES (?, ?, ?, ?)`), (b) `audit_events`, (c) `audit_schema_meta`. The Provenance Go package is unmodified.
3. **Find-or-create on `(namespace, name)` is keyed precisely.** Even though `agents_software.name` has no SQL `UNIQUE` constraint (`provenance/internal/sqlite/db.go:151`), the migrator's find query is `SELECT a.id FROM agents a JOIN agents_software s ON a.id = s.agent_id WHERE a.kind_id = 2 AND s.name = ? LIMIT 1`. If a row exists from a prior partial run, it is reused; if not, one is created with a deterministic-by-context `agent_id` minted via UUIDv7 (the same algorithm Provenance uses).

The full v3 step in pseudocode:

```go
// Pseudocode — runs on the audit migrator's *sql.DB.
func migrateV2toV3(db *sql.DB) error {
    tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelDefault})
    if err != nil { /* StructuredError */ }
    defer tx.Rollback() // safe even after Commit

    // Lock the database for writes.
    if _, err := tx.Exec(`BEGIN IMMEDIATE`); err != nil { /* StructuredError */ }

    // 1. Create new tables.
    tx.Exec(`CREATE TABLE pasture_agent_categories (...)`)
    tx.Exec(`CREATE TABLE pasture_well_known_agents (...)`)
    tx.Exec(`CREATE TABLE context_edges (...)`)
    tx.Exec(`ALTER TABLE audit_events ADD COLUMN agent_id TEXT`)

    // 2. Distinct legacy roles.
    rows, _ := tx.Query(`SELECT DISTINCT role FROM audit_events WHERE role IS NOT NULL`)
    legacyRoles := scanStrings(rows)

    // 3. Find-or-create one SoftwareAgent per distinct role.
    roleToAgentID := map[string]string{}
    for _, role := range legacyRoles {
        var agentID string
        err := tx.QueryRow(
            `SELECT a.id FROM agents a JOIN agents_software s ON a.id = s.agent_id
             WHERE a.kind_id = 2 AND s.name = ? LIMIT 1`,
            "pasture/legacy-role/"+role,
        ).Scan(&agentID)
        if err == sql.ErrNoRows {
            agentID = "pasture--" + uuid.NewV7().String()
            tx.Exec(`INSERT INTO agents (id, kind_id) VALUES (?, 2)`, agentID)
            tx.Exec(`INSERT INTO agents_software (agent_id, name, version, source) VALUES (?, ?, ?, ?)`,
                agentID, "pasture/legacy-role/"+role, "v0", "pasture/internal/audit/migrate")
        } else if err != nil {
            return &pasterrors.StructuredError{ /* CategoryStorage */ }
        }
        roleToAgentID[role] = agentID
    }

    // 4. Backfill audit_events.agent_id.
    for role, agentID := range roleToAgentID {
        tx.Exec(`UPDATE audit_events SET agent_id = ? WHERE role = ? AND agent_id IS NULL`,
            agentID, role)
    }

    // 5. SQLite table-rebuild to drop the role column.
    tx.Exec(`CREATE TABLE audit_events_new (id INTEGER PRIMARY KEY AUTOINCREMENT, agent_id TEXT NOT NULL,
             phase TEXT, event_type TEXT NOT NULL, payload TEXT NOT NULL, timestamp INTEGER NOT NULL)`)
    tx.Exec(`INSERT INTO audit_events_new (id, agent_id, phase, event_type, payload, timestamp)
             SELECT id, agent_id, phase, event_type, payload, timestamp FROM audit_events`)
    tx.Exec(`DROP TABLE audit_events`)
    tx.Exec(`ALTER TABLE audit_events_new RENAME TO audit_events`)
    tx.Exec(`CREATE INDEX idx_audit_events_agent ON audit_events (agent_id)`)
    tx.Exec(`CREATE INDEX idx_audit_events_timestamp ON audit_events (timestamp)`)

    // 6. Bump schema version. THIS is the last statement before commit.
    tx.Exec(`INSERT INTO audit_schema_meta (version, applied_at) VALUES (3, ?)`, time.Now().UnixNano())

    return tx.Commit()
}
```

If the process is killed at any point before `tx.Commit()` returns, the entire transaction (including the `audit_schema_meta` bump) is rolled back by SQLite, and on the next open the file is observably at v2 — `SELECT MAX(version) FROM audit_schema_meta` returns 2. Idempotency on re-run: step 3's find-branch covers any partial run, so a second attempt either reuses the previously-created agents or creates them fresh in the rolled-back-then-retried transaction. (Verified by §11 Scenario 11.)

#### 7.10.3 Concurrent migrator race (BLOCKER B2)

When two `pastured` (or `pasture` + `pastured`) processes open the same v1 db simultaneously, the first to issue `BEGIN IMMEDIATE` acquires the SQLite write lock. The second blocks for up to `busy_timeout=5000` ms (already set by §7.1; existing `sqlite.go:81`). Three outcomes:

1. **First completes within busy_timeout.** Second's `BEGIN IMMEDIATE` succeeds; it re-reads `audit_schema_meta`, observes `version >= 3`, and skips the v3 step (no-op).
2. **First takes longer than busy_timeout.** Second's `BEGIN IMMEDIATE` returns `SQLITE_BUSY`; the migrator retries with exponential backoff up to 30 seconds. If still busy, it returns `*StructuredError{Category: CategoryStorage, What: "another pasture process is running the audit schema migration", Why: "BEGIN IMMEDIATE blocked by concurrent writer for >30s", Impact: "this process cannot open the unified database until the migration completes", Fix: "wait for the other pasture/pastured process to finish, or kill it and re-run; check via 'pasture task agents list' once unblocked"}`.
3. **First crashes mid-migration.** Lock is released by SQLite's WAL recovery; second proceeds normally per (1) above.

`BEGIN IMMEDIATE` is preferred over `BEGIN EXCLUSIVE` because: (a) WAL mode is enabled (`PRAGMA journal_mode=WAL`, `sqlite.go:80`) so readers can continue against the pre-migration view while the migration proceeds; (b) `IMMEDIATE` is sufficient to prevent concurrent writers, which is the only thing that matters for this migration's correctness.

#### 7.10.4 Newer-schema rejection error shape (BLOCKER A3 fix)

If the migrator detects a schema newer than what the binary supports (`max_known_version < db_version`), it returns:

```go
return &pasterrors.StructuredError{
    Category: pasterrors.CategoryStorage,  // see §7.10.5 below
    What:     fmt.Sprintf("audit database schema version %d is newer than supported version %d", dbVersion, maxKnownVersion),
    Why:      "this binary was built before the schema was bumped",
    Impact:   "no events can be read or written until the binary is upgraded",
    Fix:      "upgrade pasture to a version that supports schema v" + fmt.Sprint(dbVersion) + ", or pin to the older binary that wrote it; do NOT downgrade the database",
}
```

The producer error shape is field-by-field identical to what §11 Scenario 5 asserts. (Verified by inspecting `pasture/internal/errors/errors.go:34-45`: `Category, What, Why, Impact, Fix` — five fields, no others.)

#### 7.10.5 New `CategoryStorage` value

`pasterrors.Category` currently has four values (`CategoryConnection`, `CategoryWorkflow`, `CategoryValidation`, `CategoryConfig`). Migration and persistence failures don't fit any of those cleanly. **This proposal adds `CategoryStorage`** with exit code 5 (the next free integer after CategoryConfig=4). The change is local to `pasture/internal/errors/errors.go` and `ExitCode`; no external breakage.

### 7.11 Workflow integration (R13 preserved)

The `EpochWorkflow.Run` loop in `internal/temporal/workflow.go` is unchanged in shape:

```go
// Existing:
ExecuteActivity(actCtx, ActivityRecordTransition, epochID, transitionRecord)
ExecuteActivity(actCtx, ActivityRecordAuditEvent, auditEvent)
workflow.UpsertSearchAttributes(saEpochIDKey, saPhaseKey, ...)   // R13 — preserved
```

What changes is what the activities do internally: instead of `audit.Trail.RecordEvent(...)` directly, they call `protocol.TaskTracker.RecordEvent(...) → returns event_id`, then `protocol.TaskTracker.AttachContext(event_id, ContextEpoch, epochID)` to record the epoch correlation in the new `context_edges` table. The `UpsertSearchAttributes` call is byte-identical to today's.

### 7.12 Epoch-ID validation policy (BLOCKER A4 — new section)

R5 / D5 require the epoch ID be a Provenance `TaskID` (wire form `<namespace>--<uuid>`). Today, `pasture-msg epoch start --epoch-id <id>` accepts a free string (`pasture/cmd/pasture-msg/epoch.go:127`); nothing rejects a legacy non-TaskID input. With `context_edges (event_id, EpochContext, <free-string>)` rows landing in the unified DB, a malformed `EpochContext` value would reference no `tasks.id` row in Provenance, producing dangling correlations.

**Policy: reject malformed epoch IDs at workflow start.**

1. In `cmd/pasture-msg/epoch.go` (the CLI entry point) and in `internal/temporal/activities.go`'s `Activities.RecordTransition`, the workflow start path calls `provenance.ParseTaskID(epochID)` (existing public API at `provenance/reexports.go:174`) before any signal is sent or workflow is scheduled.
2. On `provenance.ParseTaskID` error, the CLI exits with code 1 (validation) and returns:

```go
return &pasterrors.StructuredError{
    Category: pasterrors.CategoryValidation,
    What:     fmt.Sprintf("epoch-id %q is not a valid Provenance TaskID", epochID),
    Why:      err.Error(),
    Impact:   "the workflow cannot be started without an epoch ID that aligns across the audit, Provenance, and Temporal subsystems (URD R5)",
    Fix:      "create the REQUEST task first with 'pasture task create REQUEST --type=feature \"<title>\"' and pass the returned ID as --epoch-id; or use 'pasture task list --status=open --type=feature' to find an existing one",
}
```

3. The same validation applies on the `Activities.RecordTransition` activity entry — even if a malformed ID slipped past CLI validation (e.g., via direct Temporal client call), the activity refuses to record a transition referencing it, and the workflow start fails fast.

This is enforced in tests by §11 Scenario 13.

> **Migration note for existing audit_events.** Legacy rows whose `epoch_id` was a free string (pre-Provenance) are migrated into `context_edges` with `kind=EpochContext` regardless of TaskID parseability — they are historical records and rejecting them would lose data. The §7.12 validation applies only to **new** workflow starts on or after the v3+v4 migration completes. This split is documented in the Scenario 4 fixture description.

---

## 8. Implementation slices

Each slice is independently buildable and testable. Order is dependency-driven; latter slices assume earlier ones land first.

| Slice | Scope | Exits when | Approx size |
|---|---|---|---|
| **S1: Schema migration foundation** | Add `audit_schema_meta` table + version-detection + migrator scaffold (no migrations yet, just the framework). Add `CategoryStorage` to `pasture/internal/errors`. | `NewSqliteAuditTrail` reads/writes `audit_schema_meta`; a no-op migration (v1→v2) test passes. | ~150 lines + tests |
| **S2: New tables** | `context_edges`, `pasture_agent_categories`, `pasture_well_known_agents` schemas; v2→v3 migration writes these into `ensureSchema`. Old rows untouched. | Tables exist; old rows still readable; new rows can be written via raw SQL in tests. | ~200 lines + tests |
| **S3: AgentID attribution in audit_events** | Add `audit_events.agent_id` (nullable). Migration v3 backfills from `role` via the find-or-create flow in §7.10.2 (raw SQL on the audit `*sql.DB`, single `BEGIN IMMEDIATE`). Drop `audit_events.role` via SQLite table-rebuild. | New rows write `agent_id`; legacy rows have `agent_id` populated post-migration. Idempotency test: re-run after kill-9 leaves no duplicate agents. | ~250 lines + tests |
| **S4: EpochContext migration** | v3→v4 migration: every existing row with `epoch_id != NULL` gets a `context_edges` entry with `kind=EpochContext`; `audit_events.epoch_id` column dropped. | All historical events queryable via `context_edges JOIN audit_events`; `epoch_id` column gone. | ~150 lines + tests |
| **S5: `protocol.TaskTracker` interface + impl** | New `pasture/pkg/protocol/tasktracker.go` declaring the public `TaskTracker` interface from §7.4 (using Go embedding) and `OpenTaskTracker(dbPath) (TaskTracker, error)` constructor (§7.4 C2 fix). New `pasture/internal/tasks/tracker.go` implementing the `protocol.TaskTracker` interface from `pkg/protocol/tasktracker.go`; the implementation wraps `provenance.Tracker` + `audit.Trail` (both opened against the same path). The `AutomatonRole`, `PastureRole`, `ContextKind` enums also live in `pkg/protocol`. | All `pasture task <verb>` CLI commands use `protocol.TaskTracker`. Tests mock `provenance.Tracker` and `audit.Trail` separately. | ~400 lines + tests |
| **S6: New CLI subcommands** | Add `pasture task events / timeline / contexts / agents` plus the top-level `pasture migrate [--dry-run]` command (UAT-1). Each routes through `protocol.TaskTracker` (or, for `pasture migrate`, the shared auto-on-open migrator). | Subprocess CLI tests cover happy + error paths for each new subcommand including `pasture migrate` happy-path, `--dry-run` non-mutation, and idempotent re-run on an already-v4 file (Scenario 15). | ~350 lines + tests |
| **S7: Automaton agent registration at `pastured` startup** | At daemon startup, for each well-known name in §7.7.2, run the `ensureWellKnownAgent` flow (lookup, register-if-absent, insert mapping rows in one transaction). Cache AgentIDs in memory. **C3 (UAT-1 resolution)**: register `consensus-reached` (`AutomatonRoleConsensusReached`) and `create-followup` (`AutomatonRoleCreateFollowup`) as concrete, first-class automaton agents. The previous `AutomatonRoleDerivation` generic catch-all has been dropped per UAT direction (`aura-plugins-n3ecv`); the category is now identical to the type. | `pastured --db <path>` starts up cleanly. Two consecutive starts produce identical row counts in `agents`, `agents_software`, `pasture_well_known_agents`, `pasture_agent_categories` (Scenario 14). All registered agents visible via `pasture task agents list`. | ~250 lines + tests |
| **S8: Workflow integration (Activities update + EpochContext attach)** | `Activities.RecordTransition` and `RecordAuditEvent` call `protocol.TaskTracker.RecordEvent` then `AttachContext(.., ContextEpoch, epochID)`. R13 SA upsert preserved unchanged. Add §7.12 epoch-ID validation at workflow start. | Integration test runs an EpochWorkflow start→advance→end and verifies: (a) Activities table has phase brackets, (b) audit_events has events, (c) context_edges has epoch attachments, (d) Temporal SAs are upserted, (e) malformed epoch-id is rejected (Scenario 13). | ~200 lines + tests |
| **S9: Free-floating event recording** | Hook handlers and skill-invocation entry points (when present) record events with non-epoch contexts (`GitContext`, `SkillContext`, `SessionContext`) via `protocol.TaskTracker.AttachContext`. | A git commit triggered by `pasture-msg` hooks records into audit_events with `context_kind=GitContext`. | ~200 lines + tests |
| **S10: pasture-msg + cmd/pasture wiring** | Update `cmd/pasture` (hjsdt-built binary) to use `protocol.TaskTracker` instead of importing `provenance` directly. `cmd/pastured` opens the unified DB via `OpenTaskTracker` and constructs the wrapper. `pasture-msg` is unchanged for now (per j9c88 deferral of binary umbrella). | Existing hjsdt CLI tests still pass; `pasture` CLI now visibly writes to `pasture.db` instead of separate files (verify via `sqlite3` shell). | ~150 lines + tests |
| **S11: Documentation + ADR finalisation** | Update `pasture/CLAUDE.md` and `pasture/AGENTS.md` to reference `protocol.TaskTracker`. Finalise the ADR (mark `Status: Accepted`); commit. | Docs reviewed; ADR committed; URD `aura-plugins-dr2ps` updated with implementation links. | ~docs only |

---

## 9. Public interfaces (consolidated)

All interfaces shown above in §7. For a single-file overview the reviewer can scan, the load-bearing additions are:

- **Go**: `pasture/pkg/protocol.TaskTracker` interface (§7.4) — embeds `provenance.Tracker`, inlines 4 audit methods (audit methods inlined to break import cycle since `internal/audit` imports `pkg/protocol`), adds 6 pasture-only methods; constructor `OpenTaskTracker(dbPath) (TaskTracker, error)`. The interface lives in `pkg/protocol` (importable by other modules in the dayvidpham org); the implementation lives in `internal/tasks` (private).
- **Go**: `pasture/pkg/protocol.AutomatonRole`, `PastureRole`, `ContextKind` typed enums (§7.4, §7.5). `AutomatonRole` ranges over 6 values: `None`, `ConstraintChecker`, `TransitionGate`, `HookHandler`, `ConsensusReached`, `CreateFollowup` (the previous `Derivation` generic value has been replaced by the two concrete categories per UAT-1).
- **Go**: `pasture/internal/errors.CategoryStorage` (§7.10.5) — exit code 5.
- **SQL** (`internal/audit/sqlite.go`): four new tables (`context_edges`, `pasture_agent_categories`, `pasture_well_known_agents`, `audit_schema_meta`), one column add (`audit_events.agent_id`), two column drops (`audit_events.role`, `audit_events.epoch_id`).
- **CLI**: four new `pasture task` subcommands (`events`, `timeline`, `contexts`, `agents`).

---

## 10. Validation checklist

### 10.1 Constraints (must hold for the proposal to be valid)
- [ ] Provenance the library is unmodified — no PRs to `github.com/dayvidpham/provenance` from this work. (Verified by `git log` per §11 Scenario 3.)
- [ ] The audit migrator's raw-SQL access to `agents_software` is read-mostly + matches Provenance's own `INSERT` shape exactly; no Go API change. (BLOCKER A1.)
- [ ] One SQLite file at `~/.local/share/pasture/pasture.db`; both subsystems open the same file.
- [ ] R13 (Pasture URD R11) Temporal SA dual-write is byte-identical pre/post-implementation.
- [ ] `context_edges` is in BCNF (verified by inspection: composite-key, no non-key columns).
- [ ] No new PROV-O AgentKind introduced.
- [ ] "Researcher's notes" / "exploratory notes" are not in any enum, schema, or CLI surface.
- [ ] `OpenTaskTracker` returns `*pasterrors.StructuredError` (never plain `fmt.Errorf`) on every failure path. (BLOCKER A3.)
- [ ] Two consecutive `pastured` starts against an unchanged DB do not increase row counts in `agents`, `agents_software`, `pasture_well_known_agents`, `pasture_agent_categories`. (BLOCKER A2; §11 Scenario 14.)
- [ ] `--epoch-id` values that don't parse as `provenance.TaskID` are rejected at workflow start. (BLOCKER A4; §11 Scenario 13.)

### 10.2 Functional
- [ ] `pasture task <verb>` (existing + new) all route through `protocol.TaskTracker`.
- [ ] An `EpochWorkflow` run produces: PROV-O Activities (per phase boundary), audit events (per sub-event), `context_edges` rows (per event with `EpochContext`), Temporal SAs (R13).
- [ ] Free-floating git/skill/hook events can be recorded with non-epoch `context_kind`.
- [ ] All five concrete automaton categories (ConstraintChecker, TransitionGate, HookHandler, ConsensusReached, CreateFollowup) register at `pastured` startup, idempotent across restarts. (BLOCKER A2; UAT-1; Scenario 14.)
- [ ] Existing `audit.db` files (today's schema) auto-migrate cleanly to v4 without data loss.
- [ ] Newer-schema-than-binary detection returns an actionable `*StructuredError`, not silent corruption.

### 10.3 Tests (BDD coverage in §11)
- [ ] Unit tests for migration v1→v2→v3→v4 (round-trip + idempotency).
- [ ] **Crash mid-migration test (Scenario 11, BLOCKER B1).** Spawn a child `pasture` process (or use a dedicated test-only `pasture-migrate-crash` binary) that aborts after `audit_schema_meta=2` is bumped but **before** the v3 transaction's `Commit()`. On reopen, `SELECT MAX(version) FROM audit_schema_meta` is 2 (not 3, never half) and `PRAGMA integrity_check` returns "ok".
- [ ] **Concurrent-migrator race test (Scenario 12, BLOCKER B2).** Two `os/exec.Cmd` processes (real subprocesses, not goroutines) opening the same v1 db at the same instant. Assert exactly one performs the v2→v3 step (verifiable via row count of `pasture_well_known_agents` post-run AND a unique-distinct-roles count in `audit_events.agent_id`); the second either observes `version=3` and no-ops, or returns the actionable `*StructuredError` from §7.10.3.
- [ ] **File-backed cross-subsystem race test (Scenario 14b / BLOCKER B3).** Replaces PROPOSAL-1's in-memory race test. `tempDir + filepath.Join("race.db")`; spawn N=64 goroutines, each randomly picking from {`audit.Trail.RecordEvent`, `protocol.TaskTracker.AttachContext`, `provenance.Tracker.CreateTask`, `provenance.Tracker.StartActivity`}; >1000 iterations under `go test -race`. Assert: zero un-retried `SQLITE_BUSY` errors, zero `SQLITE_LOCKED`, all `RecordEvent` rows present in `audit_events`, all `CreateTask` rows present in `tasks`, all `StartActivity` rows present in `activities`, all `AttachContext` rows present in `context_edges`. This is the test that proves D11 / C5 (single file, two subsystems = fine).
- [ ] **R10 full coverage (Scenarios 8a–8e, BLOCKER B4 + UAT-1).** Parameterised over the five concrete `AutomatonRole` values (`None` excluded); explicit assertions per category — 8a ConstraintChecker, 8b TransitionGate (×3 gate kinds), 8c HookHandler (×9–12 hook events), 8d ConsensusReached, 8e CreateFollowup.
- [ ] **Fixture-based legacy migration test (Scenario 4, BLOCKER B5).** Checked-in `pasture/testdata/legacy_audit_v1.db` with the row composition specified in §11 Scenario 4.
- [ ] CLI subprocess tests for `pasture task events / timeline / contexts / agents`.
- [ ] Failure-mode tests: SQLite file deleted mid-write returns actionable error; ENOSPC on insert; permission revoked on the DB directory.

---

## 11. BDD acceptance criteria

### Scenario 1: Single .db file with epoch alignment
**Given** a fresh `~/.local/share/pasture/pasture.db`,
**When** the user runs `pasture task create REQUEST "Build X" --type=feature` followed by `pasture-msg epoch start --epoch-id <returned-task-id>` and `pasture-msg phase advance --epoch-id <id> --to-phase elicit`,
**Then** the database contains: a row in `tasks` for the REQUEST (Provenance), a row in `activities` for the phase bracket (Provenance), one or more rows in `audit_events` (audit), and matching rows in `context_edges` with `kind=EpochContext` and `context_id=<task-id-string>`,
**Should not** there be a separate `audit.db` file or any separate Provenance database file.

### Scenario 2: R13 SA dual-write preserved
**Given** the unified `pasture.db` and a running `EpochWorkflow`,
**When** the workflow performs a phase transition,
**Then** `tctl workflow describe <epochID>` shows the `SA_EPOCH_ID`, `SA_PHASE`, `SA_ROLE`, `SA_STATUS`, `SA_DOMAIN`, `SA_LAST_EVENT_TYPE` search attributes upserted byte-identically to today's behaviour (verified by snapshot diff against a captured pre-migration baseline),
**Should not** the SA upsert call be removed, refactored away, or routed through `protocol.TaskTracker` (it stays at the workflow boundary).

### Scenario 3: Provenance library is unmodified
**Given** the implementation is complete,
**When** `git log --oneline ../../../../provenance` is inspected over the implementation epoch's commit range,
**Then** no commits authored as part of this proposal appear in `provenance`,
**Should not** any required behaviour from this proposal depend on a Provenance library change.

### Scenario 4: Auto-migration on open with checked-in fixture (BLOCKER B5)

**Fixture composition** (`pasture/testdata/legacy_audit_v1.db`, hand-curated for diversity):
- Total rows in `audit_events`: 1024.
- Schema: legacy v1 (`epoch_id, phase, role, event_type, payload, timestamp`; no `audit_schema_meta`).
- `role` distribution: `architect` (256), `supervisor` (192), `worker` (192), `reviewer` (192), `automaton-checker` (96), `human-david` (64), `unknown-legacy` (32).
- `phase` distribution: covers all 12 PhaseId values; ~100 rows of NULL `phase` (free-floating events recorded under v1's NULL-permissive shape).
- `payload` JSON edge cases: 64 rows with empty object `{}`; 32 rows with deeply-nested objects (depth 4); 16 rows with embedded UTF-8 (e.g., `{"note": "café"}`); 16 rows with payloads >8 KB; 4 rows with arrays at the top level (`[1,2,3]`, intentionally exercising the JSON unmarshal path).
- `epoch_id` shapes: 768 rows are valid Provenance TaskIDs (`namespace--uuid`); 192 rows are legacy free strings (e.g., `epoch-2026-04-22-mvp`); 64 rows have `epoch_id` matching another row's, exercising the EpochContext de-duplication pass.

**Given** the fixture file has been copied to `t.TempDir() / "legacy.db"` and `pasture` is at the post-S4 binary version,
**When** `protocol.OpenTaskTracker(<tempDir-path>)` is called,
**Then** the migrator runs v1→v2→v3→v4, the file ends up at v4, every original event has an `agent_id` populated, every distinct legacy `role` value has produced exactly **one** row in `agents_software` (idempotency proof), every original event with non-NULL `epoch_id` has a corresponding `context_edges` row with `kind=EpochContext` (1024 - 0 NULLs, since v1 schema has `epoch_id NOT NULL`), `PRAGMA integrity_check` returns "ok", and `SELECT COUNT(*) FROM audit_events` is exactly 1024,
**Should not** any data be lost, any row be duplicated, or the migration partially apply.

### Scenario 5: Newer-schema rejection (BLOCKER A3 — error shape verified)
**Given** a `pasture.db` with `audit_schema_meta(version=99, applied_at=...)` (manually inserted to simulate a future schema),
**When** an older binary that knows up to v4 calls `protocol.OpenTaskTracker(dbPath)`,
**Then** the returned error satisfies `errors.As(err, &se)` with `se` of type `*pasterrors.StructuredError` with field-by-field values:
- `se.Category == pasterrors.CategoryStorage`
- `se.What == "audit database schema version 99 is newer than supported version 4"`
- `se.Why == "this binary was built before the schema was bumped"`
- `se.Impact == "no events can be read or written until the binary is upgraded"`
- `se.Fix` contains the substring `"upgrade pasture to a version that supports schema v99"`,
and `pasterrors.ExitCode(err) == 5`,
**Should not** the binary attempt to downgrade, write to the database, or return a plain `fmt.Errorf` value.

### Scenario 6: Free-floating git event recording
**Given** the unified system with no active `EpochWorkflow`,
**When** a git commit hook fires through `protocol.TaskTracker.RecordEvent({event_type: "GitCommit", payload: {sha: "abc123"}})` followed by `AttachContext(eventID, ContextGit, "abc123")`,
**Then** `pasture task events --context-kind=GitContext --context-id=abc123` returns the recorded event,
**Should not** the event require an `epoch_id` column or fail because no epoch is active.

### Scenario 7: Multi-context attachment
**Given** a workflow running for `epochID=E1` with active slice `S1`,
**When** an event is recorded inside `S1` and attached to both `EpochContext=E1` and `SliceContext=S1` via two `AttachContext` calls,
**Then** `pasture task events --context-kind=EpochContext --context-id=E1` AND `pasture task events --context-kind=SliceContext --context-id=S1` both include the event in their results,
**Should not** the event be findable only via one context (proves the many-to-many).

### Scenario 8: Automaton attribution — full R10 coverage (BLOCKER B4)

Parameterised over the four `AutomatonRole` values. Each sub-scenario fires the relevant agent, asserts the recorded event's `agent_id` resolves (via `pasture_agent_categories` JOIN) to the correct `automaton_role`.

#### 8a — ConstraintChecker
**Given** `pastured` started with the unified DB,
**When** the `CheckConstraints` activity fires during a phase transition and records an event,
**Then** the event's `agent_id` resolves (via `pasture_agent_categories` JOIN) to a SoftwareAgent with `automaton_role=ConstraintChecker` and `pasture_well_known_agents.name = "pasture/automaton/check-constraints"`,
**Should not** the event's attribution be a free-string `role` field or untyped.

#### 8b — TransitionGate (parameterised over 3 gate kinds)
**Given** `pastured` started with the unified DB,
**When** any of the three transition gates fires (`consensus`, `vote-threshold`, `exit-condition`) during a phase transition,
**Then** the event's `agent_id` resolves to a SoftwareAgent with `automaton_role=TransitionGate` whose `pasture_well_known_agents.name` is one of `pasture/automaton/transition-gate/{consensus,vote-threshold,exit-condition}`,
**Should not** the gate fire without an attributed agent.

(One parameterised test case per gate kind; failures point to which gate is unattributed.)

#### 8c — HookHandler (parameterised over 9–12 hook events)
**Given** `pastured` started with the unified DB,
**When** any Claude Code hook event fires (the canonical list at S7 implementation time, drawn from Pasture URD D7: at minimum `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Notification`, `Stop`, `SubagentStop`, `PreCompact`, `SessionEnd` — plus any others in the URD's authoritative list),
**Then** the event's `agent_id` resolves to a SoftwareAgent with `automaton_role=HookHandler` whose `pasture_well_known_agents.name` is `pasture/automaton/hook/<hook-name>`,
**Should not** the hook event be recorded without an attributed agent.

(One parameterised test case per hook event in the canonical list; the test data table is populated from the §7.7.2 enumeration.)

#### 8d — ConsensusReached (UAT-1: first-class category)
**Given** `pastured` started with the unified DB,
**When** the `consensus-reached` rule fires (writing a synthesized event after all reviewers vote ACCEPT during a phase transition),
**Then** the event's `agent_id` resolves (via `pasture_agent_categories` JOIN) to a SoftwareAgent with `automaton_role=ConsensusReached` and `pasture_well_known_agents.name = "pasture/automaton/consensus-reached"`,
**Should not** the event be unattributed or attributed to a generic `Derivation` category (replaced per UAT-1 direction).

#### 8e — CreateFollowup (UAT-1: first-class category)
**Given** `pastured` started with the unified DB,
**When** the `create-followup` rule fires (synthesizing a follow-up epic from PROPOSAL findings during ratification),
**Then** the event's `agent_id` resolves (via `pasture_agent_categories` JOIN) to a SoftwareAgent with `automaton_role=CreateFollowup` and `pasture_well_known_agents.name = "pasture/automaton/create-followup"`,
**Should not** the event be unattributed or attributed to a generic `Derivation` category (replaced per UAT-1 direction).

### Scenario 9: hjsdt CLI continues to work
**Given** the implementation is complete,
**When** the user runs the existing hjsdt-shipped commands: `pasture task create / show / update / close / list / ready / blocked / dep add / dep tree / label add / comment add`,
**Then** all behave identically to today (same output formats, exit codes, error messages),
**Should not** any user-visible change appear in these commands as a side effect of the wrapper introduction.

### Scenario 10: Researcher's notes excluded
**Given** the URD and this proposal,
**When** an agent (human or LLM) attempts to add a `ResearcherNoteContext` value to the `ContextKind` enum or a researcher-note category to the schema,
**Then** the addition is rejected during code review with reference to URE clarification C1,
**Should not** the scope creep silently into the system without a new REQUEST.

### Scenario 11: Crash mid-migration (BLOCKER B1)

**Given** the checked-in fixture `pasture/testdata/legacy_audit_v1.db` copied to `t.TempDir() / "crash.db"`,
**And** a dedicated test-only binary `pasture-migrate-crash` that performs the v2→v3 migration but is wired to `os.Exit(137)` (SIGKILL-equivalent) after the v3 transaction has executed `INSERT INTO audit_schema_meta (version=3, ...)` but **before** `tx.Commit()`,
**When** the test runs `pasture-migrate-crash <crash.db>` via `os/exec.Cmd` and observes the non-zero exit code,
**And** the test then calls `protocol.OpenTaskTracker(<crash.db>)` from the parent test process,
**Then** the migrator either (a) finds `MAX(version) = 2`, runs v3 fresh, and arrives at v4 cleanly (the rolled-back transaction case — expected), with `SELECT COUNT(*) FROM audit_events` equal to the fixture's 1024 (no row loss) and `PRAGMA integrity_check = "ok"`, or (b) finds `MAX(version) = 3` if SQLite happened to flush the WAL just before the kill (acceptable; v3 fully completed),
**Should not** the file be left in a state where `MAX(version) = 3` but the v3 backfill is incomplete (asserted by checking that every `audit_events` row has non-NULL `agent_id`), nor should `pasture_well_known_agents` exist with rows but `audit_schema_meta` say `version=2`.

(The test mechanism choice — child process with controlled abort — is required because Go's defer/panic doesn't simulate OS-level kill; the SQLite transaction guarantees rely on the OS kernel rolling back uncommitted WAL frames.)

### Scenario 12: Concurrent migrator race (BLOCKER B2)

**Given** the checked-in fixture `pasture/testdata/legacy_audit_v1.db` copied to `t.TempDir() / "race.db"`,
**When** two `os/exec.Cmd` processes spawn `pastured --db <race.db> --idle-after-migrate=1s` simultaneously (both blocked on a shared `sync.WaitGroup` to align start times within ~10ms),
**Then** exactly one process performs the v2→v3 migration (verified by checking that `pasture_well_known_agents` contains the expected number of rows from a single migration, not double; and that `agents_software` has one entry per distinct legacy role from §11 Scenario 4's fixture, not two), and the other either:
- Process B's `BEGIN IMMEDIATE` queues behind A's transaction within `busy_timeout=5000ms`, A completes, B re-reads `audit_schema_meta`, observes `version=3`, and no-ops (skip-migration branch executes); OR
- Process B's `BEGIN IMMEDIATE` exceeds the 30s retry ceiling and returns `*StructuredError{Category: CategoryStorage, What: "another pasture process is running the audit schema migration", ...}` with exit code 5, leaving the database in a consistent state for a future open,
**Should not** both processes perform the migration concurrently (verified by assertion: total `agents_software` rows minted with `name LIKE 'pasture/legacy-role/%'` equals exactly the distinct-role count from the fixture, not 2× that count).

**Locking choice rationale.** `BEGIN IMMEDIATE` is preferred over `BEGIN EXCLUSIVE` because (a) WAL mode is already enabled (`sqlite.go:80`) so readers can continue against the pre-migration view; (b) `IMMEDIATE` prevents concurrent writers, which is the only thing that matters for migration correctness. A separate advisory lock file (e.g., `flock` on `<dbPath>.migration-lock`) was considered and rejected: it adds a second on-disk artifact, doesn't survive across machines, and SQLite already provides the serialisation we need.

### Scenario 13: Epoch-ID validation policy (BLOCKER A4)

**Given** a unified `pasture.db` at v4,
**When** the user runs `pasture-msg epoch start --epoch-id "not-a-task-id"` (a free-string ID that does not match the `<namespace>--<uuid>` shape required by `provenance.ParseTaskID`),
**Then** `pasture-msg` exits with code 1 (CategoryValidation) and writes to stderr a `*StructuredError` whose:
- `Category == CategoryValidation`
- `What` contains the substring `"not a valid Provenance TaskID"`
- `Why` contains the underlying `provenance.ParseTaskID` error
- `Fix` contains the substring `"pasture task create REQUEST"`,
**And when** the same malformed ID is sent directly via Temporal client (bypassing CLI validation), the `Activities.RecordTransition` activity returns the same shape of `*StructuredError` and the workflow start fails fast,
**Should not** any row appear in `audit_events`, `context_edges`, or `tasks` for the malformed ID.

### Scenario 14: Two-restart idempotency (BLOCKER A2)

**Given** a fresh `pasture.db` at v4 schema,
**When** `pastured --db <path>` starts, completes the well-known agent registration sequence from §7.7.3, and shuts down,
**And then** `pastured --db <path>` starts again with the same DB path and shuts down,
**Then** the row counts in the following tables are identical between the two startups (after each one completes registration):
- `agents`: equal between starts (well-known agents minted only on first start)
- `agents_software`: equal between starts
- `pasture_well_known_agents`: equal between starts (the lookup-by-`name` step in §7.7.3 short-circuits before any INSERT runs; the UNIQUE constraint on `name` would also reject a duplicate INSERT if the lookup were skipped)
- `pasture_agent_categories`: equal between starts,
**And** the AgentIDs in `pasture_well_known_agents` are pointwise identical across the two startups (same `agent_id` for each `name`),
**Should not** any duplicate `agents_software` row exist for the same `name`, nor should any well-known name appear twice in `pasture_well_known_agents` (the UNIQUE constraint on `name` plus the PRIMARY KEY on `agent_id` together guarantee single-row uniqueness for both columns per UAT-1 schema).

### Scenario 15: Explicit `pasture migrate` command (UAT-1)

**Given** a v1 audit.db with N rows (e.g., the `pasture/testdata/legacy_audit_v1.db` fixture from Scenario 4 copied to `t.TempDir() / "explicit.db"`),
**When** the user runs `pasture migrate --db <path> --dry-run`,
**Then** the planned migrations are printed to stdout (`v1→v2: add audit_schema_meta`, `v2→v3: add new tables, backfill agent_id`, `v3→v4: drop epoch_id, write context_edges`), the file is unchanged on disk (verified by SHA-256 of the file before and after), and exit code is 0;
**And when** the user then runs `pasture migrate --db <path>` (no `--dry-run`),
**Then** the file ends up at v4 with all rows backfilled (same invariants as Scenario 4 — `SELECT MAX(version) FROM audit_schema_meta = 4`, every event has `agent_id`, every legacy `epoch_id` has a `context_edges` row with `kind=EpochContext`, `PRAGMA integrity_check = "ok"`, row counts match the fixture);
**And when** the user runs `pasture migrate --db <path>` a second time on the now-v4 file,
**Then** the migrator detects the file is already at the highest known version and exits 0 with `migrated <db-path> from v4 to v4` (no-op),
**Should not** the auto-on-open path or the explicit-command path produce a different result; both must converge on the same v4 state byte-for-byte (verified by comparing two test files: file A migrated via auto-on-open, file B migrated via `pasture migrate`, both starting from copies of the same fixture, must end with identical content modulo SQLite's WAL ordering).

---

## 12. Out of scope for this proposal

Per URD `aura-plugins-dr2ps` and ELICIT clarifications:

- Binary umbrella unification (`pasture-msg` → `pasture msg ...`). User direction: *"Let's keep pasture-msg as it is for now."* Tracked separately when triggered.
- Migration of skill bodies from `bd` invocations to `pasture task` (Providence URD R9). Documentation work; separate REQUEST.
- Web UI / multi-agent ACP orchestration / marketplace backbone / analytics convergence with `agent-data-leverage`. End-vision items.
- Extending the Provenance library (e.g., adding a `SessionEntry` concept, a public find-or-create for software agents, or any change to satisfy this proposal's idempotency BLOCKERs). Explicitly out of scope per ELICIT C4.
- Researcher's-notes / exploratory-notes recording (ELICIT C1).
- Cross-machine deployment / replicated `pasture.db` / server-mode storage. ADR D2 punts to a future REQUEST.

---

## 13. Beads task references (consolidated)

| Role | Beads task ID | Title |
|---|---|---|
| **Origin (UAT discovery)** | `aura-plugins-hjsdt` (closed) | feat: pasture task CLI commands (imports providence) |
| **hjsdt UAT** | `aura-plugins-dhf6q` (closed, ACCEPT) | UAT: Implementation acceptance for pasture task CLI |
| **REQUEST** | `aura-plugins-j9c88` (in_progress) | REQUEST: Re-think pasture binary umbrella + Temporal/Provenance storage layout |
| **ELICIT (URE rounds 1–3)** | `aura-plugins-pcnhq` (open) | ELICIT: Unified Pasture workflow record + observability spec |
| **URD** | `aura-plugins-dr2ps` (open) | URD: Unified Pasture workflow record + observability |
| **PROPOSAL-1 (superseded)** | `aura-plugins-9z5wg` | PROPOSAL-1: Unified Pasture workflow record + observability |
| **Round 1 review — Axis A (REVISE)** | `aura-plugins-nzlob` | PROPOSAL-1-REVIEW-A-1: Correctness |
| **Round 1 review — Axis B (REVISE)** | `aura-plugins-3rdg4` | PROPOSAL-1-REVIEW-B-1: Test quality |
| **Round 1 review — Axis C (ACCEPT)** | `aura-plugins-zxlby` | PROPOSAL-1-REVIEW-C-1: Elegance |
| **PROPOSAL-2 (this document)** | `aura-plugins-kf87g` | PROPOSAL-2: Unified Pasture workflow record + observability (Round 1 revisions) |
| **Related: ADR draft** | `docs/adr/0001-pasture-toolkit-integration-architecture.md` | ADR mapping the layered architecture |
| **Related: Pasture URD** | `aura-plugins-jbnx3` | URD: Pasture — Go port with ACP, observability, and polyrepo marketplace |
| **Related: Pasture PROPOSAL-2 (ratified)** | `aura-plugins-wab79` | PROPOSAL-2: Pasture Go port |
| **Related: Providence URD** | `aura-plugins-f85gw` (closed) | URD: Port skill bodies + protocol docs to Go (foundation) |
| **Related: Providence PROPOSAL** | `aura-plugins-5k40z` (closed) | PROPOSAL-2: Providence architecture and implementation plan |
| **Related: Providence REQUEST** | `aura-plugins-oviik` (closed) | REQUEST: Providence — PROV-O task tracker (verbatim "replace Beads") |
| **Related: hjsdt followup epic** | `aura-plugins-yeym1` | FOLLOWUP: Non-blocking improvements from pasture task CLI review |

---

## 14. Review axes (Phase 4, Round 2)

This proposal is intended to be reviewed along three axes, with one reviewer per axis. Round 2 reviewers should focus on **whether each Round 1 BLOCKER (§0 revision history) is fully resolved**, in addition to fresh issues.

| Reviewer | Axis | Round 2 focus |
|---|---|---|
| **A — Correctness** | Spirit + technicality | (1) Verify A1: §7.10 v3 migration is fully idempotent + crash-safe + C4-compliant (no Provenance API change required). (2) Verify A2: §7.7 + S7 startup is idempotent across two starts (Scenario 14). (3) Verify A3: §7.10.4 producer error and §11 Scenario 5 assertion match field-for-field. (4) Verify A4: §7.12 epoch-ID validation has a BDD scenario (Scenario 13) and a clear policy. (5) Re-check that R1–R14 and C1–C5 still hold. |
| **B — Test quality** | BDD coverage | (1) Verify Scenario 11 specifies a real crash mechanism (child process). (2) Verify Scenario 12 specifies a real concurrency mechanism (`os/exec.Cmd`). (3) Verify §10.3 race test is file-backed and cross-subsystem. (4) Verify Scenarios 8a–8e cover all five concrete `AutomatonRole` values (UAT-1: ConstraintChecker, TransitionGate, HookHandler, ConsensusReached, CreateFollowup) with explicit agent names. (5) Verify the §11 Scenario 4 fixture composition is concrete enough to commit. (6) Verify Scenarios 13, 14 are well-formed Given/When/Then/Should-not. |
| **C — Elegance** | Complexity-fit | (1) Verify §7.4 uses Go embedding (C1). (2) Verify §7.4 lists `OpenTaskTracker` (C2). (3) Verify §7.4 + §7.6 + S7 + §11 Scenarios 8d/8e reflect the UAT-1 C3 resolution: `AutomatonRoleDerivation` is dropped; `AutomatonRoleConsensusReached` and `AutomatonRoleCreateFollowup` are first-class enum values. (4) Verify §7.4 places the public `TaskTracker` interface and constructor in `pkg/protocol` (UAT-1 placement direction); implementation stays in `internal/tasks`. (5) Verify §7.9 + §7.10 + §11 Scenario 15 reflect the UAT-1 U1 resolution: `pasture migrate [--dry-run]` exists and shares the auto-on-open code path. (6) Re-check that the additions (well-known table, `CategoryStorage`, validation policy, explicit migrate command) do not cross the line into over-engineering. |

---

*End of PROPOSAL-2.*
