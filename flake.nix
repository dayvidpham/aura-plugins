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
          # This revision and the `pasture` flake input revision MUST be the
          # same commit: one release binds exactly one Pasture revision, and
          # the release pipeline stamps that single revision into the
          # aggregate manifest as `revisions.pasture`. A producer built from a
          # different Pasture commit than the one that exported the component
          # assets would freeze a false provenance claim into an immutable,
          # non-overwritable release.
          #
          # The coupling is enforced statically below (`pastureContractPin`),
          # not by convention: bumping the flake input without bumping this
          # pin fails evaluation. To move both, run
          #   nix flake update pasture
          # then set this url + hash to the same revision (a wrong hash makes
          # the build print the correct one).
          pastureAggregateContractRev = "e96d0e2ce449d9dfdfa256d38d89a3f1757f36fe";

          pastureAggregateContract = pkgs.fetchzip {
            url = "https://github.com/dayvidpham/pasture/archive/${pastureAggregateContractRev}.tar.gz";
            hash = "sha256-KvWtobneARTbLpjfMBR3/BJDAKMWj5rPqWnflD1I7Kc=";
          };

          # Static guard: refuse to evaluate a split pin. `pasture.rev` is the
          # locked flake-input revision; a source override (e.g. a local dirty
          # checkout) has no `rev`, in which case the coupling cannot be
          # proven and we warn rather than block local development.
          pastureContractPin = value:
            if pasture ? rev then
              nixpkgs.lib.throwIf (pasture.rev != pastureAggregateContractRev) ''
                aura-plugins flake.nix: split Pasture pin.
                  The aggregate producer compiles against pasture ${pastureAggregateContractRev}
                  but the flake input is locked to pasture ${pasture.rev}.
                  A release built from this tree would stamp one revision into
                  the aggregate manifest while shipping bytes from another.
                  Fix: set pastureAggregateContractRev (and its fetchzip hash)
                  in flake.nix to ${pasture.rev}, or re-lock the input to
                  ${pastureAggregateContractRev}.
              '' value
            else
              nixpkgs.lib.warn ''
                aura-plugins flake.nix: the pasture flake input has no locked
                revision (source override), so the aggregate producer's pin
                ${pastureAggregateContractRev} cannot be checked against it.
                Do not cut a release from this evaluation.
              '' value;

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
          aggregate-release = pastureContractPin (pkgs.buildGoModule {
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
          });

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
              # jq and sha256sum are what the verifier reads manifests and
              # hashes assets with, so its suite needs them here too.
              nativeBuildInputs = [ pkgs.bash pkgs.jq pkgs.coreutils ];
            } ''
            cp -r "$src" release
            chmod -R u+w release
            patchShebangs release
            bash release/release-grammar_test.sh
            bash release/verify-aggregate-dir_test.sh
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
