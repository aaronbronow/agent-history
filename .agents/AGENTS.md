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

## 3. Scope & Development Philosophy (Open-Minded but Opinionated)
- Focus effort on delivering a high-quality, fully optimized implementation for Zsh (the developer's primary shell) and generic Bash.
- Avoid half-assing or maintaining unverified integrations for environments we do not use (e.g. Fish, PowerShell, NuShell).
- Intentionally leave gaps and layout pointers in the documentation (`README.md`) to encourage open-source contributions and ports for other shells.

## 4. Performance & Profiling Constraints
- Maintain the performance target of under 200ms total execution time to keep shell login completely lag-free.
- Avoid spawning process forks (like `cat`, `jq`, `sqlite3`, `xargs`, `dirname`, `head`) inside loop constructs. Use Bash built-in parameter expansions, file redirection (`$(< file)`), and cache capability checks (`hash jq`) where possible.
- Use a single consolidated `find` query across all paths instead of running separate search processes per path. Keep the query fast by targeting specific subdirectories (e.g. `~/.gemini/antigravity-cli` instead of the root of `~/.gemini`) and excluding system paths like `*/.system_generated/*`.
- Run the [profile.sh](file:///home/aaron/dev/agent-history/tests/profile.sh) tool to measure execution times and trace parser counts whenever you add or modify project/database parsers.
