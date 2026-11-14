#!/usr/bin/env bash
# fast-download uninstaller for Linux/macOS/WSL
# Usage: curl -fsSL https://raw.githubusercontent.com/AbdullahAlHadi/fast-download/main/scripts/uninstall.sh | bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $*"; }
log_success() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $*"; }
log_error() { echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $*"; }

INSTALL_DIR="${HOME}/.fast-download"
REVERT_CONFIGS="${REVERT_CONFIGS:-false}"
FORCE="${FORCE:-false}"

if [[ "$FORCE" != "true" ]]; then
    read -p "This will remove fast-download and all agent configs. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Cancelled"
        exit 0
    fi
fi

log "=== fast-download Uninstaller ==="
log "Install dir: $INSTALL_DIR"

# Agent configurations to remove
declare -A agents=(
    ["OpenCode"]="${HOME}/.config/opencode/skill/fast-download:dir"
    ["Claude Code"]="${HOME}/.claude/agents/fast-download.md:file"
    ["Codex"]="${HOME}/.codex/agents/fast-download.md:file"
    ["Continue"]="${HOME}/.continue/agents/fast-download.yaml:file"
    ["Cline"]="${HOME}/.cline/skills/fast-download:dir"
    ["VS Code"]="${HOME}/.vscode/extensions/fast-download:dir"
    ["Cursor"]="${HOME}/.cursor/extensions/fast-download:dir"
    ["Windsurf"]="${HOME}/.windsurf/extensions/fast-download:dir"
    ["JetBrains AI"]="${HOME}/.config/JetBrains/ai/agents/fast-download.md:file"
    ["Amazon Q"]="${HOME}/.aws/amazonq/agents/fast-download.md:file"
    ["Warp"]="${HOME}/.warp/agents/fast-download.yaml:file"
)

for name in "${!agents[@]}"; do
    IFS=':' read -r path type <<< "${agents[$name]}"
    if [[ -e "$path" ]]; then
        if [[ "$type" == "dir" ]]; then
            rm -rf "$path"
        else
            rm -f "$path"
        fi
        log_success "Removed $name config"
    fi
done

# Remove install directory
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    log_success "Removed $INSTALL_DIR"
fi

# Remove from PATH in shell RC files
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.config/fish/config.fish" "${HOME}/.profile"; do
    if [[ -f "$rc" ]] && grep -q "$INSTALL_DIR" "$rc"; then
        # Remove fast-download lines
        sed -i.bak '/fast-download/d' "$rc"
        sed -i.bak '/\.fast-download/d' "$rc"
        log_success "Removed PATH entry from $rc"
    fi
done

# Revert global configs (optional)
if [[ "$REVERT_CONFIGS" == "true" ]]; then
    log "Reverting global configs..."
    
    if command -v git >/dev/null 2>&1; then
        git config --global --unset core.compression 2>/dev/null || true
        git config --global --unset core.preloadIndex 2>/dev/null || true
        git config --global --unset core.fscache 2>/dev/null || true
        git config --global --unset http.postBuffer 2>/dev/null || true
        git config --global --unset http.lowSpeedLimit 2>/dev/null || true
        git config --global --unset http.lowSpeedTime 2>/dev/null || true
        log_success "Git config reverted"
    fi
    
    if command -v npm >/dev/null 2>&1; then
        npm config delete fetch-retries 2>/dev/null || true
        npm config delete fetch-retry-factor 2>/dev/null || true
        npm config delete prefer-offline 2>/dev/null || true
        log_success "npm config reverted"
    fi
    
    if command -v pip >/dev/null 2>&1; then
        pip config unset global.retries 2>/dev/null || true
        pip config unset global.timeout 2>/dev/null || true
        log_success "pip config reverted"
    fi
else
    log "Global configs preserved (use REVERT_CONFIGS=true to revert)"
fi

echo ""
log_success "=== Uninstall Complete ==="
echo ""
log_warn "Note: Restart your terminal for PATH changes to take effect."
log_warn "Note: Shell RC backups saved as *.bak files"