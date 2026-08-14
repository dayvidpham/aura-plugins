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
          pastureAggregateContract = pkgs.fetchzip {
            url = "https://github.com/dayvidpham/pasture/archive/f5cbf4f92bb458eb0baff64f6adec603bcf0d74f.tar.gz";
            hash = "sha256-8RRNB6Is8xhVGGj1dOQ1gfcoee6nyApQYIr1Ke6ihn0=";
          };

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
          hm-module-test = import ./nix/hm-module-test.nix { inherit pkgs; };
          aggregate-release-test = self.packages.${pkgs.system}.aggregate-release;
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
