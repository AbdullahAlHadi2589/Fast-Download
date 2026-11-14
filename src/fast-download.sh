#!/usr/bin/env bash
# fast-download.sh - Universal download accelerator library
# Source this file: source fast-download.sh
# Then use: fd_download "url" "output" [checksum]

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
FD_ARIA2_CONNECTIONS="${FD_ARIA2_CONNECTIONS:-16}"
FD_ARIA2_SPLIT="${FD_ARIA2_SPLIT:-16}"
FD_ARIA2_MIN_SPLIT_SIZE="${FD_ARIA2_MIN_SPLIT_SIZE:-1M}"
FD_CURL_RETRIES="${FD_CURL_RETRIES:-5}"
FD_CURL_RETRY_DELAY="${FD_CURL_RETRY_DELAY:-3}"
FD_GIT_SHALLOW="${FD_GIT_SHALLOW:-true}"

# ============================================================================
# INTERNAL: Tool detection
# ============================================================================
_fd_has() { command -v "$1" >/dev/null 2>&1; }

_fd_detect_aria2() {
    if _fd_has aria2c; then
        echo "aria2c"
        return 0
    fi
    return 1
}

_fd_detect_curl() {
    if _fd_has curl; then
        echo "curl"
        return 0
    fi
    return 1
}

_fd_detect_git() {
    if _fd_has git; then
        echo "git"
        return 0
    fi
    return 1
}

# ============================================================================
# INTERNAL: URL classification
# ============================================================================
_fd_is_git_url() {
    local url="$1"
    [[ "$url" =~ ^https?://github\.com/ ]] || [[ "$url" =~ \.git$ ]] || [[ "$url" =~ ^git@ ]]
}

_fd_server_supports_range() {
    local url="$1"
    local tool="$(_fd_detect_curl)"
    if [[ -n "$tool" ]]; then
        # HEAD request to check Accept-Ranges
        local headers
        headers=$(curl -sI --max-time 10 "$url" 2>/dev/null || true)
        [[ "$headers" =~ [Aa]ccept-[Rr]anges:\ *bytes ]]
    else
        return 1
    fi
}

_fd_is_rate_limited() {
    local url="$1"
    # Known rate-limited domains
    [[ "$url" =~ proof\.ovh\.net ]] || [[ "$url" =~ github\.com ]] || [[ "$url" =~ release-assets\.githubusercontent\.com ]]
}

# ============================================================================
# PUBLIC: Download file (HTTP/HTTPS/FTP)
# ============================================================================
# Usage: fd_download "url" "output_path" [expected_sha256]
fd_download() {
    local url="$1"
    local output="$2"
    local expected_checksum="${3:-}"
    local force_curl="${4:-false}"

    if [[ -z "$url" || -z "$output" ]]; then
        echo "Usage: fd_download <url> <output_path> [expected_sha256]" >&2
        return 1
    fi

    local output_dir
    output_dir=$(dirname "$output")
    mkdir -p "$output_dir"

    local aria2_cmd
    aria2_cmd=$(_fd_detect_aria2) || true

    # Git URL? Delegate to git clone
    if _fd_is_git_url "$url"; then
        fd_git_clone "$url" "$output"
        return $?
    fi

    # Try aria2 first (unless forced to curl)
    if [[ "$force_curl" != "true" && -n "$aria2_cmd" ]]; then
        local connections="$FD_ARIA2_CONNECTIONS"
        local split="$FD_ARIA2_SPLIT"

        # Reduce connections for known rate-limited servers
        if _fd_is_rate_limited "$url"; then
            connections=4
            split=4
        fi

        echo "Downloading with aria2 (connections: $connections)..." >&2

        local aria2_args=(
            -x "$connections"
            -s "$split"
            -k "$FD_ARIA2_MIN_SPLIT_SIZE"
            --file-allocation=falloc
            --continue=true
            --max-tries=5
            --retry-wait=3
            --check-certificate=true
            --allow-overwrite=true
            -o "$(basename "$output")"
            -d "$output_dir"
        )

        if [[ -n "$expected_checksum" ]]; then
            aria2_args+=(--checksum="sha256=$expected_checksum")
        fi

        aria2_args+=("$url")

        if "$aria2_cmd" "${aria2_args[@]}" 2>&1; then
            echo "Download completed" >&2
            return 0
        fi

        echo "aria2 failed, falling back to curl..." >&2
    fi

    # Fallback to curl
    local curl_cmd
    curl_cmd=$(_fd_detect_curl) || { echo "No curl or aria2 available" >&2; return 1; }

    echo "Downloading with curl..." >&2

    local curl_args=(
        -L                    # Follow redirects
        -C -                  # Resume
        -o "$output"
        --retry "$FD_CURL_RETRIES"
        --retry-delay "$FD_CURL_RETRY_DELAY"
        --fail                # Fail on HTTP errors
        -#                    # Progress bar
        "$url"
    )

    if "$curl_cmd" "${curl_args[@]}" 2>&1; then
        echo "Download completed" >&2
        return 0
    fi

    echo "Download failed with both aria2 and curl" >&2
    return 1
}

# ============================================================================
# PUBLIC: Git clone
# ============================================================================
# Usage: fd_git_clone "url" "output_dir" [shallow=true]
fd_git_clone() {
    local url="$1"
    local output_dir="$2"
    local shallow="${3:-$FD_GIT_SHALLOW}"

    if [[ -z "$url" || -z "$output_dir" ]]; then
        echo "Usage: fd_git_clone <url> <output_dir> [shallow]" >&2
        return 1
    fi

    local git_cmd
    git_cmd=$(_fd_detect_git) || { echo "Git not found" >&2; return 1; }

    local args=(clone)

    if [[ "$shallow" == "true" ]]; then
        args+=(--depth 1 --single-branch --filter=blob:none)
    fi

    args+=("$url" "$output_dir")

    echo "Cloning repository${shallow == true && echo ' (shallow)'}..." >&2

    if "$git_cmd" "${args[@]}" 2>&1; then
        echo "Clone completed" >&2
        return 0
    fi

    echo "Git clone failed" >&2
    return 1
}

# ============================================================================
# PUBLIC: Verify checksum
# ============================================================================
# Usage: fd_verify "file" "expected_sha256"
fd_verify() {
    local file="$1"
    local expected="$2"
    local algo="${3:-sha256}"

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file" >&2
        return 1
    fi

    local actual
    case "$algo" in
        sha256)
            if _fd_has sha256sum; then
                actual=$(sha256sum "$file" | awk '{print $1}')
            elif _fd_has shasum; then
                actual=$(shasum -a 256 "$file" | awk '{print $1}')
            elif _fd_has certutil; then
                # Windows fallback
                actual=$(certutil -hashfile "$file" SHA256 | sed -n '2p' | tr -d ' ')
            else
                echo "No SHA256 tool available" >&2
                return 1
            fi
            ;;
        md5)
            if _fd_has md5sum; then
                actual=$(md5sum "$file" | awk '{print $1}')
            elif _fd_has md5; then
                actual=$(md5 -q "$file")
            else
                echo "No MD5 tool available" >&2
                return 1
            fi
            ;;
        *)
            echo "Unsupported algorithm: $algo" >&2
            return 1
            ;;
    esac

    if [[ "${actual,,}" == "${expected,,}" ]]; then
        echo "Checksum verified ($algo)" >&2
        return 0
    else
        echo "Checksum mismatch!" >&2
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        return 1
    fi
}

# ============================================================================
# PUBLIC: Speed test
# ============================================================================
fd_speed_test() {
    local test_url="${1:-https://proof.ovh.net/files/100Mb.dat}"
    local test_size_mb="${2:-100}"

    echo "Testing download speed from $test_url..." >&2

    local aria2_cmd
    aria2_cmd=$(_fd_detect_aria2) || true

    if [[ -n "$aria2_cmd" ]]; then
        echo "--- aria2 (${FD_ARIA2_CONNECTIONS} connections) ---" >&2
        local temp_file
        temp_file=$(mktemp)
        local start end duration speed
        start=$(date +%s.%N)
        if "$aria2_cmd" -x "$FD_ARIA2_CONNECTIONS" -s "$FD_ARIA2_SPLIT" -k "$FD_ARIA2_MIN_SPLIT_SIZE" \
            --file-allocation=none --continue=true -o "$(basename "$temp_file")" -d "$(dirname "$temp_file")" \
            "$test_url" 2>&1; then
            end=$(date +%s.%N)
            duration=$(echo "$end - $start" | bc)
            speed=$(echo "scale=1; $test_size_mb / $duration" | bc)
            echo "Time: ${duration}s" >&2
            echo "Speed: ${speed} MB/s" >&2
        fi
        rm -f "$temp_file"
    fi

    local curl_cmd
    curl_cmd=$(_fd_detect_curl) || return 1

    echo "--- curl (single connection) ---" >&2
    local temp_file
    temp_file=$(mktemp)
    local start end duration speed
    start=$(date +%s.%N)
    if "$curl_cmd" -L -o "$temp_file" "$test_url" 2>&1; then
        end=$(date +%s.%N)
        duration=$(echo "$end - $start" | bc)
        speed=$(echo "scale=1; $test_size_mb / $duration" | bc)
        echo "Time: ${duration}s" >&2
        echo "Speed: ${speed} MB/s" >&2
    fi
    rm -f "$temp_file"
}

# ============================================================================
# INIT: Apply optimized configs
# ============================================================================
fd_init() {
    local git_cmd
    git_cmd=$(_fd_detect_git) || return 0

    # Git optimizations
    "$git_cmd" config --global core.compression 9 2>/dev/null || true
    "$git_cmd" config --global core.preloadIndex true 2>/dev/null || true
    "$git_cmd" config --global core.fscache true 2>/dev/null || true
    "$git_cmd" config --global http.postBuffer 524288000 2>/dev/null || true
    "$git_cmd" config --global http.lowSpeedLimit 0 2>/dev/null || true
    "$git_cmd" config --global http.lowSpeedTime 999999 2>/dev/null || true

    # npm optimizations
    if _fd_has npm; then
        npm config set fetch-retries 5 2>/dev/null || true
        npm config set fetch-retry-factor 2 2>/dev/null || true
        npm config set prefer-offline true 2>/dev/null || true
    fi

    # pip optimizations
    if _fd_has pip; then
        pip config set global.retries 5 2>/dev/null || true
        pip config set global.timeout 60 2>/dev/null || true
    fi

    echo "fast-download initialized" >&2
}

# ============================================================================
# EXPORT
# ============================================================================
export -f fd_download fd_git_clone fd_verify fd_speed_test fd_init

# Auto-init if sourced (not executed)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    fd_init
fi