<#PSScriptInfo
.VERSION 1.0.0
.GUID 87654321-4321-4321-4321-210987654321
.AUTHOR Abdullah Al Hadi
.COPYRIGHT (c) 2026 Abdullah Al Hadi
.LICENSEURI https://opensource.org/licenses/MIT
.PROJECTURI https://github.com/AbdullahAlHadi2589/Fast-Download
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
    [switch]$DryRun,
    [string]$InstallDir = "$env:USERPROFILE\.fast-download"
)

function Write-Log {
    param([string]$Message, [ValidateSet('Info','Warn','Error','Success')][string]$Level = 'Info')
    $colors = @{ Info='Cyan'; Warn='Yellow'; Error='Red'; Success='Green' }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
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

function Remove-ItemSafe {
    param([string]$Path, [switch]$Recurse)
    $params = @{ Path = $Path; Force = $true; ErrorAction = 'SilentlyContinue' }
    if ($Recurse) { $params.Recurse = $true }
    $desc = "Remove-Item $Path"
    if ($Recurse) { $desc += " -Recurse" }
    Invoke-DryRunSafe { Remove-Item @params } $desc
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
            Remove-ItemSafe -Path $agent.Path -Recurse
        } else {
            Remove-ItemSafe -Path $agent.Path
        }
        Write-Log "Removed $($agent.Name) config" 'Success'
    }
}

# Remove install directory
if (Test-Path $InstallDir) {
    Remove-ItemSafe -Path $InstallDir -Recurse
    Write-Log "Removed $InstallDir" 'Success'
}

# Remove from user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*$InstallDir*") {
    Invoke-DryRunSafe {
        $newPath = ($userPath -split ';' | Where-Object { $_ -ne $InstallDir }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    } "Remove $InstallDir from user PATH"
    Write-Log "Removed $InstallDir from user PATH" 'Success'
}

# Revert global configs (optional)
if ($RevertConfigs) {
    Write-Log "Reverting global configs..." 'Info'
    
    # Use the same Find-Git function from install.ps1
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitExe = $gitCmd.Source
    } else {
        $commonPaths = @(
            "C:\Program Files\Git\bin\git.exe",
            "C:\Program Files (x86)\Git\bin\git.exe",
            "$env:LOCALAPPDATA\Programs\Git\bin\git.exe",
            "$env:USERPROFILE\AppData\Local\Programs\Git\bin\git.exe",
            "$env:ProgramFiles\Git\bin\git.exe"
        )
        foreach ($path in $commonPaths) {
            if (Test-Path $path) { $gitExe = $path; break }
        }
    }
    
    if ($gitExe) {
        Invoke-DryRunSafe { & $gitExe config --global --unset core.compression 2>$null } "git config --global --unset core.compression"
        Invoke-DryRunSafe { & $gitExe config --global --unset core.preloadIndex 2>$null } "git config --global --unset core.preloadIndex"
        Invoke-DryRunSafe { & $gitExe config --global --unset core.fscache 2>$null } "git config --global --unset core.fscache"
        Invoke-DryRunSafe { & $gitExe config --global --unset http.postBuffer 2>$null } "git config --global --unset http.postBuffer"
        Invoke-DryRunSafe { & $gitExe config --global --unset http.lowSpeedLimit 2>$null } "git config --global --unset http.lowSpeedLimit"
        Invoke-DryRunSafe { & $gitExe config --global --unset http.lowSpeedTime 2>$null } "git config --global --unset http.lowSpeedTime"
        Write-Log "Git config reverted" 'Success'
    }
    
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Invoke-DryRunSafe { npm config delete fetch-retries 2>$null } "npm config delete fetch-retries"
        Invoke-DryRunSafe { npm config delete fetch-retry-factor 2>$null } "npm config delete fetch-retry-factor"
        Invoke-DryRunSafe { npm config delete prefer-offline 2>$null } "npm config delete prefer-offline"
        Write-Log "npm config reverted" 'Success'
    }
    
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        Invoke-DryRunSafe { pip config unset global.retries 2>$null } "pip config unset global.retries"
        Invoke-DryRunSafe { pip config unset global.timeout 2>$null } "pip config unset global.timeout"
        Write-Log "pip config reverted" 'Success'
    }
} else {
    Write-Log "Global configs preserved (use -RevertConfigs to revert)" 'Info'
}

Write-Log "" 'Info'
Write-Log "=== Uninstall Complete ===" 'Success'
Write-Log "" 'Info'
Write-Log "Note: Restart your terminal for PATH changes to take effect." 'Warn'