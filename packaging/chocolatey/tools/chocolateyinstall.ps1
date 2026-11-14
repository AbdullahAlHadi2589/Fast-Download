$ErrorActionPreference = 'Stop'

$packageName = 'fast-download'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$installDir = Join-Path $env:USERPROFILE '.fast-download'

# Create install directory
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Copy shell library
Copy-Item (Join-Path $toolsDir 'src\fast-download.sh') (Join-Path $installDir 'fast-download.sh') -Force

# Copy agent configurations
$agents = @('opencode', 'claude-code', 'codex', 'continue', 'cline', 'vscode')
foreach ($agent in $agents) {
    $source = Join-Path $toolsDir $agent
    if (Test-Path $source) {
        $target = switch ($agent) {
            'opencode' { Join-Path $env:APPDATA 'opencode\skill\fast-download' }
            'claude-code' { Join-Path $env:USERPROFILE '.claude\agents\fast-download.md' }
            'codex' { Join-Path $env:USERPROFILE '.codex\agents\fast-download.md' }
            'continue' { Join-Path $env:USERPROFILE '.continue\agents\fast-download.yaml' }
            'cline' { Join-Path $env:USERPROFILE '.cline\skills\fast-download' }
            'vscode' { Join-Path $env:USERPROFILE '.vscode\extensions\fast-download' }
        }
        
        if ($agent -in @('claude-code', 'codex', 'continue')) {
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            Copy-Item (Join-Path $source '*') $target -Force
        } else {
            if (Test-Path $target) { Remove-Item $target -Recurse -Force }
            Copy-Item $source $target -Recurse -Force
        }
    }
}

# Copy PowerShell module
Copy-Item (Join-Path $toolsDir 'opencode\FastDownload.psm1') (Join-Path $installDir 'FastDownload.psm1') -Force

# Copy install/uninstall scripts
Copy-Item (Join-Path $toolsDir 'install.ps1') (Join-Path $installDir 'install.ps1') -Force
Copy-Item (Join-Path $toolsDir 'uninstall.ps1') (Join-Path $installDir 'uninstall.ps1') -Force

# Add to user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
    Write-Host "Added $installDir to user PATH" -ForegroundColor Green
}

# Apply global configs
$gitExe = "C:\Program Files\Git\bin\git.exe"
if (Test-Path $gitExe) {
    & $gitExe config --global core.compression 9
    & $gitExe config --global core.preloadIndex true
    & $gitExe config --global core.fscache true
    & $gitExe config --global http.postBuffer 524288000
    & $gitExe config --global http.lowSpeedLimit 0
    & $gitExe config --global http.lowSpeedTime 999999
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm config set fetch-retries 5
    npm config set fetch-retry-factor 2
    npm config set prefer-offline true
}

if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip config set global.retries 5
    pip config set global.timeout 60
}

Write-Host @"
========================================
fast-download installed successfully!
========================================

Next steps:
1. RESTART YOUR TERMINAL / POWERSHELL / VS CODE
2. Test: aria2c --version
3. Use in any terminal:
   aria2c -x 16 -s 16 -o "file.zip" "https://url/file.zip"
   git clone --depth 1 --filter=blob:none https://github.com/user/repo.git

PowerShell module: Import-Module $installDir\FastDownload.psm1
Bash/WSL: source $installDir\fast-download.sh

Agent configs deployed:
- OpenCode: $env:APPDATA\opencode\skill\fast-download
- Claude Code: $env:USERPROFILE\.claude\agents\fast-download.md
- Codex: $env:USERPROFILE\.codex\agents\fast-download.md
- Continue: $env:USERPROFILE\.continue\agents\fast-download.yaml
- Cline: $env:USERPROFILE\.cline\skills\fast-download
- VS Code: $env:USERPROFILE\.vscode\extensions\fast-download

Documentation: https://github.com/AbdullahAlHadi2589/Fast-Download
"@ -ForegroundColor Cyan