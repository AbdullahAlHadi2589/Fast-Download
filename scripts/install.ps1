<#PSScriptInfo
.VERSION 1.0.0
.GUID 12345678-1234-1234-1234-123456789012
.AUTHOR fast-download contributors
.COMPANYNAME
.COPYRIGHT (c) 2026 fast-download contributors. All rights reserved.
.TAGS fast-download, aria2, download, accelerator, git
.LICENSEURI https://opensource.org/licenses/MIT
.PROJECTURI https://github.com/AbdullahAlHadi2589/Fast-Download
.RELEASENOTES Initial release
#>

<#PSScriptInfo
.SYNOPSIS
    Install fast-download universal download accelerator for all AI coding agents.
.DESCRIPTION
    Installs aria2, and deploys agent-specific configurations
    for OpenCode, Claude Code, Codex, Continue, Cline, VS Code, Cursor, Windsurf, JetBrains AI, Amazon Q, and Warp.
    Global Git/npm/pip configs are NOT modified by default. Use -ApplyGlobalConfigs to opt-in.
.NOTES
    Requires: Windows 10/11, PowerShell 5.1+, Administrator for winget installs
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipAria2,
    [switch]$SkipGitConfig,
    [switch]$SkipNpmConfig,
    [switch]$SkipPipConfig,
    [switch]$ApplyGlobalConfigs,
    [switch]$DryRun,
    [ValidateSet('opencode','claude-code','codex','continue','cline','vscode','cursor','windsurf','jetbrains','amazon-q','warp','all')]
    [string[]]$Agent = @('all'),
    [string]$InstallDir = "$env:USERPROFILE\.fast-download"
)

# --- Helpers ---
function Write-Log {
    param([string]$Message, [ValidateSet('Info','Warn','Error','Success')][string]$Level = 'Info')
    $colors = @{ Info='Cyan'; Warn='Yellow'; Error='Red'; Success='Green' }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

function Test-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command {
    param([string]$Name)
    Get-Command $Name -ErrorAction SilentlyContinue
}

# Dry-run safe helpers
function Invoke-DryRunSafe {
    param([scriptblock]$Action, [string]$Description)
    if ($DryRun) {
        Write-Log "DRY RUN: $Description" 'Info'
        return
    }
    & $Action
}

function New-DirectorySafe {
    param([string]$Path)
    Invoke-DryRunSafe { New-Item -ItemType Directory -Path $Path -Force | Out-Null } "mkdir -p $Path"
}

function Copy-ItemSafe {
    param([string]$Source, [string]$Destination)
    Invoke-DryRunSafe { Copy-Item $Source $Destination -Force } "cp $Source $Destination"
}

function Find-Git {
    # First try PATH
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) { return $gitCmd.Source }

    # Common installation paths
    $commonPaths = @(
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files (x86)\Git\bin\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\git.exe",
        "$env:USERPROFILE\AppData\Local\Programs\Git\bin\git.exe",
        "$env:ProgramFiles\Git\bin\git.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

# --- Main ---
Write-Log "=== fast-download Installer ===" 'Info'
Write-Log "Target: $InstallDir" 'Info'
Write-Log "Agent: $Agent" 'Info'

# Check admin for winget
$isAdmin = Test-Admin
if (-not $isAdmin) {
    Write-Log "Not running as Administrator. winget installs will be skipped." 'Warn'
}

# 1. Install aria2 (if not skipped)
if (-not $SkipAria2) {
    Write-Log "Checking aria2..." 'Info'
    $aria2Cmd = Test-Command aria2c
    if ($aria2Cmd) {
        Write-Log "aria2 found: $(& $aria2Cmd --version | Select-Object -First 1)" 'Success'
    } else {
        Write-Log "aria2 not found. Installing..." 'Info'
        if ($isAdmin) {
            try {
                winget install aria2.aria2 --accept-source-agreements --accept-package-agreements --silent
                Write-Log "aria2 installed successfully" 'Success'
            } catch {
                Write-Log "aria2 install failed: $_" 'Error'
            }
        } else {
            Write-Log "Run as Admin to auto-install aria2, or install manually: winget install aria2.aria2" 'Warn'
        }
    }
}

# 2. Install Git (if missing)
Write-Log "Checking Git..." 'Info'
$gitExe = Find-Git
if ($gitExe) {
    Write-Log "Git found: $(& $gitExe --version)" 'Success'
} else {
    Write-Log "Git not found. Installing..." 'Info'
    if ($isAdmin) {
        try {
            winget install Git.Git --accept-source-agreements --accept-package-agreements --silent
            Write-Log "Git installed successfully" 'Success'
            $gitExe = Find-Git
        } catch {
            Write-Log "Git install failed: $_" 'Error'
        }
    } else {
        Write-Log "Run as Admin to auto-install Git, or install manually: winget install Git.Git" 'Warn'
    }
}

# 3. Create install directory
if (-not (Test-Path $InstallDir)) {
    New-DirectorySafe -Path $InstallDir
    Write-Log "Created $InstallDir" 'Info'
}

# 4. Copy universal shell libraries
$repoRoot = "$PSScriptRoot\.."
$srcLib = "$repoRoot\src\fast-download.sh"
$dstLib = "$InstallDir\fast-download.sh"
if (Test-Path $srcLib) {
    Copy-ItemSafe -Source $srcLib -Destination $dstLib
    Write-Log "Copied fast-download.sh to $InstallDir" 'Success'
}

$srcFish = "$repoRoot\src\fast-download.fish"
$dstFish = "$InstallDir\fast-download.fish"
if (Test-Path $srcFish) {
    Copy-ItemSafe -Source $srcFish -Destination $dstFish
    Write-Log "Copied fast-download.fish to $InstallDir" 'Success'
}

$srcNu = "$repoRoot\src\fast-download.nu"
$dstNu = "$InstallDir\fast-download.nu"
if (Test-Path $srcNu) {
    Copy-ItemSafe -Source $srcNu -Destination $dstNu
    Write-Log "Copied fast-download.nu (nushell) to $InstallDir" 'Success'
}

# 5. Copy PowerShell module
$psModule = "$repoRoot\opencode\FastDownload.psm1"
$dstModule = "$InstallDir\FastDownload.psm1"
if (Test-Path $psModule) {
    Copy-ItemSafe -Source $psModule -Destination $dstModule
    Write-Log "Copied FastDownload.psm1 to $InstallDir" 'Success'
}

# 6. Apply global configs (OPT-IN ONLY with -ApplyGlobalConfigs)
if ($ApplyGlobalConfigs) {
    Write-Log "Applying global optimizations (opt-in)..." 'Info'
    
    if ($gitExe -and -not $SkipGitConfig) {
        Write-Log "Applying Git optimizations..." 'Info'
        Invoke-DryRunSafe { & $gitExe config --global core.compression 9 } "git config --global core.compression 9"
        Invoke-DryRunSafe { & $gitExe config --global core.preloadIndex true } "git config --global core.preloadIndex true"
        Invoke-DryRunSafe { & $gitExe config --global core.fscache true } "git config --global core.fscache true"
        Invoke-DryRunSafe { & $gitExe config --global http.postBuffer 524288000 } "git config --global http.postBuffer 524288000"
        Invoke-DryRunSafe { & $gitExe config --global http.lowSpeedLimit 0 } "git config --global http.lowSpeedLimit 0"
        Invoke-DryRunSafe { & $gitExe config --global http.lowSpeedTime 999999 } "git config --global http.lowSpeedTime 999999"
        Write-Log "Git config applied" 'Success'
    } else {
        Write-Log "Git not found, skipping Git config" 'Warn'
    }

    if (Test-Command npm) {
        Write-Log "Applying npm optimizations..." 'Info'
        Invoke-DryRunSafe { npm config set fetch-retries 5 } "npm config set fetch-retries 5"
        Invoke-DryRunSafe { npm config set fetch-retry-factor 2 } "npm config set fetch-retry-factor 2"
        Invoke-DryRunSafe { npm config set prefer-offline true } "npm config set prefer-offline true"
        Write-Log "npm config applied" 'Success'
    }

    if (Test-Command pip) {
        Write-Log "Applying pip optimizations..." 'Info'
        Invoke-DryRunSafe { pip config set global.retries 5 } "pip config set global.retries 5"
        Invoke-DryRunSafe { pip config set global.timeout 60 } "pip config set global.timeout 60"
        Write-Log "pip config applied" 'Success'
    }
} else {
    Write-Log "Skipping global configs (use -ApplyGlobalConfigs to enable)" 'Info'
}

# 7. Deploy agent configurations
$agents = @()
if ($Agent -contains 'all') {
    $agents = @('opencode','claude-code','codex','continue','cline','vscode','cursor','windsurf','jetbrains','amazon-q','warp')
} else {
    $agents = @($Agent)
}

foreach ($a in $agents) {
    Write-Log "Deploying $a configuration..." 'Info'
    switch ($a) {
        'opencode' {
            $target = "$env:APPDATA\opencode\skill\fast-download"
            $source = "$repoRoot\opencode"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Invoke-DryRunSafe { Copy-Item "$source\*" $target -Recurse -Force } "cp -r $source\* $target"
                Write-Log "OpenCode skill deployed to $target" 'Success'
            }
        }
        'claude-code' {
            $target = "$env:USERPROFILE\.claude\agents"
            $source = "$repoRoot\claude-code\fast-download.md"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Copy-ItemSafe -Source $source -Destination $target
                Write-Log "Claude Code agent deployed to $target" 'Success'
            }
        }
        'codex' {
            $target = "$env:USERPROFILE\.codex\agents"
            $source = "$repoRoot\codex\fast-download.md"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Copy-ItemSafe -Source $source -Destination $target
                Write-Log "Codex agent deployed to $target" 'Success'
            }
        }
        'continue' {
            $target = "$env:USERPROFILE\.continue\agents"
            $source = "$repoRoot\continue\fast-download.yaml"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Copy-ItemSafe -Source $source -Destination $target
                Write-Log "Continue agent deployed to $target" 'Success'
            }
        }
        'cline' {
            $target = "$env:USERPROFILE\.cline\skills\fast-download"
            $source = "$repoRoot\cline\fast-download"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Invoke-DryRunSafe { Copy-Item "$source\*" $target -Recurse -Force } "cp -r $source\* $target"
                Write-Log "Cline skill deployed to $target" 'Success'
            }
        }
        'vscode' {
            $target = "$env:USERPROFILE\.vscode\extensions\fast-download"
            $source = "$repoRoot\vscode\fast-download"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Invoke-DryRunSafe { Copy-Item "$source\*" $target -Recurse -Force } "cp -r $source\* $target"
                Write-Log "VS Code skill deployed to $target" 'Success'
            }
        }
        'cursor' {
            $target = "$env:USERPROFILE\.cursor\extensions\fast-download"
            $source = "$repoRoot\cursor\fast-download"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Invoke-DryRunSafe { Copy-Item "$source\*" $target -Recurse -Force } "cp -r $source\* $target"
                Write-Log "Cursor skill deployed to $target" 'Success'
            }
        }
        'windsurf' {
            $target = "$env:USERPROFILE\.windsurf\extensions\fast-download"
            $source = "$repoRoot\windsurf\fast-download"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Invoke-DryRunSafe { Copy-Item "$source\*" $target -Recurse -Force } "cp -r $source\* $target"
                Write-Log "Windsurf skill deployed to $target" 'Success'
            }
        }
        'jetbrains' {
            $target = "$env:APPDATA\JetBrains\ai\agents"
            $source = "$repoRoot\jetbrains\fast-download.md"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Copy-ItemSafe -Source $source -Destination $target
                Write-Log "JetBrains AI agent deployed to $target" 'Success'
            }
        }
        'amazon-q' {
            $target = "$env:USERPROFILE\.aws\amazonq\agents"
            $source = "$repoRoot\amazon-q\fast-download.md"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Copy-ItemSafe -Source $source -Destination $target
                Write-Log "Amazon Q agent deployed to $target" 'Success'
            }
        }
        'warp' {
            $target = "$env:USERPROFILE\.warp\agents"
            $source = "$repoRoot\warp\fast-download.yaml"
            if (Test-Path $source) {
                New-DirectorySafe -Path $target
                Copy-ItemSafe -Source $source -Destination $target
                Write-Log "Warp agent deployed to $target" 'Success'
            }
        }
    }
}

Write-Log "=== Installation Complete ===" 'Success'
Write-Log "Installed to: $InstallDir" 'Info'
Write-Log "Add to PATH: $InstallDir" 'Info'
Write-Log "Usage: Import-Module FastDownload; Invoke-FastDownload -Url '...' -OutputPath '...'" 'Info'