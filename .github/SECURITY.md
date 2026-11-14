# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | ✅ Yes             |
| < 1.0   | ❌ No              |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please report it responsibly:

**Do not** open a public issue for security vulnerabilities.

Instead, email: **abdullahalhadi@proton.me**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes

We will:
1. Acknowledge receipt within 48 hours
2. Provide a timeline for fix
3. Credit you in the security advisory (if desired)

## Security Considerations

### What fast-download Does
- Downloads files using aria2, curl, or git
- Verifies checksums when provided
- Uses HTTPS with certificate validation (always enabled)
- Applies git/npm/pip configuration optimizations

### What fast-download Does NOT Do
- ❌ Execute downloaded files automatically
- ❌ Disable SSL verification for speed
- ❌ Store credentials or tokens
- ❌ Phone home or collect telemetry
- ❌ Modify system files outside documented config

### Best Practices for Users
1. **Always verify checksums** when downloading from untrusted sources:
   ```bash
   aria2c --checksum=sha256=abc123... -o file.zip https://example.com/file.zip
   ```

2. **Use trusted sources** — fast-download assumes HTTPS from known hosts

3. **Keep aria2 updated** — security fixes in aria2 benefit you:
   ```bash
   # Windows
   winget upgrade aria2.aria2
   
   # macOS
   brew upgrade aria2
   
   # Linux
   apt upgrade aria2  # or dnf/pacman
   ```

4. **Review agent configs** before installing — they define download behavior

### Known Limitations
- aria2's Metalink/BitTorrent support could download from untrusted peers if Metalink files are compromised
- Git shallow clones don't verify commit signatures (use full clone for verification)
- Rate-limited servers may cause aria2 to fallback to curl (expected behavior)

## Security Updates

Security patches will be released as patch versions (e.g., 1.0.1) and announced via:
- GitHub Security Advisories
- Release notes
- Repository discussions

## Contact

Security contact: **Abdullah Al Hadi** — abdullahalhadi@proton.me