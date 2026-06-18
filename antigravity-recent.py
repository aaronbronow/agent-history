#!/usr/bin/env python3
import os
import sys
import json
import time

def get_git_branch(path):
    """
    Attempts to read the current Git branch name for a directory without running git commands.
    Supports standard git directories and worktrees.
    """
    git_path = os.path.join(path, '.git')
    if not os.path.exists(git_path):
        return None
    if os.path.isfile(git_path):
        try:
            with open(git_path, 'r', encoding='utf-8') as f:
                content = f.read().strip()
                if content.startswith('gitdir: '):
                    git_path = content.partition('gitdir: ')[-1].strip()
                    if not os.path.isabs(git_path):
                        git_path = os.path.abspath(os.path.join(path, git_path))
        except:
            return None
    if not os.path.isdir(git_path):
        return None
    head_file = os.path.join(git_path, 'HEAD')
    if not os.path.isfile(head_file):
        return None
    try:
        with open(head_file, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            if content.startswith('ref: '):
                return content.partition('refs/heads/')[-1]
            return content[:7]
    except:
        return None

def format_relative_time(epoch_ms, current_time):
    """
    Formats epoch milliseconds to a human-readable relative time representation.
    """
    sec_diff = int(current_time - epoch_ms / 1000)
    if sec_diff < 0:
        return "just now"
    if sec_diff < 60:
        return f"{sec_diff}s ago"
    if sec_diff < 3600:
        return f"{sec_diff // 60}m ago"
    if sec_diff < 86400:
        return f"{sec_diff // 3600}h ago"
    return f"{sec_diff // 86400}d ago"

def parse_history(history_path, home_dir):
    """
    Parses the history log file and returns a list of unique, existing workspaces 
    sorted by recency, excluding the home directory.
    """
    wts = {}
    if os.path.exists(history_path):
        try:
            with open(history_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if not line.strip():
                        continue
                    try:
                        data = json.loads(line)
                        w = data.get('workspace')
                        t = data.get('timestamp')
                        # Exclude home directory and ensure workspace is a valid directory
                        if w and t and w != home_dir and os.path.isdir(w):
                            wts[w] = max(wts.get(w, 0), int(t))
                    except:
                        continue
        except Exception as e:
            print(f"Error reading history file: {e}", file=sys.stderr)
            sys.exit(1)
    return sorted(wts.items(), key=lambda x: x[1], reverse=True)[:5]

def main():
    # Environment variable overrides for testing
    history_path = os.getenv('ANTIGRAVITY_HISTORY_FILE', os.path.expanduser('~/.gemini/antigravity-cli/history.jsonl'))
    mock_time_env = os.getenv('ANTIGRAVITY_MOCK_TIME')
    current_time = float(mock_time_env) if mock_time_env else time.time()
    
    home = os.path.expanduser('~')
    sorted_w = parse_history(history_path, home)
    
    # Handle direct path query arguments (used by shell navigation wrapper)
    if len(sys.argv) == 3 and sys.argv[1] == '--path':
        try:
            idx = int(sys.argv[2]) - 1
            if 0 <= idx < len(sorted_w):
                print(sorted_w[idx][0])
                sys.exit(0)
            else:
                sys.exit(1)
        except ValueError:
            sys.exit(1)
            
    # Print formatted list output
    RESET = "\033[0m"
    BOLD = "\033[1m"
    CYAN = "\033[36m"
    GREEN = "\033[32m"
    GRAY = "\033[90m"
    PURPLE = "\033[35m"
    
    if not sorted_w:
        print(f"{BOLD}Recent Antigravity Projects:{RESET} None found.")
        return
        
    print(f"\n{BOLD}{PURPLE}⚡ Recent Antigravity Projects{RESET}")
    for i, (w, t) in enumerate(sorted_w):
        rel_time = format_relative_time(t, current_time)
        branch = get_git_branch(w)
        branch_str = f" {GREEN}({branch}){RESET}" if branch else ""
        
        display_path = w.replace(home, '~')
        print(f"  {i+1}. {CYAN}{display_path:<40}{RESET}{branch_str} {GRAY}({rel_time}){RESET}")
    print(f"\n💡 {GRAY}Run {BOLD}ag-recent <num>{RESET}{GRAY} to jump to a project folder.{RESET}\n")

if __name__ == '__main__':
    main()
