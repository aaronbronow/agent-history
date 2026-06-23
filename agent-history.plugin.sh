# Generic Bash/Zsh loader for agent-history
# Exposes utilities to track and switch to recent workspaces.
# Version: 1.0.0

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

# Automatically display recent projects upon SSH login
if [[ -n "$SSH_CONNECTION" ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        _agent_history_ssh_init() {
            if (( $+functions[p10k] )); then
                autoload -Uz add-zsh-hook
                add-zsh-hook -d precmd _agent_history_ssh_init
                
                _agent_history_p10k_pre_prompt() {
                    if [[ -z "${_agent_history_run_once:-}" ]]; then
                        _agent_history_run_once=1
                        local plugin_dir
                        plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                        local script_path="$plugin_dir/agent-history"
                        if [[ -f "$script_path" ]]; then
                            "$script_path"
                        fi
                    fi
                }
                
                if (( $+functions[p10k-on-pre-prompt] )); then
                    if (( ! $+functions[_agent_history_old_p10k_pre_prompt] )); then
                        functions[_agent_history_old_p10k_pre_prompt]=$functions[p10k-on-pre-prompt]
                        p10k-on-pre-prompt() {
                            _agent_history_old_p10k_pre_prompt "$@"
                            _agent_history_p10k_pre_prompt "$@"
                        }
                    fi
                else
                    p10k-on-pre-prompt() {
                        _agent_history_p10k_pre_prompt "$@"
                    }
                fi
                return
            fi
            
            autoload -Uz add-zsh-hook
            add-zsh-hook -d precmd _agent_history_ssh_init
            local plugin_dir
            plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            local script_path="$plugin_dir/agent-history"
            if [[ -f "$script_path" ]]; then
                "$script_path"
            fi
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _agent_history_ssh_init
    else
        local plugin_dir
        plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local script_path="$plugin_dir/agent-history"
        if [[ -f "$script_path" ]]; then
            "$script_path"
        fi
    fi
fi

# Convenient shortcut alias
alias ah="agent-history"
