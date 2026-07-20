# SPEC — nix-lefthook-yamllint

## §G Goal

Lefthook-compatible yamllint wrapper for git hooks. Filters `.yml`/`.yaml` files from its arguments and runs `yamllint` on them, exiting 0 when no YAML files match. Packaged as a Nix flake `writeShellApplication`. Opensource-safe: zero credentials, zero local paths, zero private refs.

## §C Constraints

- C1: Pure bash — no Python/Ruby/etc runtime deps beyond `yamllint` itself
- C2: Nix flake — `writeShellApplication` pkg, plain `mkShell` devShells with inline lefthook-wrapper composition
- C3: MIT license
- C4: Multi-platform: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`
- C5: Detached from parent project — no credential leaks, no hardcoded local paths, no private repo refs
- C6: All config via env vars — no config files beyond baseline lint config
- C7: Delegates pass/fail to `yamllint` — non-zero exit when yamllint flags a file, blocking the commit
- C8: Flattened inputs — `flake = false` `-src` leaf inputs plus `nixpkgs-lock`, no `nix-dev-shell-agentic`, no transitive flake explosion

## §I Interfaces

- I.cli: `lefthook-yamllint file1.yml [file2.yml ...]` — main binary; `exec`s `yamllint` on the matching files, propagating its exit code (non-zero blocks commit); exit 0 when no args or no YAML files match
- I.env.config: `LEFTHOOK_YAMLLINT_CONFIG` — path to a yamllint config; unset → yamllint auto-discovers `.yamllint`/`.yamllint.yml`/`.yamllint.yaml` from cwd; may live outside the repo root (nix out-link)
- I.env.timeout: `LEFTHOOK_YAMLLINT_TIMEOUT` — seconds, default 30; consumed by the `timeout` wrapper in `lefthook.yml`/`lefthook-remote.yml`
- I.remote: `lefthook-remote.yml` — consumers add as a lefthook remote; runs on `pre-commit` over `{staged_files}` and `pre-push` over `{push_files}`, both `glob: "*.{yml,yaml}"`
- I.flake: `packages.${system}.default` — `lefthook-yamllint` Nix pkg output, `runtimeInputs = [ pkgs.yamllint ]`
- I.devshell: `devShells.${system}.default` + `.#ci` — dev/CI shells; both share `ciCommon` (pkg, bats-with-libs, bats, coreutils, git, lefthook, nix, parallel, yamllint, plus the inline lefthook wrappers); `.#ci` exports `BATS_LIB_PATH`, `.#default` runs the expanded `dev.sh` shellHook
- I.ci: `.github/workflows/ci.yml` — linux + macos via `nix-lefthook-ci-action`

## §V Invariants

- V1: Zero args → immediate exit 0
- V2: Only `*.yml` and `*.yaml` arguments that exist as regular files are passed to `yamllint`; non-existent paths and non-YAML extensions are filtered out silently
- V3: After filtering, an empty file set → exit 0 (no yamllint invocation)
- V4: `LEFTHOOK_YAMLLINT_CONFIG` set → `yamllint -c "$LEFTHOOK_YAMLLINT_CONFIG"`; unset → yamllint auto-discovery preserves prior behavior
- V5: Invalid YAML or yamllint rule violations propagate yamllint's non-zero exit, blocking the commit
- V6: `LEFTHOOK_YAMLLINT_CONFIG` may point outside the repo root (nix out-link) — the config need not be a committed root file
- V7: `LEFTHOOK_YAMLLINT_TIMEOUT` (default 30s) bounds each hook invocation via `timeout`
- V8: No credentials, secrets, tokens, API keys, or private paths in any tracked file
- V9: No hardcoded local filesystem paths (enforced by `nix-lefthook-git-no-local-paths` hook)
- V10: `dev.sh` sets `BATS_LIB_PATH` and auto-installs lefthook when `.git/hooks/pre-commit` is missing
- V11: `packages.${system}.default` and `devShells` (`ci` + `default`) outputs are stable across all four supported systems
- V12: Flattened flake — inputs are `nixpkgs-lock`, `nixpkgs` (follows), and `flake = false` `-src` leaves only; no flake input pulls a transitive dep tree
- V13: CI runs lefthook pre-commit + pre-push on linux + macos via `nix-lefthook-ci-action`
- V14: All linters pass: shellcheck, shfmt, nixfmt, statix, deadnix, nix-no-embedded-shell, yamllint, typos, editorconfig-checker, bats-parse, bats-unit, trailing-whitespace, missing-final-newline, git-conflict-markers, git-no-local-paths, file-size-check, nix-flake-check
- V15: `config/lefthook/file_size_limits.yml` raises the `nix` extension limit to 10240 — the flattened `flake.nix` with inline wrappers exceeds the 4096 default

## §T Tasks

| id | status | task | cites |
| --- | --- | --- | --- |
| T1 | x | core wrapper: filter `.yml`/`.yaml` regular-file args, `exec yamllint`, exit 0 on empty | V1,V2,V3,I.cli |
| T2 | x | optional `LEFTHOOK_YAMLLINT_CONFIG` — `-c` when set, auto-discovery when unset | V4,V6,I.env |
| T3 | x | propagate yamllint non-zero exit to block commits | V5,C7 |
| T4 | x | Nix flake pkg (`writeShellApplication`, `runtimeInputs=[yamllint]`) | C2,I.flake |
| T5 | x | flattened devShells (`.#default` + `.#ci`) with inline lefthook-wrapper composition | C2,C8,I.devshell,V12 |
| T6 | x | lefthook-remote.yml + lefthook.yml: pre-commit/pre-push over yaml globs with timeout | I.remote,V7 |
| T7 | x | dev.sh — BATS_LIB_PATH + auto-install lefthook | V10 |
| T8 | x | unit tests: lefthook-yamllint.bats (10 tests, config + filtering + failure cases) | V1-V6 |
| T9 | x | unit tests: dev.bats (3 tests) | V10 |
| T10 | x | GitHub Actions CI: linux + macos via nix-lefthook-ci-action | V13,I.ci |
| T11 | x | linter suite via lefthook remotes | V14 |
| T12 | x | flatten flake: drop nix-dev-shell-agentic, use `flake = false` `-src` leaves | C8,V12 |
| T13 | x | file_size_limits.yml: raise `nix` limit to 10240 for flattened flake | V15 |
| T14 | x | opensource audit: no credentials/local-paths/private-refs in git history | V8,V9,C5 |

## §B Bugs

| id | date | cause | fix |
| --- | --- | --- | --- |
| B1 | 2026-07-03 | `case` pattern in `lefthook-yamllint.sh` indented 4 spaces instead of 2; `shfmt` rejects it | Reduce `case` pattern indentation to 2 spaces to satisfy `shfmt` |
| B2 | 2026-07-14 | `lefthook.yml` invokes `lefthook-markdownlint` and `lefthook-markdownlint-agentic`, but the flake devShell provided no wrappers for them → `timeout: No such file or directory`, exit 127, CI `build-linux` fails | Add `nix-lefthook-markdownlint-src` + `nix-lefthook-markdownlint-agentic-src` flake inputs and inline `writeShellApplication` wrappers (markdownlint-cli + `is-markdown-agentic` helper, agentic config substituted) to `lefthookWrappersFor` |
| B3 | 2026-07-19 | `packages` attrset in `flake.nix` contained two `default` attributes — the real package and a stale `mkShell` devShell definition left from migration; `nix flake check` errors with "attribute 'default' already defined" | Remove the stale `default = pkgs.mkShell { … }` block from `packages`; extract embedded shell from `apps.confirm` into `confirm.sh` with placeholder substitution to fix `nix-no-embedded-shell` check |
| B4 | 2026-07-19 | `apps.confirm` `writeShellApplication` lacked materialized packages in `runtimeInputs` — `nix run .#confirm` coherence check fails because `lefthook-markdownlint`, `lefthook-markdownlint-agentic`, `lefthook-yamllint` are not on PATH outside the devShell | Add `materializationFor` to `apps` block and append `mat.packages` to confirm's `runtimeInputs` |
