# Flatten SPEC — nix-lefthook-yamllint

## Goal
Remove the `nix-dev-shell-agentic` flake input (and its transitive
explosion) from `flake.nix`, preserving the `lefthook-yamllint` package
output and keeping CI (`nix develop .#ci` + remote lefthook hooks) and bats
green.

## Before
- flake.lock: 81 nodes.
- Inputs: nixpkgs-lock, nixpkgs(follows), nix-dev-shell-agentic(flake),
  nix-lefthook-bats-unit(flake), nix-lefthook-bats-parse(flake).
- Outputs: packages.<sys>.default = lefthook-yamllint; devShells ci/default
  via nix-dev-shell-agentic.lib.mkShells.

## Consumption of the agentic devShell here
- `.envrc` = `use flake` → devShells.<sys>.default.
- CI enters `nix develop .#ci` and runs lefthook install / pre-commit /
  pre-push --all-files.
- lefthook.yml `remotes:` invoke wrapper binaries that must be on PATH in the
  ci shell: lefthook-{nixfmt,shellcheck,shfmt,statix,deadnix,
  nix-no-embedded-shell,bats-unit,typos,trailing-whitespace,
  missing-final-newline,git-conflict-markers,editorconfig-checker,
  git-no-local-paths,file-size-check}; bare `bats` (bats-parse), bare
  `nix flake check` (nix-flake-check); plus lefthook, git, coreutils,
  parallel, yamllint.
- bats unit tests need BATS_LIB_PATH + lefthook-yamllint on PATH.

## Changes
### Inputs
Remove nix-dev-shell-agentic, nix-lefthook-bats-unit(flake),
nix-lefthook-bats-parse(flake). Add `flake = false` `-src` inputs for each
sibling wrapper the remotes invoke (14 leaves):
bats-unit, deadnix, editorconfig-checker, file-size-check,
git-conflict-markers, git-no-local-paths, missing-final-newline,
nix-no-embedded-shell, nixfmt, shellcheck, shfmt, statix,
trailing-whitespace, typos.
Result inputs: nixpkgs-lock, nixpkgs(follows), + 14 flake=false leaves. No
flake input → no dep-tree explosion. (bats-parse needs only bare `bats`;
nix-flake-check needs only bare `nix` — neither needs an -src leaf.)

### packages (UNCHANGED logic)
packages.<sys>.default = writeShellApplication { name="lefthook-yamllint";
runtimeInputs=[pkgs.yamllint]; text=readFile ./lefthook-yamllint.sh; }.

### devShells (plain mkShell, statix template shape)
- lefthookWrappersFor helper (wrap helper; bats-unit + file-size-check get
  special multi-input handling; nix-no-embedded-shell gets SCANNER prefix per
  tdd-order-bats template; rest via `wrap`).
- batsWithLibsFor helper.
- ciCommon = [self pkg, batsWithLibs, bats, coreutils, git, lefthook, nix,
  parallel, yamllint] ++ wrappers.
- ci = mkShell { packages = ciCommon; BATS_LIB_PATH = "${batsWithLibs}/share/bats"; }
- default = mkShell { packages = ciCommon; shellHook = dev.sh expanded; }

### Side changes required to land a flattened flake green
1. config/lefthook/file_size_limits.yml: nix 4096 → 10240 (flattened flake.nix exceeds 4096 bytes with 15 inline wrappers). Pure config.
2. lefthook-yamllint.sh: reformat to shfmt `-i 2` if needed. Whitespace-only.

## Validation gate (all must pass)
1. nix flake check — PASS.
2. nix flake show — packages.<sys>.default = lefthook-yamllint; devShells ci+default. UNCHANGED set.
3. nix build .#default + smoke.
4. bats tests/unit/ inside nix develop .#ci — PASS.
5. lefthook run pre-commit --all-files inside .#ci — PASS.
6. lock nodes << 81.

## Then
Branch flatten-drop-agentic, commit, push, DRAFT PR.
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
