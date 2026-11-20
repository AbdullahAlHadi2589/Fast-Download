#!/usr/bin/env node
// fast-download CLI entry point
// Connects to the universal shell library (fast-download.sh) and PowerShell module

const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const INSTALL_DIR = path.join(os.homedir(), '.fast-download');
const REPO_ROOT = path.join(__dirname, '..');

function hasCmd(cmd) {
    try {
        const checkCmd = process.platform === 'win32' ? `where ${cmd}` : `which ${cmd}`;
        execSync(checkCmd, { stdio: 'ignore' });
        return true;
    } catch {
        return false;
    }
}

function getShellLib() {
    // Priority: installed location > repo source > bundled
    const candidates = [
        path.join(INSTALL_DIR, 'fast-download.sh'),
        path.join(REPO_ROOT, 'src', 'fast-download.sh'),
    ];
    for (const p of candidates) {
        if (fs.existsSync(p)) return p;
    }
    return null;
}

function getPSModule() {
    const candidates = [
        path.join(INSTALL_DIR, 'FastDownload.psm1'),
        path.join(REPO_ROOT, 'opencode', 'FastDownload.psm1'),
    ];
    for (const p of candidates) {
        if (fs.existsSync(p)) return p;
    }
    return null;
}

function printHelp() {
    console.log(`
fast-download - Universal download accelerator for AI coding agents

Usage:
  fast-download <command> [options]

Commands:
  download <url> <output> [checksum]  Download a file with smart tool selection
  git-clone <url> <dir> [shallow]     Clone a git repository (shallow by default)
  verify <file> <checksum>            Verify file checksum (SHA256/MD5)
  speed-test [url] [size]             Test download speed
  install [options]                   Install fast-download and agent configs
  uninstall [options]                 Uninstall fast-download
  init                                Apply git/npm/pip optimizations (opt-in)
  help                                Show this help

Options:
  --force-curl                        Force using curl instead of aria2
  --agent=<name>                      Agent to install config for (install only)
  --apply-global-configs              Apply global git/npm/pip optimizations (opt-in)
  --skip-aria2                        Skip aria2 installation check
  --skip-git-config                   Skip git config optimization
  --skip-npm-config                   Skip npm config optimization
  --skip-pip-config                   Skip pip config optimization
  --dry-run                           Show what would be done without making changes
  --force                             Force uninstall without confirmation
  --revert-configs                    Revert global git/npm/pip configs (uninstall)

Examples:
  fast-download download https://example.com/large.zip ./large.zip
  fast-download download https://example.com/file.zip ./file.zip sha256:abc123...
  fast-download git-clone https://github.com/user/repo.git ./repo true
  fast-download verify ./file.zip sha256:abc123...
  fast-download install --agent=opencode --dry-run
  fast-download uninstall --force --revert-configs
`);
}

function stripChecksumPrefix(cs) {
    if (!cs) return cs;
    return cs.replace(/^(sha256|md5):/i, '');
}

async function runDownload(args) {
    if (args.length < 2) {
        console.error('Usage: fast-download download <url> <output> [checksum]');
        process.exit(1);
    }
    const [url, output, rawChecksum] = args;
    const checksum = stripChecksumPrefix(rawChecksum);
    const forceCurl = process.argv.includes('--force-curl');
    
    const shellLib = getShellLib();
    if (shellLib) {
        const cmd = `source "${shellLib}" && fd_download "${url}" "${output}" "${checksum || ''}" "${forceCurl}"`;
        const result = spawnSync('bash', ['-c', cmd], { stdio: 'inherit', shell: true });
        process.exit(result.status || 0);
    }
    
    // Fallback to PowerShell module
    const psModule = getPSModule();
    if (psModule) {
        const psCmd = `Import-Module "${psModule}"; Invoke-FastDownload -Url "${url}" -OutputPath "${output}" ${checksum ? `-Checksum "${checksum}"` : ''} ${forceCurl ? '-ForceCurl' : ''}`;
        const result = spawnSync('powershell', ['-Command', psCmd], { stdio: 'inherit' });
        process.exit(result.status || 0);
    }
    
    console.error('Error: No shell library or PowerShell module found. Run install first.');
    process.exit(1);
}

async function runGitClone(args) {
    if (args.length < 2) {
        console.error('Usage: fast-download git-clone <url> <dir> [shallow]');
        process.exit(1);
    }
    const [url, dir, shallow] = args;
    
    const shellLib = getShellLib();
    if (shellLib) {
        const cmd = `source "${shellLib}" && fd_git_clone "${url}" "${dir}" "${shallow || 'true'}"`;
        const result = spawnSync('bash', ['-c', cmd], { stdio: 'inherit', shell: true });
        process.exit(result.status || 0);
    }
    
    const psModule = getPSModule();
    if (psModule) {
        const psCmd = `Import-Module "${psModule}"; Invoke-GitClone -Url "${url}" -OutputPath "${dir}" ${shallow !== 'false' ? '-Shallow' : ''}`;
        const result = spawnSync('powershell', ['-Command', psCmd], { stdio: 'inherit' });
        process.exit(result.status || 0);
    }
    
    console.error('Error: No shell library or PowerShell module found. Run install first.');
    process.exit(1);
}

async function runVerify(args) {
    if (args.length < 2) {
        console.error('Usage: fast-download verify <file> <checksum>');
        process.exit(1);
    }
    const [file, rawChecksum] = args;
    const checksum = stripChecksumPrefix(rawChecksum);
    
    const shellLib = getShellLib();
    if (shellLib) {
        const cmd = `source "${shellLib}" && fd_verify "${file}" "${checksum}"`;
        const result = spawnSync('bash', ['-c', cmd], { stdio: 'inherit', shell: true });
        process.exit(result.status || 0);
    }
    
    const psModule = getPSModule();
    if (psModule) {
        const psCmd = `Import-Module "${psModule}"; Test-FileChecksum -FilePath "${file}" -ExpectedHash "${checksum}"`;
        const result = spawnSync('powershell', ['-Command', psCmd], { stdio: 'inherit' });
        process.exit(result.status || 0);
    }
    
    console.error('Error: No shell library or PowerShell module found. Run install first.');
    process.exit(1);
}

async function runSpeedTest(args) {
    const [url, size] = args;
    
    const shellLib = getShellLib();
    if (shellLib) {
        const cmd = `source "${shellLib}" && fd_speed_test "${url || 'http://proof.ovh.net/files/100Mb.dat'}" "${size || '100'}"`;
        const result = spawnSync('bash', ['-c', cmd], { stdio: 'inherit', shell: true });
        process.exit(result.status || 0);
    }
    
    console.error('Error: No shell library found. Run install first.');
    process.exit(1);
}

async function runInstall(args) {
    const installScript = path.join(__dirname, 'install.js');
    if (!fs.existsSync(installScript)) {
        console.error('Error: install.js not found');
        process.exit(1);
    }
    const result = spawnSync('node', [installScript, ...args], { stdio: 'inherit' });
    process.exit(result.status || 0);
}

async function runUninstall(args) {
    const uninstallScript = path.join(__dirname, 'uninstall.js');
    if (!fs.existsSync(uninstallScript)) {
        console.error('Error: uninstall.js not found');
        process.exit(1);
    }
    const result = spawnSync('node', [uninstallScript, ...args], { stdio: 'inherit' });
    process.exit(result.status || 0);
}

async function runInit(args) {
    const shellLib = getShellLib();
    if (shellLib) {
        const cmd = `source "${shellLib}" && fd_init`;
        const result = spawnSync('bash', ['-c', cmd], { stdio: 'inherit', shell: true });
        process.exit(result.status || 0);
    }
    console.error('Error: No shell library found. Run install first.');
    process.exit(1);
}

async function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    const cmdArgs = args.slice(1);
    
    switch (command) {
        case 'download':
            await runDownload(cmdArgs);
            break;
        case 'git-clone':
            await runGitClone(cmdArgs);
            break;
        case 'verify':
            await runVerify(cmdArgs);
            break;
        case 'speed-test':
            await runSpeedTest(cmdArgs);
            break;
        case 'install':
            await runInstall(cmdArgs);
            break;
        case 'uninstall':
            await runUninstall(cmdArgs);
            break;
        case 'init':
            await runInit(cmdArgs);
            break;
        case 'help':
        case '--help':
        case '-h':
        default:
            printHelp();
            if (!command) process.exit(1);
    }
}

main().catch(e => {
    console.error(`Error: ${e.message}`);
    process.exit(1);
});