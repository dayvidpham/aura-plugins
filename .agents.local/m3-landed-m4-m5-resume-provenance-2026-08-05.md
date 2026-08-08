# M3 Landed + M4/M5 Resume Provenance

Captured 2026-08-05, after PR #81 merged. Purpose: resume the lifecycle program
later without re-deriving the milestone plan or the M4/M5 dependency question.

## Current state

- **M3 Codex 0.146.0 lifecycle vertical: LANDED.** PR #81 merged to
  `dayvidpham/pasture` main at `98fa2c8` (squash). GitHub #65 closed COMPLETED.
  Branch `feat--m3-codex-lifecycle-vertical` deleted after merge; the worktree
  branches (`integrate--m3-wave-1`, `feat--m3-s5-codex-activation`) remain local
  only.
- CI: all 5 checks green on merge. The "Race Tests" job initially failed once on
  a flaky `internal/engine` test (`TestDBOSConcurrencySpike_IsolatedEnginesCanOverlap`,
  SQLITE_BUSY/Recv timeout — unrelated to the comment-only diff); rerun passed.
- Beads: `aura-plugins-28786` (M3 IMPL_PLAN epic) closed; `aura-plugins-erzdj`
  (M3 Implementation UAT) closed; all flip-review findings closed (hy9n7, 9ta7s,
  hi66x, kkdhg). M3 deferrals recorded on the UAT task.

## The milestone plan (canonical sources)

**Beads task that owns the plan:** `aura-plugins-neccm` (PROPOSAL-4: Canonical
lifecycle IR waist — ratified, now superseded), section "Milestones and testing":

| Milestone | Scope | Status |
|---|---|---|
| M1 | Contract freeze + Claude observation spine | committed |
| M2 | OpenCode frontend + differential equivalence + lazy actor derivation | committed |
| M3 | Codex frontend | committed |
| M4+ | Context binding, gates, human response, escape hatch, retire drift | directional |

**Finer split** (repo-side design doc only, NOT a ratified plan):
`llm/plan/proposal-11-harness-lifecycle-compiler.md` §5:
- M4 = raw-ingestion escape hatch (URD R4): typed, versioned raw-JSON command
  decoding into the same L1 through the same verifier, visibly marked
  non-recommended (authority §10). Stated precondition: "needs the L1 path
  stable first" (i.e., M1–M3 done).
- M5+ = definition resolution, lineage, context disclosure, the normative write
  gate. R7 (versioned interpretation identity) deferred to M5: "the codebook
  reference has no producer in the tree".
- D11: M1–M3 refuse blocking-mode events with an actionable error naming M5
  (no response encoding before M5).

**Roadmap line** (verbatim, URE transcript `aura-plugins-a6h3d`):
"M1 Claude (done) -> M2 OpenCode + differential equivalence -> M3 Codex -> M4
raw-ingestion escape hatch -> M5+ definition/lineage/context/write gate."
User chose "M2 OpenCode only (Recommended), M2 and M3" — i.e., staged program,
separate gates per milestone, not the full roadmap planned at once.

**URD deferral line** (`aura-plugins-feoub`, Explicit deferrals):
"M4 raw-ingestion escape hatch and M5+ definition/lineage/context/write-gate
work" — both deferred, no further requirements work done.

## M4 vs M5 dependency answer (verified 2026-08-05)

**M5 does NOT depend on M4.** No doc states a dependency between them; the
roadmap arrow is chronological intent, not a prerequisite chain. Their stated
preconditions both point backwards to the stable L1 path (M1–M3), not at each
other. Scopes are orthogonal: M4 = ingestion path (raw JSON -> same L1);
M5 = authority/effects/context (definition resolution, lineage, context
disclosure, write gate). So M5 could be planned and delivered before M4.

Caveats:
- Both require M1–M3 (stable L1) first.
- D11 constrains when M5 must land relative to *blocking-event* support, not M4.
- Speculative: the M5 write gate may eventually want to govern raw ingestion
  (lower-trust path) — no doc requires it today.

## Ratified proposals

- **M2/M3 work:** `aura-plugins-e3r38` (FOLLOWUP_PROPOSAL-3: Staged OpenCode
  and Codex lifecycle derivation) — ratified 2026-08-03 (3× ACCEPT + Plan UAT
  ACCEPT). Explicitly M2/M3 only; "All 14 presented non-MVP groups remain
  explicitly DEFER."
- **M4/M5: NO ratified proposal, NO URE, NO URD of its own, NO GitHub issue,
  NO Beads task.** Needs full Phase 1–6 (request -> URE -> URD -> proposal ->
  review -> UAT -> ratification) before any implementation.

## GitHub issues relevant to resuming

- #65 — M3 Codex runtime vertical. CLOSED (COMPLETED) via PR #81.
- #56 — M2 OpenCode + shared middle-end. Landed (base of M3).
- #24 — Codex packaging/bundle owner, coordination-only for runtime vertical;
  owns the deferred M3 activation audit-report artifact (k4p2z disposition:
  "DEFER to #24").
- #53 — plan/docs corrections; #54 — panic proof; #55 — live Claude captures
  (needs usage + host/MCP permission); #57 — receipt retries; #58 — coverage
  mutations; #59 — retention/GC; #60 — status guard; #61 — cause boundary;
  #62 — native event-name lookup; #63 — version matrix (declared supported
  harness versions + unsupported-version behavior).
- M1 landed at #79 (Claude activation `d2908f5`); the M2/M3 milestone program
  originated from issue #65's context and URD `aura-plugins-feoub`.

## Standing deferral set (reconfirmed verbatim at M3 UAT)

Rejection matrices; deny + input mutation; PostToolUse/Stop/SessionEnd and all
other events; exhaustive catalogs; version matrix #63; live Claude #55; #54,
#57–#62; raw captures beyond the two cleared Codex candidates; Strike; Grok
Build; M4; M5+. End-vision providers: Claude, OpenCode, Codex, Strike, Grok
Build (Strike/Grok have no inferred host contract or implementation scope).

## How to resume

1. Pick the next milestone: **#24 (Codex packaging/bundles)** is the nearest
   coordination owner (absorbs the deferred audit-report item). Alternatively
   start M4 or M5 planning — M5 is permitted before M4 per the dependency
   answer above, but either needs full Phase 1–6.
2. Create the REQUEST Beads task + GitHub issue, run URE, URD, proposal, review,
   Plan UAT, ratification, then implementation plan and worker slices per the
   Aura protocol (see `skills/protocol/PROCESS.md`).
3. Note: `bd` runs from `aura-plugins` workdir; code lives in
   `~/codebases/dayvidpham/pasture`; use isolated worktrees for implementation.

---

# Codex bundle (#24) legacy-work audit — 2026-08-05

Read-only audit (no git tree modified) of the July-24 early-slice work against
current `main`, to decide what of it is mergeable. Context: the M1–M3 native
lifecycle program (PRs #27/#40/#45/#47/#56/#65/#79/#81) landed in between.

## Pasture PR #52 (`feat/codex-assets`, commit `597d1ce`, July 24)

State at audit time:
- OPEN; **173 commits behind / 1 ahead** of `origin/main`; merge-tree reports
  **13 conflicts** (add/add on `.codex/agents/*.toml`, content on
  `go.mod`, `internal/codegen/codegen.go`, `harness.go`, `ci.yml`, etc.).
- CI "Race Tests" check red (engine flake pattern, same class as M3's
  `TestDBOSConcurrencySpike` issue — branch predates its fix).
- PR content (86 files): `.agents/skills/` tree (52 files), 5
  `.codex/agents/*.toml` in the OLD `developer_instructions`-prose format,
  codegen source (`codex_agent.go`, `templates/codex_agent.go.tmpl`,
  `codex_skill_test.go`), harness/codegen wiring, CI/docs/go.mod tweaks.

### Verdict: fully superseded — do not merge

| PR #52 content | Current `main` state |
|---|---|
| `.agents/skills/` tree (52 files) | **Byte-identical on main** (0 diff lines, name sets identical) — already landed |
| `.codex/agents/*.toml`, prose `developer_instructions` format | Replaced by newer schema `pasture.codex.agent.v1`: `schema/name/model/role_class/functions`, with `functions` derived from pinned runtime contract `codex/codex@0.146.0` (M3, PR #81) |
| `codex_agent.go` template rendering | Rewritten (+97/−128): emits TOML directly in Go; `templates/codex_agent.go.tmpl` removed from main |
| `codex_skill_test.go` | Obsolete; main has `codex_test.go`, `codex_manifest_test.go`, `codex_transport*_test.go` |
| OpenCode-specific prose/tool-call work | Landed (#27, #56/M2): main emits `.opencode/agent/*.md` with `mode/permission` + provider-qualified model ids; `openCodeVerbatimDirs` rename is on main |
| Codex-specific tool-call work | Landed (#45, #65/M3): contract-derived `functions`, `.codex/codex.toml` manifest, `.codex/hooks/` runners |
| `cmd/pasture/{phase,query,session,signal,slice,task_*}.go` "not on main" | Base-era files main has since deleted/refactored — NOT PR contributions |

Net: the codex-specific and opencode-specific prose/tool-call work in the
codegen pipeline has **already landed** on main, in richer form, via the native
target work. PR #52 is obsolete in full; no cherry-pick value identified.

## Aura commit `461b569` (`feat/codex-home-manager`, local, unpushed)

- Aura `main` has NOT moved since the worktree base (`0/0` ahead/behind);
  merge-tree shows **no conflicts** applying `461b569` onto `origin/main`.
- Content: `codex.skills.enable` → `~/.agents/skills`, `codex.agents.enable` →
  `~/.codex/agents`, `hm-module-test.nix` fixture wired into `flake.nix`
  `checks.hm-module-test`.
- **This is the genuinely mergeable remainder.** Aura main's `nix/hm-module.nix`
  still has no Codex projection (Claude `agents/` + OpenCode `.opencode/*` only);
  flake.lock pins Pasture `4b35fd0` (pre-Codex — no `.agents/skills` or
  `.codex/agents` exist there, so the module cannot evaluate correctly until the
  lock advances to a rev containing the Codex artifacts, e.g. current main
  `98fa2c8`).
- Aura remote also carries stale `feat/codex-codegen` (`12cc010`).

## Bottom line

- **Pasture:** nothing mergeable from PR #52 — supersede/close it without merge.
- **Aura:** `461b569` is the mergeable piece; requires flake.lock advance to a
  Codex-bearing Pasture rev, then push of `feat/codex-home-manager` (or a fresh
  branch) as a PR.
- Open question for wrap-up of #24: whether the Aura HM Codex projection is
  still wanted at all, given main now ships a Codex plugin manifest
  (`.codex/codex.toml`) that itself selects skills/agents/hooks packages — the
  HM module path duplicates what the manifest already enables.

---

# Architecture observation: two sides of the same "harness" pattern — 2026-08-05

Fold-in note (no code changed). During the audit we noticed the codegen layer
(`internal/codegen`, which generates skills/agents/plugin manifests/artifact
bundles — better named `artifactgen`/`plugingen` than `specgen`) and the
lifecycle frontend/ingress layer (`internal/lifecycle` + `handlers`) implement
the exact same core architecture twice, but at two different levels of
normalization. Detailed planning deferred; this is the observation to resume
from.

## The shared pattern (deliberate, coherent)

Both build "harness = closed enum, pinned versioned adapter, thin branch into a
shared neutral core":

| Concern | `internal/codegen` (artifactgen) | `internal/lifecycle` frontend/ingress |
|---|---|---|
| harness enum | const (`claude-code`/`opencode`/`codex`; `antigravity` rejected at resolve) | `ir.HarnessID` — same 3 IDs, closed set (`internal/codegen/ir/ids.go`) |
| registry | `harnessRegistry` **map** + `ResolveHarness(...)` (`harness.go`) | `dispatchLifecycle` **switch** in `handlers/hook_lifecycle.go:160` |
| adapter shape | one `Target=Target` struct (SkillRoot, SkillTemplate, SkillWrite, Agents, Manifest, Verbatim) + `AgentEmitter`/`ManifestEmitter` interfaces | one package per harness, each re-`Bind()`/`bindError`/`findDeclaredField` (~40 repeated lines) |
| shared core | `skillBody`/`skillSubBody` templates, `Generate()` (`generate.go`) | `waist.BindEvent`/`NewIdentity`, `model`, `receipt` |
| manifest | per-harness emitters (ted codex) and `.gen.go` | `hostcontractgen` → `registration/*.gen.go`, per-harness payload `.gen.go` |

## Assessment

- It is intentionally a re-application (closed enum → pinned contract → adapter
  → shared core) in two subsystem layers, not accidental duplication.
- **The artifactgen half is the more normalized.** One registration line +
  one struct gets you a harness; `opencode` even reuses the Claude agent body
  (render → strip frontmatter → rewrap). Adding a harness there is "add data".
- **The lifecycle/frontend half must bend only at the registry line, not the
  per-host packages — but its adapter carries a second concern artifactgen does
  not: provenance/attribution/identity/receipts.** The frontends produce typed
  `waist.L1` + `[]waist.Identity`; the ingress captures byte-exact payloads with
  sha256 digests and classifies dispositions; `receipt.Service.Receive` then
  persists durable attributable receipts (blob digest, identity resolver,
  clock, journal append, operation IDs — see `receipt/service.go`). Hosts
  pin different identity *fields* (Codex `session_id`/`turn_id`/`tool_use_id`;
  OpenCode `sessionID`/`callID`; Claude's catalog of native fields), so the
  identity surface is genuinely per-host typed data, not data in the hilarious
  sense artifactgen has (pure emission).

  Consequence for the transition: pushing the hooks system toward the same
  closed-enum registry direction is right, but the fold-in differs from
  artifactgen —
  - the **dispatch/registry** can become a closed-enum map (mirror
    `harnessRegistry` / `ResolveHarness`), replacing the hand-written `switch`
    in `handlers/hook_lifecycle.go:160`;
  - the **generated registration** (`hostcontractgen` → `registration/*.gen.go`,
    `event_kinds.gen.go`) IS the right analogy to artifactgen's "add data": the
    per-host *data* already exists in generated form;
  - the **typed identity/receipt/provenance core must stay host-pinned** — it
    cannot be collapsed to the neutral-emitter equivalent because attribution
    surfaces differ per host. The shared seam is the `waist.L1`/`Identity`/
    `receipt.Service` contract, not the per-host field derivation.

## Candidate follow-ups (NOT started)

1. Extract a `frontendRegistry[ir.HarnessID]frontend.Binding` map and drive
   `dispatchLifecycle` from it (map-parity with `harnessRegistry`). LOW RISK,
   purely mechanical, do first.
2. Collapse per-host `Bind` *plumbing* (the validate → `waist.BindEvent` →
   identity-loop skeleton) onto a shared generic path typed by
   `LifecycleContract` — while KEEPING the per-host event→ordinal map and the
   per-host typed identity field derivation as host-pinned data. Do NOT try to
   genericize identity/provenance/receipt semantics across hosts.
3. Renaming consideration: `internal/codegen` → `artifactgen` / `plugingen`
   (skills + agents + manifests + artifact.Bundle outputs) — naming only, no
   semantic change.
4. Provenance/receipt/identity layer review (post-when-1-2): confirm the
   closed-enum dispatch + generated-per-host data is sufficient and that
   receipts continue to report precise host provenance (which host, which
   event, which fields) — attribution is a first-class requirement, not a
   render detail.

Revisit after the #24 wrap-up decision; do not fold into the current M3/M4/M5
work without a ratified plan (M4/M5 needs full Phase 1–6 anyway).

---

# Inventory split observation: commands + events live in separate tables — 2026-08-05

Whether a given command or native event is *available* in a harness is currently
declared in at least THREE places, which drift independently:

1. **Semantic command catalog** — `CommandSpecs` map in
   `internal/codegen/specs_data.go:826` (the `cmd-*` operation set: `cmd-worker`,
   `cmd-sup-plan`, `cmd-rev-code`, etc.). This is the "what can an agent do"
   vocabulary.
2. **Lifecycle event catalog** — `internal/lifecycle/registration/event_kinds.gen.go`
   (generated by `hostcontractgen`), plus per-host registration/activation
   tables: `claude_2_1_210.gen.go`, `opencode_1_18_10.gen.go`,
   `codex_0_146_0.gen.go`, plus the per-host `*TargetEvents()` filters in
   `internal/lifecycle/activation/`.
3. **Per-harness native tool/function derivation** — the "available tool" axis
   is split across a third table: `RoleSpec.Tools` (`specs_data.go`),
   `commandSkillDirs` (`harness.go`: which command ID emits which skill dir),
   the OpenCode tool → permission map (`opencode_agent.go`), and
   `codexNativeFunctions()` (`codex.go`, derived from the pinned runtime
   contract).

So "what can this harness invoke / observe" is not expressed once: it's split
between codegen `CommandSpecs` (available agent commands), the lifecycle
registration events (lifecycle events per host), and per-host native
tools/functions. The host adapters (Claude tools, OpenCode permissions, Codex
functions) re-derive from overlapping source tables rather than one closed
vocabulary.

## Working direction to fold into planning

Build ONE closed inventory — a single per-harness-bounded table of commands +
events + native functions — that each layer (codegen emitter, lifecycle
frontend, activation filter, receipt/attribution) consumes, so that:

- "what is available in harness X" has exactly one answer;
- global-ID / capability checks, frontend `Bind` gating, and
  `codexNativeFunctions` derivations read from the same source; and
- adding a host or a capability is one row, not edits in N maps.

Scope/risks to weigh when planning (later):

- (a) name collision between the semantic command id (`cmd-worker`) and the
  event kind (`EventOpenCodeCommandExecuted`) — one namespace must reconcile or
  explicitly disambiguate them;
- (b) per-host identity/provenance fields must remain host-pinned data (see the
  frontend follow-up above) — the inventory does not change the typed identity
  surface;
- (c) `codexNativeFunctions` intentionally derives from the pinned contract at
  runtime — the inventory must not become a place to bypass contract-derived
  native truth with a literal.

Revisit after the #24 decision; do not start without a ratified plan (M4/M5
needs full Phase 1–6 anyway).

---

# M5 ↔ architecture-work dependency analysis — 2026-08-05

Question answered: how much of the frontend/ingress/artifactgen architectural
work (the two observations above) would affect M5? Verdict: **most of the
lifecycle-side work is upstream substrate for M5; the artifactgen-side work is
largely orthogonal to it.**

## Per-pillar mapping (M5 pillars from `proposal-11` §5)

| M5 pillar | Lives today in | Affected by which observed work |
|---|---|---|
| Definition resolution (R7) | no producer in the tree (empty concept) | **Inventory unification** is the seed of the codebook R7 says has no producer. Without one source of truth, the codebook cannot answer "which version of which book interpreted this". |
| Lineage | chained occurrences / receipts (`receipt.Service`, `InterpretedRecord`) | **Directly built on the provenance/identity pillar** (follow-up #4). Lineage is exactly "host + event + fields" attribution chained over time; genericizing identity/provenance would degrade M5 lineage to per-host sniffing. |
| Context disclosure | read-only projection of committed L3 state, FSM transitions | Near-indifferent. Only the one-inventory touches it ("what can this harness observe" is a disclosure input). |
| Normative write gate | legalize/backend/guard; per-event `Blocking`/`Mutation`/`ExitTwoBlocks` in event catalogs (`claude_2_1_210.go` ~line 94; `codex_0_146_0.go`; `opencode_1_18_10.go`) | **Highest concentration.** A unified inventory table is the gate's access-decision surface ("event X → blocking+mutation" per harness). |

## The two reductions

- **Lifecycle-side (frontendRegistry, Bind-collapse, inventory, provenance
  retention):** ~everything is an anode for M5. Registry makes adding a
  per-host blocking terminal "add data" (artifactgen ergonomics); inventory =
  what the gate gates on; provenance = what lineage records.
- **Artifactgen-side (rename, emitter normalization, bundles):** ~orthogonal.
  M5 is runtime/lifecycle; generated skills/plugins are not in its critical
  path. Only the command axis of the one-inventory overlaps (commands on hooks).

## The caveat

The two most M5-critical pieces — provenance/identity retention (don't refactor
it into a hole) and the single inventory — are exactly the parts recorded as
deferred follow-ups. Specifically:

- losing host-pinned identity/provenance would break R7's "which host + codebook
  + version" attribution;
- the inventory is neither a precondition to start M5 nor M5's job — the write
  gate can continue to index per-host catalog literals (current block). But
  without it, R7's codebook has no clean vocabulary.

Planning implication: when M5 planning begins (full Phase 1–6), treat
identity/provenance stability and the codebook/inventory conversation as
**inputs to the M5 URE/URD**, not invisible prerequisites to discover
afterwards. Do not fold into current work without a ratified plan.
