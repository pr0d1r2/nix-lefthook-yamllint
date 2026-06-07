#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TEST_DIR="$BATS_TEST_TMPDIR"
    git init "$TEST_DIR/repo" >/dev/null 2>&1
    mkdir -p "$TEST_DIR/repo/.git/hooks"
    touch "$TEST_DIR/repo/.git/hooks/pre-commit"

    sed 's|@BATS_LIB_PATH@|/test/lib|' dev.sh > "$TEST_DIR/dev.sh"

    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/lefthook" <<'SH'
#!/usr/bin/env bash
echo "lefthook $*" >> "$LEFTHOOK_LOG"
SH
    chmod +x "$TEST_DIR/bin/lefthook"
}

@test "sets BATS_LIB_PATH from placeholder" {
    cd "$TEST_DIR/repo"
    run bash -c 'unset BATS_LIB_PATH; source "$1"; echo "$BATS_LIB_PATH"' -- "$TEST_DIR/dev.sh"
    assert_success
    assert_output "/test/lib/share/bats"
}

@test "runs lefthook install when hooks are missing" {
    cd "$TEST_DIR/repo"
    rm "$TEST_DIR/repo/.git/hooks/pre-commit"
    # shellcheck disable=SC2030
    export PATH="$TEST_DIR/bin:$PATH"
    # shellcheck disable=SC2030
    export LEFTHOOK_LOG="$TEST_DIR/log"
    # shellcheck disable=SC1091
    source "$TEST_DIR/dev.sh"
    assert [ -f "$LEFTHOOK_LOG" ]
    run cat "$LEFTHOOK_LOG"
    assert_output "lefthook install"
}

@test "skips lefthook install when hooks exist" {
    cd "$TEST_DIR/repo"
    # shellcheck disable=SC2031
    export PATH="$TEST_DIR/bin:$PATH"
    # shellcheck disable=SC2031
    export LEFTHOOK_LOG="$TEST_DIR/log"
    # shellcheck disable=SC1091
    source "$TEST_DIR/dev.sh"
    assert [ ! -f "$LEFTHOOK_LOG" ]
}
