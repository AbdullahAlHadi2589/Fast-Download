# FastDownload PowerShell Module
# Provides optimized download functions for OpenCode sessions

# Ensure PATH includes aria2 and Git
function Initialize-FastDownload {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path","User")
    $env:Path = "$machinePath;$userPath"
    
    # Verify tools are available
    $tools = @{
        aria2c = Get-Command aria2c -ErrorAction SilentlyContinue
        git = Get-Command "C:\Program Files\Git\bin\git.exe" -ErrorAction SilentlyContinue
        curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    }
    
    $missing = $tools.Keys | Where-Object { -not $tools[$_] }
    if ($missing) {
        Write-Warning "Missing tools: $($missing -join ', ')"
    }
    
    return $tools
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
    
    # Try aria2 first (unless forced to use curl)
    if (-not $ForceCurl -and (Get-Command aria2c -ErrorAction SilentlyContinue)) {
        Write-Host "Downloading with aria2 (connections: $MaxConnections)..." -ForegroundColor Cyan
        
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
            return $true
        }
        
        Write-Warning "aria2 failed (exit code $LASTEXITCODE), falling back to curl..."
    }
    
    # Fallback to curl
    Write-Host "Downloading with curl..." -ForegroundColor Yellow
    
    $curlArgs = @(
        "-L",                    # Follow redirects
        "-C", "-",               # Resume if possible
        "-o", $OutputPath,
        "--retry", "5",
        "--retry-delay", "3",
        "--fail",                # Fail on HTTP errors
        "-#",                    # Progress bar
        $Url
    )
    
    $startTime = Get-Date
    $result = & curl.exe @curlArgs 2>&1
    $elapsed = (Get-Date) - $startTime
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Download completed in $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
        return $true
    }
    
    Write-Error "Download failed with both aria2 and curl"
    return $false
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
    
    $gitPath = "C:\Program Files\Git\bin\git.exe"
    if (-not (Test-Path $gitPath)) {
        throw "Git not found at $gitPath"
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