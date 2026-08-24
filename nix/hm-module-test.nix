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

  # worker.md exists so a protocol destination can be made to collide with a
  # harness cell, proving the docs take part in the same destination checks.
  protocolFixture = pkgs.runCommand "aura-protocol-fixture" { } ''
    mkdir -p "$out/skills/protocol"
    echo "protocol doc" > "$out/skills/protocol/PROCESS.md"
    echo "protocol worker doc" > "$out/skills/protocol/worker.md"
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

  inherit (hmlib) harnessNames axisNames;

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

  # A layout-locked cell refuses relocation instead of installing an inert
  # payload whose own public configuration points at the old path.
  codexHooksTargetOverride = evaluate (lib.recursiveUpdate
    (onlyCell "codex" "hooks")
    { CUSTOM.programs.aura-config-sync.harnesses.codex.hooks.target = "somewhere/else"; });

  codexHooksRootOverride = evaluate (lib.recursiveUpdate
    (onlyCell "codex" "hooks")
    { CUSTOM.programs.aura-config-sync.harnesses.codex.targetRoot = "relocated"; });

  codexSkillsRootOverride = evaluate (lib.recursiveUpdate
    (onlyCell "codex" "skills")
    { CUSTOM.programs.aura-config-sync.harnesses.codex.targetRoot = "relocated"; });

  tildeTarget = evaluate (lib.recursiveUpdate
    (onlyCell "claude-code" "skills")
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".skills.target = "~/claude/skills"; });

  homeRootTarget = evaluate (lib.recursiveUpdate
    (onlyCell "claude-code" "skills")
    { CUSTOM.programs.aura-config-sync.harnesses."claude-code".skills.target = "."; });

  protocolCollides = evaluate {
    CUSTOM.programs.aura-config-sync.protocol.enable = true;
    CUSTOM.programs.aura-config-sync.harnesses."claude-code" = {
      enable = true;
      skills.enable = false;
      agents.target = ".claude";
    };
  };

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
    { path = "commands.enable"; config.CUSTOM.programs.aura-config-sync.commands.enable = true; needle = "${optionRoot}.harnesses.\"claude-code\".skills.enable"; }
    { path = "commands.roles"; config.CUSTOM.programs.aura-config-sync.commands.roles.enableAll = false; needle = "${optionRoot}.harnesses.\"claude-code\".skills.enable"; }
    { path = "commands.extraCommands"; config.CUSTOM.programs.aura-config-sync.commands.extraCommands = { }; needle = "home.file.\".claude/skills/my-skill/SKILL.md\".source"; }
    { path = "agents.enable"; config.CUSTOM.programs.aura-config-sync.agents.enable = true; needle = "${optionRoot}.harnesses.\"claude-code\".agents.enable"; }
    { path = "agents.extraAgents"; config.CUSTOM.programs.aura-config-sync.agents.extraAgents = { }; needle = "home.file.\".claude/agents/my-agent.md\".source"; }
    { path = "opencode.skills.enable"; config.CUSTOM.programs.aura-config-sync.opencode.skills.enable = true; needle = "${optionRoot}.harnesses.opencode.skills.enable"; }
    { path = "opencode.agents.enable"; config.CUSTOM.programs.aura-config-sync.opencode.agents.enable = true; needle = "${optionRoot}.harnesses.opencode.agents.enable"; }
    { path = "codex.skills.enable"; config.CUSTOM.programs.aura-config-sync.codex.skills.enable = true; needle = "${optionRoot}.harnesses.codex.skills.enable"; }
    { path = "codex.agents.enable"; config.CUSTOM.programs.aura-config-sync.codex.agents.enable = true; needle = "${optionRoot}.harnesses.codex.agents.enable"; }
  ];

  # A removed option must be inert as well as loud: defining the legacy option
  # (with a valid source present) must project nothing at all, proving it is not
  # a functional alias for the cell that replaced it.
  legacyAliasProjectsNothing = evaluateRaw (lib.recursiveUpdate baseConfig {
    CUSTOM.programs.aura-config-sync.commands.enable = true;
    CUSTOM.programs.aura-config-sync.agents.enable = true;
    CUSTOM.programs.aura-config-sync.opencode.skills.enable = true;
    CUSTOM.programs.aura-config-sync.codex.agents.enable = true;
  });

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
    { name = "protocol docs opt-in still projects local documentation"; ok = passes protocolDocs && destinations protocolDocs == sorted [ ".claude/PROCESS.md" ".claude/worker.md" ]; }
    { name = "protocol docs take part in the collision check"; ok = failsWith protocolCollides "claim the same destination"; }
    { name = "codex hooks refuse a per-cell target override"; ok = failsWith codexHooksTargetOverride "layout-locked" && failsWith codexHooksTargetOverride ".codex/hooks.json" && destinations codexHooksTargetOverride == [ ]; }
    { name = "codex hooks refuse a harness targetRoot that moves them"; ok = failsWith codexHooksRootOverride "layout-locked"; }
    { name = "a codex targetRoot override is still allowed for unlocked cells"; ok = passes codexSkillsRootOverride && destinations codexSkillsRootOverride == [ "relocated/.agents/skills/example/SKILL.md" ]; }
    { name = "tilde-prefixed target is rejected"; ok = failsWith tildeTarget "does not expand"; }
    { name = "target resolving to the home directory itself is rejected"; ok = failsWith homeRootTarget "home directory itself"; }
    { name = "a removed option is inert as well as loud"; ok = builtins.attrNames legacyAliasProjectsNothing.config.home.file == [ ]; }
    { name = "the pinned Pasture input is wired into this check"; ok = pastureConfigured; }
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

  # ── Byte identity, derived from the layout table ─────────────────────────
  # The comparison plan is generated from hmlib.harnesses so this file never
  # restates the layout a third time: a cell added to or moved in the table is
  # compared automatically.
  hmlib = import ./hm-lib.nix { inherit lib; };

  quote = lib.escapeShellArg;

  cellPlan = harness: axis:
    let
      spec = hmlib.harnesses.${harness}.cells.${axis};
      target = hmlib.joinComponents (hmlib.defaultTargetComponents harness axis);
      siblingRoot = hmlib.joinComponents (hmlib.parentComponents (hmlib.defaultTargetComponents harness axis));
      renames = spec.renames or { };
      excludes = map (suffix: "*${suffix}") (spec.excludeSuffixes or [ ]);
    in
    source: projection: ''
      echo "byte identity: ${harness}/${axis}  ${spec.sourceDir} -> ${target}"
      compare_dir ${quote "${source}/${spec.sourceDir}"} ${quote "${projection}/${target}"} \
        ${lib.concatMapStringsSep " " (rename: "--rename ${quote rename}")
          (lib.mapAttrsToList (from: to: "${from}:${to}") renames)} \
        ${lib.concatMapStringsSep " " (pattern: "--exclude ${quote pattern}") excludes}
      ${lib.concatMapStrings
        (entry: ''
          compare_file ${quote "${source}/${entry.source}"} \
            ${quote "${projection}/${if siblingRoot == "" then entry.name else "${siblingRoot}/${entry.name}"}"}
        '')
        (spec.siblings or [ ])}
    '';

  identityScript = projection: source: lib.concatStrings (lib.concatMap
    (harness: map (axis: cellPlan harness axis source projection) axisNames)
    harnessNames)
  + ''
    # Native harness configuration and trust state must never be projected.
    test ! -e ${quote "${projection}/.codex/codex.toml"}
    # The one script-bearing member Pasture ships executable must stay executable.
    test -x ${quote "${projection}/.claude/hooks/scripts/git-discipline.sh"}
  '';

  comparisonHelpers = ''
    compare_file() {
      cmp "$1" "$2"
      local left right
      left=$(stat -c %a "$1")
      right=$(stat -c %a "$2")
      if [ "$left" != "$right" ]; then
        echo "mode mismatch: $2 is $right but its source $1 is $left" >&2
        echo "The projection must preserve the mode Pasture generated, so an" >&2
        echo "executable hook script stays executable." >&2
        exit 1
      fi
    }

    compare_dir() {
      local src="$1" dst="$2"; shift 2
      local -a excludes=() renames=()
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --exclude) excludes+=(-x "$2"); shift 2 ;;
          --rename) renames+=("$2"); shift 2 ;;
          *) echo "compare_dir: unexpected argument $1" >&2; exit 1 ;;
        esac
      done

      local compare="$src"
      if [ "''${#renames[@]}" -gt 0 ]; then
        compare=$(mktemp -d)
        cp -r "$src/." "$compare"
        chmod -R u+w "$compare"
        local pair
        for pair in "''${renames[@]}"; do
          mv "$compare/''${pair%%:*}" "$compare/''${pair##*:}"
        done
        # Restore the read-only store modes the copy relaxed, so the mode
        # comparison below still compares against what Pasture shipped.
        chmod -R a-w "$compare"
      fi

      diff -r "''${excludes[@]}" "$compare" "$dst"

      local relative
      while IFS= read -r relative; do
        compare_file "$compare/$relative" "$dst/$relative"
      done < <(cd "$dst" && find . -type f | sort)
    }
  '';

  # The full destination set of the pinned input is pinned in-tree: bumping the
  # pasture input must show up as a reviewable diff of exactly which files a
  # user's home gains or loses, not as a silent change.
  pinnedDestinations = lib.concatMapStrings (dest: "${dest}\n")
    (destinations pastureEvaluation);

in
pkgs.runCommand "aura-config-sync-hm-module-test"
{
  inherit report pinnedDestinations;
  passAsFile = [ "report" "pinnedDestinations" ];
  nativeBuildInputs = [ pkgs.diffutils ];
} ''
  cat "$reportPath"
  if grep -q '^FAIL' "$reportPath"; then
    echo "aura-config-sync Home Manager module test failed." >&2
    echo "The FAIL lines above name the rule that regressed; each corresponds to a" >&2
    echo "case in nix/hm-module-test.nix evaluated against nix/hm-module.nix." >&2
    exit 1
  fi

  ${comparisonHelpers}

  ${identityScript fixtureProjection "${./hm-module-test-data/full}"}

  ${lib.optionalString pastureConfigured ''
    ${identityScript pastureProjection "${pasture}"}

    if ! diff -u ${./hm-module-test-data/pinned-destinations.txt} "$pinnedDestinationsPath"; then
      echo "The set of files projected from the pinned Pasture input changed." >&2
      echo "If that is intended (for example after bumping the pasture flake input)," >&2
      echo "refresh nix/hm-module-test-data/pinned-destinations.txt from the '+'/'-'" >&2
      echo "lines above and review the diff: it is exactly what a user's home gains" >&2
      echo "or loses on the next activation." >&2
      exit 1
    fi
  ''}

  touch "$out"
''
