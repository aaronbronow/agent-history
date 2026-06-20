# Oh My Zsh Plugin: agent-history
# Exposes utilities to track and switch to recent Antigravity workspaces.

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
    elif [[ "$1" =~ ^[1-5]$ ]]; then
        local target_dir
        target_dir=$("$script_path" --path "$1")
        if [[ -d "$target_dir" ]]; then
            cd "$target_dir" || return 1
        else
            echo "Error: Directory not found: $target_dir" >&2
            return 1
        fi
    else
        echo "Usage: ah [1-5]" >&2
        return 1
    fi
}

# Helper function to run once at startup after zsh finishes initializing
_agent_history_ssh_init() {
    # Deregister function from precmd hooks so it only runs once
    autoload -Uz add-zsh-hook
    add-zsh-hook -d precmd _agent_history_ssh_init
    
    local script_path="$_AGENT_HISTORY_DIR/agent-history"
    if [[ -f "$script_path" ]]; then
        "$script_path"
    fi
}

# Automatically display recent projects upon SSH login (delayed to prevent Powerlevel10k instant prompt warning)
if [[ -n "$SSH_CONNECTION" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _agent_history_ssh_init
fi

# Convenient shortcut alias
alias ah="agent-history"

