# fast-download



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

## 🎬 Demo

![fast-download demo](docs/demo.gif)

*Left: `aria2c -x 16` (39 MB/s) — Right: `curl` (5 MB/s) — Same file, same connection*

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
┌─────────────────────────────────────────────────────────────┐
│  fast-download                                              │
├─────────────────────────────────────────────────────────────┤
│  ▸ aria2: 16 parallel connections, auto-resume, checksums  │
│  ▸ Git: --depth=1 --filter=blob:none (90% less data)       │
│  ▸ Fallback: curl with resume when servers rate-limit       │
│  ▸ Verification: Built-in SHA256/MD5 validation            │
│  ▸ Config: Optimized git/npm/pip defaults                  │
└─────────────────────────────────────────────────────────────┘
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
│                    DOWNLOAD REQUEST                         │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│  Is it a Git URL?                                           │
│  ├── YES → git clone --depth 1 --filter=blob:none          │
│  └── NO  → Continue                                         │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│  File > 10MB AND server supports Range requests?           │
│  ├── YES → aria2c -x 16 -s 16 (16 parallel connections)    │
│  ├── NO (rate-limited) → aria2c -x 4 -s 4 OR curl -C -     │
│  └── Small file (<10MB) → curl (lower overhead)            │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│  Verify checksum if provided → Done                         │
└────────────────────────────────────────────────────────────┘
```

### Security First
- ✅ SSL verification **always enabled** (`--check-certificate=true`)
- ✅ Checksum verification **supported** (`--checksum=sha256=<hash>`)
- ✅ No insecure defaults — never disables cert validation for speed
- ✅ Trusted sources only — assumes HTTPS from known hosts

---

## Repository Structure

```
fast-download/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # Cross-platform CI
│   │   └── release.yml         # Automated releases
│   ├── ISSUE_TEMPLATE/         # Bug report, feature request
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── CODEOWNERS
│   └── SECURITY.md
├── src/
│   └── fast-download.sh        # Universal shell library
├── opencode/                   # OpenCode skill
│   ├── skill.json
│   ├── instructions.md
│   ├── FastDownload.psm1
│   ├── test-skill.ps1
│   └── references/download-methods.md
├── claude-code/                # Claude Code agent
│   └── fast-download.md
├── codex/                      # OpenAI Codex agent
│   └── fast-download.md
├── continue/                   # Continue.dev agent
│   └── fast-download.yaml
├── cline/                      # Cline skill
│   ├── skill.json
│   └── instructions.md
├── vscode/                     # VS Code / Cursor / Windsurf
│   └── fast-download/
├── scripts/
│   ├── install.ps1             # Windows installer
│   ├── install.sh              # Unix installer
│   ├── uninstall.ps1           # Windows uninstaller
│   ├── uninstall.sh            # Unix uninstaller
│   ├── test.sh                 # Test suite
│   └── create-demo.sh          # Demo GIF creator
├── packaging/
│   ├── homebrew/               # Homebrew formula
│   ├── chocolatey/             # Chocolatey package
│   ├── winget/                 # Winget manifest
│   ├── scoop/                  # Scoop manifest
│   └── aur/                    # AUR PKGBUILD
├── docs/
│   ├── PERFORMANCE_REPORT.md
│   ├── AGENT_SETUP.md
│   └── demo.gif
├── CONTRIBUTING.md
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── LICENSE
├── package.json
└── README.md
```

---

## Configuration

### Git Optimizations (Applied Automatically)
```bash
git config --global core.compression 9
git config --global core.preloadIndex true
git config --global core.fscache true
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
```

### npm Optimizations
```bash
npm config set fetch-retries 5
npm config set fetch-retry-factor 2
npm config set prefer-offline true
```

### pip Optimizations
```bash
pip config set global.retries 5
pip config set global.timeout 60
```

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `FD_ARIA2_CONNECTIONS` | 16 | Parallel connections for aria2 |
| `FD_ARIA2_SPLIT` | 16 | Number of splits |
| `FD_ARIA2_MIN_SPLIT_SIZE` | 1M | Minimum split size |
| `FD_CURL_RETRIES` | 5 | curl retry count |
| `FD_CURL_RETRY_DELAY` | 3 | curl retry delay (seconds) |
| `FD_GIT_SHALLOW` | true | Default to shallow clones |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `aria2c` not found | Restart shell, or run installer again |
| 429 Too Many Requests | Use `-x 4 -s 4` or `curl -L -C -` |
| Resume not working | Server must support `Accept-Ranges: bytes` |
| Git not in PATH (Windows) | Use full path: `C:\Program Files\Git\bin\git.exe` |
| Slow GitHub downloads | GitHub CDN limits per-connection; use `-x 4` |

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start
```bash
git clone https://github.com/AbdullahAlHadi2589/Fast-Download.git
cd fast-download
# Make your changes
./scripts/test.sh  # Run tests
# Submit PR
```

### Areas for Contribution
- 🐛 Bug fixes
- ✨ New agent integrations
- 📦 Package manager submissions (Homebrew, Chocolatey, Winget, Scoop, AUR)
- 📚 Documentation improvements
- 🧪 Test coverage
- 🎨 Demo GIF updates
- 🌐 Translations

---

## License

[License](LICENSE) — see [LICENSE](LICENSE) for details.

**Author:** Abdullah Al Hadi

---

## Credits

- [aria2](https://aria2.github.io/) — The download accelerator that makes this possible
- [Git](https://git-scm.com/) — Shallow clone optimization
- Contributors: [See GitHub](https://github.com/AbdullahAlHadi2589/Fast-Download/graphs/contributors)

---

## Support

- 🐛 [Report a bug](https://github.com/AbdullahAlHadi2589/Fast-Download/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/AbdullahAlHadi2589/Fast-Download/issues/new?template=feature_request.md)
- 💬 [Discussions](https://github.com/AbdullahAlHadi2589/Fast-Download/discussions)
- ⭐ Star this repo if it helped you!

---

**Made for developers who want their 100% internet speed, everywhere.**
