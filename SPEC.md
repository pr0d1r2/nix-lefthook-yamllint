# SPEC

## §D — Description

nix-lefthook-yamllint is a Nix flake that packages a lefthook-compatible yamllint wrapper shell script. It filters `.yml` and `.yaml` files from staged/pushed file arguments, skipping non-existent or non-YAML files, and runs yamllint on the remainder — exiting 0 when no matching files are found. It targets developers using Nix-based devShells with lefthook git hooks who want automated YAML linting on pre-commit and pre-push, consumable either as a lefthook remote or as a flake input.

## §V — Invariants

1. Zero arguments must exit 0 (no files to lint is not an error)
2. Non-existent file arguments must be skipped silently (exit 0 if no valid files remain)
3. Non-YAML file arguments (not `.yml`/`.yaml`) must be skipped silently
4. Valid YAML files must exit 0
5. Invalid YAML files must cause non-zero exit
6. Both `.yml` and `.yaml` extensions must be accepted
7. Multiple files with at least one invalid must cause failure
8. `dev.sh` must export `BATS_LIB_PATH` from the placeholder substitution
9. `dev.sh` must run `lefthook install` only when `.git/hooks/pre-commit` is absent
10. `dev.sh` must skip `lefthook install` when hooks already exist
11. Flake must build on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`
12. CI must pass on both Linux and macOS
13. All shell scripts must pass shellcheck
14. All nix files must pass statix, deadnix, and nixfmt
15. All YAML files must pass yamllint
16. Every lefthook command must have a timeout
17. Every shell script must have 1-to-1 bats unit test coverage

## §I — Interfaces

### CLI

```
lefthook-yamllint [file ...]
```

Filters input file paths to those with `.yml`/`.yaml` extensions that exist on disk, then runs `yamllint` on them. Exits 0 when no matching files remain.

### Nix Flake Package

```nix
packages.${system}.default  # writeShellApplication wrapping lefthook-yamllint.sh
```

Runtime dependency: `yamllint`.

### Nix Flake DevShell

```nix
devShells.${system}.default  # includes lefthook-yamllint + dev tooling
devShells.${system}.ci       # CI-oriented shell
```

Provided via `nix-dev-shell-agentic.lib.mkShells`.

### Lefthook Remote Config (`lefthook-remote.yml`)

```yaml
pre-commit:
  commands:
    yamllint:
      glob: "*.{yml,yaml}"
      run: timeout ${LEFTHOOK_YAMLLINT_TIMEOUT:-30} lefthook-yamllint {staged_files}

pre-push:
  commands:
    yamllint:
      glob: "*.{yml,yaml}"
      run: timeout ${LEFTHOOK_YAMLLINT_TIMEOUT:-30} lefthook-yamllint {push_files}
```

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `LEFTHOOK_YAMLLINT_TIMEOUT` | `30` | Timeout in seconds for yamllint execution |
| `BATS_LIB_PATH` | Set by `dev.sh` | Path to bats helper libraries |

### Configuration Files

| File | Format | Purpose |
|------|--------|---------|
| `.yamllint.yml` | YAML | yamllint rules (extends default, disables truthy key check and line-length) |
| `.editorconfig` | INI | Editor formatting (UTF-8, LF, 2-space indent) |
| `.markdownlint.yml` | YAML | Markdown lint rules (disables line-length) |
| `config/lefthook/file_size_limits.yml` | YAML | Max file sizes per extension (default 4096 bytes) |

## §T — Tasks

| status | id | goal |
|--------|-----|------|
| `.` | T1 | Add `watch_file` entries to `.envrc` for `flake.nix`, `dev.sh`, and nix modules per direnv skill |
| `.` | T2 | Add markdownlint lefthook check for `.md` files (linter skill requires every tracked file type has a linter) |
| `.` | T3 | Add test for `lefthook-remote.yml` content/structure validation |
| `.` | T4 | Add integration test verifying timeout behavior via `LEFTHOOK_YAMLLINT_TIMEOUT` |
| `.` | T5 | Add `flake.lock` to `.envrc` watch list for automatic reload on lock updates |
| `.` | T6 | Add symlink/special-file edge case tests to `lefthook-yamllint.bats` |
| `.` | T7 | Pin `nix-lefthook-ci-action` to a tagged release instead of a commit SHA |
| `.` | T8 | Add `nix flake check` as a bats test or verify it runs in CI |
| `.` | T9 | Document the `nix-dev-shell-agentic` dependency and what `mkShells` provides |

## §B — Bugs / Known Issues

1. **No linter configured for Markdown files** — `.md` files are tracked in git (README.md, CLAUDE.md, agent skills) but have no lefthook check, violating the linter skill which requires every tracked file type to have an assigned linter.

2. **No timeout test coverage** — The timeout behavior (`LEFTHOOK_YAMLLINT_TIMEOUT`) is specified in the remote config and documented in the README, but there are no tests verifying it works correctly or that the default of 30s applies.
