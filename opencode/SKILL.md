---
name: fast-download
description: Optimized download accelerator for OpenCode using aria2, parallel connections, and smart fallbacks. Use for large file downloads, Git shallow clones, and checksum-verified transfers.
---

# Fast Download Skill

Agent runbook for accelerated downloads on Windows using aria2 (multi-connection), Git shallow clones, and curl fallback with resume support.

## Operating Principles

1. **Use aria2 for HTTP/HTTPS/FTP** - Multi-connection downloads with 16 parallel connections and resume support
2. **Use Git shallow clones** - Save 90%+ bandwidth when full history isn't needed
3. **Verify integrity** - Always checksum downloaded files when possible
4. **Fail gracefully** - Fall back to curl with resume when aria2 isn't available
5. **Never compromise security** - SSL verification always enabled

## Quick Reference

### Download a file (HTTP/HTTPS)
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

- **Files > 10MB with range support**: aria2 with 16 connections
- **Files < 10MB or no range support**: curl with resume
- **Git repos without full history needed**: shallow clone with `--depth 1 --single-branch --filter=blob:none`
- **npm/pip packages**: Use native package managers

## Integration

This skill is automatically available when you use shell commands in OpenCode. The PATH is configured to include aria2 and Git. Use the patterns above for all downloads.

See `instructions.md` for complete documentation including PowerShell functions `Invoke-FastDownload` and `Invoke-GitClone`.