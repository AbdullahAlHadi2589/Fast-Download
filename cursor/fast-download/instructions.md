# Fast Download Skill for Cursor

## Purpose
Download accelerator for Cursor terminal tasks. Use aria2 (16 connections), Git shallow clones, smart fallbacks.

## Quick Commands

### Terminal (Ctrl+`)
```bash
# Large file - full speed
aria2c -x 16 -s 16 -k 1M --continue=true -o "file.zip" "https://url"

# With SHA256 verification
aria2c --checksum=sha256=abc123... -x 16 -s 16 -o "file.zip" "https://url"

# GitHub / rate-limited
aria2c -x 4 -s 4 -k 1M --continue=true -o "file.zip" "https://github.com/..."

# Fallback
curl -L -C - -o "file.zip" "https://url"

# Git shallow (default)
git clone --depth 1 --single-branch --filter=blob:none https://github.com/user/repo.git
```

### Tasks (Terminal > Run Task)
Create `.cursor/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "fast-download: aria2",
      "type": "shell",
      "command": "aria2c -x 16 -s 16 -k 1M --continue=true -o \"${input:outputFile}\" \"${input:url}\"",
      "problemMatcher": []
    },
    {
      "label": "fast-download: git-shallow",
      "type": "shell",
      "command": "git clone --depth 1 --single-branch --filter=blob:none \"${input:repoUrl}\" \"${input:outputDir}\"",
      "problemMatcher": []
    }
  ],
  "inputs": [
    {"id": "url", "type": "promptString", "description": "Download URL"},
    {"id": "outputFile", "type": "promptString", "description": "Output filename"},
    {"id": "repoUrl", "type": "promptString", "description": "Git repository URL"},
    {"id": "outputDir", "type": "promptString", "description": "Output directory"}
  ]
}
```

## Auto-config (run once in terminal)
```bash
git config --global core.compression 9
git config --global core.preloadIndex true
git config --global http.postBuffer 524288000
npm config set fetch-retries 5
npm config set prefer-offline true
pip config set global.retries 5
```

## Verification
```bash
# PowerShell
Get-FileHash -Algorithm SHA256 file.zip

# Bash
sha256sum file.zip
```