# Design and Implementation Details

This document outlines how the `agent-history` plugin was designed, implemented, and optimized.

## 1. Context & Discovery
During pair programming, we needed a script to show the last 5 projects the user was chatting with Antigravity in, sorted by recency.

We inspected the Antigravity application directory (`~/.gemini/antigravity-cli`) and discovered the following:
- `history.jsonl`: A JSON lines log storing history events.
- Each event containing a workspace path, a conversation identifier, and a Unix millisecond timestamp.
  ```json
  {"display":"some prompt","timestamp":1781716101217,"workspace":"/home/aaron/dev/abc","conversationId":"b29681b0-aaa5-...","type":"slash_command"}
  ```

## 2. Key Design Decisions

### Manual `.git/HEAD` Parsing (Performance)
Instead of launching a `git` shell subprocess (e.g. `git branch --show-current`) for each directory, which is expensive and slow, the python script parses the git HEAD file directly:
1. Looks for `.git/HEAD`.
2. Resolves Git worktrees where `.git` is a file containing `gitdir: <path>`.
3. Parses references (`ref: refs/heads/<branch>`) or falls back to short hashes for detached HEAD states.
This results in instantaneous load times (less than 5ms total execution time), keeping interactive logins completely lag-free.

### Workspace Filtering & Validation
1. **Home Directory Exclusion**: The user's root home directory (`~`) is excluded by default since global chats outside specific workspaces clutter the project history.
2. **Path Verification**: The script checks `os.path.isdir(path)` to verify directories still exist. Deleted or moved folders are automatically filtered out, ensuring all listed items are valid navigation targets.
3. **De-duplication**: The log is processed bottom-up, keeping only the highest timestamp per workspace.

### Parent Shell Navigation Trick
A child process (the python script) cannot change the current working directory (`cd`) of its parent shell. 
To resolve this:
1. The Zsh function `agent-history` (aliased as `ah`) is the primary interface.
2. If arguments are passed (e.g., `ah 2`), it queries the Bash script using a hidden argument: `agent-history --path 2`.
3. The Bash script outputs only the raw directory path.
4. The Zsh wrapper captures this output and calls `cd` in the parent process.

## 3. Testability
To allow robust unit tests, the Bash script accepts two override environment variables:
- `ANTIGRAVITY_HISTORY_FILE`: Allows pointing to custom mock JSONL fixtures.
- `ANTIGRAVITY_MOCK_TIME`: Locks the "current" system time for deterministic relative time formatting assertions.
This allows running fast Bash unit tests without interfering with the live history files.
