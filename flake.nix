{
  description = "Lefthook-compatible yamllint wrapper for git hooks";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.url = "github:pr0d1r2/set-and-setting";
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-yamllint";
          runtimeInputs = [ pkgs.yamllint ];
          text = builtins.readFile ./lefthook-yamllint.sh;
        };
        setting = (set-and-setting.lib.mkSetting { inherit pkgs; }).materialized;
      });

      devShells = forAllSystems (
        pkgs:
        let
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
          sys = pkgs.stdenv.hostPlatform.system;
          bats = pkgs.bats.withLibraries (p: [
            p.bats-assert
            p.bats-support
          ]);
          shells = set-and-setting.lib.mkDevShells {
            inherit pkgs;
            basePackages = [
              self.packages.${sys}.default
              bats
            ]
            ++ mat.packages;
            defaultShellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${bats}" ] (
              builtins.readFile ./dev.sh
            );
            settingHook = ''
              ${self.packages.${sys}.setting}/bin/sync-setting .
              _assemble_out="$(mktemp -d)"
              FRAGMENTS="${builtins.concatStringsSep " " fragments}" \
                out="$_assemble_out" \
                FRAGMENTS_DIR="${set-and-setting}/setting/integrations/lefthook" \
                bash "${set-and-setting}/setting/lib/assemble-lefthook.sh"
              cp -f "$_assemble_out/lefthook.yml" lefthook.yml
              rm -rf "$_assemble_out"
            '';
          };
        in
        shells // { ci = shells.default; }
      );

      checks = forAllSystems (
        pkgs:
        (set-and-setting.lib.checksFor {
          inherit pkgs fragments;
          src = ./.;
        })
        // {
          unit =
            let
              bats = pkgs.bats.withLibraries (p: [
                p.bats-assert
                p.bats-support
              ]);
            in
            pkgs.runCommand "unit-tests"
              {
                nativeBuildInputs = [
                  self.packages.${pkgs.stdenv.hostPlatform.system}.default
                  bats
                  pkgs.git
                ];
                BATS_LIB_PATH = "${bats}/share/bats";
              }
              ''
                cp -r ${./.} source
                chmod -R u+w source
                cd source
                bats tests/unit
                touch "$out"
              '';
          dep-graph = set-and-setting.lib.mkDepGraphCheck {
            inherit pkgs;
            projectRoot = ./.;
          };
          default = pkgs.runCommand "checks" { } "touch $out";
        }
      );

      apps = forAllSystems (
        pkgs:
        let
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
        in
        {
          confirm = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "confirm";
                runtimeInputs = [
                  pkgs.coreutils
                  pkgs.diffutils
                  pkgs.findutils
                  pkgs.gawk
                  pkgs.git
                  pkgs.gnugrep
                ]
                ++ mat.packages;
                text =
                  builtins.replaceStrings
                    [
                      "@FRAGMENTS_DIR@"
                      "@ASSEMBLE_SCRIPT@"
                      "@DETECT_SCRIPT@"
                      "@SETTING_SRC@"
                      "@CONFIRM_SCRIPT@"
                      "@CONFIRM_REV@"
                    ]
                    [
                      "${set-and-setting}/setting/integrations/lefthook"
                      "${set-and-setting}/setting/lib/assemble-lefthook.sh"
                      "${set-and-setting}/setting/lib/detect-fragments.sh"
                      "${self.packages.${pkgs.stdenv.hostPlatform.system}.setting}"
                      "${set-and-setting}/lib/confirm.sh"
                      "${set-and-setting.rev or "unknown"}"
                    ]
                    (builtins.readFile ./confirm.sh);
              }
            }/bin/confirm";
          };
        }
      );
    };
}
