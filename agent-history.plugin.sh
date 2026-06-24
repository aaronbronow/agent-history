# Generic Bash/Zsh loader for agent-history
# Exposes utilities to track and switch to recent workspaces.
# Version: 1.1.0

function agent-history() {
    # Resolve the plugin's absolute directory to locate the script
    local plugin_dir
    plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local script_path="$plugin_dir/agent-history"

    if [[ ! -f "$script_path" ]]; then
        echo "Error: agent-history not found at $script_path" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        "$script_path"
    elif [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
        local target_dir
        target_dir=$("$script_path" --path "$1")
        if [[ -d "$target_dir" ]]; then
            cd "$target_dir" || return 1
        else
            echo "Error: Directory not found or out of range: $target_dir" >&2
            return 1
        fi
    else
        "$script_path" "$@"
    fi
}

# Convenient shortcut alias
alias ah="agent-history"
