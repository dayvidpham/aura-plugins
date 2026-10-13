# Aura Protocol - Agent Directive

This is the reusable core agent directive for projects using the Aura protocol.
Copy or include this file in your project's CLAUDE.md alongside project-specific instructions.

The current Pasture-generated protocol and repository root AGENTS.md remain the
operative authority. Before tracker recipes, follow [TRACKER.md](TRACKER.md):
select the store, bind the explicit namespace and registered author, and bind
all task URI variables from actual create output or verified assignments/reads.

## System Philosophy

- What does the end-user need, and how will this tradeoff impact them?
- One of the primary design goals of each behaviour, interface, and API, is that they should be easily testable. This is usually done through creation of interfaces with a public API that you KNOW you will need in the end.
- Integration tests are of the most important value, though we want public behaviours to be unit testable.
- If things can be statically defined, then prefer this over runtime definitions and checking.
- Prefer using strongly-typed enums instead of stringly-typed API, return values, or arguments.
- Think about mapping the engineering design space of the specific problem along its axes:
    - how much parallelism do we have in this problem?
    - is it a distributed problem, or a sequential one?
    - do we need many of something, or one?
    - what are the has-a relationships in the problem, and what are the is-a relationships?
    - how often will this problem occur, and how much will it cost each time?

## Constraints

### Universal Code Quality

**Given** shared resources **when** modifying **then** use atomic operations with timeouts **should never** check-then-act

**Given** external input **when** parsing **then** validate at system boundaries with the project's schema/validation tooling **should never** trust raw input or cast types unsafely

**Given** parallel work **when** assigning files **then** ensure each file has exactly one owner with atomic commits **should never** have multiple workers on same file

**Given** a feature request **when** writing requirements **then** use Given/When/Then/Should,Should Not format **should never** write vague criteria

**Given** a class or struct with dependencies **when** designing **then** inject all deps (including clocks, loggers) **should never** hard-code

**Given** runtime events **when** logging **then** use structured logging with context **should never** log secrets or use unstructured print statements

**Given** status/type fields **when** defining **then** use strongly-typed enums **should never** use bare strings at API boundaries

**Given** code changes **when** committing **then** type checking and tests must pass **should never** allow optional CI

### Git & Pasture Tracker

**Given** task is implemented **when** you are about to commit **then** you **should** use `git agent-commit -m ...`, **should never** use `git commit -m ...`

**Given** you want to execute a Pasture tracker command **when** you are about to call `pasture task <verb> ...` **then** you **should** pass the explicit `--namespace` and full task URIs, **should never** `cd <repo_root> && pasture task ...` or rely on an implicit namespace or unbound legacy ID

**Given** you are adding a Pasture dependency **when** determining the direction **then** the **parent** (plan, request, epic) is blocked by the **child** (implementation, proposal, task). The parent stays open until the child resolves it. **MUST** use `pasture task dep add "$PARENT_URI" --blocked-by "$CHILD_URI"`. **SHOULD NEVER** make the child blocked by the parent — that inverts the relationship and means the child can't start until the parent closes, which is backwards.

**The rule:** Ask "which one stays open until the other finishes?" That one is the parent. `pasture task dep add "$STAYS_OPEN_URI" --blocked-by "$MUST_FINISH_FIRST_URI"`.

### Correct: `--blocked-by` points at what must finish first

```bash
# "REQUEST is blocked by URE" — URE must complete before REQUEST can close
pasture task dep add "$REQUEST_URI" --blocked-by "$URE_URI" --namespace "$PASTURE_NAMESPACE"

# "PROPOSAL is blocked by IMPL PLAN"
pasture task dep add "$PROPOSAL_URI" --blocked-by "$IMPL_PLAN_URI" --namespace "$PASTURE_NAMESPACE"

# "IMPL PLAN is blocked by each slice"
pasture task dep add "$IMPL_PLAN_URI" --blocked-by "$SLICE_1_URI" --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$IMPL_PLAN_URI" --blocked-by "$SLICE_2_URI" --namespace "$PASTURE_NAMESPACE"

# "slice is blocked by its leaf tasks"
pasture task dep add "$SLICE_1_URI" --blocked-by "$LEAF_A_URI" --namespace "$PASTURE_NAMESPACE"
pasture task dep add "$SLICE_1_URI" --blocked-by "$LEAF_B_URI" --namespace "$PASTURE_NAMESPACE"
```

Produces the correct tree (leaf work at the bottom, user request at the top):

```
REQUEST
  └── blocked by URE
        └── blocked by PROPOSAL
              └── blocked by IMPL PLAN
                    ├── blocked by slice-1
                    │     ├── blocked by leaf-task-a
                    │     └── blocked by leaf-task-b
                    └── blocked by slice-2
                          ├── blocked by leaf-task-c
                          └── blocked by leaf-task-d
```

### Wrong: reversed direction

```bash
# WRONG — this says "URE is blocked by REQUEST", meaning the request
# must finish before requirements gathering can start (backwards)
pasture task dep add "$URE_URI" --blocked-by "$REQUEST_URI"
```

**Rule of thumb:** The `--blocked-by` target is always the thing you do *first*. Work flows bottom-up; closure flows top-down.

### User Requirements Document (URD)

**Given** Phase 2 (URE) completes **when** requirements are captured **then** create a URD task (label `aura:urd`) as the single source of truth for user requirements **should never** scatter requirements across multiple unlinked tasks

**Given** a URD exists **when** any phase creates or updates requirements **then** update the URD via `pasture task comment add "$URD_URI" "..." --author "$PASTURE_AUTHOR"` **should never** leave the URD stale when scope changes

**Given** a URD exists **when** architects, reviewers, or supervisors need to understand user intent **then** read the URD with `pasture task show "$URD_URI"` **should never** rely solely on the original REQUEST task for requirements

**Given** a URD is created **when** linking to other tasks **then** include the URD task URI in the description frontmatter of referencing tasks (e.g., `urd: {{urd-task-uri}}`) **should never** make the URD a blocking dependency — it is a living reference document

### Agent Orchestration

**Given** you need parallel agents for an epic **then** spawn short-lived subagents via the Task tool and coordinate through `pasture task` evidence. **SHOULD NOT** launch long-running supervisors or workers as Task tool subagents.

**Given** you need a separate supervisor or architect to plan a new epic **then** delegate the planning phases to the appropriate role skill in-session. **SHOULD NOT** use the deprecated `aura-swarm` orchestration CLI — it is retained only as clearly deprecated history.

**Given** you need reviewer rounds (plan review or code review) **then** spawn reviewers as subagents (via the Task tool). Reviewers are short-lived and should stay in-session for direct result collection.

**Given** inter-agent communication is needed **then** use the Pasture tracker for coordination (`pasture task comment add`, `pasture task update`, `pasture task show`). **SHOULD NOT** reference `aura agent send/broadcast/inbox` — that CLI does not exist.

**Given** you are assigning work to a teammate **when** composing the message **then** MUST include: (1) explicit skill invocation instruction (e.g., `Skill(/aura:worker)`), (2) all relevant Pasture task URIs, (3) `pasture task show <uri>` commands for each reference, and (4) the handoff document path if applicable. **SHOULD NEVER** send bare instructions without tracker context — teammates spawned without context cannot see your conversation history or task tree.

**Given** you are a supervisor **when** implementation work is needed (code edits, file creation, config changes — no matter how small) **then** MUST delegate to a worker teammate or subagent. **MUST NEVER** use Edit, Write, or other file-modification tools directly. The supervisor's role is coordination, tracking, and quality control — never implementation.

**Given** you are a supervisor **when** codebase exploration is needed (understanding APIs, tracing data flow, finding integration points) **then** MUST spawn ephemeral Explore subagents via the Task tool with scoped queries. Each subagent is short-lived and returns findings — no standing team overhead. **SHOULD NEVER** perform deep codebase exploration directly as the supervisor or maintain a standing explore team.

### Tests & Fixtures

**Given** you are writing a test **when** you need any value (email, path, UUID, timestamp, etc.) **then**:
1. **MUST** first check for an existing fixture/constant in the project's test fixtures
2. **MUST** use centralized constants when they exist
3. **MUST** use factory functions for complex objects when they exist
4. **MUST** use mock factories for dependencies when they exist
5. **SHOULD NOT** write inline string or numeric literals for values that have fixture equivalents
6. **OTHERWISE** if no fixture exists, **MUST** add the value to the appropriate fixture file **before** using it in any test
7. **MUST NOT** mock the system under test — mock dependencies only

### User Interviews (URE/UAT)

**Given** a user interview (requirements elicitation or UAT) **when** capturing the Q&A in a Pasture task **then** you **MUST** record the full question, ALL options presented with their descriptions, AND the user's verbatim response. **SHOULD NEVER** summarize options as "(1)", "(2)", "(3)" without the option text — the user's answer referencing option numbers is meaningless without the full options.

### Worker Completion

**Given** a worker finishes implementation **when** signaling completion **then** the worker **MUST**:
1. Run all quality gates (type checking + tests must pass)
2. Verify production code path via code inspection (no TODOs, real deps wired)
3. Keep the task in progress (`pasture task update "$TASK_URI" --status in_progress`)
4. Add an attributed completion comment (`pasture task comment add "$TASK_URI" "Implementation complete." --author "$PASTURE_AUTHOR"`)

**SHOULD NEVER** signal completion with only "tests pass" as the gate — must also verify production code path. **SHOULD NEVER** close a task; only the supervisor closes work after review.

### Slice Reviews

**Given** a slice implementation is complete (tests + typecheck pass) **when** considering closing the task **then** you **MUST** launch a code review before closing it, **MUST** resolve all BLOCKER findings before closing, **SHOULD NEVER** close a slice task with only "tests pass" as the completion gate.

## Behavior

**When uncertain, ask.** If requirements are ambiguous, scope is unclear, or multiple valid approaches exist — stop and ask before proceeding. Wrong assumptions compound.

**Always think about how your work will affect the end-user**, and if the code will handle changes in the future.

**Design the interface you know you will need:** if it will be required in the end, then include it. But don't make it more complicated than it needs to be, and don't make it simpler than it is.

### Self-Validation Model

Before claiming completion:

1. **Plan backwards:** *"What does success look like, and what does it require?"*
   - Define the end state, then identify each prerequisite working backwards
   - Missing prerequisites reveal missing work
   - Define all public interfaces first; use mocks/stubs until full implementation is needed

2. **Invert the problem:** *"What would make this fail?"*
   - List failure modes (edge cases, race conditions, unhandled errors)
   - Verify each is addressed or explicitly out of scope
   - If you can't falsify your own work, it's not ready

## Agent Roles

| Role | Responsibility | Label Awareness |
|------|----------------|-----------------|
| Architect | Specs, tradeoffs, validation checklist, BDD criteria | `aura:p3-plan`, `aura:p4-plan`, `aura:p6-plan`, `aura:p7-plan` |
| Reviewer | End-user alignment, implementation gaps, MVP impact | `aura:p4-plan`, `aura:p10-impl`, `aura:severity:*` |
| Supervisor | Vertical-slice task decomposition, worker allocation, merge order, commits | `aura:p8-impl`, `aura:p9-impl`, `aura:epic-followup` |
| Worker | Vertical slice implementation (full production code path) | `aura:p9-impl:s9-slice` |

**Consensus:** All 3 reviewers must ACCEPT. Revisions loop until consensus.

## 12-Phase Workflow

All work flows through Pasture tasks using 12 phases:

```
Phase 1:  REQUEST (user prompt)
            s1_1-classify → s1_2-research (parallel) → s1_3-explore (parallel)
Phase 2:  ELICIT (URE survey, s2_1) → URD (s2_2, single source of truth)
Phase 3:  PROPOSAL-N (architect proposes, s3-propose)
Phase 4:  PROPOSAL-N-REVIEW-{axis}-{round} (3 axis-specific reviewers: A/B/C, ACCEPT/REVISE)
Phase 5:  Plan UAT (user acceptance test on plan)
Phase 6:  Ratification (aura:superseded marks old proposals)
Phase 7:  Handoff (architect → supervisor, stored at .git/.aura/handoff/)
Phase 8:  IMPL_PLAN (supervisor decomposes into slices + leaf tasks)
Phase 9:  SLICE-N (parallel workers, each owns one production code path)
            Each slice MUST have leaf tasks (L1: types, L2: tests, L3: impl)
            Workers are assigned to leaf tasks, not slices
Phase 10: Code review (3x reviewers, full severity tree with EAGER creation)
            Severity tree: BLOCKER / IMPORTANT / MINOR (always 3 groups)
            BLOCKER → blocks slice | IMPORTANT/MINOR → blocks FOLLOWUP only
            Dual-parent BLOCKER relationship
Phase 11: Implementation UAT
Phase 12: Landing (commit, push, hand off)
```

### Label Schema

```
Format: aura:p{phase}-{domain}:s{step}-{type}

Phase-domain pairs:
  aura:p1-user     — Request + classify + research + explore
  aura:p2-user     — Elicit + URD
  aura:p3-plan     — Propose
  aura:p4-plan     — Plan review
  aura:p5-user     — Plan UAT
  aura:p6-plan     — Ratify
  aura:p7-plan     — Handoff
  aura:p8-impl     — Impl plan
  aura:p9-impl     — Worker slices
  aura:p10-impl    — Code review
  aura:p11-user    — Impl UAT
  aura:p12-impl    — Landing

Special labels:
  aura:urd                  — User Requirements Document
  aura:superseded           — Superseded proposal/plan
  aura:severity:blocker     — Blocker severity group
  aura:severity:important   — Important severity group
  aura:severity:minor       — Minor severity group
  aura:epic-followup        — Follow-up epic
```

### Task Title Conventions

| Title Format | Label | Created By |
|---|---|---|
| `REQUEST: Description` | `aura:p1-user:s1_1-classify` | User or Coordinator |
| `PROPOSAL-N: Description` | `aura:p3-plan:s3-propose` | Architect |
| `PROPOSAL-N-REVIEW-{axis}-{round}: Description` | `aura:p4-plan:s4-review` | Reviewers |
| `URD: Description` | `aura:urd` | Architect (after Phase 2) |
| `IMPL_PLAN: Description` | `aura:p8-impl:s8-plan` | Supervisor |
| `SLICE-N: Description` | `aura:p9-impl:s9-slice` | Workers |

### Frontmatter References

Instead of peer-reference commands, include task URIs in the description frontmatter:

```bash
URD_URI=$(pasture task create "URD: Feature name" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  elicit: {{elicit-task-uri}}
---
## Requirements
..." --format json | jq -er '.id')
pasture task label add "$URD_URI" aura:urd --namespace "$PASTURE_NAMESPACE"
```

Other tasks reference the URD similarly:
```bash
PROPOSAL_URI=$(pasture task create "PROPOSAL-1: Technical approach" \
  --namespace "$PASTURE_NAMESPACE" --type feature --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  urd: {{urd-task-uri}}
---
## Proposal
..." --format json | jq -er '.id')
pasture task label add "$PROPOSAL_URI" aura:p3-plan:s3-propose --namespace "$PASTURE_NAMESPACE"
```

### Review Severity Tree (Code Reviews Only)

Code review rounds (Phase 10) use a severity tree with **EAGER creation**:

**ALWAYS create 3 severity group tasks per review round**, even if some groups have no findings:

```bash
# Create all 3 severity groups immediately (EAGER, not lazy). Bind each URI from
# its own create output, then add its severity label in a second command.
BLOCKER_GROUP_URI=$(pasture task create "SLICE-1-REVIEW-A-1 BLOCKER" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "Severity group for SLICE-1 review round A-1" --format json | jq -er '.id')
pasture task label add "$BLOCKER_GROUP_URI" aura:severity:blocker --namespace "$PASTURE_NAMESPACE"
pasture task label add "$BLOCKER_GROUP_URI" aura:p10-impl:s10-review --namespace "$PASTURE_NAMESPACE"
# Repeat for the IMPORTANT (aura:severity:important) and MINOR (aura:severity:minor) groups.

# Empty groups have no children and are closed immediately (supervisor only).
pasture task close "$EMPTY_IMPORTANT_URI" --reason "No findings in this severity group" --namespace "$PASTURE_NAMESPACE"
pasture task close "$EMPTY_MINOR_URI" --reason "No findings in this severity group" --namespace "$PASTURE_NAMESPACE"
```

**Dual-parent BLOCKER relationship:** BLOCKER findings have two parents:
1. The severity group task (`aura:severity:blocker`)
2. The proposal or slice they block (via `pasture task dep add "$SLICE_URI" --blocked-by "$BLOCKER_FINDING_URI"`)

This ensures BLOCKERs both categorize under the severity tree AND block the artifact they apply to.

**Plan reviews (Phase 4) do NOT use a severity tree.** Plan reviews use binary ACCEPT/REVISE votes only.

### Follow-up Epic

**Trigger:** Review completion + ANY IMPORTANT or MINOR findings exist (NOT gated on BLOCKER resolution).

**Owner:** Supervisor creates the follow-up epic (label `aura:epic-followup`).

**Content:** Aggregated IMPORTANT and MINOR findings from the review round, organized by priority.

**Timing:** Created as soon as the review round completes, regardless of whether BLOCKERs are still being resolved. This ensures non-blocking improvements are tracked and not lost.

**Follow-up lifecycle:** The follow-up epic runs the same protocol phases with FOLLOWUP_* prefixed task types:
FOLLOWUP_URE → FOLLOWUP_URD → (h6 to architect) → FOLLOWUP_PROPOSAL → (h1 back to supervisor) → FOLLOWUP_IMPL_PLAN → FOLLOWUP_SLICE-N.
Original IMPORTANT/MINOR leaf tasks are adopted as children of FOLLOWUP_SLICE-N (dual-parent).
No followup-of-followup — findings from follow-up code review stay on the existing follow-up epic.

### When Reviewing

Check **end-user alignment**, not technical specializations:

- Who are the end-users?
- What would end-users want?
- How would this affect them?
- Are there implementation gaps?
- Does MVP scope make sense?
- Is validation checklist complete?

**Votes (binary):**

| Vote | Requirement |
|------|-------------|
| **ACCEPT** | All 6 criteria satisfied; no BLOCKER items |
| **REVISE** | BLOCKER issues found; must provide actionable feedback |

### When Working

**Supervisor** creates vertical slice tasks (SLICE-N) with:
- One production code path per slice
- Key details from ratified plan
- Tradeoffs relevant to each slice
- Reference to IMPL_PLAN task in description frontmatter
- Validation checklist items per task
- BDD acceptance criteria (Given/When/Then/Should Not)
- Explicit file ownership boundaries within each slice
- Leaf tasks (L1: types, L2: tests, L3: impl) within each slice — a slice without leaf tasks is undecomposed
- Workers are assigned to leaf tasks, not slices
- NEVER implements code themselves — ALWAYS spawns workers

**Worker** implements by:
- Owning a leaf task within a vertical slice (one layer: types, tests, or implementation)
- Following interface contracts from ratified plan
- Satisfying validation checklist items
- Meeting BDD acceptance criteria
- Running quality gates (type checking + tests)
- Signaling completion with an attributed tracker comment

### Handoff Documents

6 actor-change transitions require handoff documents, stored at `.git/.aura/handoff/{request-task-id}/` (or `{followup-epic-id}/` for follow-up lifecycle):

| Transition | File | Content Level |
|---|---|---|
| Architect → Supervisor | `architect-to-supervisor.md` | Full inline provenance |
| Supervisor → Worker | `supervisor-to-worker.md` | Summary + task URIs |
| Supervisor → Reviewer | `supervisor-to-reviewer.md` | Summary + task URIs |
| Worker → Reviewer | `worker-to-reviewer.md` | Summary + task URIs |
| Reviewer → Followup | `reviewer-to-followup.md` | Summary + task URIs |
| Supervisor → Architect | `supervisor-to-architect.md` | Summary + task URIs |

**Same-actor transitions do NOT need handoff:** UAT → Ratify and Ratify → Handoff are performed by the same actor (architect), so no handoff document is needed.

See [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md) for the standardized template.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **COMMIT AND PUSH (push only with approval)** - This is MANDATORY:
   ```bash
   git add <files>
   git agent-commit -m "feat(scope): description"
   pasture task comment add "$TASK_URI" "Landed: <commit sha>; evidence: <pointer>" \
     --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
   git pull --rebase
   git push          # only with explicit approval
   git status        # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Create handoff document if actor transition occurs (see [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md)); provide context for next session using the label format

**CRITICAL RULES:**
- Use `git agent-commit` (not `git commit`) for signed commits
- Landing is NOT complete until the approved push succeeds and `git status` shows the branch up to date with its remote
- NEVER stop before the approved push — that leaves work stranded locally
- If the approved push fails, resolve and retry until it succeeds
- Use the label format (`aura:p{N}-{domain}:s{M}-{type}`) for all tracker operations

## References

- [PROCESS.md](PROCESS.md) - Step-by-step workflow execution (single source of truth)
- [CONSTRAINTS.md](CONSTRAINTS.md) - Coding standards, checklists, naming conventions
- [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md) - Standardized handoff document template
- [MIGRATION_v1_to_v2.md](MIGRATION_v1_to_v2.md) - Migration procedure from v1 to v2 labels
- `skills/*/SKILL.md` - Agent role definitions
