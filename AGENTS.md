# Agent Instructions

This repository contains the remaining Aura-side operational tooling:

- `bin/aura-swarm` for worktree and tmux orchestration.
- `scripts/aura_protocol/session_registry.py` for `aura-swarm` session state.
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

The module must source generated skills and agents from Pasture, not from local
deprecated Aura skill or agent directories. Local `skills/protocol/` is retained
only as protocol documentation.

OpenCode paths used by the module:

- Skills: `~/.config/opencode/skills/<name>/SKILL.md`
- Agents: `~/.config/opencode/agent/<role>.md`

Claude Code paths used by the module:

- Skills: `~/.claude/skills/<name>/SKILL.md`
- Agents: `~/.claude/agents/<role>.md`

Codex paths used by the module (opt-in, disabled by default):

- Skills: `~/.agents/skills/<name>/SKILL.md`
- Agents: `~/.codex/agents/pasture-<role>.toml`

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
