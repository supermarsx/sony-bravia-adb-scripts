class SonyBraviaScripts < Formula
  desc "Sony Bravia TV ADB control scripts with 70+ actions"
  homepage "https://github.com/supermarsx/sony-bravia-adb-scripts"
  url "https://github.com/supermarsx/sony-bravia-adb-scripts/releases/download/rolling/sony-bravia-scripts-unix.zip"
  version "2.0.0-4b5a370"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"

  depends_on "powershell"
  depends_on "android-platform-tools"

  def install
    # Install main script and launcher
    libexec.install "sony-bravia-scripts.ps1"
    libexec.install "sony-bravia-scripts.sh"

    # Install documentation
    doc.install "readme.md" if File.exist?("readme.md")
    doc.install "license.md" if File.exist?("license.md")

    # Create wrapper script in bin
    (bin/"sony-bravia").write <<~EOS
      #!/bin/bash
      exec pwsh "#{libexec}/sony-bravia-scripts.ps1" "$@"
    EOS
  end

  test do
    # Test that the script can be invoked
    assert_match "Sony Bravia", shell_output("#{bin}/sony-bravia --help 2>&1", 0)
  end

  def caveats
    <<~EOS
      Sony Bravia ADB Scripts installed!

      Usage:
        sony-bravia                    # Interactive TUI mode
        sony-bravia -Action a1         # CLI mode (Home button)
        sony-bravia -Action "a1,a2"    # Batch mode
        sony-bravia -Batch file.txt    # File batch mode

      First-time setup:
        1. Enable USB debugging on your Sony Bravia TV
        2. Find your TV's IP address
        3. Connect: adb connect <tv-ip>:5555
        4. Run: sony-bravia

      Documentation: #{doc}
    EOS
  end
end
