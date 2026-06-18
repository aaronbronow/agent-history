# PowerShell Support Plan

To bring `agent-history` to PowerShell users, running a raw Bash script natively on Windows is going to be a major friction point (requiring WSL or Git Bash). Because PowerShell is fully cross-platform now (running on Windows, macOS, and Linux), the absolute best way to support this crowd is to port the logic into a **native PowerShell Module (`.psm1`)**.

The good news? PowerShell is practically tailor-made for this kind of file-scraping tool, and it will actually require *fewer* lines of code than the Bash version.

Here is the blueprint for making `agent-history` native and available to the PowerShell community:

---

## 1. Why PowerShell is a Great Fit for This Logic

You won't need to mess with brittle `grep`/`sed` or force users to install `jq`. PowerShell treats data as structured objects natively.

* **Native JSON Parsing:** Instead of checking for `jq`, PowerShell has `ConvertFrom-Json` baked right into the core runtime.
```powershell
# Equivalent to your Level 1 / Level 2 JSON parsing:
if (Test-Path "$HOME\.claude\config.json") {
    $config = Get-Content "$HOME\.claude\config.json" | ConvertFrom-Json
    $historyPath = $config.historyDirectory
}
```

*   **Built-in Path Handling:** Dealing with the Pi CLI's hyphenated paths or cross-platform slashes is trivial with `Join-Path` and native string manipulation operators (like `-replace`).
*   **The SQLite Caveat:** Windows doesn't ship with `sqlite3` by default. Your Level 3 fallback logic (using regex to read the raw strings out of Copilot's `session-store.db` binary) will map beautifully to PowerShell's native `-match` and `Select-String` operators.

---

## 2. Structure as a PowerShell Module

To give it that native "plugin" feel (the PowerShell equivalent of an Oh My Zsh plugin), you will bundle it as a module. Your repository structure would look like this:

```text
agent-history/
├── agent-history.psm1   # The core script containing your functions
├── agent-history.psd1   # The module manifest (metadata, author, version)
└── README.md
```

Inside `agent-history.psm1`, you export a primary command like `Get-AgentHistory`. To make it feel fast, you can add an alias at the bottom of the script:

```powershell
Set-Alias -Name agh -Value Get-AgentHistory
```

---

## 3. The Windows Agent Path Nuance

When writing the PowerShell logic, keep in mind that while macOS/Linux users keep everything in `$HOME`, Windows agent CLIs usually default to the Windows user profile directory (`$HOME` or `$env:USERPROFILE`), which mirrors the dotfile structure perfectly (e.g., `C:\Users\Aaron\.gemini\settings.json`).

PowerShell’s `$HOME` variable automatically resolves correctly regardless of whether the user is running Windows, Mac, or Linux.

---

## 4. Distribution: The PowerShell Gallery (PSG)

The gold standard for PowerShell distribution is the **PowerShell Gallery** (the npm/Homebrew equivalent for Windows).

1. Create a free account at [powershellgallery.com](https://www.powershellgallery.com/).
2. Generate an API key.
3. Publish your module straight from your terminal using:
```powershell
Publish-Module -Path ./agent-history -NuGetApiKey "your-api-key"
```

Once published, any developer in the world on Windows, Mac, or Linux can open their PowerShell terminal and install your tool instantly by running:
```powershell
Install-Module -Name agent-history -Scope CurrentUser
```

They can then drop `Import-Module agent-history` into their `$PROFILE` script, and they are good to go.
