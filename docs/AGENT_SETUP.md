# Agent Setup Guide

Complete installation instructions for each supported AI coding agent.

---

## Quick Start (All Agents)

Run the universal installer:
```bash
# Windows (PowerShell)
irm https://raw.githubusercontent.com/yourusername/fast-download/main/scripts/install.ps1 | iex

# Linux/macOS/WSL (Bash)
curl -fsSL https://raw.githubusercontent.com/yourusername/fast-download/main/scripts/install.sh | bash
```

Or install manually per agent below.

---

## Prerequisites (All Platforms)

### Install aria2
| Platform | Command |
|----------|---------|
| Windows | `winget install aria2.aria2` |
| macOS | `brew install aria2` |
| Ubuntu/Debian | `sudo apt install aria2` |
| Fedora | `sudo dnf install aria2` |
| Arch | `sudo pacman -S aria2` |

### Install Git
| Platform | Command |
|----------|---------|
| Windows | `winget install Git.Git` |
| macOS | `brew install git` |
| Ubuntu/Debian | `sudo apt install git` |

### Verify
```bash
aria2c --version
git --version
```

---

## OpenCode

### Auto-install (Recommended)
```powershell
# Run installer with OpenCode only
.\scripts\install.ps1 -Agent opencode
```

### Manual Install
1. Copy `opencode/` folder to OpenCode skill directory:
   - **Windows**: `%APPDATA%\opencode\skill\fast-download\`
   - **Linux/macOS**: `~/.config/opencode/skill/fast-download/`

2. Restart OpenCode

### Verify
In OpenCode shell:
```bash
aria2c -x 16 -s 16 -o test.zip "https://example.com/file.zip"
```

---

## Claude Code

### Auto-install
```bash
./scripts/install.sh claude-code
```

### Manual Install
1. Copy `claude-code/fast-download.md` to:
   - **All platforms**: `~/.claude/agents/fast-download.md`

2. Use in Claude Code:
   ```bash
   # In Claude Code chat
   /agent fast-download
   ```

### Verify
Agent appears in `/agent` list.

---

## Codex (OpenAI)

### Auto-install
```bash
./scripts/install.sh codex
```

### Manual Install
1. Copy `codex/fast-download.md` to:
   - **All platforms**: `~/.codex/agents/fast-download.md`

2. Restart Codex

### Verify
Agent auto-loads for download tasks.

---

## Continue.dev

### Auto-install
```bash
./scripts/install.sh continue
```

### Manual Install
1. Copy `continue/fast-download.yaml` to:
   - **All platforms**: `~/.continue/agents/fast-download.yaml`

2. Add to `~/.continue/config.yaml`:
   ```yaml
   agents:
     - name: fast-download
       file: ~/.continue/agents/fast-download.yaml
   ```

3. Restart Continue

### Verify
Agent appears in Continue sidebar.

---

## Cline

### Auto-install
```bash
./scripts/install.sh cline
```

### Manual Install
1. Copy `cline/fast-download/` folder to:
   - **Windows**: `%USERPROFILE%\.cline\skills\fast-download\`
   - **Linux/macOS**: `~/.cline/skills/fast-download/`

2. In Cline: Skills → fast-download → Enable

### Verify
Skill appears in Cline skills panel.

---

## VS Code (GitHub Copilot)

### Auto-install
```powershell
.\scripts\install.ps1 -Agent vscode
```

### Manual Install
1. Copy `vscode/fast-download/` to:
   - **Windows**: `%USERPROFILE%\.vscode\extensions\fast-download\`
   - **Linux/macOS**: `~/.vscode/extensions/fast-download/`

2. Reload VS Code (Ctrl+Shift+P → Developer: Reload Window)

### Verify
Run tasks: Terminal → Run Task → `fast-download: aria2`

---

## Universal Shell (Any Terminal)

### Install
```bash
# Copy the shell library
mkdir -p ~/.fast-download
cp src/fast-download.sh ~/.fast-download/

# Add to shell RC
echo 'source ~/.fast-download/fast-download.sh' >> ~/.bashrc  # or .zshrc

# Reload
source ~/.bashrc
```

### Usage
```bash
# After sourcing, these functions are available:
fd_download "https://example.com/file.zip" "~/Downloads/file.zip" "sha256:abc123..."
fd_git_clone "https://github.com/user/repo.git" "~/Projects/repo" true
fd_verify "file.zip" "abc123..."
fd_speed_test
```

---

## PowerShell (Windows)

### Install
```powershell
# Copy module
mkdir -Force ~/.fast-download
cp opencode/FastDownload.psm1 ~/.fast-download/

# Import in profile
Add-Content $PROFILE 'Import-Module ~/.fast-download/FastDownload.psm1'

# Reload
. $PROFILE
```

### Usage
```powershell
Invoke-FastDownload -Url "https://example.com/file.zip" -OutputPath "~/Downloads/file.zip"
Invoke-GitClone -Url "https://github.com/user/repo.git" -OutputPath "~/Projects/repo" -Shallow
Test-FileChecksum -FilePath "file.zip" -ExpectedHash "abc123..."
Measure-DownloadSpeed
```

---

## Configuration Reference

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `FD_ARIA2_CONNECTIONS` | 16 | Parallel connections for aria2 |
| `FD_ARIA2_SPLIT` | 16 | Number of splits |
| `FD_ARIA2_MIN_SPLIT_SIZE` | 1M | Minimum split size |
| `FD_CURL_RETRIES` | 5 | curl retry count |
| `FD_CURL_RETRY_DELAY` | 3 | curl retry delay (seconds) |
| `FD_GIT_SHALLOW` | true | Default to shallow clones |

### Git Config (Auto-applied)
```bash
git config --global core.compression 9
git config --global core.preloadIndex true
git config --global core.fscache true
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
```

### npm Config (Auto-applied)
```bash
npm config set fetch-retries 5
npm config set fetch-retry-factor 2
npm config set prefer-offline true
```

### pip Config (Auto-applied)
```bash
pip config set global.retries 5
pip config set global.timeout 60
```

---

## Troubleshooting

### Agent not loading
1. Check file location matches exactly
2. Restart the agent/IDE
3. Check agent logs for errors

### aria2 not found
```bash
# Refresh PATH
# Windows
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Unix
source ~/.bashrc  # or ~/.zshrc
```

### Permission errors (Linux/macOS)
```bash
chmod +x ~/.fast-download/fast-download.sh
chmod +x ~/scripts/install.sh
```

### Rate limiting (429 errors)
Use 4 connections instead of 16:
```bash
aria2c -x 4 -s 4 -o "file.zip" "https://github.com/.../file.zip"
# Or just use curl
curl -L -C - -o "file.zip" "https://github.com/.../file.zip"
```

---

## Uninstall

### Per Agent
```bash
# OpenCode
rm -rf ~/.config/opencode/skill/fast-download

# Claude Code
rm ~/.claude/agents/fast-download.md

# Codex
rm ~/.codex/agents/fast-download.md

# Continue
rm ~/.continue/agents/fast-download.yaml

# Cline
rm -rf ~/.cline/skills/fast-download

# VS Code
rm -rf ~/.vscode/extensions/fast-download

# Shell
rm -rf ~/.fast-download
# Remove from .bashrc/.zshrc
```

### Full Uninstall (Windows)
```powershell
.\scripts\uninstall.ps1
```

### Full Uninstall (Unix)
```bash
./scripts/uninstall.sh
```