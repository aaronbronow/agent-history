#!/usr/bin/env bash
# Profiling script for agent-history performance analysis

set -eu

# Source the main script to load its functions into our profiling context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../agent-history"

# High-resolution time helper (returns epoch nanoseconds or milliseconds depending on OS support)
get_time_ns() {
    date +%s%N
}

profile_runs() {
    echo -e "\n=== PERFORMANCE PROFILING ==="
    
    # 1. Profile paths_list generation and find
    local start_time=$(get_time_ns)
    local paths_list=(
        "$HOME/.antigravitycli"
        "$HOME/.gemini/antigravity-cli"
        "$HOME/.gemini/history"
        "$HOME/.claude"
        "$HOME/.copilot"
        "$HOME/.aider"
        "$HOME/.pi"
        "$HOME/.droid"
        "$HOME/.factory"
        "$HOME/.codex"
        "$HOME/.openclaw"
        "$HOME/.hermes"
        "$HOME/.local/share/opencode"
        "$HOME/.opencode"
    )
    
    local existing_paths=()
    for raw_path in "${paths_list[@]}"; do
        local p="${raw_path/#\~/$HOME}"
        if [[ -d "$p" && -r "$p" && -x "$p" ]] || [[ -f "$p" && -r "$p" ]]; then
            existing_paths+=("$p")
        fi
    done

    local matched_files=()
    local start_find=$(get_time_ns)
    if (( ${#existing_paths[@]} > 0 )); then
        while read -r line; do
            if [[ -n "$line" ]]; then
                matched_files+=("$line")
            fi
        done < <(find -L "${existing_paths[@]}" -type f \
            ! -path "*/.tmp/*" \
            ! -path "*/plugins/*" \
            ! -path "*/cache/*" \
            ! -path "*/backups/*" \
            ! -path "*/downloads/*" \
            ! -path "*/node_modules/*" \
            ! -name "rollout-*.jsonl" \
            \( \
                -name "*.jsonl" \
                -o -name ".project_root" \
                -o -name "session-store.db" \
                -o -name ".aider.input.history" \
                -o -name ".aider.history" \
                -o -name "*.db" \
                -o -name "*.sqlite" \
                -o -name "*.sqlite3" \
                -o -path "*/conversations/*.pb" \
                -o -path "*/brain/*/logs/transcript.jsonl" \
                -o -path "*/brain/*/logs/transcript_full.jsonl" \
                -o \( -name "*.json" ! -name "settings.json" ! -name "mcp_config.json" ! -name "projects.json" ! -name "import_manifest.json" ! -name "*.metadata.json" ! -path "*/.system_generated/*" \) \
            \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n 100 || true)
    fi
    local end_find=$(get_time_ns)
    local find_duration=$(( (end_find - start_find) / 1000000 ))
    echo "1. Consolidated find + sort + head: ${find_duration}ms (found ${#matched_files[@]} files)"

    # 2. Profile workspace resolution
    local start_parse=$(get_time_ns)
    local resolved_workspaces=()
    local parsed_count=0
    for entry in "${matched_files[@]}"; do
        local file_path="${entry#* }"
        local ws
        ws=$(get_workspace_from_manifest "$file_path" || true)
        if [[ -n "$ws" ]]; then
            resolved_workspaces+=("$ws")
        fi
        parsed_count=$((parsed_count + 1))
    done
    local end_parse=$(get_time_ns)
    local parse_duration=$(( (end_parse - start_parse) / 1000000 ))
    echo "2. get_workspace_from_manifest (Total parsing ${parsed_count} files): ${parse_duration}ms"

    # 3. Profile git branch checks
    local start_git=$(get_time_ns)
    local git_checked=0
    for ws in "${resolved_workspaces[@]}"; do
        if [[ -d "$ws" ]]; then
            local branch
            branch=$(get_git_branch "$ws" || true)
            git_checked=$((git_checked + 1))
        fi
    done
    local end_git=$(get_time_ns)
    local git_duration=$(( (end_git - start_git) / 1000000 ))
    echo "3. get_git_branch (Total checking ${git_checked} workspaces): ${git_duration}ms"
    
    # 4. Total script run
    local start_main=$(get_time_ns)
    # Run main silently
    main >/dev/null 2>&1 || true
    local end_main=$(get_time_ns)
    local main_duration=$(( (end_main - start_main) / 1000000 ))
    echo "4. Total main execution time: ${main_duration}ms"
    echo "============================="
}

profile_runs
