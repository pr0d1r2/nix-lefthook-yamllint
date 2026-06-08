#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR"
}

@test "no args exits 0" {
    run lefthook-yamllint
    assert_success
}

@test "non-existent file is skipped" {
    run lefthook-yamllint /nonexistent/file.yml
    assert_success
}

@test "non-yaml files are skipped" {
    echo 'hello' > "$TMP/readme.md"
    run lefthook-yamllint "$TMP/readme.md"
    assert_success
}

@test "valid yaml passes" {
    cat > "$TMP/good.yml" <<'YML'
---
name: test
value: 42
YML
    run lefthook-yamllint "$TMP/good.yml"
    assert_success
}

@test "invalid yaml fails" {
    cat > "$TMP/bad.yml" <<'YML'
name: test
  bad_indent: true
YML
    run lefthook-yamllint "$TMP/bad.yml"
    assert_failure
}

@test ".yaml extension is accepted" {
    cat > "$TMP/good.yaml" <<'YML'
---
name: test
YML
    run lefthook-yamllint "$TMP/good.yaml"
    assert_success
}

@test "multiple files: bad one causes failure" {
    cat > "$TMP/good.yml" <<'YML'
---
name: test
YML
    cat > "$TMP/bad.yml" <<'YML'
name: test
  bad_indent: true
YML
    run lefthook-yamllint "$TMP/good.yml" "$TMP/bad.yml"
    assert_failure
}

@test "LEFTHOOK_YAMLLINT_CONFIG applies a custom config" {
    cat > "$TMP/relaxed.yml" <<'YML'
rules: {}
YML
    cat > "$TMP/dup.yml" <<'YML'
---
a: 1
a: 2
YML
    LEFTHOOK_YAMLLINT_CONFIG="$TMP/relaxed.yml" run lefthook-yamllint "$TMP/dup.yml"
    assert_success
}

@test "LEFTHOOK_YAMLLINT_CONFIG from outside the repo root" {
    mkdir -p "$TMP/out/link"
    cat > "$TMP/out/link/.yamllint.yml" <<'YML'
rules: {}
YML
    cat > "$TMP/dup.yml" <<'YML'
---
a: 1
a: 2
YML
    LEFTHOOK_YAMLLINT_CONFIG="$TMP/out/link/.yamllint.yml" run lefthook-yamllint "$TMP/dup.yml"
    assert_success
}

@test "unset LEFTHOOK_YAMLLINT_CONFIG still flags problems" {
    cat > "$TMP/dup.yml" <<'YML'
---
a: 1
a: 2
YML
    run lefthook-yamllint "$TMP/dup.yml"
    assert_failure
}
