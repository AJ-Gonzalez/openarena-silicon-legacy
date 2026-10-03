# Homebrew formula for OpenArena Legacy for Apple Silicon.
# This repository doubles as the tap (docs.brew.sh/Taps — two-argument form):
#
#   brew tap AJ-Gonzalez/openarena https://github.com/AJ-Gonzalez/openarena-silicon-legacy.git
#   brew install --HEAD AJ-Gonzalez/openarena/openarena
#
# HEAD-only for now: there is no versioned release tarball yet. The game
# data is a pinned resource (sha256 below; upstream md5 checked in build.sh).

class Openarena < Formula
  desc "OpenArena 0.8.8 with the Apple Silicon engine port"
  homepage "https://github.com/AJ-Gonzalez/openarena-silicon-legacy"
  head "https://github.com/AJ-Gonzalez/openarena-silicon-legacy.git", branch: "main"
  license "GPL-2.0-or-later"

  depends_on :macos
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "sdl12-compat"

  resource "openarena-data" do
    url "https://archive.org/download/openarena-0.8.8/openarena-0.8.8.zip"
    sha256 "5a8faf7f5b51f351b0a1618c06b6b98a5f1a6758f1d39818de2c87df2a0bac4a"
  end

  def install
    # build.sh is the single build entry point. The formula provides the
    # dependencies and the pinned game data itself (Homebrew forbids network
    # access during the build phase), so tell the script to skip its own
    # dependency handling and downloads.
    ENV["SKIP_DEPS"] = "1"
    ENV["OA_DATA_ZIP"] = resource("openarena-data").cached_download.to_s
    ENV["OA_INSTALL_DIR"] = prefix.to_s
    system "./build.sh"

    (bin/"openarena").write <<~SH
      #!/bin/bash
      # SDL12COMPAT_FIX_BORDERLESS_FS_WIN=0: keep sdl12-compat from promoting
      # the game window to a macOS fullscreen Space (weird Space switching).
      export SDL12COMPAT_FIX_BORDERLESS_FS_WIN=0
      exec "#{prefix}/OpenArena.app/Contents/MacOS/openarena" "$@"
    SH
  end

  def caveats
    <<~EOS
      OpenArena.app is installed in #{prefix}.
      Launch it with:  open #{prefix}/OpenArena.app
      Or use the CLI wrapper:  openarena
    EOS
  end

  test do
    assert_match "ioq3+oa", shell_output("#{bin}/openarena +quit 2>&1")
  end
end
