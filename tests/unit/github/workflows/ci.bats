#!/usr/bin/env bats

@test "ci.yml pins every remote uses reference to a full 40-character commit SHA" {
  run grep -E '^\s*(-\s*)?uses:' .github/workflows/ci.yml
  [ "$status" -eq 0 ]
  run bash -c "grep -E '^\s*(-\s*)?uses:' .github/workflows/ci.yml | grep -vE 'uses:\s*\./' | grep -vE '@[0-9a-f]{40}(\s|\$)'"
  [ "$status" -eq 1 ]
}
