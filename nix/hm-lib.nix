# Pure helper functions for the aura-config-sync Home Manager module.
#
# Everything here is a pure Nix function over the pinned Pasture source tree:
# directory listing, destination-path normalization, and the frozen per-harness
# layout table. No fetching, no activation scripts, no impure builtins — the
# module must evaluate offline from a flake input alone.
{ lib }:

let
  inherit (lib)
    concatStringsSep
    hasPrefix
    hasSuffix
    splitString
    mapAttrsToList
    concatLists
    ;

  inherit (builtins) length elemAt filter elem;

  # ── Path handling ────────────────────────────────────────────────────────
  # A destination is modelled as a list of path components relative to
  # home.homeDirectory. Splitting drops empty and "." segments so that
  # "skills", "./skills/", and "skills//" normalize identically.
  splitComponents = value: filter (c: c != "" && c != ".") (splitString "/" value);

  joinComponents = components: concatStringsSep "/" components;

  take = count: list: lib.sublist 0 count list;
  drop = count: list: lib.sublist count (length list) list;

  # true when `prefix` is a component-wise prefix of `components`.
  isComponentPrefix = prefix: components:
    length prefix <= length components && take (length prefix) components == prefix;

  # Normalize a user-supplied destination into home-relative components.
  #
  # `allowHomeRoot` distinguishes a harness root (which may legitimately be the
  # home directory itself — Codex's native layout spans ~/.agents and ~/.codex)
  # from a cell destination (which may not: a cell owns a directory subtree, and
  # owning the whole home would put every unrelated file under its ownership).
  #
  # Returns { ok = true; components = [...]; } or
  #         { ok = false; reason = <string>; } where reason is one of
  #         "tilde", "traversal", "home-unknown", "outside-home", "home-root".
  normalizeTarget =
    { homeDirectory, value, allowHomeRoot ? false }:
    let
      raw = toString value;
      absolute = hasPrefix "/" raw;
      components = splitComponents raw;
      homeComponents = splitComponents (toString (if homeDirectory == null then "" else homeDirectory));
      homeKnown = homeDirectory != null && homeComponents != [ ];
      relative = { ok = true; components = components; };
      accept = result:
        if result.ok && result.components == [ ] && !allowHomeRoot
        then { ok = false; reason = "home-root"; }
        else result;
    in
    # Nix performs no tilde expansion, so "~/x" would be realized as a literal
    # directory named "~" inside the home. Reject it rather than create it.
    if raw == "~" || hasPrefix "~/" raw then
      { ok = false; reason = "tilde"; }
    else if elem ".." components then
      { ok = false; reason = "traversal"; }
    else if !absolute then
      accept relative
    else if !homeKnown then
      { ok = false; reason = "home-unknown"; }
    else if !(isComponentPrefix homeComponents components) then
      { ok = false; reason = "outside-home"; }
    else
      accept { ok = true; components = drop (length homeComponents) components; };

  # Parent of a destination; the home root is its own parent.
  parentComponents = components:
    if components == [ ] then [ ] else take (length components - 1) components;

  # ── Source-tree listing ──────────────────────────────────────────────────
  # Recursive listing of every file below `dir`, as slash-joined paths relative
  # to `dir`. Missing directories list as empty rather than throwing; callers
  # turn "empty" into an actionable missing-source assertion.
  relativeFiles = dir:
    let
      walk = sub:
        let
          here = if sub == "" then "${dir}" else "${dir}/${sub}";
          entries = builtins.readDir here;
        in
        concatLists (mapAttrsToList
          (name: type:
            let rel = if sub == "" then name else "${sub}/${name}"; in
            if type == "directory" then walk rel
            else if type == "regular" || type == "symlink" then [ rel ]
            else [ ])
          entries);
    in
    if builtins.pathExists "${dir}" then walk "" else [ ];

  # ── Frozen harness layout ────────────────────────────────────────────────
  # Per harness: the default destination root below the managed home, and per
  # cell the Pasture source subdirectory plus the destination subdirectory
  # appended to that root.
  #
  # Sources are the harness-specific generated trees committed in Pasture. A
  # harness is never fed another harness's tree: the frontmatter schemas differ
  # and cross-wiring ships files the host cannot load.
  #
  # KNOWN DUPLICATION — this table restates layout facts that Pasture also
  # holds as Go constants (its per-harness host controllers and the frozen
  # component layouts under testdata/install/global/). Nothing machine-checks
  # the two against each other today: Pasture exposes no machine-readable
  # export of these facts as of the pinned revision, so the table is
  # hand-transcribed and the byte-identity checks in nix/hm-module-test.nix are
  # what catch a source tree that moved or disappeared.
  # The intended future drift seam is a component-export manifest from Pasture's
  # installer (a `pasture install export-components`-style verb, not yet
  # implemented upstream): when it lands, generate this table from that manifest
  # instead of restating it, and assert equality in the flake check.
  harnesses = {
    "claude-code" = {
      defaultRoot = ".claude";
      cells = {
        # skills/<name>/SKILL.md and the multi-file protocol skill.
        skills = { sourceDir = "skills"; subdir = "skills"; };
        agents = { sourceDir = "agents"; subdir = "agents"; };
        # The Pasture repository keeps its Go sources for the hook package in
        # the same directory as the hook payload; only the payload is a hook
        # file, so Go sources are filtered out rather than copied to the home.
        hooks = {
          sourceDir = "hooks";
          subdir = "hooks";
          excludeSuffixes = [ ".go" ];
        };
      };
    };

    opencode = {
      defaultRoot = ".config/opencode";
      cells = {
        skills = { sourceDir = ".opencode/skill"; subdir = "skills"; };
        agents = { sourceDir = ".opencode/agent"; subdir = "agent"; };
        # OpenCode discovers plugins by directory; the generated module is
        # named for its source role, and the destination name matches the file
        # name Pasture's own installer writes so both controllers agree on one
        # canonical destination.
        hooks = {
          sourceDir = ".opencode/plugins";
          subdir = "plugins";
          renames = { "pasture-lifecycle.ts" = "pasture-hooks.ts"; };
        };
      };
    };

    codex = {
      # Codex splits its native layout across two home directories
      # (~/.agents for skills, ~/.codex for agents and hooks), so the harness
      # root is the managed home itself and each cell carries its own subtree.
      defaultRoot = "";
      cells = {
        skills = { sourceDir = ".agents/skills"; subdir = ".agents/skills"; };
        agents = { sourceDir = ".codex/agents"; subdir = ".codex/agents"; };
        # The event scripts live below the hooks directory; the public hook
        # configuration and the activation report are siblings of it, exactly
        # as in the harness layout Pasture's installer targets. They are public
        # configuration, never private trust state.
        #
        # This cell is layout-locked: the generated .codex/hooks.json invokes
        # its event scripts as `sh .codex/hooks/events/<Event>.sh`, a path fixed
        # when Pasture generated the payload. Relocating the cell would move the
        # scripts out from under that hard-coded path and leave the public
        # configuration pointing at nothing, so a destination override is
        # refused instead of silently producing an inert cell.
        hooks = {
          sourceDir = ".codex/hooks";
          subdir = ".codex/hooks";
          layoutLocked = true;
          lockedBecause = "the generated .codex/hooks.json invokes each event script as `sh .codex/hooks/events/<Event>.sh`, a path fixed when Pasture generated the payload";
          siblings = [
            { source = ".codex/hooks.json"; name = "hooks.json"; }
            { source = ".codex/pasture-codex-activation.json"; name = "pasture-codex-activation.json"; }
          ];
        };
      };
    };
  };

  harnessNames = lib.attrNames harnesses;
  axisNames = [ "skills" "agents" "hooks" ];

  # ── Projection ───────────────────────────────────────────────────────────
  # Build { files = { "<home-relative dest>" = "<source file>"; }; sourceDir; }
  # for one cell. `sourceDir` is returned rather than recomputed by callers so
  # the path quoted in a missing-source error is exactly the path that was read.
  projectCell =
    { source, cell, targetComponents }:
    let
      sourceDir = "${source}/${cell.sourceDir}";
      # Exclusions are declared as data (suffixes) so the byte-identity checks in
      # nix/hm-module-test.nix can reuse the same list as diff -x patterns.
      excluded = rel: builtins.any (suffix: hasSuffix suffix rel) (cell.excludeSuffixes or [ ]);
      renames = cell.renames or { };
      siblings = cell.siblings or [ ];

      wanted = filter (rel: !(excluded rel)) (relativeFiles sourceDir);

      # Renames are keyed on the full source-relative path, so a rename can
      # never fire on an unrelated file that happens to share a basename.
      destOf = rel: joinComponents (targetComponents ++ splitComponents (renames.${rel} or rel));

      subtree = builtins.listToAttrs (map
        (rel: { name = destOf rel; value = "${sourceDir}/${rel}"; })
        wanted);

      # Sibling members are public configuration that the generated payload
      # itself references by a fixed path, so they are anchored to the parent of
      # the cell destination rather than placed inside it.
      siblingRoot = parentComponents targetComponents;
      siblingFiles = builtins.listToAttrs (map
        (entry: {
          name = joinComponents (siblingRoot ++ [ entry.name ]);
          value = "${source}/${entry.source}";
        })
        (filter (entry: builtins.pathExists "${source}/${entry.source}") siblings));
    in
    {
      inherit sourceDir;
      files = subtree // siblingFiles;
    };

  # Destination a cell occupies when neither its harness root nor its own
  # target is overridden. Single source of truth for the module's defaults and
  # for the byte-identity checks in nix/hm-module-test.nix.
  defaultTargetComponents = harness: axis:
    splitComponents harnesses.${harness}.defaultRoot
    ++ splitComponents harnesses.${harness}.cells.${axis}.subdir;

in
{
  inherit
    splitComponents
    joinComponents
    isComponentPrefix
    parentComponents
    normalizeTarget
    relativeFiles
    harnesses
    harnessNames
    axisNames
    projectCell
    defaultTargetComponents
    ;
}
