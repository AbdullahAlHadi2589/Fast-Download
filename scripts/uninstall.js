#!/usr/bin/env node
// fast-download npm uninstaller
// Usage: npx fast-download uninstall [options]

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const INSTALL_DIR = path.join(os.homedir(), '.fast-download');

const args = process.argv.slice(2);
const force = args.includes('--force');
const revertConfigs = args.includes('--revert-configs');
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
            throw e;
        }
        return '';
    }
}

// Dry-run safe filesystem operations
function rmSyncSafe(path, options) {
    if (dryRun) {
        log(`DRY RUN: rm -rf ${path}`, 'info');
        return;
    }
    fs.rmSync(path, options);
}

function unlinkSyncSafe(path) {
    if (dryRun) {
        log(`DRY RUN: rm ${path}`, 'info');
        return;
    }
    fs.unlinkSync(path);
}

function copyFileSyncSafeForBackup(src, dst) {
    if (dryRun) {
        log(`DRY RUN: cp ${src} ${dst} (backup)`, 'info');
        return;
    }
    fs.copyFileSync(src, dst);
}

function writeFileSyncSafe(file, content) {
    if (dryRun) {
        log(`DRY RUN: write to ${file}`, 'info');
        return;
    }
    fs.writeFileSync(file, content);
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
    log('=== fast-download npm Uninstaller ===');
    log(`Install dir: ${INSTALL_DIR}`);

    if (!force) {
        // In a real scenario, we'd prompt. For now, just warn.
        log('Use --force to confirm uninstallation', 'warn');
        process.exit(1);
    }

    // Agent configurations to remove
    const agents = {
        'OpenCode': { path: path.join(os.homedir(), '.config/opencode/skill/fast-download'), type: 'dir' },
        'Claude Code': { path: path.join(os.homedir(), '.claude/agents/fast-download.md'), type: 'file' },
        'Codex': { path: path.join(os.homedir(), '.codex/agents/fast-download.md'), type: 'file' },
        'Continue': { path: path.join(os.homedir(), '.continue/agents/fast-download.yaml'), type: 'file' },
        'Cline': { path: path.join(os.homedir(), '.cline/skills/fast-download'), type: 'dir' },
        'VS Code': { path: path.join(os.homedir(), '.vscode/extensions/fast-download'), type: 'dir' },
        'Cursor': { path: path.join(os.homedir(), '.cursor/extensions/fast-download'), type: 'dir' },
        'Windsurf': { path: path.join(os.homedir(), '.windsurf/extensions/fast-download'), type: 'dir' },
        'JetBrains AI': { path: path.join(os.homedir(), '.config/JetBrains/ai/agents/fast-download.md'), type: 'file' },
        'Amazon Q': { path: path.join(os.homedir(), '.aws/amazonq/agents/fast-download.md'), type: 'file' },
        'Warp': { path: path.join(os.homedir(), '.warp/agents/fast-download.yaml'), type: 'file' }
    };

    for (const [name, config] of Object.entries(agents)) {
        if (fs.existsSync(config.path)) {
            try {
                if (config.type === 'dir') {
                    rmSyncSafe(config.path, { recursive: true, force: true });
                } else {
                    unlinkSyncSafe(config.path);
                }
                log(`Removed ${name} config`, 'success');
            } catch (e) {
                log(`Failed to remove ${name}: ${e.message}`, 'warn');
            }
        }
    }

    // Remove install directory
    if (fs.existsSync(INSTALL_DIR)) {
        try {
            rmSyncSafe(INSTALL_DIR, { recursive: true, force: true });
            log(`Removed ${INSTALL_DIR}`, 'success');
        } catch (e) {
            log(`Failed to remove install dir: ${e.message}`, 'warn');
        }
    }

    // Remove from PATH in shell RC files
    const shellRcs = [
        path.join(os.homedir(), '.bashrc'),
        path.join(os.homedir(), '.zshrc'),
        path.join(os.homedir(), '.config/fish/config.fish'),
        path.join(os.homedir(), '.config/nushell/config.nu'),
        path.join(os.homedir(), '.profile')
    ];

    for (const rc of shellRcs) {
        if (fs.existsSync(rc)) {
            let content = fs.readFileSync(rc, 'utf8');
            if (content.includes(INSTALL_DIR) || content.includes('fast-download')) {
                // Create backup
                copyFileSyncSafeForBackup(rc, `${rc}.bak`);
                // Remove fast-download lines
                const lines = content.split('\n').filter(line => 
                    !line.includes(INSTALL_DIR) && !line.includes('fast-download')
                );
                writeFileSyncSafe(rc, lines.join('\n'));
                log(`Removed PATH entry from ${rc}`, 'success');
            }
        }
    }

    // Revert global configs (optional)
    if (revertConfigs) {
        log('Reverting global configs...');
        
        if (hasCmd('git')) {
            run('git config --global --unset core.compression', { ignoreErrors: true });
            run('git config --global --unset core.preloadIndex', { ignoreErrors: true });
            run('git config --global --unset core.fscache', { ignoreErrors: true });
            run('git config --global --unset http.postBuffer', { ignoreErrors: true });
            run('git config --global --unset http.lowSpeedLimit', { ignoreErrors: true });
            run('git config --global --unset http.lowSpeedTime', { ignoreErrors: true });
            log('Git config reverted', 'success');
        }
        
        if (hasCmd('npm')) {
            run('npm config delete fetch-retries', { ignoreErrors: true });
            run('npm config delete fetch-retry-factor', { ignoreErrors: true });
            run('npm config delete prefer-offline', { ignoreErrors: true });
            log('npm config reverted', 'success');
        }
        
        if (hasCmd('pip')) {
            run('pip config unset global.retries', { ignoreErrors: true });
            run('pip config unset global.timeout', { ignoreErrors: true });
            log('pip config reverted', 'success');
        }
    } else {
        log('Global configs preserved (use --revert-configs to revert)', 'info');
    }

    log('', 'info');
    log('=== Uninstall Complete ===', 'success');
    log('', 'info');
    log('Note: Restart your terminal for PATH changes to take effect.', 'warn');
    log('Note: Shell RC backups saved as *.bak files', 'info');
}

main().catch(e => {
    log(`Uninstall failed: ${e.message}`, 'error');
    process.exit(1);
});