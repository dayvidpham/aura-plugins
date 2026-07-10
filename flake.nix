{
  description = "aura-swarm tooling and config sync for Pasture-generated agent workflows";

  # ============================================================
  # INPUTS
  # ============================================================

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
      packages = forAllSystems ({ pkgs, system }: {
        aura-swarm = pkgs.writeShellApplication {
          name = "aura-swarm";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            export AURA_PACKAGE_SKILLS_DIR="${pasture}/skills"
            PYTHONPATH="${self}/scripts" exec python3 "${self}/bin/aura-swarm" "$@"
          '';
        };

        default = pkgs.symlinkJoin {
          name = "aura-plugins";
          paths = [
            self.packages.${system}.aura-swarm
          ];
        };
      });

      # ── Home Manager Modules ─────────────────────────────────
      homeManagerModules = {
        aura-config-sync = import ./nix/hm-module.nix { inherit self pasture; };
      };

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
