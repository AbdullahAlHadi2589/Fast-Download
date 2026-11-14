#!/usr/bin/env fish
# fast-download.fish - Universal download accelerator library for fish shell
# Source this file: source ~/.fast-download/fast-download.fish
# Then use: fd_download "url" "output" [checksum]

# ============================================================================
# CONFIGURATION
# ============================================================================
set -g FD_ARIA2_CONNECTIONS 16
set -g FD_ARIA2_SPLIT 16
set -g FD_ARIA2_MIN_SPLIT_SIZE 1M
set -g FD_CURL_RETRIES 5
set -g FD_CURL_RETRY_DELAY 3
set -g FD_GIT_SHALLOW true

# ============================================================================
# INTERNAL: Tool detection
# ============================================================================
function _fd_has
    command -v $argv[1] >/dev/null 2>&1
end

function _fd_detect_aria2
    if _fd_has aria2c
        echo aria2c
        return 0
    end
    return 1
end

function _fd_detect_curl
    if _fd_has curl
        echo curl
        return 0
    end
    return 1
end

function _fd_detect_git
    if _fd_has git
        echo git
        return 0
    end
    return 1
end

# ============================================================================
# INTERNAL: URL classification
# ============================================================================
function _fd_is_git_url
    set url $argv[1]
    string match -r '^https?://github\.com/' $url >/dev/null; or \
    string match -r '\.git$' $url >/dev/null; or \
    string match -r '^git@' $url >/dev/null
end

function _fd_server_supports_range
    set url $argv[1]
    set tool (_fd_detect_curl)
    if test -n "$tool"
        set headers (curl -sI --max-time 10 $url 2>/dev/null)
        string match -ri 'Accept-Ranges:\ *bytes' $headers >/dev/null
    else
        return 1
    end
end

function _fd_is_rate_limited
    set url $argv[1]
    string match -r 'proof\.ovh\.net' $url >/dev/null; or \
    string match -r 'github\.com' $url >/dev/null; or \
    string match -r 'release-assets\.githubusercontent\.com' $url >/dev/null
end

# ============================================================================
# PUBLIC: Download file (HTTP/HTTPS/FTP)
# ============================================================================
# Usage: fd_download "url" "output_path" [expected_sha256]
function fd_download
    set url $argv[1]
    set output $argv[2]
    set expected_checksum $argv[3]
    set force_curl $argv[4]

    if test -z "$url" -o -z "$output"
        echo "Usage: fd_download <url> <output_path> [expected_sha256]" >&2
        return 1
    end

    set output_dir (dirname $output)
    mkdir -p $output_dir

    set aria2_cmd (_fd_detect_aria2)

    # Git URL? Delegate to git clone
    if _fd_is_git_url $url
        fd_git_clone $url $output
        return $status
    end

    # Try aria2 first (unless forced to curl)
    if test "$force_curl" != "true" -a -n "$aria2_cmd"
        set connections $FD_ARIA2_CONNECTIONS
        set split $FD_ARIA2_SPLIT

        # Reduce connections for known rate-limited servers
        if _fd_is_rate_limited $url
            set connections 4
            set split 4
        end

        echo "Downloading with aria2 (connections: $connections)..." >&2

        set aria2_args \
            -x $connections \
            -s $split \
            -k $FD_ARIA2_MIN_SPLIT_SIZE \
            --file-allocation=falloc \
            --continue=true \
            --max-tries=5 \
            --retry-wait=3 \
            --check-certificate=true \
            --allow-overwrite=true \
            -o (basename $output) \
            -d $output_dir

        if test -n "$expected_checksum"
            set aria2_args $aria2_args --checksum="sha256=$expected_checksum"
        end

        set aria2_args $aria2_args $url

        if $aria2_cmd $aria2_args 2>&1
            echo "Download completed" >&2
            return 0
        end

        echo "aria2 failed, falling back to curl..." >&2
    end

    # Fallback to curl
    set curl_cmd (_fd_detect_curl)
    if test -z "$curl_cmd"
        echo "No curl or aria2 available" >&2
        return 1
    end

    echo "Downloading with curl..." >&2

    set curl_args \
        -L \
        -C - \
        -o $output \
        --retry $FD_CURL_RETRIES \
        --retry-delay $FD_CURL_RETRY_DELAY \
        --fail \
        -# \
        $url

    if $curl_cmd $curl_args 2>&1
        echo "Download completed" >&2
        return 0
    end

    echo "Download failed with both aria2 and curl" >&2
    return 1
end

# ============================================================================
# PUBLIC: Git clone
# ============================================================================
# Usage: fd_git_clone "url" "output_dir" [shallow=true]
function fd_git_clone
    set url $argv[1]
    set output_dir $argv[2]
    set shallow $argv[3]

    if test -z "$url" -o -z "$output_dir"
        echo "Usage: fd_git_clone <url> <output_dir> [shallow]" >&2
        return 1
    end

    if test -z "$shallow"
        set shallow $FD_GIT_SHALLOW
    end

    set git_cmd (_fd_detect_git)
    if test -z "$git_cmd"
        echo "Git not found" >&2
        return 1
    end

    set args clone

    if test "$shallow" = "true"
        set args $args --depth 1 --single-branch --filter=blob:none
    end

    set args $args $url $output_dir

    echo "Cloning repository" >&2
    if test "$shallow" = "true"
        echo " (shallow)" >&2
    end
    echo "..." >&2

    if $git_cmd $args 2>&1
        echo "Clone completed" >&2
        return 0
    end

    echo "Git clone failed" >&2
    return 1
end

# ============================================================================
# PUBLIC: Verify checksum
# ============================================================================
# Usage: fd_verify "file" "expected_sha256"
function fd_verify
    set file $argv[1]
    set expected $argv[2]
    set algo $argv[3]

    if test -z "$algo"
        set algo sha256
    end

    if not test -f $file
        echo "File not found: $file" >&2
        return 1
    end

    set actual ""
    switch $algo
        case sha256
            if _fd_has sha256sum
                set actual (sha256sum $file | awk '{print $1}')
            else if _fd_has shasum
                set actual (shasum -a 256 $file | awk '{print $1}')
            else if _fd_has certutil
                set actual (certutil -hashfile $file SHA256 | sed -n '2p' | tr -d ' ')
            else
                echo "No SHA256 tool available" >&2
                return 1
            end
        case md5
            if _fd_has md5sum
                set actual (md5sum $file | awk '{print $1}')
            else if _fd_has md5
                set actual (md5 -q $file)
            else
                echo "No MD5 tool available" >&2
                return 1
            end
        case '*'
            echo "Unsupported algorithm: $algo" >&2
            return 1
    end

    if test (string lower $actual) = (string lower $expected)
        echo "Checksum verified ($algo)" >&2
        return 0
    else
        echo "Checksum mismatch!" >&2
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        return 1
    end
end

# ============================================================================
# PUBLIC: Speed test
# ============================================================================
function fd_speed_test
    set test_url $argv[1]
    set test_size_mb $argv[2]

    if test -z "$test_url"
        set test_url "https://proof.ovh.net/files/100Mb.dat"
    end
    if test -z "$test_size_mb"
        set test_size_mb 100
    end

    echo "Testing download speed from $test_url..." >&2

    set aria2_cmd (_fd_detect_aria2)
    if test -n "$aria2_cmd"
        echo "--- aria2 ($FD_ARIA2_CONNECTIONS connections) ---" >&2
        set temp_file (mktemp)
        set start (date +%s.%N)
        if $aria2_cmd -x $FD_ARIA2_CONNECTIONS -s $FD_ARIA2_SPLIT -k $FD_ARIA2_MIN_SPLIT_SIZE \
            --file-allocation=none --continue=true -o (basename $temp_file) -d (dirname $temp_file) \
            $test_url 2>&1
            set end (date +%s.%N)
            set duration (echo "$end - $start" | bc)
            set speed (echo "scale=1; $test_size_mb / $duration" | bc)
            echo "Time: ${duration}s" >&2
            echo "Speed: ${speed} MB/s" >&2
        end
        rm -f $temp_file
    end

    set curl_cmd (_fd_detect_curl)
    if test -n "$curl_cmd"
        echo "--- curl (single connection) ---" >&2
        set temp_file (mktemp)
        set start (date +%s.%N)
        if $curl_cmd -L -o $temp_file $test_url 2>&1
            set end (date +%s.%N)
            set duration (echo "$end - $start" | bc)
            set speed (echo "scale=1; $test_size_mb / $duration" | bc)
            echo "Time: ${duration}s" >&2
            echo "Speed: ${speed} MB/s" >&2
        end
        rm -f $temp_file
    end
end

# ============================================================================
# INIT: Apply optimized configs
# ============================================================================
function fd_init
    set git_cmd (_fd_detect_git)
    if test -z "$git_cmd"
        return 0
    end

    # Git optimizations
    $git_cmd config --global core.compression 9 2>/dev/null; or true
    $git_cmd config --global core.preloadIndex true 2>/dev/null; or true
    $git_cmd config --global core.fscache true 2>/dev/null; or true
    $git_cmd config --global http.postBuffer 524288000 2>/dev/null; or true
    $git_cmd config --global http.lowSpeedLimit 0 2>/dev/null; or true
    $git_cmd config --global http.lowSpeedTime 999999 2>/dev/null; or true

    # npm optimizations
    if _fd_has npm
        npm config set fetch-retries 5 2>/dev/null; or true
        npm config set fetch-retry-factor 2 2>/dev/null; or true
        npm config set prefer-offline true 2>/dev/null; or true
    end

    # pip optimizations
    if _fd_has pip
        pip config set global.retries 5 2>/dev/null; or true
        pip config set global.timeout 60 2>/dev/null; or true
    end

    echo "fast-download initialized" >&2
end

# Auto-init if sourced
fd_init