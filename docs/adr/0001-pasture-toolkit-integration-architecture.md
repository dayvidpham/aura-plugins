# ADR 0001: Pasture Toolkit Integration Architecture

| Field | Value |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-04-25 |
| **Driver** | hjsdt UAT (`aura-plugins-hjsdt`) surfaced that no document describes how the pasture toolkit's binaries, libraries, and storage layers integrate end-to-end. |
| **Supersedes** | None (first ADR for this codebase) |
| **Related** | Pasture URD `aura-plugins-jbnx3`, Providence URD `aura-plugins-f85gw`, Providence REQUEST `aura-plugins-oviik`, hjsdt UAT `aura-plugins-dhf6q`, paused REQUEST `aura-plugins-j9c88`, PROPOSAL-2 URD `aura-plugins-dr2ps`, PROPOSAL-2 ratified `aura-plugins-kf87g`, PROPOSAL-2 IMPL_PLAN `aura-plugins-eauj6` |

---

## Context

The pasture toolkit has accreted four binaries, three libraries, three SQLite stores, and one external service (Temporal) across three Git repositories. Each piece was specified in its own URD, but **no document captures the end-to-end integration story**.

This came to a head during hjsdt's Phase 11 UAT, where the user asked:

> *"What is going on with pasture-msg and pasture? Did we at some point decide to deprecate pasture-msg in a previous epoch? or this epoch?"*

> *"how would we work with the Temporal DB? shouldn't that be the local SQLite?"*

> *"The original idea was for `provenance` to replace Beads in our skills and protocol."*

Reading the URDs reveals that:

1. The new `pasture` binary added in hjsdt is not specified in any URD — it was an implementation-time interpretation of an ambiguous spec (Providence PROPOSAL-2 §8). §8 *was* ratified, but its internal ambiguity (§8.2 invocation form vs §8.5 file-path example) was never surfaced as a disambiguation question.
2. The unification of `pasture-msg` under a `pasture` umbrella has never been written down.
3. Providence URD R9 specified that bd would be replaced by Provenance in skills, but that migration **has not happened**: `pasture/skills/protocol/*.md` still references `bd <verb>` throughout.
4. Pasture URD R7 promised a `TaskTracker` interface in pasture that Provenance would implement. **This interface has not yet been built**; `cmd/pasture/task_*.go` imports `github.com/dayvidpham/provenance` directly. (Not a bypass — an unimplemented requirement.)
5. Bestiary integration into Provenance happened (commits `8cec1fb`, `11022a1`) and is documented in Provenance's project-level docs (`README.md`, `CONCEPTS.md`, `adapter.go`), but not in any aura-plugins-side beads URD.
6. `audit.db` (Pasture URD R10/R11) and `provenance.db` (the Beads-replacement substrate, hjsdt) look superficially similar — both are SQLite, both record what-happened-when — but serve **categorically different roles** that no document had previously distinguished.

Before any further URE / PROPOSAL work can be scoped sensibly, this ADR maps what exists, what was planned, and where the seams are.

---

## The five-layer model

```
Layer 5 — User/agent CLIs       │ pasture (NEW)        pasture-msg        pasture-release
                                │   ▼                     ▼                  ▼
Layer 4 — Daemons / services    │                       pastured ─────► Temporal server (:7233)
                                │   ▼                     ▼                  ─
Layer 3 — Library APIs (Go)     │  provenance.Tracker   pkg/protocol         (no library; CLI only)
                                │   ▼                     ▼                  ─
Layer 2 — Persistence           │  provenance.db        audit.db             (Temporal server's
                                │  (replaces bd:        (R10/R11:            own backend,
                                │   Tasks/Edges/        Temporal-integrated  chosen at
                                │   Labels/Comments,    workflow event log,  server config)
                                │   Agents,             ACP SessionEntry,
                                │   Activities)         SA dual-write)
                                │  ~/.local/share/      ~/.local/share/
                                │  pasture/             pasture/
                                │   ▲                                          ▲
Layer 1 — Static catalogs       │  bestiary  ────────────── used by ─────────┘ (potentially, future)
                                │  (models.dev cache)         provenance for
                                │                             ML agent validation
```

**Two SQLite files, one directory, two roles** — the directory is shared (`~/.local/share/pasture/`) for backup ergonomics; the files are distinct because the underlying records are categorically different (see D2).

### Layer-by-layer ownership

| Layer | Component | Repo | Owns |
|---|---|---|---|
| 5 | `pasture` | aura-plugins / pasture (submodule) | Local Provenance task management CLI (hjsdt). Imports `github.com/dayvidpham/provenance`. |
| 5 | `pasture-msg` | aura-plugins / pasture (submodule) | Temporal client CLI: 8 subcommands (epoch, signal, query, phase, session). Talks to `pastured` via Temporal SDK. |
| 5 | `pasture-release` | aura-plugins / pasture (submodule) | Polyrepo version coordination, marketplace.json sync, semver bump + tag automation. |
| 4 | `pastured` | aura-plugins / pasture (submodule) | Temporal worker daemon. Registers `EpochWorkflow`, `SliceWorkflow`, `ReviewPhaseWorkflow`. Owns the AuditTrail in `audit.db` (R10). |
| 4 | Temporal server | external (`:7233`) | Workflow execution state. Backend chosen at server config (SQLite/MySQL/Postgres/Cassandra). |
| 3 | `provenance.Tracker` | github.com/dayvidpham/provenance | Public Go library: PROV-O entities, edges, labels, comments, agent TPT (Human/ML/Software). Implemented by `sqliteTracker`. |
| 3 | `pkg/protocol` (in pasture) | github.com/dayvidpham/pasture | Convergence types — public protocol types (signals, queries, phases) shared between `pastured`, `pasture-msg`, and any external consumers (e.g., agent-data-leverage). |
| 2 | `provenance.db` | filesystem | Default at `~/.local/share/pasture/provenance.db` (per hjsdt). **The Beads replacement substrate** — human-protocol task tracking (Tasks, Edges, Labels, Comments, Agents). Written by humans/agents via `pasture task ...` CLI. PROV-O entity-and-attribution model. |
| 2 | `audit.db` | filesystem | Defaults to `~/.local/share/pasture/audit.db` in code (URD R10's `~/.local/share/aura/plugin/audit.db` is stale spec text). **Distinct role from `provenance.db`**: Temporal-integrated workflow forensic log. Written by `EpochWorkflow` activities at every phase boundary; carries ACP `SessionEntry` batches; same writes also dual-publish to Temporal search attributes for native `tctl` queryability (R11). High-frequency append, machine-driven, workflow-bound lifecycle. Not a Beads replacement (different shape, different actor). See D2 for why this stays distinct. |
| 2 | Temporal server's own DB | external | Configured at the Temporal server level. Stores *live workflow execution state* — fundamentally different from forensic records. Not selected by any pasture-toolkit binary; never merged into `provenance.db` or `audit.db`. |
| 1 | `bestiary` | github.com/dayvidpham/bestiary | Static catalog of AI model metadata (wraps models.dev). Exposes `ModelID`, `Provider`, `ModelInfo`, `Family`. SQLite cache for offline use. |

### Aura-plugins (the umbrella repo)

Owns the **non-Go side** of the toolkit: skills, protocol docs, plugin marketplace metadata, the Python `aura_protocol` codegen package (deprecated path), and this ADR. Pasture is included as a git submodule.

---

## What exists vs planned vs deferred

### Currently shipped

- **pastured + pasture-msg + pasture-release** (Pasture URD `jbnx3`, ratified PROPOSAL-2 `wab79`).
- **ACP client integration** (locally-defined wire types, Adapter interface with compile-time static registry, two adapters: Claude JSONL, OpenCode JSON).
- **12 Claude Code hook events** with configurable per-handler dispatch timeout.
- **Provenance v0.1.0** (PROV-O tracker, 28-method `Tracker` interface, BCNF schema, agent TPT, integrated with Bestiary for model validation via `RegistryFromBestiary`).
- **`pasture` binary** (hjsdt) — `task create / show / update / close / list / ready / blocked / dep add / dep tree / label add+remove / comment add / comments`.
- **`pkg/protocol`** convergence types in pasture.
- **R10 AuditTrail (SqliteAuditTrail) + R11 Temporal search-attribute dual-write** — fully built, wired, and live: `internal/audit/sqlite.go` (~250 lines) implements `RecordEvent`, `QueryEvents`, `RecordSessionEntries`, schema migration. `cmd/pastured/main.go:82,248` constructs it at daemon startup. `internal/temporal/workflow.go:205,222` invokes `ActivityRecordTransition` and `ActivityRecordAuditEvent` at every EpochWorkflow phase boundary. The same workflow upserts the SA_EPOCH_ID/SA_PHASE/etc. search attributes (workflow.go:23-28); `pastured` registers them at startup (`main.go:170` calling `temporal.EnsureSearchAttributes`). The implementation defaults to `~/.local/share/pasture/audit.db` (env: `PASTURE_AUDIT_DB_PATH`) — **the post-rebrand location**, not the URD R10 spec path of `~/.local/share/aura/plugin/audit.db`. The code already aligned with the `~/.local/share/pasture/` convention; the URD is what's stale, not the implementation. Per D2, `audit.db` stays as the Temporal-integrated workflow forensic substrate, distinct from Provenance's task-tracker role.
- **Bestiary v0.1.0** as a separate repo, used by Provenance.
- **bd (Beads)** still in active use throughout `pasture/skills/protocol/*.md` for protocol-level task tracking.

### Planned per URD but not built

- **TaskTracker interface in pasture** (Pasture URD R7). Status: **not yet implemented**. The pasture-side abstraction was not bypassed in principle — it simply hasn't been built. In practice, Provenance shipped its own `Tracker` interface (28 methods covering CRUD + edges + readiness + labels + comments + agents + activities), and `cmd/pasture/task_*.go` imports it directly. R7's specified surface (CRUD / DepAdd-DepTree-Blocked / labels / CommentsAdd) is fully covered by `provenance.Tracker`, so **the open question is whether pasture should reinstate R7 as a thin adapter over `provenance.Tracker`** (for domain-specific naming, defaulting, or hooks integration), or whether direct import is acceptable. See D3.
- **bd → Provenance migration in skills/protocol** (Providence URD R9). Status: not started. Skills still cite `bd <verb>` invocations.
- **Cross-skill rollout of the Pasture skill bodies** (Providence URD: foundation 7 of 37 skills). Status: foundation done; remaining 30 skills are still on the old aura-protocol Python codegen path.
- **End-vision items**: web UI, multi-agent ACP orchestration, plugin marketplace backbone, **analytics convergence** with agent-data-leverage. All explicitly deferred in URDs.

  *Analytics convergence* (term used in the Pasture URD): the goal of sharing type definitions between `pasture` and the agent-data-leverage repo (`~/dev/agent-data-leverage/develop`, reference-only per the URD) so that events emitted during pasture epoch execution — `SessionUpdate` notifications via the ACP client, phase transitions, vote records, slice progress, audit events — can be consumed directly by agent-data-leverage's analytics pipeline without translation layers. Convergence happens at the Go-type level (`pkg/protocol`, ACP wire types, audit event schemas), not at the storage level. Concretely: agent-data-leverage imports pasture types and processes the same wire formats, rather than each project defining its own.

### Active but undocumented

- **`pasture` binary umbrella structure** (hjsdt) — built but never specified in a URD. The CLI form `pasture task ...` came from Providence PROPOSAL-2 §8.2 (`aura-plugins-5k40z`), which **was ratified by the user** through the standard reviewer + Plan UAT path. However, §8 contained an internal ambiguity — §8.2 documented the user-facing invocation as `pasture task ...` while §8.5's example file path placed handlers under `cmd/pasture-msg/`. **No reviewer surfaced this disambiguation question, and Plan UAT did not call it out**, so the binary-vs-subcommand resolution fell to the implementer at hjsdt time. Net effect: §8 was reviewed and ratified, but the part that mattered (which binary owns the verb) was not explicitly chosen.
- **Storage location convention** (`~/.local/share/pasture/`) — chosen for `provenance.db` in hjsdt and (already, in code) for `audit.db`. The running `pastured` defaults `--audit-db-path` to `~/.local/share/pasture/audit.db`, post-rebrand. URD R10's `~/.local/share/aura/plugin/audit.db` spec text is stale relative to the implementation; the code is correct. The two SQLite files co-locate in `~/.local/share/pasture/` for ops convenience but serve categorically different roles (see D2): `provenance.db` is the human-protocol task tracker (Beads replacement), `audit.db` is the Temporal-integrated workflow event log + R11 search-attribute substrate.
- **Bestiary integration into Provenance** — shipped and **documented in Provenance's project-level docs** (`provenance/README.md`: *"Uses bestiary as its ML model catalog (110+ models from models.dev)"*; `provenance/CONCEPTS.md`: *"MLAgent extends PROV-DM's concept of SoftwareAgent with ML-specific attributes: the agent's Role in the workflow ... and the MLModel it runs (identified by provider + model ID from the bestiary catalog)"*; `provenance/adapter.go`: `RegistryFromBestiary([]bestiary.ModelInfo) ptypes.ModelRegistry`). Not separately recorded in any aura-plugins-side beads URD, but Provenance treats its own `README.md` + `CONCEPTS.md` as its project-level URD-equivalent.

---

## Architectural decisions this ADR records

### D1: Three CLI binaries by concern (current state, intentional)

`pasture-msg` (Temporal control), `pasture` (local Provenance), `pasture-release` (versioning) are kept as separate binaries because they serve fundamentally different concerns and have different runtime requirements:

- `pasture-msg` requires `pastured` and a reachable Temporal server.
- `pasture` requires only a local SQLite file.
- `pasture-release` operates on git/file metadata.

The naming-overlap concern surfaced in hjsdt UAT is real but does not by itself justify the migration cost. **Trigger for revisiting**: a fourth pasture-related CLI appears, or user-facing friction (install-cli sprawl, hooks misrouting) is concretely felt.

### D2: `audit.db` and `provenance.db` are categorically different stores; do not consolidate

> *Note: an earlier draft of this ADR proposed consolidating `audit.db` into `provenance.db` on the grounds that both were "forensic records." That framing was a category error and is withdrawn here. The current decision (below) keeps them distinct.*

`audit.db` and `provenance.db` look superficially similar — both are SQLite, both record what-happened-when, both could be queried for forensic lookup. They are nonetheless **categorically different stores** that should not be conflated:

| | `audit.db` | Provenance task-tracker piece (`provenance.db`) |
|---|---|---|
| **Generated by** | Temporal workflows (machine, automatic, fires at every phase boundary inside `EpochWorkflow`) | Humans and agents (manual, via the `pasture task` CLI or agent decision points) |
| **Data model** | Flat event log: `AuditEvent{EpochID, Phase, Role, EventType, Payload, Timestamp}`; plus ACP `SessionEntry` batches | Entity model: tasks with typed edges, labels, threaded comments, agent attribution |
| **Access pattern** | High-frequency append; indexed scan by `(epoch_id, phase, role)` | Low-frequency CRUD; dep-graph traversal; comment threads |
| **Integrates with** | **Temporal directly** — written from workflow activities; R11 dual-writes to Temporal search attributes for native `tctl` queryability | **The protocol workflow** — REQUEST → URD → PROPOSAL → SLICE → review → UAT lifecycle |
| **Lifecycle** | Tied to a single workflow run; events fire as state changes; entries are immutable post-write | Entities live across the entire epoch; mutable status / comments accumulate over time |
| **Replaces Beads?** | **No.** Wrong shape (event log, not entity model), wrong actor (machine, not human), wrong lifecycle (workflow-bound, not epoch-spanning). | **Yes.** Entity-for-entity correspondence — bd issues become Provenance tasks, bd dependencies become PROV-O `blocked_by` edges, bd labels and comments map directly. |

The Beads replacement is **exclusively** the role of Provenance's task-tracker surface (`Tracker.Create`/`Update`/`Close`/`AddEdge`/`AddLabel`/`AddComment`/etc.). `audit.db` has no Beads-replacement role; it serves a different purpose entirely.

PROV-O can technically model both shapes (Entities for tasks, Activities for events), and a sufficiently motivated implementation could host both in the same `.db` file. **But that doesn't make them the same thing.** The categorical distinction — *who generates the record, what data model fits, what access pattern dominates, what it integrates with* — is load-bearing and should be preserved in our architecture even if the substrate is theoretically unifiable.

**Decision**: `audit.db` stays as `pastured`'s Temporal-integrated forensic substrate. Provenance stays as the human-protocol task tracker (Beads replacement). They live in the same directory (`~/.local/share/pasture/`) for ops convenience, but they are distinct files with distinct schemas, distinct write paths, and distinct purposes.

**Concrete implications**:

| Store | Owner | Role | Lives at |
|---|---|---|---|
| `provenance.db` | `pasture` CLI (and any Go consumer of `provenance.Tracker`) | **Replaces Beads** for human-protocol task tracking. Tasks, typed edges, labels, comments, agent registration. PROV-O entity-and-attribution model. | `~/.local/share/pasture/provenance.db` |
| `audit.db` | `pastured` (via `audit.Trail` interface; R10 + R11) | **Temporal-integrated workflow forensic log.** Records `EpochWorkflow` phase transitions and audit events as they fire; ACP `SessionEntry` batches; dual-writes to Temporal search attributes for native `tctl` queryability. | `~/.local/share/pasture/audit.db` (already correct in code; URD R10's `~/.local/share/aura/plugin/` is the stale spec text) |
| Temporal server's backend | Temporal server process | Live workflow execution state. Backend chosen at server config (SQLite for dev / Postgres or MySQL or Cassandra for prod). | External to pasture. |

**Why this is the right call** (despite PROV-O technically allowing one-store consolidation):

1. **Different actors should write to different substrates.** Mixing high-frequency machine-driven audit appends with low-frequency human task CRUD into one SQLite file invites WAL contention and complicates backup semantics.
2. **The Beads replacement story is cleaner if Provenance is "what replaces Beads, full stop"** rather than "Provenance has a tasks portion that replaces Beads, and also an Activities portion that subsumes audit.db." The mental model and the migration story (skills moving from `bd <verb>` to `pasture task <verb>`) are simpler if Provenance's surface is just the task-tracker.
3. **`audit.db`'s value comes from its Temporal integration**, not from being a generic event store. Keeping it as a Temporal-tied component preserves the integration invariants (R11 dual-write, schema designed around `EpochWorkflow` lifecycle) that would dilute if folded into a general-purpose PROV-O substrate.
4. **R11 is preserved automatically.** Since `audit.db` stays where it is, the workflow-boundary search-attribute dual-write doesn't change. No risk of accidentally regressing the `tctl workflow list --query "SA_EPOCH_ID = ..."` capability.

**What about cross-store references?** PROV-O agents (registered in `provenance.db` via `RegisterHumanAgent` / `RegisterMLAgent` / `RegisterSoftwareAgent`) can be referenced by AgentID string in `audit.db`'s `role` field — agent-keyed audit lookup works across the boundary without forcing schema unification. This is the right level of coupling: shared identifiers, distinct stores.

**Storage location alignment**: the running code already defaults to `~/.local/share/pasture/audit.db`, post-rebrand. No migration needed for the location. URD R10's `~/.local/share/aura/plugin/audit.db` is what's stale, not the implementation.

### D3: R7 (TaskTracker in pasture) is deferred, not dropped — wrapper only if there's a concrete reason

Pasture URD R7 promised a `TaskTracker` Go interface in pasture. **This has not yet been implemented**, but the abstraction is not redundant on principle — only by feature parity. Provenance's `Tracker` (28 methods) covers everything R7 specified:

| R7 surface | `provenance.Tracker` method |
|---|---|
| CRUD (Create, Show, Update, Close) | `Create`, `Show`, `Update`, `CloseTask`, `List` |
| Dependencies (DepAdd-blocked-by, DepTree, Blocked) | `AddEdge(..., EdgeBlockedBy)`, `DepTree`, `Blocked`, `Ready`, `Ancestors`, `Descendants` |
| Labels (LabelAdd, LabelRemove, ListByLabel) | `AddLabel`, `RemoveLabel`, `Labels`, `List(ListFilter{Label: ...})` |
| Comments (CommentsAdd) | `AddComment`, `Comments` |

So R7's *original motivation* (a bd-backed stub to prove an interface, per URE Round 2) is moot — Provenance shipped the real implementation. The remaining question is whether pasture should still introduce a thin adapter over `provenance.Tracker`.

**Reasons to add a pasture-side wrapper later**:
- **Domain-specific naming**: `pastureTracker.AddBlockedBy(parent, child)` reads better than `provenance.AddEdge(parent, child, EdgeBlockedBy)`.
- **Defaulting**: a wrapper can hard-code the namespace from the current git remote so callers never pass it.
- **Cross-cutting concerns**: log every write, emit metrics, fire Claude Code hooks (Pasture URD D7's `slice_started` / `slice_completed` events could hang off task lifecycle).
- **Future swap**: if pasture ever needs to swap Provenance for a remote-API-backed tracker, an adapter limits the blast radius.

**Reasons to skip the wrapper**:
- Today, all of the above are speculative. `cmd/pasture/task_*.go` imports `github.com/dayvidpham/provenance` directly and that works.
- A wrapper that mirrors Provenance's API one-to-one is dead weight.

**Decision**: R7 is deferred. Reinstate a `pasture.TaskTracker` adapter **only when one of the four wrapper-justifying needs becomes concrete** (typically: hooks integration, or cross-cutting metrics for `pastured`'s slice workflows). Until then, direct import of `provenance.Tracker` is sanctioned. This ADR rejects "build the wrapper because the URD said so" without a present-tense reason.

### D4: Bestiary is the canonical AI model catalog

Provenance uses Bestiary's `ModelInfo` registry to validate `(provider, modelName)` pairs at ML agent registration time. This is a direct dependency, intentional, and recorded here.

Future consumers (e.g., a possible `pasture msg`-style ML agent listing CLI) should also use Bestiary as the canonical source.

### D5: The skills' migration from bd to Provenance is a separate work item

Providence URD R9 said skills would migrate from `bd <verb>` to the new tracker. **This has not happened.** The skill bodies in `pasture/skills/protocol/*.md` and `aura-plugins/skills/*/SKILL.md` still cite `bd` invocations.

This ADR does not migrate the skills. It records that:
- bd remains the operational tracker for protocol-level work (REQUEST/URD/PROPOSAL/SLICE etc.) until skills are migrated.
- The skill migration is its own scoped piece of work, separate from j9c88's binary-umbrella concern.
- Provenance is technically ready (`pasture task` CLI works); the migration is a documentation + agent-instruction problem, not a code problem.

---

## Open questions (for follow-up REQUESTs)

These are questions this ADR explicitly does not answer. Each should become its own REQUEST when ready:

1. **Skill migration from bd to Provenance.** Rollout strategy: migrate all skills at once or phase by role (worker → reviewer → architect → supervisor)? How are existing in-flight bd issues handled? Does the migration also rewrite the protocol docs (`pasture/skills/protocol/*.md`) or are those a separate pass?
2. **Cross-store agent reference contract.** Provenance owns AgentIDs (`RegisterHumanAgent`/`RegisterMLAgent`/`RegisterSoftwareAgent`); `audit.db` references agents by AgentID string in its `role` field. This works today because both stores are local. Should there be a documented contract (e.g., a published ID format, a validation step) that audit writes only reference agents that exist in Provenance? Or is the loose coupling intentional? Comes up if the stores ever live on different machines.
3. **Pasture R7 wrapper trigger (per D3).** What concrete need pulls a `pasture.TaskTracker` adapter into existence — Claude Code hooks tied to task lifecycle? Cross-cutting metrics for `pastured`'s slice workflows? Track this so we don't reach for the wrapper preemptively.
4. **Cross-machine deployment.** When (if ever) does the toolkit move beyond single-machine? Trigger conditions (multiple developers, distributed agent fleet, latency-sensitive workflows)?
5. **End-vision execution.** Web UI, multi-agent ACP orchestration, marketplace backbone — each needs its own URD when timing is right.
6. **Bestiary as canonical model catalog beyond Provenance.** Should the toolkit's CLI(s) surface Bestiary data — e.g., `pasture msg models list` to enumerate registered ML agents' valid `(provider, model)` pairs?
7. **The `j9c88` question (binary umbrella).** Per D1, this ADR does not unify at this time. `j9c88` should be reframed as **either** (a) closed as "documented no-op per ADR D1" with the architectural decision recorded here, **or** (b) narrowed to just resolving the `--namespace` flag collision between `pasture` (Provenance namespace) and `pasture-msg` (Temporal namespace) which remains a real ambiguity independent of unification.

---

## Consequences

### Positive

- A single document captures the toolkit's architectural seams. Future agents and contributors can read this ADR before proposing changes.
- The bd → Provenance migration is now a named, scoped piece of work rather than an implicit assumption — and **its boundaries are explicit**: bd is replaced exclusively by Provenance's task-tracker surface (Tasks/Edges/Labels/Comments/Agents). `audit.db` is *not* part of the Beads-replacement story; it serves a categorically different role.
- The "where does this thing live?" questions (binary, library, SQLite store) have explicit answers, including the categorical distinction between human-protocol records (`provenance.db`) and Temporal-integrated workflow records (`audit.db`).
- The hjsdt UAT outcome (ACCEPT for the new `pasture` binary) is now retroactively grounded in D1's rationale.
- j9c88 can be reframed cleanly against this ADR's D1 decision.
- A first-draft consolidation proposal (the previous D2) was caught and walked back during ADR review before any code was written, demonstrating the ADR's review value.

### Negative

- D3 records that R7 (`pasture.TaskTracker`) is deferred indefinitely without a concrete trigger. If no trigger ever materializes, the wrapper never gets built — readers who saw R7 in the original URD may want it built on principle. The ADR rejects "build it because the URD said so".
- D5 explicitly defers the skill migration — meaning the skills will continue to reference `bd` for an unspecified period, which is documentation debt that compounds with each new skill.
- D2 records that `audit.db` and `provenance.db` stay distinct — leaving the toolkit with two SQLite files in `~/.local/share/pasture/`. Some readers may prefer a single-file backup target; D2 argues the categorical distinction outweighs the ops convenience, but it is a real tradeoff.

### Neutral

- This ADR does not change any code. It documents and clarifies. Implementation work follow-ups (skill migration from bd to Provenance, --namespace collision resolution, possible R7 wrapper if a trigger appears) are separate REQUESTs.

---

## Implementation Reference

This ADR was promoted from **Proposed** to **Accepted** on 2026-04-25 as part of
the closing slice (S11) of the PROPOSAL-2 epoch (`pasture-workflow-record`).
That epoch reverses one of this ADR's earlier decisions: D3's "R7 deferred
indefinitely" stance is superseded by PROPOSAL-2 §7.4, which reinstates a
unified `protocol.TaskTracker` façade over `provenance.Tracker` + `audit.Trail`
(now landed as the canonical entry point for task + audit operations across
the toolkit). D2's "two SQLite files" decision is also revised: PROPOSAL-2
§7.1 collapses `provenance.db` and `audit.db` into a single
`~/.local/share/pasture/pasture.db` while preserving the categorical
two-table-separation invariant (D2's original concern) via the BCNF
`context_edges` table. The `audit.db` → `pasture.db` rename and the
`--audit-db-path` deprecation alias are documented in `pasture/AGENTS.md`.

This section records the artifacts that ship the implementation so future
readers can trace the decision through to landed code.

### Authoritative artifacts

| Artifact | Path / ID |
|---|---|
| URD | `aura-plugins-dr2ps` (Unified Pasture workflow record + observability) |
| Ratified PROPOSAL-2 | `aura-plugins-kf87g` → `docs/proposals/PROPOSAL-2-pasture-workflow-record.md` |
| IMPL_PLAN | `aura-plugins-eauj6` → `docs/impl-plans/IMPL_PLAN-PROPOSAL-2-pasture-workflow-record.md` |
| Architect→supervisor handoff | `aura-plugins-79ysg` |

### Slice tasks (Beads)

| Slice | Beads ID | Scope |
|---|---|---|
| S1 | `aura-plugins-7c23z` | Schema-migration foundation (`audit_schema_meta` + v1→v2 + `CategoryStorage`) |
| S2 | `aura-plugins-498x4` | New tables (`context_edges`, `pasture_agent_categories`, `pasture_well_known_agents`) — v2→v3 |
| S3 | `aura-plugins-k5g3o` | AgentID attribution in `audit_events` (v3 backfill + crash binary + legacy fixture) |
| S4 | `aura-plugins-9es12` | EpochContext migration (v3→v4: backfill `context_edges`, drop `epoch_id`) |
| S5 | `aura-plugins-mbkfi` | `protocol.TaskTracker` interface + impl + cross-subsystem race test |
| S6 | `aura-plugins-h4qnq` | New CLI subcommands (`events`/`timeline`/`contexts`/`agents`) + `pasture migrate [--dry-run]` |
| S7 | `aura-plugins-9ye50` | Well-known automaton agent registration at `pastured` startup (15 agents, idempotent) |
| S8 | `aura-plugins-6r63q` | Workflow integration (Activities use TaskTracker + AttachContext) + §7.12 epoch-ID validation |
| S9 | `aura-plugins-qo5ps` | Free-floating event recording (`GitContext`, `SkillContext`, `SessionContext`) |
| S10 | `aura-plugins-de173` | `pasture-msg` + `cmd/pasture` wiring; unify `pasture.db` path |
| S11 | `aura-plugins-0p8kh` | Documentation + ADR finalisation (this ADR's promotion to **Accepted**) |

### Commit range

The implementation lands in commits `af3b432..b6d5dda` on the
`feat--pasture--initial-golang-port` branch (24 commits across S1–S10), plus
the S11 docs commit (`3dbbc46`) that promotes this ADR. Notable:

- `af3b432` — S1 foundation: `CategoryStorage` (exit code 5).
- `ea01432` — S1 framework: `audit_schema_meta` + v1→v2 migration.
- `7bee59e` — S2: v2→v3 schema add (3 new tables).
- `0f2a567`, `1d1a84c`, `1f04054` — S3: v3 backfill + crash binary + Scenarios 4/11.
- `b6d5dda` — S4: v3→v4 EpochContext migration + `epoch_id` column drop.
- `41537ab`, `9bb15c3`, `ff4d703`, `2a064b1` — S5: `protocol.TaskTracker` interface + race test.
- `3f3831f`, `98f733a`, `7bd2097`, `dfb2bac` — S6: new CLI subcommands + `pasture migrate`.
- `c62f855` — S7: well-known agent registration.
- `9af3f9d` — S9: free-floating event recording.
- `79ed742`, `39487b6` — S8: Activities + AttachContext + R13 SA snapshot.
- `750c9a8`, `93d9ca1`, `3072406`, `d1a3511` — S10: unified `pasture.db` path.

### Architect-applied correction (2026-04-25)

PROPOSAL-2 §7.4's original pseudocode embedded `audit.Trail` directly in the
`protocol.TaskTracker` interface, but `internal/audit` already imports
`pkg/protocol` (for `AuditEvent`, `SessionEntry`, `PhaseId`), so a literal
embedding would create an import cycle. The architect applied an in-place §7.4
correction: re-declare the 4 `audit.Trail` method signatures inline in
`pkg/protocol/tasktracker.go`. Any `audit.Trail` implementation satisfies them
automatically because the signatures match exactly; the net public surface
(28 + 4 + 6 + Close + OpenTaskTracker) is unchanged. See the supervisor's
comment trail on `aura-plugins-mbkfi` for the design rationale and the
file-level header comment in `pkg/protocol/tasktracker.go`.

---

## References

- Pasture URD: `aura-plugins-jbnx3` (ratified PROPOSAL-2: `aura-plugins-wab79`)
- Providence URD: `aura-plugins-f85gw` (ratified PROPOSAL: `aura-plugins-ygkp0`)
- Providence REQUEST (verbatim "replace Beads"): `aura-plugins-oviik`
- aurad+aura-msg URD (superseded by Pasture): `aura-plugins-bwfqm`
- hjsdt slice (`pasture` binary built): `aura-plugins-hjsdt`, UAT `aura-plugins-dhf6q`
- Paused REQUEST awaiting this ADR: `aura-plugins-j9c88`
- Followup epic from hjsdt: `aura-plugins-yeym1` (covers `pc82r`, `awe1p`, `m656u`)
- Bestiary repo: `github.com/dayvidpham/bestiary` (`~/codebases/dayvidpham/bestiary`)
- Provenance repo: `github.com/dayvidpham/provenance` (`~/codebases/dayvidpham/provenance`)
- Pasture repo (submodule): `github.com/dayvidpham/pasture` (`~/codebases/dayvidpham/aura-plugins/worktree/aura-protocol/pasture`)
- PROPOSAL-2 URD: `aura-plugins-dr2ps`
- PROPOSAL-2 ratified: `aura-plugins-kf87g` (`docs/proposals/PROPOSAL-2-pasture-workflow-record.md`)
- PROPOSAL-2 IMPL_PLAN: `aura-plugins-eauj6` (`docs/impl-plans/IMPL_PLAN-PROPOSAL-2-pasture-workflow-record.md`)
- PROPOSAL-2 architect→supervisor handoff: `aura-plugins-79ysg`
