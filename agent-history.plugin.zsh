# Oh My Zsh Plugin: agent-history
# Exposes utilities to track and switch to recent Antigravity workspaces.

function ag-recent() {
    # Resolve the plugin's absolute directory to locate the python script
    local plugin_dir="${0:A:h}"
    local script_path="$plugin_dir/antigravity-recent.py"

    if [[ ! -f "$script_path" ]]; then
        echo "Error: antigravity-recent.py not found at $script_path" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        python3 "$script_path"
    elif [[ "$1" =~ ^[1-5]$ ]]; then
        local target_dir
        target_dir=$(python3 "$script_path" --path "$1")
        if [[ -d "$target_dir" ]]; then
            cd "$target_dir" || return 1
        else
            echo "Error: Directory not found: $target_dir" >&2
            return 1
        fi
    else
        echo "Usage: ag-recent [1-5]" >&2
        return 1
    fi
}

# Automatically display recent projects upon SSH login
if [[ -n "$SSH_CONNECTION" ]]; then
    local plugin_dir="${0:A:h}"
    local script_path="$plugin_dir/antigravity-recent.py"
    if [[ -f "$script_path" ]]; then
        python3 "$script_path"
    fi
fi
