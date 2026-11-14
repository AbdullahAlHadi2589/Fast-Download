# Fast Download Skill Instructions

## Purpose
This skill teaches OpenCode to use optimized download methods for maximum throughput on Windows. It automatically selects the best tool based on the download type and provides fallback mechanisms.

## Core Principles
1. **Use aria2 for HTTP/HTTPS/FTP** - Multi-connection downloads with resume support
2. **Use Git shallow clones** - When full history isn't needed, save 90%+ bandwidth
3. **Verify integrity** - Always checksum downloaded files when possible
4. **Fail gracefully** - Fall back to standard tools when optimization isn't available
5. **Never compromise security** - SSL verification always enabled

## Quick Reference Commands

### Download a file (HTTP/HTTPS)
```bash
# Preferred: aria2 with 16 connections, resume enabled
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
# aria2 with SHA256 verification
aria2c --checksum=sha256=<expected_hash> -x 16 -s 16 -o "output.zip" "https://example.com/file.zip"
```

## Decision Logic for Tool Selection

### For HTTP/HTTPS/FTP URLs:
```
IF file_size > 10MB AND server_supports_range_requests:
    USE aria2 with 16 connections
ELIF file_size < 10MB OR NOT server_supports_range_requests:
    USE curl with resume (-C -)
ELSE:
    USE curl (fallback)
```

### For Git URLs:
```
IF full_history_not_required:
    USE git clone --depth 1 --single-branch --filter=blob:none
ELSE:
    USE git clone (full)
```

### For Package Managers:
```
npm packages: USE npm install (registry optimized)
Python packages: USE pip install (PyPI optimized)
```

## Implementation Functions

### PowerShell Function: Invoke-FastDownload
```powershell
function Invoke-FastDownload {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$ExpectedChecksum = $null,
        [int]$MaxConnections = 16
    )
    
    # Ensure aria2 is in PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Check if URL is a Git repository
    if ($Url -match '^https?://github\.com/') {
        # Could be a repo or a release asset
        if ($Url -match '\.git$' -or $Url -match 'github\.com/[^/]+/[^/]+/?$') {
            return Invoke-GitClone -Url $Url -OutputPath $OutputPath
        }
    }
    
    # For regular files, try aria2 first
    if (Test-Path (Get-Command aria2c -ErrorAction SilentlyContinue).Source) {
        $args = @(
            "-x", $MaxConnections,
            "-s", $MaxConnections,
            "-k", "1M",
            "--file-allocation=falloc",
            "--continue=true",
            "--max-tries=5",
            "--retry-wait=3",
            "--check-certificate=true",
            "--allow-overwrite=true",
            "-o", (Split-Path $OutputPath -Leaf),
            "-d", (Split-Path $OutputPath -Parent),
            $Url
        )
        
        if ($ExpectedChecksum) {
            $args += "--checksum=sha256=$ExpectedChecksum"
        }
        
        $result = & aria2c @args 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        Write-Warning "aria2 failed, falling back to curl: $result"
    }
    
    # Fallback to curl
    $curlArgs = @(
        "-L",                    # Follow redirects
        "-C", "-",               # Resume if possible
        "-o", $OutputPath,
        "--retry", "5",
        "--retry-delay", "3",
        "--fail",                # Fail on HTTP errors
        $Url
    )
    
    $result = & curl.exe @curlArgs 2>&1
    return $LASTEXITCODE -eq 0
}
```

### PowerShell Function: Invoke-GitClone
```powershell
function Invoke-GitClone {
    param(
        [string]$Url,
        [string]$OutputPath,
        [switch]$Shallow = $true
    )
    
    $gitPath = "C:\Program Files\Git\bin\git.exe"
    if (-not (Test-Path $gitPath)) {
        throw "Git not found at $gitPath"
    }
    
    $args = @("clone")
    
    if ($Shallow) {
        $args += @("--depth", "1", "--single-branch", "--filter=blob:none")
    }
    
    $args += @($Url, $OutputPath)
    
    $result = & $gitPath @args 2>&1
    return $LASTEXITCODE -eq 0
}
```

## Usage in OpenCode Sessions

### Shell Commands
When you need to download anything in shell, use these patterns:

```bash
# Large file download
aria2c -x 16 -s 16 -k 1M --continue=true -o "file.zip" "https://url/file.zip"

# Git repo (shallow)
git clone --depth 1 --single-branch --filter=blob:none https://github.com/user/repo.git

# With checksum
aria2c --checksum=sha256=abc123... -x 16 -s 16 -o "file.zip" "https://url/file.zip"

# Resume interrupted
aria2c -x 16 -s 16 --continue=true -o "file.zip" "https://url/file.zip"
```

### Verification After Download
```bash
# Verify SHA256
Get-FileHash -Algorithm SHA256 file.zip

# Verify file size matches expected
$expected = 104857600
$actual = (Get-Item file.zip).Length
if ($actual -eq $expected) { "OK" } else { "MISMATCH" }
```

## Environment Setup (Run Once)
```powershell
# Add to PowerShell profile for persistent PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

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

## Troubleshooting

### aria2 not found
```powershell
# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
aria2c --version
```

### Slow GitHub downloads
- GitHub release assets are served from `release-assets.githubusercontent.com`
- aria2 handles redirects automatically
- If rate limited, reduce connections: `-x 4 -s 4`

### Resume not working
- Server must support `Accept-Ranges: bytes`
- Check with: `curl -I <url> | findstr Accept-Ranges`
- If not supported, aria2 falls back to single connection

### SSL Certificate Errors
- Never disable certificate verification
- If corporate proxy, configure aria2 with `--proxy-method` and `--all-proxy`
- Use `--ca-certificate` for custom CAs

## Performance Expectations

| Scenario | Expected Speed | Notes |
|----------|---------------|-------|
| Large file (CDN) | 50-100+ MB/s | Limited by server/ISP |
| GitHub releases | 10-30 MB/s | Server-side limits |
| Git shallow clone | 5-20 MB/s | Depends on repo size |
| npm/pip packages | Variable | Registry CDN optimized |

## Integration with OpenCode
This skill is automatically available when you use shell commands in OpenCode. The PATH is configured to include aria2 and Git. Use the patterns above for all downloads.

## Version History
- 1.0.0: Initial release with aria2, git shallow clones, curl fallback