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
# When set to true, skip aria2 and use curl directly (for rate-limited servers)
$env.FD_FORCE_CURL = false

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
    ($url | str match "^https?://github\.com/[^/]+/[^/]+\.git$") or
    (($url | str match "^https?://github\.com/[^/]+/[^/]+/?$") and (not ($url | str match "\.[a-zA-Z0-9]+$"))) or
    ($url | str starts-with "git@") or
    ($url | str ends-with ".git")
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

def _fd_get_content_length [$url] {
    let tool = (_fd_detect_curl)
    if ($tool != "") {
        let headers = (^curl -sI --max-time 10 $url 2>/dev/null | str join "\n")
        let length_line = ($headers | lines | each { if ($in | str starts-with "content-length:") { $in } })
        if ($length_line != "") {
            let length = ($length_line | str replace "content-length:" "" | str trim)
            if ($length | str match "^[0-9]+$") {
                return ($length | into int)
            }
        }
    }
    return -1
}

def _fd_is_rate_limited [$url] {
    ($url | str contains "proof.ovh.net") or 
    (($url | str contains "github.com") and (not ($url | str match "github\.com/[^/]+/[^/]+/(raw|releases|archive)"))) or
    ($url | str contains "release-assets.githubusercontent.com")
}

# 10 MB threshold (in bytes) - below this, curl is more efficient due to aria2 overhead
$env.FD_SMALL_FILE_THRESHOLD = 10485760

# ============================================================================
# INTERNAL: Smart download method selection
# ============================================================================
def _fd_select_download_method [$url, $force_curl: $env.FD_FORCE_CURL] {
    # Git URLs are handled separately
    if (_fd_is_git_url $url) {
        return "git"
    }

    # Force curl if requested
    if ($force_curl == true) {
        return "curl"
    }

    # Check for aria2 availability
    let aria2_cmd = (_fd_detect_aria2)
    if ($aria2_cmd == "") {
        return "curl"
    }

    # For rate-limited servers, use reduced aria2
    if (_fd_is_rate_limited $url) {
        return "aria2-limited"
    }

    # Check if server supports range requests
    if (not (_fd_server_supports_range $url)) {
        # Server doesn't support range requests - aria2's multi-connection won't help
        return "curl"
    }

    # Server supports ranges - check file size to decide between aria2 and curl
    let content_length = (_fd_get_content_length $url)
    if ($content_length > 0 and $content_length < $env.FD_SMALL_FILE_THRESHOLD) {
        # File is smaller than threshold - curl is more efficient
        return "curl"
    }

    # Large file or unknown size with range support - use aria2
    return "aria2"
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

    # Git URL? Delegate to git clone
    if (_fd_is_git_url $url) {
        return (fd_git_clone $url $output)
    }

    let method = (_fd_select_download_method $url $force_curl)
    let aria2_cmd = (_fd_detect_aria2)

    # Track if download succeeded
    let download_succeeded = false

    # Try aria2 first (for aria2 and aria2-limited methods)
    if (($method == "aria2" or $method == "aria2-limited") and $aria2_cmd != "") {
        let connections = $env.FD_ARIA2_CONNECTIONS
        let split = $env.FD_ARIA2_SPLIT

        # Reduce connections for known rate-limited servers
        if ($method == "aria2-limited") {
            $connections = 4
            $split = 4
        }

        print $"Downloading with aria2 (connections: ($connections), method: ($method))..."

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
            $download_succeeded = true
        } else {
            print "aria2 failed, falling back to curl..."
        }
    }

    # Fallback to curl
    if ($download_succeeded == false) {
        let curl_cmd = (_fd_detect_curl)
        if ($curl_cmd == "") {
            print "No curl or aria2 available"
            return false
        }

        print "Downloading with curl..."

        let curl_args = [
            "-L"
            "-o" $output
            "--retry" $env.FD_CURL_RETRIES
            "--retry-delay" $env.FD_CURL_RETRY_DELAY
            "--fail"
            "-#"
            $url
        ]

        # Use resume (-C -) only if not forcing curl (force_curl skips aria2 and often means no-range servers)
        if ($force_curl == false) {
            $curl_args = (["-C" "-"] ++ $curl_args)
        }

        if (^$curl_cmd ...$curl_args 2>&1) {
            print "Download completed"
            $download_succeeded = true
        }
    }

    # Verify checksum after ANY successful download
    if ($download_succeeded == true and $expected_checksum != "") {
        print "Verifying checksum..."
        if (not (fd_verify $output $expected_checksum)) {
            print "Checksum verification failed! Removing invalid file."
            ^rm -f $output
            return false
        }
        print "Checksum verified"
    }

    if ($download_succeeded == true) {
        return true
    } else {
        print "Download failed with both aria2 and curl"
        return false
    }
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
# INIT: Apply optimized configs (EXPLICITLY OPT-IN)
# ============================================================================
# This function modifies global git/npm/pip configuration.
# It MUST be called explicitly by the user. It does NOT run automatically on source.
# Usage: fd_init
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

    print "fast-download initialized (git/npm/pip configs applied)"
}

# NOTE: Auto-init on source has been REMOVED.
# Users must explicitly call `fd_init` to apply git/npm/pip optimizations.
# This prevents unexpected global configuration changes.