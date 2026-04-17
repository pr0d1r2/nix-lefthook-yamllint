# nix-lefthook-yamllint

[![CI](https://github.com/pr0d1r2/nix-lefthook-yamllint/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-yamllint/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [yamllint](https://github.com/adrienverge/yamllint) wrapper, packaged as a Nix flake.

Filters `.yml` and `.yaml` files from staged arguments and runs yamllint on them. Exits 0 when no matching files are found.

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just `pkgs.yamllint` in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-yamllint
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-yamllint = {
  url = "github:pr0d1r2/nix-lefthook-yamllint";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-yamllint.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    yamllint:
      glob: "*.{yml,yaml}"
      run: timeout ${LEFTHOOK_YAMLLINT_TIMEOUT:-30} lefthook-yamllint {staged_files}
```

### Configuring timeout

The default timeout is 30 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_YAMLLINT_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-yamllint  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT
