{
  description = "aura-swarm tooling and config sync for Pasture-generated agent workflows";

  # ============================================================
  # INPUTS
  # ============================================================

  inputs = rec {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    pasture.url = "github:dayvidpham/pasture";
  };

  # ============================================================
  # OUTPUTS
  # ============================================================

  outputs =
    inputs@{ self
    , nixpkgs
    , pasture
    , ...
    }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          inherit system;
          pkgs = import nixpkgs { inherit system; };
        }
      );

    in
    {
      # ── Packages ──────────────────────────────────────────────
      packages = forAllSystems ({ pkgs, system }:
        let
          # The Pasture source the aggregate producer compiles against.
          #
          # It is the `pasture` flake input itself — the same store path the
          # rest of this flake consumes — rather than a second, separately
          # hashed copy of the same commit. One release binds exactly one
          # Pasture revision, and the release pipeline stamps that revision
          # into the aggregate manifest as `revisions.pasture`; a producer
          # built from a different Pasture commit than the one that exported
          # the component assets would freeze a false provenance claim into an
          # immutable, non-overwritable release.
          #
          # Earlier this coupling was a second `fetchzip` pin plus an
          # eval-time guard asserting the two revisions agreed. That guard
          # only ever caught a drift that this flake itself created, and it
          # drifted three times (f5cbf4f / be01293 / e96d0e2) before it was
          # made to fail closed. Consuming the input outright removes the
          # class: there is no second revision to disagree with, so
          # `nix flake update pasture` is the whole procedure for moving it.
          pastureAggregateContract = pasture;

          # Deprecation stub: a package that was removed still resolves as an
          # output, but fails at run time with an actionable pointer to its
          # replacement — instead of a cryptic "attribute 'X' missing" for
          # anyone (or any downstream flake) still referencing the old name.
          removed = name: what: replacement: pkgs.writeShellScriptBin name ''
            {
              echo "error: '${name}' was removed from aura-plugins."
              echo "  ${what} was deleted when the Python protocol tooling was retired (aura-plugins PR #6)."
              echo "  pasture (github:dayvidpham/pasture, Go) is now the source of truth."
              echo "  Use instead: ${replacement}"
            } >&2
            exit 1
          '';
        in
        {
          aggregate-release = pkgs.buildGoModule {
            pname = "aura-aggregate-release";
            version = "0.1.0";
            src = ./aggregate-release;
            vendorHash = null;
            postPatch = ''
              go mod edit -replace github.com/dayvidpham/pasture=${pastureAggregateContract}
            '';
            preBuild = ''export GOFLAGS="$GOFLAGS -mod=mod"'';
            preCheck = ''export GOFLAGS="$GOFLAGS -mod=mod"'';
            postInstall = ''
              mv "$out/bin/aggregate-release" "$out/bin/aura-aggregate-release"
            '';
          };

          aura-swarm = pkgs.writeShellApplication {
            name = "aura-swarm";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              export AURA_PACKAGE_SKILLS_DIR="${pasture}/skills"
              PYTHONPATH="${self}/scripts" exec python3 "${self}/bin/aura-swarm" "$@"
            '';
          };

          # ── Deprecation stubs (removed in PR #6) ──────────────────
          # These fail with a pointer to the pasture replacement. The Python
          # protocol engine and its bins (aurad, aura-msg, aura-release) plus
          # the deprecated aura-parallel wrapper were retired in favour of the
          # Go pasture toolchain.
          aura-parallel = removed "aura-parallel"
            "aura-parallel (a deprecated intree-launch wrapper)"
            "aura-swarm intree mode: nix run .#aura-swarm -- start --swarm-mode intree --role <role> ...";
          aura-release = removed "aura-release"
            "aura-release (the Python version bumper and git tagger)"
            "pasture-release: nix run github:dayvidpham/pasture#pasture-release -- --help";
          aurad = removed "aurad"
            "aurad (the Python Temporal worker daemon)"
            "pastured: nix run github:dayvidpham/pasture#pastured";
          aura-msg = removed "aura-msg"
            "aura-msg (the Python protocol signal/query CLI)"
            "pasture-msg, now folded into the pasture CLI: nix run github:dayvidpham/pasture#pasture -- <epoch|signal|query|...>";

          default = pkgs.symlinkJoin {
            name = "aura-plugins";
            paths = [
              self.packages.${system}.aggregate-release
              self.packages.${system}.aura-swarm
            ];
          };
        });

      # ── Home Manager Modules ─────────────────────────────────
      homeManagerModules = {
        aura-config-sync = import ./nix/hm-module.nix { inherit self pasture; };
      };

      checks = forAllSystems ({ pkgs, ... }:
        {
          hm-module-test = import ./nix/hm-module-test.nix { inherit pkgs pasture; };
          aggregate-release-test = self.packages.${pkgs.system}.aggregate-release;
          # Runs the release-script test suites on every `nix flake check`, so a
          # regression in either surfaces on ordinary changes instead of first
          # appearing on a release PR — or, worse, mid-publication. Both scripts
          # decide irreversible things: the grammar decides what version a
          # permanent tag carries, and the verifier decides whether an aggregate
          # may be published and whether a published one is sound.
          #
          # The producer-acceptance probe deliberately stays in the release
          # gates instead: it needs the built producer binary, and it is about
          # agreement between two parsers rather than either script's own logic.
          release-scripts = pkgs.runCommand "release-scripts-test"
            {
              src = ./scripts/release;
              # The pinned-revision suite checks this repository's own lock
              # file, which is not reachable from the store copy of the
              # scripts, so it is passed in explicitly.
              AURA_FLAKE_LOCK = ./flake.lock;
              # jq and sha256sum are what the verifier reads manifests and
              # hashes assets with, so its suite needs them here too.
              # git is needed by the tag-assertion suite, which builds real
              # bare repositories and reaches them through git ls-remote —
              # entirely offline, so it runs in the sandbox.
              nativeBuildInputs = [ pkgs.bash pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.git ];
            } ''
            cp -r "$src" release
            chmod -R u+w release
            patchShebangs release
            export HOME="$TMPDIR"
            git config --global user.email test@localhost
            git config --global user.name test
            bash release/release-grammar_test.sh
            bash release/verify-aggregate-dir_test.sh
            bash release/pinned-pasture-revision_test.sh
            bash release/assert-pasture-release-tag_test.sh
            touch "$out"
          '';
        }
      );

      # ── Dev Shell (for working on aura-plugins itself) ───────
      devShells = forAllSystems ({ pkgs, ... }: {
        default = pkgs.mkShell {
          name = "aura-plugins-dev";
          packages = [
            pkgs.python3
            pkgs.tmux
          ];
        };
      });
    };
}
