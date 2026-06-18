# agent-history plugin

An Oh My Zsh plugin to track and easily navigate to your most recent projects and workspaces where you have been chatting with the Antigravity coding assistant.

It reads the Antigravity command execution logs (`history.jsonl`), filters out deleted folders and your root home directory, and displays a beautiful status dashboard of the top 5 projects sorted by recency.

## Features

- **Relative Recency Timestamps**: Shows when a project was last edited (e.g. `23h ago`, `2d ago`).
- **Git Branch Integration**: Shows the current active Git branch (works with standard git repositories and git worktrees).
- **Directory Validation**: Automatically filters out projects that have been renamed or deleted.
- **SSH Auto-run Dashboard**: Automatically prints the dashboard on login when establishing an SSH session.
- **Quick Shell Navigation (`ah <num>`)**: Jump directly to a project directory.

## Installation

### 1-Line Quick Install (Recommended)
You can install or update the plugin automatically using our installer script via `curl` or `wget`:
```bash
curl -sSL https://raw.githubusercontent.com/aaronbronow/agent-history/main/install.sh | bash
```

### Manual Installation
Clone this repository into your custom Oh My Zsh plugins folder:
```bash
git clone https://github.com/aaronbronow/agent-history.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/agent-history
```

### 2. Enable the Plugin
Add `agent-history` to the `plugins` array in your `~/.zshrc` configuration file:
```zsh
plugins=(
    # ... other plugins ...
    agent-history
)
```

### 3. Load the Changes
Source your `~/.zshrc` file or open a new terminal session:
```bash
source ~/.zshrc
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
- `AGENT_HISTORY_PATH`: Colon-separated list of agent dot directories to search for session and chat history (e.g. `~/.antigravitycli:~/.gemini/antigravity-cli:~/.copilot`). If unset, defaults to searching all three.
