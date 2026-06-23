# Manual Verification & Testing Matrix

Use this document to track manual QA checks across different shell environments and operating systems before releasing new versions of `agent-history`. 

Because `agent-history` is implemented as a shell plugin (Zsh/Bash), it is optimized for Unix-based terminals. Windows PowerShell, Fish, and NuShell are out of scope.

---

## 📋 Release Validation Checklist

### 1. Environment & Setup Matrix

| Operating System | Shell | Framework / Setup | Session Type | Status | Verified Version | Notes |
| :--- | :--- | :--- | :--- | :---: | :--- | :--- |
| **macOS** | Zsh | Oh My Zsh | Local | `[ ]` | | |
| **macOS** | Zsh | Oh My Zsh | SSH | `[ ]` | | |
| **macOS** | Zsh | Generic / Sourced | Local | `[ ]` | | |
| **Linux (Ubuntu)** | Zsh | Oh My Zsh | Local | `[ ]` | | |
| **Linux (Ubuntu)** | Zsh | Oh My Zsh | SSH | `[ ]` | | |
| **Linux (Ubuntu)** | Zsh | Generic / Sourced | Local | `[ ]` | | |
| **Linux (Ubuntu)** | Bash | Generic / Sourced | Local | `[ ]` | | |
| **Linux (Ubuntu)** | Bash | Generic / Sourced | SSH | `[ ]` | | |

---

### 2. Functional Test Checklist

Complete these verification steps inside each tested environment:

- [ ] **Installation/Update (`install.sh`)**
  - Run the `curl` installer on a fresh environment.
  - Verify loader block is added to `~/.zshrc` or `~/.bashrc` (if not using Oh My Zsh).
- [ ] **Basic Dashboard (`ah` / `agent-history`)**
  - Verify the list of recent coding sessions is printed correctly.
  - Ensure the output displays the active Git branch in parentheses (e.g. `(main)`).
  - Verify that relative time intervals are correctly computed (e.g., `(23h ago)`).
- [ ] **Navigation Command (`ah <num>`)**
  - Run `ah 1` to `ah 5` and verify that the shell changes directory (`cd`) to the selected workspace path.
  - Test calling `ah` with an invalid index (e.g., `ah 99` or `ah abc`) and confirm it prints an error message without changing the directory.
- [ ] **Adaptive Layout & Path Shrinking**
  - Resize the terminal to a narrow width (e.g., 60 columns).
  - Run `ah` and verify that intermediate directory paths shrink correctly (e.g., `~/dev/scratch/job` becomes `~/d/s/job`) to fit the terminal width without wrapping lines.
- [ ] **SSH Auto-run Behavior**
  - Establish an SSH connection to the machine.
  - Verify the agent-history dashboard prints automatically upon login.
  - **Zsh/P10k Specific:** Confirm that no Powerlevel10k instant prompt warnings or prompt-pause errors occur during login.
- [ ] **Performance Validation**
  - Run the profiling script to check latency:
    ```bash
    ./tests/profile.sh
    ```
  - Verify total execution time is under **200ms**.

---

## 📝 Verification Logs

Record your test results here before tagging a release:

### Version v1.0.0 (2026-06-22)
* **Status**: Passed unit tests and profiling benchmarks.
* **Verified by**: @aaronbronow
* **Notes**: Tested locally on development VM under Ubuntu with Zsh (Oh My Zsh).
