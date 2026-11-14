#!/usr/bin/env nu
# fast-download.nu - Universal download accelerator library for nushell
# Source this file: source ~/.fast-download/fast-download.nu
# Then use: fd_download "url" "output" [checksum]

# ============================================================================
# CONFIGURATION
# ============================================================================
$env.FD_ARIA2_CONNECTIONS = 16
$env.FD_ARIA2_SPLIT = 16
$env.FD_ARIA2_MIN_SPLIT_SIZE = "1M"
$env.FD_CURL_RETRIES = 5
$env.FD_CURL_RETRY_DELAY = 3
$env.FD_GIT_SHALLOW = true

# ============================================================================
# INTERNAL: Tool detection
# ============================================================================
def _fd_has [$tool] {
    try { ^which $tool > /dev/null; true } catch { false }
}

def _fd_detect_aria2 [] {
    if (_fd_has "aria2c") { "aria2c" } else { "" }
}

def _fd_detect_curl [] {
    if (_fd_has "curl") { "curl" } else { "" }
}

def _fd_detect_git [] {
    if (_fd_has "git") { "git" } else { "" }
}

# ============================================================================
# INTERNAL: URL classification
# ============================================================================
def _fd_is_git_url [$url] {
    ($url | str contains "github.com/") or ($url | str ends-with ".git") or ($url | str starts-with "git@")
}

def _fd_server_supports_range [$url] {
    let tool = (_fd_detect_curl)
    if ($tool != "") {
        let headers = (^curl -sI --max-time 10 $url 2>/dev/null | str join "\n")
        $headers | str contains -i "accept-ranges: bytes"
    } else {
        false
    }
}

def _fd_is_rate_limited [$url] {
    ($url | str contains "proof.ovh.net") or ($url | str contains "github.com") or ($url | str contains "release-assets.githubusercontent.com")
}

# ============================================================================
# PUBLIC: Download file (HTTP/HTTPS/FTP)
# ============================================================================
# Usage: fd_download "url" "output_path" [expected_sha256]
def fd_download [$url, $output, $expected_checksum: "", $force_curl: false] {
    if ($url == "" or $output == "") {
        print "Usage: fd_download <url> <output_path> [expected_sha256]"
        return false
    }

    let output_dir = ($output | path dirname)
    ^mkdir -p $output_dir

    let aria2_cmd = (_fd_detect_aria2)

    # Git URL? Delegate to git clone
    if (_fd_is_git_url $url) {
        return (fd_git_clone $url $output)
    }

    # Try aria2 first (unless forced to curl)
    if ($force_curl == false and $aria2_cmd != "") {
        let connections = $env.FD_ARIA2_CONNECTIONS
        let split = $env.FD_ARIA2_SPLIT

        # Reduce connections for known rate-limited servers
        if (_fd_is_rate_limited $url) {
            $connections = 4
            $split = 4
        }

        print "Downloading with aria2 (connections: $connections)..."

        let aria2_args = [
            "-x" $connections
            "-s" $split
            "-k" $env.FD_ARIA2_MIN_SPLIT_SIZE
            "--file-allocation=falloc"
            "--continue=true"
            "--max-tries=5"
            "--retry-wait=3"
            "--check-certificate=true"
            "--allow-overwrite=true"
            "-o" ($output | path basename)
            "-d" $output_dir
        ]

        if ($expected_checksum != "") {
            $aria2_args = ($aria2_args ++ ["--checksum=sha256=$expected_checksum"])
        }

        $aria2_args = ($aria2_args ++ [$url])

        if (^$aria2_cmd ...$aria2_args 2>&1) {
            print "Download completed"
            return true
        }

        print "aria2 failed, falling back to curl..."
    }

    # Fallback to curl
    let curl_cmd = (_fd_detect_curl)
    if ($curl_cmd == "") {
        print "No curl or aria2 available"
        return false
    }

    print "Downloading with curl..."

    let curl_args = [
        "-L"
        "-C" "-"
        "-o" $output
        "--retry" $env.FD_CURL_RETRIES
        "--retry-delay" $env.FD_CURL_RETRY_DELAY
        "--fail"
        "-#"
        $url
    ]

    if (^$curl_cmd ...$curl_args 2>&1) {
        print "Download completed"
        return true
    }

    print "Download failed with both aria2 and curl"
    return false
}

# ============================================================================
# PUBLIC: Git clone
# ============================================================================
# Usage: fd_git_clone "url" "output_dir" [shallow=true]
def fd_git_clone [$url, $output_dir, $shallow: $env.FD_GIT_SHALLOW] {
    if ($url == "" or $output_dir == "") {
        print "Usage: fd_git_clone <url> <output_dir> [shallow]"
        return false
    }

    let git_cmd = (_fd_detect_git)
    if ($git_cmd == "") {
        print "Git not found"
        return false
    }

    let args = ["clone"]

    if ($shallow == true) {
        $args = ($args ++ ["--depth" "1" "--single-branch" "--filter=blob:none"])
    }

    $args = ($args ++ [$url, $output_dir])

    print "Cloning repository"
    if ($shallow == true) { print " (shallow)" }
    print "..."

    if (^$git_cmd ...$args 2>&1) {
        print "Clone completed"
        return true
    }

    print "Git clone failed"
    return false
}

# ============================================================================
# PUBLIC: Verify checksum
# ============================================================================
# Usage: fd_verify "file" "expected_sha256" [algorithm]
def fd_verify [$file, $expected, $algo: "sha256"] {
    if (not ($file | path exists)) {
        print "File not found: $file"
        return false
    }

    let actual = ""
    match $algo {
        "sha256" => {
            if (_fd_has "sha256sum") {
                $actual = (^sha256sum $file | str split " " | first)
            } else if (_fd_has "shasum") {
                $actual = (^shasum -a 256 $file | str split " " | first)
            } else if (_fd_has "certutil") {
                $actual = (^certutil -hashfile $file SHA256 | lines | get 1 | str trim)
            } else {
                print "No SHA256 tool available"
                return false
            }
        }
        "md5" => {
            if (_fd_has "md5sum") {
                $actual = (^md5sum $file | str split " " | first)
            } else if (_fd_has "md5") {
                $actual = (^md5 -q $file)
            } else {
                print "No MD5 tool available"
                return false
            }
        }
        _ => {
            print "Unsupported algorithm: $algo"
            return false
        }
    }

    if (($actual | str lower) == ($expected | str lower)) {
        print "Checksum verified ($algo)"
        return true
    } else {
        print "Checksum mismatch!"
        print $"Expected: ($expected)"
        print $"Actual:   ($actual)"
        return false
    }
}

# ============================================================================
# PUBLIC: Speed test
# ============================================================================
def fd_speed_test [$test_url: "https://proof.ovh.net/files/100Mb.dat", $test_size_mb: 100] {
    print $"Testing download speed from ($test_url)..."

    let aria2_cmd = (_fd_detect_aria2)
    if ($aria2_cmd != "") {
        print "--- aria2 ($env.FD_ARIA2_CONNECTIONS connections) ---"
        let temp_file = (^mktemp)
        let start = (^date +%s.%N)
        if (^$aria2_cmd -x $env.FD_ARIA2_CONNECTIONS -s $env.FD_ARIA2_SPLIT -k $env.FD_ARIA2_MIN_SPLIT_SIZE --file-allocation=none --continue=true -o ($temp_file | path basename) -d ($temp_file | path dirname) $test_url 2>&1) {
            let end = (^date +%s.%N)
            let duration = ($end - $start | math eval)
            let speed = (($test_size_mb / $duration) | math eval)
            print $"Time: ($duration)s"
            print $"Speed: ($speed) MB/s"
        }
        ^rm -f $temp_file
    }

    let curl_cmd = (_fd_detect_curl)
    if ($curl_cmd != "") {
        print "--- curl (single connection) ---"
        let temp_file = (^mktemp)
        let start = (^date +%s.%N)
        if (^$curl_cmd -L -o $temp_file $test_url 2>&1) {
            let end = (^date +%s.%N)
            let duration = ($end - $start | math eval)
            let speed = (($test_size_mb / $duration) | math eval)
            print $"Time: ($duration)s"
            print $"Speed: ($speed) MB/s"
        }
        ^rm -f $temp_file
    }
}

# ============================================================================
# INIT: Apply optimized configs
# ============================================================================
def fd_init [] {
    let git_cmd = (_fd_detect_git)
    if ($git_cmd == "") { return }

    # Git optimizations
    ^$git_cmd config --global core.compression 9 2>/dev/null; or true
    ^$git_cmd config --global core.preloadIndex true 2>/dev/null; or true
    ^$git_cmd config --global core.fscache true 2>/dev/null; or true
    ^$git_cmd config --global http.postBuffer 524288000 2>/dev/null; or true
    ^$git_cmd config --global http.lowSpeedLimit 0 2>/dev/null; or true
    ^$git_cmd config --global http.lowSpeedTime 999999 2>/dev/null; or true

    # npm optimizations
    if (_fd_has "npm") {
        ^npm config set fetch-retries 5 2>/dev/null; or true
        ^npm config set fetch-retry-factor 2 2>/dev/null; or true
        ^npm config set prefer-offline true 2>/dev/null; or true
    }

    # pip optimizations
    if (_fd_has "pip") {
        ^pip config set global.retries 5 2>/dev/null; or true
        ^pip config set global.timeout 60 2>/dev/null; or true
    }

    print "fast-download initialized"
}

# Auto-init
fd_init