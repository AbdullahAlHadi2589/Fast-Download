# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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