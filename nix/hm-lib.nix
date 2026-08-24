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
  # Returns { ok = true; components = [...]; } or
  #         { ok = false; reason = <string>; } where reason is one of
  #         "traversal", "home-unknown", "outside-home".
  normalizeTarget =
    { homeDirectory, value }:
    let
      raw = toString value;
      absolute = hasPrefix "/" raw;
      components = splitComponents raw;
      homeComponents = splitComponents (toString (if homeDirectory == null then "" else homeDirectory));
      homeKnown = homeDirectory != null && homeComponents != [ ];
    in
    if elem ".." components then
      { ok = false; reason = "traversal"; }
    else if !absolute then
      { ok = true; components = components; }
    else if !homeKnown then
      { ok = false; reason = "home-unknown"; }
    else if !(isComponentPrefix homeComponents components) then
      { ok = false; reason = "outside-home"; }
    else
      { ok = true; components = drop (length homeComponents) components; };

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
          exclude = rel: hasSuffix ".go" rel;
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
        hooks = {
          sourceDir = ".codex/hooks";
          subdir = ".codex/hooks";
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
  # Build { "<home-relative dest>" = "<absolute source>"; } for one cell.
  projectCell =
    { source, cell, targetComponents }:
    let
      sourceDir = "${source}/${cell.sourceDir}";
      exclude = cell.exclude or (_: false);
      renames = cell.renames or { };
      siblings = cell.siblings or [ ];

      wanted = filter (rel: !(exclude rel)) (relativeFiles sourceDir);

      destOf = rel:
        let
          parts = splitComponents rel;
          last = elemAt parts (length parts - 1);
          renamed = renames.${last} or last;
        in
        joinComponents (targetComponents ++ take (length parts - 1) parts ++ [ renamed ]);

      subtree = builtins.listToAttrs (map
        (rel: { name = destOf rel; value = "${sourceDir}/${rel}"; })
        wanted);

      siblingRoot = parentComponents targetComponents;
      siblingFiles = builtins.listToAttrs (map
        (entry: {
          name = joinComponents (siblingRoot ++ [ entry.name ]);
          value = "${source}/${entry.source}";
        })
        (filter (entry: builtins.pathExists "${source}/${entry.source}") siblings));
    in
    subtree // siblingFiles;
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
    ;
}
