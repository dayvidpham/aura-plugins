---
audit: aura-plugins-fzctk
type: fidelity
wave: 2
elicit: aura-plugins-8y1wo
urd: aura-plugins-6wqht
ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md §5.1
fixes_epic: aura-plugins-yivi2
executed: 2026-05-30
uat: 2026-05-31
status: complete
---

# Fidelity Audit — `fzctk` Supervisor + Worker SKILL.md vs Go Codegen

## §1. Scope and Methodology

Per-fragment fidelity audit of hand-written content in the parent skills vs the Go
codegen that reproduces it.

- **Parent (source of truth):** `skills/supervisor/SKILL.md` L341–869 + `skills/worker/SKILL.md` L253–568.
- **Go codegen:** `pasture/internal/codegen/specs_data_body.go` (prose `SkillBody` sections) **AND** `pasture/internal/codegen/specs_data.go` (schema workflows, behaviors, figures). **Both** render into the generated SKILL.md — see §4 methodology correction.
- **19 header-block fragments** audited (supervisor 11, worker 8).

**Verdict vocabulary (URE-locked):** `captured / distorted / irrelevant / unverifiable / superseded`.

**Distortion threshold (URE-locked):** paraphrase-equivalent OK **if the operational instruction is preserved**; a dropped/changed operational rule → `distorted`.

**Granularity (URE-locked):** two-level — block verdict, drill to bullets when partially distorted.

**Constraint-deference (URE-locked):** verify-then-superseded (case-by-case) — `superseded` only if the C-* constraint's generated text actually covers the fragment.

**Done + checkpoint (URE-locked):** verdict all fragments, then one `/user-uat` pass over the distorted set; every distorted finding gets an explicit user verdict (binding user rule).

## §2. F-A1 Fidelity Table

| # | Fragment | Parent loc | Verdict | Note |
|---|---|---|---|---|
| 1 | **Ride the Wave (Rewritten)** | supervisor L344–399 | **distorted** | Operational rules all captured (schema `rtw-*` actions); the **command** on the Stage-2 spawn action is wrong — see §3 |
| 2 | Given/When/Then/Should | supervisor L400–411 | captured | 5 behavioral rules → `sup-*` behaviors |
| 3 | First Steps | supervisor L412–464 | captured | 7 steps → `sup-first-steps` + subsections |
| 4 | Exploration (Ephemeral Explore Subagents) | supervisor L465–485 | captured | pattern + Task example verbatim |
| 5 | Reading from Beads | supervisor L486–495 | captured | bash commands copied |
| 6 | Implementation Task Structure | supervisor L496–516 | captured | Go struct preserved |
| 7 | Creating Vertical Slices (Phase 8) | supervisor L517–648 | captured | Steps 1–3 incl. bash examples |
| 8 | Assigning Slices | supervisor L649–657 | captured | verbatim |
| 9 | Spawning Workers (+ Model Selection, TeamCreate Context) | supervisor L658–735 | captured | examples reordered, content identical |
| 10 | EPIC_FOLLOWUP Creation (Phase 10) | supervisor L736–845 | captured | handoff chain condensed; dropped a **non-operational** `impl-review` reference link (not a distortion) |
| 11 | Tracking Progress | supervisor L846–869 | captured | 8 `bd` commands verbatim |
| 12 | What You Own | worker L256–270 | captured | |
| 13 | Planning Backwards from Production Code Path | worker L271–304 | captured | 4 steps + diagram |
| 14 | Implementation Order (Layers Within Your Slice) | worker L305–389 | captured | L1/L2/L3 + no-stubs rule |
| 15 | TDD Layer Awareness | worker L390–406 | captured | |
| 16 | Reading from Beads | worker L407–425 | captured | |
| 17 | Vertical Slice Fields | worker L426–436 | captured | 8 fields |
| 18 | Follow-up Slices (FOLLOWUP_SLICE-N) | worker L437–449 | captured | 3 additions present |
| 19 | Updating Beads Status | worker L450–467 | captured | start/complete/blocked |

**Tally:** captured **18**, distorted **1**, irrelevant 0, unverifiable 0, superseded 0.

## §3. The distorted fragment (user-confirmed at Phase-11 UAT)

**Fragment 1 — "Ride the Wave (Rewritten)", Stage 2 (Build).** The operational *rules* are all
faithfully captured in the schema `rtw-build-*` actions (`specs_data.go`):
- `rtw-build-spawn` Instruction: "Spawn workers as Agent tool subagents (general-purpose, run_in_background); use TeamCreate only for >=3 slices with shared integration points" ✓
- `rtw-build-integrate`: "Supervisor commits at integration points (atomic commits) — commit small, integrate early and often" ✓

**The distortion is the accompanying command — at TWO sites.** Both use the
**worktree-tmux-swarm launcher** `aura-swarm start --epic <epic-id>` where the spawn is actually
an in-session Agent-tool spawn:
- `rtw-build-spawn` (`specs_data.go:1357-1361`) — Ride-the-Wave Stage 2 Build. Instruction correctly
  says "Spawn workers as Agent tool subagents…; use TeamCreate only for >=3 slices", but `Command`
  is wrong.
- `S-supervisor-spawn-workers` startup step 6 (`specs_data.go:~1843-1847`) — Instruction "Spawn
  workers for leaf tasks", same wrong `Command`. (This site is in the generated startup sequence,
  outside the original hand-authored audit scope, but is the same defect — surfaced by the user and
  folded into the fix.)

**Correct content (user spec, verbatim 2026-05-31):**
- Mechanism: use the **Agent tool** — `name` field specified → a **teammate**; empty `name` → a
  **backgrounded subagent**. Not `aura-swarm`.
- Describe the worker agent **model** (sonnet non-trivial / haiku trivial — `B-sup-model-*` already
  exist at `specs_data.go:701/708`; surface them at the spawn step).
- Describe the **thinking effort** (the `Thinking` field exists at `specs_data.go:545/566/673`;
  surface it at the spawn step).

- **User UAT verdicts (verbatim):** rule ① "Actually captured — adequately covered elsewhere";
  rule ② "captured in the Golang description… However: what's wrong is the `aura swarm …` command
  that accompanies the instruction. That's the wrong command for this context."; startup site:
  "the startup sequence describes the wrong command. Should not use `aura-swarm …` for this"; correct
  content: "Should describe the worker agent model and thinking effort", "should be Agent with the
  name field specified (for a teammate) or an empty name (for a backgrounded subagent)."
- **Fix:** `aura-plugins-9e42d` (under epic `aura-plugins-yivi2`) — covers both sites + the correct
  Agent-tool/model/thinking-effort content.

## §4. Methodology correction (verify-don't-assume)

The initial pass (3 Explore agents) checked **only** `specs_data_body.go` (the prose `SkillBody`
sections) and reported Fragment 1 as `distorted` with **two lost rules** (supervisor-commit-cadence
and the Task-vs-TeamCreate threshold). **Both were false positives** — coordinator verification +
the user showed the rules are captured in `specs_data.go` schema **workflows/behaviors** (`rtw-build-*`),
a region the agents never read. The real, narrower defect (wrong command) was surfaced by the user.

**Lesson for fidelity audits:** generated SKILL.md content renders from **both** `specs_data_body.go`
(prose) **and** `specs_data.go` (schema workflows, behaviors, figures, startup sequence). Auditing
only one half produces false "lost" verdicts. Future fragment audits must diff against both.

## §5b. Second-pass over `specs_data.go` (coverage-gap remediation)

After the user surfaced the wrong-command defects (in the schema region the first pass skipped),
a second pass of 2 Explore agents audited the supervisor + worker **schema** content in
`specs_data.go` (workflows, startup sequences, behaviors, figures). Result: **no new confirmed
fidelity distortions** beyond the worker-spawn command. Three agent candidates were verified and
dispositioned:

| Candidate | Verification | Disposition (user) |
|---|---|---|
| `rtw-plan-explore` terse instruction (L1329) | operationally complete (captured); omits model/thinking-effort like worker-spawn | not actioned (left as-is) |
| `B-sup-read-context` reads 4 vs startup step 2 reads 2 | internal inconsistency present identically in **both** Python and Go — not a Go-vs-parent distortion | filed as a separate nit `aura-plugins-cqbbg` |
| `B-worker-verify-production` richer in Go | Go ahead-of parent (5wbhm pattern), generated behavior outside hand-authored scope | not a distortion (left as-is) |

(Both agents over-rated the `aura-swarm` defects as BLOCKER; severity held at **minor** per the
user UAT — the operational rules are captured; only the command + missing model/thinking-effort
description are defective.)

## §5c. UAT — distorted-set walk (verbatim)

- Rule ① (supervisor commit cadence): **"Actually captured — adequately covered elsewhere"** (verified at `rtw-build-integrate`).
- Rule ② (Task-by-default / TeamCreate ≥3): **"captured in the Golang description… However: what's wrong is the `aura swarm …` command… the wrong command for this context."**
- Startup site: **"the startup sequence describes the wrong command. Should not use `aura-swarm …` for this."**
- Correct content: **"Should describe the worker agent model and thinking effort."**; **"should be Agent with the name field specified (for a teammate) or an empty name (for a backgrounded subagent)."**

## §5. F-A5 — R1 verdict line

**R1 ("Port aurad / supervisor+worker skill bodies to Go codegen") — codegen-fidelity layer: `DONE-with-residuals-filed`.**

18/19 fragments faithfully captured; 1 distorted (a wrong command, not lost content), fix filed.

### Residuals appendix

| bd task | summary | severity |
|---|---|---|
| `aura-plugins-9e42d` | wrong `aura-swarm start --epic` command on TWO worker-spawn sites (Ride-the-Wave Stage 2 `rtw-build-spawn` + startup step 6 `S-supervisor-spawn-workers`); should use the Agent tool (name → teammate, empty name → backgrounded subagent) and describe worker model + thinking effort | minor (command + missing model/thinking-effort description; operational rules intact) |
