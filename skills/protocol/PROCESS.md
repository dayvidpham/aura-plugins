# Aura Protocol - Process Guide

This is retained Aura reference documentation. The operative authority is the
current Pasture-generated protocol and the repository's root AGENTS.md, not a
second local protocol implementation. Before running any tracker recipe, follow
[TRACKER.md](TRACKER.md) to select the store, explicit namespace and registered
author. Bind every task variable to a full URI from actual create output or a
verified assignment/read; these examples must not run with unbound variables.

For agent role definitions and detailed tool references, see `skills/`.

---

## Quick Start (60 seconds)

**The Aura Protocol runs through 12 phases:**

```
Phase 1:  REQUEST         (classify, research, explore)
Phase 2:  ELICIT + URD    (URE survey, user requirements document)
Phase 3:  PROPOSAL-N      (architect proposes)
Phase 4:  REVIEW          (parallel reviewers, ACCEPT/REVISE)
Phase 5:  Plan UAT        (user acceptance test)
Phase 6:  Ratification    (supersede old proposals)
Phase 7:  Handoff         (architect → supervisor)
Phase 8:  IMPL_PLAN       (supervisor decomposes into slices)
Phase 9:  SLICE-N         (parallel workers)
Phase 10: Code Review     (severity tree: BLOCKER/IMPORTANT/MINOR)
Phase 11: Impl UAT        (user acceptance test)
Phase 12: Landing         (commit, push, hand off)
```

**Check current progress:**
```bash
# Project overview: derive counts locally from one namespaced read (there is no `stats` verb).
pasture task list --namespace "$PASTURE_NAMESPACE" --format json | jq 'group_by(.status) | map({status: .[0].status, count: length})'
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p3-plan:s3-propose    # Active proposals
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice --status in_progress  # Implementation progress
```

**Full sections below.** For detailed steps, see agent files in `skills/`.

---

## Phase 1: REQUEST (`aura:p1-user`)

### When to Trigger Planning

Start planning when:
- User submits a new feature request
- A blocker requires architectural decision
- Multi-phase work needs coordination

### Sub-steps

Phase 1 expands into 3 sub-steps:

| Sub-step | Label | Description | Parallel? |
|----------|-------|-------------|-----------|
| s1_1-classify | `aura:p1-user:s1_1-classify` | Capture and classify user request | Sequential (first) |
| s1_2-research | `aura:p1-user:s1_2-research` | Research existing solutions and patterns | Parallel with s1_3 |
| s1_3-explore | `aura:p1-user:s1_3-explore` | Explore codebase for integration points | Parallel with s1_2 |

### REQUEST Task

**What:** Capture user's problem statement as a Pasture task.

```bash
REQUEST_URI=$(pasture task create "REQUEST: Brief description of need" \
  --namespace "$PASTURE_NAMESPACE" --type feature --priority high \
  --description "Full user request with context, acceptance criteria" --format json | jq -er '.id')
pasture task label add "$REQUEST_URI" aura:p1-user:s1_1-classify --namespace "$PASTURE_NAMESPACE"
```

**Who:** Usually user or coordinator creates this.

**Next:** After classification, research and exploration happen in parallel. Then proceed to Phase 2 (Elicitation).

See: [../user-request/SKILL.md](../user-request/SKILL.md)

---

## Phase 2: ELICIT & URD (`aura:p2-user`)

### Sub-steps

| Sub-step | Label | Description |
|----------|-------|-------------|
| s2_1-elicit | `aura:p2-user:s2_1-elicit` | URE survey — structured requirements elicitation |
| s2_2-urd | `aura:p2-user:s2_2-urd` (also `aura:urd`) | Create URD — single source of truth for requirements |

### URE Survey (s2_1)

Architect runs `/aura:user-elicit` for structured requirements elicitation.

Capture results using the same structured format as
[UAT_TEMPLATE.md](UAT_TEMPLATE.md) — each question must include the exact
question text, ALL options with their descriptions, and the user's verbatim
response. See [UAT_EXAMPLE.md](UAT_EXAMPLE.md) for an example of the recording
quality expected.

### User Requirements Document (s2_2)

**What:** A single Pasture task (label `aura:urd`) that serves as the single source of truth for user requirements, priorities, design choices, MVP goals, and end-vision goals.

**Lifecycle:**
- **Created** in Phase 2 with structured requirements from the URE survey
- **Referenced** via description frontmatter in PROPOSAL, IMPL_PLAN, UAT, and other tasks
- **Updated** via `pasture task comment add` whenever requirements/scope change (UAT results, ratification, user feedback)
- **Consulted** by architects, reviewers, and supervisors as the single source of truth for "what does the user want?"

```bash
# Create URD after elicitation. The title is positional; labels are a second command.
URD_URI=$(pasture task create "URD: {{feature name}}" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  elicit: {{elicit-task-uri}}
---
## Requirements
{{structured requirements from URE survey}}

## Priorities
{{user-stated priorities}}

## Design Choices
{{design decisions from elicitation}}

## MVP Goals
{{minimum viable scope}}

## End-Vision Goals
{{user's ultimate vision}}" --format json | jq -er '.id')
pasture task label add "$URD_URI" aura:urd --namespace "$PASTURE_NAMESPACE"
pasture task label add "$URD_URI" aura:p2-user:s2_2-urd --namespace "$PASTURE_NAMESPACE"
```

**Don't Forget About the URD!** Every agent should consult the URD before making decisions. When in doubt about requirements, `pasture task show "$URD_URI"` is your first stop.

### Dependencies

The canonical dependency chain flows top-down (parents blocked by children):

```
REQUEST
  └── blocked by ELICIT
        └── blocked by PROPOSAL-1
              └── blocked by IMPL_PLAN
                    ├── blocked by SLICE-1
                    │     ├── blocked by leaf-task-a
                    │     └── blocked by leaf-task-b
                    └── blocked by SLICE-2

URD ← referenced via frontmatter in (REQUEST, ELICIT, PROPOSAL, IMPL_PLAN, UAT)
```

**Rule:** `pasture task dep add "$STAYS_OPEN_URI" --blocked-by "$MUST_FINISH_FIRST_URI"`. The `--blocked-by` target is always the thing you do first. Work flows bottom-up; closure flows top-down.

**Next:** Architect spawns `/aura:architect-propose-plan` skill to explore and propose.

---

## Phase 3: PROPOSAL-N (`aura:p3-plan`)

### PROPOSAL-N Task

**What:** Architect's full technical proposal including tradeoffs, interfaces, validation checklist, and BDD criteria. N starts at 1 and increments with each revision.

**PROPOSAL-N must include:**

| Item | Purpose | Example |
|------|---------|---------|
| **Problem Space** | Map the engineering axes (parallelism, distribution, frequency) | "Is this distributed? How much parallelism?" |
| **Tradeoffs** | Document why we chose Option A over B | "Chose Redis over in-memory because..." |
| **Interfaces** | Define all public types, enums, methods | `type FooService interface { DoThing(...) }` |
| **Validation Checklist** | Testable items per phase | `[ ] Type checking passes, [ ] All tests pass` |
| **BDD Criteria** | Acceptance criteria in Given/When/Then format | `Given <state> When <action> Then <outcome>` |
| **MVP Scope** | What's in MVP vs Phase 2 | "MVP: core flow only. Phase 2: parallel workers" |

**Creation:**
```bash
PROPOSAL_URI=$(pasture task create "PROPOSAL-1: Technical proposal for feature" \
  --namespace "$PASTURE_NAMESPACE" --type feature --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  urd: {{urd-task-uri}}
---
## Design
{validation_checklist: [...], acceptance_criteria: [...]}
..." --format json | jq -er '.id')
pasture task label add "$PROPOSAL_URI" aura:p3-plan:s3-propose --namespace "$PASTURE_NAMESPACE"
```

Link dependency:
```bash
pasture task dep add "$REQUEST_URI" --blocked-by "$PROPOSAL_URI" --namespace "$PASTURE_NAMESPACE"
```

**Next:** Architect runs `/aura:architect-request-review` to spawn 3 reviewers in **PARALLEL**.

See: [../architect-propose-plan/SKILL.md](../architect-propose-plan/SKILL.md)

---

## Phase 4: Plan Review (`aura:p4-plan`)

### Spawning Reviewers

Architect spawns **3 independent reviewers** in parallel (not sequentially).

Spawn reviewers as `general-purpose` subagents (via the Task tool, `subagent_type: "general-purpose"`) and instruct each to invoke the `/aura:reviewer` skill to load its role instructions. `/aura:reviewer` is a **Skill** (invoked via the Skill tool), not a subagent type — it provides the reviewer's workflow, severity tree, and voting procedures. Reviewers are short-lived — keep them in-session for direct result collection. Do NOT use the deprecated swarm orchestration CLI for reviewer rounds.

> **CRITICAL: No Fake Reviews**
>
> The architect **MUST** spawn actual independent reviewer subagents. The architect **CANNOT**:
> - Write review comments pretending to be reviewers
> - Simulate votes by adding comments from the same actor
> - Skip the review phase by self-approving
>
> If the architect lacks permission to spawn subagents, it **MUST** ask the user for help rather than faking reviews. Reviews from the same actor do not count as independent consensus.

**Reviewer Selection:**
- **Plan Review (Phase 4):** Use generic end-user alignment perspective (NOT technical specialization)
- **Code Review (Phase 10):** Optional specialized reviewers (security, performance, etc.)

### Review Criteria (6 Questions)

Each reviewer assesses **end-user alignment**, not technical taste:

1. **Who are the end-users?** Can you name them?
2. **What do end-users want?** What problem does this solve for them?
3. **How will this affect them?** Positively? Any downsides?
4. **Are there implementation gaps?** Will the code actually deliver what's promised?
5. **Does MVP scope make sense?** Is it achievable without taking on too much?
6. **Is validation checklist complete?** Can each item be tested independently?

### Voting: ACCEPT vs REVISE (Binary Only)

| Vote | Requirement |
|------|-------------|
| **ACCEPT** | All 6 criteria satisfied; no BLOCKER items |
| **REVISE** | BLOCKER issues found; must provide actionable feedback (not just criticism) |

**Plan reviews do NOT use a severity tree.** Plan reviews use binary ACCEPT/REVISE votes only. The severity tree is reserved for code reviews (Phase 10).

**Documentation (via attributed Pasture comments):**
```bash
pasture task comment add "$TASK_URI" "VOTE: ACCEPT - [reason]" --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
# OR
pasture task comment add "$TASK_URI" "VOTE: REVISE - [specific issue]. Suggest: [fix]" --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
```

### Revision Loop

If any reviewer votes REVISE:

1. Architect reads feedback in task comments
2. Creates PROPOSAL-N+1 task (increment N) with fixes
3. Marks PROPOSAL-N as `aura:superseded` with a comment explaining why
4. Re-spawns all 3 reviewers to re-assess the new proposal
5. Loop until all 3 vote ACCEPT

**Max Revision Rounds:** No hard limit; use common sense. If > 3 rounds, escalate to user for decision.

**Next (All 3 ACCEPT):** Proceed to Phase 5 (Plan UAT)

See: [../reviewer/SKILL.md](../reviewer/SKILL.md)

---

## Phase 5: Plan UAT (`aura:p5-user`)

### User Approval (Required!)

**DO NOT auto-proceed.** Present the accepted proposal to the user for explicit approval.

The idea here is: the plan and the implementation MUST match with the user's end vision for the project.
The architect should also plan out several MVP milestones, in order to reach the user's vision.

**Questions must split the engineering design space on its ambiguous boundaries
to extract maximum information — like a decision tree, where each question
bisects the remaining uncertainty.** Questions must NOT be general.

**BAD example:**
> "exactly matches feedback, mostly matches feedback, requires revisions, ..."
> "Does this match your vision?" with options like "Yes exactly", "Mostly", "No"

These fail because the options are approval levels, not engineering alternatives.
They don't help the architect make better decisions.

**GOOD example:**
> "Should this be statically-allocated or allocated at runtime? Static: catches
> errors at compile time, more boilerplate. Dynamic: flexible, errors at runtime."
>
> "Which of these variants we chose are appropriate, and why? Variant 1, main
> tradeoffs: ...; Variant N, ...."
>
> "Should runtime deps be baked into the Nix wrapper (hermetic, reproducible) or
> expected from PATH (lighter, user-managed)?"

Each option must be a real engineering alternative with specific tradeoffs.
The user's choice should directly inform the implementation.

**Structure questions as a decision tree:** highest-leverage boundaries first
(1-2 questions per AskUserQuestion call), then dependent decisions informed by
prior answers. Later questions should depend on earlier answers.

User should be prompted with multiSelect, because the user can choose multiple tradeoffs/design choices.

The user should NOT be prompted with all questions at once, about all components. The user MUST be shown snippets of the definition, the implementation, and a motivating example. Then they should be asked several critical questions about one component at a time.

See [UAT_TEMPLATE.md](UAT_TEMPLATE.md) for the structured output format and
[UAT_EXAMPLE.md](UAT_EXAMPLE.md) for a worked example of this question quality.

If user requests changes: Loop back to Phase 3 (architect revises as new PROPOSAL-N).
If user approves: Proceed to Phase 6 (Ratification).

See: [UAT_TEMPLATE.md](UAT_TEMPLATE.md) for the structured UAT output template.

---

## Phase 6: Ratification (`aura:p6-plan`)

### Consensus Requirement

**All 3 reviewers must vote ACCEPT AND user must approve via UAT.** No exceptions.

### Superseding Old Proposals

When a proposal is ratified, all previous proposals are marked as superseded:

```bash
# Mark old proposal as superseded (additive label + attributed comment)
pasture task label add "$OLD_PROPOSAL_URI" aura:superseded --namespace "$PASTURE_NAMESPACE"
pasture task comment add "$OLD_PROPOSAL_URI" "Superseded by PROPOSAL-N ($NEW_PROPOSAL_URI)" \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
```

### Creating Ratified Version

```bash
# Add ratify label to the accepted proposal
pasture task label add "$PROPOSAL_URI" aura:p6-plan:s6-ratify --namespace "$PASTURE_NAMESPACE"
pasture task comment add "$PROPOSAL_URI" "RATIFIED: All 3 reviewers ACCEPT, UAT passed ($UAT_URI)." \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"

# Link to request:
pasture task dep add "$REQUEST_URI" --blocked-by "$PROPOSAL_URI" --namespace "$PASTURE_NAMESPACE"
```

**Next:** Proceed to Phase 7 (Handoff)

See: [../architect-ratify/SKILL.md](../architect-ratify/SKILL.md)

---

## Phase 7: Handoff (`aura:p7-plan`)

### Architect → Supervisor Handoff

The architect creates a handoff document with full inline provenance and transfers ownership to the supervisor.

**Storage:** `.git/.aura/handoff/{request-task-id}/architect-to-supervisor.md`

```bash
HANDOFF_URI=$(pasture task create "HANDOFF: Architect → Supervisor for REQUEST" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  urd: {{urd-task-uri}}
  proposal: {{ratified-proposal-uri}}
---
Handoff from architect to supervisor. See handoff document at
.git/.aura/handoff/{{request-task-id}}/architect-to-supervisor.md" --format json | jq -er '.id')
pasture task label add "$HANDOFF_URI" aura:p7-plan:s7-handoff --namespace "$PASTURE_NAMESPACE"
```

### All 6 Handoff Transitions

| # | From | To | When | Content Level |
|---|------|----|------|---------------|
| 1 | Architect | Supervisor | Phase 7 | Full inline provenance |
| 2 | Supervisor | Worker | Phase 9 (slice assignment) | Summary + task URIs |
| 3 | Supervisor | Reviewer | Phase 10 (code review) | Summary + task URIs |
| 4 | Worker | Reviewer | Phase 10 (code review) | Summary + task URIs |
| 5 | Reviewer | Followup | After Phase 10 | Summary + task URIs |
| 6 | Supervisor | Architect | Follow-up lifecycle (FOLLOWUP_URE/URD → FOLLOWUP_PROPOSAL) | Summary + task URIs |

**Same-actor transitions do NOT need handoff:** UAT → Ratify and Ratify → Handoff are performed by the same actor (architect).
In the follow-up lifecycle, the supervisor creating FOLLOWUP_URE and then FOLLOWUP_URD are also same-actor transitions (no handoff needed).

See: [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md) for the standardized template.

---

## Phase 8: Implementation Plan (`aura:p8-impl`)

### Overview

Supervisor takes the ratified proposal and decomposes into **vertical slices** (production code paths).

**Key Principle:** Each worker owns a full vertical slice — types, tests, implementation, and wiring for one production code path.

**Supervisor startup sequence:**
1. Call `Skill(/aura:supervisor)` to load role instructions
2. Read RATIFIED_PLAN and URD via `pasture task show`
3. **Spawn ephemeral Explore subagents** via Task tool for scoped codebase queries — each subagent is short-lived and returns findings
4. Decompose into vertical slices
5. **Identify horizontal Layer Integration Points** — contracts shared across slices (see Layer Integration Points below)
6. **Create leaf tasks (L1/L2/L3) for every slice** — a slice without leaf tasks is undecomposed
7. Spawn workers for leaf tasks

```
Layer 0: Shared infrastructure (common types, enums — optional, parallel)
   ↓
Vertical Slices (parallel, each worker owns one slice):
  Layer 1: Types for this slice
  Layer 2: Tests importing production code (will FAIL — expected!)
  Layer 3: Implementation + wiring (makes tests PASS)
   ↓
IMPLEMENTATION COMPLETE
```

### Ephemeral Explore and Review Agents

The supervisor spawns **ephemeral Explore subagents** via the Task tool for scoped codebase queries during Phase 8. Each subagent is short-lived and returns findings — no standing team overhead.

- **Phase 8:** Spawn Explore subagents as needed for codebase mapping. Each handles a scoped query and terminates after returning results.
- **Phase 10:** Spawn ephemeral reviewers via Task tool for per-slice code review. Each reviewer handles one or more slices and terminates after producing severity groups.

There is no standing team that persists across phases. Each exploration or review need spawns fresh ephemeral agents.

### Layer Integration Points

When slices share types, interfaces, or data flows, the supervisor MUST identify **horizontal Layer Integration Points** in the IMPL_PLAN. These are contracts where one slice exports something another slice imports.

**Rule: merge sooner, not later.** Divergence grows with delay. If SLICE-1 defines a type that SLICE-2 and SLICE-3 consume, SLICE-1 must complete its L1 (types) layer before SLICE-2 and SLICE-3 begin their L1.

**Include an integration points table in the IMPL_PLAN body:**

| ID | Contract | Owner (exports) | Consumer(s) (imports) | Merge Timing |
|----|----------|-----------------|----------------------|--------------|
| IP-1 | PhaseEnum type | SLICE-1 | SLICE-2, SLICE-3 | L1 (types) |
| IP-2 | EpochService interface | SLICE-2 | SLICE-3, SLICE-4 | L2 (tests) |

If no integration points exist, include an empty table with a note: "No cross-slice contracts identified."

### IMPL_PLAN Task

```bash
IMPL_PLAN_URI=$(pasture task create "IMPL_PLAN: Vertical slice decomposition" \
  --namespace "$PASTURE_NAMESPACE" --type epic --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  urd: {{urd-task-uri}}
  proposal: {{ratified-proposal-uri}}
---
Supervisor's breakdown of ratified plan into slices" --format json | jq -er '.id')
pasture task label add "$IMPL_PLAN_URI" aura:p8-impl:s8-plan --namespace "$PASTURE_NAMESPACE"
```

**Body includes:**
- Vertical slice structure (which production code path per slice)
- Dependencies between slices (if any)
- Worker assignments
- Reference to ratified proposal in description frontmatter

---

## Phase 9: Worker Slices (`aura:p9-impl`)

### Creating SLICE-N Tasks

**One task per production code path.** Each worker owns the full vertical:

```bash
SLICE_URI=$(pasture task create "SLICE-1: Implement logging infrastructure (full vertical)" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "---
references:
  impl_plan: {{impl-plan-task-uri}}
  urd: {{urd-task-uri}}
---
## Design
{validation_checklist: [...], acceptance_criteria: [...]}
..." --format json | jq -er '.id')
pasture task label add "$SLICE_URI" aura:p9-impl:s9-slice --namespace "$PASTURE_NAMESPACE"
```

Link dependency:
```bash
pasture task dep add "$IMPL_PLAN_URI" --blocked-by "$SLICE_URI" --namespace "$PASTURE_NAMESPACE"
```

### Creating Leaf Tasks Within Each Slice

**A slice without leaf tasks is undecomposed.** The supervisor MUST create Pasture leaf tasks for each horizontal layer within the slice. Workers are assigned to leaf tasks, not slices directly.

```bash
# L1: Types for this slice
LEAF_L1=$(pasture task create "SLICE-1-L1: Types — {{slice name}}" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "..." --format json | jq -er '.id')
pasture task label add "$LEAF_L1" aura:p9-impl:s9-slice --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$SLICE_URI" --blocked-by "$LEAF_L1" --namespace "$PASTURE_NAMESPACE"

# L2: Tests (will fail until L3)
LEAF_L2=$(pasture task create "SLICE-1-L2: Tests — {{slice name}}" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "..." --format json | jq -er '.id')
pasture task label add "$LEAF_L2" aura:p9-impl:s9-slice --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$SLICE_URI" --blocked-by "$LEAF_L2" --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$LEAF_L2" --blocked-by "$LEAF_L1" --namespace "$PASTURE_NAMESPACE"   # L2 depends on L1

# L3: Implementation (makes tests pass)
LEAF_L3=$(pasture task create "SLICE-1-L3: Impl — {{slice name}}" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "..." --format json | jq -er '.id')
pasture task label add "$LEAF_L3" aura:p9-impl:s9-slice --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$SLICE_URI" --blocked-by "$LEAF_L3" --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$LEAF_L3" --blocked-by "$LEAF_L2" --namespace "$PASTURE_NAMESPACE"   # L3 depends on L2
```

The resulting tree per slice:

```
IMPL_PLAN
  └── blocked by SLICE-1
        ├── blocked by SLICE-1-L1: Types    (no deps)
        ├── blocked by SLICE-1-L2: Tests    (blocked by L1)
        └── blocked by SLICE-1-L3: Impl     (blocked by L2)
```

Workers are assigned to leaf tasks. The slice closes when all its leaf tasks close.

<!-- ADAPT: Replace quality gate commands with your project's equivalents -->

**Task body (canonical schema, placed in the description):**

```json
{
  "productionCodePath": "tool feature list",
  "validation_checklist": [
    "Type checking passes",
    "Tests pass",
    "Production code path implemented (not test-only export)",
    "Tests verify actual production code",
    "All TODO placeholders replaced with working code",
    "Production code verified via code inspection"
  ],
  "acceptance_criteria": [
    {
      "given": "user runs tool feature list",
      "when": "command executes",
      "then": "shows feature list from actual service",
      "should_not": "have dual-export (test vs production paths)"
    }
  ],
  "tradeoffs": [
    {
      "decision": "chosen approach",
      "rationale": "why this over alternatives"
    }
  ],
  "ratified_plan": "<task-id>"
}
```

### Layer 1: Types & Interfaces (Within Each Slice)

**Purpose:** Define public contracts (types, enums, interfaces, schemas) for this slice only.

**Quality Gate:** Type checking passes.

### Layer 2: Tests (Within Each Slice)

**CRITICAL:** Tests will FAIL in Layer 2. This is **correct and expected**.

**Tests must import production code paths:**

**Given** Layer 2 tests **when** writing **then** import actual production code (CLI/API/entry points) **should never** create test-only exports or dual code paths

Tests define what production code should do. When Layer 3 implements production code, these tests should pass.

**CORRECT — import actual production code:**
```
import the_actual_cli_command_or_api_handler
test that it does what end users expect
→ FAILS (expected, no implementation yet)
```

**WRONG — dual-export anti-pattern:**
```
import a test_only_export_of_internal_handler
mock out the system under test
→ PASSES but doesn't test what users actually run
```

### Layer 3: Implementation (Within Each Slice)

**Purpose:** Write code to make Layer 2 tests pass **using production code paths**.

**Given** Layer 3 implementation **when** implementing **then** wire production code together (service instantiation, CLI/API actions) **should never** leave TODO placeholders or create dual exports

**Critical:** Layer 3 is where you wire production code together:
- Create service instances with real dependencies
- Wire services into CLI commands / API handlers
- Ensure the code path users run is the code path tests verify

**Anti-pattern check:**

**Given** Layer 3 complete **when** tests pass but production code has TODOs **then** implementation is incomplete **should never** have dual-export (test vs production paths)

**Quality Gates:**
```bash
# Run your project's type checking and test commands
# Verify production code path via code inspection:
# - No TODO placeholders
# - Real dependencies wired (not mocks in production code)
# - Tests import production code (not test-only export)
```

### Ride the Wave — Worker Persistence

**Ride the Wave** is the execution model for Phases 8-10: workers implement slices, ephemeral reviewers review them per-slice, workers fix findings — all in a coordinated cycle.

**Worker persistence rules:**

- Workers do **NOT** shut down after completing implementation
- When implementation is complete, workers signal via an attributed Pasture comment (not `pasture task close`):
  ```bash
  pasture task comment add "$SLICE_URI" "Implementation complete, awaiting review" \
    --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
  ```
- Workers stay alive for the review-fix cycle — ephemeral reviewers will review their work and may send findings back
- Workers wait for review feedback and fix any BLOCKERs or IMPORTANT findings assigned to them
- The supervisor receives completion notifications but does **NOT** close the slice

### Slice Closure Rules

- Slices **MUST NOT** be closed by workers immediately upon implementation completion
- A slice must be reviewed **at least once** by ephemeral reviewers before it can close
- **Only the supervisor closes slices**, after review passes (Phase 10) or after 3 review-fix cycles complete
- Workers who finish implementation stay alive and await review feedback before the session ends

---

## Phase 10: Code Review (`aura:p10-impl`)

### Overview

After all slices complete, the supervisor spawns **ephemeral reviewers** via the Task tool for per-slice code review. Each reviewer handles one or more slices, produces severity groups using the **full severity tree** with EAGER creation, and terminates. The supervisor then coordinates the review-fix cycle with workers.

### Review-Fix Cycle (Max 3 per Slice)

Phase 10 runs up to **3 review-fix cycles per slice**. Workers do not shut down — they await findings and fix them in-place.

**Cycle procedure:**

1. **Ephemeral reviewers review all slices** — create severity groups (BLOCKER/IMPORTANT/MINOR) for each slice per the EAGER creation protocol
2. **Supervisor collects findings** — aggregates BLOCKERs and IMPORTANTs across all slices; sends findings to the relevant workers
3. **Workers fix BLOCKERs + IMPORTANTs** — workers address assigned findings with atomic commits and notify the supervisor when done
4. **New ephemeral reviewers re-review fixed slices** — create new severity groups for the new round (round suffix increments: `-1`, `-2`, `-3`)
5. **Repeat** — max 3 cycles per slice

**Cycle exit conditions:**

| Condition | Action |
|-----------|--------|
| All slices ACCEPT, 0 BLOCKERs + 0 IMPORTANTs | Proceed to Phase 11 (Implementation UAT) |
| BLOCKERs or IMPORTANTs remain, cycles < 3 per slice | Workers fix, spawn new ephemeral reviewers (next cycle) |
| 3 cycles exhausted, IMPORTANT remain | Track in FOLLOWUP epic; proceed to Phase 11 |
| 3 cycles exhausted, only MINOR remain | Track in FOLLOWUP epic; proceed to Phase 11 |
| 3 cycles exhausted per slice, BLOCKERs remain | **Escalate to architect** for re-planning |

After cycle 3: UAT is **NOT blocked** on remaining IMPORTANT or MINOR findings. The supervisor creates the FOLLOWUP epic to track them, then proceeds to Phase 11.

### Severity Tree (EAGER Creation)

**ALWAYS create 3 severity group tasks per review round**, even if some groups have no findings:

```bash
# Create all 3 severity groups immediately (EAGER, not lazy). Bind each URI from
# its own create output, then add its labels in a second command each.
BLOCKER_GROUP=$(pasture task create "SLICE-1-REVIEW-A-1 BLOCKER" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "Severity group for SLICE-1 review round A-1" --format json | jq -er '.id')
pasture task label add "$BLOCKER_GROUP" aura:severity:blocker --namespace "$PASTURE_NAMESPACE"
pasture task label add "$BLOCKER_GROUP" aura:p10-impl:s10-review --namespace "$PASTURE_NAMESPACE"
# Repeat for IMPORTANT (aura:severity:important) and MINOR (aura:severity:minor).

# Empty groups are closed immediately (supervisor only)
pasture task close "$EMPTY_IMPORTANT_URI" --reason "No findings in this severity group" --namespace "$PASTURE_NAMESPACE"
pasture task close "$EMPTY_MINOR_URI" --reason "No findings in this severity group" --namespace "$PASTURE_NAMESPACE"
```

### Dual-Parent BLOCKER Relationship

BLOCKER findings have **two parents**:
1. The severity group task (`aura:severity:blocker`) — for categorization
2. The slice they block — for dependency tracking

```bash
# BLOCKER finding blocks both the severity group and the slice
pasture task dep add "$BLOCKER_GROUP" --blocked-by "$BLOCKER_FINDING_URI" --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$SLICE_URI" --blocked-by "$BLOCKER_FINDING_URI" --namespace "$PASTURE_NAMESPACE"
```

### Severity Group Dependency Routing (CRITICAL)

Each severity group is linked to exactly one parent based on its level:

| Severity | Blocks | Command |
|----------|--------|---------|
| BLOCKER | The **slice** it applies to | `pasture task dep add "$SLICE_URI" --blocked-by "$BLOCKER_GROUP"` |
| IMPORTANT | The **FOLLOWUP epic** only | `pasture task dep add "$FOLLOWUP_EPIC_URI" --blocked-by "$IMPORTANT_GROUP"` |
| MINOR | The **FOLLOWUP epic** only | `pasture task dep add "$FOLLOWUP_EPIC_URI" --blocked-by "$MINOR_GROUP"` |

**NEVER link IMPORTANT or MINOR severity groups as blocking IMPL_PLAN or any slice.** Only BLOCKER findings block the implementation path. IMPORTANT and MINOR findings are non-blocking improvements tracked in the follow-up epic.

### Follow-up Epic

**Trigger:** Review completion + ANY IMPORTANT or MINOR findings exist.
**NOT gated on BLOCKER resolution.**
**Owner:** Supervisor creates it.

```bash
FOLLOWUP_EPIC=$(pasture task create "FOLLOWUP: Non-blocking improvements from code review" \
  --namespace "$PASTURE_NAMESPACE" --type epic --priority low \
  --description "---
references:
  request: {{request-task-uri}}
  review_round: {{review-task-uris}}
---
Aggregated IMPORTANT and MINOR findings from code review." --format json | jq -er '.id')
pasture task label add "$FOLLOWUP_EPIC" aura:epic-followup --namespace "$PASTURE_NAMESPACE"

# Route IMPORTANT and MINOR to FOLLOWUP (NOT to IMPL_PLAN or slices)
pasture task dep add "$FOLLOWUP_EPIC" --blocked-by "$IMPORTANT_GROUP" --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$FOLLOWUP_EPIC" --blocked-by "$MINOR_GROUP" --namespace "$PASTURE_NAMESPACE"
```

The follow-up epic is created as soon as the review round completes, regardless of whether BLOCKERs are still being resolved. This ensures non-blocking improvements are tracked and not lost.

**After 3 review-fix cycles:** Any remaining IMPORTANT and MINOR findings both route to the FOLLOWUP epic. UAT proceeds immediately — it is NOT blocked on IMPORTANT or MINOR findings after cycle 3. The supervisor creates the FOLLOWUP epic and then advances to Phase 11.

### Follow-up Lifecycle (FOLLOWUP_* Phases)

The follow-up epic runs the same protocol phases with FOLLOWUP_* prefixed task types. This is NOT a flat task list — it is a full protocol re-run:

```
FOLLOWUP epic (aura:epic-followup)
  └── blocked-by: FOLLOWUP_URE         (Phase 2: scope which findings to address)
        └── blocked-by: FOLLOWUP_URD   (Phase 2: requirements for follow-up)
              └── blocked-by: FOLLOWUP_PROPOSAL-1  (Phase 3: proposal for follow-up)
                    └── blocked-by: FOLLOWUP_IMPL_PLAN  (Phase 8: decompose into slices)
                          ├── blocked-by: FOLLOWUP_SLICE-1  (Phase 9)
                          │     ├── blocked-by: important-leaf-task-...
                          │     └── blocked-by: minor-leaf-task-...
                          └── blocked-by: FOLLOWUP_SLICE-2
```

**Lifecycle steps:**
1. **Supervisor** creates FOLLOWUP_URE (same actor — scoping URE with user to determine which findings to address)
2. **Supervisor** creates FOLLOWUP_URD (same actor — requirements for follow-up scope)
3. **Supervisor → Architect (h6):** Hands off FOLLOWUP_URE + FOLLOWUP_URD to architect for FOLLOWUP_PROPOSAL creation
4. **Architect** creates FOLLOWUP_PROPOSAL-N (same review/ratify/UAT cycle applies)
5. **Architect → Supervisor (h1):** After FOLLOWUP_PROPOSAL ratified, hands off for FOLLOWUP_IMPL_PLAN
6. **Supervisor → Worker (h2):** FOLLOWUP_SLICE-N assignment with adopted leaf task IDs
7. **Supervisor → Reviewer (h3):** Code review of follow-up slices
8. **Worker → Reviewer (h4):** Follow-up slice completion, reports which original leaf tasks resolved

**Leaf task adoption (dual-parent):** When the supervisor creates FOLLOWUP_SLICE-N, the original IMPORTANT/MINOR leaf tasks gain a second parent — they are children of both the original severity group AND the follow-up slice.

**No followup-of-followup:** IMPORTANT/MINOR findings from follow-up code review are tracked on the existing follow-up epic. A nested follow-up epic is never created.

### Voting

Same binary voting as plan review: ACCEPT or REVISE.

All BLOCKERs and IMPORTANTs must be resolved before proceeding (clean exit = 0 BLOCKERs + 0 IMPORTANTs). MINOR findings go to follow-up epic.

**Next (0 BLOCKERs + 0 IMPORTANTs, all reviewers ACCEPT):** Proceed to Phase 11 (Implementation UAT)

---

## Phase 11: Implementation UAT (`aura:p11-user`)

### User Approval

Present the completed implementation to the user for explicit approval, similar to Phase 5 but for code.

```bash
IMPL_UAT_URI=$(pasture task create "UAT: Implementation acceptance for feature" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  urd: {{urd-task-uri}}
  impl_plan: {{impl-plan-task-uri}}
---
Implementation UAT" --format json | jq -er '.id')
pasture task label add "$IMPL_UAT_URI" aura:p11-user:s11-uat --namespace "$PASTURE_NAMESPACE"
```

If user approves: Proceed to Phase 12 (Landing).
If user requests changes: Loop back to appropriate phase.

---

## Phase 12: Landing (`aura:p12-impl`)

See [Session Completion](#session-completion-landing-the-plane) below.

---

## Worker Implementation Details

### Before Starting

Read your Pasture task completely:
```bash
pasture task show "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
```

Extract:
- `validation_checklist` - items you must verify
- `acceptance_criteria` - Given/When/Then specs you must satisfy
- `tradeoffs` - why certain decisions were made
- `ratified_plan` - link to larger context

### TDD Awareness

- **Layer 2 tests will fail** - this is normal until Layer 3 implementation exists
- **Layer 3 tests must pass** - if your implementation doesn't pass, it's not done
- **Don't fight TDD** - tests define the contract; implement to satisfy tests

### Implementation Checklist

- [ ] Read the full Pasture task with `pasture task show`
- [ ] Understand validation_checklist and acceptance_criteria
- [ ] Modify ONLY your assigned files (file-level ownership within your slice)
- [ ] Inject all dependencies (constructor DI, never hard-code)
- [ ] Validate external input at system boundaries
- [ ] Run type checking (must pass)
- [ ] Run tests (must pass)
- [ ] Keep the task in progress and record evidence (`pasture task comment add ... --author "$PASTURE_AUTHOR"`); workers never close tasks

### Blockers

If you can't proceed:

```bash
pasture task update "$TASK_URI" --notes="Blocked: Missing type definition. Waiting for: {{dependency-uri}}" --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$TASK_URI" --blocked-by "$DEPENDENCY_URI" --namespace "$PASTURE_NAMESPACE"
pasture task comment add "$TASK_URI" "Blocked: {{reason}}" --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
```

Supervisor reads the tracker, resolves, or reassigns. There is no `blocked` status — a blocker is a note plus a `blocked_by` edge.

See: [../worker-blocked/SKILL.md](../worker-blocked/SKILL.md)

---

## Quality Assurance Throughout

### When to Run Tests

| Phase | What to Run | Must Pass? |
|-------|-------------|-----------|
| **L1: Types** | Type checking | **YES** |
| **L2: Tests** | Tests | NO (will fail) |
| **L3: Implementation** | Type checking + tests | **YES** |
| **Integration** | Integration tests | **YES** |
| **Before Commit** | All applicable | **YES** |

### Interpreting Failures

**Layer 2 Test Failures:**
- Expected! Tests import non-existent implementation.
- Proceed to Layer 3.
- Do NOT fix Layer 2 tests until Layer 3 exists.

**Layer 3 Test Failures After Implementation:**
- Your implementation is incomplete or wrong.
- Check `acceptance_criteria` - are all conditions met?
- Fix implementation to make tests pass.

**Failures in Unrelated Tests:**
- Example: You implemented feature X, but unrelated feature Y tests fail.
- This is NOT a blocker for your task (other workers own Y).
- Supervisor decides if layer continues or rollback.

### Rollback/Recovery

If a layer fails catastrophically:

```bash
# Revert commits:
git revert <commit-hash>

# Record the rollback in the tracker (supervisor):
pasture task update "$LAYER_TASK_URI" --status open --notes="Layer rolled back due to X. Reassigning..." --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$LAYER_TASK_URI" --blocked-by "$DEPENDENCY_URI" --namespace "$PASTURE_NAMESPACE"
```

Supervisor reassigns or revises approach.

---

## Monitoring & Status

### Check Progress Anytime

```bash
# Overall project health (derive counts locally from one namespaced read):
pasture task list --namespace "$PASTURE_NAMESPACE" --format json | jq 'group_by(.status) | map({status: .[0].status, count: length})'

# What's currently in progress:
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice --status in_progress

# What's blocked (not namespace-scoped; inspect returned URIs):
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice --status open
pasture task blocked

# What's ready (for supervisor; not namespace-scoped):
pasture task ready

# Active proposals (not yet ratified):
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p3-plan:s3-propose --status open

# Ratified plans awaiting implementation:
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p6-plan:s6-ratify --status open
```

### Tracker Query Reference

```bash
# Find all REQUEST tasks:
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p1-user:s1_1-classify

# Find all PROPOSAL-N in open status:
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p3-plan:s3-propose --status open

# Find implementation slices:
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice

# For your assignment, obtain the full task URI from the supervisor's handoff.
# There is no assignee query flag; a name in a title is not assignment evidence.
pasture task show "$TASK_URI" --namespace "$PASTURE_NAMESPACE"

# Get detailed view:
pasture task show "$TASK_URI" --namespace "$PASTURE_NAMESPACE"

# Find severity groups for a review:
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:severity:blocker
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:severity:important
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:severity:minor

# Find follow-up epics:
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:epic-followup
```

See [TRACKER.md](TRACKER.md) and [../status/SKILL.md](../status/SKILL.md) for the full supported query set.

---

## Coordination via Pasture

All inter-agent coordination happens through Pasture task status and attributed comments.

### Message Patterns

Assignment transfer requires an existing active owner assignment and the exact
successor assignment ID, registered committing actor and registered worker
occupant supplied by the supervisor. If a task is unassigned, stop and ask the
supervisor to arrange allocation; no assignment-start/list command is implied.

| Pattern | How | When |
|---------|-----|------|
| Task assignment | `pasture task assignment transfer "$TASK_URI" --slot owner-responsibility --assignment "$ASSIGNMENT_ID" --actor "$ACTOR_ID" --occupant "$OCCUPANT_ID" --namespace "$PASTURE_NAMESPACE"` | Supervisor transfers an existing active owner assignment; this is not initial allocation |
| Task progress | `pasture task comment add "$TASK_URI" "Done: ..." --author "$PASTURE_AUTHOR"` | Worker reports progress (never closes) |
| Task blocked | `pasture task dep add "$TASK_URI" --blocked-by "$DEPENDENCY_URI"` + a note | Worker is stuck |
| Review request | `pasture task comment add "$TASK_URI" "Review requested" --author "$PASTURE_AUTHOR"` | Architect asks for review |
| Review vote | `pasture task comment add "$TASK_URI" "VOTE: ACCEPT - reason" --author "$PASTURE_AUTHOR"` | Reviewer votes |
| State change | `pasture task comment add "$TASK_URI" "Phase 9 complete, proceeding to Phase 10" --author "$PASTURE_AUTHOR"` | Supervisor announces |
| Supersede | `pasture task label add "$OLD_PROPOSAL_URI" aura:superseded` + an attributed comment | Architect supersedes old proposal |

Every comment carries an explicit `--author` (machine automation uses
`$PASTURE_AUTHOR`). Nothing is deleted; labels and comments are additive.

### Supervisor Monitoring Loop

Supervisor continuously:

1. **Check the tracker for status updates:**
   ```bash
   pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice --status closed
   pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice --status in_progress
   pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice --status open
   ```

2. **Review comments for progress:**
   ```bash
   pasture task comments "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
   ```

3. **Decide next action:**
   - All slices done? → Proceed to Phase 10 (Code Review)
   - Some tasks blocked? → Resolve or reassign
   - Some tasks in progress? → Wait (don't block them)

4. **Repeat** until all slices complete

See: [../supervisor-track-progress/SKILL.md](../supervisor-track-progress/SKILL.md)

---

## Session Completion (Landing the Plane)

**Before you can say "done", you MUST complete this 7-step checklist:**

### 1. File Issues for Remaining Work

Create Pasture tasks for anything discovered but not completed:

```bash
FOLLOWUP_URI=$(pasture task create "Follow-up: ..." --namespace "$PASTURE_NAMESPACE" --type task --priority low --format json | jq -er '.id')
```

### 2. Run Quality Gates

If code changed, run your project's quality gates. All must pass.

### 3. Update Issue Status

- Supervisor closes completed work after review: `pasture task close "$TASK_URI" --reason "..." --namespace "$PASTURE_NAMESPACE"`
- Record progress: `pasture task comment add "$TASK_URI" "..." --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"`
- Update notes: `pasture task update "$TASK_URI" --notes "..." --namespace "$PASTURE_NAMESPACE"`

### 4. Commit and Push (push only with approval)

```bash
git add <changed-files>
git agent-commit -m "feat(scope): Description of changes"
pasture task comment add "$TASK_URI" "Landed: <commit sha>; evidence: <pointer>" \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
git pull --rebase
git push    # only with explicit approval
```

There is no tracker sync step — store writes are already durable, and Git history lands separately.

**Verify success:**
```bash
git status
# Must show: "Your branch is up to date with 'origin/...'"
```

### 5. Clean Up

```bash
# Clear stashes:
git stash clear

# Prune remote branches (optional):
git fetch --prune
```

### 6. Verify

```bash
git log --oneline -5  # Confirm commits are there
git push --dry-run     # Verify push would succeed
```

### 7. Hand Off

Create handoff document if actor transition occurs (see [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md)). Provide context for next session:
- Link to ratified plan (if applicable)
- Current phase (use phase number and label)
- Blockers or next steps
- Link to open issues

---

## Troubleshooting Decision Trees

### "My reviewer is stuck - keeps voting REVISE"

```
├─ Have you provided ACTIONABLE feedback?
│  └─ NO → Give specific suggestions, not just criticism
│  └─ YES → Continue
│
├─ Is feedback valid (aligns with acceptance_criteria)?
│  └─ NO → Explain why feedback is out of scope (respectfully)
│  └─ YES → Architect revises (creates PROPOSAL-N+1)
│
└─ > 3 revision rounds?
   └─ YES → Escalate to user: "Consensus not reachable. User decision needed."
   └─ NO → Continue revision loop
```

### "My worker reports TaskBlocked"

```
├─ Is the blocker valid?
│  └─ NO → Clarify why (update task); worker continues
│  └─ YES → Continue
│
├─ Can you resolve it?
│  ├─ YES → Create/unblock dependency task; notify worker
│  └─ NO → Reassign task to different worker; explain why
│
└─ Is blocker on critical path (blocks multiple workers)?
   └─ YES → Prioritize resolution
   └─ NO → Continue with other workers
```

### "Layer 2 tests are failing"

```
└─ Is this Layer 2 (test phase)?
   └─ YES → **EXPECTED!** Implementation doesn't exist yet.
   │        Proceed to Layer 3 immediately.
   │        Do NOT try to make tests pass in Layer 2.
   │
   └─ NO → Is this Layer 3+ (implementation phase)?
      └─ YES → This is a blocker. Implementation must make tests pass.
      └─ NO → Escalate; something is wrong with phase tracking
```

### "My layer has mixed success (some tasks done, some in progress)"

```
└─ Are all done tasks passing quality gates?
   └─ NO → Rerun failed tasks; don't proceed
   └─ YES → Continue
│
└─ Are blocked tasks on critical path (block other tasks)?
   └─ YES → Resolve blockers before proceeding to next layer
   └─ NO → Start next layer in parallel; return to blockers later
```

### "Tests are failing unrelated to my work"

```
└─ Is the failing test owned by another worker?
   └─ YES → Not your blocker. Notify supervisor; continue your work.
   │        Supervisor decides if layer continues or rollback.
   │
   └─ NO (owned by you) → Must resolve before marking task complete.
```

---

## Tools & Capabilities Matrix

### Architect Tools & Skills

| Tool | Purpose |
|------|---------|
| Explore | Map codebase, understand problem space |
| Read | Read existing code for context |
| Write, Edit | Document plan in the Pasture task body |
| Bash | Git operations, running tests |
| Skill: aura:architect:propose-plan | Create PROPOSAL-N task |
| Skill: aura:architect:request-review | Spawn reviewers |
| Skill: aura:architect:ratify | Ratify proposal (Phase 6) |
| Skill: aura:architect:handoff | Handoff to supervisor (Phase 7) |

### Reviewer Tools & Skills

| Tool | Purpose |
|------|---------|
| Read, Glob, Grep | Read proposal, search code |
| Bash | Run tests to verify claims |
| Skill: aura:reviewer:review-plan | Evaluate proposal (Phase 4) |
| Skill: aura:reviewer:review-code | Evaluate implementation (Phase 10) |
| Skill: aura:reviewer:vote | Cast vote (ACCEPT/REVISE) |
| Skill: aura:reviewer:comment | Leave structured review comment (via Pasture task comment) |

### Supervisor Tools & Skills

| Tool | Purpose |
|------|---------|
| Bash | Git operations, run tests, launch agents |
| Read | Read ratified plan |
| Skill: aura:supervisor:plan-tasks | Create vertical slice decomposition (Phase 8) |
| Skill: aura:supervisor:spawn-worker | Launch workers (Phase 9) |
| Skill: aura:supervisor:track-progress | Monitor slice completion |
| Skill: aura:supervisor:commit | Atomic commit per layer (Phase 12) |

**Agent launching:**
```bash
# Long-running supervisors/architects and short-lived reviewers are launched in
# the current session as role skills / Task-tool subagents:
#   - supervisor/architect: invoke the role skill in-session for the planning phases
#   - reviewers: spawn general-purpose subagents (Task tool) instructed to load /aura:reviewer
# The `aura-swarm` orchestration CLI is DEPRECATED and is not an approved
# invocation path; it is retained only as clearly deprecated history.
```

### Worker Tools & Skills

| Tool | Purpose |
|------|---------|
| Read, Write, Edit | Implement assigned files |
| Glob, Grep | Understand dependencies |
| Bash | Run type checking, tests |
| Skill: aura:worker:implement | Write code for task |
| Skill: aura:worker:complete | Signal task done |
| Skill: aura:worker:blocked | Report blocker |

---

## Migration from v1

For migrating in-flight epics from v1 labels and conventions to v2, see [MIGRATION_v1_to_v2.md](MIGRATION_v1_to_v2.md).

---

## See Also

- [CONSTRAINTS.md](CONSTRAINTS.md) - Coding standards, checklists, naming conventions
- [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md) - Standardized handoff document template
- [MIGRATION_v1_to_v2.md](MIGRATION_v1_to_v2.md) - Migration procedure from v1 to v2 labels
- `skills/` - Detailed agent role definitions
  - Architect: `aura:architect.md`
  - Reviewer: `aura:reviewer.md`
  - Supervisor: `aura:supervisor.md`
  - Worker: `aura:worker.md`
  - Cross-role: `aura:plan.md`, messaging, testing, status
