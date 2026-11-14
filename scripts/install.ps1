<#PSScriptInfo
.VERSION 1.0.0
.GUID 12345678-1234-1234-1234-123456789012
.AUTHOR fast-download contributors
.COMPANYNAME
.COPYRIGHT (c) 2026 fast-download contributors. All rights reserved.
.TAGS fast-download, aria2, download, accelerator, git
.LICENSEURI https://opensource.org/licenses/MIT
.PROJECTURI https://github.com/yourusername/fast-download
.RELEASENOTES Initial release
#>

<#PSScriptInfo
.SYNOPSIS
    Install fast-download universal download accelerator for all AI coding agents.
.DESCRIPTION
    Installs aria2, configures git/npm/pip, and deploys agent-specific configurations
    for OpenCode, Claude Code, Codex, Continue, Cline, and VS Code.
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
    [switch]$OnlyAgent,
    [ValidateSet('opencode','claude-code','codex','continue','cline','vscode','all')]
    [string]$Agent = 'all',
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

# --- Main ---
Write-Log "=== fast-download Installer ===" 'Info'
Write-Log "Target: $InstallDir" 'Info'
Write-Log "Agent: $Agent" 'Info'

# Check admin for winget
$isAdmin = Test-Admin
if (-not $isAdmin) {
    Write-Log "Not running as Administrator. winget installs may fail." 'Warn'
}

# 1. Install aria2
if (-not $SkipAria2) {
    Write-Log "Installing aria2..." 'Info'
    if (Test-Command aria2c) {
        Write-Log "aria2 already installed: $(aria2c --version | Select-Object -First 1)" 'Success'
    } else {
        if ($isAdmin) {
            try {
                winget install aria2.aria2 --accept-source-agreements --accept-package-agreements --silent
                Write-Log "aria2 installed successfully" 'Success'
            } catch {
                Write-Log "winget install failed: $_" 'Error'
                Write-Log "Manual install: https://aria2.github.io/" 'Warn'
            }
        } else {
            Write-Log "Run as Admin to auto-install aria2, or install manually: winget install aria2.aria2" 'Warn'
        }
    }
}

# 2. Install Git (if missing)
if (Test-Command "C:\Program Files\Git\bin\git.exe") {
    Write-Log "Git found: $(& "C:\Program Files\Git\bin\git.exe" --version)" 'Success'
} else {
    Write-Log "Git not found. Installing..." 'Info'
    if ($isAdmin) {
        try {
            winget install Git.Git --accept-source-agreements --accept-package-agreements --silent
            Write-Log "Git installed successfully" 'Success'
        } catch {
            Write-Log "Git install failed: $_" 'Error'
        }
    } else {
        Write-Log "Run as Admin to auto-install Git, or install manually: winget install Git.Git" 'Warn'
    }
}

# 3. Create install directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Log "Created $InstallDir" 'Info'
}

# 4. Copy universal shell library
$repoRoot = "$PSScriptRoot\.."
$srcLib = "$repoRoot\src\fast-download.sh"
$dstLib = "$InstallDir\fast-download.sh"
if (Test-Path $srcLib) {
    Copy-Item $srcLib $dstLib -Force
    Write-Log "Copied fast-download.sh to $InstallDir" 'Success'
}

# 5. Copy PowerShell module
$psModule = "$repoRoot\opencode\FastDownload.psm1"
$dstModule = "$InstallDir\FastDownload.psm1"
if (Test-Path $psModule) {
    Copy-Item $psModule $dstModule -Force
    Write-Log "Copied FastDownload.psm1 to $InstallDir" 'Success'
}

# 6. Apply global configs
if (-not $SkipGitConfig) {
    Write-Log "Applying Git optimizations..." 'Info'
    $gitExe = "C:\Program Files\Git\bin\git.exe"
    if (Test-Path $gitExe) {
        & $gitExe config --global core.compression 9
        & $gitExe config --global core.preloadIndex true
        & $gitExe config --global core.fscache true
        & $gitExe config --global http.postBuffer 524288000
        & $gitExe config --global http.lowSpeedLimit 0
        & $gitExe config --global http.lowSpeedTime 999999
        Write-Log "Git config applied" 'Success'
    }
}

if (-not $SkipNpmConfig) {
    if (Test-Command npm) {
        Write-Log "Applying npm optimizations..." 'Info'
        npm config set fetch-retries 5
        npm config set fetch-retry-factor 2
        npm config set prefer-offline true
        Write-Log "npm config applied" 'Success'
    }
}

if (-not $SkipPipConfig) {
    if (Test-Command pip) {
        Write-Log "Applying pip optimizations..." 'Info'
        pip config set global.retries 5
        pip config set global.timeout 60
        Write-Log "pip config applied" 'Success'
    }
}

# 7. Deploy agent configurations
$agents = @()
if ($Agent -eq 'all') {
    $agents = 'opencode','claude-code','codex','continue','cline','vscode','cursor','windsurf','jetbrains','amazon-q','warp'
} else {
    $agents = $Agent
}

foreach ($a in $agents) {
    Write-Log "Deploying $a configuration..." 'Info'
    switch ($a) {
        'opencode' {
            $target = "$env:APPDATA\opencode\skill\fast-download"
            $source = "$repoRoot\opencode"
            if (Test-Path $source) {
                Copy-Item $source $target -Recurse -Force
                Write-Log "OpenCode skill deployed to $target" 'Success'
            }
        }
        'claude-code' {
            $target = "$env:USERPROFILE\.claude\agents\fast-download.md"
            $source = "$repoRoot\claude-code\fast-download.md"
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (Test-Path $source) {
                Copy-Item $source $target -Force
                Write-Log "Claude Code agent deployed to $target" 'Success'
            }
        }
        'codex' {
            $target = "$env:USERPROFILE\.codex\agents\fast-download.md"
            $source = "$repoRoot\codex\fast-download.md"
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (Test-Path $source) {
                Copy-Item $source $target -Force
                Write-Log "Codex agent deployed to $target" 'Success'
            }
        }
        'continue' {
            $target = "$env:USERPROFILE\.continue\agents\fast-download.yaml"
            $source = "$repoRoot\continue\fast-download.yaml"
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (Test-Path $source) {
                Copy-Item $source $target -Force
                Write-Log "Continue agent deployed to $target" 'Success'
            }
        }
        'cline' {
            $target = "$env:USERPROFILE\.cline\skills\fast-download"
            $source = "$repoRoot\cline\fast-download"
            if (Test-Path $source) {
                Copy-Item $source $target -Recurse -Force
                Write-Log "Cline skill deployed to $target" 'Success'
            }
        }
        'vscode' {
            $target = "$env:USERPROFILE\.vscode\extensions\fast-download"
            $source = "$repoRoot\vscode\fast-download"
            if (Test-Path $source) {
                Copy-Item $source $target -Recurse -Force
                Write-Log "VS Code skill deployed to $target" 'Success'
            }
        }
        'cursor' {
            $target = "$env:USERPROFILE\.cursor\extensions\fast-download"
            $source = "$repoRoot\vscode\fast-download"
            if (Test-Path $source) {
                Copy-Item $source $target -Recurse -Force
                Write-Log "Cursor skill deployed to $target" 'Success'
            }
        }
        'windsurf' {
            $target = "$env:USERPROFILE\.windsurf\extensions\fast-download"
            $source = "$repoRoot\vscode\fast-download"
            if (Test-Path $source) {
                Copy-Item $source $target -Recurse -Force
                Write-Log "Windsurf skill deployed to $target" 'Success'
            }
        }
        'jetbrains' {
            $target = "$env:APPDATA\JetBrains\ai\agents\fast-download.md"
            $source = "$repoRoot\claude-code\fast-download.md"
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (Test-Path $source) {
                Copy-Item $source $target -Force
                Write-Log "JetBrains AI agent deployed to $target" 'Success'
            }
        }
        'amazon-q' {
            $target = "$env:USERPROFILE\.aws\amazonq\agents\fast-download.md"
            $source = "$repoRoot\claude-code\fast-download.md"
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (Test-Path $source) {
                Copy-Item $source $target -Force
                Write-Log "Amazon Q agent deployed to $target" 'Success'
            }
        }
        'warp' {
            $target = "$env:USERPROFILE\.warp\agents\fast-download.yaml"
            $source = "$repoRoot\continue\fast-download.yaml"
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (Test-Path $source) {
                Copy-Item $source $target -Force
                Write-Log "Warp agent deployed to $target" 'Success'
            }
        }
    }
}

# 8. Add to PATH (user scope)
$installDirInPath = $false
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    Write-Log "Added $InstallDir to user PATH" 'Success'
    $installDirInPath = $true
}

# 9. Verify
Write-Log "=== Verification ===" 'Info'
$tools = @('aria2c', 'git', 'curl')
foreach ($t in $tools) {
    if (Test-Command $t) {
        Write-Log "$t: Available" 'Success'
    } else {
        Write-Log "$t: NOT FOUND" 'Warn'
    }
}

# 10. Final message
Write-Log "" 'Info'
Write-Log "=== Installation Complete ===" 'Success'
Write-Log "" 'Info'
Write-Log "Next steps:" 'Info'
Write-Log "  1. RESTART YOUR TERMINAL / IDE to refresh PATH" 'Info'
Write-Log "  2. Test: aria2c --version" 'Info'
Write-Log "  3. Use in any terminal:" 'Info'
Write-Log '     aria2c -x 16 -s 16 -o "file.zip" "https://url/file.zip"' 'Info'
Write-Log '     git clone --depth 1 --filter=blob:none https://github.com/user/repo.git' 'Info'
Write-Log "" 'Info'
Write-Log "Shell libraries installed:" 'Info'
Write-Log "  PowerShell: Import-Module $InstallDir\FastDownload.psm1" 'Info'
Write-Log "  Bash/WSL:   source $InstallDir\fast-download.sh" 'Info'
Write-Log "  Fish:       source $InstallDir\fast-download.fish" 'Info'
Write-Log "  Nushell:    source $InstallDir\fast-download.nu" 'Info'
Write-Log "" 'Info'
Write-Log "Agent configs deployed:" 'Info'
foreach ($a in $agents) {
    Write-Log "  - $a" 'Info'
}

if ($installDirInPath) {
    Write-Log "" 'Warn'
    Write-Log "IMPORTANT: Restart your terminal/PowerShell/VS Code for PATH changes to take effect." 'Warn'
}