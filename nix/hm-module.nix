{ self, pasture ? null }:

{ config
, pkgs
, lib ? config.lib
, ...
}:
let
  cfg = config.CUSTOM.programs.aura-config-sync;

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  roleNames = [ "architect" "supervisor" "worker" "reviewer" "epoch" ];

  pastureSourceDefault =
    if pasture == null
    then null
    else pasture.outPath or pasture;

  pastureSource = cfg.pasture.source;

  # Pasture emits distinct generated trees. Claude Code, OpenCode, and Codex must each
  # source from their own tree — they carry different frontmatter schemas (OpenCode
  # uses mode/permission + provider-qualified model ids; Claude Code uses tools/model).
  # Cross-wiring them ships wrong-schema files (breaks OpenCode agent loading).
  pastureSkillsDir = "${pastureSource}/skills";              # Claude Code target
  pastureAgentsDir = "${pastureSource}/agents";              # Claude Code target
  pastureOpenCodeSkillsDir = "${pastureSource}/.opencode/skill"; # OpenCode target
  pastureOpenCodeAgentsDir = "${pastureSource}/.opencode/agent"; # OpenCode target
  pastureCodexSkillsDir = "${pastureSource}/.agents/skills";     # Codex target
  pastureCodexAgentsDir = "${pastureSource}/.codex/agents";      # Codex target
  protocolDir = "${self}/skills/protocol";

  listMdFiles = dir:
    let
      entries = builtins.readDir dir;
      mdFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) entries;
    in
    lib.mapAttrs (name: _: "${dir}/${name}") mdFiles;

  listSkillFiles = dir:
    let
      entries = builtins.readDir dir;
      subdirs = lib.filterAttrs (name: type: type == "directory") entries;
    in
    lib.filterAttrs (name: path: builtins.pathExists path)
      (lib.mapAttrs (name: _: "${dir}/${name}/SKILL.md") subdirs);

  listTomlFiles = dir:
    let
      entries = builtins.readDir dir;
      tomlFiles = lib.filterAttrs
        (name: type: type == "regular" && lib.hasPrefix "pasture-" name && lib.hasSuffix ".toml" name)
        entries;
    in
    lib.mapAttrs (name: _: "${dir}/${name}") tomlFiles;

  readDirSucceeds = dir:
    builtins.pathExists dir
    && (builtins.tryEval (builtins.readDir dir)).success;

  # A local pasture.source override may not have generated the OpenCode target tree.
  # The `pastureSource != null &&` short-circuit keeps the "${null}/…" path from ever
  # being forced (Nix laziness) when no source is configured.
  pastureOpenCodeSkillsAvailable = pastureSource != null && builtins.pathExists pastureOpenCodeSkillsDir;
  pastureOpenCodeAgentsAvailable = pastureSource != null && builtins.pathExists pastureOpenCodeAgentsDir;
  pastureCodexSkillsAvailable =
    pastureSource != null
    && readDirSucceeds pastureCodexSkillsDir
    && builtins.length (builtins.attrNames (listSkillFiles pastureCodexSkillsDir)) > 0;
  pastureCodexAgentsAvailable =
    pastureSource != null
    && readDirSucceeds pastureCodexAgentsDir
    && builtins.length (builtins.attrNames (listTomlFiles pastureCodexAgentsDir)) > 0;

  # Apply the role enable/disable filtering to a given skills dir. Core (non-role)
  # skills are always installed; role skills only when that role is enabled. Shared
  # by both the Claude Code and OpenCode targets so they stay in lockstep.
  enabledSkillFilesFrom = skillsDir:
    let
      allSkills = listSkillFiles skillsDir;
      coreSkills =
        lib.filterAttrs
          (name: _: !(builtins.any (role: lib.hasPrefix role name) roleNames))
          allSkills;
      roleSkills = builtins.foldl'
        (acc: role:
          if cfg.commands.roles.${role}.enable
          then acc // (lib.filterAttrs (name: _: lib.hasPrefix role name) allSkills)
          else acc
        )
        { }
        roleNames;
    in
    coreSkills // roleSkills;

  # Claude Code sets (installed to ~/.claude/…).
  enabledPastureSkillFiles = (enabledSkillFilesFrom pastureSkillsDir) // cfg.commands.extraCommands;
  enabledPastureAgentFiles = (listMdFiles pastureAgentsDir) // cfg.agents.extraAgents;

  # OpenCode sets (installed to ~/.config/opencode/…) — sourced from the .opencode
  # target tree, or empty if that tree is absent (guarded by the assertion below).
  enabledOpenCodeSkillFiles =
    if pastureOpenCodeSkillsAvailable then enabledSkillFilesFrom pastureOpenCodeSkillsDir else { };
  enabledOpenCodeAgentFiles =
    if pastureOpenCodeAgentsAvailable then listMdFiles pastureOpenCodeAgentsDir else { };

  # Codex skills are installed to ~/.agents/… and custom agents to ~/.codex/… —
  # both are sourced only from Pasture's generated Codex trees. Codex agents are
  # standalone TOML files, not plugin manifests.
  enabledCodexSkillFiles =
    if pastureCodexSkillsAvailable then listSkillFiles pastureCodexSkillsDir else { };
  enabledCodexAgentFiles =
    if pastureCodexAgentsAvailable then listTomlFiles pastureCodexAgentsDir else { };

  usesPastureGenerated =
    cfg.commands.enable
    || cfg.agents.enable
    || cfg.opencode.skills.enable
    || cfg.opencode.agents.enable
    || cfg.codex.skills.enable
    || cfg.codex.agents.enable;

  usesOpenCode = cfg.opencode.skills.enable || cfg.opencode.agents.enable;
in
{
  options.CUSTOM.programs.aura-config-sync = {
    enable = mkEnableOption "Aura config sync: aura-swarm plus Pasture-generated skills and agents";

    pasture.source = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = pastureSourceDefault;
      defaultText = lib.literalExpression "pasture flake input";
      description = ''
        Source checkout for Pasture-generated skills/ and agents/ (and their
          .opencode/ OpenCode- and .agents/skills plus .codex/agents Codex-target counterparts). The
        aura-plugins flake passes the dayvidpham/pasture input by default. Override
        this for local Pasture development checkouts.
      '';
      example = lib.literalExpression "../pasture";
    };

    packages.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install aura-swarm.";
    };

    commands = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Pasture-generated skills into ~/.claude/skills/<name>/SKILL.md.";
      };

      roles = {
        enableAll = mkOption {
          type = types.bool;
          default = true;
          description = "Enable all generated role skills. Set false to pick individual roles.";
        };
      } // (builtins.listToAttrs (map
        (role: {
          name = role;
          value.enable = mkOption {
            type = types.bool;
            default = cfg.commands.roles.enableAll;
            description = "Install generated ${role} role skills.";
          };
        })
        roleNames
      ));

      extraCommands = mkOption {
        type = types.attrsOf (types.either types.path types.str);
        default = { };
        description = "Additional skill files to install. Keys are skill directory names; values are SKILL.md paths.";
        example = lib.literalExpression ''
          { "my-custom-skill" = ./my-skill/SKILL.md; }
        '';
      };
    };

    agents = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Pasture-generated agent definitions into ~/.claude/agents/.";
      };

      extraAgents = mkOption {
        type = types.attrsOf (types.either types.path types.str);
        default = { };
        description = "Additional Claude Code agent .md files to install.";
      };
    };

    opencode = {
      skills.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Pasture OpenCode-target skills (.opencode/skill) into ~/.config/opencode/skills/<name>/SKILL.md.";
      };

      agents.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Pasture OpenCode-target agents (.opencode/agent) into ~/.config/opencode/agent/<role>.md.";
      };
    };

    codex = {
      skills.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install Pasture Codex-target skills (.agents/skills) into ~/.agents/skills/<name>/SKILL.md.";
      };

      agents.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install Pasture Codex custom agents (.codex/agents) into ~/.codex/agents/pasture-<role>.toml.";
      };
    };

    protocol = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install local protocol docs. Disabled by default since projects may have their own instructions.";
      };

      target = mkOption {
        type = types.enum [ "global" "xdg" ];
        default = "global";
        description = "Where to install protocol docs. global = ~/.claude/, xdg = ~/.config/aura/protocol/.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = !usesPastureGenerated || pastureSource != null;
          message = ''
            CUSTOM.programs.aura-config-sync needs a Pasture source when generated
            skills or agents are enabled (evaluated during Home Manager activation).
            Without it, no Pasture-generated skills or agents can be installed under
            ~/.claude, ~/.config/opencode, ~/.agents, or ~/.codex. Set
            CUSTOM.programs.aura-config-sync.pasture.source to a Pasture checkout, or
            use the aura-plugins flake so its pasture input is supplied automatically.
          '';
        }
        {
          assertion = !cfg.codex.skills.enable
            || pastureSource == null
            || pastureCodexSkillsAvailable;
          message = ''
            CUSTOM.programs.aura-config-sync.codex.skills.enable is true, but the
            Pasture source does not contain the generated Codex skill tree
            (expected ${pastureCodexSkillsDir}/<name>/SKILL.md). Aura only consumes
            committed Pasture output and will not recreate protocol prose here.
            Generate Pasture's Codex target or point
            CUSTOM.programs.aura-config-sync.pasture.source at a checkout containing
            .agents/skills, then re-evaluate Home Manager.
          '';
        }
        {
          assertion = !cfg.codex.agents.enable
            || pastureSource == null
            || pastureCodexAgentsAvailable;
          message = ''
            CUSTOM.programs.aura-config-sync.codex.agents.enable is true, but the
            Pasture source does not contain the generated Codex custom-agent tree
            (expected ${pastureCodexAgentsDir}/pasture-<role>.toml). Aura only
            consumes committed Pasture TOMLs and will not invent a plugin manifest
            or agent definition. Generate Pasture's Codex target or point
            CUSTOM.programs.aura-config-sync.pasture.source at a checkout containing
            .codex/agents, then re-evaluate Home Manager.
          '';
        }
        {
          assertion = !usesOpenCode
            || pastureSource == null
            || (pastureOpenCodeSkillsAvailable && pastureOpenCodeAgentsAvailable);
          message = ''
            CUSTOM.programs.aura-config-sync.opencode.{skills,agents} is enabled, but
            the Pasture source does not contain the OpenCode target tree (expected
            ${pastureOpenCodeSkillsDir} and ${pastureOpenCodeAgentsDir}). This is
            evaluated during Home Manager activation; without that tree no OpenCode
            skills/agents can be installed, and installing the Claude Code tree in its
            place would ship files with the wrong (mode/permission-less) frontmatter.
            Fix by generating Pasture's OpenCode target (its .opencode/skill and
            .opencode/agent outputs), by pointing
            CUSTOM.programs.aura-config-sync.pasture.source at a checkout that has
            them, or by setting
            CUSTOM.programs.aura-config-sync.opencode.skills.enable = false and
            CUSTOM.programs.aura-config-sync.opencode.agents.enable = false.
          '';
        }
      ];
    }

    # ── Packages ──
    (mkIf cfg.packages.enable {
      home.packages = [
        self.packages.${pkgs.system}.aura-swarm
      ];
    })

    # ── Claude Code skills → ~/.claude/skills/<name>/SKILL.md ──
    (mkIf cfg.commands.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".claude/skills/${name}/SKILL.md";
          value.source = path;
        })
        enabledPastureSkillFiles;
    })

    # ── Claude Code agents → ~/.claude/agents/<role>.md ──
    (mkIf cfg.agents.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".claude/agents/${name}";
          value.source = path;
        })
        enabledPastureAgentFiles;
    })

    # ── OpenCode skills → ~/.config/opencode/skills/<name>/SKILL.md ──
    (mkIf cfg.opencode.skills.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".config/opencode/skills/${name}/SKILL.md";
          value.source = path;
        })
        enabledOpenCodeSkillFiles;
    })

    # ── OpenCode agents → ~/.config/opencode/agent/<role>.md ──
    (mkIf cfg.opencode.agents.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".config/opencode/agent/${name}";
          value.source = path;
        })
        enabledOpenCodeAgentFiles;
    })

    # Codex skills → ~/.agents/skills/<name>/SKILL.md
    (mkIf cfg.codex.skills.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".agents/skills/${name}/SKILL.md";
          value.source = path;
        })
        enabledCodexSkillFiles;
    })

    # Codex custom agents → ~/.codex/agents/pasture-<role>.toml
    (mkIf cfg.codex.agents.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".codex/agents/${name}";
          value.source = path;
        })
        enabledCodexAgentFiles;
    })

    # ── Protocol docs (opt-in) ──
    (mkIf cfg.protocol.enable (
      let
        prefix =
          if cfg.protocol.target == "global"
          then ".claude"
          else ".config/aura/protocol";
        protocolFiles = listMdFiles protocolDir;
      in
      {
        home.file = lib.mapAttrs'
          (name: path: {
            name = "${prefix}/${name}";
            value.source = path;
          })
          protocolFiles;
      }
    ))
  ]);
}
