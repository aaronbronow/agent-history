# Fisher / Fish shell plugin: agent-history
# Exposes a command and alias to track and switch to recent workspaces.

function agent-history --description "Track and switch to recent agent workspaces"
    # Resolve the plugin's absolute directory to locate the bash script
    set -l script_dir (dirname (realpath (status current-filename)))
    set -l script_path "$script_dir/agent-history"

    if not test -f "$script_path"
        # If the file is not found (e.g. copied instead of symlinked), fallback to checking
        # common Fisher/Oh My Fish clone locations
        set -l search_paths \
            "$HOME/.config/fish/conf.d/agent-history" \
            "$HOME/.local/share/fisher/github.com/aaronbronow/agent-history" \
            "$HOME/.local/share/omf/db/pkg/agent-history"
        for p in $search_paths
            if test -f "$p/agent-history"
                set script_path "$p/agent-history"
                break
            end
        end
    end

    if not test -f "$script_path"
        echo "Error: agent-history executable not found" >&2
        return 1
    end

    if test (count $argv) -eq 0
        bash "$script_path"
    else if string match -q -r '^[1-5]$' -- "$argv[1]"
        set -l target_dir (bash "$script_path" --path "$argv[1]")
        if test -d "$target_dir"
            cd "$target_dir"
        else
            echo "Error: Directory not found: $target_dir" >&2
            return 1
        end
    else
        echo "Usage: ah [1-5]" >&2
        return 1
    fi
end

# Automatically display recent projects upon SSH login
if test -n "$SSH_CONNECTION"
    set -l script_dir (dirname (realpath (status current-filename)))
    set -l script_path "$script_dir/agent-history"
    if not test -f "$script_path"
        set -l search_paths \
            "$HOME/.config/fish/conf.d/agent-history" \
            "$HOME/.local/share/fisher/github.com/aaronbronow/agent-history" \
            "$HOME/.local/share/omf/db/pkg/agent-history"
        for p in $search_paths
            if test -f "$p/agent-history"
                set script_path "$p/agent-history"
                break
            end
        end
    end
    if test -f "$script_path"
        bash "$script_path"
    end
end

# Convenient shortcut alias
alias ah="agent-history"
