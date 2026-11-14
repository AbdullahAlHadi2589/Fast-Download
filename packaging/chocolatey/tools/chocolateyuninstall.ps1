$ErrorActionPreference = 'Continue'

$installDir = Join-Path $env:USERPROFILE '.fast-download'

Write-Host "Uninstalling fast-download..." -ForegroundColor Yellow

# Remove agent configurations
$agents = @(
    @{ Name = 'OpenCode'; Path = Join-Path $env:APPDATA 'opencode\skill\fast-download' },
    @{ Name = 'Claude Code'; Path = Join-Path $env:USERPROFILE '.claude\agents\fast-download.md' },
    @{ Name = 'Codex'; Path = Join-Path $env:USERPROFILE '.codex\agents\fast-download.md' },
    @{ Name = 'Continue'; Path = Join-Path $env:USERPROFILE '.continue\agents\fast-download.yaml' },
    @{ Name = 'Cline'; Path = Join-Path $env:USERPROFILE '.cline\skills\fast-download' },
    @{ Name = 'VS Code'; Path = Join-Path $env:USERPROFILE '.vscode\extensions\fast-download' }
)

foreach ($agent in $agents) {
    if (Test-Path $agent.Path) {
        Remove-Item $agent.Path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed $($agent.Name) config" -ForegroundColor Green
    }
}

# Remove install directory
if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed $installDir" -ForegroundColor Green
}

# Remove from user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*$installDir*") {
    $newPath = ($userPath -split ';' | Where-Object { $_ -ne $installDir }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Removed $installDir from user PATH" -ForegroundColor Green
}

Write-Host @"
========================================
fast-download uninstalled successfully!
========================================

Note: Global git/npm/pip configs were NOT reverted.
To reset them manually:
  git config --global --unset core.compression
  git config --global --unset core.preloadIndex
  git config --global --unset core.fscache
  git config --global --unset http.postBuffer
  git config --global --unset http.lowSpeedLimit
  git config --global --unset http.lowSpeedTime
  npm config delete fetch-retries
  npm config delete fetch-retry-factor
  npm config delete prefer-offline
  pip config unset global.retries
  pip config unset global.timeout

Restart your terminal for PATH changes to take effect.
"@ -ForegroundColor Cyan