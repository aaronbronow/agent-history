# VHS Tape to record agent-history demo
# Run `vhs demo.tape` to generate demo.gif

# Set shell to zsh
Set Shell "zsh"

# Output configuration
Output demo.gif

# Terminal Settings
Set FontSize 18
Set Width 1200
Set Height 600
Set Padding 20
# Set Theme "Catppuccin Mocha"

# --- Setup Phase (Hidden from final recording) ---
Hide
Type "export AGENT_HISTORY_PATH='/home/aaron/dev/scratch/mock_agent_dir'" Enter
Type "source /home/aaron/dev/agent-history/agent-history.plugin.zsh" Enter
Type "PROMPT='%~ ❯ '" Enter
Type "cd ~" Enter
Type "clear" Enter
Sleep 1s
Show

# --- Active Demo Phase ---

# 1. Show agent sessions list
Type "ah"
Sleep 500ms
Enter
Sleep 4s

# 2. Jump to quantum-ledger workspace (item 1)
Type "ah 1"
Sleep 500ms
Enter
Sleep 2s

# 3. Start a new Claude Code session in the target directory
Type "claude -c"
Sleep 3s
#Enter
#Sleep 3s
