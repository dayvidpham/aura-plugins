---
name: ROADMAP
description: Forward-looking inventory of deferred items, infrastructure gaps, and roadmap work for the unified Pasture workflow record + observability epic. Cross-references the parent Pasture URD (jbnx3) and the FOLLOWUP-ROADMAP epic (cmvu5).
references:
  parent_urd: aura-plugins-jbnx3
  source_epic: aura-plugins-cmvu5
  closure_triage: aura-plugins-ow0pq
  ratified_proposal: aura-plugins-kf87g (docs/proposals/PROPOSAL-2-pasture-workflow-record.md)
  impl_plan: aura-plugins-eauj6 (docs/impl-plans/IMPL_PLAN-PROPOSAL-2-pasture-workflow-record.md)
  audit_proposal: aura-plugins-ircvi (docs/proposals/ROADMAP-COMPLETENESS-AUDIT.md)
  audit_request: aura-plugins-t3498
  python_migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
  related_followup_epic: aura-plugins-f59jc (Phase 10 review findings — drained)
---

# ROADMAP — unified Pasture workflow record + observability

This document is the human-readable view of the forward-looking work tracked
by the Beads epic [`aura-plugins-cmvu5`](beads://aura-plugins-cmvu5), with
cross-references to the parent Pasture URD
[`aura-plugins-jbnx3`](beads://aura-plugins-jbnx3) and its closure triage
gate [`aura-plugins-ow0pq`](beads://aura-plugins-ow0pq). The Beads task
graph is the source of truth for status and dependencies; this file is the
browsable / diff-able reference for what's outstanding and why.

> **Status (2026-06-06): `jbnx3` CLOSED — the Go port is delivered as scoped; the audit closure cascade is complete.**
> All 8 `ow0pq` blockers resolved (`3iz51` / `fzctk` / `h2zd9` / `qzr8a` / `bch` + `rk2su` / `x5071` / `6l5yo`); the R1–R7 re-walk is recorded on `ow0pq`; `ow0pq` and the parent URD `jbnx3` are closed. **R1/R2/R3/R5/R6/R7 DONE**; **R4 (ACP)** core delivered with live-bidirectional externally blocked on Claude Code native ACP (residuals tracked: `pasture#1`/`#2`/`n856x`).
> **Forward scope now lives in its own threads — NOT `jbnx3`:** durable-execution substrate Temporal→DBOS ([`pasture#13`](https://github.com/dayvidpham/pasture/issues/13) / `onhv2`), provenance integration ([`pasture#14`](https://github.com/dayvidpham/pasture/issues/14) / `9wdwc`), modular workflow compiler ([`pasture#15`](https://github.com/dayvidpham/pasture/issues/15)), multi-vendor extensibility (`kv0od`), and the `6l5yo` git_recorder graduation (§2g — **DELIVERED** at pasture `04ec6ad`, local-unpushed; 3 deferrals → FOLLOWUP epic `sibkn`).

Sections:

- **§0. Design context** — load-bearing distinctions and framings.
- **§1. Observability + smoke-test infrastructure** — paths the
  unit/integration suite covers via mocks or in-memory backends; surfacing
  them as production-shape smoke tests catches wiring bugs the test suite
  cannot see.
- **§1.5. Sibling epics blocking `jbnx3` closure** — the dep cascade that
  must drain before the parent URD can close.
- **§2. Deferred roadmap items** — explicitly out of scope for PROPOSAL-2
  §12 and the ELICIT C1–C5 bindings, plus URD-derived residuals; each
  becomes its own REQUEST when triggered.
- **§3. Discovered-during-E2E UX polish** — small UX items surfaced when
  exercising the toolkit end-to-end.
- **§4. Discoveries during roadmap execution** — bugs and gaps that the
  roadmap work itself surfaced. The Temporal smoke (§1a) and the
  ROADMAP-COMPLETENESS-AUDIT both fed this section.
- **§5. Done so far** — what's finished.

Status legend:

| Symbol | Meaning |
|---|---|
| ✅ | Done — landed in a commit; Beads task closed. |
| 🔄 | In progress — Beads task in_progress or actively under review. |
| 🟡 | Open — Beads task open, work not yet started. |
| 🚫 | Blocked — open Beads task with at least one open blocker. |

Each row links to its Beads task. Run `bd show <id> --allow-stale` for full
context.

---

## §0. Design context (what this roadmap is and isn't)

A few load-bearing distinctions the roadmap rests on. These are documented
here so future readers don't re-derive (or worse, misframe) them.

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
the original PROPOSAL-2 carved out as future scope**, plus URD-derived
residuals.

### Code generation vs runtime context injection

Two distinct concerns the system handles separately:

- **Code generation (build time)**: protocol schema → SKILL.md headers + the
  `agents/*.md` definition files. The original is
  `aura-plugins/scripts/aura_protocol/gen_skills.py` (Python). The Go port at
  `pasture/internal/codegen/skills.go` is live and is the going-forward
  canonical source (Python is deprecated; see below). Codegen authority
  documentation is tracked at
  [`aura-plugins-5wbhm`](beads://aura-plugins-5wbhm). The figure pipeline
  (ASCII diagrams embedded in SKILL.md headers) is part of (a) build-time
  codegen, NOT (b) runtime context injection — see §5.
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

### Python `aura_protocol` is deprecated; Go (Pasture) is canonical

As of 2026-05-20, the Python prototype at `aura-plugins/scripts/aura_protocol/`
is **deprecated**. The Go port (Pasture) has absorbed every substrate concern
and is the only implementation that runs in any deployment. The two
implementations are intentionally forked at the Temporal search-attribute
wire-name level (Python keeps `Aura*`; Go uses `Pasture*` per
[`aura-plugins-fb658`](beads://aura-plugins-fb658)) — see
[`scripts/aura_protocol/DEPRECATED.md`](../../scripts/aura_protocol/DEPRECATED.md)
in the parent repo and
[`docs/PYTHON_TO_GO_MIGRATION.md`](PYTHON_TO_GO_MIGRATION.md) for the
inventory of what's ported, what's drifted, and the reconciliation policy.

### Version mapping (v1 → v2 → v3 → v4)

Per user direction during the 2026-05-24 URE on the ROADMAP completeness
audit. Some upstream docs (`aura-plugins/CLAUDE.md`,
`docs/architecture.md`, `docs/aurad.md`, `docs/aura-msg.md`) still use the
older framing where v3 was labeled "future" — these are pending update
under [`aura-plugins-64mld`](beads://aura-plugins-64mld).

| Version | Scope | Status |
|---|---|---|
| **v1** | Python prototype: state machine + Temporal workflow + 26 C-* constraint validators | ✅ Shipped (frozen) |
| **v2** | Schema-driven codegen + runtime context injection; Python as source of truth | ✅ Shipped (frozen) |
| **v3** | Temporal Python engine | ⏹ **MVP built, then abandoned** in favor of v4 |
| **v4** | Golang + Temporal port (Pasture) — current canonical implementation | ✅ Shipped via PROPOSAL-2 |

### Supervisor reconciliation framing (per URE Q8)

`PYTHON_TO_GO_MIGRATION.md` flagged the supervisor and worker SKILL.md as
having substantial drifts (212 + 122 lines) between the parent
(`aura-plugins/skills/`) and Pasture (`pasture/skills/`) homes. During the
2026-05-24 audit it became clear that **the Go port absorbed the parent's
hand-authored body content into Go literal structs** (`specs_data_body.go::supervisorBody`
at line 24+, `workerBody` at line 1375+). Pasture's SKILL.md files are now
fully generated; parent's are partially hand-authored.

**The reconciliation framing is NOT "Go side wins by default"** but **"audit
each previously-hand-written fragment to verify the Go codegen captured it
accurately"** (user verbatim, 2026-05-24 URE Q8). The per-fragment fidelity
audit is tracked as
[`aura-plugins-fzctk`](beads://aura-plugins-fzctk).

### `jbnx3` closure cascade

`jbnx3` (P1, the Pasture parent URD opened 2026-03-10) is conceptually the
umbrella for the entire Go port. PROPOSAL-2 was ONE slice of it (the
unified workflow record + observability substrate); other slices have their
own epics (`bch` for R3 pasture-release; `6ujr` + `rk2su` for R4 ACP; etc.).
Because we don't know what's actually left on `jbnx3` until the visibility
audits land, the dep graph is now structured so:

```
jbnx3 (URD, P1, BLOCKED)
  └── ow0pq closure triage (P2) — re-walk R1–R7 once blockers land
        ├── 5 cmvu5 visibility audits (fzctk, qzr8a, h2zd9, 3iz51, 6l5yo)
        └── 4 peer epics implementing R-rows (bch, 6ujr, rk2su, x5071)
```

See [§1.5](#§15-sibling-epics-blocking-jbnx3-closure) for the full table
and current state. `cmvu5` is left as a peer of `jbnx3` (not a child) —
the audit work it tracks isn't *implementing* `jbnx3` so much as *making
the closure decision possible*.

---

## §1. Observability + smoke-test infrastructure

| Status | Item | Beads | Notes |
|---|---|---|---|
| ✅ | **1a. Temporal-integrated workflow E2E smoke** | [`aura-plugins-cn5ax`](beads://aura-plugins-cn5ax) | `scripts/smoke/temporal-e2e.sh` + `make smoke-temporal`. Boots `temporal server start-dev` on non-default ports (17233/18233), runs `pastured` against a fresh sqlite db, exercises one phase advance, asserts `tasks` / `audit_events` / `context_edges` / SAs. Surfaced [`aura-plugins-x45ho`](beads://aura-plugins-x45ho) (see §4). Smoke documented in `pasture/AGENTS.md` under "Smoke tests". |
| 🟡 | **1b. Hook-fired free-floating event recording smoke** | (not yet filed) | A real Claude Code session firing PreToolUse / PostToolUse hooks; assert that `audit_events` accrues `context_kind=GitContext` / `SessionContext` rows. PROPOSAL-2 §11 Scenario 6 covers this in unit tests. **Coupled to §2g** — the smoke needs the stub hook handler graduated. |
| 🟡 | **1c. `git-discipline.sh` PreToolUse hook soak verification** | (not yet filed) | Replay the two known destructive-git incidents (S4 wipe of original; W5 wipe of W3) through the deployed hook; confirm 100% catch rate. Add allowlist exemptions if false-positives surface on normal worker activity. |
| 🟡 | **1d. `pasture-migrate-crash` CI integration audit** | (not yet filed) | Verify the Scenario-11 crash-recovery binary is exercised by `make test-race` in CI; add explicit assertion if not. |
| 🟡 | **1e. Unified "where am I" status command** | [`aura-plugins-punit`](beads://aura-plugins-punit) | Today `pasture-msg query state` (live, via Temporal) + `pasture task events/timeline` (durable, via `pasture.db`) require two CLIs and a mental join on epoch-id. A `pasture status <epoch-id>` consolidation would render one human + JSON view. The pieces are already coherent because of the D5/R13 binding (see §0); this is a UX consolidation, not a missing capability. |
| 🟡 | **1f. Constraint coverage audit — 26 C-* checks** | [`aura-plugins-mh4ek`](beads://aura-plugins-mh4ek) | The Python `aura_protocol/constraints.py` has 26 C-* runtime checks. Verify each is ported to Go and tested. Defense-in-depth audit; post-deprecation parity confirmation. |
| 🟡 | **1g. Codegen authority audit** | [`aura-plugins-5wbhm`](beads://aura-plugins-5wbhm) | Document that `pasture/internal/codegen/skills.go` is authoritative; verify the Python `gen_skills.py` is fully superseded. Inventories remaining drift between the parent and Pasture skill homes. |
| 🟡 | **1h. Banner Python-era docs with deprecation redirect** | (not yet filed; covered by [`aura-plugins-64mld`](beads://aura-plugins-64mld)) | Add a top-of-file deprecation banner pointing readers at `PYTHON_TO_GO_MIGRATION.md` to: `docs/architecture.md`, `docs/aurad.md`, `docs/aura-msg.md`. Their "Roadmap" sections describe pre-deprecation Python work that is now stale. `64mld` also folds in the v1/v2/v3/v4 reframing. |
| 🟡 | **1i. Skill-drift CI check** | (not yet filed) | Add a CI check that flags any drift between `aura-plugins/skills/<skill>/SKILL.md` and `pasture/skills/<skill>/SKILL.md` for the 8 overlapping skills. Migration doc named this; never filed. |
| 🟡 | **1j. Supervisor + worker SKILL.md per-fragment fidelity audit** | [`aura-plugins-fzctk`](beads://aura-plugins-fzctk) | Per URE Q8: walk through parent SKILL.md L341–869 (supervisor) + L253–568 (worker), fragment by fragment, and verify the Go codegen literal (`specs_data_body.go::supervisorBody` L24+, `workerBody` L1375+) captured each piece accurately. **Blocks `jbnx3` closure** — informs whether R1 "Port aurad" is genuinely complete at the codegen-fidelity layer. |

## §1.5. Sibling epics blocking `jbnx3` closure — ✅ RESOLVED (2026-06-06)

**All 8 prerequisites landed; `ow0pq` re-walked R1–R7 and `jbnx3` is CLOSED.** This section is retained for the audit trail; the table below records the final state. `6ujr` was descoped 2026-05-30 (see below).

| Status | Type | Task | Why it blocked `jbnx3` closure |
|---|---|---|---|
| ✅ | gate | [`aura-plugins-ow0pq`](beads://aura-plugins-ow0pq) | The single direct blocker on `jbnx3`. Re-walked R1–R7 once the 8 below landed; **CLOSED** (jbnx3 closed with residuals filed). |
| 🟡 | audit | [`aura-plugins-fzctk`](beads://aura-plugins-fzctk) (§1j) | Per-fragment supervisor/worker fidelity audit — informs R1 codegen-fidelity completeness. |
| 🟡 | audit | [`aura-plugins-qzr8a`](beads://aura-plugins-qzr8a) (§2i) | 19 stale items individual triage — `bwfqm` ("aurad+aura-msg URD") and `q72mt` ("rework supervisor URD") may carry residual asks against R1/R2. |
| 🟡 | audit | [`aura-plugins-h2zd9`](beads://aura-plugins-h2zd9) (§2k) | IS jbnx3 R5 directly — specify cross-module consumption story for `pkg/protocol`. |
| 🟡 | audit | [`aura-plugins-3iz51`](beads://aura-plugins-3iz51) (§4c) | Individually place 8 sibling epics into §5/§2/§0; resolves whether `x5071`/`6ujr`/`rk2su`/`9wdwc` are done or in-flight. |
| 🟡 | audit | [`aura-plugins-6l5yo`](beads://aura-plugins-6l5yo) (§2g) | Graduate `git_recorder.go` from stub — R1/R4-adjacent hook wiring. |
| 🚫 | epic | [`aura-plugins-bch`](beads://aura-plugins-bch) | **R3** — IMPL_PLAN for `bin/pasture-release`; binary builds but feature work open. |
| 🟡 | epic | [`aura-plugins-rk2su`](beads://aura-plugins-rk2su) | **R4** — FOLLOWUP: ACP wiring non-blocking improvements. |
| 🟡 | epic | [`aura-plugins-x5071`](beads://aura-plugins-x5071) | **R5-adjacent** — Port remaining 30 Python skills to Go (the policy filed for the Python-only skills inventory). |

Items in `cmvu5` that **don't** block `jbnx3` closure (post-`jbnx3` scope
or administrative): `aura-plugins-6ujr` (R4 ACP — **descoped from `ow0pq` 2026-05-30**: R13/R15/R17 externally-blocked on Claude Code native ACP; R16/indexer split to `aura-plugins-n856x`, low-prio), `aura-plugins-kv0od` (multi-vendor; new), `aura-plugins-64mld`
(v3/v4 doc reframing; administrative), `aura-plugins-e86ea` (this ROADMAP
refresh; administrative).

## §2. Deferred roadmap items

Each item has explicit provenance (PROPOSAL-2 §12, URD `jbnx3`, ELICIT
C1–C5 bindings, or post-URE discovery) and becomes its own REQUEST when
its trigger condition fires.

| Status | Item | Beads | Trigger / notes |
|---|---|---|---|
| 🟡 | **2a. Binary umbrella: `pasture-msg` → `pasture msg ...`** | (not yet filed) | REQUEST [`aura-plugins-j9c88`](beads://aura-plugins-j9c88) original framing; verbatim direction *"Let's keep pasture-msg as it is for now. We will need to re-think our unification approach."* Not technically blocked; awaits UX decision. |
| 🟡 | **2b. Skill-bodies migration: bd → `pasture task`** | (not yet filed) | Providence URD R9 follow-through. All `/aura:*` skill bodies that call `bd create / close / update / etc.` migrate to equivalent `pasture task` invocations once `pasture task` is the canonical local task tracker. Documentation-heavy; orthogonal to the substrate. |
| 🟡 | **2c. Cross-machine deployment / replicated `pasture.db`** | (not yet filed) | Multi-host need. ADR 0001 D2 punts this; PROPOSAL-2 §5 acknowledges single-machine SQLite. Future: replication or client-server storage swap behind `OpenTaskTracker`. |
| 🟡 | **2d. Provenance library evolution (lift C4)** | (not yet filed) | New REQUEST + ELICIT to lift C4 binding (*"Provenance the library is NOT modified"*). E.g., adding `SessionEntry` natively in Provenance. |
| 🟡 | **2e. Researcher's-notes recording (lift C1)** | (not yet filed) | New REQUEST + user endorsement to lift C1 binding (*"Researcher's notes / exploratory notes are out of scope"*). Was agent-introduced hypothetical, not user-endorsed. |
| 🟡 | **2f. Web UI / multi-agent ACP / analytics convergence** | (not yet filed) | End-vision per PROPOSAL-2 §12. The unified workflow record substrate is in place; visualisation / orchestration layers are the remaining surface. *(Note: the original §12 catch-all also mentioned "marketplace" — that has been reclassified as DONE in §5; see URE Q6 reclassification of jbnx3 R7.)* |
| 🟡 | **2g. Graduate `git_recorder.go` from stub to production** | [`aura-plugins-6l5yo`](beads://aura-plugins-6l5yo) | URE Q3a. Coupled with §1b smoke (smoke can't meaningfully run until this lands). Today `RecordCommit` works (test-covered); `Handle` subscribes defensively to `HookSliceCompleted` but no upstream Claude Code → pasture HookEvent mapping exists ("S7+" deferred). **Blocks `jbnx3` closure** (R1/R4-adjacent). |
| 🟡 | **2h. 30 Python-only skills port to Go** | [`aura-plugins-x5071`](beads://aura-plugins-x5071) | URE §4.5 correction. The "no policy" framing was wrong — `x5071` is the filed policy ("Port all remaining ~30 Python skill directories to Go pasture; user confirmed: Go becomes canonical source"). **Blocks `jbnx3` closure** (R5-adjacent). **x5071 = remaining-30 follow-up to the (re-opened) foundation URD `aura-plugins-f85gw`** (foundation + provenance); IMPL_UAT decisions belong to f85gw, not x5071. |
| 🟡 | **2i. Triage 19 stale work items (3 buckets)** | [`aura-plugins-qzr8a`](beads://aura-plugins-qzr8a) | URE Q5. Bucket A: 10 stale 2026-03 REQUESTs (`oqhjg / bwfqm / fw1cx / u3ae0 / odasf / lczzv / ytj66 / 3ubig / v2a51 / q72mt`). Bucket B: 6 Python-era artifacts (epic `2tj` + URDs `bwfqm / o7i9 / 7vtb / e28b / s6i`). Bucket C: 3 non-Python URDs (`1nla / 99q / s7l0`). All audited individually. **Blocks `jbnx3` closure** (some URDs may carry residuals against R1/R2). |
| 🟡 | **2j. R4 ACP Integration (Full Client)** | tracked by [`aura-plugins-6ujr`](beads://aura-plugins-6ujr) + [`aura-plugins-rk2su`](beads://aura-plugins-rk2su) | URD `jbnx3` R4. Locally-defined ACP wire types + Adapter interface + static registry + 12 hook events. **SPLIT + DESCOPED from `ow0pq` 2026-05-30:** R16/indexer → `aura-plugins-n856x` (low-prio, harness-independent); R13/R15/R17 externally-blocked on Claude Code native ACP. jbnx3 R4 = 'core + ACP types delivered; live bidirectional ACP deferred'. 6ujr §2-active P3 low-prio. |
| 🟡 | **2k. R5 Shared Go Library — cross-module consumption story** | [`aura-plugins-h2zd9`](beads://aura-plugins-h2zd9) | URE Q6a. `pkg/protocol` is shipped; versioning policy, semver guarantees, agent-data-leverage import path, and deprecation policy are unspecified. **Blocks `jbnx3` closure** (IS R5). |
| 🟡 | **2m. Multi-vendor extensibility (OpenCode / Codex / Gemini / Antigravity)** | [`aura-plugins-kv0od`](beads://aura-plugins-kv0od) | URE Q6 NEW. User direction (verbatim 2026-05-24): *"We have plans to extend this system to OpenCode, Codex, and Gemini / Antigravity, but as of right now, we only support Claude Code."* Extend Pasture's codegen to emit role/sub-skill/agent definitions in vendor-specific formats. Post-`jbnx3` scope; **NOT a `jbnx3` closure blocker**. |
| 🟡 | **2n. Codegen body integration non-blocking improvements** | [`aura-plugins-q9sz9`](beads://aura-plugins-q9sz9) | FOLLOWUP epic from Phase 10 code review of codegen body integration. 2 IMPORTANTs (deprecated goldmark API `c.Text(src)→c.Value(src)`; mutable global SkillBodySpecs in tests) + 7 MINORs outstanding. Findings not yet broken into child tasks. Not a `jbnx3` closure blocker. Placed §2-active by audit `aura-plugins-3iz51` (2026-05-29). |
| 🟡 | **2o. Go test paradigm non-blocking improvements** | [`aura-plugins-wftdf`](beads://aura-plugins-wftdf) | FOLLOWUP epic from code review of YAML-driven Go test paradigm port. 3 MINORs outstanding (want_stderr_contains naming, missing t.Parallel() in viper_test.go, AGENTS.md update for Go test paradigm). Findings not yet broken into child tasks. Not a `jbnx3` closure blocker. Placed §2-active by audit `aura-plugins-3iz51` (2026-05-29). |
| 🟡 | **2p. UAT-revision code review non-blocking improvements (Python era)** | [`aura-plugins-ad8i1`](beads://aura-plugins-ad8i1) | FOLLOWUP-2 epic from code review of Python-era UAT revision (`oqhjg`). 8 IMPORTANT findings (signal handler, missing unit tests, formatter/enum issues). Findings not yet broken into child tasks. **RE-PLACED (2026-05-30 Phase-11) §2-active → extract-residual:** the 8 IMPORTANTs target deprecated Python; verify-against-Go residual `aura-plugins-fs107` (verify which apply to Go, file Go-side, close Python-obsolete). R-A theme. Not a `jbnx3` closure blocker. |
| 🟡 | **2q. Beads → provenance integration** | [`aura-plugins-9wdwc`](beads://aura-plugins-9wdwc) | Deferred from aurad+aura-msg UAT. User verbatim: *"We should also plan for how we will move away from Beads. Beads is highly unstable and quickly turning into a garbage fire."* **RE-SCOPED (2026-05-30 Phase-11): Beads → provenance** — the shipped Beads-replacement is provenance (PROV-O SQLite), not Temporal. New scope: how pasture uses provenance + provenance↔Temporal integration. Links §2b. Not a `jbnx3` closure blocker. |
| 🟡 | **2r. ACP-wiring FOLLOWUP — closure-gated on verification** | [`aura-plugins-rk2su`](beads://aura-plugins-rk2su) | All 9 children (ACP-WIRING-REVIEW A/B/C IMPORTANT+MINOR) are CLOSED, but rk2su closure is **gated on verifying the children actually addressed the original findings** (verification task [`aura-plugins-t70aw`](beads://aura-plugins-t70aw)). **Still blocks `ow0pq`** until verified + closed. Placed §2-active by audit `aura-plugins-3iz51` (2026-05-30). |

## §3. Discovered-during-E2E UX polish

Small UX items surfaced during the 2026-04-26 hands-on E2E verification.
Low priority; fold into the next CLI cycle.

| Status | Item | Beads | Notes |
|---|---|---|---|
| 🟡 | **3a. `pasture task events --task-id` alias** | (not yet filed) | Supported filters are `--epoch-id`, `--context-id`, `--context-kind`, `--agent`. Users may reach for `--task-id` from the mental model. Possible fix: add `--task-id` as alias for `--epoch-id` (epoch IDs ARE task IDs per D5), OR clarify the help text. |
| 🟡 | **3b. `pasture task comment add` auto-default-author** | (not yet filed) | Currently requires `--author <wire-format AgentID>` — end-users without a registered agent can't comment. Possible fix: auto-register a "cli-default" agent on first comment-add, OR document the agent-registration step prominently in CLI help. |
| 🟡 | **3c. SessionStart hook — auto-load phase-context from Temporal SAs** | [`aura-plugins-oo359`](beads://aura-plugins-oo359) | When a Claude Code session opens in a worktree associated with an open epoch, read the workflow's `PasturePhase` / `PastureRole` SAs and either *suggest* the matching `/aura:*` skill (safer) or *auto-load* it (more magical). Needs a story for "which epoch is this worktree tied to?" — likely a per-worktree `.pasture/epoch-id` marker, or the aura-swarm one-worktree-per-epoch convention. Lives in the parent `aura-plugins/hooks/` directory. |

## §4. Discoveries during roadmap execution

Bugs and gaps that the roadmap work itself surfaced. These were not in the
original PROPOSAL-2 §12 / FOLLOWUP-ROADMAP inventory — the roadmap turned
them up.

| Status | Item | Beads | Notes |
|---|---|---|---|
| 🟡 | **4a. PROV-O `activities` table never populated** | [`aura-plugins-x45ho`](beads://aura-plugins-x45ho) (P2 bug) | Discovered during §1a smoke. Workflow code never calls `Tracker.StartActivity` / `EndActivity` — `activities` rows aren't written despite PROPOSAL-2 §11 Scenario 1 specifying phase-bracket rows there. **The unit tests don't catch this** because they assert what `RecordTransition` does write (rows in `audit_events` + `context_edges`), not what §11 demands. The SUT is genuinely not mocked; the gap is "tests assert impl behavior instead of spec invariants." Acceptance includes extending `activities_integration_test.go` to assert against the `activities` table per phase transition. Smoke currently emits a WARN on this assertion; tighten back to FAIL when fixed. |
| 🟡 | **4b. Reframe v1/v2/v3/v4 across 4 docs** | [`aura-plugins-64mld`](beads://aura-plugins-64mld) | Discovered during the 2026-05-24 ROADMAP completeness audit URE. Three docs (`docs/architecture.md`, `docs/aurad.md`, `docs/aura-msg.md`) plus `aura-plugins/CLAUDE.md` use "v3 = future engine" framing that's now wrong (v3 was a Python Temporal MVP that was built then abandoned in favor of v4 = Pasture). Updates the framing + adds deprecation banners (subsumes §1h). |
| 🟡 | **4c. Place 8 sibling epics individually** | [`aura-plugins-3iz51`](beads://aura-plugins-3iz51) | Discovered during the 2026-05-24 audit Round 1 (Axis B). The audit had missed 14 of 16 open epics on first pass. URE Q9 outcome: individually place `x5071 / q9sz9 / wftdf / rk2su / ytzcl / ad8i1 / 9wdwc / 6ujr` into §5 / §2 / §0. **Blocks `jbnx3` closure**. |
| 🟡 | **4d. `jbnx3` closure triage** | [`aura-plugins-ow0pq`](beads://aura-plugins-ow0pq) | Discovered during 2026-05-24 audit conclusion. We don't know what's left on `jbnx3` until the visibility audits land; the triage task gates `jbnx3` closure. See §1.5 for the full cascade. |
| 🟡 | **4e. ROADMAP refresh consolidator** | [`aura-plugins-e86ea`](beads://aura-plugins-e86ea) | Administrative task collecting the post-URE ROADMAP.md updates (this commit closes it). |

## §5. Done so far

| Status | Item | Beads | Landed in |
|---|---|---|---|
| ✅ | **PROPOSAL-2 epic — unified Pasture workflow record + observability** | [`aura-plugins-kf87g`](beads://aura-plugins-kf87g) | Commits `af3b432..4436945` (56+ commits across 11 slices + REVISE wave + Phase 12 + smoke). Pushed to `feat--pasture--initial-golang-port`. |
| ✅ | **Gofmt drift cleanup (~28 files)** | [`aura-plugins-ug7oj`](beads://aura-plugins-ug7oj) | Commit `602dea5`. |
| ✅ | **§1a Temporal E2E smoke** | [`aura-plugins-cn5ax`](beads://aura-plugins-cn5ax) | Commit `4436945`. Smoke surfaced [`aura-plugins-x45ho`](beads://aura-plugins-x45ho) — see §4. |
| ✅ | **FOLLOWUP epic (Phase 10 review findings)** | [`aura-plugins-f59jc`](beads://aura-plugins-f59jc) | All findings drained during the Phase 11 REVISE wave (3 IMPORTANTs + ~10 MINORs elevated; epic stays open by convention as a landing-pad for any late trickle-in). |
| ✅ | **Python `aura_protocol` deprecation + skill drift inventory** | [`aura-plugins-naupi`](beads://aura-plugins-naupi) | Commit `c8e3320` on `aura-protocol` branch. `scripts/aura_protocol/DEPRECATED.md` + `docs/PYTHON_TO_GO_MIGRATION.md` landed. |
| ✅ | **Temporal SA rename (`Aura*` → `Pasture*`)** | [`aura-plugins-fb658`](beads://aura-plugins-fb658) | Commits `1b65ca3` (pasture submodule) + `4fff4bf` (parent). 6 SA wire strings renamed. |
| ✅ | **Figures pipeline — ASCII diagrams auto-rendered into role + sub-skill SKILL.md headers** | [`aura-plugins-c4pa`](beads://aura-plugins-c4pa) + [`aura-plugins-mrug`](beads://aura-plugins-mrug) + Go port via [`aura-plugins-0dai6`](beads://aura-plugins-0dai6) | 3 figures (layer-cake, ride-the-wave, architect-state-flow) load from `skills/protocol/figures/*.yaml` at build time. Both Python `gen_skills.py` and Go `internal/codegen/skills.go` render. `TestFigureSpecsCompleteness` asserts the inventory. URE Q1 confirmed closure. |
| ✅ | **`jbnx3` R7 — Polyrepo split** | (URD `jbnx3` R7, intrinsic) | Pasture is a git submodule of `aura-plugins` per URD D11. URE Q6 reclassified this as DONE — the URD's "Marketplace" label was a misnomer; the actual scope was the polyrepo split. We *use* Claude Code's marketplace; we don't build one. Multi-vendor extension is tracked separately as §2m. |
| ✅ | **`agents/*.md` codegen (Go-canonical)** | (intrinsic to Go codegen) | The Go codegen also writes `pasture/agents/{epoch,architect,reviewer,supervisor,worker}.md`. No Python counterpart. Recorded in `PYTHON_TO_GO_MIGRATION.md` 2026-05-24 update. |
| ✅ | **ROADMAP completeness audit (3 review rounds + URE)** | [`aura-plugins-t3498`](beads://aura-plugins-t3498) (REQUEST) + [`aura-plugins-ircvi`](beads://aura-plugins-ircvi) (PROPOSAL) | Commit `0c43d30`. Artifact at `docs/proposals/ROADMAP-COMPLETENESS-AUDIT.md`. 8 post-URE tasks filed + the `ow0pq` `jbnx3` closure cascade wired. |
| ✅ | **Pasture code review FOLLOWUP — all findings resolved** | [`aura-plugins-ytzcl`](beads://aura-plugins-ytzcl) | All 8 child tasks done (✓): PhaseId wire values, ContentBlock dual-fields, CLI coverage, viper config discrepancy, DefaultClientFactory coverage, config file loading coverage, hooks timing assertion. Umbrella task open by convention; work complete. Does not block `jbnx3` closure. Placed §5-done by audit `aura-plugins-3iz51` (2026-05-29). |

---

## How this roadmap evolves

- New items get filed as Beads tasks with `--deps discovered-from:aura-plugins-cmvu5` (transitive ok; via a child like `cn5ax` is fine too).
- Items that block `jbnx3` closure get an additional `bd dep add aura-plugins-ow0pq --blocked-by <task-id>` so the §1.5 cascade stays current.
- Items that turn into real implementation get linked directly under `cmvu5` via `bd dep add aura-plugins-cmvu5 --blocked-by <task-id>` so they appear in `bd dep tree`.
- This ROADMAP.md gets updated when an item moves between status buckets (🟡 → 🔄 → ✅) or when a discovery (§4) surfaces. The Beads tasks are the source of truth; this doc is the browsable summary.

## Cross-references

- **Parent URD:** [`aura-plugins-jbnx3`](beads://aura-plugins-jbnx3) — the Pasture port requirements R1–R7. See §1.5 for closure cascade.
- **FOLLOWUP-ROADMAP epic:** [`aura-plugins-cmvu5`](beads://aura-plugins-cmvu5) — the work-index epic this document narrates.
- **Closure triage:** [`aura-plugins-ow0pq`](beads://aura-plugins-ow0pq) — the gate task that decides `jbnx3` closure.
- **Audit artifact:** [docs/proposals/ROADMAP-COMPLETENESS-AUDIT.md](proposals/ROADMAP-COMPLETENESS-AUDIT.md) — the 2026-05-24 investigation that produced §1.5, §4b–§4e, §2g–§2m.
- **Migration policy:** [docs/PYTHON_TO_GO_MIGRATION.md](PYTHON_TO_GO_MIGRATION.md) — Python deprecation + skill drift + reconciliation policy.
- **Source documents:** [PROPOSAL-2](proposals/PROPOSAL-2-pasture-workflow-record.md), [IMPL_PLAN](impl-plans/IMPL_PLAN-PROPOSAL-2-pasture-workflow-record.md), [ADR 0001](adr/0001-pasture-toolkit-integration-architecture.md).
- **Live binaries:** `pasture` (local task + audit CLI), `pasture-msg` (Temporal signal CLI), `pastured` (Temporal worker daemon), `pasture-release` (versioning), `pasture-migrate-crash` (test-only).
- **Smoke entry point:** `make smoke-temporal` from `pasture/` inside `nix develop`.
