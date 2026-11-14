# Agent Setup Guide

Complete installation instructions for each supported AI coding agent.

---

## Quick Start (All Agents)

Run the universal installer:
```bash
# Windows (PowerShell)
irm https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.ps1 | iex

# Linux/macOS/WSL (Bash)
curl -fsSL https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.sh | bash
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
| openSUSE | `sudo zypper install aria2` |

### Install Git
| Platform | Command |
|----------|---------|
| Windows | `winget install Git.Git` |
| macOS | `brew install git` |
| Ubuntu/Debian | `sudo apt install git` |
| Fedora | `sudo dnf install git` |
| Arch | `sudo pacman -S git` |

### Verify
```bash
aria2c --version
git --version
```

---

## Supported Agents

| Agent | Config Type | Config Location | Status |
|-------|-------------|-----------------|--------|
| **OpenCode** | Skill | `~/.config/opencode/skill/fast-download/` | ✅ |
| **Claude Code** | Agent | `~/.claude/agents/fast-download.md` | ✅ |
| **GitHub Copilot (VS Code)** | Extension/Skill | `~/.vscode/extensions/fast-download/` | ✅ |
| **Cursor** | Extension/Skill | `~/.cursor/extensions/fast-download/` | ✅ |
| **Windsurf** | Extension/Skill | `~/.windsurf/extensions/fast-download/` | ✅ |
| **OpenAI Codex** | Agent | `~/.codex/agents/fast-download.md` | ✅ |
| **Continue** | Agent | `~/.continue/agents/fast-download.yaml` | ✅ |
| **Cline** | Skill | `~/.cline/skills/fast-download/` | ✅ |
| **JetBrains AI** | Agent | `~/.config/JetBrains/ai/agents/fast-download.md` | ✅ |
| **Amazon Q Developer** | Agent | `~/.aws/amazonq/agents/fast-download.md` | ✅ |
| **Warp** | Agent | `~/.warp/agents/fast-download.yaml` | ✅ |
| **Universal Shell** | Library | `~/.fast-download/fast-download.sh` | ✅ |

### Not Yet Supported (No Public API)
- Google Jules / Gemini Code Assist
- Replit Agent
- Tabnine
- Mistral Vibe
- Kilo Code
- Devin
- Pi

---

## Installation Methods

### Method 1: Universal Installer (Recommended)

#### Windows (PowerShell)
```powershell
# Install everything
irm https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.ps1 | iex

# Install specific agents only
irm https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.ps1 | iex -Agent opencode,claude-code,vscode

# Skip certain components
irm https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.ps1 | iex -SkipAria2 -SkipGitConfig
```

#### Linux/macOS/WSL (Bash)
```bash
# Install everything
curl -fsSL https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.sh | bash

# Install specific agents only
curl -fsSL https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.sh | bash -s -- opencode claude-code vscode

# Skip certain components
SKIP_ARIA2=true SKIP_GIT_CONFIG=true curl -fsSL https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/install.sh | bash
```

### Method 2: Package Managers

```bash
# Homebrew (macOS/Linux)
brew install AbdullahAlHadi/tap/fast-download

# Chocolatey (Windows)
choco install fast-download

# Winget (Windows)
winget install AbdullahAlHadi.fast-download

# Scoop (Windows)
scoop bucket add fast-download https://github.com/AbdullahAlHadi/fast-download
scoop install fast-download

# AUR (Arch Linux)
yay -S fast-download

# npm (any platform)
npx fast-download
```

### Method 3: Manual Installation

#### OpenCode
```bash
# Copy skill folder
mkdir -p ~/.config/opencode/skill/fast-download
cp -r opencode/* ~/.config/opencode/skill/fast-download/

# Restart OpenCode
```

#### Claude Code
```bash
# Copy agent file
mkdir -p ~/.claude/agents
cp claude-code/fast-download.md ~/.claude/agents/fast-download.md

# Use in chat: /agent fast-download
```

#### GitHub Copilot / Cursor / Windsurf (VS Code)
```bash
# Copy extension folder
mkdir -p ~/.vscode/extensions/fast-download
cp -r vscode/fast-download/* ~/.vscode/extensions/fast-download/

# Reload VS Code: Ctrl+Shift+P → Developer: Reload Window
# Run tasks: Terminal → Run Task → fast-download: aria2
```

#### OpenAI Codex
```bash
# Copy agent file
mkdir -p ~/.codex/agents
cp codex/fast-download.md ~/.codex/agents/fast-download.md

# Restart Codex
```

#### Continue
```bash
# Copy agent file
mkdir -p ~/.continue/agents
cp continue/fast-download.yaml ~/.continue/agents/fast-download.yaml

# Add to ~/.continue/config.yaml:
# agents:
#   - name: fast-download
#     file: ~/.continue/agents/fast-download.yaml

# Restart Continue
```

#### Cline
```bash
# Copy skill folder
mkdir -p ~/.cline/skills/fast-download
cp -r cline/fast-download/* ~/.cline/skills/fast-download/

# In Cline: Skills → fast-download → Enable
```

#### JetBrains AI
```bash
# Copy agent file
mkdir -p ~/.config/JetBrains/ai/agents
cp claude-code/fast-download.md ~/.config/JetBrains/ai/agents/fast-download.md

# Settings → AI Assistant → Agents → fast-download
```

#### Amazon Q Developer
```bash
# Copy agent file
mkdir -p ~/.aws/amazonq/agents
cp claude-code/fast-download.md ~/.aws/amazonq/agents/fast-download.md

# CLI: amazonq agent install
```

#### Warp
```bash
# Copy agent file
mkdir -p ~/.warp/agents
cp continue/fast-download.yaml ~/.warp/agents/fast-download.yaml

# Settings → AI → Agents
```

---

## Universal Shell (Any Terminal)

### Install
```bash
# Copy the shell libraries
mkdir -p ~/.fast-download
cp src/fast-download.sh ~/.fast-download/
cp src/fast-download.fish ~/.fast-download/
cp src/fast-download.nu ~/.fast-download/

# Add to shell RC
# Bash
echo 'source ~/.fast-download/fast-download.sh' >> ~/.bashrc

# Zsh
echo 'source ~/.fast-download/fast-download.sh' >> ~/.zshrc

# Fish
echo 'source ~/.fast-download/fast-download.fish' >> ~/.config/fish/config.fish

# Nushell
echo 'source ~/.fast-download/fast-download.nu' >> ~/.config/nushell/config.nu

# Reload
source ~/.bashrc  # or ~/.zshrc, etc.
```

### Usage
```bash
# After sourcing, these functions are available:
fd_download "https://example.com/file.zip" "~/Downloads/file.zip" "sha256:abc123..."
fd_git_clone "https://github.com/user/repo.git" "~/Projects/repo" true
fd_verify "file.zip" "abc123..."
fd_speed_test
fd_init  # Apply git/npm/pip optimizations
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

# Cursor
rm -rf ~/.cursor/extensions/fast-download

# Windsurf
rm -rf ~/.windsurf/extensions/fast-download

# JetBrains AI
rm ~/.config/JetBrains/ai/agents/fast-download.md

# Amazon Q
rm ~/.aws/amazonq/agents/fast-download.md

# Warp
rm ~/.warp/agents/fast-download.yaml

# Shell
rm -rf ~/.fast-download
# Remove from .bashrc/.zshrc/.config/fish/config.fish
```

### Full Uninstall (Windows)
```powershell
.\scripts\uninstall.ps1

# With config revert
.\scripts\uninstall.ps1 -RevertConfigs
```

### Full Uninstall (Unix)
```bash
./scripts/uninstall.sh

# With config revert
REVERT_CONFIGS=true ./scripts/uninstall.sh
```