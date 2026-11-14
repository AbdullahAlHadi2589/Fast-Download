#!/usr/bin/env bash
# Create demo GIF for fast-download README
# Requires: asciinema, agg (asciinema GIF generator), or terminalizer
# Usage: ./scripts/create-demo.sh

set -euo pipefail

DEMO_DIR="/tmp/fast-download-demo"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_GIF="${REPO_ROOT}/docs/demo.gif"

# Colors for terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[DEMO]${NC} $*"; }
log_success() { echo -e "${GREEN}[DEMO]${NC} $*"; }

# Check for recording tools
has_asciinema() { command -v asciinema >/dev/null 2>&1; }
has_terminalizer() { command -v terminalizer >/dev/null 2>&1; }
has_agg() { command -v agg >/dev/null 2>&1; }

mkdir -p "$DEMO_DIR"

log "Creating demo recording..."

# Demo script to record
cat > "$DEMO_DIR/demo-script.sh" << 'EOF'
#!/usr/bin/env bash
# This script will be recorded with asciinema

clear
echo "=== fast-download Demo ==="
echo ""
echo "Comparing download speeds: aria2 (16 connections) vs curl (single)"
echo ""

# Test file - GitHub release (2.4 MB)
URL="https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"

echo "Test file: aria2 2.4 MB release"
echo "URL: $URL"
echo ""
echo "--- Test 1: curl (single connection) ---"
echo "$ curl -L -o curl-test.zip \"$URL\""
curl -L -o curl-test.zip "$URL" 2>&1 | grep -E "(KB|MB|GB)/s|[0-9]+\%"
echo ""
echo "--- Test 2: aria2 (16 connections) ---"
echo "$ aria2c -x 16 -s 16 -o aria2-test.zip \"$URL\""
aria2c -x 16 -s 16 -o aria2-test.zip "$URL" 2>&1 | grep -E "(MiB|KiB)/s|[0-9]+\%"
echo ""
echo "--- Results ---"
ls -lh curl-test.zip aria2-test.zip
echo ""
echo "=== Git Shallow Clone Demo ==="
echo ""
echo "Full clone (200+ MB, ~43s):"
echo "$ git clone https://github.com/git/git.git"
echo ""
echo "Shallow clone (~20 MB, ~10s):"
echo "$ git clone --depth 1 --single-branch --filter=blob:none https://github.com/git/git.git"
echo ""
echo "=== Checksum Verification ==="
echo "$ aria2c --checksum=sha256=abc123... -o file.zip \"$URL\""
echo ""
echo "Done! fast-download gives you 100% of your internet speed."
EOF

chmod +x "$DEMO_DIR/demo-script.sh"

if has_asciinema && has_agg; then
    log "Recording with asciinema..."
    cd "$DEMO_DIR"
    asciinema rec demo.cast -c "./demo-script.sh" --overwrite
    
    log "Converting to GIF with agg..."
    agg demo.cast "$OUTPUT_GIF" --theme solarized-dark --font-size 14 --speed 2
    
    log_success "Demo GIF created: $OUTPUT_GIF"
elif has_terminalizer; then
    log "Recording with terminalizer..."
    cat > "$DEMO_DIR/terminalizer.yml" << EOF
config:
  cols: 100
  rows: 30
  frameDelay: auto
  maxIdleTime: 2000
  cursorStyle: block
  fontFamily: "Monospace"
  fontSize: 14
  theme:
    background: "#002b36"
    foreground: "#839496"
    cursor: "#839496"
    black: "#073642"
    red: "#dc322f"
    green: "#859900"
    yellow: "#b58900"
    blue: "#268bd2"
    magenta: "#d33682"
    cyan: "#2aa198"
    white: "#eee8d5"
    brightBlack: "#002b36"
    brightRed: "#cb4b16"
    brightGreen: "#586e75"
    brightYellow: "#657b83"
    brightBlue: "#839496"
    brightMagenta: "#6c71c4"
    brightCyan: "#93a1a1"
    brightWhite: "#fdf6e3"
records:
  - delay: 100
    content: "$ ./demo-script.sh\r\n"
EOF
    cd "$DEMO_DIR"
    terminalizer record demo -c "./demo-script.sh"
    terminalizer render demo "$OUTPUT_GIF"
    log_success "Demo GIF created: $OUTPUT_GIF"
else
    log_warn "No recording tool found. Install one of:"
    log_warn "  - asciinema + agg: pip install asciinema agg"
    log_warn "  - terminalizer: npm install -g terminalizer"
    log ""
    log "Manual demo commands to record:"
    cat "$DEMO_DIR/demo-script.sh"
fi

# Cleanup
rm -rf "$DEMO_DIR"