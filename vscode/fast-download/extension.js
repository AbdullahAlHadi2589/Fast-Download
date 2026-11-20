const vscode = require('vscode');
const { exec } = require('child_process');

function activate(context) {
    const downloadFile = vscode.commands.registerCommand('fast-download.downloadFile', async () => {
        const url = await vscode.window.showInputBox({ prompt: 'Enter file URL to download' });
        if (!url) return;
        const targetPath = await vscode.window.showInputBox({ prompt: 'Enter destination path' });
        if (!targetPath) return;

        const config = vscode.workspace.getConfiguration('fast-download');
        const maxConn = config.get('maxConnections', 16);
        const cmd = `aria2c -x ${maxConn} -s ${maxConn} -k 1M --continue=true -o "${targetPath}" "${url}"`;

        vscode.window.showInformationMessage(`Starting fast download: ${url}`);
        exec(cmd, (err, stdout, stderr) => {
            if (err) {
                vscode.window.showErrorMessage(`Download failed: ${stderr || err.message}`);
            } else {
                vscode.window.showInformationMessage(`Download completed: ${targetPath}`);
            }
        });
    });

    const cloneRepo = vscode.commands.registerCommand('fast-download.cloneRepo', async () => {
        const url = await vscode.window.showInputBox({ prompt: 'Enter Git repository URL' });
        if (!url) return;
        const targetDir = await vscode.window.showInputBox({ prompt: 'Enter destination directory' });
        if (!targetDir) return;

        const cmd = `git clone --depth 1 --single-branch --filter=blob:none "${url}" "${targetDir}"`;
        vscode.window.showInformationMessage(`Starting shallow clone: ${url}`);
        exec(cmd, (err, stdout, stderr) => {
            if (err) {
                vscode.window.showErrorMessage(`Clone failed: ${stderr || err.message}`);
            } else {
                vscode.window.showInformationMessage(`Repository cloned successfully to ${targetDir}`);
            }
        });
    });

    const verifyChecksum = vscode.commands.registerCommand('fast-download.verifyChecksum', async () => {
        const filePath = await vscode.window.showInputBox({ prompt: 'Enter file path' });
        if (!filePath) return;
        const expectedHash = await vscode.window.showInputBox({ prompt: 'Enter expected SHA256 checksum' });
        if (!expectedHash) return;

        const cleanHash = expectedHash.replace(/^(sha256|md5):/i, '');
        const isWin = process.platform === 'win32';
        const cmd = isWin
            ? `powershell -Command "(Get-FileHash -Algorithm SHA256 '${filePath}').Hash.ToLower()"`
            : `sha256sum "${filePath}" | cut -d' ' -f1`;

        exec(cmd, (err, stdout) => {
            if (err) {
                vscode.window.showErrorMessage(`Verification failed: ${err.message}`);
                return;
            }
            const actual = stdout.trim().toLowerCase();
            if (actual === cleanHash.toLowerCase()) {
                vscode.window.showInformationMessage('Checksum MATCHED!');
            } else {
                vscode.window.showErrorMessage(`Checksum MISMATCH: expected ${cleanHash}, got ${actual}`);
            }
        });
    });

    context.subscriptions.push(downloadFile, cloneRepo, verifyChecksum);
}

function deactivate() {}

module.exports = {
    activate,
    deactivate
};
