#!/usr/bin/env bash
# fast-download installer for Linux/macOS/WSL
# Usage: curl -fsSL https://raw.githubusercontent.com/AbdullahAlHadi2589/Fast-Download/master/scripts/install.sh | bash

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
SKIP_NPM_CONFIG="${SKIP_NPM_CONFIG:-false}"
SKIP_PIP_CONFIG="${SKIP_PIP_CONFIG:-false}"
APPLY_GLOBAL_CONFIGS="${APPLY_GLOBAL_CONFIGS:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Dry-run safe helpers
run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: $*"
        return 0
    fi
    "$@"
}

mkdir_p() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: mkdir -p $*"
        return 0
    fi
    mkdir -p "$@"
}

cp_file() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: cp $1 $2"
        return 0
    fi
    cp "$1" "$2"
}

chmod_x() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: chmod +x $1"
        return 0
    fi
    chmod +x "$1"
}

append_to_file() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: append to $1: $2"
        return 0
    fi
    echo "$2" >> "$1"
}

rm_rf() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: rm -rf $*"
        return 0
    fi
    rm -rf "$@"
}

cp_backup() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: cp $1 ${1}.bak (backup)"
        return 0
    fi
    cp "$1" "${1}.bak"
}

write_file() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: write to $1"
        return 0
    fi
    cat > "$1"
}

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
    log "Checking aria2..."
    if has_cmd aria2c; then
        log_success "aria2 already installed: $(aria2c --version | head -1)"
    else
        log "aria2 not found. Installing..."
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

# --- 2. Install Git (if missing) ---
log "Checking Git..."
if has_cmd git; then
    log_success "Git already installed: $(git --version)"
else
    log "Git not found. Installing..."
    case "$PLATFORM" in
        macos)
            if has_cmd brew; then
                brew install git
                log_success "Git installed via Homebrew"
            else
                log_error "Homebrew not found. Install from https://brew.sh/"
            fi
            ;;
        linux)
            if has_cmd apt; then
                sudo apt update && sudo apt install -y git
                log_success "Git installed via apt"
            elif has_cmd dnf; then
                sudo dnf install -y git
                log_success "Git installed via dnf"
            elif has_cmd pacman; then
                sudo pacman -S --noconfirm git
                log_success "Git installed via pacman"
            elif has_cmd zypper; then
                sudo zypper install -y git
                log_success "Git installed via zypper"
            else
                log_error "No supported package manager found. Install Git manually."
            fi
            ;;
        windows)
            log_warn "On Windows, run install.ps1 instead"
            ;;
    esac
fi

# --- 3. Create install directory ---
if [[ ! -d "$INSTALL_DIR" ]]; then
    mkdir_p "$INSTALL_DIR"
    log_success "Created $INSTALL_DIR"
fi

# --- 4. Copy universal shell libraries ---
cp_file "$REPO_ROOT/src/fast-download.sh" "$INSTALL_DIR/fast-download.sh"
chmod_x "$INSTALL_DIR/fast-download.sh"
log_success "Copied fast-download.sh"

if [[ -f "$REPO_ROOT/src/fast-download.fish" ]]; then
    cp_file "$REPO_ROOT/src/fast-download.fish" "$INSTALL_DIR/fast-download.fish"
    log_success "Copied fast-download.fish"
fi
if [[ -f "$REPO_ROOT/src/fast-download.nu" ]]; then
    cp_file "$REPO_ROOT/src/fast-download.nu" "$INSTALL_DIR/fast-download.nu"
    log_success "Copied fast-download.nu (nushell)"
fi

# --- 5. Copy PowerShell module ---
if [[ -f "$REPO_ROOT/opencode/FastDownload.psm1" ]]; then
    cp_file "$REPO_ROOT/opencode/FastDownload.psm1" "$INSTALL_DIR/FastDownload.psm1"
    log_success "Copied FastDownload.psm1"
fi

# --- 6. Apply global configs (OPT-IN ONLY with APPLY_GLOBAL_CONFIGS=true) ---
if [[ "$APPLY_GLOBAL_CONFIGS" == "true" ]]; then
    log "Applying global optimizations (opt-in)..."
    
    if has_cmd git; then
        log "Applying Git optimizations..."
        run_cmd git config --global core.compression 9
        run_cmd git config --global core.preloadIndex true
        run_cmd git config --global core.fscache true
        run_cmd git config --global http.postBuffer 524288000
        run_cmd git config --global http.lowSpeedLimit 0
        run_cmd git config --global http.lowSpeedTime 999999
        log_success "Git config applied"
    else
        log_warn "Git not found, skipping Git config"
    fi

    if has_cmd npm; then
        log "Applying npm optimizations..."
        run_cmd npm config set fetch-retries 5
        run_cmd npm config set fetch-retry-factor 2
        run_cmd npm config set prefer-offline true
        log_success "npm config applied"
    fi

    if has_cmd pip; then
        log "Applying pip optimizations..."
        run_cmd pip config set global.retries 5
        run_cmd pip config set global.timeout 60
        log_success "pip config applied"
    fi
else
    log "Skipping global configs (set APPLY_GLOBAL_CONFIGS=true to enable)"
fi

# --- 7. Deploy agent configurations ---
deploy_agents=()
if [[ "$AGENT" == "all" ]]; then
    deploy_agents=(opencode claude-code codex continue cline vscode cursor windsurf jetbrains amazon-q warp)
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
                mkdir_p "$target"
                run_cmd cp -r "$source"/* "$target/"
                log_success "OpenCode skill deployed to $target"
            fi
            ;;
        claude-code)
            target="${HOME}/.claude/agents"
            source="$REPO_ROOT/claude-code/fast-download.md"
            if [[ -f "$source" ]]; then
                mkdir_p "$target"
                cp_file "$source" "$target/"
                log_success "Claude Code agent deployed to $target"
            fi
            ;;
        codex)
            target="${HOME}/.codex/agents"
            source="$REPO_ROOT/codex/fast-download.md"
            if [[ -f "$source" ]]; then
                mkdir_p "$target"
                cp_file "$source" "$target/"
                log_success "Codex agent deployed to $target"
            fi
            ;;
        continue)
            target="${HOME}/.continue/agents"
            source="$REPO_ROOT/continue/fast-download.yaml"
            if [[ -f "$source" ]]; then
                mkdir_p "$target"
                cp_file "$source" "$target/"
                log_success "Continue agent deployed to $target"
            fi
            ;;
        cline)
            target="${HOME}/.cline/skills/fast-download"
            source="$REPO_ROOT/cline/fast-download"
            if [[ -d "$source" ]]; then
                mkdir_p "$target"
                run_cmd cp -r "$source"/* "$target/"
                log_success "Cline skill deployed to $target"
            fi
            ;;
        vscode)
            target="${HOME}/.vscode/extensions/fast-download"
            source="$REPO_ROOT/vscode/fast-download"
            if [[ -d "$source" ]]; then
                mkdir_p "$target"
                run_cmd cp -r "$source"/* "$target/"
                log_success "VS Code skill deployed to $target"
            fi
            ;;
        cursor)
            target="${HOME}/.cursor/extensions/fast-download"
            source="$REPO_ROOT/vscode/fast-download"
            if [[ -d "$source" ]]; then
                mkdir_p "$target"
                run_cmd cp -r "$source"/* "$target/"
                log_success "Cursor skill deployed to $target"
            fi
            ;;
        windsurf)
            target="${HOME}/.windsurf/extensions/fast-download"
            source="$REPO_ROOT/vscode/fast-download"
            if [[ -d "$source" ]]; then
                mkdir_p "$target"
                run_cmd cp -r "$source"/* "$target/"
                log_success "Windsurf skill deployed to $target"
            fi
            ;;
        jetbrains)
            target="${HOME}/.config/JetBrains/ai/agents"
            source="$REPO_ROOT/jetbrains/fast-download.md"
            if [[ -f "$source" ]]; then
                mkdir_p "$target"
                cp_file "$source" "$target/"
                log_success "JetBrains AI agent deployed to $target"
            fi
            ;;
        amazon-q)
            target="${HOME}/.aws/amazonq/agents"
            source="$REPO_ROOT/amazon-q/fast-download.md"
            if [[ -f "$source" ]]; then
                mkdir_p "$target"
                cp_file "$source" "$target/"
                log_success "Amazon Q agent deployed to $target"
            fi
            ;;
        warp)
            target="${HOME}/.warp/agents"
            source="$REPO_ROOT/warp/fast-download.yaml"
            if [[ -f "$source" ]]; then
                mkdir_p "$target"
                cp_file "$source" "$target/"
                log_success "Warp agent deployed to $target"
            fi
            ;;
    esac
done

log_success "=== Installation Complete ==="
log "Installed to: $INSTALL_DIR"
log "Add to PATH: $INSTALL_DIR"
log "Usage: source fast-download.sh; fd_download \"url\" \"output\" [checksum]"