# Fast Download Methods Reference

## Overview
This document describes the optimized download methods available in the fast-download skill. Each method is designed to maximize throughput while maintaining reliability and security.

## Tool Priority Order

### 1. aria2 (Primary - HTTP/HTTPS/FTP/BitTorrent/Metalink)
- **Use for**: Large files (>10MB), resumable downloads, parallel connections
- **Features**: 16 concurrent connections, automatic resume, checksum verification
- **Command**: `aria2c -x 16 -s 16 -k 1M --file-allocation=falloc --auto-file-renaming=false --continue=true`

### 2. Git Shallow Clone (Primary - Git Repositories)
- **Use for**: Git repositories where full history is not needed
- **Features**: `--depth 1`, `--single-branch`, `--filter=blob:none`
- **Command**: `git clone --depth 1 --single-branch --filter=blob:none <url>`

### 3. Git Full Clone (Fallback - Git Repositories)
- **Use for**: When full history is required
- **Features**: Standard git clone with optimized config
- **Command**: `git clone <url>`

### 4. curl (Fallback - HTTP/HTTPS)
- **Use for**: Small files, servers that don't support range requests, simple downloads
- **Features**: Single connection, resume with `-C -`
- **Command**: `curl -L -C - -o <file> <url>`

### 5. npm (Node.js Packages)
- **Use for**: npm package downloads
- **Features**: Built-in registry optimization, cache
- **Command**: `npm install <package>`

### 6. pip (Python Packages)
- **Use for**: Python package downloads
- **Features**: Built-in PyPI optimization, cache
- **Command**: `pip install <package>`

## Configuration

### aria2 Default Options
```bash
aria2c \
  -x 16 \                    # Max connections per server
  -s 16 \                    # Min split size (16 connections)
  -k 1M \                    # Min split size 1MB
  --file-allocation=falloc \ # Fast file allocation
  --auto-file-renaming=false \ # Don't rename on conflict
  --continue=true \          # Resume by default
  --max-tries=5 \            # Retry failed downloads
  --retry-wait=3 \           # Wait 3s between retries
  --check-certificate=true \ # Verify SSL
  --allow-overwrite=true     # Overwrite existing files
```

### Git Optimized Config
```bash
git config --global core.compression 9
git config --global core.preloadIndex true
git config --global core.fscache true
git config --global gc.auto 256
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
```

### npm Optimized Config
```bash
npm config set fetch-retries 5
npm config set fetch-retry-factor 2
npm config set fetch-retry-mintimeout 10000
npm config set fetch-retry-maxtimeout 60000
npm config set prefer-offline true
```

### pip Optimized Config
```bash
pip config set global.retries 5
pip config set global.timeout 60
```

## Decision Matrix

| Scenario | Primary Tool | Fallback | Notes |
|----------|-------------|----------|-------|
| Large HTTP/HTTPS file (>10MB) | aria2 | curl | Use aria2 for parallel downloads |
| Small HTTP/HTTPS file (<10MB) | curl | aria2 | curl overhead lower for small files |
| Git repo (no history needed) | git shallow | git full | --depth 1 saves 90%+ bandwidth |
| Git repo (history needed) | git full | - | Full clone required |
| npm package | npm | - | Registry handles optimization |
| Python package | pip | - | PyPI handles optimization |
| Resume interrupted | aria2 | curl -C - | aria2 handles resume better |
| Checksum verification | aria2 --checksum | manual | Built-in verification |

## Speed Test Results (Baseline)

| File | Source | curl (single) | aria2 (16 conn) | Improvement |
|------|--------|---------------|-----------------|-------------|
| 100MB | proof.ovh.net | ~9.6 MB/s | ~8.7 MB/s | Similar (server limited) |
| 2.4MB | GitHub releases | ~3 MB/s | ~10 MB/s | 3.3x faster |
| Git repo (shallow) | GitHub | N/A | 7.8s | N/A |
| Git repo (full) | GitHub | N/A | 43.5s | N/A |

## Security Considerations
- Always verify SSL certificates (`--check-certificate=true`)
- Validate checksums when available (`--checksum=sha256=<hash>`)
- Don't disable certificate verification for speed
- Use trusted sources only