# Oh My Zsh Plugin: agent-history
# Exposes utilities to track and switch to recent Antigravity workspaces.
# Version: 1.0.0

# Get the directory of the current script (works during sourcing)
_AGENT_HISTORY_DIR="${${(%):-%x}:A:h}"

function agent-history() {
    local script_path="$_AGENT_HISTORY_DIR/agent-history"

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

# Helper function to run once at startup after zsh finishes initializing
_agent_history_ssh_init() {
    local script_path="$_AGENT_HISTORY_DIR/agent-history"
    if [[ -f "$script_path" ]]; then
        "$script_path"
    fi
}

# Automatically display recent projects upon SSH login (scheduled to prevent Powerlevel10k instant prompt warning)
if [[ -n "$SSH_CONNECTION" ]]; then
    sched +1 _agent_history_ssh_init
fi

# Convenient shortcut alias
alias ah="agent-history"

