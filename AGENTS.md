# Agent Instructions

This repository contains the remaining Aura-side operational tooling:

- **DEPRECATED**: `bin/aura-swarm` do NOT use this for orchestration and handoff.
- **DEPRECATED**: `scripts/aura_protocol/session_registry.py` for `aura-swarm` session state.
- `nix/hm-module.nix` for Home Manager sync.
- `skills/protocol/` for reference protocol documentation.
- `.claude-plugin/marketplace.json` for marketplace registry entries.

The Go `pasture` repository is the source of truth for protocol implementation,
generated skills, and generated agents. Do not add new Python protocol-engine
code here.

## Git Hooks Policy

Never install, enable, or modify any git hook without explicit user approval.
This includes tracker/tool installer hook changes, `core.hooksPath`, writing to
`.git/hooks/`, and `pre-commit install`. Home Manager harness hook payload
projection is not permission to install or configure Git hooks.

## Pasture Tracker

Use `pasture task` for all operational tracking. Retained `.beads/` data is
legacy migration/archive evidence, not an alternative working tracker. The
triage ledger owns legacy-ID-to-successor-URI mapping; inspect a recorded
successor before creating a duplicate. After cutover, read
`docs/audits/bd-retirement-triage.md`; until that reviewed ledger exists, do not
guess legacy successors or recreate legacy work from old documents.

At session start (and after compaction), follow Pasture's generated recovery
instructions, select the intended store and repository namespace, and re-read
live task state. `--db` overrides `PASTURE_DB_PATH`, otherwise the configured
default store is used. A failed query is a configuration/connectivity failure,
not proof of no work: report the command, store path and repair before proceeding.
`task list`, `task ready`, and `task blocked` are scoped to the effective
namespace: an explicit `--namespace`, otherwise `PASTURE_NAMESPACE`. Pass
`--all-namespaces` to read every namespace. With neither source set those reads
are unscoped; inspect full returned URIs before choosing repository work.
Separate reads are not an atomic snapshot.

```bash
set -euo pipefail
export PASTURE_NAMESPACE=https://github.com/dayvidpham/aura-plugins
# This machine actor is already registered. Human comments use their own
# registered identity; do not silently register or impersonate another author.
export PASTURE_AUTHOR=pasture-system/00000000-0000-0000-0000-000000000000
pasture task ready --namespace "$PASTURE_NAMESPACE" --format json
pasture task blocked --namespace "$PASTURE_NAMESPACE"
pasture task list --namespace "$PASTURE_NAMESPACE" --status in_progress
```

Task operands are full URIs, never unbound legacy IDs. Since the 2026-10-15
identity cutover, both task URIs and actor identities use the **slash** form
(`<namespace>/<uuid>` and `pasture-system/<uuid>`); the retired two-dash form
(`<namespace>--<uuid>`) no longer resolves for any command. Capture the actual
JSON `id` field immediately; creation and labeling are separate, non-atomic
writes. Retain the URI and retry a failed label/comment, not creation.

```bash
TASK_URI=$(pasture task create "Implement the approved change" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority medium \
  --description "Approved scope and acceptance cases" --format json | jq -er '.id')
pasture task label add "$TASK_URI" pasture:work --namespace "$PASTURE_NAMESPACE"
pasture task show "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
pasture task update "$TASK_URI" --status in_progress --namespace "$PASTURE_NAMESPACE"
pasture task comment add "$TASK_URI" "Progress: evidence and next step" \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
pasture task comments "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
pasture task timeline "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
```

## Dependencies and Audit

The parent stays open until the child finishes; work flows bottom-up and closure
flows top-down. Bind `PARENT_URI` and `CHILD_URI` from their creation output or
verified tracker reads before running:

```bash
pasture task dep add "$PARENT_URI" --blocked-by "$CHILD_URI" --namespace "$PASTURE_NAMESPACE"
pasture task dep tree "$PARENT_URI" --kind all --namespace "$PASTURE_NAMESPACE"
```

Chain each real work unit to its parent, never reverse the blocker. Reference
documents (URD, request, proposal) go in description frontmatter `references:`,
not fake relation commands or blocking edges. Preserve audit history: add labels
and attributed comments; do not delete tasks or remove audit labels/comments.
Workers record implementation and verification evidence, never close assigned
tasks. Only the supervisor closes work after independent review and approval:

```bash
pasture task close "$CHILD_URI" --reason "Reviewed and verified; evidence in comments" \
  --namespace "$PASTURE_NAMESPACE"
```

Store writes are durable; no tracker sync/prime/edit/molecule ritual exists.
Git history lands separately. Use explicit updates instead of an interactive
editor, and scoped JSON task-list reads for local summaries/searches.

## Home Manager Source Rules

The module (`nix/hm-module.nix` + `nix/hm-lib.nix`) must source every cell from
Pasture's own generated tree for that harness, never from local deprecated Aura
skill or agent directories and never from another harness's tree. Local
`skills/protocol/` is retained only as protocol documentation and is projected
solely by the opt-in `protocol.enable` option.

The schema is a closed three-by-three matrix under
`CUSTOM.programs.aura-config-sync.harnesses.<harness>`: `enable`, `targetRoot`,
and `skills` / `agents` / `hooks`, each with `enable` and an optional `target`
that overrides the harness-derived destination. Harness `enable` defaults false;
`skills` and `agents` default true but stay inert until the harness is enabled;
`hooks` defaults false. The former flat options (`commands.*`, `agents.*`,
`opencode.*`, `codex.*`) are removed, not aliased: defining one fails evaluation
with its exact replacement path.

Default source → destination per cell (destination shown for the default
`targetRoot`):

| Harness | Cell | Pasture source | Destination |
|---|---|---|---|
| claude-code | skills | `skills/` | `~/.claude/skills/` |
| claude-code | agents | `agents/` | `~/.claude/agents/` |
| claude-code | hooks | `hooks/` (Go sources excluded) | `~/.claude/hooks/` |
| opencode | skills | `.opencode/skill/` | `~/.config/opencode/skills/` |
| opencode | agents | `.opencode/agent/` | `~/.config/opencode/agent/` |
| opencode | hooks | `.opencode/plugins/pasture-lifecycle.ts` | `~/.config/opencode/plugins/pasture-hooks.ts` |
| codex | skills | `.agents/skills/` | `~/.agents/skills/` |
| codex | agents | `.codex/agents/` | `~/.codex/agents/` |
| codex | hooks | `.codex/hooks/` + `.codex/hooks.json`, `.codex/pasture-codex-activation.json` | `~/.codex/hooks/` + the two files in `~/.codex/` |

Rules that must hold for any change to the module:

- Pure Nix projection only. Never invoke `pasture install`, a native plugin
  manager, or the network from Home Manager, and never write Pasture's
  installation inventory.
- Hook cells project payload files only — never a Git hook, never
  `core.hooksPath`, never private harness trust or enablement state.
  `.codex/codex.toml` is native configuration and is never projected.
- Destinations stay inside `home.homeDirectory`. Reject `~`-prefixed paths,
  `..` traversal, absolute paths outside the home, a cell destination equal to
  the home root, duplicate destinations, and parent/child ownership overlap.
- The Codex hooks cell is layout-locked to `~/.codex/hooks`; its generated
  public configuration hard-codes that path, so relocation is refused.
- `home.file` entries leave `executable` unset so the source mode is preserved.
- `nix/hm-module-test.nix` derives its comparison plan from the layout table in
  `nix/hm-lib.nix`; do not restate the layout there. The projected destination
  set of the pinned Pasture input is pinned in
  `nix/hm-module-test-data/pinned-destinations.txt` and must be refreshed in the
  same change that bumps the `pasture` flake input.

## Validation

Before landing code changes, run the relevant gates:

```bash
nix flake check --no-build
python3 scripts/test_active_docs.py
python3 scripts/check-active-docs.py
nix build .#checks.x86_64-linux.hm-module-test --no-link
nix build .#aura-swarm --no-link
nix run .#aura-swarm -- --help
```

If you commit, use:

```bash
git agent-commit -m "<message>"
```

Do not use `git commit -m` unless the user explicitly overrides the project rule.

## Landing

When the user asks you to land the work, verify the diff, run quality gates,
record attributed tracker evidence, commit with `git agent-commit`, pull with
rebase, push only with approval, and confirm `git status` reports the branch is
up to date with its remote. Worker handoff stops at the local commit and evidence;
do not push or close assigned tasks.
