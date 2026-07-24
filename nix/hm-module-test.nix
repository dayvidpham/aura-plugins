{ pkgs }:

let
  inherit (pkgs) lib;
  inherit (lib) types;

  fileEntry = types.submodule ({ ... }: {
    options.source = lib.mkOption {
      type = types.either types.path types.str;
    };
  });

  assertionEntry = types.submodule ({ ... }: {
    options = {
      assertion = lib.mkOption { type = types.bool; };
      message = lib.mkOption { type = types.str; };
    };
  });

  homeFixture = {
    options = {
      assertions = lib.mkOption {
        type = types.listOf assertionEntry;
        default = [ ];
      };

      home = {
        packages = lib.mkOption {
          type = types.listOf types.package;
          default = [ ];
        };

        file = lib.mkOption {
          type = types.attrsOf fileEntry;
          default = { };
        };
      };
    };
  };

  self = {
    packages = lib.genAttrs [ pkgs.system ] (_: {
      aura-swarm = pkgs.writeText "aura-swarm-fixture" "fixture";
    });
  };

  # These are source paths, rather than runCommand outputs, because the module
  # inspects their directory trees during evaluation. The missing-tree fixtures
  # deliberately omit the corresponding directory instead of creating it empty.
  sourceWithCodex = builtins.toString ./hm-module-test-data/with-codex;
  sourceWithoutSkills = builtins.toString ./hm-module-test-data/without-skills;
  sourceWithoutAgents = builtins.toString ./hm-module-test-data/without-agents;

  module = import ./hm-module.nix { inherit self; pasture = sourceWithCodex; };

  baseConfig = {
    CUSTOM.programs.aura-config-sync = {
      enable = true;
      packages.enable = false;
      commands.enable = false;
      agents.enable = false;
      opencode.skills.enable = false;
      opencode.agents.enable = false;
      protocol.enable = false;
    };
  };

  evaluate = extraConfig: lib.evalModules {
    modules = [
      homeFixture
      module
      { _module.args.pkgs = pkgs; }
      { config = lib.recursiveUpdate baseConfig extraConfig; }
    ];
  };

  assertionsPass = evaluated:
    builtins.all (item: item.assertion) evaluated.config.assertions;

  assertionMessageContains = evaluated: needle:
    builtins.any (item: lib.hasInfix needle item.message) evaluated.config.assertions;

  defaultConfig = evaluate { };
  disabledConfig = evaluate {
    CUSTOM.programs.aura-config-sync.enable = false;
    CUSTOM.programs.aura-config-sync.pasture.source = null;
  };
  disabledWithCodexConfig = evaluate {
    CUSTOM.programs.aura-config-sync.enable = false;
    CUSTOM.programs.aura-config-sync.pasture.source = null;
    CUSTOM.programs.aura-config-sync.codex.skills.enable = true;
    CUSTOM.programs.aura-config-sync.codex.agents.enable = true;
  };
  enabledConfig = evaluate {
    CUSTOM.programs.aura-config-sync.codex.skills.enable = true;
    CUSTOM.programs.aura-config-sync.codex.agents.enable = true;
  };
  missingSourceConfig = evaluate {
    CUSTOM.programs.aura-config-sync.pasture.source = null;
    CUSTOM.programs.aura-config-sync.codex.skills.enable = true;
  };
  missingSkillsConfig = evaluate {
    CUSTOM.programs.aura-config-sync.pasture.source = sourceWithoutSkills;
    CUSTOM.programs.aura-config-sync.codex.skills.enable = true;
  };
  missingAgentsConfig = evaluate {
    CUSTOM.programs.aura-config-sync.pasture.source = sourceWithoutAgents;
    CUSTOM.programs.aura-config-sync.codex.agents.enable = true;
  };

in
assert assertionsPass defaultConfig;
assert builtins.attrNames defaultConfig.config.home.file == [ ];
assert assertionsPass disabledConfig;
assert builtins.attrNames disabledConfig.config.home.file == [ ];
assert assertionsPass disabledWithCodexConfig;
assert builtins.attrNames disabledWithCodexConfig.config.home.file == [ ];
assert assertionsPass enabledConfig;
assert builtins.attrNames enabledConfig.config.home.file == [
  ".agents/skills/example/SKILL.md"
  ".codex/agents/pasture-worker.toml"
];
assert enabledConfig.config.home.file.".agents/skills/example/SKILL.md".source == "${sourceWithCodex}/.agents/skills/example/SKILL.md";
assert enabledConfig.config.home.file.".codex/agents/pasture-worker.toml".source == "${sourceWithCodex}/.codex/agents/pasture-worker.toml";
assert !(assertionsPass missingSourceConfig);
assert assertionMessageContains missingSourceConfig "needs a Pasture source";
assert !(assertionsPass missingSkillsConfig);
assert assertionMessageContains missingSkillsConfig "generated Codex skill tree";
assert !(assertionsPass missingAgentsConfig);
assert assertionMessageContains missingAgentsConfig "generated Codex custom-agent tree";
pkgs.runCommand "aura-config-sync-codex-module-test" { } ''
  touch "$out"
''
