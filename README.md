# agent-history plugin

A universal shell plugin (supporting Zsh, Bash, and Fish) to track and easily navigate to your most recent projects and workspaces where you have been chatting with AI coding assistants (such as Antigravity, Claude Code, Copilot, Aider, and Pi).

It reads the command execution logs and session databases, filters out deleted folders and your root home directory, and displays a beautiful status dashboard of the top 5 projects sorted by recency.

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
⚡ Recent Antigravity Projects
  1. ~/dev/scratch/wp                         (23h ago)
  2. ~/dev/scratch/threads-reader             (main) (23h ago)
  3. ~/dev/yaml/pyyaml                        (dos-in-merge-key) (1d ago)
  4. ~/dev/scratch/gsig_app                   (bookstore-app) (2d ago)
  5. ~/dev/packablock                         (main) (4d ago)

💡 Run ah <num> to jump to a project folder.
```

### Quick Jump
To switch your shell's current working directory directly to one of the listed projects, pass the project index:
```bash
ah 2
```

## Configuration

The plugin supports environment overrides:
- `AGENT_HISTORY_PATH`: Colon-separated list of agent dot directories to search for session and chat history (e.g. `~/.antigravitycli:~/.gemini/antigravity-cli:~/.copilot`). If unset, defaults to searching all of them.
- `AGENT_HISTORY_LIMIT`: Number of recent projects to display in the list (default is `5`, maximum is `25` to maintain sub-200ms prompt loading performance).

## 🗺️ Porting to Other Shells (Contribute!)

To keep the core engine highly optimized and lightweight, `agent-history` is natively written for **Zsh and generic Bash**. 

If you are an avid user of **Fish, PowerShell, NuShell,** or any other environment, I would love to see this tool ported! Please feel free to fork the repository and build an implementation for your favorite shell. 

### How to Port the Logic
The core engine follows a strict 3-level resolution pattern that you can easily replicate in your native shell syntax:
1. **Level 1 (Direct Query):** Look for global/local agent dotfiles (e.g., `~/.claude/`, `~/.gemini/`) and parse their configuration JSON or SQLite databases.
2. **Level 2 (Text Log Scanning):** Fall back to reading chronological structured text logs (like `history.jsonl`).
3. **Level 3 (Stream Parsing Fallback):** If heavy JSON/database tools are missing, use your shell's native pattern matching or stream filtering to safely scrape path strings directly from the raw data streams.

Open an issue or submit a link to your fork so it can be highlighted here!
