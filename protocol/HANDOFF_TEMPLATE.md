# Handoff Document Template

Standardized template for all 5 actor-change transitions in the Aura protocol.

**Storage:** `.git/.aura/handoff/{request-task-id}/{source}-to-{target}.md`

---

## Transitions Overview

| # | From | To | When | Content Level |
|---|------|-----|------|---------------|
| 1 | Architect | Supervisor | Phase 7 (Handoff) | Full inline provenance |
| 2 | Supervisor | Worker | Phase 9 (Slice assignment) | Summary + bd IDs |
| 3 | Supervisor | Reviewer | Phase 10 (Code review) | Summary + bd IDs |
| 4 | Worker | Reviewer | Phase 10 (Code review) | Summary + bd IDs |
| 5 | Reviewer | Followup | After Phase 10 (Follow-up epic) | Summary + bd IDs |

### Same-Actor Transitions (NO Handoff Needed)

These transitions are performed by the same actor and do not require a handoff document:
- **Plan UAT → Ratify** (Phase 5 → Phase 6): Architect performs both
- **Ratify → Handoff** (Phase 6 → Phase 7): Architect performs both

---

## Template Structure

```markdown
# Handoff: {{SOURCE_ROLE}} → {{TARGET_ROLE}}

## Metadata
- **Request:** {{REQUEST_TASK_ID}} — {{REQUEST_TITLE}}
- **Date:** {{YYYY-MM-DD}}
- **Source:** {{SOURCE_ROLE}} ({{SOURCE_AGENT_ID}})
- **Target:** {{TARGET_ROLE}}

## Task References
- **Request:** {{request-task-id}}
- **URD:** {{urd-task-id}}
- **Proposal:** {{proposal-task-id}}
- **Ratified Plan:** {{ratified-task-id}}  <!-- if applicable -->
- **Impl Plan:** {{impl-plan-task-id}}    <!-- if applicable -->
- **Slice:** {{slice-task-id}}            <!-- if applicable -->

## Context
{{BRIEF_DESCRIPTION_OF_WHAT_WAS_DONE_AND_WHY}}

## Key Decisions
{{LIST_OF_CRITICAL_DESIGN_DECISIONS_AND_THEIR_RATIONALE}}

## Open Items
{{ANYTHING_THE_TARGET_NEEDS_TO_BE_AWARE_OF}}

## Acceptance Criteria
{{WHAT_THE_TARGET_MUST_DELIVER}}
```

---

## Required Fields Per Transition

| Field | Architect→Supervisor | Supervisor→Worker | Supervisor→Reviewer | Worker→Reviewer | Reviewer→Followup |
|-------|---------------------|-------------------|--------------------|-----------------|--------------------|
| Request | Required | Required | Required | Required | Required |
| URD | Required | Required | Required | Required | Required |
| Proposal | Required | Required | Required | — | Required |
| Ratified Plan | Required | Required | Required | — | — |
| Impl Plan | — | Required | Required | Required | — |
| Slice | — | Required | — | Required | — |
| Context | Full provenance | Summary | Summary | Summary | Summary |
| Key Decisions | Full list | Slice-relevant | Review scope | Impl decisions | Findings summary |
| Open Items | Required | Required | — | Required | Required |
| Acceptance Criteria | Required | Required | Required | — | Required |

---

## Examples

### 1. Architect → Supervisor (Full Inline Provenance)

```markdown
# Handoff: Architect → Supervisor

## Metadata
- **Request:** aura-scripts-abc — REQUEST: Add structured logging
- **Date:** 2026-02-20
- **Source:** Architect (architect-agent-1)
- **Target:** Supervisor

## Task References
- **Request:** aura-scripts-abc
- **URD:** aura-scripts-def
- **Proposal:** aura-scripts-ghi (PROPOSAL-2, ratified)
- **Ratified Plan:** aura-scripts-jkl

## Context
User requested structured logging across all CLI commands. After URE survey,
user prioritized JSON output format and log-level filtering. PROPOSAL-1 was
superseded (used plain-text format); PROPOSAL-2 adopted JSON with slog and
was ratified after 1 revision round (3/3 ACCEPT).

## Key Decisions
1. **slog over zerolog:** User prefers stdlib compatibility; slog is Go stdlib.
2. **JSON output only (no plain-text):** User confirmed JSON-only in UAT.
3. **Log levels via env var:** LOG_LEVEL env var, not CLI flag, per user preference.
4. **No file output in MVP:** Console-only; file output deferred to follow-up epic.

## Open Items
- Reviewer suggested adding request-id correlation; deferred to follow-up.
- Performance benchmark not yet run; add to code review checklist.

## Acceptance Criteria
- All CLI commands emit structured JSON logs via slog
- LOG_LEVEL env var controls verbosity (debug, info, warn, error)
- No secrets appear in log output
- Tests verify log output format
```

### 2. Supervisor → Worker (Summary + bd IDs)

```markdown
# Handoff: Supervisor → Worker

## Metadata
- **Request:** aura-scripts-abc — REQUEST: Add structured logging
- **Date:** 2026-02-20
- **Source:** Supervisor (supervisor-agent-1)
- **Target:** Worker (SLICE-1 owner)

## Task References
- **Request:** aura-scripts-abc
- **URD:** aura-scripts-def
- **Proposal:** aura-scripts-ghi
- **Ratified Plan:** aura-scripts-jkl
- **Impl Plan:** aura-scripts-mno
- **Slice:** aura-scripts-pqr (SLICE-1)

## Context
SLICE-1 covers the core logging infrastructure: slog handler setup, JSON
formatter, and LOG_LEVEL env var parsing. Other slices depend on this.

## Key Decisions
1. Use slog.Handler interface for testability (inject mock handler in tests).
2. Parse LOG_LEVEL at startup, not per-call.

## Open Items
- SLICE-2 (CLI integration) depends on SLICE-1 completing first.

## Acceptance Criteria
- See bd task aura-scripts-pqr for full validation_checklist and acceptance_criteria.
```

### 3. Supervisor → Reviewer (Summary + bd IDs)

```markdown
# Handoff: Supervisor → Reviewer

## Metadata
- **Request:** aura-scripts-abc — REQUEST: Add structured logging
- **Date:** 2026-02-20
- **Source:** Supervisor (supervisor-agent-1)
- **Target:** Reviewer

## Task References
- **Request:** aura-scripts-abc
- **URD:** aura-scripts-def
- **Proposal:** aura-scripts-ghi
- **Ratified Plan:** aura-scripts-jkl
- **Impl Plan:** aura-scripts-mno

## Context
All 3 slices are complete. Code review covers the full implementation
against the ratified plan and URD requirements.

## Key Decisions
1. Review against URD priorities: JSON format, log-level filtering, no secrets in logs.
2. Check all 3 slices for consistency in slog handler usage.

## Acceptance Criteria
- Review all slices for end-user alignment (6 review criteria).
- Create severity groups (BLOCKER, IMPORTANT, MINOR) per EAGER creation rule.
- Vote ACCEPT or REVISE per slice.
```

### 4. Worker → Reviewer (Summary + bd IDs)

```markdown
# Handoff: Worker → Reviewer

## Metadata
- **Request:** aura-scripts-abc — REQUEST: Add structured logging
- **Date:** 2026-02-20
- **Source:** Worker (worker-slice-1)
- **Target:** Reviewer

## Task References
- **Request:** aura-scripts-abc
- **URD:** aura-scripts-def
- **Impl Plan:** aura-scripts-mno
- **Slice:** aura-scripts-pqr (SLICE-1)

## Context
SLICE-1 implements the core logging infrastructure. All quality gates pass
(type checking + tests). Production code path verified via code inspection.

## Key Decisions
1. Used slog.NewJSONHandler with os.Stderr as default output.
2. LOG_LEVEL parsed once at init() via env.MustGet("LOG_LEVEL").

## Open Items
- Consider adding log rotation in follow-up (not in scope for MVP).

## Acceptance Criteria
- See bd task aura-scripts-pqr for validation_checklist completion status.
```

### 5. Reviewer → Followup (Summary + bd IDs)

```markdown
# Handoff: Reviewer → Followup

## Metadata
- **Request:** aura-scripts-abc — REQUEST: Add structured logging
- **Date:** 2026-02-20
- **Source:** Reviewer (reviewer-1)
- **Target:** Followup (Supervisor creates follow-up epic)

## Task References
- **Request:** aura-scripts-abc
- **URD:** aura-scripts-def
- **Proposal:** aura-scripts-ghi

## Context
Code review complete. 0 BLOCKERs, 2 IMPORTANT, 1 MINOR findings.
Follow-up epic needed for non-blocking improvements.

## Key Decisions
1. IMPORTANT: Add request-id correlation to all log entries (cross-cutting).
2. IMPORTANT: Add performance benchmark for high-throughput logging paths.
3. MINOR: Rename LogConfig → LoggingConfig for consistency with project naming.

## Open Items
- All findings above should be tracked as tasks in the follow-up epic.

## Acceptance Criteria
- Follow-up epic created with label `aura:epic-followup`.
- All IMPORTANT and MINOR findings captured as individual tasks.
```
