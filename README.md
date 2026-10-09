# agent-history plugin

[![Awesome Zsh Plugins](https://img.shields.io/badge/awesome--zsh--plugins-listed-brightgreen.svg)](https://github.com/unixorn/awesome-zsh-plugins)
[![GitHub Release](https://img.shields.io/github/v/release/aaronbronow/agent-history?color=blue)](https://github.com/aaronbronow/agent-history/releases/latest)

The fastest shell shortcut to resume your recent AI coding sessions before your terminal cools down.

It reads execution logs and session databases from AI coding assistants (such as Claude Code, GitHub Copilot, Aider, Gemini / Antigravity, Pi, Droid, Factory, Codex, OpenClaw, Hermes, and OpenCode), filters out deleted folders and home directory roots, and displays a beautiful status dashboard of your most recent sessions.

![agent-history Demo](demos/ah%201.gif)

## Features

- **Relative Recency Timestamps**: Shows when a project was last edited (e.g. `23h ago`, `2d ago`).
- **Git Branch Integration**: Shows the current active Git branch (works with standard git repositories and git worktrees).
- **Directory Validation**: Automatically filters out projects that have been renamed or deleted.
- **SSH Auto-run Dashboard**: Automatically prints the dashboard on login when establishing an SSH session.
- **Adaptive Mobile Layout**: Dynamically adjusts padding on narrow screens to prevent lines from wrapping.
- **Smart Path Shrinking**: Shortens intermediate directory names to 1 letter (e.g. `~/d/s/jobsearch` -> `~/d/s/jobsearch`) if the path exceeds the terminal width, keeping the project's leaf folder intact.
- **High-Performance (Under 200ms)**: Consolidates search queries into a single `find` run and leverages pure Bash built-ins to eliminate subprocess fork overhead, keeping shell load times completely lag-free.
- **Quick Shell Navigation (`ah <num>`)**: Jump directly to a project directory.

## Installation & Shell Support

### 1-Line Quick Install (Recommended)
You can install or update the plugin automatically using our installer script via `curl`:
```bash
curl -sSL https://raw.githubusercontent.com/aaronbronow/agent-history/main/install.sh | bash
```

### Zsh Frameworks (Oh My Zsh, Antidote, Zinit, Zim)
* **Oh My Zsh**: Clone this repository into your custom plugins folder:
  ```bash
  git clone https://github.com/aaronbronow/agent-history.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/agent-history
  ```
  Then add `agent-history` to your `plugins=(...)` list in `~/.zshrc`.
* **Antidote / Zinit**: Add `aaronbronow/agent-history` to your plugins file (`plugins.txt` for Antidote). It will automatically load via `agent-history.plugin.zsh`.

### Generic Bash / Manual Installation
1. Clone the repository to a folder of your choice:
   ```bash
   git clone https://github.com/aaronbronow/agent-history.git ~/.agent-history
   ```
2. Source the helper script in your `~/.bashrc` or `~/.zshrc` (if not using a plugin manager):
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   source ~/.agent-history/agent-history.plugin.zsh  # For Zsh
   # (For Bash, you can alias or add to PATH)
   ```

## Usage

### Display Recent Projects
Simply type `agent-history` (or use the convenient shortcut alias `ah`):
```bash
ah
```
Output:
```
⚡ Recent Agent Sessions
  1. ~/dev/chat-bot                           (main) (Claude · 2m ago)
  2. ~/projects/next-auth                     (oauth-fix) (Aider · 1h ago)
  3. ~/src/web-scraper                        (main) (Gemini · 3h ago)
  4. ~/work/pricing-api                       (feature-rules) (Copilot · 1d ago)
  5. ~/personal/dotfiles                      (main) (Claude · 3d ago)

💡 Run ah <num> to jump to a project folder. (showing 5 most recent)
```

### Quick Jump
To switch your shell's current working directory directly to one of the listed projects, pass the project index:
```bash
ah 2
```

### Command Options
You can configure or adjust the active session limits dynamically using flags:
* `ah -a` or `ah --all`: Display all matching workspace sessions up to the performance cap of 25.
* `ah -n <num>`: Display exactly the specified `<num>` of sessions (1 to 25).
* `ah -h` or `ah --help`: Display the usage guidelines and help panel.
* `ah -v` or `ah --version`: Display the version.

## Configuration

The plugin supports environment overrides:
- `AGENT_HISTORY_PATH`: Colon-separated list of agent dot directories to search for session and chat history (e.g. `~/.antigravitycli:~/.gemini/antigravity-cli:~/.copilot`). If unset, defaults to searching all of them.
- `AGENT_HISTORY_LIMIT`: Number of recent projects to display in the list (default is `5`, maximum is `25` to maintain sub-200ms prompt loading performance).

### Auto-run on Startup / SSH Login

To automatically display recent workspaces when opening a terminal or logging in via SSH, append the command to your `~/.zshrc`. 

> [!TIP]
> If you are using **Powerlevel10k with Instant Prompt**, place this block at the very **top** of your `~/.zshrc` (above the instant prompt preamble block) to prevent initialization console warnings.

**Show on SSH login only (Recommended):**
```zsh
if [[ -n "$SSH_CONNECTION" ]]; then
  # Adjust path if installed in a different location
  local script_path="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/agent-history/agent-history"
  [[ -f "$script_path" ]] && "$script_path"
fi
```

**Show on every terminal open:**
```zsh
# Simply invoke the ah alias/function
ah
```


## 🗺️ Porting to Other Shells (Contribute!)

To keep the core engine highly optimized and lightweight, `agent-history` is natively written for **Zsh and generic Bash**. 

If you are an avid user of **Fish, PowerShell, NuShell,** or any other environment, I would love to see this tool ported! Please feel free to fork the repository and build an implementation for your favorite shell. 

### How to Port the Logic
The core engine follows a strict 3-level resolution pattern that you can easily replicate in your native shell syntax:
1. **Level 1 (Direct Query):** Look for global/local agent dotfiles (e.g., `~/.claude/`, `~/.gemini/`) and parse their configuration JSON or SQLite databases.
2. **Level 2 (Text Log Scanning):** Fall back to reading chronological structured text logs (like `history.jsonl`).
3. **Level 3 (Stream Parsing Fallback):** If heavy JSON/database tools are missing, use your shell's native pattern matching or stream filtering to safely scrape path strings directly from the raw data streams.

Open an issue or submit a link to your fork so it can be highlighted here!
