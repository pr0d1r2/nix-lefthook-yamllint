#!/usr/bin/env bats

@test "ci.yml pins every remote uses reference to a full 40-character commit SHA" {
  uses=$(grep -E '^[[:space:]]*(-[[:space:]]*)?uses:' .github/workflows/ci.yml)
  [ -n "$uses" ]
  # Strip YAML quotes, skip local ./ actions, and require the SHA in the
  # uses value itself -- a SHA in a trailing comment does not pin anything.
  unpinned=$(printf '%s\n' "$uses" | tr -d "\"'" |
    grep -vE 'uses:[[:space:]]*\./' |
    grep -vE 'uses:[[:space:]]*[^[:space:]#@]+@[0-9a-f]{40}([[:space:]]|$)' || true)
  echo "unpinned: $unpinned"
  [ -z "$unpinned" ]
}
