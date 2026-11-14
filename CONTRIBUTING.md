# Contributing to fast-download

Thank you for your interest in contributing! This project welcomes contributions from everyone.

## Code of Conduct

By participating, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Bugs
1. Check [existing issues](https://github.com/AbdullahAlHadi2589/Fast-Download/issues)
2. Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md)
3. Include: OS, shell, agent, steps to reproduce, expected vs actual behavior

### Suggesting Features
1. Check [existing issues](https://github.com/AbdullahAlHadi2589/Fast-Download/issues)
2. Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md)
3. Explain the use case and expected behavior

### Pull Requests
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `./scripts/test.sh`
5. Commit with conventional commits: `git commit -m "feat: add amazing feature"`
6. Push and open a PR

## Development Setup

### Prerequisites
- Git
- Bash (for shell library testing)
- PowerShell 5.1+ (for Windows module testing)
- aria2, curl, git (for integration tests)

### Local Testing
```bash
# Clone
git clone https://github.com/AbdullahAlHadi2589/Fast-Download.git
cd fast-download

# Run test suite
./scripts/test.sh

# Test specific agent configs
./scripts/test.sh --agent opencode
./scripts/test.sh --agent claude-code
# etc.

# Test installers (dry run)
DRY_RUN=1 ./scripts/install.sh
DRY_RUN=1 pwsh ./scripts/install.ps1
```

## Coding Standards

### Shell Scripts (`src/fast-download.sh`, `scripts/*.sh`)
- POSIX-compliant where possible
- ShellCheck clean: `shellcheck src/fast-download.sh`
- Functions prefixed with `fd_`
- Global variables prefixed with `FD_`
- Error handling with `set -euo pipefail`

### PowerShell (`opencode/FastDownload.psm1`, `scripts/*.ps1`)
- PowerShell 5.1+ compatible
- Verb-Noun naming for functions
- Comment-based help for public functions
- Strict mode: `Set-StrictMode -Version Latest`

### Agent Configs
- Follow each platform's schema
- Keep instructions concise and actionable
- Test with actual agent before submitting

### Documentation
- Markdown with proper headings
- Code blocks with language hints
- Update `CHANGELOG.md` for user-facing changes

## Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

Examples:
```
feat(agent): add Windsurf support
fix(shell): handle spaces in file paths
docs(readme): add demo GIF
test: add fd_verify edge cases
```

## Testing Requirements

All PRs must pass:
1. ShellCheck on all `.sh` files
2. PowerShell syntax check on all `.ps1` files
3. `./scripts/test.sh` passes
4. No regression in existing agent configs
5. New agents tested manually

## Adding New Agent Support

1. Create folder under root: `new-agent/`
2. Add config file(s) following platform schema
3. Add entry to `README.md` supported agents table
4. Add entry to `docs/AGENT_SETUP.md`
5. Add test case in `scripts/test.sh`
6. Update `package.json` if needed

## Package Manager Submissions

We accept PRs for:
- Homebrew formula (`packaging/homebrew/`)
- Chocolatey package (`packaging/chocolatey/`)
- Winget manifest (`packaging/winget/`)
- Scoop manifest (`packaging/scoop/`)
- AUR PKGBUILD (`packaging/aur/`)
- npm package (via `package.json`)

## Release Process

Maintainers only:
1. Update `CHANGELOG.md`
2. Bump version in `package.json` and `skill.json` files
3. Create tag: `git tag v1.2.3`
4. Push tag: `git push origin v1.2.3`
5. GitHub Actions creates release automatically

## Questions?

Open a [discussion](https://github.com/AbdullahAlHadi2589/Fast-Download/discussions) or [issue](https://github.com/AbdullahAlHadi2589/Fast-Download/issues).

---

**Maintainer:** Abdullah Al Hadi