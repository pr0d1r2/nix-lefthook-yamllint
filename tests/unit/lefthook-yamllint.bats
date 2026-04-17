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
