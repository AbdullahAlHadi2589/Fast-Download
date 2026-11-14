#!/usr/bin/env bash
# fast-download installer for Linux/macOS/WSL
# Usage: curl -fsSL https://raw.githubusercontent.com/yourusername/fast-download/main/scripts/install.sh | bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $*"; }
log_success() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $*"; }
log_error() { echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $*"; }

# Config
INSTALL_DIR="${HOME}/.fast-download"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="${1:-all}"
FORCE="${FORCE:-false}"
SKIP_ARIA2="${SKIP_ARIA2:-false}"
SKIP_GIT_CONFIG="${SKIP_GIT_CONFIG:-false}"
SKIP_NPM_CONFIG="${SKIP_NPM_CONFIG:-false}"
SKIP_PIP_CONFIG="${SKIP_PIP_CONFIG:-false}"

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="macos" ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
    *)          PLATFORM="unknown" ;;
esac

log "=== fast-download Installer ==="
log "Platform: $PLATFORM ($OS)"
log "Install dir: $INSTALL_DIR"
log "Agent: $AGENT"

# --- Helper: check command ---
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- 1. Install aria2 ---
if [[ "$SKIP_ARIA2" != "true" ]]; then
    log "Installing aria2..."
    if has_cmd aria2c; then
        log_success "aria2 already installed: $(aria2c --version | head -1)"
    else
        case "$PLATFORM" in
            macos)
                if has_cmd brew; then
                    brew install aria2
                    log_success "aria2 installed via Homebrew"
                else
                    log_error "Homebrew not found. Install from https://brew.sh/"
                fi
                ;;
            linux)
                if has_cmd apt; then
                    sudo apt update && sudo apt install -y aria2
                    log_success "aria2 installed via apt"
                elif has_cmd dnf; then
                    sudo dnf install -y aria2
                    log_success "aria2 installed via dnf"
                elif has_cmd pacman; then
                    sudo pacman -S --noconfirm aria2
                    log_success "aria2 installed via pacman"
                elif has_cmd zypper; then
                    sudo zypper install -y aria2
                    log_success "aria2 installed via zypper"
                else
                    log_error "No supported package manager found. Install aria2 manually."
                fi
                ;;
            windows)
                log_warn "On Windows, run install.ps1 instead"
                ;;
        esac
    fi
fi

# --- 2. Install Git ---
if has_cmd git; then
    log_success "Git found: $(git --version)"
else
    log "Installing Git..."
    case "$PLATFORM" in
        macos)
            if has_cmd brew; then brew install git; log_success "Git installed"; fi
            ;;
        linux)
            if has_cmd apt; then sudo apt install -y git; log_success "Git installed"; fi
            ;;
    esac
fi

# --- 3. Create install directory ---
mkdir -p "$INSTALL_DIR"
log "Created $INSTALL_DIR"

# --- 4. Copy universal shell library ---
if [[ -f "$REPO_ROOT/src/fast-download.sh" ]]; then
    cp "$REPO_ROOT/src/fast-download.sh" "$INSTALL_DIR/fast-download.sh"
    chmod +x "$INSTALL_DIR/fast-download.sh"
    log_success "Copied fast-download.sh"
fi

# --- 5. Apply global configs ---
if [[ "$SKIP_GIT_CONFIG" != "true" ]] && has_cmd git; then
    log "Applying Git optimizations..."
    git config --global core.compression 9
    git config --global core.preloadIndex true
    git config --global core.fscache true
    git config --global http.postBuffer 524288000
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999
    log_success "Git config applied"
fi

if [[ "$SKIP_NPM_CONFIG" != "true" ]] && has_cmd npm; then
    log "Applying npm optimizations..."
    npm config set fetch-retries 5
    npm config set fetch-retry-factor 2
    npm config set prefer-offline true
    log_success "npm config applied"
fi

if [[ "$SKIP_PIP_CONFIG" != "true" ]] && has_cmd pip; then
    log "Applying pip optimizations..."
    pip config set global.retries 5
    pip config set global.timeout 60
    log_success "pip config applied"
fi

# --- 6. Deploy agent configurations ---
deploy_agents=()
if [[ "$AGENT" == "all" ]]; then
    deploy_agents=(opencode claude-code codex continue cline vscode)
else
    deploy_agents=("$AGENT")
fi

for a in "${deploy_agents[@]}"; do
    log "Deploying $a configuration..."
    case "$a" in
        opencode)
            target="${HOME}/.config/opencode/skill/fast-download"
            source="$REPO_ROOT/opencode"
            if [[ -d "$source" ]]; then
                mkdir -p "$target"
                cp -r "$source"/* "$target/"
                log_success "OpenCode skill deployed to $target"
            fi
            ;;
        claude-code)
            target="${HOME}/.claude/agents/fast-download.md"
            source="$REPO_ROOT/claude-code/fast-download.md"
            mkdir -p "$(dirname "$target")"
            if [[ -f "$source" ]]; then
                cp "$source" "$target"
                log_success "Claude Code agent deployed to $target"
            fi
            ;;
        codex)
            target="${HOME}/.codex/agents/fast-download.md"
            source="$REPO_ROOT/codex/fast-download.md"
            mkdir -p "$(dirname "$target")"
            if [[ -f "$source" ]]; then
                cp "$source" "$target"
                log_success "Codex agent deployed to $target"
            fi
            ;;
        continue)
            target="${HOME}/.continue/agents/fast-download.yaml"
            source="$REPO_ROOT/continue/fast-download.yaml"
            mkdir -p "$(dirname "$target")"
            if [[ -f "$source" ]]; then
                cp "$source" "$target"
                log_success "Continue agent deployed to $target"
            fi
            ;;
        cline)
            target="${HOME}/.cline/skills/fast-download"
            source="$REPO_ROOT/cline/fast-download"
            if [[ -d "$source" ]]; then
                mkdir -p "$target"
                cp -r "$source"/* "$target/"
                log_success "Cline skill deployed to $target"
            fi
            ;;
        vscode)
            target="${HOME}/.vscode/extensions/fast-download"
            source="$REPO_ROOT/vscode/fast-download"
            if [[ -d "$source" ]]; then
                mkdir -p "$target"
                cp -r "$source"/* "$target/"
                log_success "VS Code skill deployed to $target"
            fi
            ;;
    esac
done

# --- 7. Add to PATH ---
shell_rc=""
case "$SHELL" in
    */zsh) shell_rc="${HOME}/.zshrc" ;;
    */bash) shell_rc="${HOME}/.bashrc" ;;
    */fish) shell_rc="${HOME}/.config/fish/config.fish" ;;
    *) shell_rc="${HOME}/.profile" ;;
esac

path_entry="export PATH=\"\$PATH:$INSTALL_DIR\""
if [[ -f "$shell_rc" ]] && ! grep -q "$INSTALL_DIR" "$shell_rc"; then
    echo "" >> "$shell_rc"
    echo "# fast-download" >> "$shell_rc"
    echo "$path_entry" >> "$shell_rc"
    log_success "Added $INSTALL_DIR to PATH in $shell_rc"
elif [[ ! -f "$shell_rc" ]]; then
    echo "$path_entry" > "$shell_rc"
    log_success "Created $shell_rc with PATH entry"
else
    log "PATH already configured in $shell_rc"
fi

# --- 8. Verify ---
log "=== Verification ==="
for t in aria2c git curl; do
    if has_cmd "$t"; then
        log_success "$t: Available"
    else
        log_warn "$t: NOT FOUND"
    fi
done

# --- 9. Final message ---
echo ""
log_success "=== Installation Complete ==="
echo ""
log "Next steps:"
log "  1. RESTART YOUR TERMINAL or run: source $shell_rc"
log "  2. Test: aria2c --version"
log "  3. Use in any terminal:"
log '     aria2c -x 16 -s 16 -o "file.zip" "https://url/file.zip"'
log '     git clone --depth 1 --filter=blob:none https://github.com/user/repo.git'
echo ""
log "Bash/WSL: source $INSTALL_DIR/fast-download.sh"
log "Then use: fd_download \"url\" \"output\" [checksum]"
echo ""
log "Agent configs deployed:"
for a in "${deploy_agents[@]}"; do
    log "  - $a"
done
echo ""
log_warn "IMPORTANT: Restart your terminal for PATH changes to take effect."