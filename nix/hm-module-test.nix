# Evaluation tests for the aura-config-sync Home Manager module.
#
# Two layers:
#   1. Pure evaluation cases -> a PASS/FAIL report checked inside the build.
#   2. Realized projections diffed byte-for-byte against the source tree, both
#      for the hand-written fixture and (when supplied) the pinned Pasture input.
#
# Cases are bounded and representative: one per rule, plus per-cell isolation.
# There is no exhaustive cross-product of harnesses, cells, and destinations.
{ pkgs, pasture ? null }:

let
  inherit (pkgs) lib;
  inherit (lib) types;

  fileEntry = types.submodule {
    options.source = lib.mkOption { type = types.either types.path types.str; };
  };

  assertionEntry = types.submodule {
    options = {
      assertion = lib.mkOption { type = types.bool; };
      message = lib.mkOption { type = types.str; };
    };
  };

  homeFixture = {
    options = {
      assertions = lib.mkOption {
        type = types.listOf assertionEntry;
        default = [ ];
      };

      home = {
        homeDirectory = lib.mkOption {
          type = types.str;
          default = "/home/tester";
        };

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

  protocolFixture = pkgs.runCommand "aura-protocol-fixture" { } ''
    mkdir -p "$out/skills/protocol"
    echo "protocol doc" > "$out/skills/protocol/PROCESS.md"
  '';

  self = {
    outPath = protocolFixture;
    packages = lib.genAttrs [ pkgs.system ] (_: {
      aura-swarm = pkgs.writeText "aura-swarm-fixture" "fixture";
    });
  };

  # Source fixtures are path values so the module copies them into the store,
  # which is what makes the byte-identity diff below meaningful.
  fullSource = ./hm-module-test-data/full;
  emptySource = ./hm-module-test-data/empty;

  module = import ./hm-module.nix { inherit self; pasture = null; };

  optionRoot = "CUSTOM.programs.aura-config-sync";

  baseConfig = {
    CUSTOM.programs.aura-config-sync = {
      enable = true;
      packages.enable = false;
      pasture.source = fullSource;
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

  # Same, but without the fixture base — used for removed-option cases so the
  # legacy definition is the only thing under test.
  evaluateRaw = configuration: lib.evalModules {
    modules = [
      homeFixture
      module
      { _module.args.pkgs = pkgs; }
      { config = configuration; }
    ];
  };

  harnessConfig = harness: cells: {
    CUSTOM.programs.aura-config-sync.harnesses.${harness} = { enable = true; } // cells;
  };

  destinations = evaluated: lib.sort (a: b: a < b) (builtins.attrNames evaluated.config.home.file);

  passes = evaluated: builtins.all (item: item.assertion) evaluated.config.assertions;

  failureMessages = evaluated:
    map (item: item.message) (builtins.filter (item: !item.assertion) evaluated.config.assertions);

  failsWith = evaluated: needle:
    !(passes evaluated)
    && builtins.any (message: lib.hasInfix needle message) (failureMessages evaluated);

  onlyCell = harness: axis:
    harnessConfig harness (builtins.listToAttrs (map
      (other: { name = other; value.enable = other == axis; })
      [ "skills" "agents" "hooks" ]));

  # ── Expected fixture projections, per cell ───────────────────────────────
  expected = {
    "claude-code" = {
      skills = [
        ".claude/skills/example/SKILL.md"
        ".claude/skills/protocol/PROCESS.md"
        ".claude/skills/protocol/SKILL.md"
      ];
      agents = [ ".claude/agents/worker.md" ];
      hooks = [
        ".claude/hooks/hooks.json"
        ".claude/hooks/pasture-activation.json"
        ".claude/hooks/scripts/git-discipline.sh"
      ];
    };
    opencode = {
      skills = [ ".config/opencode/skills/example/SKILL.md" ];
      agents = [ ".config/opencode/agent/worker.md" ];
      hooks = [ ".config/opencode/plugins/pasture-hooks.ts" ];
    };
    codex = {
      skills = [ ".agents/skills/example/SKILL.md" ];
      agents = [ ".codex/agents/pasture-worker.toml" ];
      hooks = [
        ".codex/hooks.json"
        ".codex/hooks/events/SessionStart.sh"
        ".codex/pasture-codex-activation.json"
      ];
    };
  };

  sorted = list: lib.sort (a: b: a < b) list;

  harnessNames = [ "claude-code" "codex" "opencode" ];
  axisNames = [ "skills" "agents" "hooks" ];

  # ── Evaluations ──────────────────────────────────────────────────────────
  allOff = evaluate { };

  moduleDisabled = evaluate (lib.recursiveUpdate
    (harnessConfig "claude-code" { })
    { CUSTOM.programs.aura-config-sync.enable = false; });

  harnessAlone = lib.genAttrs harnessNames (harness: evaluate (harnessConfig harness { }));

  cellAlone = lib.genAttrs harnessNames
    (harness: lib.genAttrs axisNames (axis: evaluate (onlyCell harness axis)));

  everything = evaluate (lib.foldl' lib.recursiveUpdate { } (map
    (harness: harnessConfig harness { hooks.enable = true; })
    harnessNames));

  # Destination handling.
  relativeRoot = evaluate (lib.recursiveUpdate
    (harnessConfig "claude-code" { })
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".targetRoot = "nested/claude"; });

  absoluteRoot = evaluate (lib.recursiveUpdate
    (harnessConfig "claude-code" { })
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".targetRoot = "/home/tester/nested/claude"; });

  uncleanRoot = evaluate (lib.recursiveUpdate
    (harnessConfig "claude-code" { })
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".targetRoot = "./nested//claude/"; });

  cellOverride = evaluate (lib.recursiveUpdate
    (onlyCell "claude-code" "skills")
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".skills.target = "custom/skills"; });

  outsideHome = evaluate (lib.recursiveUpdate
    (harnessConfig "claude-code" { })
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".targetRoot = "/etc/claude"; });

  traversalTarget = evaluate (lib.recursiveUpdate
    (onlyCell "claude-code" "skills")
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".skills.target = "../escape/skills"; });

  # Both harnesses ship an agents file named worker.md, so pointing the two
  # agents cells at one directory produces a genuine same-path collision.
  collidingTargets = evaluate (lib.recursiveUpdate
    (lib.recursiveUpdate (onlyCell "claude-code" "agents") (onlyCell "opencode" "agents"))
    {
      CUSTOM.programs.aura-config-sync.harnesses."claude-code".agents.target = "shared/agents";
      CUSTOM.programs.aura-config-sync.harnesses.opencode.agents.target = "shared/agents";
    });

  overlappingTargets = evaluate (lib.recursiveUpdate
    (harnessConfig "claude-code" { })
    {
      CUSTOM.programs.aura-config-sync.harnesses."claude-code".skills.target = ".claude/nest";
      CUSTOM.programs.aura-config-sync.harnesses."claude-code".agents.target = ".claude/nest/inner";
    });

  missingSource = evaluate (lib.recursiveUpdate
    (harnessConfig "opencode" { })
    { CUSTOM.programs.aura-config-sync.pasture.source = emptySource; });

  missingPastureSource = evaluate (lib.recursiveUpdate
    (harnessConfig "codex" { })
    { CUSTOM.programs.aura-config-sync.pasture.source = lib.mkForce null; });

  protocolDocs = evaluate {
    CUSTOM.programs.aura-config-sync.protocol.enable = true;
  };

  removedCases = [
    { path = "commands.enable"; config.CUSTOM.programs.aura-config-sync.commands.enable = true; needle = "harnesses.\"claude-code\".skills.enable"; }
    { path = "commands.roles"; config.CUSTOM.programs.aura-config-sync.commands.roles.enableAll = false; needle = "Per-role skill filtering was removed"; }
    { path = "commands.extraCommands"; config.CUSTOM.programs.aura-config-sync.commands.extraCommands = { }; needle = "home.file"; }
    { path = "agents.enable"; config.CUSTOM.programs.aura-config-sync.agents.enable = true; needle = "harnesses.\"claude-code\".agents.enable"; }
    { path = "agents.extraAgents"; config.CUSTOM.programs.aura-config-sync.agents.extraAgents = { }; needle = "home.file"; }
    { path = "opencode.skills.enable"; config.CUSTOM.programs.aura-config-sync.opencode.skills.enable = true; needle = "harnesses.opencode.skills.enable"; }
    { path = "opencode.agents.enable"; config.CUSTOM.programs.aura-config-sync.opencode.agents.enable = true; needle = "harnesses.opencode.agents.enable"; }
    { path = "codex.skills.enable"; config.CUSTOM.programs.aura-config-sync.codex.skills.enable = true; needle = "harnesses.codex.skills.enable"; }
    { path = "codex.agents.enable"; config.CUSTOM.programs.aura-config-sync.codex.agents.enable = true; needle = "harnesses.codex.agents.enable"; }
  ];

  # The pinned Pasture input is the source Home Manager users actually consume.
  # These cases prove every one of the nine generated trees exists in it, so a
  # Pasture revision that stops emitting a tree fails here instead of silently
  # installing nothing on a user's machine.
  pastureCellEvaluation = harness: axis: evaluate (lib.recursiveUpdate
    (onlyCell harness axis)
    { CUSTOM.programs.aura-config-sync.pasture.source = lib.mkForce "${pasture}"; });

  pastureCases = lib.optionals pastureConfigured ([
    {
      name = "pinned Pasture input satisfies every module assertion with all nine cells enabled";
      ok = passes pastureEvaluation;
    }
  ] ++ lib.concatMap
    (harness: map
      (axis: {
        name = "pinned Pasture input provides a non-empty ${harness}/${axis} tree";
        ok =
          let evaluated = pastureCellEvaluation harness axis; in
          passes evaluated && destinations evaluated != [ ];
      })
      axisNames)
    harnessNames);

  removedEvaluations = map
    (entry: {
      name = "removed option ${optionRoot}.${entry.path} fails with its replacement path";
      ok =
        let evaluated = evaluateRaw entry.config; in
        failsWith evaluated "no longer has any effect" && failsWith evaluated entry.needle;
    })
    removedCases;

  cellIsolationCases = lib.concatMap
    (harness: map
      (axis: {
        name = "cell ${harness}/${axis} projects exactly its own files with siblings absent";
        ok = passes cellAlone.${harness}.${axis}
          && destinations cellAlone.${harness}.${axis} == sorted expected.${harness}.${axis};
      })
      axisNames)
    harnessNames;

  harnessAloneCases = map
    (harness: {
      name = "harness ${harness} alone projects skills and agents and no hooks";
      ok = passes harnessAlone.${harness}
        && destinations harnessAlone.${harness}
        == sorted (expected.${harness}.skills ++ expected.${harness}.agents);
    })
    harnessNames;

  cases = [
    { name = "all harnesses off projects no files"; ok = passes allOff && destinations allOff == [ ]; }
    { name = "module disabled projects no files even with a harness enabled"; ok = passes moduleDisabled && destinations moduleDisabled == [ ]; }
    {
      name = "every harness plus hooks projects all nine cells";
      ok = passes everything
        && destinations everything == sorted (lib.concatMap
        (harness: lib.concatMap (axis: expected.${harness}.${axis}) axisNames)
        harnessNames);
    }
    { name = "claude hooks cell excludes Pasture Go sources"; ok = !(builtins.elem ".claude/hooks/doc.go" (destinations cellAlone."claude-code".hooks)); }
    { name = "codex hooks cell excludes native config and agent files"; ok = !(lib.any (dest: lib.hasSuffix "codex.toml" dest || lib.hasInfix ".codex/agents/" dest) (destinations cellAlone.codex.hooks)); }
    { name = "no cell ever projects a Git hook path or Git configuration"; ok = !(lib.any (dest: lib.hasInfix ".git/" dest || lib.hasInfix "hooksPath" dest || lib.hasSuffix ".gitconfig" dest) (destinations everything)); }
    { name = "harness targetRoot relocates the derived destinations"; ok = passes relativeRoot && destinations relativeRoot == sorted [ "nested/claude/skills/example/SKILL.md" "nested/claude/skills/protocol/PROCESS.md" "nested/claude/skills/protocol/SKILL.md" "nested/claude/agents/worker.md" ]; }
    { name = "in-home absolute targetRoot normalizes identically to the relative form"; ok = destinations absoluteRoot == destinations relativeRoot; }
    { name = "unclean targetRoot normalizes identically to the clean form"; ok = destinations uncleanRoot == destinations relativeRoot; }
    { name = "per-cell target overrides the harness-derived destination"; ok = passes cellOverride && destinations cellOverride == sorted [ "custom/skills/example/SKILL.md" "custom/skills/protocol/PROCESS.md" "custom/skills/protocol/SKILL.md" ]; }
    { name = "target outside the managed home is rejected"; ok = failsWith outsideHome "does not resolve beneath home.homeDirectory"; }
    { name = "traversing target is rejected"; ok = failsWith traversalTarget "contains a '..' segment"; }
    { name = "colliding destinations are rejected"; ok = failsWith collidingTargets "claim the same destination"; }
    { name = "overlapping parent/child destinations are rejected"; ok = failsWith overlappingTargets "inside the destination directory owned by"; }
    { name = "missing generated tree is rejected with the expected source path"; ok = failsWith missingSource "contains no opencode skills tree" && failsWith missingSource ".opencode/skill"; }
    { name = "missing pasture source is rejected"; ok = failsWith missingPastureSource "no Pasture source is configured"; }
    { name = "protocol docs opt-in still projects local documentation"; ok = passes protocolDocs && destinations protocolDocs == [ ".claude/PROCESS.md" ]; }
  ]
  ++ harnessAloneCases
  ++ cellIsolationCases
  ++ pastureCases
  ++ removedEvaluations;

  report = lib.concatMapStrings
    (case: "${if case.ok then "PASS" else "FAIL"}\t${case.name}\n")
    cases;

  # ── Realized projections (byte identity) ─────────────────────────────────
  realize = name: evaluated: pkgs.runCommand name { } (''
    mkdir -p "$out"
  '' + lib.concatStrings (lib.mapAttrsToList
    (dest: entry: ''
      mkdir -p "$out/$(dirname ${lib.escapeShellArg dest})"
      cp -T ${lib.escapeShellArg (toString entry.source)} "$out/${dest}"
    '')
    evaluated.config.home.file));

  fixtureProjection = realize "aura-hm-fixture-projection" everything;

  pastureConfigured = pasture != null;

  pastureEvaluation = evaluate (lib.recursiveUpdate
    (lib.foldl' lib.recursiveUpdate { } (map (harness: harnessConfig harness { hooks.enable = true; }) harnessNames))
    { CUSTOM.programs.aura-config-sync.pasture.source = lib.mkForce "${pasture}"; });

  pastureProjection =
    if pastureConfigured
    then realize "aura-hm-pasture-projection" pastureEvaluation
    else pkgs.runCommand "aura-hm-pasture-projection-absent" { } ''mkdir -p "$out"'';

  # Compare one projected subtree against the exact source subtree it came from.
  compareTree = projection: source: relDestination: relSource: excludes: ''
    echo "byte identity: ${relDestination} <- ${relSource}"
    diff -r ${lib.concatMapStrings (pattern: "-x ${lib.escapeShellArg pattern} ") excludes} \
      ${source}/${relSource} ${projection}/${relDestination}
  '';

  compareFile = projection: source: relDestination: relSource: ''
    cmp ${source}/${relSource} ${projection}/${relDestination}
  '';

  identityScript = projection: source: ''
    ${compareTree projection source ".claude/skills" "skills" [ ]}
    ${compareTree projection source ".claude/agents" "agents" [ ]}
    ${compareTree projection source ".claude/hooks" "hooks" [ "*.go" ]}
    ${compareTree projection source ".config/opencode/skills" ".opencode/skill" [ ]}
    ${compareTree projection source ".config/opencode/agent" ".opencode/agent" [ ]}
    ${compareFile projection source ".config/opencode/plugins/pasture-hooks.ts" ".opencode/plugins/pasture-lifecycle.ts"}
    ${compareTree projection source ".agents/skills" ".agents/skills" [ ]}
    ${compareTree projection source ".codex/agents" ".codex/agents" [ ]}
    ${compareTree projection source ".codex/hooks" ".codex/hooks" [ ]}
    ${compareFile projection source ".codex/hooks.json" ".codex/hooks.json"}
    ${compareFile projection source ".codex/pasture-codex-activation.json" ".codex/pasture-codex-activation.json"}
    test ! -e ${projection}/.codex/codex.toml
  '';

in
pkgs.runCommand "aura-config-sync-hm-module-test"
{
  inherit report;
  passAsFile = [ "report" ];
  nativeBuildInputs = [ pkgs.diffutils ];
} ''
  cat "$reportPath"
  if grep -q '^FAIL' "$reportPath"; then
    echo "aura-config-sync Home Manager module test failed." >&2
    echo "The FAIL lines above name the rule that regressed; each corresponds to a" >&2
    echo "case in nix/hm-module-test.nix evaluated against nix/hm-module.nix." >&2
    exit 1
  fi

  ${identityScript fixtureProjection "${./hm-module-test-data/full}"}

  ${lib.optionalString pastureConfigured (identityScript pastureProjection "${pasture}")}

  touch "$out"
''
