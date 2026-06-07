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

> **2026-06-06 — parent URD `jbnx3` CLOSED.** The Go port is delivered as scoped (R1–R7 re-walk recorded on `aura-plugins-ow0pq`): R1/R2/R3/R5/R6/R7 DONE, R4 ACP core delivered (live-bidirectional externally blocked; residuals `pasture#1`/`#2`/`n856x`). Python `aura_protocol` remains deprecated/frozen and is slated for wholesale deletion (`aura-plugins-4s5zt`). Forward scope is tracked outside `jbnx3`: durable-execution substrate Temporal→DBOS (`pasture#13`), provenance integration (`pasture#14`), modular workflow compiler (`pasture#15`).

## Status as of 2026-05-24

| Layer | Python (`scripts/aura_protocol/`) | Go (`pasture/`) | Notes |
|---|---|---|---|
| Workflow execution | Frozen | **Canonical** | `pastured` runs all live workflows. |
| Task tracking | Frozen | **Canonical** | `protocol.TaskTracker` (PROPOSAL-2 epic, landed 2026-04-26). |
| Audit trail | Frozen | **Canonical** | unified `pasture.db` with BCNF `context_edges`. |
| Constraints (26 C-* checks) | Frozen | Parity audit pending | [`aura-plugins-mh4ek`](beads://aura-plugins-mh4ek) confirms the port is complete. |
| Schema codegen | Frozen | Authority audit pending | [`aura-plugins-5wbhm`](beads://aura-plugins-5wbhm) confirms Go is the live generator. |
| SKILL.md generation | Drifted (see below) | Drifted (see below) | This document. Both generators re-run 2026-05-24; residual drift is structural (template-level), not stale-regeneration. |
| `agents/*.md` generation | Not implemented | **Canonical** | Go codegen also writes `pasture/agents/{epoch,architect,reviewer,supervisor,worker}.md`. No Python counterpart. |
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
working surface at the time. The two homes drifted. **Latest audit
2026-05-24** (both generators just re-run; numbers below are
post-regeneration so they reflect the structural template drift, not
stale output):

### Drifted skills (7, out of 8 overlapping)

| Skill | Diff lines (2026-05-24) | vs 2026-05-20 | Nature of drift |
|---|---:|---:|---|
| `architect` | 56 | = | `skills:` frontmatter list reordered (alphabetical in Go vs declared-order in Python). Sub-skill table sort order. Example block label position. Heading text. |
| `impl-review` | 25 | = | Python `gen_skills.py` does **not** have an impl-review template — parent stays at the 2026-02-23 hand-authored version. Go writes a full schema-driven body with `[impl-rev-bN]` typed bullets + generated markers. **Unfixable from the Python side.** |
| `reviewer` | 30 | = | `skills:` frontmatter list sort order + same heading/label patterns. |
| **`supervisor`** | **208** | -4 | Same shape as worker plus: the parent retains a hand-authored `## Ride the Wave (Rewritten)` tail section AFTER the `<!-- END GENERATED -->` marker that the Go side does not produce; the Go side embeds a Stage-3 ASCII flow diagram in the generated block that the Python side does not. The −4 line delta vs 2026-05-20 came from the Python regen narrowing "ephemeral reviewers" wording to match the schema. |
| `supervisor-plan-tasks` | 27 | = | `# Supervisor Plan Tasks` title heading order vs marker order. Workflow heading hierarchy (Python `#####` inside generated block, Go `###` outside). Behavior bullet placement. |
| `supervisor-spawn-worker` | 33 | = | Same shape as `supervisor-plan-tasks`. |
| `worker` | 49 | -73 | Cosmetic only: `skills:` sort order, heading text, example label position, blank-line spacing in numbered steps, phase ID strings (Python `p9` vs Go `worker-slices`). The −73 line delta vs the 2026-05-20 doc reflects a measurement-baseline correction; today's number is the residual structural drift. |
| `protocol` | 0 | (new) | In sync. Not previously tracked. |

### Non-overlapping skills (31)

The other 31 skills under `aura-plugins/skills/` (e.g. `epoch`, `feedback`,
`research`, `templates`, all the `msg-*` and `architect-*` and `reviewer-*`
sub-skills) do **not** exist under `pasture/skills/`. They are Python-side
only.

### Pasture-only skill (1)

`pasture/skills/install-cli/` is unique to the Pasture submodule — it's the
Claude Code skill installer that ships with the pasture binaries. No Python
counterpart.

### Structural drift drivers

The seven drifted skills above (out of 8 overlapping — `protocol` is the 8th and is in sync) share a small, repeating set of template-level
differences. Listing them once here so readers don't have to re-derive them
from each per-skill diff:

1. **`skills:` frontmatter sort order** — Go sorts alphabetically; Python
   preserves the order from `types.py`. Affects every overlapping main-role
   skill (`architect`, `reviewer`, `supervisor`, `worker`).
2. **Sub-skill table sort order** — same root cause as #1; affects the
   `| Command | Description | Phases |` table.
3. **Section heading text** — Go renders `### General Constraints`; Python
   renders `### Constraints (Given/When/Then/Should Not)`. Schema text is
   identical; only the renderer label differs.
4. **`_Example (correct/anti-pattern)_` label placement** — Go writes the
   label immediately before the code fence with a blank line after; Python
   writes the label immediately after the fence. Affects every constraint
   that has illustrative examples.
5. **`<!-- BEGIN/END GENERATED FROM aura schema -->` marker semantics** —
   Python preserves any hand-authored content placed AFTER the END marker
   (the parent supervisor's `## Ride the Wave (Rewritten)` tail is the
   clearest example). The Go side replaces the whole region on regeneration
   and ignores trailing hand-edits.
6. **Heading hierarchy** — Python uses deeper levels (`#####`) inside the
   generated block; Go uses shallower levels (`##` / `###`) and places some
   sections outside the generated block.
7. **Phase / step ID display strings** — Python emits short phase IDs
   (e.g. `p9`); Go emits the descriptive form (e.g. `worker-slices`).
8. **`impl-review` template only exists on the Go side** — the largest
   non-cosmetic divergence; Python silently leaves the parent copy at its
   pre-deprecation hand-authored form.

Drivers 1–7 are structural template differences and would require either
template harmonization or a one-off normalization pass to close. Driver 8
is a missing-feature gap that would require porting a Jinja2 template if
the Python side were to stay in sync — which the deprecation policy
explicitly does not require.

## Reconciliation policy

**Authority going forward**: where a skill exists in both homes,
`pasture/skills/` is the source of truth. Hand-edits in
`aura-plugins/skills/` that haven't been reflected in `pasture/skills/`
must be ported (or explicitly retired) before the parent copy is
overwritten.

Updated recommendations after the 2026-05-24 dual regen:

| Skill | Recommended action |
|---|---|
| `architect`, `reviewer`, `worker` | **Auto-reconcile** is safe. After today's regen, the residual drift maps cleanly onto structural drivers 1–7 (sort order, heading text, label placement). No load-bearing parent hand-edits identified. Replacing parent with the Go output would not lose content. |
| `supervisor-plan-tasks`, `supervisor-spawn-worker` | **Auto-reconcile** is safe. The heading-order and marker-position differences are template-level; no per-skill hand-edits identified. |
| `impl-review` | **Port a Jinja2 template** if the Python side is to stay current — the parent copy is frozen at 2026-02-23 and pre-dates the schema-driven body. Alternatively, retire the parent copy and rely on `pasture/skills/impl-review/`. The deprecation policy makes the latter the default. |
| **`supervisor`** | **Manual review required** (1 specific item). The parent retains a hand-authored `## Ride the Wave (Rewritten)` tail section after the `<!-- END GENERATED -->` marker. The Go side ignores that region on regeneration. Decide whether that tail content (a) belongs in the schema body so both renderers emit it, (b) should be retired now that the Go output embeds the Stage-3 ASCII flow diagram inline, or (c) should be preserved as a parent-only addendum. |

For the 31 Python-only skills: no immediate action. They continue to live at
`aura-plugins/skills/` and are loaded by Claude Code as today. If/when the
Go codegen takes over their generation, file follow-up tasks per skill.

The actual reconciliation work (running the diffs, picking content, applying
merges) is scoped as a follow-up REQUEST — out of scope for the deprecation
declaration itself.

## Regenerator commands (run during the 2026-05-24 audit)

For future auditors — these are the exact commands that produced the
drift numbers above. Both ran cleanly with the working tree clean
beforehand:

```bash
# Python regen (writes to skills/)
PYTHONPATH=scripts uv run python -m aura_protocol.gen_skills

# Go regen (writes to pasture/skills/ and pasture/agents/)
cd pasture && nix develop --command go generate ./internal/codegen/...
```

Result of the 2026-05-24 run:

- Python regen modified only `skills/supervisor/SKILL.md` (4 lines —
  the "ephemeral reviewers" → "reviewers" wording change). All other
  parent skills were already in sync with the Python template output.
- Go regen made no changes — `pasture/skills/*` and `pasture/agents/*`
  were already in sync with the Go template output.

The takeaway: the residual 7-skill drift (out of 8 overlapping; `protocol` is in sync) listed above is **structural
between the two generators** and not a stale-regeneration backlog.
Running the regenerators on a clean tree does not close the drift.

## How drift accumulates (to prevent recurrence)

The drift came from:

1. **Two generators writing to two homes**: `gen_skills.py` writes
   `aura-plugins/skills/`; `internal/codegen/skills.go` writes
   `pasture/skills/`. Neither is aware of the other.
2. **Hand-edits happening downstream of generation**: once a generated
   SKILL.md is shipped, edits to the .md (not the schema or template) only
   live on one side until someone manually re-syncs.
3. **No CI check** that the two homes stay in sync for overlapping skills.
4. **Template-level divergence between the two generators**: the eight
   drift drivers listed above are not stale-output problems — they are
   different rendering choices baked into the two templates. Even running
   both generators on the same clean tree will not close the drift until
   the templates are harmonized (or the deprecation is finalized and one
   home is retired).

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
