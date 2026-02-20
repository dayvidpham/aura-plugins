---
name: protocol
description: Aura protocol reference documentation — 12-phase workflow, agent roles, constraints, and coding standards. Read when you need to understand the full workflow or look up conventions.
---

# Aura Protocol Reference

Complete reference documentation for the Aura 12-phase workflow system.

## Documents

### Core

| File | Purpose |
|------|---------|
| [PROCESS.md](PROCESS.md) | Step-by-step workflow execution (single source of truth) |
| [AGENTS.md](AGENTS.md) | Agent roles, phase ownership, and handoff procedures |
| [CONSTRAINTS.md](CONSTRAINTS.md) | Coding standards, naming conventions, and checklists |
| [CLAUDE.md](CLAUDE.md) | Reusable agent directive for projects using Aura |
| [SKILLS.md](SKILLS.md) | Complete skill reference by role and phase |
| [README.md](README.md) | Protocol overview and quick-start |
| [schema.xml](schema.xml) | Beads label schema (XML format) |

### Templates & Examples

| File | Purpose |
|------|---------|
| [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md) | Standardized handoff document template |
| [HANDOFF_EXAMPLE-web-command-impl.md](HANDOFF_EXAMPLE-web-command-impl.md) | Handoff example: web command implementation |
| [HANDOFF_EXAMPLE-ingest-pipeline-impl.md](HANDOFF_EXAMPLE-ingest-pipeline-impl.md) | Handoff example: ingest pipeline implementation |
| [UAT_TEMPLATE.md](UAT_TEMPLATE.md) | User acceptance testing template |
| [UAT_EXAMPLE.md](UAT_EXAMPLE.md) | UAT example with demonstrative scenarios |
| [RESEARCH_EXAMPLE-nix-openclaw-req-ure-proposal.md](RESEARCH_EXAMPLE-nix-openclaw-req-ure-proposal.md) | Research example: Nix/OpenClaw request through proposal |

### Migration & Design

| File | Purpose |
|------|---------|
| [MIGRATION_v1_to_v2.md](MIGRATION_v1_to_v2.md) | Migration procedure from v1 to v2 label format |
| [user-request-revamp-v2.md](user-request-revamp-v2.md) | Design doc for v2 user request phase revamp |

## Quick Reference

### 12 Phases

1. **REQUEST** — Capture user request verbatim, classify, research, explore
2. **ELICIT + URD** — Requirements elicitation survey, create URD
3. **PROPOSAL-N** — Architect creates technical proposal
4. **REVIEW** — 3 axis-specific reviewers (A/B/C), binary ACCEPT/REVISE
5. **Plan UAT** — User acceptance test on the plan
6. **RATIFY** — Ratify accepted proposal, mark old as superseded
7. **HANDOFF** — Architect hands off to supervisor
8. **IMPL_PLAN** — Supervisor decomposes into vertical slices
9. **SLICE-N** — Workers implement slices in parallel
10. **Code Review** — 3 reviewers, severity tree (BLOCKER/IMPORTANT/MINOR)
11. **Impl UAT** — User acceptance test on the implementation
12. **LANDING** — Atomic commit, push, hand off

### Label Format

```
aura:p{phase}-{domain}:s{step}-{type}
```

### Agent Roles

| Role | Phases | Key Responsibility |
|------|--------|--------------------|
| Epoch | 1-12 | Master orchestrator |
| Architect | 1-7 | Specs, proposals, review coordination |
| Reviewer | 4, 10 | End-user alignment review |
| Supervisor | 7-12 | Task decomposition, worker allocation |
| Worker | 9 | Vertical slice implementation |
