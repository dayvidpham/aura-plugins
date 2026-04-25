# PROPOSAL-1: Unified Pasture workflow record + observability

| Field | Value |
|---|---|
| **Status** | Draft (Phase 3 — pending review consensus, then Phase 5 UAT, then Phase 6 ratification) |
| **Date** | 2026-04-25 |
| **Beads task** | (to be created on commit; will be referenced here once filed) |
| **REQUEST** | `aura-plugins-j9c88` |
| **ELICIT** | `aura-plugins-pcnhq` |
| **URD** | `aura-plugins-dr2ps` |
| **Supersedes** | (none — first proposal for this REQUEST) |
| **Origin** | `aura-plugins-hjsdt` UAT (`aura-plugins-dhf6q`) surfaced the unification need; ADR draft at `docs/adr/0001-pasture-toolkit-integration-architecture.md` mapped the architectural seams; URE rounds 1–3 settled the design space. |
| **Related context** | Pasture URD `aura-plugins-jbnx3` (PROPOSAL-2 ratified `aura-plugins-wab79`), Providence URD `aura-plugins-f85gw` (proposal `aura-plugins-ygkp0`), Bestiary integration in Provenance commits `8cec1fb`, `11022a1`. |

---

## 1. Summary

Build a unified Pasture workflow record + observability surface that combines the existing PROV-O task tracker (Provenance) and the existing Temporal-integrated audit subsystem behind a single `pasture.TaskTracker` façade in pasture, backed by a single SQLite file. The Provenance library is **not modified**; integration happens at pasture's wrapper layer. The audit subsystem expands its scope from epoch-and-session events to also cover slices, reviews, follow-ups, hooks, skills, and git events both inside and around workflows. Event–context attachment moves to a normalised `context_edges` table in BCNF.

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
| **C4** | Provenance the library is **not modified** | ELICIT C4 — stated by user twice | All integration is in `pasture/` packages; no PRs to `github.com/dayvidpham/provenance` for this work |
| **C5** | Single SQLite file (not separate audit.db + provenance.db) | ELICIT C5 — verbatim "No, I don't want them in separate .db files" | §7.1 specifies one `.db` file path opened by both subsystems |

---

## 4. URD requirements addressed

| URD Req | Description | Addressed in §… |
|---|---|---|
| R1 | Provenance unmodified | §6 D1, §10.1 validation |
| R2 | `pasture.TaskTracker` is the unified façade | §7.4 interface |
| R3 | Single SQLite file at `~/.local/share/pasture/<filename>.db` | §7.1 — filename: `pasture.db` |
| R4 | Two tables (activities, audit_events) joinable on `agent_id` | §7.2 schema |
| R5 | Epoch ID alignment across subsystems | §6 D5, §7.3 ID-flow diagram |
| R6 | Scope: workflow-internal + adjacent + free-floating | §7.5 `context_kind` enum |
| R7 | Three actor categories with PROV-O attribution | §7.6 actor model |
| R8 | Pasture-side strongly-typed agent categorisation | §7.7 `pasture_agent_categories` table |
| R9 | `context_edges` in BCNF | §7.8 schema |
| R10 | All four automaton categories emit events | §8 implementation slice 7 |
| R11 | CLI under `pasture task <verb>` | §7.9 CLI surface |
| R12 | Auto-migrate audit_events schema on open | §7.10 migration |
| R13 | R11 (Pasture URD) Temporal SA dual-write preserved | §6 D12, §10.1 validation |
| R14 | Low write contention, single file is fine | §6 D11 rationale |

---

## 5. Problem space

### Axes
- **Concurrency**: multiple writers (`pastured` workflow activities, `pasture task` CLI from a human, hook handlers, future skill-runners) into one SQLite file. Per URD R14: low frequency, WAL mode + 5 s `busy_timeout` is sufficient.
- **Lifetime**: live workflow execution events (workflow boundary), human-protocol task entities (epoch-spanning), free-floating events (no lifecycle anchor). All co-resident; differentiated by `context_edges`.
- **Generators**: humans, ML coding agents, conventional software agents, rules-based automata. All registered as Provenance Agents; the latter two share `SoftwareAgent` kind with pasture-side categorisation.
- **Cross-machine readiness**: SQLite is single-machine. Per ADR D2, this is acceptable for now; cross-machine deployment is its own future REQUEST. The unified store does not paint us into a corner — both `provenance.Tracker` and `audit.Trail` retain their interfaces; future server-mode storage can swap behind the same façade.

### Has-a / Is-a
- A workflow run **has-a** PROV-O REQUEST Task (ID = epoch ID = Temporal workflow ID).
- A workflow run **has-many** Activities (one per phase bracket, plus sub-Activities for nested work).
- An Activity **has-many** audit events (point-in-time records inside its time window).
- An audit event **has-many** contexts (via `context_edges`): epoch, slice, review, follow-up, git, skill, session.
- An automaton **is-a** SoftwareAgent (Provenance) **with-a** pasture-side category (constraint_checker | transition_gate | hook_handler | derivation).

### Existing assets to preserve
- `internal/audit/{audit,memory,sqlite,activities}.go` — fully built; `Trail` interface; `SqliteAuditTrail` with WAL + `ensureSchema`.
- `provenance.Tracker` (28-method interface) — handles task CRUD, edges, labels, comments, agents, activities. Bestiary-integrated for ML model validation.
- `pkg/protocol/{types,session_entry}.go` — `AuditEvent`, `EventType`, `SessionEntry`, `PhaseId`, `PhaseRole`.
- `cmd/pasture/task_*.go` (hjsdt, commit `30dcdd6`) — `pasture task` CLI surface; currently imports `provenance` directly. Will be re-routed through `pasture.TaskTracker` per R2.
- `internal/temporal/{workflow,activities,search_attributes}.go` — `EpochWorkflow` writes audit + upserts SAs (R13); preserved unchanged at the workflow boundary.

---

## 6. Engineering tradeoffs (settled by URE)

| ID | Decision | Pros | Cons | Why we picked this |
|---|---|---|---|---|
| **D1** | Provenance the library is **not modified** | Library stays domain-pure; reusable beyond pasture; no churn in a separate repo | Pasture must wrap rather than extend; some duplication in domain naming | URE C4 — stated twice by user. Library domain purity is a non-negotiable. |
| **D2** | `pasture.TaskTracker` (URD R7) is revived as the integration mechanism | One façade for CLI, workflows, and hooks; cross-cutting concerns (logging, hooks, default namespace) live here; future swap-readiness | Adds a layer; some indirection cost | URD R2; ADR D3 had deferred this without trigger — URE supplied the trigger. |
| **D3** | Single SQLite file (`~/.local/share/pasture/pasture.db`) | One backup target; epoch IDs trivially join across tables; matches user mental model | Two subsystems share WAL — small contention in theory | URE C5 — verbatim "No, I don't want them in separate .db files". URE Q3 confirmed write contention is not a real concern. |
| **D4** | Two tables (`activities` + `audit_events`); joinable on `agent_id` | Granularity preserved (phase brackets vs point events); existing schema barely changes; queries express intent clearly | Two tables vs one; query authors must know which to read | URE Round 2 Q1 — user picked "Both, separate" with the additional categorisation table. |
| **D5** | Epoch ID = Provenance REQUEST TaskID = Temporal workflow ID = `audit_events.epoch_id` (carried via `context_edges` after migration) | Single string flows through whole stack; no translation; `tctl` queries align with DB queries | Identifier shape (Provenance's `namespace--uuid`) is longer than today's free-string epoch IDs | URE direct quote: "we need the epoch IDs in both the audit and provenance to align". |
| **D6** | Scope expands beyond epochs to include slices, reviews, follow-ups, hooks, skills, git operations | Captures the whole engineering record; supports retrospectives and cross-epoch analysis | More event types to design; larger event volume (still low per URD R14) | URE Round 1 Q1 — user picked "Workflow + adjacent + free-floating" + verbatim list of in-scope event categories. |
| **D7** | Rule automata = `SoftwareAgent` + pasture-side strongly-typed categories | No Provenance changes; type safety on the pasture side; humans/ML/conventional software stay on existing PROV-O kinds | Categorisation lives in two places (PROV-O kind + pasture category); JOINs needed for full identity | URE Round 2 Q2 + verbatim "strongly-typed categories and sub-tags on our Pasture side. No changes needed to Provenance". |
| **D8** | `context_edges(event_id, context_kind, context_id)` many-to-many; BCNF | One event can attach to multiple contexts (e.g., a git commit tied to an epoch AND a slice); schema fully normalised | Adds a JOIN to most queries vs an inline column | URE Round 3 Q2 + verbatim "should be in Boyce-Codd Normal Form". |
| **D9** | CLI verbs stay under `pasture task <verb>` | Single verb namespace for entity work AND event/timeline queries; matches what hjsdt established | `pasture task` covers more semantics than just task CRUD; subcommand list grows | URE Round 2 Q3. |
| **D10** | Auto-migrate audit_events schema on open via `schema_meta` version table | Backwards-readable; no data loss; matches the bestiary pattern; opaque to callers | Migration code must be tested; schema rollbacks not supported (forward-only) | URE Round 2 Q4. |
| **D11** | Low write frequency = no message-queue interposition | Simplest possible architecture; no extra processes | If write rate ever increases, this assumption needs revisiting | URE Round 3 Q3 + verbatim "Shouldn't be worried about write contention". |
| **D12** | R11 (Pasture URD) Temporal SA dual-write preserved at workflow boundary | Native `tctl` queryability for in-flight epochs; orthogonal to substrate; zero risk during migration | Requires no change — but must be explicitly preserved during refactors | URD R13; ADR D2 cycle 3. |

---

## 7. Public interfaces and schema

### 7.1 Filesystem layout
- Default DB path: `~/.local/share/pasture/pasture.db` (the URD-deferred filename is set here).
- Override: `--db <path>` flag on `pasture` and `pastured`; env `PASTURE_DB_PATH`. (`pastured`'s existing `--audit-db-path` becomes an alias for `--db` after migration; if both are set and disagree, prefer `--db` and emit a deprecation warning per Constraint C-actionable-errors.)
- Both `provenance.OpenSQLite(dbPath)` and `audit.NewSqliteAuditTrail(dbPath)` open the same file.

### 7.2 Schema (post-migration)

Tables owned by **Provenance** (unchanged — this proposal does not touch them):
- `tasks`, `edges`, `labels`, `comments`
- `agents`, `agents_human`, `agents_ml`, `agents_software`, `ml_models`, `providers`
- `activities`
- `schema_meta` (Provenance's own — ignored by audit's migrator)

Tables owned by **`internal/audit`** (this proposal modifies `audit_events`, adds three new tables):

```sql
-- Renamed/reshaped from current; old `epoch_id` and `role` columns drop in favor of agent_id + context_edges.
audit_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id    TEXT NOT NULL,                 -- references provenance.agents.id (string AgentID)
    phase       TEXT,                          -- nullable for free-floating events
    event_type  TEXT NOT NULL,                 -- protocol.EventType wire string
    payload     TEXT NOT NULL,                 -- JSON, schema validated by EventType
    timestamp   INTEGER NOT NULL,              -- Unix nanoseconds UTC
    INDEX idx_audit_events_agent (agent_id),
    INDEX idx_audit_events_timestamp (timestamp)
);

-- Many-to-many context attachment. BCNF: every non-key field is fully dependent on the whole key.
context_edges (
    event_id     INTEGER NOT NULL REFERENCES audit_events(id) ON DELETE CASCADE,
    context_kind TEXT NOT NULL,                -- ContextKind enum wire string
    context_id   TEXT NOT NULL,                -- shape varies per kind: epoch UUID, git SHA, etc.
    PRIMARY KEY (event_id, context_kind, context_id),
    INDEX idx_context_edges_lookup (context_kind, context_id),
    INDEX idx_context_edges_event (event_id)
);

-- Pasture-side typed categorisation for agents (R8).
pasture_agent_categories (
    agent_id        TEXT PRIMARY KEY,          -- references provenance.agents.id
    automaton_role  TEXT NOT NULL DEFAULT 'None',  -- AutomatonRole enum
    pasture_role    TEXT NOT NULL DEFAULT 'None'   -- PastureRole enum
);

-- Schema version tracking (R12) — audit's own; separate from Provenance's.
audit_schema_meta (
    version    INTEGER PRIMARY KEY,
    applied_at INTEGER NOT NULL                -- Unix nanoseconds UTC
);
```

The existing session-entries table (carrying `protocol.SessionEntry` per `RecordSessionEntries`) is preserved unchanged — it doesn't map cleanly into Provenance Activities (per discussion in this thread; SessionEntry is below PROV-O granularity).

### 7.3 Epoch ID alignment

```
Human invokes: pasture task create REQUEST "<title>" --type=feature --phase=request
                       │
                       ▼  pasture.TaskTracker.Create() → provenance.Tracker.Create()
            req := provenance.Task{ID: TaskID{Namespace: "aura-plugins", UUID: <uuidv7>}}
                       │
                       │  epochID := req.ID.String()      ← "aura-plugins--01968a3c-..."
                       ▼
       Human invokes: pasture-msg epoch start --epoch-id <epochID>
                       │
                       ▼  client.ExecuteWorkflow(EpochWorkflow, EpochInput{EpochID: epochID, RequestTaskID: req.ID})
       Temporal workflow ID = epochID

       EpochWorkflow.Run:
                       │
                       ▼  ExecuteActivity(StartActivity, agentID=workflow-agent, phase=request, ...)
                          ↳ provenance.Tracker.StartActivity(...)
                       ▼  ExecuteActivity(RecordAuditEvent, AuditEvent{...})
                          ↳ audit.Trail.RecordEvent(...)  → INSERT INTO audit_events
                          ↳ pasture.TaskTracker.AttachContext(eventID, EpochContext, epochID)
                                                          → INSERT INTO context_edges
                       ▼  workflow.UpsertSearchAttributes(SA_EPOCH_ID: epochID, ...)   ← R13 preserved
```

For free-floating events (no epoch context), the same flow runs but `AttachContext` uses a different `context_kind`:
- A git commit hook fires → records `AuditEvent{event_type: "GitCommit", ...}` with `context_edges(event_id, GitContext, "<sha>")`.
- A skill invocation outside an epoch → `(event_id, SkillContext, "aura:user-elicit-<run-id>")`.
- An adjacent post-epoch commit citing epoch X → two context edges: `(event_id, GitContext, "<sha>")` and `(event_id, EpochContext, "<epochID>")`.

### 7.4 `pasture.TaskTracker` interface (R2)

```go
// Package tasks provides the unified pasture façade over provenance.Tracker
// and audit.Trail. Wraps both subsystems behind a single API surface so
// CLI commands, workflow activities, and hook handlers all use one entry point.
package tasks

import (
    "context"

    "github.com/dayvidpham/provenance"

    "github.com/dayvidpham/pasture/internal/audit"
    "github.com/dayvidpham/pasture/pkg/protocol"
)

// TaskTracker is the unified façade. Implementations wrap a provenance.Tracker
// and an audit.Trail backed by the same SQLite file.
type TaskTracker interface {
    // ─── Task lifecycle (delegates to provenance.Tracker) ────────────────
    Create(ns, title, desc string, t provenance.TaskType, p provenance.Priority, ph provenance.Phase) (provenance.Task, error)
    Show(id provenance.TaskID) (provenance.Task, error)
    Update(id provenance.TaskID, fields provenance.UpdateFields) (provenance.Task, error)
    CloseTask(id provenance.TaskID, reason string) (provenance.Task, error)
    List(filter provenance.ListFilter) ([]provenance.Task, error)

    // ─── Edges, labels, comments (delegates to provenance.Tracker) ───────
    AddEdge(src provenance.TaskID, tgt string, kind provenance.EdgeKind) error
    RemoveEdge(src provenance.TaskID, tgt string, kind provenance.EdgeKind) error
    DepTree(id provenance.TaskID) ([]provenance.Edge, error)
    Ready() ([]provenance.Task, error)
    Blocked() ([]provenance.Task, error)
    AddLabel(id provenance.TaskID, label string) error
    RemoveLabel(id provenance.TaskID, label string) error
    Labels(id provenance.TaskID) ([]string, error)
    AddComment(id provenance.TaskID, author provenance.AgentID, body string) (provenance.Comment, error)
    Comments(id provenance.TaskID) ([]provenance.Comment, error)

    // ─── Agents (delegates to provenance.Tracker) ────────────────────────
    RegisterHumanAgent(ns, name, contact string) (provenance.HumanAgent, error)
    RegisterMLAgent(ns string, role provenance.Role, provider provenance.Provider, model provenance.ModelID) (provenance.MLAgent, error)
    RegisterSoftwareAgent(ns, name, version, source string) (provenance.SoftwareAgent, error)

    // ─── Pasture-side category decoration (R8) ───────────────────────────
    SetAgentCategories(id provenance.AgentID, automaton AutomatonRole, pastureRole PastureRole) error
    AgentCategories(id provenance.AgentID) (AutomatonRole, PastureRole, error)

    // ─── Activity recording (delegates to provenance.Tracker.StartActivity) ─
    StartActivity(agent provenance.AgentID, phase provenance.Phase, stage provenance.Stage, notes string) (provenance.Activity, error)
    EndActivity(id provenance.ActivityID) (provenance.Activity, error)
    Activities(agent *provenance.AgentID) ([]provenance.Activity, error)

    // ─── Audit events (delegates to audit.Trail) ─────────────────────────
    RecordEvent(ctx context.Context, ev protocol.AuditEvent) (eventID int64, err error)
    QueryEvents(ctx context.Context, filter EventFilter) ([]protocol.AuditEvent, error)
    RecordSessionEntries(ctx context.Context, entries []protocol.SessionEntry) error
    QuerySessionEntries(ctx context.Context, sessionID string) ([]protocol.SessionEntry, error)

    // ─── Context attachment (this proposal's new surface) ────────────────
    AttachContext(ctx context.Context, eventID int64, kind ContextKind, contextID string) error
    EventContexts(ctx context.Context, eventID int64) ([]Context, error)
    Timeline(ctx context.Context, kind ContextKind, contextID string) ([]protocol.AuditEvent, error)

    // ─── Lifecycle ───────────────────────────────────────────────────────
    Close() error
}

// AutomatonRole is the strongly-typed pasture-side category for SoftwareAgent
// instances that represent rules-based automata (URD R8).
type AutomatonRole string

const (
    AutomatonRoleNone             AutomatonRole = "None"
    AutomatonRoleConstraintChecker AutomatonRole = "ConstraintChecker"
    AutomatonRoleTransitionGate    AutomatonRole = "TransitionGate"
    AutomatonRoleHookHandler       AutomatonRole = "HookHandler"
    AutomatonRoleDerivation        AutomatonRole = "Derivation"
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

At `pastured` startup, well-known automata are registered exactly once and their AgentIDs cached:

- ConstraintChecker: `(name="check-constraints", source="github.com/dayvidpham/pasture/internal/temporal", category=ConstraintChecker)`
- TransitionGate: one per gate kind (consensus, vote-threshold, exit-condition); `category=TransitionGate`
- HookHandler: 12 SoftwareAgents, one per hook event from URD D7; `category=HookHandler`
- Derivation: stable derivation rules (consensus-reached, auto-followup-creator) get registered; one-off rule fires use the most relevant existing agent.

### 7.7 `pasture_agent_categories` table

See §7.2 schema. Agent registration via `pasture.TaskTracker.RegisterSoftwareAgent` must call `SetAgentCategories(...)` immediately after to populate the row; `AgentCategories(...)` reads the typed pair on demand. SQL JOIN example for full agent identity:

```sql
SELECT a.id, a.kind_id, c.automaton_role, c.pasture_role
FROM agents a
LEFT JOIN pasture_agent_categories c ON c.agent_id = a.id
WHERE a.id = ?
```

### 7.8 `context_edges` design (R9)

BCNF rationale: the only non-trivial functional dependency is `(event_id, context_kind, context_id) → ∅` (the row exists or not). There are no partial or transitive deps because there are no non-key columns. The table is in 6NF, which implies BCNF. This structure trivially supports:

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

Existing subcommands (`create / show / update / close / list / dep / label / comment / ready / blocked`) continue to work unchanged but route through `pasture.TaskTracker` instead of importing `provenance` directly.

### 7.10 Auto-migration (R12)

`audit.NewSqliteAuditTrail(dbPath)` opens the file, reads `audit_schema_meta`. Migration table:

| Version | Migration | Notes |
|---|---|---|
| 1 | (current shape, pre-this-proposal) | `audit_events(epoch_id, phase, role, event_type, payload, timestamp)`; no `context_edges`, `pasture_agent_categories`, or `audit_schema_meta` tables. |
| 2 | Add `audit_schema_meta` and seed `(version=1, applied_at=<now>)`. | One-shot bootstrap; idempotent. |
| 3 | Create `pasture_agent_categories`, `context_edges`. Add `audit_events.agent_id` column (NULLABLE during transition). Backfill: for each row, register a SoftwareAgent for the `role` value if not already registered, and write that AgentID into `agent_id`. Then drop `audit_events.role` (SQLite via table-rebuild pattern). | Forward-only; no rollback. Migration is transactional. |
| 4 | Drop `audit_events.epoch_id` after backfilling rows into `context_edges` with `kind=EpochContext`. | Same forward-only constraint. |

If the migrator detects a schema newer than what the binary supports (`max_known_version < db_version`), it returns an actionable error: `"audit.NewSqliteAuditTrail: database schema version %d is newer than this binary's supported version %d — upgrade pasture or pin to the older binary; do not downgrade silently"`.

### 7.11 Workflow integration (R13 preserved)

The `EpochWorkflow.Run` loop in `internal/temporal/workflow.go` is unchanged in shape:

```go
// Existing:
ExecuteActivity(actCtx, ActivityRecordTransition, epochID, transitionRecord)
ExecuteActivity(actCtx, ActivityRecordAuditEvent, auditEvent)
workflow.UpsertSearchAttributes(saEpochIDKey, saPhaseKey, ...)   // R13 — preserved
```

What changes is what the activities do internally: instead of `audit.Trail.RecordEvent(...)` directly, they call `pasture.TaskTracker.RecordEvent(...) → returns event_id`, then `pasture.TaskTracker.AttachContext(event_id, ContextEpoch, epochID)` to record the epoch correlation in the new `context_edges` table. The `UpsertSearchAttributes` call is byte-identical to today's.

---

## 8. Implementation slices

Each slice is independently buildable and testable. Order is dependency-driven; latter slices assume earlier ones land first.

| Slice | Scope | Exits when | Approx size |
|---|---|---|---|
| **S1: Schema migration foundation** | Add `audit_schema_meta` table + version-detection + migrator scaffold (no migrations yet, just the framework). | `NewSqliteAuditTrail` reads/writes `audit_schema_meta`; a no-op migration (v1→v1) test passes. | ~150 lines + tests |
| **S2: New tables** | `context_edges` + `pasture_agent_categories` schemas; v1→v3 migration writes these into `ensureSchema`. Old rows untouched. | Tables exist; old rows still readable; new rows can be written via raw SQL in tests. | ~200 lines + tests |
| **S3: AgentID attribution in audit_events** | Add `audit_events.agent_id` (nullable). Migration v3 backfills from `role` (registers a SoftwareAgent per distinct role string). Drop `audit_events.role` via SQLite table-rebuild. | New rows write `agent_id`; legacy rows have `agent_id` populated post-migration. | ~250 lines + tests |
| **S4: EpochContext migration** | v3→v4 migration: every existing row with `epoch_id != NULL` gets a `context_edges` entry with `kind=EpochContext`; `audit_events.epoch_id` column dropped. | All historical events queryable via `context_edges JOIN audit_events`; `epoch_id` column gone. | ~150 lines + tests |
| **S5: `pasture.TaskTracker` interface + impl** | New `pasture/internal/tasks/tracker.go` with the `TaskTracker` interface from §7.4. Implementation wraps `provenance.Tracker` + `audit.Trail` (both opened against the same path). Helpers: `OpenTracker(dbPath) (*pastureTracker, error)` mirrors hjsdt's existing helper but routes through the new façade. | All `pasture task <verb>` CLI commands use `pasture.TaskTracker`. Tests mock `provenance.Tracker` and `audit.Trail` separately. | ~400 lines + tests |
| **S6: New CLI subcommands** | Add `pasture task events / timeline / contexts / agents`. Each routes through `pasture.TaskTracker`. | Subprocess CLI tests cover happy + error paths for each new subcommand. | ~300 lines + tests |
| **S7: Automaton agent registration at `pastured` startup** | At daemon startup, register the 4-category automata (constraint checkers, transition gates, 12 hook handlers, derivations) as `SoftwareAgent` + `pasture_agent_categories`. Cache AgentIDs. Wire into the existing `Activities` struct. | `pastured --audit-trail=sqlite` starts up cleanly; restart is idempotent (no duplicate agent registration); registered agents visible via `pasture task agents list`. | ~250 lines + tests |
| **S8: Workflow integration (Activities update + EpochContext attach)** | `Activities.RecordTransition` and `RecordAuditEvent` call `pasture.TaskTracker.RecordEvent` then `AttachContext(.., ContextEpoch, epochID)`. R13 SA upsert preserved unchanged. | Integration test runs an EpochWorkflow start→advance→end and verifies: (a) Activities table has phase brackets, (b) audit_events has events, (c) context_edges has epoch attachments, (d) Temporal SAs are upserted. | ~200 lines + tests |
| **S9: Free-floating event recording** | Hook handlers and skill-invocation entry points (when present) record events with non-epoch contexts (`GitContext`, `SkillContext`, `SessionContext`) via `pasture.TaskTracker.AttachContext`. | A git commit triggered by `pasture-msg` hooks records into audit_events with `context_kind=GitContext`. | ~200 lines + tests |
| **S10: pasture-msg + cmd/pasture wiring** | Update `cmd/pasture` (hjsdt-built binary) to use `pasture.TaskTracker` instead of importing `provenance` directly. `cmd/pastured` opens the unified DB and constructs the wrapper. `pasture-msg` is unchanged for now (per j9c88 deferral of binary umbrella). | Existing hjsdt CLI tests still pass; `pasture` CLI now visibly writes to `pasture.db` instead of separate files (verify via `sqlite3` shell). | ~150 lines + tests |
| **S11: Documentation + ADR finalisation** | Update `pasture/CLAUDE.md` and `pasture/AGENTS.md` to reference `pasture.TaskTracker`. Finalise the ADR (mark `Status: Accepted`); commit. Spec-style docs in `docs/spec/` if needed. | Docs reviewed; ADR committed; URD `aura-plugins-dr2ps` updated with implementation links. | ~docs only |

---

## 9. Public interfaces (consolidated)

All interfaces shown above in §7. For a single-file overview the reviewer can scan, the load-bearing additions are:

- **Go**: `pasture/internal/tasks.TaskTracker` interface (§7.4). 35+ methods; implementation thin (delegates almost everything).
- **Go**: `pasture/internal/tasks.AutomatonRole`, `PastureRole`, `ContextKind` typed enums (§7.4, §7.5).
- **SQL** (`internal/audit/sqlite.go`): three new tables (`context_edges`, `pasture_agent_categories`, `audit_schema_meta`), one column add (`audit_events.agent_id`), one column drop (`audit_events.role`), one column drop (`audit_events.epoch_id`).
- **CLI**: four new `pasture task` subcommands (`events`, `timeline`, `contexts`, `agents`).

---

## 10. Validation checklist

### 10.1 Constraints (must hold for the proposal to be valid)
- [ ] Provenance the library is unmodified — no PRs to `github.com/dayvidpham/provenance` from this work.
- [ ] One SQLite file at `~/.local/share/pasture/pasture.db`; both subsystems open the same file.
- [ ] R13 (Pasture URD R11) Temporal SA dual-write is byte-identical pre/post-implementation.
- [ ] `context_edges` is in BCNF (verified by inspection: composite-key, no non-key columns).
- [ ] No new PROV-O AgentKind introduced.
- [ ] "Researcher's notes" / "exploratory notes" are not in any enum, schema, or CLI surface.

### 10.2 Functional
- [ ] `pasture task <verb>` (existing + new) all route through `pasture.TaskTracker`.
- [ ] An `EpochWorkflow` run produces: PROV-O Activities (per phase boundary), audit events (per sub-event), `context_edges` rows (per event with `EpochContext`), Temporal SAs (R13).
- [ ] Free-floating git/skill/hook events can be recorded with non-epoch `context_kind`.
- [ ] All four automaton categories register at `pastured` startup, idempotent across restarts.
- [ ] Existing `audit.db` files (today's schema) auto-migrate cleanly to v4 without data loss.
- [ ] Newer-schema-than-binary detection returns an actionable error, not silent corruption.

### 10.3 Tests (BDD coverage in §11)
- [ ] Unit tests for migration v1→v2→v3→v4 (round-trip + idempotency).
- [ ] Integration tests for the full workflow → audit → context_edges → SA path.
- [ ] CLI subprocess tests for `pasture task events / timeline / contexts / agents`.
- [ ] Concurrency test: 10 goroutines each calling `RecordEvent` + `AttachContext` against an in-memory DB; no data races (`-race` flag).
- [ ] Failure-mode test: SQLite file deleted mid-write returns actionable error.

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
**Then** `tctl workflow describe <epochID>` shows the `SA_EPOCH_ID`, `SA_PHASE`, `SA_ROLE`, `SA_STATUS`, `SA_DOMAIN`, `SA_LAST_EVENT_TYPE` search attributes upserted byte-identically to today's behaviour,
**Should not** the SA upsert call be removed, refactored away, or routed through `pasture.TaskTracker` (it stays at the workflow boundary).

### Scenario 3: Provenance library is unmodified
**Given** the implementation is complete,
**When** `git log --oneline ../../../../provenance` is inspected,
**Then** no commits authored as part of this proposal appear in `provenance`,
**Should not** any required behaviour from this proposal depend on a Provenance library change.

### Scenario 4: Auto-migration on open
**Given** a `pasture.db` (or legacy `audit.db`) at schema v1 with 1000 existing audit_events rows,
**When** a new `pastured` binary opens the file,
**Then** the migrator runs v1→v2→v3→v4, the file ends up at v4, every original event has a corresponding `context_edges` row with `kind=EpochContext`, and `agent_id` is populated for every row,
**Should not** any data be lost, any row be duplicated, or the migration partially apply on a crash mid-flight (transactional guarantee).

### Scenario 5: Newer-schema rejection
**Given** a `pasture.db` at schema v5 (future version),
**When** an older binary that knows up to v4 opens the file,
**Then** `NewSqliteAuditTrail` returns `*StructuredError{Category: CategoryStorage, What: "schema version 5 is newer than supported version 4", Why: ..., Fix: "upgrade pasture or pin to the older binary"}`,
**Should not** the binary attempt to downgrade or write to the database.

### Scenario 6: Free-floating git event recording
**Given** the unified system with no active `EpochWorkflow`,
**When** a git commit hook fires through `pasture.TaskTracker.RecordEvent({event_type: "GitCommit", payload: {sha: "abc123"}})` followed by `AttachContext(eventID, ContextGit, "abc123")`,
**Then** `pasture task events --context-kind=GitContext --context-id=abc123` returns the recorded event,
**Should not** the event require an `epoch_id` column or fail because no epoch is active.

### Scenario 7: Multi-context attachment
**Given** a workflow running for `epochID=E1` with active slice `S1`,
**When** an event is recorded inside `S1` and attached to both `EpochContext=E1` and `SliceContext=S1` via two `AttachContext` calls,
**Then** `pasture task events --context-kind=EpochContext --context-id=E1` AND `pasture task events --context-kind=SliceContext --context-id=S1` both include the event in their results,
**Should not** the event be findable only via one context (proves the many-to-many).

### Scenario 8: Automaton attribution
**Given** `pastured` started with the unified DB,
**When** the `CheckConstraints` activity fires during a phase transition and records an event,
**Then** the event's `agent_id` resolves (via `pasture_agent_categories` JOIN) to a SoftwareAgent with `automaton_role=ConstraintChecker`,
**Should not** the event's attribution be a free-string `role` field or untyped.

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

---

## 12. Out of scope for this proposal

Per URD `aura-plugins-dr2ps` and ELICIT clarifications:

- Binary umbrella unification (`pasture-msg` → `pasture msg ...`). User direction: *"Let's keep pasture-msg as it is for now."* Tracked separately when triggered.
- Migration of skill bodies from `bd` invocations to `pasture task` (Providence URD R9). Documentation work; separate REQUEST.
- Web UI / multi-agent ACP orchestration / marketplace backbone / analytics convergence with `agent-data-leverage`. End-vision items.
- Extending the Provenance library (e.g., adding a `SessionEntry` concept). Explicitly out of scope per ELICIT C4.
- Researcher's-notes / exploratory-notes recording (ELICIT C1).
- Cross-machine deployment / replicated `pasture.db` / server-mode storage. ADR D2 punts to a future REQUEST.

---

## 13. Beads task references (consolidated)

| Role | Beads task ID | Title |
|---|---|---|
| **Origin (UAT discovery)** | `aura-plugins-hjsdt` (closed) | feat: pasture task CLI commands (imports providence) |
| **hjsdt UAT** | `aura-plugins-dhf6q` (closed, ACCEPT) | UAT: Implementation acceptance for pasture task CLI |
| **REQUEST** | `aura-plugins-j9c88` (in_progress) | REQUEST: Re-think pasture binary umbrella + Temporal/Provenance storage layout (scope expanded post-ADR review) |
| **ELICIT (URE rounds 1–3)** | `aura-plugins-pcnhq` (open) | ELICIT: Unified Pasture workflow record + observability spec |
| **URD** | `aura-plugins-dr2ps` (open) | URD: Unified Pasture workflow record + observability |
| **PROPOSAL-1 (this document)** | (TBD on commit) | PROPOSAL-1: Unified Pasture workflow record + observability |
| **Related: ADR draft** | `docs/adr/0001-pasture-toolkit-integration-architecture.md` (uncommitted) | ADR mapping the layered architecture |
| **Related: Pasture URD** | `aura-plugins-jbnx3` | URD: Pasture — Go port with ACP, observability, and polyrepo marketplace |
| **Related: Pasture PROPOSAL-2 (ratified)** | `aura-plugins-wab79` | PROPOSAL-2: Pasture Go port |
| **Related: Providence URD** | `aura-plugins-f85gw` (closed) | URD: Port skill bodies + protocol docs to Go (foundation) |
| **Related: Providence PROPOSAL** | `aura-plugins-5k40z` (closed) | PROPOSAL-2: Providence architecture and implementation plan |
| **Related: Providence REQUEST** | `aura-plugins-oviik` (closed) | REQUEST: Providence — PROV-O task tracker (verbatim "replace Beads") |
| **Related: hjsdt followup epic** | `aura-plugins-yeym1` | FOLLOWUP: Non-blocking improvements from pasture task CLI review |

---

## 14. Review axes (Phase 4)

This proposal is intended to be reviewed along three axes, with one reviewer per axis:

| Reviewer | Axis | Look for |
|---|---|---|
| **A — Correctness** | Spirit + technicality | Does the design faithfully serve URD requirements R1–R14? Are any URE clarifications C1–C5 quietly violated by the schema or CLI? Are migration semantics complete? Does R13 (SA dual-write) survive every change unchanged? |
| **B — Test quality** | BDD coverage | Are the 10 BDD scenarios in §11 sufficient? Is the migration tested forward and idempotently? Is `-race` runnable on the integration tests? Are failure modes explicit? |
| **C — Elegance** | Complexity-fit | Is the `pasture.TaskTracker` interface (§7.4) the right size? Are the 11 implementation slices the right granularity? Is `context_edges` BCNF defensible? Is anything over- or under-engineered (premature abstractions vs missing seams)? |

---

*End of PROPOSAL-1.*
