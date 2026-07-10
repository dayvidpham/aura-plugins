# aura-plugins

`aura-plugins` now carries the operational pieces that still belong outside the
Go [Pasture](https://github.com/dayvidpham/pasture) repo:

- `bin/aura-swarm`: worktree and tmux orchestration for multi-agent sessions.
- `nix/hm-module.nix`: Home Manager sync for `aura-swarm` and Pasture-generated skills/agents.
- `skills/protocol/`: protocol reference documentation retained for humans and agents.
- `.claude-plugin/marketplace.json`: marketplace registry entries for external plugins.

Pasture is the source of truth for protocol implementation, generated skills,
and generated agents. This repo no longer ships the retired Python protocol
engine, Aura plugin package, daemon, message CLI, release CLI, or Python tests.

## Install

### Nix Package

```nix
{
  inputs.aura-plugins.url = "github:dayvidpham/aura-plugins";
}
```

Use the package directly:

```nix
aura-plugins.packages.${system}.aura-swarm
```

The default package is a symlink join containing `aura-swarm`.

### Home Manager

The module installs `aura-swarm` and symlinks Pasture-generated skills and
agents into Claude Code and OpenCode config locations.

```nix
{
  imports = [ aura-plugins.homeManagerModules.aura-config-sync ];

  CUSTOM.programs.aura-config-sync = {
    enable = true;
    packages.enable = true;

    # Sources generated skills/ and agents/ from the pasture flake input by default.
    commands.enable = true;        # ~/.claude/skills/<name>/SKILL.md
    agents.enable = true;          # ~/.claude/agents/<role>.md
    opencode.skills.enable = true; # ~/.config/opencode/skills/<name>/SKILL.md
    opencode.agents.enable = true; # ~/.config/opencode/agent/<role>.md

    protocol.enable = false;       # optional local protocol docs sync
  };
}
```

For local Pasture development, override the generated source:

```nix
CUSTOM.programs.aura-config-sync.pasture.source = ../pasture;
```

### Manual

`aura-swarm` is a Python 3.10+ script with only standard-library runtime
dependencies. It requires `scripts/aura_protocol/session_registry.py` on
`PYTHONPATH`.

```bash
PYTHONPATH=scripts bin/aura-swarm --help
```

When running outside the Nix wrapper, set `AURA_PACKAGE_SKILLS_DIR` to a Pasture
`skills/` directory if the target project does not provide local role skills:

```bash
AURA_PACKAGE_SKILLS_DIR=/path/to/pasture/skills PYTHONPATH=scripts bin/aura-swarm start --swarm-mode intree --role supervisor --prompt "..."
```

## aura-swarm

`aura-swarm` supports two launch modes:

- Worktree mode creates or reuses an isolated git worktree for a Beads epic and launches Claude in tmux.
- Intree mode launches one or more Claude sessions in the current checkout without creating worktrees.

Examples:

```bash
aura-swarm start --epic aura-example --model sonnet
aura-swarm start --swarm-mode intree --role supervisor -n 1 --prompt "Coordinate this implementation"
aura-swarm status
aura-swarm attach aura-example
aura-swarm stop aura-example
aura-swarm cleanup --done
```

Prerequisites:

| Tool | Purpose |
|------|---------|
| `git` | Worktree and branch management |
| `tmux` | Agent session hosting |
| `bd` | Beads issue tracking |
| `claude` | Agent runtime |

## Marketplace

This repo remains a marketplace registry, but it no longer contains a
self-installable `aura` plugin. Use the `pasture` marketplace entry for the
generated protocol skills and agents.

## Development

Useful checks before landing changes:

```bash
nix flake check --no-build
nix build .#aura-swarm --no-link
nix run .#aura-swarm -- --help
```

The Python package metadata exists only to package `aura-swarm` and the retained
session registry helper. There are no third-party Python dependencies.
