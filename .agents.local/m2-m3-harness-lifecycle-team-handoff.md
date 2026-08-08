---
handoff_kind: pre-planning-agent-team
created: 2026-08-03
status: requirements-elicitation-in-progress
implementation_authorized: false
pasture_repository: /home/minttea/codebases/dayvidpham/aura-plugins/worktree/proposal-57-integration/pasture
pasture_base_branch: main
pasture_base_commit: 0414ad9a7455905c6f865468fe0f2c23222d11b7
landed_pull_request: https://github.com/dayvidpham/pasture/pull/64
beads:
  original_request: aura-plugins-s43qq
  canonical_multi_harness_urd: aura-plugins-hznvh
  historical_ratified_waist_proposal: aura-plugins-neccm
  m1_plan_uat: aura-plugins-h7kkc
  m1_implementation_plan: aura-plugins-pmnvo
  m1_implementation_uat: aura-plugins-uy7nt
  followup_epic: aura-plugins-821k0
  active_followup_ure: aura-plugins-a6h3d
  stale_m2_proposal: aura-plugins-p3g7j
  deferred_native_lookup: aura-plugins-57lhx
  blocked_claude_capture: aura-plugins-3rtgj
  partially_addressed_payload_parity_task: aura-plugins-noqor
  stale_middle_end_finding: aura-plugins-mgn58
github:
  selected_m1_docs: https://github.com/dayvidpham/pasture/issues/53
  selected_m2_experiment: https://github.com/dayvidpham/pasture/issues/56
  opencode_target_artifacts: https://github.com/dayvidpham/pasture/issues/27
  codex_target_artifacts: https://github.com/dayvidpham/pasture/issues/24
  runtime_contracts: https://github.com/dayvidpham/pasture/issues/40
  multi_harness_tracker: https://github.com/dayvidpham/pasture/issues/44
  deferred_native_lookup: https://github.com/dayvidpham/pasture/issues/62
documents:
  lifecycle_urd: llm/plan/urd-harness-lifecycle.md
  standing_research: llm/research/hooks-ir-compilers-architecture-lessons.md
  m1_as_built_plan: llm/plan/impl-plan-m1-claude-vertical.md
  milestone_architecture: llm/plan/proposal-11-harness-lifecycle-compiler.md
  target_codegen_research: llm/research/opencode-codex-codegen-investigation.md
---

# Pre-M2/M3 Handoff - Harness Lifecycle Compiler

## 1. Purpose And Stop Condition

This document grounds a new architect/supervisor/worker team before M2 and M3.
It is not a ratified proposal or implementation plan. Do not start production
code, create worker slices, or launch a worker swarm from this handoff alone.

The immediate role is architect. Finish the active follow-up requirements
elicitation, create a scoped follow-up URD, write a new current-tree proposal,
run independent plan review, and obtain Plan UAT before implementation.

M1 is complete and merged. The current working sequence is staged, but the
active URE must confirm that sequence explicitly:

```text
M1 Claude vertical (merged)
  -> M2 OpenCode authentic ingress + differential equivalence
  -> M2 acceptance gate
  -> M3 Codex frontend + three-harness equivalence
  -> M3 acceptance gate
```

The user requested this handoff before starting either M2 or M3. Preserve that
boundary.

## 2. Landed Baseline

Pasture PR #64 merged the accepted Claude M1 implementation:

- PR: https://github.com/dayvidpham/pasture/pull/64
- Merge commit: `0414ad9a7455905c6f865468fe0f2c23222d11b7`
- Accepted M1 implementation commit: `22f508ff7670fd680c2658e2cbedd8e109882882`
- Final pre-merge cleanup commit: `b35bd94fe9ddd8d0fcf61f5ffde72030e3ca9040`
- Final-head CI passed build/test on Go 1.25 and 1.26, lint, codegen drift,
  and race tests before merge.

The reference checkout was clean and synchronized with `origin/main` at the
merge commit when this handoff was written. Feature work must still use new
isolated worktrees. Do not turn the reference checkout into a shared worker
tree.

`git worktree list` currently contains many historical or separate-epic
worktrees, including OpenCode, Codex, runtime-contract, and M1 branches. Their
presence does not prove that a worker is active or that their branch is current.
Do not reuse one by name alone. Check Beads ownership, branch ancestry, and the
ratified new slice before selecting or creating a worktree.

## 3. User Decisions Captured So Far

### 3.1 Prior Implementation UAT Direction

The accepted M1 follow-up direction is recorded in
`aura-plugins-a6h3d` and `aura-plugins-hznvh`:

- Land accepted Claude M1 first.
- Keep the nine unavailable Claude captures experimental and non-gating.
- Run the lifecycle approach against authentic OpenCode events after M1.
- OpenCode is a distinct provider. OpenCode payloads must never be represented
  as Claude evidence and must never enable Claude activation entries.

Earlier user response, verbatim:

> I ended up running out of Claude usage. Can we keep this experimental, and
> then run this against the OpenCode in the mean time?

Clarifying response, verbatim:

> Land M1, then experiment (Recommended)

### 3.2 Current M2/M3 Scope Choice

Question shown verbatim:

> The merged roadmap is `M1 Claude (done) -> M2 OpenCode + differential
> equivalence -> M3 Codex -> M4 raw-ingestion escape hatch -> M5+
> definition/lineage/context/write gate`. What does "the rest" mean for this
> implementation wave?

Options shown verbatim:

| Option | Description |
|---|---|
| M2 OpenCode only (Recommended) | Deliver and review the next milestone before Codex; matches your prior UAT decision. |
| M2 and M3 | Plan OpenCode and Codex together, with separate implementation and acceptance gates. |
| Full roadmap | Plan M2 through M5+ now; later milestones still need substantial requirements work. |
| Deferred backlog | Prioritize GitHub issues #53-#63 instead of the milestone sequence. |

User response verbatim:

> M2 OpenCode only (Recommended), M2 and M3

Working interpretation already presented to the user: one staged M2/M3 program,
with M2 completed and accepted before M3 proceeds. Do not collapse both
frontends into one unreviewable slice. This interpretation has not yet received
a separate sequencing confirmation, so record that confirmation before proposal
creation.

### 3.3 Deferred Work Selected For This Wave

Question shown verbatim:

> At this follow-up gate, all deferred items must be reconfirmed. Select every
> deferred issue to include in the M2/M3 wave; anything unselected remains open
> and deferred.

Options shown verbatim:

| Option | Description |
|---|---|
| #56 OpenCode (Recommended) | Authentic OpenCode frontend and differential-equivalence milestone selected above. |
| #62 Native lookup (Recommended) | Add one validating contract-derived event-name lookup before introducing another frontend. |
| #53 Plan docs | Correct stale references, package maps, caveats, and plan wording. |
| #54 Panic proof | Add safe runtime proof of lifecycle panic recovery without production injection. |
| #55 Claude captures | Gather nine authentic Claude events; still needs usage and host/MCP permission. |
| #57 Receipt retries | Continue contention acquisition within the bounded outer ingress budget. |
| #58 Coverage mutations | Make corpus coverage and source-mutation anti-vacuity checks executable. |
| #59 Retention and GC | Design measured truncation, deletion, garbage collection, and optional external CAS. |
| #60 Status guard | Mechanically classify mutable status enums in immutable snapshots. |
| #61 Cause boundary | Decide and enforce what collaborator errors may reach user-facing reports. |
| #63 Version matrix | Declare supported harness versions and unsupported-version behavior. |

User response verbatim:

> #56 OpenCode (Recommended), #53 Plan docs

Consequences:

- Include GitHub #56 and #53 in the new proposal/program.
- Keep #54, #55, #57, #58, #59, #60, #61, #62, and #63 open and deferred.
- In particular, the user did not select #62. The stale OpenCode proposal calls
  #62 a prerequisite, but that amendment is not current authority. Do not
  implement `EventByNativeName` silently. Either design M2 against the existing
  contract-derived frontend lookup or return to the user with a concrete reason
  to reopen #62.

### 3.4 OpenCode Host Permission

Question shown verbatim:

> Which OpenCode host actions are authorized for collecting authentic M2
> evidence? These permissions are additive; no selected action will modify Git
> hooks.

Options shown verbatim:

| Option | Description |
|---|---|
| Inspect host (Recommended) | Read the OpenCode binary version/path and existing project/global configuration. |
| Isolated OpenCode run (Recommended) | Run OpenCode with disposable project/config/data state and the generated plugin; no global edits. |
| Project config edits | Allow reviewed changes to this repository's generated project-local OpenCode configuration. |
| Global config edits | Allow reviewed changes under `~/.config/opencode` to load capture plumbing. |
| No host actions | Use repository tests and synthetic fixtures only; authentic capture remains unproven. |

User response verbatim:

> Inspect host (Recommended), Isolated OpenCode run (Recommended), Global config
> edits, Project config edits

This authorizes narrowly reviewed OpenCode inspection, isolated execution, and
OpenCode project/global configuration changes needed for authentic capture. It
does not authorize:

- installing, enabling, or modifying Git hooks;
- changing `core.hooksPath`;
- enabling Beads hooks;
- running Claude or changing Claude configuration;
- inspecting, running, or configuring Codex for M3 without a separate user
  permission decision;
- collecting or publishing secrets from captured payloads.

## 4. Requirements Sources

### 4.1 Beads Requirements

| ID | Status | Role In This Program |
|---|---|---|
| `aura-plugins-s43qq` | closed | Original request: lower native harness events through a canonical lifecycle IR. |
| `aura-plugins-hznvh` | open | Canonical broad multi-harness extension URD. Covers Claude/OpenCode/Codex generated skills, agents, lifecycle hooks, native destinations, installer boundaries, and the no-Git-hooks rule. |
| `aura-plugins-h7kkc` | closed | Accepted M1 implementation-plan UAT and its exact FIX-NOW/DEFER transcript. |
| `aura-plugins-pmnvo` | closed | Completed M1 Claude implementation plan. Use it to understand the interfaces that actually landed, not as an M2/M3 plan. |
| `aura-plugins-uy7nt` | closed | Accepted M1 implementation UAT. Contains the accepted behavior and final deferral dispositions. |
| `aura-plugins-821k0` | open | Parent follow-up epic. It covers all M1 deferrals, not only the selected M2/M3 wave. Do not launch its entire tree as one worker swarm. |
| `aura-plugins-a6h3d` | open | Active FOLLOWUP_URE for the OpenCode experiment. Continue this interview and record exact questions/options/answers. |
| `aura-plugins-p3g7j` | closed | Stale OpenCode proposal. Prior art only; all M1 anchors and package assumptions were superseded. |
| `aura-plugins-57lhx` | open | Deferred native-name reverse lookup, GitHub #62. Explicitly not selected for this wave. |
| `aura-plugins-3rtgj` | blocked | Nine authentic Claude captures, GitHub #55. Remains blocked/experimental and must not gate M2. |

### 4.2 Lifecycle-Specific URD

Read `llm/plan/urd-harness-lifecycle.md` as the lifecycle-specific requirements
extraction. Its central product outcome is:

```text
native harness event
  -> provider frontend / Level 1
  -> typed lifecycle waist / Level 2
  -> legalization / Level 3
  -> backend and Provenance effects / Level 4
```

The narrow waist makes integration `N + M`, rather than one implementation per
harness-operation pair. Operation selection belongs in the middle-end, never in
generated TypeScript, Python, shell, or a caller-selected environment variable.

The URD currently infers the order Claude, then OpenCode, then Codex; it
explicitly marks that order as inferred rather than traceable to a quoted user
decision. The current URE selected both M2 and M3 but still must confirm their
execution order. The URD does state that differential equivalence is mandatory:
a single frontend cannot prove that the waist is genuinely harness-neutral.

### 4.3 Broad Multi-Harness URD

`aura-plugins-hznvh` currently has the title:

> FOLLOWUP_URD-3: Multi-harness Pasture extension delivery

It is broader than lifecycle runtime ingestion. It is nevertheless critical
because M2/M3 generated transport and installation touch its native-delivery
requirements:

- OpenCode skills: `~/.config/opencode/skills/<name>/SKILL.md`
- OpenCode agents: `~/.config/opencode/agent/<role>.md`
- OpenCode lifecycle hooks: OpenCode's JS/TS plugin surface
- Codex skills: `~/.agents/skills/<name>/SKILL.md`
- Codex agents: `~/.codex/agents/pasture-<role>.toml`
- Codex lifecycle hooks: native Codex plugin/hook surface, subject to trust
  review
- "Hooks" always means harness lifecycle hooks. Git hooks are forbidden.

The M2/M3 follow-up proposal must cite both this Beads URD and the
lifecycle-specific file. Do not replace either with the stale proposal.

## 5. Documentation And Research Reading Order

All paths below are relative to the Pasture repository root.

### Authoritative Or Current

| Order | Path | Why It Matters |
|---|---|---|
| 1 | `AGENTS.md` | Current coding, worktree, test, generated-file, and no-process-artifact rules. |
| 2 | `llm/research/hooks-ir-compilers-architecture-lessons.md` | Standing architectural authority for frontends, thin foreign adapters, progressive lowering, and differential testing. |
| 3 | `llm/plan/urd-harness-lifecycle.md` | User-confirmed lifecycle requirements and currently inferred milestone intent; execution order still requires URE confirmation. |
| 4 | `llm/plan/impl-plan-m1-claude-vertical.md` | Detailed as-built M1 interfaces, receipt ordering, activation evidence, and end-to-end behavior. |
| 5 | `docs/codegen.md` | Current generated source-to-target data flow. Read before changing OpenCode/Codex emitters. |
| 6 | `CONTRIBUTING.md` | Current codegen change recipes and generated-output workflow. |
| 7 | `docs/privacy.md` | Exact-payload persistence and privacy posture that authentic capture must preserve. |
| 8 | `llm/research/opencode-codex-codegen-investigation.md` | Historical target research. Revalidate every schema/version claim against current code or official sources before using it. |

### Current Intent, Not An Implementation-Ready M2/M3 Plan

| Path | Use |
|---|---|
| `llm/plan/proposal-11-harness-lifecycle-compiler.md` | Milestone intent: M2 OpenCode differential equivalence, M3 Codex, M4 raw ingress, M5+ deeper control. Its M1 statements predate the landed implementation. |
| GitHub #27 | Broader OpenCode generated artifacts and package boundaries. Coordinate with it; do not conflate it with authentic runtime lifecycle ingress. |
| GitHub #24 | Broader Codex artifacts and package boundaries. It does not by itself define a current runtime lifecycle frontend experiment. |
| GitHub #40 | Version-bounded runtime contracts for all three harnesses. Much of the contract code exists on main; verify live code before assuming every open checkbox means missing code. |
| GitHub #44 | Umbrella tracker only. It is not a slice or implementation plan. |

### Superseded Or Stale Prior Art

| Path Or ID | Warning |
|---|---|
| `aura-plugins-p3g7j` | Closed stale M2 proposal. It assumes superseded M1 types, packages, and actor machinery. Mine requirements/tradeoffs only; re-derive every interface. |
| `llm/plan/lifecycle-ir-waist.md` | Superseded proposal-4 plan. Do not implement from it. |
| `llm/plan/proposal-10-hook-lifecycle-architecture.md` | Historical Claude planning. Its "not built" inventory is stale after PR #64. |
| `.agents.local/harness-lifecycle-compiler-team-handoff.md` | Pre-M1 handoff at obsolete commit `d8a91d7`; preserved for provenance. This document supersedes it operationally. |

## 6. Current Production Architecture On Main

### 6.1 Shared Runtime Contracts Already Exist

`internal/runtime/lifecycle_profiles.go` contains closed typed catalogs and
mappings for:

- Claude Code: 30 events
- OpenCode 1.17.18: 42 events
- Codex 0.144.1: 10 events

The generic M1 stack is implemented and reusable:

- `internal/lifecycle/waist/`: binding and verified Level-1/Level-2 values
- `internal/lifecycle/legalize/`: target-neutral legalization
- `internal/lifecycle/backend/`: target-neutral consultation response/evidence
- `internal/lifecycle/receipt/`: exact bytes, occurrence, interpreted evidence,
  consultation evidence, and one journal operation
- `internal/lifecycle/projection/`: read projection

Do not fork these stages per harness. A second semantic model would defeat the
M2 acceptance criterion.

Critical current-tree fact: `0414ad9` has no generic `Lower` function,
`internal/lifecycle/lower.go`, or landed middle-end production API. The Claude
handler directly coordinates ingress, frontend binding and `NewEvent`,
legalization, backend consultation construction, and receipt. The architectural
requirement that operation selection belong in one middle-end therefore does
not name an existing M1 component. M2 must re-derive whether and how to
introduce that pass from the current interfaces. Do not implement against the
stale `lower.go`, `BackendView`, or `lifecycle-ir-waist.md` design by assumption.

### 6.2 Claude Is The Only Production Lifecycle Ingress

The current production path is in:

- `internal/lifecycle/ingress/claude/`
- `internal/lifecycle/frontend/claude/`
- `internal/lifecycle/activation/claude_2_1_210.go`
- `internal/handlers/hook_lifecycle.go`
- `cmd/pasture/hook_lifecycle.go`

`internal/handlers/hook_lifecycle.go` currently rejects every harness except
Claude. There is no OpenCode or Codex package under
`internal/lifecycle/ingress/` or `internal/lifecycle/frontend/`.

### 6.3 OpenCode Generated Transport Exists, But Uses The Wrong Runtime Path

Current generated files and sources include:

- `opencode.json`
- `.opencode/plugins/pasture-lifecycle.ts`
- `.opencode/pasture-opencode.json`
- `internal/codegen/opencode_hooks.go`
- `internal/codegen/opencode_target.go`
- `internal/codegen/opencode_manifest.go`
- `internal/codegen/opencode_agent.go`

The generated plugin supports named output handlers and a catch-all event
handler, but lifecycle invocation remains gated by `PASTURE_ADAPTER_EVENT`,
`PASTURE_ADAPTER_OPERATION`, and `PASTURE_ADAPTER_INPUT`. It calls
`pasture __adapter invoke`, where the caller selects an operation. That path does
not persist authentic native lifecycle input and violates the desired
native-event -> frontend -> waist architecture.

Do not extend `__adapter invoke` as the lifecycle transport. Replace only the
lifecycle route with a thin event-forwarding boundary whose semantic work stays
in Go.

The only committed OpenCode native fixture is synthetic:

- `internal/codegen/testdata/native/opencode/tool_execute_before.json`

It is useful as schema prior art but is not authentic host evidence.

### 6.4 Codex Generated Transport Exists, But M3 Runtime Work Is Unplanned

Current generated sources include:

- `internal/codegen/codex.go`
- `internal/codegen/codex_agent.go`
- `internal/codegen/codex_manifest.go`
- `.codex/hooks/pasture-lifecycle.py`
- `.codex/hooks/events/*.sh`

The committed Codex native fixture is:

- `internal/codegen/testdata/native/codex/pre_tool_use.json`

Treat it as synthetic unless authentic provenance says otherwise. The current
Codex transport still participates in caller-selected adapter behavior. M3 must
replace that lifecycle path and extend differential equivalence to all three
harnesses, but it needs its own re-anchored requirements and host permission.

### 6.5 Adjacent Open Beads Records Need Triage, Not Blind Adoption

`aura-plugins-noqor` is still marked `in_progress`. The current tree contains a
Claude/Codex guard in `internal/codegen/claude_hooks_test.go`, but it proves only
that every declared identity field appears in the pinned payload shape. It does
not catch loss of non-identity native fields and cannot prove that the declared
shape matches authentic host payloads. OpenCode also has no equivalent complete
native payload-shape table. Reconcile the partially addressed task and its
residual corpus/non-identity coverage before closing, splitting, or creating
duplicate work; authentic captures should drive the remaining decision.

`aura-plugins-mgn58` is still open, but it refers to
`internal/lifecycle/lower.go`, `BackendView`, and `Origin.behaviour`, none of
which exist on current main. Re-evaluate it against the landed `waist`,
`legalize`, and `backend` packages. Do not implement its old package-move remedy
without proving the finding survives the M1 architecture.

## 7. GitHub Issue Map

### Selected For The M2/M3 Program

| Issue | Scope | Required Disposition |
|---|---|---|
| [#53](https://github.com/dayvidpham/pasture/issues/53) | Documentation-only M1 plan corrections and caveats. | Include as a file-disjoint documentation slice or complete before proposal review. It must not change production behavior. |
| [#56](https://github.com/dayvidpham/pasture/issues/56) | Authentic OpenCode lifecycle experiment. | Core M2 runtime issue. Re-anchor to `0414ad9`; preserve provider-correct evidence and default-off experimental activation. |

### Coordinate, But Do Not Conflate

| Issue | Scope | Relationship |
|---|---|---|
| [#27](https://github.com/dayvidpham/pasture/issues/27) | OpenCode skills, agents, hooks artifacts, bundles, and package boundaries. | Owns broader target projection. M2 #56 owns authentic runtime lifecycle ingress. The new proposal must list every shared generated source/output path, say whether #27 is in scope or coordination-only, and assign each path to one slice owner. |
| [#24](https://github.com/dayvidpham/pasture/issues/24) | Codex skills, agents, hooks artifacts, bundles, and package boundaries. | Broader M3 target issue. The new proposal must decide whether #24 is in scope or coordination-only, enumerate every shared generated source/output path, and create a distinct runtime issue if #24 does not own that path. |
| [#40](https://github.com/dayvidpham/pasture/issues/40) | Version-bounded typed runtime contracts. | The typed OpenCode/Codex lifecycle catalogs already exist. Reuse them and verify current gaps. |
| [#44](https://github.com/dayvidpham/pasture/issues/44) | Multi-harness umbrella tracker. | Context only; never dispatch it as one slice. |

### Explicitly Deferred At This Gate

| Issue | Deferred Scope |
|---|---|
| [#54](https://github.com/dayvidpham/pasture/issues/54) | Safe panic-recovery runtime proof. |
| [#55](https://github.com/dayvidpham/pasture/issues/55) | Nine authentic Claude captures. |
| [#57](https://github.com/dayvidpham/pasture/issues/57) | Outer-budget receipt contention continuation. |
| [#58](https://github.com/dayvidpham/pasture/issues/58) | Executable source mutation and case-bound coverage. |
| [#59](https://github.com/dayvidpham/pasture/issues/59) | Payload retention, deletion, GC, and optional external CAS. |
| [#60](https://github.com/dayvidpham/pasture/issues/60) | Mechanical mutable-status classification. |
| [#61](https://github.com/dayvidpham/pasture/issues/61) | User-visible `StructuredError.Cause` boundary. |
| [#62](https://github.com/dayvidpham/pasture/issues/62) | Generic validating native-event reverse lookup. |
| [#63](https://github.com/dayvidpham/pasture/issues/63) | Published harness-version support matrix and skew policy. |

Do not silently absorb these issues into M2/M3 because they appear convenient.
If one becomes a real blocker, return to the user with the exact production
path and tradeoff before changing scope.

## 8. M2 Exploration Findings, Not Yet User-Approved Design

The current-tree exploration found two useful OpenCode candidates:

| Candidate | Why | Caveat |
|---|---|---|
| `session.created` | Small catch-all observation candidate; avoids output mutation and is suitable for proving authentic event delivery. | Verify the live payload and identity requirements against the exact installed OpenCode version before treating it as minimal. |
| `tool.execute.before` | Meaningful correlated named event with `sessionID` and `callID`; natural counterpart to Claude `PreToolUse`. | Blocking/output behavior and native input/output shape are unproven by authentic evidence. |

The recommended experiment sequence from exploration is:

```text
authentic session.created capture
  -> authentic tool.execute.before capture
  -> provider-specific ingress/frontend
  -> differential equivalence with Claude PreToolUse
  -> optional full durable receipt path, if selected in URE
```

This is a recommendation, not a user decision. The new team must still ask the
user which event or pair, and how deep the first experiment should go.

## 9. Unresolved URE Decisions Before Any Proposal

Continue `aura-plugins-a6h3d`. At minimum, elicit and record:

1. Whether M2 must be completed and accepted before M3 implementation begins,
   or whether planning/implementation may overlap while acceptance remains
   separate.
2. M2 first event scope: `session.created`, `tool.execute.before`, or both.
3. M2 depth: authentic capture only; capture through verified waist; or full
   legalize/backend/durable receipt.
4. M2 success criterion: exact provider evidence, differential equivalence,
   durable read-back, activation status, or a selected combination.
5. M2 privacy boundary: what must be redacted, how exact-byte claims change
   after redaction, and whether captured payloads may be committed.
6. M2 version behavior: experiment on exact 1.17.18 or re-profile the installed
   version without implementing deferred #63.
7. M3 Codex host permissions. The OpenCode authorization does not carry over.
8. M3 first authentic event/equivalence class and experiment depth.
9. M3 issue ownership: whether runtime lifecycle work is added to #24 or gets a
   dedicated issue analogous to #56.
10. Definition of done and concrete must-pass/must-fail validation cases for both
   milestones.
11. Catch-all user feedback before synthesizing the follow-up URD.

Per the elicitation protocol, record each question, every option and
description, any code or example shown, and the user's response verbatim. Create
a new scoped FOLLOWUP_URD after the interview; do not treat this handoff as that
URD.

## 10. Proposal Constraints

The replacement proposal must:

- reference `aura-plugins-hznvh`, the new follow-up URD,
  `llm/plan/urd-harness-lifecycle.md`, and current main `0414ad9`;
- record the user-confirmed M2/M3 order and define separate milestone, review,
  and UAT gates if the staged sequence is confirmed;
- define public typed interfaces from the final production path backward;
- preserve explicit OpenCode/Codex provider identities in every durable record;
- keep foreign TypeScript/Python/shell code mechanical and semantics-free;
- derive semantics from the typed runtime contracts in Go;
- use the landed waist/legalize/backend/receipt contracts rather than fork them;
- define differential equivalence over real provider-specific values, not only
  a shape-only boolean;
- keep experimental activation default-off until authentic evidence, privacy
  review, and built-production-path tests pass;
- enumerate every generated source and generated output file touched by M2/M3,
  state whether #27 and #24 are in scope or coordination-only, and assign each
  file to exactly one issue/slice owner so #27/#56 and #24/M3 runtime work never
  overlap;
- include #53 documentation corrections without coupling them to runtime
  behavior;
- state which deferred issues remain deferred;
- not require #62 unless the user explicitly reopens it;
- never install or modify Git hooks.

## 11. Validation Expectations

Every Go test invocation includes `-race`. Do not run a non-race Go test first
and duplicate it later.

Typical final gates from a clean Pasture worktree are:

```bash
nix develop path:. -c make generate
nix develop path:. -c env CGO_ENABLED=1 go test -race -count=1 ./...
nix develop path:. -c go vet ./...
nix develop path:. -c env CGO_ENABLED=0 go build ./...
nix flake check --no-build
git diff --check
```

Use focused race-enabled package tests during iteration. Verify generated files
with a zero-diff regeneration at each integration point. Never hand-merge files
marked as generated; merge their typed sources and regenerate.

## 12. Team Startup Sequence

1. Read this handoff and every document in Section 5.
2. Run `bd show` for the IDs in the YAML frontmatter, especially
   `aura-plugins-a6h3d` and `aura-plugins-hznvh`.
3. Inspect current `origin/main`; do not assume the reference checkout remains at
   the handoff commit.
4. Reconcile partially addressed `aura-plugins-noqor` and stale
   `aura-plugins-mgn58` against current code without adopting old remedies.
5. Finish the M2/M3 URE and create the scoped follow-up URD.
6. Create a new proposal. Do not reopen or implement `aura-plugins-p3g7j`.
7. Run three independent plan reviewers and Plan UAT.
8. After ratification, create a dedicated implementation plan with vertical
   slices and explicit cross-slice integration points.
9. Only then launch workers, one production path and one file owner per
   worktree.
10. Follow the sequence confirmed in URE. The current working assumption is to
    review and accept M2 before dispatching M3 implementation work.

For this pre-planning handoff, launch only one long-running architect if a new
session is needed:

```bash
/home/minttea/codebases/dayvidpham/aura-scripts/launch-parallel.py \
  --role architect \
  -n 1 \
  --prompt "Read /home/minttea/codebases/dayvidpham/aura-plugins/.agents.local/m2-m3-harness-lifecycle-team-handoff.md and resume aura-plugins-a6h3d. Finish URE and a scoped URD; do not implement M2 or M3."
```

Do not invoke `aura-swarm` for this handoff, and do not use the deprecated
`aura-plugins/bin/aura-swarm`. The worktree swarm becomes eligible only after a
scoped implementation epic is ratified. Informational only; do not run during
this handoff: the later permitted form is
`/home/minttea/codebases/dayvidpham/aura-scripts/aura-swarm start --epic <id>`.
Reviewers stay short-lived and independent.

## 13. Non-Negotiable Safety Rules

- Never install, enable, or modify any Git hook without new explicit permission.
- Never use OpenCode evidence as Claude or Codex evidence.
- Never synthesize an "authentic" fixture or provenance record.
- Never expose captured secrets in fixtures, logs, comments, or commits.
- Never let generated foreign-language code select semantic operations.
- Never work around the typed runtime contract with an arbitrary string map.
- Never edit generated outputs as the source of truth.
- Never share a worker worktree.
- Never use `git commit`; use `git agent-commit` when a later implementation
  task explicitly reaches landing.
- Never commit unrelated dirty files from the Aura Plugins root. `.agents.local`
  is local coordination state unless the user explicitly asks to version it.

## 14. Definition Of A Successful Handoff

The receiving team succeeds when it can answer all of the following before
writing production code:

- Which exact authentic OpenCode event(s) constitute M2?
- How far through the landed pipeline must M2 travel?
- Which evidence and differential assertions prove the waist is real?
- Which exact Codex event(s) and host permissions constitute M3?
- Must M2 acceptance precede M3 implementation, or may the milestones overlap?
- Which generated files belong to the runtime experiment versus #27/#24?
- Which issues are intentionally deferred and therefore excluded?
- What are the independent M2 and M3 acceptance gates?

If any answer is missing, continue elicitation or architecture work. Do not hand
the ambiguity to workers.
