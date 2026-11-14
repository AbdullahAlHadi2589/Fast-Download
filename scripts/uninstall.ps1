<#PSScriptInfo
.VERSION 1.0.0
.GUID 87654321-4321-4321-4321-210987654321
.AUTHOR Abdullah Al Hadi
.COPYRIGHT (c) 2026 Abdullah Al Hadi
.LICENSEURI https://opensource.org/licenses/MIT
.PROJECTURI https://github.com/AbdullahAlHadi/fast-download
#>

<#PSScriptInfo
.SYNOPSIS
    Uninstall fast-download and all agent configurations.
.DESCRIPTION
    Removes fast-download shell library, PowerShell module, and all agent configurations.
    Optionally reverts global git/npm/pip configurations.
.NOTES
    Run from PowerShell. Does not require Administrator unless reverting global configs.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$RevertConfigs,
    [string]$InstallDir = "$env:USERPROFILE\.fast-download"
)

function Write-Log {
    param([string]$Message, [ValidateSet('Info','Warn','Error','Success')][string]$Level = 'Info')
    $colors = @{ Info='Cyan'; Warn='Yellow'; Error='Red'; Success='Green' }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

if (-not $Force) {
    $confirm = Read-Host "This will remove fast-download and all agent configs. Continue? (y/N)"
    if ($confirm -notmatch '^y$') {
        Write-Log "Cancelled" 'Warn'
        exit 0
    }
}

Write-Log "=== fast-download Uninstaller ===" 'Info'
Write-Log "Install dir: $InstallDir" 'Info'

# Remove agent configurations
$agents = @(
    @{ Name = 'OpenCode'; Path = Join-Path $env:APPDATA 'opencode\skill\fast-download'; Type = 'Dir' },
    @{ Name = 'Claude Code'; Path = Join-Path $env:USERPROFILE '.claude\agents\fast-download.md'; Type = 'File' },
    @{ Name = 'Codex'; Path = Join-Path $env:USERPROFILE '.codex\agents\fast-download.md'; Type = 'File' },
    @{ Name = 'Continue'; Path = Join-Path $env:USERPROFILE '.continue\agents\fast-download.yaml'; Type = 'File' },
    @{ Name = 'Cline'; Path = Join-Path $env:USERPROFILE '.cline\skills\fast-download'; Type = 'Dir' },
    @{ Name = 'VS Code'; Path = Join-Path $env:USERPROFILE '.vscode\extensions\fast-download'; Type = 'Dir' },
    @{ Name = 'Cursor'; Path = Join-Path $env:USERPROFILE '.cursor\extensions\fast-download'; Type = 'Dir' },
    @{ Name = 'Windsurf'; Path = Join-Path $env:USERPROFILE '.windsurf\extensions\fast-download'; Type = 'Dir' },
    @{ Name = 'JetBrains AI'; Path = Join-Path $env:APPDATA 'JetBrains\ai\agents\fast-download.md'; Type = 'File' },
    @{ Name = 'Amazon Q'; Path = Join-Path $env:USERPROFILE '.aws\amazonq\agents\fast-download.md'; Type = 'File' },
    @{ Name = 'Warp'; Path = Join-Path $env:USERPROFILE '.warp\agents\fast-download.yaml'; Type = 'File' }
)

foreach ($agent in $agents) {
    if (Test-Path $agent.Path) {
        if ($agent.Type -eq 'Dir') {
            Remove-Item $agent.Path -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Remove-Item $agent.Path -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Removed $($agent.Name) config" 'Success'
    }
}

# Remove install directory
if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Removed $InstallDir" 'Success'
}

# Remove from user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*$InstallDir*") {
    $newPath = ($userPath -split ';' | Where-Object { $_ -ne $InstallDir }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Log "Removed $InstallDir from user PATH" 'Success'
}

# Revert global configs (optional)
if ($RevertConfigs) {
    Write-Log "Reverting global configs..." 'Info'
    
    $gitExe = "C:\Program Files\Git\bin\git.exe"
    if (Test-Path $gitExe) {
        & $gitExe config --global --unset core.compression 2>$null
        & $gitExe config --global --unset core.preloadIndex 2>$null
        & $gitExe config --global --unset core.fscache 2>$null
        & $gitExe config --global --unset http.postBuffer 2>$null
        & $gitExe config --global --unset http.lowSpeedLimit 2>$null
        & $gitExe config --global --unset http.lowSpeedTime 2>$null
        Write-Log "Git config reverted" 'Success'
    }
    
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm config delete fetch-retries 2>$null
        npm config delete fetch-retry-factor 2>$null
        npm config delete prefer-offline 2>$null
        Write-Log "npm config reverted" 'Success'
    }
    
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        pip config unset global.retries 2>$null
        pip config unset global.timeout 2>$null
        Write-Log "pip config reverted" 'Success'
    }
} else {
    Write-Log "Global configs preserved (use -RevertConfigs to revert)" 'Info'
}

Write-Log "" 'Info'
Write-Log "=== Uninstall Complete ===" 'Success'
Write-Log "" 'Info'
Write-Log "Note: Restart your terminal for PATH changes to take effect." 'Warn'