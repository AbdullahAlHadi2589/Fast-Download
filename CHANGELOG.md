# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Installers: cursor and windsurf now deploy from their own agent folders (`cursor/fast-download/`, `windsurf/fast-download/`) instead of `vscode/fast-download/`
- Installers: jetbrains, amazon-q, and warp now deploy their own agent files (`jetbrains/fast-download.md`, `amazon-q/fast-download.md`, `warp/fast-download.yaml`) instead of reusing claude-code/continue files
- install.ps1: replaced `-OnlyAgent` with a real `[string[]]$Agent` parameter (comma-separated or array); added `-SkipGitConfig`; removed `-WhatIf` support
- install.js: `hasCmd` now uses `where` on Windows and `which` on POSIX; global git/npm/pip configs are now opt-in via `--apply-global-configs` (with `--skip-*` overrides)
- fast-download.js: `hasCmd` now uses `where` on Windows and `which` on POSIX; `sha256:`/`md5:` prefix is stripped before checksum verification
- Shell library: curl resume (`-C -`) is only applied when the output file exists and is non-empty AND the server supports byte ranges
- VS Code: added a minimal working `extension.js` with `main`/`activationEvents` in `package.json`
- JetBrains: removed `plugin.xml` (prompt-only); updated README status to "Prompt-only"
- CI: fixed install script syntax checks (positional `install.sh opencode`, `-SkipGitConfig` on Windows); added Node syntax checks for `install.js`, `fast-download.js`, `extension.js`
- Documentation: fixed JetBrains/Amazon Q/Warp manual install paths, PowerShell one-liner usage, Homebrew branch (`master`) and sha256 placeholder (`TODO`), and project structure tree

### Added
- Initial release of fast-download universal download accelerator
- aria2-powered multi-connection downloads (16 parallel connections)
- Git shallow clones (--depth 1 --filter=blob:none) for 90% less bandwidth
- Checksum verification (SHA256/MD5) built-in
- Smart fallbacks: curl with resume for rate-limited servers
- Optimized configs for git, npm, pip
- Universal shell library (fast-download.sh) for any terminal
- PowerShell module (FastDownload.psm1) for Windows
- Agent configs for: OpenCode, Claude Code, Codex, Continue, Cline, VS Code, Cursor, Windsurf, JetBrains AI, Amazon Q, Warp
- Installers: install.ps1 (Windows), install.sh (Linux/macOS/WSL)
- Uninstallers: uninstall.ps1, uninstall.sh
- CI/CD pipeline with cross-platform testing
- Comprehensive documentation and benchmarks

## [1.0.0] - 2026-11-14

### Added
- Initial release

---

## Release Notes Template

### [Version] - YYYY-MM-DD

#### Added
- New features

#### Changed
- Changes in existing functionality

#### Deprecated
- Soon-to-be removed features

#### Removed
- Removed features

#### Fixed
- Bug fixes

#### Security
- Vulnerability fixes