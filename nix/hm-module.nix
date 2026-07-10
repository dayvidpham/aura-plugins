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
  pastureSkillsDir = "${pastureSource}/skills";
  pastureAgentsDir = "${pastureSource}/agents";
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

  allPastureSkillFiles = listSkillFiles pastureSkillsDir;
  allPastureAgentFiles = listMdFiles pastureAgentsDir;

  skillsForRole = role:
    lib.filterAttrs
      (name: _: lib.hasPrefix role name)
      allPastureSkillFiles;

  coreSkillFiles =
    lib.filterAttrs
      (name: _:
        let
          isRoleSpecific = builtins.any (role: lib.hasPrefix role name) roleNames;
        in
        !isRoleSpecific
      )
      allPastureSkillFiles;

  enabledPastureSkillFiles =
    let
      roleFiles = builtins.foldl'
        (acc: role:
          if cfg.commands.roles.${role}.enable
          then acc // (skillsForRole role)
          else acc
        )
        { }
        roleNames;
    in
    coreSkillFiles // roleFiles // cfg.commands.extraCommands;

  enabledPastureAgentFiles = allPastureAgentFiles // cfg.agents.extraAgents;

  usesPastureGenerated =
    cfg.commands.enable
    || cfg.agents.enable
    || cfg.opencode.skills.enable
    || cfg.opencode.agents.enable;
in
{
  options.CUSTOM.programs.aura-config-sync = {
    enable = mkEnableOption "Aura config sync: aura-swarm plus Pasture-generated skills and agents";

    pasture.source = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = pastureSourceDefault;
      defaultText = lib.literalExpression "pasture flake input";
      description = ''
        Source checkout for Pasture-generated skills/ and agents/. The aura-plugins
        flake passes the dayvidpham/pasture input by default. Override this for
        local Pasture development checkouts.
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
        description = "Install Pasture-generated skills into ~/.config/opencode/skills/<name>/SKILL.md.";
      };

      agents.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Pasture-generated agents into ~/.config/opencode/agent/<role>.md.";
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
            skills or agents are enabled. Set CUSTOM.programs.aura-config-sync.pasture.source
            to a Pasture checkout, or use the aura-plugins flake so its pasture input
            is supplied automatically.
          '';
        }
      ];
    }

    (mkIf cfg.packages.enable {
      home.packages = [
        self.packages.${pkgs.system}.aura-swarm
      ];
    })

    (mkIf cfg.commands.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".claude/skills/${name}/SKILL.md";
          value.source = path;
        })
        enabledPastureSkillFiles;
    })

    (mkIf cfg.agents.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".claude/agents/${name}";
          value.source = path;
        })
        enabledPastureAgentFiles;
    })

    (mkIf cfg.opencode.skills.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".config/opencode/skills/${name}/SKILL.md";
          value.source = path;
        })
        enabledPastureSkillFiles;
    })

    (mkIf cfg.opencode.agents.enable {
      home.file = lib.mapAttrs'
        (name: path: {
          name = ".config/opencode/agent/${name}";
          value.source = path;
        })
        enabledPastureAgentFiles;
    })

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
