---
name: ROADMAP
description: Forward-looking inventory of deferred items, infrastructure gaps, and roadmap work for the unified Pasture workflow record + observability epic.
references:
  source_epic: aura-plugins-cmvu5
  ratified_proposal: aura-plugins-kf87g (docs/proposals/PROPOSAL-2-pasture-workflow-record.md)
  impl_plan: aura-plugins-eauj6 (docs/impl-plans/IMPL_PLAN-PROPOSAL-2-pasture-workflow-record.md)
  urd: aura-plugins-dr2ps
  elicit: aura-plugins-pcnhq
  request: aura-plugins-j9c88
  related_followup_epic: aura-plugins-f59jc (Phase 10 review findings — mostly drained)
---

# ROADMAP — unified Pasture workflow record + observability

This document is the human-readable view of the forward-looking work tracked
by the Beads epic [`aura-plugins-cmvu5`](beads://aura-plugins-cmvu5). The epic
is the source of truth for status and dependencies; this file is the
browsable / diff-able reference for what's outstanding and why.

Two buckets, plus a record of discoveries that came up during execution:

- **§1. Smoke-test infrastructure gaps** — paths the unit/integration suite
  covers via mocks or in-memory backends; surfacing them as production-shape
  smoke tests catches wiring bugs the test suite cannot see.
- **§2. Deferred roadmap items** — explicitly out of scope for PROPOSAL-2 §12
  and the ELICIT C1–C5 bindings; each becomes its own REQUEST when triggered.
- **§3. Discovered-during-E2E UX polish** — small UX items surfaced when
  exercising the toolkit end-to-end.
- **§4. Discoveries during roadmap execution** — bugs and gaps that the
  roadmap work itself surfaced. The Temporal smoke (§1a) already turned up
  one (PROV-O `activities` table never populated); future roadmap work will
  likely surface more.
- **§5. Done so far** — what's finished. The roadmap is small enough that
  listing both inbound and finished work in one doc is more useful than
  splitting them.

Status legend:

| Symbol | Meaning |
|---|---|
| ✅ | Done — landed in a commit; Beads task closed. |
| 🔄 | In progress — Beads task in_progress or actively under review. |
| 🟡 | Open — Beads task open, work not yet started. Triggered when its precondition fires. |
| 🚫 | Blocked — open Beads task with at least one open blocker. |

Each row links to its Beads task. Run `bd show <id> --allow-stale` for full
context.

---

## §0. Design context (what this roadmap is and isn't)

A few load-bearing distinctions the roadmap rests on. These are documented
here so future readers don't re-derive (or worse, misframe) them:

### Why Temporal: observability + introspection

Temporal was selected as the workflow substrate **specifically because it
provides the observability and introspection surface the toolkit needs**.
There is no separate Pasture-side "introspection layer" left to build. The
Temporal stack already gives:

- **Live state** — `pasture-msg query state` queries the running workflow
  via Temporal's workflow-query API.
- **Filterable cross-workflow listing** — six search attributes upserted on
  every workflow (`PastureEpochId`, `PasturePhase`, `PastureRole`,
  `PastureStatus`, `PastureDomain`, `PastureLastEventType`) make any open
  epoch greppable.
- **UI + history replay** — the Temporal UI + `temporal workflow show`
  provide per-workflow timelines and event histories with zero code on our
  side.
- **Durable substrate** — `pasture.db` (`audit_events` + `context_edges`)
  holds the canonical record outside of Temporal's retention window.

The **join key** that makes these layers coherent is the D5/R13 binding from
PROPOSAL-2: `epoch-id = Provenance TaskID = Temporal workflow ID =
audit_events context key`. One string flows through the whole stack without
translation. §7.12's malformed-epoch-id rejection exists precisely to
preserve this alignment — losing it would break the introspection surface.

What's tracked on this roadmap, then, is not the introspection layer itself
(that's done) but **convenience wrappers + missing audits + deferred items
the original PROPOSAL-2 carved out as future scope**.

### Code generation vs runtime context injection

Two distinct concerns the system handles separately:

- **Code generation (build time)**: protocol schema → SKILL.md headers. The
  original is `aura-plugins/scripts/aura_protocol/gen_skills.py` (Python).
  The Go port at `pasture/internal/codegen/skills.go` is live; whether it's
  now authoritative or still subordinate to Python is the
  [`aura-plugins-5wbhm`](beads://aura-plugins-5wbhm) audit.
- **Runtime context injection (session time)**: "load the right phase /
  role context into a Claude session at the current workflow position." This
  is *not* a missing Go layer. The session loads the right `/aura:*` skill;
  Temporal SAs answer "which phase / role are we at"; the SKILL.md author
  decides what context that skill carries. The bridge between "Temporal says
  phase=elicit" and "load the elicit-stage skill" can be implicit (user
  invokes the matching slash command) or explicit (a SessionStart hook —
  tracked as [`aura-plugins-oo359`](beads://aura-plugins-oo359)).

### Pasture vs Beads vs Provenance — the three task trackers

For new contributors: the three names are not synonyms.

- **Beads (`bd`)**: the meta-tracker for the aura-plugins project itself
  (issues, dependencies, sync) — see `aura-plugins/CLAUDE.md`. Used for
  managing the work that builds the toolkit.
- **Provenance**: the embedded PROV-O task-graph library
  (`github.com/dayvidpham/provenance`) — used by `protocol.TaskTracker` to
  store tasks, edges, labels, comments, agents, activities inside
  `pasture.db`. Domain-pure; ELICIT C4 binds us not to modify it.
- **Pasture**: the human-facing toolkit (`pasture` / `pasture-msg` /
  `pastured`) that composes Provenance + the audit subsystem + Temporal
  workflows into a single unified workflow record. This is the system the
  ROADMAP tracks.

Pasture was chosen over extending Beads because Beads's model is
issue-centric (good for project management) while Pasture's model is
workflow-centric (REQUEST → ELICIT → PROPOSAL → … → LANDING, with phase
brackets, audit events, and context edges). The two coexist: Beads tracks
the work of building Pasture; Pasture tracks the work of running aura
workflows. The skill-bodies migration in §2b is what eventually lets the
`/aura:*` skills stop reaching for `bd` directly and use `pasture task`
instead.

---

## §1. Observability + smoke-test infrastructure

| Status | Item | Beads | Notes |
|---|---|---|---|
| ✅ | **1a. Temporal-integrated workflow E2E smoke** | [`aura-plugins-cn5ax`](beads://aura-plugins-cn5ax) | `scripts/smoke/temporal-e2e.sh` + `make smoke-temporal`. Boots `temporal server start-dev` on non-default ports (17233/18233), runs `pastured` against a fresh sqlite db, exercises one phase advance, asserts `tasks` / `audit_events` / `context_edges` / SAs. Surfaced [`aura-plugins-x45ho`](beads://aura-plugins-x45ho) (see §4). Smoke is documented in `pasture/AGENTS.md` under "Smoke tests". |
| 🟡 | **1b. Hook-fired free-floating event recording smoke** | (not yet filed) | A real Claude Code session firing PreToolUse / PostToolUse hooks against the toolkit; assert that `audit_events` accrues `context_kind=GitContext` / `SessionContext` rows. PROPOSAL-2 §11 Scenario 6 covers this in unit tests. |
| 🟡 | **1c. `git-discipline.sh` PreToolUse hook soak verification** | (not yet filed) | Replay the two known destructive-git incidents from this epic (S4 wipe of original; W5 wipe of W3) through the deployed hook; confirm 100% catch rate. Add allowlist exemptions if false-positives surface on normal worker activity. |
| 🟡 | **1d. `pasture-migrate-crash` CI integration audit** | (not yet filed) | Verify that the Scenario-11 crash-recovery binary is actually exercised by `make test-race` in CI; add an explicit CI assertion if not. |
| 🟡 | **1e. Unified "where am I" status command** | [`aura-plugins-punit`](beads://aura-plugins-punit) | Today `pasture-msg query state` (live, via Temporal) + `pasture task events/timeline` (durable, via `pasture.db`) require two CLIs and a mental join on epoch-id. A `pasture status <epoch-id>` consolidation would render one human + JSON view. The pieces are already coherent because of the D5/R13 binding (see §0); this is a UX consolidation, not a missing capability. |
| 🟡 | **1f. Constraint coverage audit — 26 C-* checks** | [`aura-plugins-mh4ek`](beads://aura-plugins-mh4ek) | The Python `aura_protocol/constraints.py` has 26 C-* runtime checks. The Go side has `ActivityCheckConstraints` wired in the workflow, but a coverage table — for each C-*, is it present on the Go side and is it tested — hasn't been produced. Defense-in-depth audit. |
| 🟡 | **1g. Codegen authority audit** | [`aura-plugins-5wbhm`](beads://aura-plugins-5wbhm) | Two SKILL.md generators exist: `aura-plugins/scripts/aura_protocol/gen_skills.py` (Python, original) and `pasture/internal/codegen/skills.go` (Go, port). Document which one is authoritative for live regeneration. If both run, deprecate one. Build-time concern; not user-visible. |

## §2. Deferred roadmap items (PROPOSAL-2 §12)

Each item has explicit user-direction provenance (REQUEST verbatim, ELICIT
clarifications, URD design choices) and becomes its own REQUEST when its
trigger condition fires.

| Status | Item | Trigger | Notes |
|---|---|---|---|
| 🟡 | **2a. Binary umbrella: `pasture-msg` → `pasture msg ...`** | User UX re-think | REQUEST [`aura-plugins-j9c88`](beads://aura-plugins-j9c88) original framing; verbatim direction *"Let's keep pasture-msg as it is for now. We will need to re-think our unification approach."* Not blocked technically; blocked on UX decision. |
| 🟡 | **2b. Skill-bodies migration: bd → `pasture task`** | Providence URD R9 follow-through | All `/aura:*` skill bodies that call `bd create / close / update / etc.` migrate to equivalent `pasture task` invocations once `pasture task` is the canonical local task tracker. Documentation-heavy; orthogonal to the substrate just shipped. |
| 🟡 | **2c. Cross-machine deployment / replicated `pasture.db`** | Multi-host need | ADR 0001 D2 punts this; PROPOSAL-2 §5 acknowledges single-machine SQLite. Future: either replication or a client-server storage swap behind `OpenTaskTracker`. |
| 🟡 | **2d. Provenance library evolution (lift C4)** | New REQUEST + ELICIT to lift C4 | E.g., adding `SessionEntry` natively in Provenance. ELICIT C4 binding (*"Provenance the library is NOT modified"*) prevents this in the current epic. |
| 🟡 | **2e. Researcher's-notes recording (lift C1)** | New REQUEST + user endorsement | A notebook-style audit context kind for free-form exploratory notes. ELICIT C1 binding (*"Researcher's notes / exploratory notes are out of scope"*); was agent-introduced hypothetical not user-endorsed. |
| 🟡 | **2f. Web UI / multi-agent ACP / marketplace / analytics convergence** | Each becomes own epic | End-vision per PROPOSAL-2 §12. The unified workflow record substrate is in place; visualisation/orchestration layers are the remaining surface. |

## §3. Discovered-during-E2E UX polish

Small UX items surfaced during the 2026-04-26 hands-on E2E verification.
Low priority; fold into the next CLI cycle.

| Status | Item | Beads | Notes |
|---|---|---|---|
| 🟡 | **3a. `pasture task events --task-id` alias** | (not yet filed) | Supported filters are `--epoch-id`, `--context-id`, `--context-kind`, `--agent`. Users may reach for `--task-id` from the mental model. Possible fix: add `--task-id` as alias for `--epoch-id` (epoch IDs ARE task IDs per D5), OR clarify the help text. |
| 🟡 | **3b. `pasture task comment add` auto-default-author** | (not yet filed) | Currently requires `--author <wire-format AgentID>` — end-users without a registered agent can't comment. Possible fix: auto-register a "cli-default" agent on first comment-add, OR document the agent-registration step prominently in CLI help. |
| 🟡 | **3c. SessionStart hook — auto-load phase-context from Temporal SAs** | [`aura-plugins-oo359`](beads://aura-plugins-oo359) | When a Claude Code session opens in a worktree associated with an open epoch, read the workflow's `PasturePhase` / `PastureRole` SAs and either *suggest* the matching `/aura:*` skill (safer) or *auto-load* it (more magical). Needs a story for "which epoch is this worktree tied to?" — likely a per-worktree `.pasture/epoch-id` marker, or the aura-swarm one-worktree-per-epoch convention. Lives in the parent `aura-plugins/hooks/` directory, not inside `pasture/`. |

## §4. Discoveries during roadmap execution

Bugs and gaps that the roadmap work itself surfaced. These were not in the
original PROPOSAL-2 §12 / FOLLOWUP-ROADMAP inventory — the roadmap turned
them up. They feed back into the same Beads epic.

| Status | Item | Beads | Notes |
|---|---|---|---|
| 🟡 | **4a. PROV-O `activities` table never populated** | [`aura-plugins-x45ho`](beads://aura-plugins-x45ho) (P2 bug) | Discovered during §1a smoke. Workflow code never calls `Tracker.StartActivity` / `EndActivity` — `activities` rows aren't written despite PROPOSAL-2 §11 Scenario 1 specifying phase-bracket rows there. **The unit tests don't catch this** because they assert what `RecordTransition` does write (rows in `audit_events` + `context_edges`), not what §11 demands. The SUT is genuinely not mocked; the gap is "tests assert impl behavior instead of spec invariants." Acceptance includes extending `activities_integration_test.go` to assert against the `activities` table per phase transition. Smoke currently emits a WARN on this assertion; tighten back to FAIL when fixed. |

## §5. Done so far

| Status | Item | Beads | Landed in |
|---|---|---|---|
| ✅ | **PROPOSAL-2 epic — unified Pasture workflow record + observability** | [`aura-plugins-kf87g`](beads://aura-plugins-kf87g) | Commits `af3b432..4436945` (56+ commits across 11 slices + REVISE wave + Phase 12 + smoke). Pushed to `feat--pasture--initial-golang-port`. |
| ✅ | **Gofmt drift cleanup (~28 files)** | [`aura-plugins-ug7oj`](beads://aura-plugins-ug7oj) | Commit `602dea5`. |
| ✅ | **§1a Temporal E2E smoke** | [`aura-plugins-cn5ax`](beads://aura-plugins-cn5ax) | Commit `4436945`. Smoke surfaced [`aura-plugins-x45ho`](beads://aura-plugins-x45ho) — see §4. |
| ✅ | **FOLLOWUP epic (Phase 10 review findings)** | [`aura-plugins-f59jc`](beads://aura-plugins-f59jc) | All findings drained during the Phase 11 REVISE wave (3 IMPORTANTs + ~10 MINORs elevated; epic stays open by convention as a landing-pad for any late trickle-in). |

---

## How this roadmap evolves

- New items get filed as Beads tasks with `--deps discovered-from:aura-plugins-cmvu5` (transitive ok; via a child like `cn5ax` is fine too).
- Items that turn into real implementation get linked directly under cmvu5 via `bd dep add aura-plugins-cmvu5 --blocked-by <task-id>` so they appear in `bd dep tree`.
- This ROADMAP.md gets updated when an item moves between status buckets (🟡 → 🔄 → ✅) or when a discovery (§4) surfaces. The Beads tasks are the source of truth; this doc is the browsable summary.

## Cross-references

- **Source documents:** [PROPOSAL-2](proposals/PROPOSAL-2-pasture-workflow-record.md) (the ratified spec), [IMPL_PLAN](impl-plans/IMPL_PLAN-PROPOSAL-2-pasture-workflow-record.md) (the implementation plan), [ADR 0001](adr/0001-pasture-toolkit-integration-architecture.md) (the architectural decision record).
- **Live binaries:** `pasture` (local task + audit CLI), `pasture-msg` (Temporal signal CLI), `pastured` (Temporal worker daemon), `pasture-release` (versioning), `pasture-migrate-crash` (test-only).
- **Smoke entry point:** `make smoke-temporal` from `pasture/` inside `nix develop`.
