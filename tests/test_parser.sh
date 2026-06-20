#!/usr/bin/env bash
# Unit tests for agent-history

set -eu

# Source the script under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../agent-history"

# Assertion helper
assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    if [[ "$expected" != "$actual" ]]; then
        echo "FAIL: $msg (Expected: '$expected', Actual: '$actual')" >&2
        exit 1
    fi
}

test_format_relative_time() {
    echo "Running test_format_relative_time..."
    
    # Lock mock time for testing
    export ANTIGRAVITY_MOCK_TIME=1780000000
    
    # 10s ago
    assert_equals "10s ago" "$(format_relative_time $((1780000000 - 10)))" "10s ago calculation"
    
    # 5m ago
    assert_equals "5m ago" "$(format_relative_time $((1780000000 - 300)))" "5m ago calculation"
    
    # 3h ago
    assert_equals "3h ago" "$(format_relative_time $((1780000000 - 10800)))" "3h ago calculation"
    
    # 2d ago
    assert_equals "2d ago" "$(format_relative_time $((1780000000 - 172800)))" "2d ago calculation"
    
    # Future / negative -> just now
    assert_equals "just now" "$(format_relative_time $((1780000000 + 10)))" "just now calculation"
    
    unset ANTIGRAVITY_MOCK_TIME
}

test_get_git_branch_standard() {
    echo "Running test_get_git_branch_standard..."
    local test_dir
    test_dir=$(mktemp -d)
    
    mkdir -p "$test_dir/.git"
    echo "ref: refs/heads/feature/cool-stuff" > "$test_dir/.git/HEAD"
    
    assert_equals "feature/cool-stuff" "$(get_git_branch "$test_dir")" "Standard git branch resolution"
    
    rm -rf "$test_dir"
}

test_get_git_branch_detached() {
    echo "Running test_get_git_branch_detached..."
    local test_dir
    test_dir=$(mktemp -d)
    
    mkdir -p "$test_dir/.git"
    echo "a1b2c3d4e5f6" > "$test_dir/.git/HEAD"
    
    assert_equals "a1b2c3d" "$(get_git_branch "$test_dir")" "Detached HEAD branch resolution"
    
    rm -rf "$test_dir"
}

test_get_git_branch_worktree() {
    echo "Running test_get_git_branch_worktree..."
    local test_dir
    test_dir=$(mktemp -d)
    
    local real_git_dir
    real_git_dir=$(mktemp -d)
    
    echo "gitdir: $real_git_dir" > "$test_dir/.git"
    echo "ref: refs/heads/worktree-branch" > "$real_git_dir/HEAD"
    
    assert_equals "worktree-branch" "$(get_git_branch "$test_dir")" "Worktree branch resolution"
    
    rm -rf "$test_dir" "$real_git_dir"
}

test_get_workspace_from_manifest_json() {
    echo "Running test_get_workspace_from_manifest_json..."
    local test_dir
    test_dir=$(mktemp -d)
    
    local manifest="$test_dir/manifest.json"
    echo '{"name": "/home/aaron/dev/foo"}' > "$manifest"
    assert_equals "/home/aaron/dev/foo" "$(get_workspace_from_manifest "$manifest")" "JSON manifest resolution via name"
    
    echo '{"projectResources": {"resources": [{"folderUri": "file:///home/aaron/dev/bar"}]}}' > "$manifest"
    assert_equals "/home/aaron/dev/bar" "$(get_workspace_from_manifest "$manifest")" "JSON manifest resolution via folderUri"
    
    rm -rf "$test_dir"
}

test_get_workspace_from_manifest_history_jsonl() {
    echo "Running test_get_workspace_from_manifest_history_jsonl..."
    local test_dir
    test_dir=$(mktemp -d)
    
    local hist="$test_dir/history.jsonl"
    echo '{"workspace": "/home/aaron/dev/project1"}' > "$hist"
    echo '{"workspace": "/home/aaron/dev/project2"}' >> "$hist"
    
    assert_equals "/home/aaron/dev/project2" "$(get_workspace_from_manifest "$hist")" "history.jsonl workspace resolution"
    
    rm -rf "$test_dir"
}

test_get_workspace_from_manifest_db() {
    echo "Running test_get_workspace_from_manifest_db..."
    local test_dir
    test_dir=$(mktemp -d)
    
    # Create conversations dir
    mkdir -p "$test_dir/conversations"
    local db_file="$test_dir/conversations/1234.db"
    
    # Initialize mock SQLite DB
    sqlite3 "$db_file" "CREATE TABLE trajectory_metadata_blob (id TEXT PRIMARY KEY, data BLOB);"
    # Insert mock binary blob containing file:///home/aaron/dev/test-db-ws
    sqlite3 "$db_file" "INSERT INTO trajectory_metadata_blob (id, data) VALUES ('main', x'66696c653a2f2f2f686f6d652f6161726f6e2f6465762f746573742d64622d7773');"
    
    assert_equals "/home/aaron/dev/test-db-ws" "$(get_workspace_from_manifest "$db_file")" "SQLite database direct extraction"
    
    rm -rf "$test_dir"
}

test_get_workspace_from_manifest_fallbacks() {
    echo "Running test_get_workspace_from_manifest_fallbacks..."
    local test_dir
    test_dir=$(mktemp -d)
    
    # Override hash function to simulate missing jq and sqlite3
    hash() {
        if [[ "$1" == "jq" || "$1" == "sqlite3" ]]; then
            return 1
        fi
        builtin hash "$@"
    }
    
    # Test JSON manifest parsing fallback
    local manifest="$test_dir/manifest.json"
    echo '{"name": "/home/aaron/dev/foo-fallback"}' > "$manifest"
    assert_equals "/home/aaron/dev/foo-fallback" "$(get_workspace_from_manifest "$manifest")" "JSON manifest fallback via name"
    
    echo '{"projectResources": {"resources": [{"folderUri": "file:///home/aaron/dev/bar-fallback"}]}}' > "$manifest"
    assert_equals "/home/aaron/dev/bar-fallback" "$(get_workspace_from_manifest "$manifest")" "JSON manifest fallback via folderUri"

    # Test history.jsonl parsing fallback
    local hist="$test_dir/history.jsonl"
    echo '{"workspace": "/home/aaron/dev/project-fallback"}' > "$hist"
    assert_equals "/home/aaron/dev/project-fallback" "$(get_workspace_from_manifest "$hist")" "history.jsonl fallback workspace resolution"

    # Test SQLite binary db parsing fallback
    mkdir -p "$test_dir/conversations"
    local db_file="$test_dir/conversations/9999.db"
    
    # Create database structure but write binary content directly
    sqlite3 "$db_file" "CREATE TABLE trajectory_metadata_blob (id TEXT PRIMARY KEY, data BLOB);"
    sqlite3 "$db_file" "INSERT INTO trajectory_metadata_blob (id, data) VALUES ('main', x'66696c653a2f2f2f686f6d652f6161726f6e2f6465762f746573742d62696e6172792d66616c6c6261636b');"
    
    # Since sqlite3 is mocked as missing, it will use step 3: POSIX binary DB parsing fallback
    assert_equals "/home/aaron/dev/test-binary-fallback" "$(get_workspace_from_manifest "$db_file")" "SQLite database POSIX binary fallback extraction"

    # Clean up mock function
    unset -f hash
    rm -rf "$test_dir"
}

test_get_workspace_from_manifest_project_root() {
    echo "Running test_get_workspace_from_manifest_project_root..."
    local test_dir
    test_dir=$(mktemp -d)
    
    local pr_file="$test_dir/.project_root"
    echo "/home/aaron/dev/my-project" > "$pr_file"
    
    assert_equals "/home/aaron/dev/my-project" "$(get_workspace_from_manifest "$pr_file")" ".project_root workspace resolution"
    
    rm -rf "$test_dir"
}

test_get_workspace_from_manifest_aider() {
    echo "Running test_get_workspace_from_manifest_aider..."
    local test_dir
    test_dir=$(mktemp -d)
    
    local aider_file="$test_dir/.aider.input.history"
    touch "$aider_file"
    
    assert_equals "$test_dir" "$(get_workspace_from_manifest "$aider_file")" ".aider.input.history workspace resolution"
    
    rm -rf "$test_dir"
}

test_resolve_encoded_path() {
    echo "Running test_resolve_encoded_path..."
    local test_dir
    test_dir=$(mktemp -d)
    
    # We will construct a real temp directory structure
    local project_dir="$test_dir/my-cool-project"
    mkdir -p "$project_dir"
    
    local encoded
    encoded=$(echo "$project_dir" | sed 's|/|-|g')
    encoded="--${encoded}--"
    
    local resolved
    resolved=$(resolve_encoded_path "$encoded")
    assert_equals "$project_dir" "$resolved" "resolve_encoded_path on mock project dir"
    
    rm -rf "$test_dir"
}

test_get_workspace_from_manifest_pi() {
    echo "Running test_get_workspace_from_manifest_pi..."
    local test_dir
    test_dir=$(mktemp -d)
    
    local project_dir="$test_dir/project-foo"
    mkdir -p "$project_dir"
    
    local encoded
    encoded=$(echo "$project_dir" | sed 's|/|-|g')
    
    local pi_dir="$test_dir/.pi/agent/sessions/--${encoded}--"
    mkdir -p "$pi_dir"
    local session_file="$pi_dir/12345_xyz.jsonl"
    touch "$session_file"
    
    assert_equals "$project_dir" "$(get_workspace_from_manifest "$session_file")" "Pi session workspace extraction"
    
    rm -rf "$test_dir"
}

test_get_workspace_from_manifest_opencode() {
    echo "Running test_get_workspace_from_manifest_opencode..."
    local test_dir
    test_dir=$(mktemp -d)
    
    local db_file="$test_dir/opencode.db"
    
    sqlite3 "$db_file" "CREATE TABLE session (directory TEXT, time_updated INTEGER);"
    sqlite3 "$db_file" "INSERT INTO session (directory, time_updated) VALUES ('/home/aaron/dev/project-a', 100);"
    sqlite3 "$db_file" "INSERT INTO session (directory, time_updated) VALUES ('/home/aaron/dev/project-b', 200);"
    
    assert_equals "/home/aaron/dev/project-b" "$(get_workspace_from_manifest "$db_file")" "OpenCode SQLite db workspace extraction"
    
    # Test POSIX fallback for OpenCode
    # Override hash function to simulate missing sqlite3
    hash() {
        if [[ "$1" == "sqlite3" || "$1" == "jq" ]]; then
            return 1
        fi
        builtin hash "$@"
    }
    
    local fallback_db_file="$test_dir/opencode_fallback.db"
    sqlite3 "$fallback_db_file" "CREATE TABLE session (directory TEXT, time_updated INTEGER);"
    sqlite3 "$fallback_db_file" "INSERT INTO session (directory, time_updated) VALUES ('/home/aaron/dev/project-fallback', 1);"
    
    assert_equals "/home/aaron/dev/project-fallback" "$(get_workspace_from_manifest "$fallback_db_file")" "OpenCode SQLite db POSIX fallback extraction"
    
    unset -f hash
    rm -rf "$test_dir"
}

test_shrink_path() {
    echo "Running test_shrink_path..."
    assert_equals "foo" "$(shrink_path "foo")" "Short path (no directories)"
    assert_equals "foo/bar" "$(shrink_path "foo/bar")" "Short path (2 parts)"
    assert_equals "~/d/s/jobsearch" "$(shrink_path "~/dev/scratch/jobsearch")" "OMZ style path"
    assert_equals "/h/a/d/s/jobsearch" "$(shrink_path "/home/aaron/dev/scratch/jobsearch")" "Absolute path"
    assert_equals "/a/b/c" "$(shrink_path "/a/b/c")" "3 parts path"
}

test_version_flag() {
    echo "Running test_version_flag..."
    local script_bin="$SCRIPT_DIR/../agent-history"
    
    local version_out_short
    version_out_short=$("$script_bin" -v)
    assert_equals "agent-history 1.0.0" "$version_out_short" "-v flag output"
    
    local version_out_long
    version_out_long=$("$script_bin" --version)
    assert_equals "agent-history 1.0.0" "$version_out_long" "--version flag output"
}

test_help_flag() {
    echo "Running test_help_flag..."
    local script_bin="$SCRIPT_DIR/../agent-history"
    
    local help_out_short
    help_out_short=$("$script_bin" -h)
    if [[ ! "$help_out_short" == *"https://github.com/aaronbronow/agent-history"* || ! "$help_out_short" == *"AGENT_HISTORY_PATH"* ]]; then
        echo "FAIL: -h flag output does not contain expected help sections" >&2
        exit 1
    fi
    
    local help_out_long
    help_out_long=$("$script_bin" --help)
    if [[ ! "$help_out_long" == *"https://github.com/aaronbronow/agent-history"* || ! "$help_out_long" == *"AGENT_HISTORY_PATH"* ]]; then
        echo "FAIL: --help flag output does not contain expected help sections" >&2
        exit 1
    fi

    local help_out_question
    help_out_question=$("$script_bin" "-?")
    if [[ ! "$help_out_question" == *"https://github.com/aaronbronow/agent-history"* || ! "$help_out_question" == *"AGENT_HISTORY_PATH"* ]]; then
        echo "FAIL: -? flag output does not contain expected help sections" >&2
        exit 1
    fi
}

test_history_limit() {
    echo "Running test_history_limit..."
    local script_bin="$SCRIPT_DIR/../agent-history"
    local temp_path
    temp_path=$(mktemp -d)
    
    # Create 10 different workspace directories and corresponding .project_root files
    local i
    for i in {1..10}; do
        local ws="$temp_path/ws_$i"
        mkdir -p "$ws"
        # Create a mock session file in each
        local pr_file="$ws/.project_root"
        echo "$ws" > "$pr_file"
        # Set different mtimes to ensure deterministic sorting order
        local t_val
        t_val=$(printf "2026062000%02d" "$i")
        touch -m -t "$t_val" "$pr_file"
    done
    
    # Use only our temp path for searches
    export AGENT_HISTORY_PATH="$temp_path"
    
    # Test default limit (should print 5 items)
    local out_default
    out_default=$(AGENT_HISTORY_LIMIT= "$script_bin" | grep -c -E '^[[:space:]]+[0-9]+\. ')
    assert_equals "5" "$out_default" "Default limit count"
    
    # Test limit set to 3
    local out_3
    out_3=$(AGENT_HISTORY_LIMIT=3 "$script_bin" | grep -c -E '^[[:space:]]+[0-9]+\. ')
    assert_equals "3" "$out_3" "Limit set to 3"
    
    # Test limit set to 8
    local out_8
    out_8=$(AGENT_HISTORY_LIMIT=8 "$script_bin" | grep -c -E '^[[:space:]]+[0-9]+\. ')
    assert_equals "8" "$out_8" "Limit set to 8"
    
    # Test limit set to 50 (should ceiling to max_limit=25, or since we only have 10, should show 10)
    local out_50
    out_50=$(AGENT_HISTORY_LIMIT=50 "$script_bin" | grep -c -E '^[[:space:]]+[0-9]+\. ')
    assert_equals "10" "$out_50" "Limit set to 50 with 10 available workspaces"
    
    # Test invalid limit (negative or non-numeric) fallback to default (5)
    local out_invalid
    out_invalid=$(AGENT_HISTORY_LIMIT=abc "$script_bin" | grep -c -E '^[[:space:]]+[0-9]+\. ')
    assert_equals "5" "$out_invalid" "Invalid limit fallback count"
    
    unset AGENT_HISTORY_PATH
    rm -rf "$temp_path"
}

# Run all tests
test_format_relative_time
test_get_git_branch_standard
test_get_git_branch_detached
test_get_git_branch_worktree
test_get_workspace_from_manifest_json
test_get_workspace_from_manifest_history_jsonl
test_get_workspace_from_manifest_db
test_get_workspace_from_manifest_fallbacks
test_get_workspace_from_manifest_project_root
test_get_workspace_from_manifest_aider
test_resolve_encoded_path
test_get_workspace_from_manifest_pi
test_get_workspace_from_manifest_opencode
test_shrink_path
test_version_flag
test_help_flag
test_history_limit

echo "ALL TESTS PASSED SUCCESSFULLY!"

