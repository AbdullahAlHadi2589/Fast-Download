---
name: fast-download
description: Optimized download accelerator using aria2, parallel connections, and smart fallbacks. Universal download skill for all AI coding agents.
version: 1.0.0
author: AbdullahAlHadi2589
license: MIT
repository: https://github.com/AbdullahAlHadi2589/Fast-Download
---

# Fast Download Skill

Universal download accelerator for AI coding agents. Supports OpenCode, Cline, Cursor, VSCode, Windsurf, JetBrains, and more.

## Features

- **aria2 multi-connection downloads** - 16 parallel connections for maximum throughput
- **Git shallow clones** - Save 90%+ bandwidth with `--depth 1 --filter=blob:none`
- **Smart fallbacks** - Automatic fallback to curl with resume capability
- **Checksum verification** - Built-in SHA256 verification support
- **Cross-platform** - Works on Windows, macOS, Linux
- **Security-first** - SSL verification always enabled, no security compromises

## Quick Start

### Download a file (HTTP/HTTPS/FTP)
```bash
# Preferred: aria2 with 16 connections
aria2c -x 16 -s 16 -k 1M --file-allocation=falloc --continue=true -o "output.zip" "https://example.com/file.zip"

# Fallback: curl with resume
curl -L -C - -o "output.zip" "https://example.com/file.zip"
```

### Clone a Git repository
```bash
# Shallow clone (preferred when history not needed)
git clone --depth 1 --single-branch --filter=blob:none https://github.com/user/repo.git

# Full clone (when history required)
git clone https://github.com/user/repo.git
```

### Download with checksum verification
```bash
aria2c --checksum=sha256=<expected_hash> -x 16 -s 16 -o "output.zip" "https://example.com/file.zip"
```

## Tool Selection Logic

| Scenario | Primary Tool | Fallback |
|----------|-------------|----------|
| Files > 10MB with range support | aria2 (16 connections) | curl with resume |
| Files < 10MB or no range support | curl with resume | aria2 (single connection) |
| Git repos (no history needed) | git clone --depth 1 --filter=blob:none | git clone (full) |
| npm/pip/cargo/go packages | Native package managers | — |

## IDE / Agent Integration

| IDE / Agent | Manifest File | Location |
|-------------|--------------|----------|
| **OpenCode** | `SKILL.md` | `opencode/SKILL.md` or repo root |
| **Cline** | `.clinerules` | `cline/fast-download/.clinerules` |
| **Cursor** | `.cursorrules` | `cursor/fast-download/.cursorrules` |
| **VSCode** | `package.json` | `vscode/fast-download/package.json` |
| **Windsurf** | `.windsurfrules` | `windsurf/fast-download/.windsurfrules` |
| **JetBrains** | `plugin.xml` + `fast-download.md` | `jetbrains/` |

## Installation

### OpenCode
```bash
# Copy the opencode folder to your OpenCode skills directory
cp -r opencode ~/.config/opencode/skill/fast-download
```

### Cline
```bash
# Copy .clinerules to your project or global Cline rules
cp cline/fast-download/.clinerules .clinerules
```

### Cursor
```bash
# Copy .cursorrules to your project root
cp cursor/fast-download/.cursorrules .cursorrules
```

### VSCode
```bash
# Install as VSCode extension (when published)
# Or copy vscode/fast-download to your extensions folder
```

### Windsurf
```bash
# Copy .windsurfrules to your project root
cp windsurf/fast-download/.windsurfrules .windsurfrules
```

### JetBrains
```bash
# Install plugin from JetBrains Marketplace (when published)
# Or use the fast-download.md as AI agent instructions
```

## Configuration

### One-time setup (recommended)
```bash
# Git optimizations
git config --global core.compression 9
git config --global core.preloadIndex true
git config --global core.fscache true
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# npm optimizations
npm config set fetch-retries 5
npm config set fetch-retry-factor 2
npm config set prefer-offline true

# pip optimizations
pip config set global.retries 5
pip config set global.timeout 60
```

### Environment variables
```bash
# Ensure aria2 is in PATH
export PATH="$PATH:/usr/local/bin"  # macOS/Linux
# Windows: Add aria2 directory to System PATH
```

## Verification

### Verify SHA256 checksum
```bash
# Linux/macOS
sha256sum file.zip

# PowerShell
Get-FileHash -Algorithm SHA256 file.zip

# Windows CMD
certutil -hashfile file.zip SHA256
```

### Check aria2 installation
```bash
aria2c --version
```

## Performance Expectations

| Scenario | Expected Speed | Notes |
|----------|---------------|-------|
| Large file (CDN) | 50-100+ MB/s | Limited by server/ISP |
| GitHub releases | 10-30 MB/s | Server-side limits |
| Git shallow clone | 5-20 MB/s | Depends on repo size |
| npm/pip packages | Variable | Registry CDN optimized |

## Troubleshooting

### aria2 not found
```bash
# Install aria2
# Windows: choco install aria2 / scoop install aria2
# macOS: brew install aria2
# Linux: apt install aria2 / yum install aria2 / pacman -S aria2
```

### Slow GitHub downloads
- GitHub release assets served from `release-assets.githubusercontent.com`
- aria2 handles redirects automatically
- If rate limited, reduce connections: `-x 4 -s 4`

### Resume not working
- Server must support `Accept-Ranges: bytes`
- Check with: `curl -I <url> | grep Accept-Ranges`
- If not supported, aria2 falls back to single connection

### SSL Certificate Errors
- Never disable certificate verification
- If corporate proxy, configure aria2 with `--proxy-method` and `--all-proxy`
- Use `--ca-certificate` for custom CAs

## License

MIT License - see LICENSE file for details.

## Contributing

See CONTRIBUTING.md for contribution guidelines.

## Changelog

See CHANGELOG.md for version history.