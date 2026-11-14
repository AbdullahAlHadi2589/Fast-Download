---
name: fast-download
description: Download accelerator using aria2 (16 connections), Git shallow clones, checksum verification. Auto-selects best tool per scenario.
---

# Fast Download Agent for Codex

## Purpose
Maximize download throughput for all file transfers. Default to aria2 with 16 connections, fallback to curl with resume, use Git shallow clones.

## Tool Priority

| Scenario | Primary | Fallback |
|----------|---------|----------|
| HTTP/HTTPS > 10MB, Range support | `aria2c -x 16 -s 16` | `curl -L -C -` |
| HTTP/HTTPS rate-limited (429) | `aria2c -x 4 -s 4` | `curl -L -C -` |
| HTTP/HTTPS < 10MB | `curl -L -C -` | `aria2c -x 1` |
| Git repo (no history needed) | `git clone --depth 1 --filter=blob:none` | `git clone` |
| Git repo (history needed) | `git clone` | — |
| npm/pip/cargo/go | Native (pre-configured) | — |

## Commands

### Download
```bash
# Large file - full speed
aria2c -x 16 -s 16 -k 1M --file-allocation=falloc --continue=true --max-tries=5 -o "file.zip" "https://url"

# With verification
aria2c --checksum=sha256=abc123... -x 16 -s 16 -o "file.zip" "https://url"

# GitHub / rate-limited
aria2c -x 4 -s 4 -k 1M --continue=true -o "file.zip" "https://github.com/..."

# Simple fallback
curl -L -C - -o "file.zip" "https://url"
```

### Git
```bash
# Shallow (default)
git clone --depth 1 --single-branch --filter=blob:none https://github.com/user/repo.git

# Full
git clone https://github.com/user/repo.git
```

## Auto-config (run once)
```bash
git config --global core.compression 9
git config --global core.preloadIndex true
git config --global http.postBuffer 524288000
npm config set fetch-retries 5
npm config set prefer-offline true
pip config set global.retries 5
```

## Verification
```bash
sha256sum file.zip  # Linux/macOS
Get-FileHash -Algorithm SHA256 file.zip  # PowerShell
```