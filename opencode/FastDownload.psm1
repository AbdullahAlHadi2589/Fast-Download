# FastDownload PowerShell Module
# Provides optimized download functions for OpenCode sessions

# Ensure PATH includes aria2 and Git
function Initialize-FastDownload {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path","User")
    $env:Path = "$machinePath;$userPath"
    
    # Detect Git using Get-Command first (checks PATH)
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    
    # If not in PATH, check common installation locations
    if (-not $gitCmd) {
        $commonPaths = @(
            "C:\Program Files\Git\bin\git.exe",
            "C:\Program Files (x86)\Git\bin\git.exe",
            "$env:LOCALAPPDATA\Programs\Git\bin\git.exe",
            "$env:USERPROFILE\AppData\Local\Programs\Git\bin\git.exe",
            "$env:ProgramFiles\Git\bin\git.exe"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $gitCmd = Get-Command $path -ErrorAction SilentlyContinue
                if ($gitCmd) { break }
            }
        }
    }
    
    # Verify tools are available
    $tools = @{
        aria2c = Get-Command aria2c -ErrorAction SilentlyContinue
        git = $gitCmd
        curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    }
    
    $missing = $tools.Keys | Where-Object { -not $tools[$_] }
    if ($missing) {
        Write-Warning "Missing tools: $($missing -join ', ')"
    }
    
    return $tools
}

# 10 MB threshold (in bytes) - below this, curl is more efficient due to aria2 overhead
$global:FD_SMALL_FILE_THRESHOLD = 10485760

# Internal: Check if server supports range requests
function _Test-RangeSupport {
    param([string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.Headers.ContainsKey("Accept-Ranges") -and $response.Headers["Accept-Ranges"] -eq "bytes") {
            return $true
        }
    } catch {
        # If HEAD request fails, assume no range support
    }
    return $false
}

# Internal: Get content length from HEAD request
function _Get-ContentLength {
    param([string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.Headers.ContainsKey("Content-Length")) {
            $length = $response.Headers["Content-Length"]
            if ($length -match '^\d+$') {
                return [int64]$length
            }
        }
    } catch {
        # Ignore errors
    }
    return -1
}

# Internal: Smart download method selection
function _Select-DownloadMethod {
    param(
        [string]$Url,
        [switch]$ForceCurl
    )
    
    # Git URLs are handled separately (match actual repo URLs, not file downloads)
    # Matches: https://github.com/user/repo, https://github.com/user/repo/, https://github.com/user/repo.git, git@...
    # Does NOT match: https://github.com/user/repo/file.zip, https://github.com/user/repo/releases/..., etc.
    if ($Url -match '^https?://github\.com/[^/]+/[^/]+\.git$' -or 
        ($Url -match '^https?://github\.com/[^/]+/[^/]+/?$' -and -not $Url -match '\.[a-zA-Z0-9]+$') -or
        $Url -match '^git@' -or
        $Url -match '\.git$') {
        return "git"
    }
    
    # Force curl if requested
    if ($ForceCurl) {
        return "curl"
    }
    
    # Check for aria2 availability
    $aria2c = Get-Command aria2c -ErrorAction SilentlyContinue
    if (-not $aria2c) {
        return "curl"
    }
    
    # Known rate-limited domains (exclude raw file URLs like github.com/user/repo/raw/...)
    if ($Url -match 'proof\.ovh\.net' -or 
        ($Url -match 'github\.com' -and -not $Url -match 'github\.com/[^/]+/[^/]+/(raw|releases|archive)') -or 
        $Url -match 'release-assets\.githubusercontent\.com') {
        return "aria2-limited"
    }
    
    # Check if server supports range requests
    if (-not (_Test-RangeSupport -Url $Url)) {
        # Server doesn't support range requests - aria2's multi-connection won't help
        return "curl"
    }
    
    # Server supports ranges - check file size to decide between aria2 and curl
    $contentLength = _Get-ContentLength -Url $Url
    if ($contentLength -gt 0 -and $contentLength -lt $global:FD_SMALL_FILE_THRESHOLD) {
        # File is smaller than threshold - curl is more efficient
        return "curl"
    }
    
    # Large file or unknown size with range support - use aria2
    return "aria2"
}

# Download a file using aria2 (preferred) with curl fallback
function Invoke-FastDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [string]$ExpectedChecksum = $null,
        
        [int]$MaxConnections = 16,
        
        [switch]$ForceCurl = $false
    )
    
    Initialize-FastDownload | Out-Null
    
    $outputDir = Split-Path $OutputPath -Parent
    $outputFile = Split-Path $OutputPath -Leaf
    
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Smart method selection
    $method = _Select-DownloadMethod -Url $Url -ForceCurl:$ForceCurl
    $downloadSucceeded = $false
    
    # Try aria2 first (for aria2 and aria2-limited methods)
    if (($method -eq "aria2" -or $method -eq "aria2-limited") -and (Get-Command aria2c -ErrorAction SilentlyContinue)) {
        $connections = $MaxConnections
        if ($method -eq "aria2-limited") {
            $connections = 4
        }
        
        Write-Host "Downloading with aria2 (connections: $connections, method: $method)..." -ForegroundColor Cyan
        
        $args = @(
            "-x", $connections,
            "-s", $connections,
            "-k", "1M",
            "--file-allocation=falloc",
            "--continue=true",
            "--max-tries=5",
            "--retry-wait=3",
            "--check-certificate=true",
            "--allow-overwrite=true",
            "-o", $outputFile,
            "-d", $outputDir,
            $Url
        )
        
        if ($ExpectedChecksum) {
            $args += "--checksum=sha256=$ExpectedChecksum"
        }
        
        $startTime = Get-Date
        $result = & aria2c @args 2>&1
        $elapsed = (Get-Date) - $startTime
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Download completed in $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
            $downloadSucceeded = $true
        } else {
            Write-Warning "aria2 failed (exit code $LASTEXITCODE), falling back to curl..."
        }
    }
    
    # Fallback to curl
    if (-not $downloadSucceeded) {
        Write-Host "Downloading with curl..." -ForegroundColor Yellow
        
        $curlArgs = @(
            "-L",                    # Follow redirects
            "-o", $OutputPath,
            "--retry", "5",
            "--retry-delay", "3",
            "--fail",                # Fail on HTTP errors
            "-#",                    # Progress bar
            $Url
        )
        
        # Use resume (-C -) only if file exists and is non-empty AND server supports ranges
        if ((Test-Path $OutputPath) -and (Get-Item $OutputPath).Length -gt 0 -and (_Test-RangeSupport $Url)) {
            $curlArgs = @("-C", "-") + $curlArgs
        }
        
        $startTime = Get-Date
        $result = & curl.exe @curlArgs 2>&1
        $elapsed = (Get-Date) - $startTime
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Download completed in $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
            $downloadSucceeded = $true
        }
    }
    
    # Verify checksum after ANY successful download
    if ($downloadSucceeded -and $ExpectedChecksum) {
        Write-Host "Verifying checksum..." -ForegroundColor Cyan
        $actualHash = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash.ToLower()
        $expectedHash = $ExpectedChecksum.ToLower()
        
        if ($actualHash -eq $expectedHash) {
            Write-Host "Checksum verified (SHA256)" -ForegroundColor Green
        } else {
            Write-Error "Checksum mismatch!`nExpected: $expectedHash`nActual:   $actualHash"
            Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    
    if ($downloadSucceeded) {
        return $true
    } else {
        Write-Error "Download failed with both aria2 and curl"
        return $false
    }
}

# Clone a Git repository with optional shallow clone
function Invoke-GitClone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [switch]$Shallow = $true,
        
        [string]$Branch = $null
    )
    
    Initialize-FastDownload | Out-Null
    
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    
    # If not in PATH, check common installation locations
    if (-not $gitPath) {
        $commonPaths = @(
            "C:\Program Files\Git\bin\git.exe",
            "C:\Program Files (x86)\Git\bin\git.exe",
            "$env:LOCALAPPDATA\Programs\Git\bin\git.exe",
            "$env:USERPROFILE\AppData\Local\Programs\Git\bin\git.exe",
            "$env:ProgramFiles\Git\bin\git.exe"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $gitPath = $path
                break
            }
        }
    }
    
    if (-not $gitPath) {
        throw "Git not found. Please ensure Git is installed and in PATH."
    }
    
    $args = @("clone")
    
    if ($Shallow) {
        $args += @("--depth", "1", "--single-branch", "--filter=blob:none")
    }
    
    if ($Branch) {
        $args += @("--branch", $Branch)
    }
    
    $args += @($Url, $OutputPath)
    
    $shallowText = if ($Shallow) { " (shallow)" } else { "" }
    Write-Host "Cloning repository$shallowText..." -ForegroundColor Cyan
    $startTime = Get-Date
    $result = & $gitPath @args 2>&1
    $elapsed = (Get-Date) - $startTime
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Clone completed in $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
        return $true
    }
    
    Write-Error "Git clone failed: $result"
    return $false
}

# Verify file checksum
function Test-FileChecksum {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$ExpectedHash,
        
        [ValidateSet('SHA256', 'SHA1', 'MD5')]
        [string]$Algorithm = 'SHA256'
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }
    
    $actualHash = (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash.ToLower()
    $expectedHash = $ExpectedHash.ToLower()
    
    if ($actualHash -eq $expectedHash) {
        Write-Host "Checksum verified ($Algorithm)" -ForegroundColor Green
        return $true
    }
    else {
        Write-Error "Checksum mismatch!`nExpected: $expectedHash`nActual:   $actualHash"
        return $false
    }
}

# Get download speed test
function Measure-DownloadSpeed {
    [CmdletBinding()]
    param(
        [string]$TestUrl = "https://proof.ovh.net/files/100Mb.dat",
        [int]$TestSizeMB = 100
    )
    
    Initialize-FastDownload | Out-Null
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    Write-Host "Testing download speed from $TestUrl..." -ForegroundColor Cyan
    
    # Test with aria2
    if (Get-Command aria2c -ErrorAction SilentlyContinue) {
        Write-Host "`n--- aria2 (16 connections) ---" -ForegroundColor Yellow
        $result = Measure-Command { 
            & aria2c -x 16 -s 16 -k 1M --file-allocation=none --continue=true -o $tempFile -d ([System.IO.Path]::GetTempPath()) $TestUrl 2>&1 
        }
        if ($LASTEXITCODE -eq 0) {
            $speedMBps = $TestSizeMB / $result.TotalSeconds
            Write-Host "Time: $($result.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
            Write-Host "Speed: $($speedMBps.ToString('F1')) MB/s" -ForegroundColor Green
        }
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
    
    # Test with curl
    Write-Host "`n--- curl (single connection) ---" -ForegroundColor Yellow
    $result = Measure-Command { 
        & curl.exe -L -o $tempFile $TestUrl 2>&1 
    }
    if ($LASTEXITCODE -eq 0) {
        $speedMBps = $TestSizeMB / $result.TotalSeconds
        Write-Host "Time: $($result.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
        Write-Host "Speed: $($speedMBps.ToString('F1')) MB/s" -ForegroundColor Green
    }
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

# Export functions
Export-ModuleMember -Function Invoke-FastDownload, Invoke-GitClone, Test-FileChecksum, Measure-DownloadSpeed, Initialize-FastDownload