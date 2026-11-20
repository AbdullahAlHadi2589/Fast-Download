class FastDownload < Formula
  desc "Universal download accelerator for AI coding agents - aria2 multi-connection downloads, Git shallow clones, checksum verification"
  homepage "https://github.com/AbdullahAlHadi2589/Fast-Download"
  url "https://github.com/AbdullahAlHadi2589/Fast-Download/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "TODO"
  license "MIT"
  head "https://github.com/AbdullahAlHadi2589/Fast-Download.git", branch: "master"

  depends_on "aria2"
  depends_on "git"

  def install
    # Install shell library
    libexec.install "src/fast-download.sh"
    
    # Install agent configurations
    prefix.install "opencode"
    prefix.install "claude-code"
    prefix.install "codex"
    prefix.install "continue"
    prefix.install "cline"
    prefix.install "vscode"
    
    # Install scripts
    libexec.install "scripts/install.sh"
    libexec.install "scripts/uninstall.sh"
    
    # Create symlinks
    bin.install_symlink libexec/"fast-download.sh" => "fast-download"
    bin.install_symlink libexec/"install.sh" => "fast-download-install"
    bin.install_symlink libexec/"uninstall.sh" => "fast-download-uninstall"
    
    # Generate shell completions
    generate_completions_from_executable(bin/"fast-download", "completion")
  end

  def caveats
    <<~EOS
      To use fast-download in your shell, add to your ~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish:

        # Bash/Zsh
        source $(brew --prefix)/libexec/fast-download.sh

        # Fish
        source (brew --prefix)/libexec/fast-download.sh

      Then reload your shell:
        source ~/.bashrc  # or ~/.zshrc

      For AI agents, run the installer:
        fast-download-install

      This will deploy configurations for:
      - OpenCode
      - Claude Code
      - Codex
      - Continue
      - Cline
      - VS Code / Cursor / Windsurf

      See https://github.com/AbdullahAlHadi2589/Fast-Download for details.
    EOS
  end

  test do
    # Test shell library loads
    system bin/"fast-download", "--help"
    
    # Test functions are defined
    assert_match "fd_download", shell_output("source #{libexec}/fast-download.sh && declare -f fd_download")
    assert_match "fd_git_clone", shell_output("source #{libexec}/fast-download.sh && declare -f fd_git_clone")
    assert_match "fd_verify", shell_output("source #{libexec}/fast-download.sh && declare -f fd_verify")
    
    # Test aria2 integration
    assert_match "aria2c", shell_output("source #{libexec}/fast-download.sh && fd_speed_test https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip 2 2>&1 | head -20")
  end
end