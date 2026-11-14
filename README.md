# Fast-Download

<div align="center">
  <img src="assets/logo.png" alt="fast-download logo" width="50%">
</div>

> **Universal download accelerator for AI coding agents** — aria2-powered multi-connection downloads, Git shallow clones, checksum verification, and smart fallbacks. Works with OpenCode, Claude Code, Codex, Continue, Cline, VS Code, Cursor, Windsurf, JetBrains AI, Amazon Q, Warp, and any shell.

[![License](https://img.shields.io/badge/License-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](https://github.com/AbdullahAlHadi2589/Fast-Download)
[![Download: aria2](https://img.shields.io/badge/Powered%20by-aria2-green)](https://aria2.github.io/)
[![Build Status](https://img.shields.io/github/actions/workflow/status/AbdullahAlHadi2589/Fast-Download/ci.yml?branch=master&logo=github)](https://github.com/AbdullahAlHadi2589/Fast-Download/actions)
[![Release](https://img.shields.io/github/v/release/AbdullahAlHadi2589/Fast-Download?logo=github)](https://github.com/AbdullahAlHadi2589/Fast-Download/releases)
[![Downloads](https://img.shields.io/github/downloads/AbdullahAlHadi2589/Fast-Download/total?logo=github)](https://github.com/AbdullahAlHadi2589/Fast-Download/releases)
[![Stars](https://img.shields.io/github/stars/AbdullahAlHadi2589/Fast-Download?style=social)](https://github.com/AbdullahAlHadi2589/Fast-Download/stargazers)
[![Forks](https://img.shields.io/github/forks/AbdullahAlHadi2589/Fast-Download?style=social)](https://github.com/AbdullahAlHadi2589/Fast-Download/network)
[![Issues](https://img.shields.io/github/issues/AbdullahAlHadi2589/Fast-Download)](https://github.com/AbdullahAlHadi2589/Fast-Download/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/AbdullahAlHadi2589/Fast-Download/blob/master/CONTRIBUTING.md)
[![Code Size](https://img.shields.io/github/languages/code-size/AbdullahAlHadi2589/Fast-Download)](https://github.com/AbdullahAlHadi2589/Fast-Download)
[![Top Language](https://img.shields.io/github/languages/top/AbdullahAlHadi2589/Fast-Download)](https://github.com/AbdullahAlHadi2589/Fast-Download)
[![Last Commit](https://img.shields.io/github/last-commit/AbdullahAlHadi2589/Fast-Download)](https://github.com/AbdullahAlHadi2589/Fast-Download/commits/master)

---

## The Problem

Your internet is fast. Your AI agent's downloads are slow.

| Tool | Default Behavior | Result |
|------|-----------------|--------|
| `curl` | Single connection | ~5 MB/s on 100+ MB/s line |
| `git clone` | Full history | 10x bandwidth waste |
| `npm/pip` | No retry tuning | Flaky on large packages |
| Interrupted download | Manual restart | Waste time & bandwidth |

---

## The Solution

**One skill, every agent, maximum speed.**

```
┌────────────────────────────────────────────────────────────┐
│  fast-download                                             │
├────────────────────────────────────────────────────────────┤
│  ▸ aria2: 16 parallel connections, auto-resume, checksums  │
│  ▸ Git: --depth=1 --filter=blob:none (90% less data)       │
│  ▸ Fallback: curl with resume when servers rate-limit      │
│  ▸ Verification: Built-in SHA256/MD5 validation            │
│  ▸ Config: Optimized git/npm/pip defaults                  │
└────────────────────────────────────────────────────────────┘
```

### Benchmarks (Windows 11, 1 Gbps line)

| Scenario | Before | After | Improvement |
|----------|--------|-------|-------------|
| Large file (CDN) | 5 MB/s | **39 MB/s** | **7.8×** |
| GitHub release (2.4 MB) | 2.6 MB/s | 2.5 MB/s | Server-limited |
| Git clone (full) | 43.6s | 43.6s | When needed |
| Git clone (shallow) | N/A | **10.6s** | **New: 4.1× faster** |
| Resume interrupted | Manual | **Automatic** | ✨ UX |

---

## Quick Install

### One-liner (PowerShell) — Windows
```powershell
irm https://raw.githubusercontent.com/AbdullahAlHadi2589/Fast-Download/master/scripts/install.ps1 | iex
```

### One-liner (Bash) — Linux/macOS/WSL
```bash
curl -fsSL https://raw.githubusercontent.com/AbdullahAlHadi2589/Fast-Download/master/scripts/install.sh | bash
```

### Quick Agent Install
**Easiest way:** Copy the one-liner above and paste it into your AI coding agent (OpenCode, Claude Code, Cursor, etc.) — it will handle the installation automatically.

### Manual
1. Install aria2: `winget install aria2.aria2` / `brew install aria2` / `apt install aria2`
2. Copy the agent config for your tool (see below)
3. Restart your agent

---

## Supported Agents

| Agent | Config Location | Install Method | Status |
|-------|----------------|----------------|--------|
| **OpenCode** | `~/.config/opencode/skill/fast-download/` | Auto-discovered | ✅ |
| **Claude Code** | `~/.claude/agents/fast-download.md` | `--agent` flag | ✅ |
| **GitHub Copilot (VS Code)** | `~/.vscode/extensions/fast-download/` | Workspace skill | ✅ |
| **Cursor** | `~/.cursor/extensions/fast-download/` | Same as VS Code | ✅ |
| **Windsurf** | `~/.windsurf/extensions/fast-download/` | Same as VS Code | ✅ |
| **OpenAI Codex** | `~/.codex/agents/fast-download.md` | Auto-loaded | ✅ |
| **Continue** | `~/.continue/agents/fast-download.yaml` | Config YAML | ✅ |
| **Cline** | `~/.cline/skills/fast-download/` | Skill folder | ✅ |
| **JetBrains AI** | `~/.config/JetBrains/ai/agents/fast-download.md` | Settings → AI Assistant | ✅ |
| **Amazon Q Developer** | `~/.aws/amazonq/agents/fast-download.md` | CLI: `amazonq agent install` | ✅ |
| **Warp** | `~/.warp/agents/fast-download.yaml` | Settings → AI → Agents | ✅ |
| **Any Shell** | `~/.fast-download/` | Source `fast-download.sh` | ✅ |
| **Google Jules** | *Not yet supported* | No public API | 🔄 |
| **Gemini Code Assist** | *Not yet supported* | No public API | 🔄 |
| **Replit Agent** | *Not yet supported* | No public API | 🔄 |
| **Tabnine** | *Not yet supported* | No public API | 🔄 |
| **Mistral Vibe** | *Not yet supported* | No public API | 🔄 |
| **Kilo Code** | *Not yet supported* | No public API | 🔄 |
| **Devin** | *Not yet supported* | No public API | 🔄 |
| **Pi** | *Not yet supported* | No public API | 🔄 |

---

## Usage

After install, just use these patterns in **any terminal**:

### Download large files (HTTP/HTTPS/FTP)
```bash
# Preferred: aria2 with 16 connections, resume, verification
aria2c -x 16 -s 16 -k 1M --continue=true -o "file.zip" "https://example.com/file.zip"

# With SHA256 verification
aria2c --checksum=sha256=abc123... -x 16 -s 16 -o "file.zip" "https://example.com/file.zip"

# Rate-limited servers (GitHub, proof.ovh.net) - use 4 connections
aria2c -x 4 -s 4 -k 1M --continue=true -o "file.zip" "https://github.com/.../file.zip"

# Fallback: curl with resume
curl -L -C - -o "file.zip" "https://example.com/file.zip"
```

### Clone Git repositories
```bash
# Shallow clone (preferred - 90% less data, 4× faster)
git clone --depth 1 --single-branch --filter=blob:none https://github.com/user/repo.git

# Full clone (when history required)
git clone https://github.com/user/repo.git

# Specific branch, shallow
git clone --depth 1 --branch master https://github.com/user/repo.git
```

### PowerShell Module (Windows)
```powershell
Import-Module "~/.fast-download/FastDownload.psm1"

# Smart download (auto-selects aria2/curl)
Invoke-FastDownload -Url "https://example.com/large.zip" -OutputPath "C:\Downloads\large.zip"

# Git clone with options
Invoke-GitClone -Url "https://github.com/user/repo.git" -OutputPath "C:\Projects\repo" -Shallow

# Verify checksum
Test-FileChecksum -FilePath "file.zip" -ExpectedHash "abc123..." -Algorithm SHA256
```

### Universal Shell Library (Any POSIX Shell)
```bash
# Source once
source ~/.fast-download/fast-download.sh

# Then use:
fd_download "https://example.com/file.zip" "~/Downloads/file.zip" "sha256:abc123..."
fd_git_clone "https://github.com/user/repo.git" "~/Projects/repo" true
fd_verify "file.zip" "abc123..."
fd_speed_test
fd_init  # Apply git/npm/pip optimizations
```

---

## How It Works

### Smart Tool Selection
```
┌────────────────────────────────────────────────────────────┐
│                    DOWNLOAD REQUEST                        │
└────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌────────────────────────────────────────────────────────────┐
│  Is it a Git URL?                                          │
│  ├── YES → git clone --depth 1 --filter=blob:none          │
│  └── NO  → Continue                                        │
└────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌────────────────────────────────────────────────────────────┐
│  File > 10MB AND server supports Range requests?           │
│  ├── YES → aria2c -x 16 -s 16 (16 parallel connections)    │
│  ├── NO (rate-limited) → aria2c -x 4 -s 4 OR curl -C -     │
│  └── NO (small/unknown) → curl (lower overhead)            │
└────────────────────────────────────────────────────────────┘
```

### Built-in Verification
- **SHA256/MD5** checksums validated automatically after every download
- **Corrupted files deleted** on mismatch — no partial files left behind
- **Resume support** via `curl -C -` and aria2's built-in continuation

### Global Config Optimizations (Opt-in)
```bash
# Git: compression, larger buffers, no low-speed timeouts
git config --global core.compression 9
git config --global http.postBuffer 524288000

# npm: retries, offline preference
npm config set fetch-retries 5
npm config set prefer-offline true

# pip: retries, timeout
pip config set global.retries 5
pip config set global.timeout 60
```

> **Note:** Global configs require explicit opt-in (`APPLY_GLOBAL_CONFIGS=true` / `-ApplyGlobalConfigs`)

---

## 📁 Project Structure

```
fast-download/
├── src/
│   ├── fast-download.sh        # Universal Bash library
│   ├── fast-download.fish      # Fish shell library
│   └── fast-download.nu        # Nushell library
├── opencode/
│   ├── FastDownload.psm1       # PowerShell module
│   ├── skill.json              # OpenCode skill manifest
│   └── instructions.md         # Agent instructions
├── claude-code/
│   └── fast-download.md        # Claude Code agent
├── codex/
│   └── fast-download.md        # OpenAI Codex agent
├── continue/
│   └── fast-download.yaml      # Continue.dev agent
├── cline/
│   └── fast-download/          # Cline skill
├── vscode/
│   └── fast-download/          # VS Code / Cursor / Windsurf
├── jetbrains/
│   └── fast-download.md        # JetBrains AI agent
├── amazon-q/
│   └── fast-download.md        # Amazon Q agent
├── warp/
│   └── fast-download.yaml      # Warp agent
├── scripts/
│   ├── install.sh              # Bash installer (Linux/macOS/WSL)
│   ├── install.ps1             # PowerShell installer (Windows)
│   ├── uninstall.sh            # Uninstaller
│   └── test.sh                 # Test suite (40+ tests)
├── packaging/
│   └── aur/                    # Arch Linux AUR package
├── docs/
│   ├── AGENT_SETUP.md          # Detailed agent setup guide
│   └── PERFORMANCE_REPORT.md   # Benchmarks & methodology
├── assets/
│   └── logo.png                # Project logo
├── README.md                   # This file
├── LICENSE                     # License
├── CONTRIBUTING.md             # Contribution guide
├── CODE_OF_CONDUCT.md          # Code of conduct
└── CHANGELOG.md                # Version history
```

---

## Requirements

| Platform | Requirements |
|----------|--------------|
| **Windows** | Windows 10/11, PowerShell 5.1+, aria2, Git (optional) |
| **Linux** | Bash 4+, aria2, curl, Git (optional) |
| **macOS** | Bash 4+/zsh/fish, aria2, curl, Git (optional) |
| **WSL** | Same as Linux |

All shell libraries (bash, fish, nushell) and PowerShell module are **dependency-free** — they only call `aria2c`, `curl`, or `git` if available.

---

## Performance

| Metric | Value |
|--------|-------|
| Max parallel connections | 16 (aria2) / 4 (rate-limited) |
| Resume support | ✅ Full (aria2 + curl) |
| Checksum algorithms | SHA256, MD5 |
| Git shallow clone | ✅ `--depth=1 --filter=blob:none` |
| Rate-limit fallback | ✅ Automatic (aria2 → curl) |
| Zero config | ✅ Works out of the box |

See [PERFORMANCE_REPORT.md](docs/PERFORMANCE_REPORT.md) for detailed benchmarks.

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repo
2. Create a feature branch
3. Run tests: `bash scripts/test.sh`
4. Submit PR

---

## License

[License](LICENSE) — see [LICENSE](LICENSE) for details.

**Author:** Abdullah Al Hadi

---

## Credits

- [aria2](https://aria2.github.io/) — The powerful download utility that makes this possible
- [OpenCode](https://opencode.ai/) — For the skill architecture
- All AI coding agent platforms that support extensibility