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
This includes Beads hook installation, `core.hooksPath`, writing to `.git/hooks/`,
and `pre-commit install`.

## Beads

This project uses `bd` for issue tracking.

```bash
bd ready --json
bd show <id>
bd update <id> --status in_progress --json
bd comments add <id> "Progress: ..."
bd close <id> --reason "Completed" --json
```

Dependency direction is always parent blocked by child:

```bash
bd dep add request-id --blocked-by work-that-must-finish-first
```

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
sync Beads, commit with `git agent-commit`, pull with rebase, push, and confirm
`git status` reports the branch is up to date with its remote.
