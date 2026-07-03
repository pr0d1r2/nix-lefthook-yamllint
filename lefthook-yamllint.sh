# shellcheck shell=bash
# Lefthook-compatible yamllint wrapper.
# Usage: lefthook-yamllint file1.yml [file2.yml ...]
# Non-.yml/.yaml files are skipped silently.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
  exit 0
fi

files=()
for f in "$@"; do
  [ -f "$f" ] || continue
  case "$f" in
  *.yml | *.yaml) files+=("$f") ;;
  esac
done

if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

# Optional config path. Unset -> yamllint auto-discovers (.yamllint /
# .yamllint.yml / .yamllint.yaml from cwd), preserving prior behavior. Set ->
# use the given file, which may live outside the repo root (e.g. a nix
# out-link), so the config need not be a committed root file.
config_args=()
if [ -n "${LEFTHOOK_YAMLLINT_CONFIG:-}" ]; then
  config_args=(-c "$LEFTHOOK_YAMLLINT_CONFIG")
fi

exec yamllint "${config_args[@]}" "${files[@]}"
