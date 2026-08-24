# Home Manager module: declaratively project Pasture's generated harness trees
# into the managed home.
#
# The module is a pure Nix projection. It reads the pinned Pasture flake input
# and declares `home.file` entries; it never runs Pasture's installer, never
# drives a native plugin manager, never touches the network, and never writes
# Pasture's operational installation inventory. Hook cells project hook *files*
# only — never Git hooks, never core.hooksPath, never private harness trust
# state (enabling a projected hook payload stays a deliberate user action).
{ self, pasture ? null }:

{ config
, pkgs
, lib ? config.lib
, ...
}:
let
  hmlib = import ./hm-lib.nix { inherit lib; };

  cfg = config.CUSTOM.programs.aura-config-sync;

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkRemovedOptionModule
    types
    ;

  inherit (hmlib)
    axisNames
    harnessNames
    harnesses
    isComponentPrefix
    joinComponents
    normalizeTarget
    projectCell
    splitComponents
    ;

  optionRoot = "CUSTOM.programs.aura-config-sync";
  harnessPath = harness: "${optionRoot}.harnesses.\"${harness}\"";
  cellPath = harness: axis: "${harnessPath harness}.${axis}";

  pastureSourceDefault =
    if pasture == null
    then null
    else pasture.outPath or pasture;

  pastureSource = cfg.pasture.source;

  # Interpolated (not toString'd) so a plain-path override is copied into the
  # store rather than referenced from an impure filesystem location.
  sourceRoot = if pastureSource == null then null else "${pastureSource}";

  protocolDir = "${self}/skills/protocol";

  # home.homeDirectory is mandatory in a real Home Manager evaluation, but the
  # module only needs it to validate absolute destinations. Reading it lazily
  # keeps purely relative configurations evaluable even before the user sets it.
  homeDirectory =
    let probe = builtins.tryEval config.home.homeDirectory;
    in if probe.success then probe.value else null;

  # ── Per-cell resolution ──────────────────────────────────────────────────
  resolveCell = harness: axis:
    let
      harnessCfg = cfg.harnesses.${harness};
      cellCfg = harnessCfg.${axis};
      spec = harnesses.${harness}.cells.${axis};

      enabled = cfg.enable && harnessCfg.enable && cellCfg.enable;

      rootResult = normalizeTarget {
        inherit homeDirectory;
        value = harnessCfg.targetRoot;
      };

      overrideResult =
        if cellCfg.target == null
        then null
        else normalizeTarget { inherit homeDirectory; value = cellCfg.target; };

      usesOverride = overrideResult != null;

      # A per-cell target replaces the harness-root-derived destination.
      derived = (rootResult.components or [ ]) ++ splitComponents spec.subdir;

      targetOk =
        if usesOverride then overrideResult.ok else rootResult.ok;

      targetComponents =
        if usesOverride then (overrideResult.components or [ ]) else derived;

      failedOption =
        if usesOverride then "${cellPath harness axis}.target" else "${harnessPath harness}.targetRoot";

      failedValue =
        if usesOverride then cellCfg.target else harnessCfg.targetRoot;

      failedReason =
        if targetOk then null
        else if usesOverride then overrideResult.reason else rootResult.reason;

      sourceDir = "${sourceRoot}/${spec.sourceDir}";

      files =
        if enabled && targetOk && pastureSource != null
        then projectCell { source = sourceRoot; cell = spec; inherit targetComponents; }
        else { };
    in
    {
      inherit harness axis enabled targetOk targetComponents files sourceDir;
      inherit failedOption failedValue failedReason;
      path = cellPath harness axis;
      destinations = lib.attrNames files;
    };

  cells = lib.concatMap (harness: map (axis: resolveCell harness axis) axisNames) harnessNames;

  enabledCells = builtins.filter (cell: cell.enabled) cells;

  anyEnabled = enabledCells != [ ];

  # ── Assertions ───────────────────────────────────────────────────────────
  sourceAssertion = {
    assertion = !anyEnabled || pastureSource != null;
    message = ''
      ${optionRoot}: no Pasture source is configured, but ${toString (builtins.length enabledCells)} harness cell(s) are enabled.
      Why: ${optionRoot}.pasture.source is null, so there is no pinned tree to project from; this is evaluated while building the Home Manager generation.
      Where: nix/hm-module.nix, source assertion.
      Impact: none of the enabled skills/agents/hooks files can be placed in the managed home.
      Fix: consume this module through the aura-plugins flake (which passes its pinned pasture input automatically), or set ${optionRoot}.pasture.source to a Pasture checkout that contains the generated harness trees.
    '';
  };

  targetReasonText = cell:
    if cell.failedReason == "traversal" then
      "the path contains a '..' segment, which would escape the destination it is written under"
    else if cell.failedReason == "outside-home" then
      "the absolute path does not resolve beneath home.homeDirectory (${toString homeDirectory})"
    else
      "the path is absolute but home.homeDirectory is not set, so it cannot be proven to stay inside the managed home";

  targetAssertions = map
    (cell: {
      assertion = cell.targetOk;
      message = ''
        ${cell.failedOption}: rejected destination "${toString cell.failedValue}" for the ${cell.harness} ${cell.axis} cell.
        Why: ${targetReasonText cell}. Home Manager may only own paths inside the managed home.
        Where: nix/hm-module.nix, destination normalization for ${cell.path}.
        When: while resolving destinations, before any file is realized.
        Impact: the ${cell.harness} ${cell.axis} files are not projected and the generation is refused.
        Fix: use a path relative to the home directory (for example "${joinComponents (splitComponents harnesses.${cell.harness}.defaultRoot ++ splitComponents harnesses.${cell.harness}.cells.${cell.axis}.subdir)}") or an absolute path beneath home.homeDirectory, with no '..' segments.
      '';
    })
    (builtins.filter (cell: cell.enabled && !cell.targetOk) cells);

  missingSourceAssertions = map
    (cell: {
      assertion = false;
      message = ''
        ${cell.path}.enable is true, but the Pasture source contains no ${cell.harness} ${cell.axis} tree.
        Why: no files were found under ${cell.sourceDir}; Aura consumes committed Pasture output only and will never synthesize harness files or substitute another harness's tree.
        Where: nix/hm-module.nix, projection of ${cell.path}.
        When: while enumerating the pinned Pasture source, before any file is realized.
        Impact: enabling this cell would silently install nothing, so the generation is refused instead.
        Fix: point ${optionRoot}.pasture.source at a Pasture revision whose generated ${cell.harness} ${cell.axis} tree exists (run `make generate` in Pasture and commit the output), or set ${cell.path}.enable = false.
      '';
    })
    (builtins.filter
      (cell: cell.enabled && cell.targetOk && pastureSource != null && cell.files == { })
      cells);

  # Destination collisions: two enabled cells claiming the same home path.
  allDestinations = lib.concatMap
    (cell: map (dest: { inherit dest; owner = cell.path; }) cell.destinations)
    (builtins.filter (cell: cell.targetOk) enabledCells);

  duplicateDestinations = lib.unique (map (entry: entry.dest)
    (builtins.filter
      (entry: builtins.length (builtins.filter (other: other.dest == entry.dest) allDestinations) > 1)
      allDestinations));

  collisionAssertions = map
    (dest: {
      assertion = false;
      message = ''
        ${optionRoot}: two enabled harness cells claim the same destination "${dest}".
        Why: the cells ${lib.concatStringsSep " and " (lib.unique (map (entry: entry.owner) (builtins.filter (entry: entry.dest == dest) allDestinations)))} resolve to one home path, so Home Manager would be asked to own the same file twice with different contents.
        Where: nix/hm-module.nix, destination collision check.
        When: while resolving destinations, before any file is realized.
        Impact: the projected tree would be ambiguous and the generation is refused.
        Fix: give one of those cells a distinct destination via its own `target` option, or via its harness `targetRoot`.
      '';
    })
    duplicateDestinations;

  # Ownership overlap: a cell's file landing inside another cell's directory.
  overlapPairs = lib.concatMap
    (cell: lib.concatMap
      (other:
        if other.path == cell.path then [ ]
        else
          let
            inside = builtins.filter
              (dest:
                let parts = splitComponents dest; in
                isComponentPrefix other.targetComponents parts
                && builtins.length parts > builtins.length other.targetComponents)
              cell.destinations;
          in
          if inside == [ ] then [ ] else [{ inherit cell other; example = builtins.head inside; }])
      (builtins.filter (candidate: candidate.targetOk) enabledCells))
    (builtins.filter (candidate: candidate.targetOk) enabledCells);

  overlapAssertions = map
    (pair: {
      assertion = false;
      message = ''
        ${optionRoot}: the ${pair.cell.harness} ${pair.cell.axis} cell writes "${pair.example}" inside the destination directory owned by ${pair.other.path} ("${joinComponents pair.other.targetComponents}").
        Why: overlapping destinations make two cells co-own one directory subtree, so disabling or removing either cell would corrupt the other's files.
        Where: nix/hm-module.nix, destination overlap check.
        When: while resolving destinations, before any file is realized.
        Impact: the generation is refused rather than producing a tree with ambiguous ownership.
        Fix: move one cell to a disjoint destination with its `target` option, or change the harness `targetRoot` so the two subtrees no longer nest.
      '';
    })
    overlapPairs;

  projectedFiles = lib.foldl' (acc: cell: acc // cell.files) { }
    (builtins.filter (cell: cell.targetOk) enabledCells);

  # ── Option construction ──────────────────────────────────────────────────
  hooksNote = ''
    This cell places hook payload *files* only. It never writes Git hooks, never
    sets core.hooksPath, and never edits the harness's private trust or enablement
    state — turning a projected hook payload on stays a deliberate user action in
    the harness's own configuration.
  '';

  cellOption = harness: axis: defaultEnable: {
    enable = mkOption {
      type = types.bool;
      default = defaultEnable;
      description = ''
        Project Pasture's generated ${harness} ${axis} tree into the managed home.
        Inert unless ${harnessPath harness}.enable is also true.
        ${lib.optionalString (axis == "hooks") hooksNote}
      '';
    };

    target = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Destination directory for the ${harness} ${axis} cell, overriding the
        destination derived from ${harnessPath harness}.targetRoot. Accepts a
        path relative to the home directory, or an absolute path that resolves
        beneath home.homeDirectory. The per-cell value always wins.
      '';
      example = joinComponents (splitComponents harnesses.${harness}.defaultRoot
        ++ splitComponents harnesses.${harness}.cells.${axis}.subdir);
    };
  };

  harnessOption = harness: {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Project Pasture's generated ${harness} trees into the managed home.";
    };

    targetRoot = mkOption {
      type = types.str;
      default = harnesses.${harness}.defaultRoot;
      description = ''
        Destination root for the ${harness} harness. Each enabled cell is placed
        below this root at its harness-native subdirectory unless the cell sets
        its own `target`. Accepts a home-relative path or an absolute path
        beneath home.homeDirectory.
      '';
    };

    skills = cellOption harness "skills" true;
    agents = cellOption harness "agents" true;
    hooks = cellOption harness "hooks" false;
  };

  removedFlatOption = pathTail: replacement:
    mkRemovedOptionModule ([ "CUSTOM" "programs" "aura-config-sync" ] ++ pathTail) replacement;
in
{
  imports = [
    (removedFlatOption [ "commands" "enable" ] ''
      Use ${optionRoot}.harnesses."claude-code".enable = true; together with
      ${optionRoot}.harnesses."claude-code".skills.enable (default true).
    '')
    (removedFlatOption [ "commands" "roles" ] ''
      Per-role skill filtering was removed. A harness cell projects the complete
      generated tree, so use ${optionRoot}.harnesses."claude-code".skills.enable
      to turn the Claude Code skills cell on or off as a whole.
    '')
    (removedFlatOption [ "commands" "extraCommands" ] ''
      Aura projects Pasture-generated trees only. Declare your own skills with a
      plain home.file entry, for example
      home.file.".claude/skills/my-skill/SKILL.md".source = ./my-skill/SKILL.md;
    '')
    (removedFlatOption [ "agents" "enable" ] ''
      Use ${optionRoot}.harnesses."claude-code".enable = true; together with
      ${optionRoot}.harnesses."claude-code".agents.enable (default true).
    '')
    (removedFlatOption [ "agents" "extraAgents" ] ''
      Aura projects Pasture-generated trees only. Declare your own agents with a
      plain home.file entry, for example
      home.file.".claude/agents/my-agent.md".source = ./my-agent.md;
    '')
    (removedFlatOption [ "opencode" "skills" "enable" ] ''
      Use ${optionRoot}.harnesses.opencode.enable = true; together with
      ${optionRoot}.harnesses.opencode.skills.enable (default true).
    '')
    (removedFlatOption [ "opencode" "agents" "enable" ] ''
      Use ${optionRoot}.harnesses.opencode.enable = true; together with
      ${optionRoot}.harnesses.opencode.agents.enable (default true).
    '')
    (removedFlatOption [ "codex" "skills" "enable" ] ''
      Use ${optionRoot}.harnesses.codex.enable = true; together with
      ${optionRoot}.harnesses.codex.skills.enable (default true).
    '')
    (removedFlatOption [ "codex" "agents" "enable" ] ''
      Use ${optionRoot}.harnesses.codex.enable = true; together with
      ${optionRoot}.harnesses.codex.agents.enable (default true).
    '')
  ];

  options.CUSTOM.programs.aura-config-sync = {
    enable = mkEnableOption "Aura config sync: aura-swarm plus Pasture-generated harness trees";

    pasture.source = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = pastureSourceDefault;
      defaultText = lib.literalExpression "pasture flake input";
      description = ''
        Pinned source checkout holding Pasture's generated harness trees. The
        aura-plugins flake passes its dayvidpham/pasture input by default;
        override this for local Pasture development checkouts. Activation reads
        this tree only — it never fetches anything.
      '';
      example = lib.literalExpression "../pasture";
    };

    packages.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install aura-swarm.";
    };

    harnesses = builtins.listToAttrs (map
      (harness: { name = harness; value = harnessOption harness; })
      harnessNames);

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
      assertions = [ sourceAssertion ]
        ++ targetAssertions
        ++ missingSourceAssertions
        ++ collisionAssertions
        ++ overlapAssertions;
    }

    (mkIf cfg.packages.enable {
      home.packages = [
        self.packages.${pkgs.system}.aura-swarm
      ];
    })

    {
      home.file = lib.mapAttrs (_: source: { inherit source; }) projectedFiles;
    }

    (mkIf cfg.protocol.enable (
      let
        prefix =
          if cfg.protocol.target == "global"
          then ".claude"
          else ".config/aura/protocol";
        protocolFiles = builtins.filter (rel: lib.hasSuffix ".md" rel) (hmlib.relativeFiles protocolDir);
      in
      {
        home.file = builtins.listToAttrs (map
          (rel: { name = "${prefix}/${rel}"; value.source = "${protocolDir}/${rel}"; })
          protocolFiles);
      }
    ))
  ]);
}
