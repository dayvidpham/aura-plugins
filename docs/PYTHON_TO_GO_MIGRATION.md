---
name: Python → Go migration status
description: Tracks the deprecation of the Python `aura_protocol` package and the going-forward authority of the Go port (Pasture). Drift inventory + reconciliation policy.
references:
  parent_task: aura-plugins-naupi
  deprecation_notice: aura-plugins/scripts/aura_protocol/DEPRECATED.md
  related_audits:
    codegen: aura-plugins-5wbhm
    constraints: aura-plugins-mh4ek
    sa_rename: aura-plugins-fb658
  roadmap: aura-plugins-cmvu5
---

# Python → Go migration status

## Status as of 2026-05-20

| Layer | Python (`scripts/aura_protocol/`) | Go (`pasture/`) | Notes |
|---|---|---|---|
| Workflow execution | Frozen | **Canonical** | `pastured` runs all live workflows. |
| Task tracking | Frozen | **Canonical** | `protocol.TaskTracker` (PROPOSAL-2 epic, landed 2026-04-26). |
| Audit trail | Frozen | **Canonical** | unified `pasture.db` with BCNF `context_edges`. |
| Constraints (26 C-* checks) | Frozen | Parity audit pending | [`aura-plugins-mh4ek`](beads://aura-plugins-mh4ek) confirms the port is complete. |
| Schema codegen | Frozen | Authority audit pending | [`aura-plugins-5wbhm`](beads://aura-plugins-5wbhm) confirms Go is the live generator. |
| SKILL.md generation | Drifted (see below) | Drifted (see below) | This document. |
| Temporal search attributes | `Aura*` (frozen) | `Pasture*` (canonical) | Wire-name fork landed 2026-05-20 ([`aura-plugins-fb658`](beads://aura-plugins-fb658)). |

The Python package carries a `DEPRECATED.md` header notice and remains
in-tree for reference / archival until the three audits complete.

## Skill drift inventory

Two skill homes contain overlapping role skills:

- **Parent**: `aura-plugins/skills/<skill>/SKILL.md` — historically driven by
  the Python `gen_skills.py`, with some later hand-edits.
- **Pasture**: `aura-plugins/worktree/aura-protocol/pasture/skills/<skill>/SKILL.md`
  — Go-generated (via `internal/codegen/skills.go`) plus some hand-edits.

During development, edits flowed to whichever copy was closer to the
working surface at the time. The two homes drifted. Audit run 2026-05-20:

### Drifted skills (7)

| Skill | Changed lines | Nature of drift |
|---|---:|---|
| `architect` | 56 | `skills:` frontmatter list reordered (alphabetical vs phase-order). Example blocks reordered. Section heading "General Constraints" vs "Constraints (Given/When/Then/Should Not)". |
| `impl-review` | 25 | Frontmatter (`name:` / `description:`) added on one side; generated-section markers (`<!-- BEGIN GENERATED FROM aura schema -->`) present on one side and absent on the other. |
| `reviewer` | 30 | `skills:` frontmatter list reordered. |
| **`supervisor`** | **212** | **Substantial — needs content review.** Likely a mix of reordering + real content edits in one direction that weren't propagated. |
| `supervisor-plan-tasks` | 27 | Title heading (`# Supervisor Plan Tasks`) added on one side. Content restructured. |
| `supervisor-spawn-worker` | 33 | Title heading added on one side. Content restructured. |
| **`worker`** | **122** | **Substantial — needs content review.** Same shape as the supervisor drift. |

### Non-overlapping skills (31)

The other 31 skills under `aura-plugins/skills/` (e.g. `epoch`, `feedback`,
`research`, `templates`, all the `msg-*` and `architect-*` and `reviewer-*`
sub-skills) do **not** exist under `pasture/skills/`. They are Python-side
only.

### Pasture-only skill (1)

`pasture/skills/install-cli/` is unique to the Pasture submodule — it's the
Claude Code skill installer that ships with the pasture binaries. No Python
counterpart.

## Reconciliation policy

**Authority going forward**: where a skill exists in both homes,
`pasture/skills/` is the source of truth. Hand-edits in
`aura-plugins/skills/` that haven't been reflected in `pasture/skills/`
must be ported (or explicitly retired) before the parent copy is
overwritten.

For the 7 drifted skills:

| Skill | Recommended action |
|---|---|
| `architect`, `reviewer`, `impl-review` | **Auto-reconcile**: regenerate from Go codegen; the drift is cosmetic (sort order, generated markers). Verify no hand-edits are being discarded. |
| `supervisor-plan-tasks`, `supervisor-spawn-worker` | **Auto-reconcile** after eyeballing: the title-heading addition and content restructuring may carry real intent. Pick the better-structured version, regenerate from Go codegen. |
| **`supervisor`**, **`worker`** | **Manual review required**: 212 + 122 line diffs are not cosmetic. Side-by-side review needed to decide which content lines are load-bearing additions vs reformatting noise. Each merge decision should be captured in a per-skill bd task. |

For the 31 Python-only skills: no immediate action. They continue to live at
`aura-plugins/skills/` and are loaded by Claude Code as today. If/when the
Go codegen takes over their generation, file follow-up tasks per skill.

The actual reconciliation work (running the diffs, picking content, applying
merges) is scoped as a follow-up REQUEST — out of scope for the deprecation
declaration itself.

## How drift accumulates (to prevent recurrence)

The drift came from:

1. **Two generators writing to two homes**: `gen_skills.py` writes
   `aura-plugins/skills/`; `internal/codegen/skills.go` writes
   `pasture/skills/`. Neither is aware of the other.
2. **Hand-edits happening downstream of generation**: once a generated
   SKILL.md is shipped, edits to the .md (not the schema or template) only
   live on one side until someone manually re-syncs.
3. **No CI check** that the two homes stay in sync for overlapping skills.

Going forward (after the Go codegen authority audit closes):

- The Go codegen is the only one that runs in normal workflows.
- The Python `gen_skills.py` is frozen (its output is, by definition, stale
  against any post-deprecation schema change).
- For skills that exist in both homes, the Pasture copy is canonical; the
  parent copy is a snapshot to be eventually overwritten by `make
  generate-skills` (Go) or removed.
- A CI check should be added that flags any drift between matching skill
  files in the two homes (separate task to file when the Go codegen
  authority audit closes).

## How to read this document

This file is the human-readable audit; the source of truth is the Beads
task graph rooted at [`aura-plugins-naupi`](beads://aura-plugins-naupi) and
its children:

- [`aura-plugins-5wbhm`](beads://aura-plugins-5wbhm) — Codegen authority
  audit.
- [`aura-plugins-mh4ek`](beads://aura-plugins-mh4ek) — Constraint coverage
  audit.
- [`aura-plugins-fb658`](beads://aura-plugins-fb658) — SA wire-name
  rename (closed; the fork is now intentional).
- (Future) per-skill reconciliation tasks for the 7 drifted skills.
