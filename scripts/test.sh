#!/usr/bin/env bash
# Test suite for fast-download
# Run from repo root: bash scripts/test.sh

# set -euo pipefail  # Disabled for debugging
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

log() { echo -e "${CYAN}[TEST]${NC} $*"; }
pass() { echo -e "${GREEN}[PASS]${NC} $*"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${NC} $*"; ((FAIL++)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="/tmp/fast-download-test-$$"
mkdir -p "$TEST_DIR"

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# --- Test 1: Shell library syntax ---
log "Test 1: Shell library syntax"
if bash -n "$REPO_ROOT/src/fast-download.sh"; then
    pass "fast-download.sh syntax OK"
else
    fail "fast-download.sh syntax error"
fi

# --- Test 2: Install script syntax ---
log "Test 2: Install script syntax"
if bash -n "$REPO_ROOT/scripts/install.sh"; then
    pass "install.sh syntax OK"
else
    fail "install.sh syntax error"
fi

# --- Test 3: Shell library syntax (fish) ---
log "Test 3: Fish shell library syntax"
if command -v fish >/dev/null 2>&1; then
    if fish -n "$REPO_ROOT/src/fast-download.fish" 2>/dev/null; then
        pass "fast-download.fish syntax OK"
    else
        fail "fast-download.fish syntax error"
    fi
else
    warn "fish not installed, skipping fish syntax check"
fi

# --- Test 4: Shell library syntax (nushell) ---
log "Test 4: Nushell library syntax"
if command -v nu >/dev/null 2>&1; then
    if nu --parse "$REPO_ROOT/src/fast-download.nu" 2>/dev/null; then
        pass "fast-download.nu syntax OK"
    else
        fail "fast-download.nu syntax error"
    fi
else
    warn "nu not installed, skipping nushell syntax check"
fi

# --- Test 5: Source shell library (bash) ---
log "Test 5: Source shell library (bash)"
if source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null; then
    pass "fast-download.sh sources cleanly"
else
    fail "fast-download.sh source failed"
fi

# --- Test 6: Functions exported (bash) ---
log "Test 6: Functions exported (bash)"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
for fn in fd_download fd_git_clone fd_verify fd_speed_test fd_init; do
    if declare -f "$fn" >/dev/null; then
        pass "Function $fn exported"
    else
        fail "Function $fn NOT exported"
    fi
done

# --- Test 7: Source shell library (fish) ---
log "Test 7: Source shell library (fish)"
if command -v fish >/dev/null 2>&1; then
    if fish -c "source '$REPO_ROOT/src/fast-download.fish'; functions -q fd_download" 2>/dev/null; then
        pass "fast-download.fish sources cleanly"
    else
        fail "fast-download.fish source failed"
    fi
else
    warn "fish not installed, skipping fish source test"
fi

# --- Test 8: Functions exported (fish) ---
log "Test 8: Functions exported (fish)"
if command -v fish >/dev/null 2>&1; then
    for fn in fd_download fd_git_clone fd_verify fd_speed_test fd_init; do
        if fish -c "source '$REPO_ROOT/src/fast-download.fish'; functions -q $fn" 2>/dev/null; then
            pass "Fish function $fn exported"
        else
            fail "Fish function $fn NOT exported"
        fi
    done
else
    warn "fish not installed, skipping fish function tests"
fi

# --- Test 9: Tool detection ---
log "Test 9: Tool detection"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
for tool in aria2c git curl; do
    if command -v "$tool" >/dev/null 2>&1; then
        pass "$tool available"
    else
        warn "$tool not installed (will be installed by installer)"
    fi
done

# --- Test 10: Download with aria2 (small file) ---
log "Test 10: aria2 download (small file)"
if command -v aria2c >/dev/null 2>&1; then
    cd "$TEST_DIR"
    if aria2c -x 4 -s 4 -k 1M --file-allocation=none --continue=true \
        -o test.zip "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" 2>&1 | tail -5; then
        if [[ -f test.zip && $(stat -c%s test.zip 2>/dev/null || stat -f%z test.zip) -gt 1000000 ]]; then
            pass "aria2 download works ($(du -h test.zip | cut -f1))"
        else
            fail "aria2 download produced empty/small file"
        fi
    else
        fail "aria2 download failed"
    fi
else
    warn "aria2c not installed, skipping download test"
fi

# --- Test 11: Git shallow clone ---
log "Test 11: Git shallow clone"
if command -v git >/dev/null 2>&1; then
    cd "$TEST_DIR"
    if git clone --depth 1 --single-branch --filter=blob:none https://github.com/git/git.git git-shallow-test 2>&1 | tail -3; then
        if [[ -d git-shallow-test/.git ]]; then
            size=$(du -sh git-shallow-test 2>/dev/null | cut -f1)
            pass "Shallow clone works ($size)"
        else
            fail "Shallow clone directory missing"
        fi
    else
        fail "Shallow clone failed"
    fi
else
    warn "git not installed, skipping clone test"
fi

# --- Test 12: Checksum verification ---
log "Test 12: Checksum verification"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
echo "test content" > "$TEST_DIR/checksum-test.txt"
expected=$(sha256sum "$TEST_DIR/checksum-test.txt" | cut -d' ' -f1)
if fd_verify "$TEST_DIR/checksum-test.txt" "$expected" 2>&1; then
    pass "Checksum verification works"
else
    fail "Checksum verification failed"
fi

# Wrong checksum
wrong="0000000000000000000000000000000000000000000000000000000000000000"
if ! fd_verify "$TEST_DIR/checksum-test.txt" "$wrong" 2>/dev/null; then
    pass "Checksum mismatch correctly detected"
else
    fail "Checksum mismatch NOT detected"
fi

# --- Test 9: Agent config files exist ---
log "Test 9: Agent config files exist"
agents=(
    "opencode/skill.json"
    "opencode/instructions.md"
    "claude-code/fast-download.md"
    "codex/fast-download.md"
    "continue/fast-download.yaml"
    "cline/fast-download/skill.json"
    "cline/fast-download/instructions.md"
    "vscode/fast-download/skill.json"
    "vscode/fast-download/instructions.md"
    "cursor/fast-download/skill.json"
    "cursor/fast-download/instructions.md"
    "windsurf/fast-download/skill.json"
    "windsurf/fast-download/instructions.md"
    "jetbrains/fast-download.md"
    "amazon-q/fast-download.md"
    "warp/fast-download.yaml"
)
for f in "${agents[@]}"; do
    if [[ -f "$REPO_ROOT/$f" ]]; then
        pass "Agent config: $f"
    else
        fail "Missing agent config: $f"
    fi
done

# --- Test 13: Core docs exist ---
log "Test 13: Core documentation"
docs=(
    "README.md"
    "LICENSE"
    "CONTRIBUTING.md"
    "CODE_OF_CONDUCT.md"
    "CHANGELOG.md"
    "docs/PERFORMANCE_REPORT.md"
    "docs/AGENT_SETUP.md"
)
for f in "${docs[@]}"; do
    if [[ -f "$REPO_ROOT/$f" ]]; then
        pass "Doc: $f"
    else
        fail "Missing doc: $f"
    fi
done

# --- Test 14: PowerShell module syntax ---
log "Test 14: PowerShell module syntax"
if command -v pwsh >/dev/null 2>&1; then
    if pwsh -NoProfile -Command "Import-Module '$REPO_ROOT/opencode/FastDownload.psm1' -Force; Initialize-FastDownload" 2>&1 | grep -q "aria2c"; then
        pass "PowerShell module loads"
    else
        fail "PowerShell module load failed"
    fi
else
    warn "pwsh not available, skipping PS module test"
fi

# --- Summary ---
echo ""
echo "===================="
echo "Results: $PASS passed, $FAIL failed"
echo "===================="
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi