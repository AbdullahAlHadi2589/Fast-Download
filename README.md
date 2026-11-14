# fast-download

> **Universal download accelerator for AI coding agents** — aria2-powered multi-connection downloads, Git shallow clones, checksum verification, and smart fallbacks. Works with OpenCode, Claude Code, Codex, Continue, Cline, VS Code, and any shell.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](https://github.com/yourusername/fast-download)
[![Download: aria2](https://img.shields.io/badge/Powered%20by-aria2-green)](https://aria2.github.io/)

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

### One-liner (PowerShell)
```powershell
irm https://raw.githubusercontent.com/yourusername/fast-download/main/scripts/install.ps1 | iex
```

### One-liner (Bash/WSL/macOS/Linux)
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/fast-download/main/scripts/install.sh | bash
```

### Manual
1. Install aria2: `winget install aria2.aria2` / `brew install aria2` / `apt install aria2`
2. Copy the agent config for your tool (see below)
3. Restart your agent

---

## Supported Agents

| Agent | Config Location | Install Method |
|-------|----------------|----------------|
| **OpenCode** | `~/.config/opencode/skill/fast-download/` | Auto-discovered |
| **Claude Code** | `~/.claude/agents/fast-download.md` | `--agent` flag |
| **Codex** | `~/.codex/agents/fast-download.md` | Auto-loaded |
| **Continue** | `~/.continue/agents/fast-download.yaml` | Config YAML |
| **Cline** | `~/.cline/skills/fast-download/` | Skill folder |
| **VS Code (Copilot)** | `.vscode/fast-download/` | Workspace skill |
| **Any Shell** | `~/.fast-download/` | Source `fast-download.sh` |

---

## Usage

After install, just use these patterns in **any terminal**:

### Download large files (HTTP/HTTPS)
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

# Full clone (when history needed)
git clone https://github.com/user/repo.git

# Specific branch, shallow
git clone --depth 1 --branch main https://github.com/user/repo.git
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
│  ├── YES → git clone --depth 1 (shallow)                   │
│  └── NO  → Continue                                         │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│  File > 10MB AND server supports Range requests?           │
│  ├── YES → aria2 -x 16 -s 16 (16 parallel connections)    │
│  ├── NO (rate-limited) → aria2 -x 4 -s 4 OR curl -C -     │
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
├── .github/workflows/       # CI/CD for testing & releases
├── opencode/                # OpenCode skill (auto-discovered)
│   ├── skill.json
│   ├── instructions.md
│   ├── FastDownload.psm1
│   └── test-skill.ps1
├── claude-code/             # Claude Code agent
│   └── fast-download.md
├── codex/                   # OpenAI Codex agent
│   └── fast-download.md
├── continue/                # Continue.dev agent
│   └── fast-download.yaml
├── cline/                   # Cline skill
│   └── fast-download/
├── vscode/                  # VS Code Copilot skill
│   └── fast-download/
├── scripts/
│   ├── install.ps1          # Windows installer
│   ├── install.sh           # Unix installer
│   └── uninstall.ps1
├── docs/
│   ├── PERFORMANCE_REPORT.md
│   └── AGENT_SETUP.md
├── src/
│   └── fast-download.sh     # Universal shell library
├── LICENSE
├── package.json             # For npm publishing
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

1. Fork the repo
2. Create feature branch: `git checkout -b feature/amazing`
3. Test with: `./scripts/test-all-agents.sh`
4. Submit PR

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Credits

- [aria2](https://aria2.github.io/) — The download accelerator that makes this possible
- [Git](https://git-scm.com/) — Shallow clone optimization
- All the AI agent platforms for extensibility

---

**Made for developers who want their 100% internet speed, everywhere.**