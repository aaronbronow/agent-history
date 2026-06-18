# Workspace Learnings & Rules for agent-history

These rules and learnings should guide future updates and maintenance tasks in the `agent-history` repository.

## 1. POSIX Fallback Parsing & Regex Strictness
- When extracting absolute file paths from binary logs or databases (e.g. SQLite files) via POSIX tools, always restrict matching to valid path characters `[a-zA-Z0-9_./-]+` instead of matching all non-control characters (`[^[:cntrl:]]`).
- Raw integers or field lengths adjacent to strings in SQLite row formats can map to printable ASCII characters (e.g. integer `100` translates to character `d`) and corrupt the matches unless restricted or validated.
- Always check that any extracted path exists (`[[ -d "$path" ]]`) before utilizing it for shell navigation.

## 2. Hyphen-Encoded Path Resolution
- To map hyphen-encoded paths (like Pi CLI's `--home-aaron-dev-agent-history--` directory names) back to standard Unix/macOS paths, use the backtracking algorithm:
  1. Strip leading and trailing double-hyphens.
  2. Split by hyphens (`-`).
  3. Start backtracking search (starting with `/` and index `1`), recursively trying both hyphen-join (`cur_path-next_part`) and slash-join (`cur_path/next_part`).
  4. To avoid double slashes at the root (e.g. `//tmp/...`), skip index `1` if the first split element is empty.

## 3. Universal Shell Framework Integration
- Maintain entrypoint loader files at the root of the repository to support all major shells and plugin managers:
  - `agent-history.plugin.zsh` for OMZ, Antidote, Zinit, Zim, Zplug (Zsh)
  - `agent-history.plugin.sh` for Oh My Bash, Bash-it (Bash)
  - `conf.d/agent-history.fish` for Fisher, OMF (Fish)
- When resolving paths from Fish configuration scripts (loaded by Fisher), use `status current-filename` combined with `realpath` to handle symlinks correctly.
