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

## 5. Subprocess Avoidance & In-Memory Preloading
- To achieve optimal shell startup performance, avoid executing any external commands/forks (like `jq`, `tail`, `grep`, `sed`, `sqlite3`) inside loops.
- Preload configuration and manifest files (such as `history.jsonl`) into global Bash dynamic variables (`_HISTORY_WS_<key>`) on demand or at startup using pure-Bash `while read` constructs, `printf -v`, and indirect expansion (`${!var}`). Avoid `declare -A` (associative arrays) to maintain compatibility with default macOS Bash 3.2. This converts loop database lookups into in-memory microsecond operations with zero process forks.
- Avoid command substitution (`$()`) inside loops. Use in-process resolver functions (`_resolve_*`) that assign to global variables (`_RESOLVED_*`) to eliminate subshell process fork overhead.
- For home directory path display, use `${ws/#$HOME/~}` (un-escaped tilde) to avoid literal backslashes in display paths.
- Ensure consolidated `find` queries exclude temporary, cache, backup, and plugin directories (e.g., `! -path "*/.tmp/*"`, `! -path "*/plugins/*"`, `! -path "*/cache/*"`, `! -path "*/backups/*"`, `! -name "rollout-*.jsonl"`) to keep file matching lists clean and prevent config files from flooding results.

## 6. Version Release & Bump Management
- Whenever releasing a new version or creating a tag, ensure the version string (e.g. `1.2.1`) is updated in the following 4 files:
  1. `agent-history` (the version comment `# Version: X.Y.Z` at the top and the `-v|--version` flag output block inside `main()`).
  2. `agent-history.plugin.zsh` (the version comment `# Version: X.Y.Z` at the top).
  3. `agent-history.plugin.sh` (the version comment `# Version: X.Y.Z` at the top).
  4. `tests/test_parser.sh` (the assertion checks inside `test_version_flag()`).
- Ensure release versions never default to running in dev mode (`AGENT_HISTORY_DEV=0` / disabled by default).
- For non-interactive git commit/tag sessions on `ubuntu-dev`, pass `--no-gpg-sign` to avoid 1Password Touch ID prompt timeouts.

## 7. Repository Hygiene & README Minimalism
- **Minimal Documentation**: Keep `README.md` clean, focused, and uncluttered. Do not add repository watch/star nudges or built-in auto-update prompts; OMZ plugin users should update via standard Oh My Zsh workflows (`omz pr update` or git pull).
- **External Assets**: Do not commit binary social cards or preview assets directly into the repository git tree. Keep rendered preview cards in user space (e.g. `~/<repo>-social-card.png`) and upload them via GitHub repository settings.

## 8. Social Preview Card Design & Feed Downscaling
- **Feed Downscaling Physics**: Social platforms (like LinkedIn's `articleshare-shrink_480` and mobile feeds) frequently downscale 1280×640 images to 480×240px and display them on Retina/HiDPI screens.
- **Typography Scale**: Never use dense, full-height terminal session dumps (7+ lines of ~12-14px font). Instead, design high-impact terminal cards with 2–3 punchy lines and large typography (20px+ at 1280×640) so character widths remain at least 8–10px in 480px thumbnails.
- **Supersampling**: Render at 2x resolution (2560×1280) and downscale to exact 1280×640px via Lanczos filtering for clean sub-pixel anti-aliasing while keeping file sizes comfortably below GitHub's 1 MB limit (~300–400 KB).
