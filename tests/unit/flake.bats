#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
}

@test "CI dev shell provides nix" {
    run nix eval --json .#devShells.x86_64-linux.ci.nativeBuildInputs
    assert_success
    assert_output --partial "-nix-"
}
