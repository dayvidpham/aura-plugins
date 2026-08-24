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

The module installs `aura-swarm` and projects Pasture's generated harness trees
into the managed home with pure Nix file ownership. The schema is a closed
three-by-three matrix: three harnesses (`claude-code`, `opencode`, `codex`) each
with a `skills`, `agents`, and `hooks` cell. Every cell is sourced from that
harness's own generated tree in the pinned Pasture flake input — Aura never
recreates protocol content, never substitutes one harness's files for another,
never runs Pasture's installer or a native plugin manager, and never writes
Pasture's installation inventory or any harness's private trust state.

```nix
{
  imports = [ aura-plugins.homeManagerModules.aura-config-sync ];

  CUSTOM.programs.aura-config-sync = {
    enable = true;
    packages.enable = true;

    # Harnesses are opt-in. Within an enabled harness, skills and agents are on
    # by default and hooks are off by default.
    harnesses."claude-code" = {
      enable = true;               # ~/.claude/skills/…, ~/.claude/agents/…
      hooks.enable = true;         # ~/.claude/hooks/… (payload files only)
    };

    harnesses.opencode.enable = true;
      # ~/.config/opencode/skills/<name>/SKILL.md
      # ~/.config/opencode/agent/<role>.md
      # hooks (opt-in): ~/.config/opencode/plugins/pasture-hooks.ts

    harnesses.codex = {
      enable = true;               # ~/.agents/skills/…, ~/.codex/agents/…
      agents.enable = true;
      skills.target = "some/other/skills";  # per-cell destination override
    };

    protocol.enable = false;       # optional local protocol docs sync
  };
}
```

Destinations are configurable. Each harness has a `targetRoot` (defaults:
`.claude`, `.config/opencode`, and the home directory itself for Codex, whose
native layout spans `~/.agents` and `~/.codex`), and each cell may set its own
`target`, which wins over the harness-derived destination. Destinations may be
home-relative or absolute; an absolute path is accepted only when it resolves
beneath `home.homeDirectory`. Paths outside the managed home, `..` traversal,
colliding destinations, and parent/child ownership overlap are all rejected
during evaluation, before any file is realized.

Hook cells project hook *payload files* only. The module never installs a Git
hook, never touches `core.hooksPath`, and never edits a harness's private trust
or enablement state; switching a projected hook payload on remains a deliberate
action in the harness's own configuration.

The previous flat options (`commands.*`, `agents.*`, `opencode.*`, `codex.*`)
were removed rather than aliased. Defining any of them fails evaluation with the
exact replacement path, for example
`CUSTOM.programs.aura-config-sync.harnesses."claude-code".skills.enable`.

These destinations follow the official [Codex skill documentation](https://learn.chatgpt.com/docs/build-skills)
and [custom-agent documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents?surface=app).
The [plugin documentation](https://learn.chatgpt.com/docs/build-plugins) describes
plugins as packages containing skills and/or an MCP server, so custom-agent TOMLs
remain this module's separate Home Manager projection. The former `.codex/skills`
path is superseded; this module installs no duplicate skill tree.

This Home Manager projection and the imperative `pasture install` workflow are
two independent installation paths: the home-manager installation exists for
those who are using NixOS and want declarative opt-in. the imperative `pasture
install` work exists for those who are not doing so, or want something more
flexible with less overhead. Home Manager activation regenerates the managed
files, so imperative edits made directly to those projected paths do not persist
across the next activation.

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
