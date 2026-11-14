#!/usr/bin/env node
// fast-download npm installer
// Usage: npx fast-download install [options]

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const REPO_ROOT = path.join(__dirname, '..');
const INSTALL_DIR = path.join(os.homedir(), '.fast-download');

const args = process.argv.slice(2);
const agentArg = args.find(a => a.startsWith('--agent='));
const agents = agentArg ? agentArg.split('=')[1].split(',') : 'all';
const skipAria2 = args.includes('--skip-aria2');
const skipGitConfig = args.includes('--skip-git-config');
const skipNpmConfig = args.includes('--skip-npm-config');
const skipPipConfig = args.includes('--skip-pip-config');
const dryRun = args.includes('--dry-run');

function log(message, level = 'info') {
    const colors = {
        info: '\x1b[36m',
        warn: '\x1b[33m',
        error: '\x1b[31m',
        success: '\x1b[32m',
        reset: '\x1b[0m'
    };
    console.log(`${colors[level]}[${new Date().toLocaleTimeString()}]${colors.reset} ${message}`);
}

function run(cmd, options = {}) {
    if (dryRun) {
        log(`DRY RUN: ${cmd}`, 'info');
        return '';
    }
    try {
        return execSync(cmd, { 
            stdio: 'pipe', 
            encoding: 'utf8',
            ...options 
        }).trim();
    } catch (e) {
        if (!options.ignoreErrors) {
            log(`Command failed: ${cmd}`, 'error');
            log(e.stdout || e.message, 'error');
            throw e;
        }
        return '';
    }
}

function hasCmd(cmd) {
    try {
        execSync(`which ${cmd}`, { stdio: 'ignore' });
        return true;
    } catch {
        return false;
    }
}

async function main() {
    log('=== fast-download npm Installer ===');
    log(`Install dir: ${INSTALL_DIR}`);
    log(`Agents: ${agents}`);

    // 1. Install aria2
    if (!skipAria2) {
        log('Checking aria2...');
        if (hasCmd('aria2c')) {
            log(`aria2 already installed: ${run('aria2c --version | head -1')}`, 'success');
        } else {
            log('aria2 not found. Please install manually:', 'warn');
            log('  macOS: brew install aria2', 'info');
            log('  Linux: apt/dnf/pacman install aria2', 'info');
            log('  Windows: winget install aria2.aria2', 'info');
        }
    }

    // 2. Install Git
    if (hasCmd('git')) {
        log(`Git found: ${run('git --version')}`, 'success');
    } else {
        log('Git not found. Please install manually.', 'warn');
    }

    // 3. Create install directory
    if (!fs.existsSync(INSTALL_DIR)) {
        fs.mkdirSync(INSTALL_DIR, { recursive: true });
        log(`Created ${INSTALL_DIR}`);
    }

    // 4. Copy shell libraries
    const libs = ['fast-download.sh', 'fast-download.fish', 'fast-download.nu'];
    for (const lib of libs) {
        const src = path.join(REPO_ROOT, 'src', lib);
        const dst = path.join(INSTALL_DIR, lib);
        if (fs.existsSync(src)) {
            fs.copyFileSync(src, dst);
            if (lib.endsWith('.sh')) {
                fs.chmodSync(dst, 0o755);
            }
            log(`Copied ${lib}`, 'success');
        }
    }

    // 5. Apply global configs
    if (!skipGitConfig && hasCmd('git')) {
        log('Applying Git optimizations...');
        run('git config --global core.compression 9');
        run('git config --global core.preloadIndex true');
        run('git config --global core.fscache true');
        run('git config --global http.postBuffer 524288000');
        run('git config --global http.lowSpeedLimit 0');
        run('git config --global http.lowSpeedTime 999999');
        log('Git config applied', 'success');
    }

    if (!skipNpmConfig && hasCmd('npm')) {
        log('Applying npm optimizations...');
        run('npm config set fetch-retries 5');
        run('npm config set fetch-retry-factor 2');
        run('npm config set prefer-offline true');
        log('npm config applied', 'success');
    }

    if (!skipPipConfig && hasCmd('pip')) {
        log('Applying pip optimizations...');
        run('pip config set global.retries 5');
        run('pip config set global.timeout 60');
        log('pip config applied', 'success');
    }

    // 6. Deploy agent configurations
    const allAgents = ['opencode', 'claude-code', 'codex', 'continue', 'cline', 'vscode', 'cursor', 'windsurf', 'jetbrains', 'amazon-q', 'warp'];
    const deployAgents = agents === 'all' ? allAgents : agents;

    for (const agent of deployAgents) {
        log(`Deploying ${agent} configuration...`);
        try {
            switch (agent) {
                case 'opencode':
                    deployDir(path.join(REPO_ROOT, 'opencode'), path.join(os.homedir(), '.config/opencode/skill/fast-download'));
                    break;
                case 'claude-code':
                    deployFile(path.join(REPO_ROOT, 'claude-code/fast-download.md'), path.join(os.homedir(), '.claude/agents/fast-download.md'));
                    break;
                case 'codex':
                    deployFile(path.join(REPO_ROOT, 'codex/fast-download.md'), path.join(os.homedir(), '.codex/agents/fast-download.md'));
                    break;
                case 'continue':
                    deployFile(path.join(REPO_ROOT, 'continue/fast-download.yaml'), path.join(os.homedir(), '.continue/agents/fast-download.yaml'));
                    break;
                case 'cline':
                    deployDir(path.join(REPO_ROOT, 'cline/fast-download'), path.join(os.homedir(), '.cline/skills/fast-download'));
                    break;
                case 'vscode':
                    deployDir(path.join(REPO_ROOT, 'vscode/fast-download'), path.join(os.homedir(), '.vscode/extensions/fast-download'));
                    break;
                case 'cursor':
                    deployDir(path.join(REPO_ROOT, 'vscode/fast-download'), path.join(os.homedir(), '.cursor/extensions/fast-download'));
                    break;
                case 'windsurf':
                    deployDir(path.join(REPO_ROOT, 'vscode/fast-download'), path.join(os.homedir(), '.windsurf/extensions/fast-download'));
                    break;
                case 'jetbrains':
                    deployFile(path.join(REPO_ROOT, 'claude-code/fast-download.md'), path.join(os.homedir(), '.config/JetBrains/ai/agents/fast-download.md'));
                    break;
                case 'amazon-q':
                    deployFile(path.join(REPO_ROOT, 'claude-code/fast-download.md'), path.join(os.homedir(), '.aws/amazonq/agents/fast-download.md'));
                    break;
                case 'warp':
                    deployFile(path.join(REPO_ROOT, 'continue/fast-download.yaml'), path.join(os.homedir(), '.warp/agents/fast-download.yaml'));
                    break;
            }
        } catch (e) {
            log(`Failed to deploy ${agent}: ${e.message}`, 'warn');
        }
    }

    // 7. Add to PATH
    const shellRc = getShellRc();
    const pathEntry = `export PATH="$PATH:${INSTALL_DIR}"`;
    if (shellRc && fs.existsSync(shellRc)) {
        const content = fs.readFileSync(shellRc, 'utf8');
        if (!content.includes(INSTALL_DIR)) {
            fs.appendFileSync(shellRc, `\n# fast-download\n${pathEntry}\n`);
            log(`Added ${INSTALL_DIR} to PATH in ${shellRc}`, 'success');
        }
    }

    // 8. Verify
    log('=== Verification ===', 'info');
    for (const tool of ['aria2c', 'git', 'curl']) {
        if (hasCmd(tool)) {
            log(`${tool}: Available`, 'success');
        } else {
            log(`${tool}: NOT FOUND`, 'warn');
        }
    }

    // 9. Final message
    log('', 'info');
    log('=== Installation Complete ===', 'success');
    log('', 'info');
    log('Next steps:');
    log('  1. RESTART YOUR TERMINAL or run: source ~/.bashrc (or ~/.zshrc)');
    log('  2. Test: aria2c --version');
    log('  3. Use in any terminal:');
    log('     aria2c -x 16 -s 16 -o "file.zip" "https://url/file.zip"');
    log('     git clone --depth 1 --filter=blob:none https://github.com/user/repo.git');
    log('');
    log('Shell libraries installed:');
    log(`  Bash/Zsh:   source ${INSTALL_DIR}/fast-download.sh`);
    log(`  Fish:       source ${INSTALL_DIR}/fast-download.fish`);
    log(`  Nushell:    source ${INSTALL_DIR}/fast-download.nu`);
    log('');
    log('Agent configs deployed:');
    for (const a of deployAgents) {
        log(`  - ${a}`);
    }
    log('');
    log('IMPORTANT: Restart your terminal for PATH changes to take effect.', 'warn');
}

function deployDir(src, dst) {
    if (!fs.existsSync(src)) return;
    if (!fs.existsSync(dst)) {
        fs.mkdirSync(dst, { recursive: true });
    }
    copyRecursive(src, dst);
    log(`${path.basename(src)} deployed to ${dst}`, 'success');
}

function deployFile(src, dst) {
    if (!fs.existsSync(src)) return;
    const dir = path.dirname(dst);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    fs.copyFileSync(src, dst);
    log(`${path.basename(src)} deployed to ${dst}`, 'success');
}

function copyRecursive(src, dst) {
    const entries = fs.readdirSync(src, { withFileTypes: true });
    for (const entry of entries) {
        const srcPath = path.join(src, entry.name);
        const dstPath = path.join(dst, entry.name);
        if (entry.isDirectory()) {
            if (!fs.existsSync(dstPath)) {
                fs.mkdirSync(dstPath, { recursive: true });
            }
            copyRecursive(srcPath, dstPath);
        } else {
            fs.copyFileSync(srcPath, dstPath);
        }
    }
}

function getShellRc() {
    const shell = process.env.SHELL || '';
    if (shell.includes('zsh')) return path.join(os.homedir(), '.zshrc');
    if (shell.includes('bash')) return path.join(os.homedir(), '.bashrc');
    if (shell.includes('fish')) return path.join(os.homedir(), '.config/fish/config.fish');
    if (shell.includes('nu')) return path.join(os.homedir(), '.config/nushell/config.nu');
    return path.join(os.homedir(), '.profile');
}

main().catch(e => {
    log(`Installation failed: ${e.message}`, 'error');
    process.exit(1);
});