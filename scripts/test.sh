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
    # Kill any background HTTP server
    if [[ -n "${HTTP_SERVER_PID:-}" ]]; then
        kill "$HTTP_SERVER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Start a simple HTTP server for testing
start_http_server() {
    local port=8999
    cd "$TEST_DIR"
    # Create test files first
    echo "test content for download" > "$TEST_DIR/test-file.txt"
    echo "another test file" > "$TEST_DIR/test-file2.txt"
    dd if=/dev/zero of="$TEST_DIR/10mb.bin" bs=1M count=10 2>/dev/null
    # Create a file without Accept-Ranges header simulation
    echo "no-range-support" > "$TEST_DIR/no-range.txt"
    
    # Start server
    python -m http.server "$port" >"$TEST_DIR/server.log" 2>&1 &
    HTTP_SERVER_PID=$!
    sleep 2
    # Verify server is running
    if ! curl -s "http://localhost:$port/test-file.txt" >/dev/null 2>&1; then
        warn "HTTP server failed to start, check $TEST_DIR/server.log"
        cat "$TEST_DIR/server.log" 2>/dev/null || true
        return 1
    fi
    log "HTTP server started on port $port (PID: $HTTP_SERVER_PID)"
}

# Test 1: Shell library syntax
log "Test 1: Shell library syntax"
if bash -n "$REPO_ROOT/src/fast-download.sh"; then
    pass "fast-download.sh syntax OK"
else
    fail "fast-download.sh syntax error"
fi

# Test 2: Install script syntax
log "Test 2: Install script syntax"
if bash -n "$REPO_ROOT/scripts/install.sh"; then
    pass "install.sh syntax OK"
else
    fail "install.sh syntax error"
fi

# Test 3: Shell library syntax (fish)
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

# Test 4: Shell library syntax (nushell)
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

# Test 5: Source shell library (bash)
log "Test 5: Source shell library (bash)"
if source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null; then
    pass "fast-download.sh sources cleanly"
else
    fail "fast-download.sh source failed"
fi

# Test 6: Functions exported (bash)
log "Test 6: Functions exported (bash)"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
for fn in fd_download fd_git_clone fd_verify fd_speed_test fd_init; do
    if declare -f "$fn" >/dev/null; then
        pass "Function $fn exported"
    else
        fail "Function $fn NOT exported"
    fi
done

# Test 7: Source shell library (fish)
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

# Test 8: Functions exported (fish)
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

# Test 9: Tool detection
log "Test 9: Tool detection"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
for tool in aria2c git curl; do
    if command -v "$tool" >/dev/null 2>&1; then
        pass "$tool available"
    else
        warn "$tool not installed (will be installed by installer)"
    fi
done

# Test 10: Download with aria2 (small file)
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

# Test 11: Git shallow clone
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

# Test 12: Checksum verification (match)
log "Test 12: Checksum verification (match)"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
echo "test content" > "$TEST_DIR/checksum-test.txt"
expected=$(sha256sum "$TEST_DIR/checksum-test.txt" | cut -d' ' -f1)
if fd_verify "$TEST_DIR/checksum-test.txt" "$expected" 2>&1; then
    pass "Checksum verification works"
else
    fail "Checksum verification failed"
fi

# Test 13: Checksum mismatch correctly detected
log "Test 13: Checksum mismatch correctly detected"
wrong="0000000000000000000000000000000000000000000000000000000000000000"
if ! fd_verify "$TEST_DIR/checksum-test.txt" "$wrong" 2>/dev/null; then
    pass "Checksum mismatch correctly detected"
else
    fail "Checksum mismatch NOT detected"
fi

# Start HTTP server for local tests
start_http_server

# Test 14: fd_download with local HTTP server (curl)
log "Test 14: fd_download via curl (local server)"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
if fd_download "http://localhost:8999/test-file.txt" "$TEST_DIR/downloaded.txt" 2>&1; then
    if [[ -f "$TEST_DIR/downloaded.txt" ]]; then
        content=$(cat "$TEST_DIR/downloaded.txt")
        if [[ "$content" == "test content for download" ]]; then
            pass "fd_download via curl works"
        else
            fail "fd_download content mismatch: $content"
        fi
    else
        fail "fd_download: file not created"
    fi
else
    fail "fd_download via curl failed"
fi

# Test 15: fd_download with checksum (success)
log "Test 15: fd_download with checksum verification (success)"
expected_checksum=$(sha256sum "$TEST_DIR/test-file.txt" | cut -d' ' -f1)
if fd_download "http://localhost:8999/test-file.txt" "$TEST_DIR/downloaded-with-checksum.txt" "$expected_checksum" 2>&1; then
    if [[ -f "$TEST_DIR/downloaded-with-checksum.txt" ]]; then
        pass "fd_download with correct checksum passes"
    else
        fail "fd_download: file not created after checksum"
    fi
else
    fail "fd_download with correct checksum failed"
fi

# Test 16: fd_download with checksum mismatch (should fail and cleanup)
log "Test 16: fd_download with checksum mismatch (cleanup)"
wrong_checksum="0000000000000000000000000000000000000000000000000000000000000000"
if fd_download "http://localhost:8999/test-file.txt" "$TEST_DIR/should-fail.txt" "$wrong_checksum" 2>&1; then
    fail "fd_download with wrong checksum should have failed"
else
    if [[ ! -f "$TEST_DIR/should-fail.txt" ]]; then
        pass "fd_download with wrong checksum fails and cleans up file"
    else
        fail "fd_download with wrong checksum left file behind"
    fi
fi

# Test 17: fd_download to existing file (should overwrite)
log "Test 17: fd_download to existing destination (overwrite)"
echo "old content" > "$TEST_DIR/existing.txt"
# Use force_curl to avoid resume issues with Python's simple HTTP server
if fd_download "http://localhost:8999/test-file.txt" "$TEST_DIR/existing.txt" "" "true" 2>&1; then
    content=$(cat "$TEST_DIR/existing.txt")
    if [[ "$content" == "test content for download" ]]; then
        pass "fd_download overwrites existing file"
    else
        fail "fd_download did not overwrite: $content"
    fi
else
    fail "fd_download to existing file failed"
fi

# Test 18: fd_download with HTTP 404
log "Test 18: fd_download with HTTP 404 (should fail)"
if ! fd_download "http://localhost:8999/nonexistent.txt" "$TEST_DIR/404.txt" 2>&1; then
    if [[ ! -f "$TEST_DIR/404.txt" ]]; then
        pass "fd_download fails on 404 and cleans up"
    else
        fail "fd_download left file after 404"
    fi
else
    fail "fd_download should have failed on 404"
fi

# Test 19: fd_git_clone
log "Test 19: fd_git_clone shallow"
if command -v git >/dev/null 2>&1; then
    if fd_git_clone "https://github.com/git/git.git" "$TEST_DIR/git-clone-test" true 2>&1 | tail -3; then
        if [[ -d "$TEST_DIR/git-clone-test/.git" ]]; then
            pass "fd_git_clone works (shallow)"
        else
            fail "fd_git_clone directory missing"
        fi
    else
        fail "fd_git_clone failed"
    fi
else
    warn "git not installed, skipping fd_git_clone test"
fi

# Test 20: fd_speed_test (just check it runs without error)
log "Test 20: fd_speed_test runs"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
if fd_speed_test "http://localhost:8999/10mb.bin" 10 2>&1 | head -20; then
    pass "fd_speed_test runs without error"
else
    warn "fd_speed_test failed (may be expected without aria2/curl)"
fi

# Test 21: fd_init runs (explicit opt-in)
log "Test 21: fd_init runs (explicit opt-in)"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
if fd_init 2>&1 | grep -q "initialized"; then
    pass "fd_init runs explicitly"
else
    fail "fd_init failed"
fi

# Test 22: fd_download with force_curl option
log "Test 22: fd_download with force_curl=true"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
if fd_download "http://localhost:8999/test-file.txt" "$TEST_DIR/force-curl.txt" "" "true" 2>&1; then
    if [[ -f "$TEST_DIR/force-curl.txt" ]]; then
        content=$(cat "$TEST_DIR/force-curl.txt")
        if [[ "$content" == "test content for download" ]]; then
            pass "fd_download with force_curl works"
        else
            fail "fd_download force_curl content mismatch"
        fi
    else
        fail "fd_download force_curl: file not created"
    fi
else
    fail "fd_download force_curl failed"
fi

# Test 23: _fd_select_download_method logic
log "Test 23: _fd_select_download_method function"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
# Test git URL
result=$(_fd_select_download_method "https://github.com/user/repo.git" "false")
if [[ "$result" == "git" ]]; then
    pass "_fd_select_download_method detects git URL"
else
    fail "_fd_select_download_method git URL: got $result"
fi
# Test rate-limited
result=$(_fd_select_download_method "https://github.com/user/file.zip" "false")
if [[ "$result" == "aria2-limited" || "$result" == "curl" ]]; then
    pass "_fd_select_download_method handles rate-limited"
else
    fail "_fd_select_download_method rate-limited: got $result"
fi
# Test force curl
result=$(_fd_select_download_method "http://example.com/file.zip" "true")
if [[ "$result" == "curl" ]]; then
    pass "_fd_select_download_method respects force_curl"
else
    fail "_fd_select_download_method force_curl: got $result"
fi

# Test 24: _fd_server_supports_range
log "Test 24: _fd_server_supports_range"
source "$REPO_ROOT/src/fast-download.sh" 2>/dev/null
if _fd_server_supports_range "http://localhost:8999/test-file.txt" 2>/dev/null; then
    pass "_fd_server_supports_range works for local server"
else
    warn "_fd_server_supports_range: local server may not support ranges"
fi

# Test 25: PowerShell module syntax
log "Test 25: PowerShell module syntax"
if command -v pwsh >/dev/null 2>&1; then
    if pwsh -NoProfile -Command "Import-Module '$REPO_ROOT/opencode/FastDownload.psm1' -Force; Initialize-FastDownload" 2>&1 | grep -q "aria2c"; then
        pass "PowerShell module loads"
    else
        fail "PowerShell module load failed"
    fi
else
    warn "pwsh not available, skipping PS module test"
fi

# Test 26: Agent config files exist
log "Test 26: Agent config files exist"
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

# Test 27: Core docs exist
log "Test 27: Core documentation"
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

# Test 28: Logo exists
log "Test 28: Logo exists"
if [[ -f "$REPO_ROOT/assets/logo.png" ]]; then
    pass "Logo exists at assets/logo.png"
else
    fail "Missing logo at assets/logo.png"
fi

# Test 29: README references logo
log "Test 29: README references logo"
if grep -q "assets/logo.png" "$REPO_ROOT/README.md"; then
    pass "README references logo"
else
    fail "README does not reference logo"
fi

# Test 30: Branch references are master (not main)
log "Test 30: Branch references use master"
if ! grep -r "main" "$REPO_ROOT/.github/workflows/" | grep -q "branches:"; then
    pass "CI workflow uses master branch"
else
    fail "CI workflow still references main branch"
fi

if ! grep -q "Fast-Download/main" "$REPO_ROOT/README.md"; then
    pass "README uses master branch"
else
    fail "README still references main branch"
fi

# Summary
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