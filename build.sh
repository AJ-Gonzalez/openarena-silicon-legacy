#!/usr/bin/env bash
#
# build.sh — the single command for this repo (agents.md goal 2).
# One run does everything: dependencies, build, game data, install.
# Result: /Applications/OpenArena.app, playable on Apple Silicon.
# Plan: roadmap.md Phase 5.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
CACHE="$BUILD/cache"
APP="$BUILD/OpenArena.app"
INSTALL_DIR="/Applications"

ENGINE_DIR="$ROOT/engine/openarena-engine-source-0.8.8"
GAMECODE_DIR="$ROOT/game_code/oa-0.8.8"
ENGINE_BUILD="$ENGINE_DIR/build/release-darwin-arm64"
GAMECODE_BUILD="$GAMECODE_DIR/build/release-darwin-arm64"

# Official OpenArena 0.8.8 data. Not tracked in git (too big); fetched and
# verified here. md5 is the checksum published by the OpenArena team.
DATA_URL="https://archive.org/download/openarena-0.8.8/openarena-0.8.8.zip"
DATA_MD5="9f353d96d7889c377349d692c3905e5b"
DATA_ZIP="$CACHE/openarena-0.8.8.zip"

step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- platform
step "Checking platform"
[ "$(uname -s)" = "Darwin" ] || die "This build targets macOS. Found: $(uname -s)"
[ "$(uname -m)" = "arm64" ] || die "This build targets Apple Silicon (arm64). Found: $(uname -m)"
echo "OK: macOS $(uname -r), arm64"

# -------------------------------------------------------------------- deps
# sdl12-compat: SDL 1.2 API on SDL2 (window, input, GL context).
# libogg/libvorbis: music and sound decoding the client links against.
step "Checking dependencies (Homebrew)"
command -v brew >/dev/null 2>&1 || die "Homebrew is required. Install it from https://brew.sh"
for pkg in sdl12-compat libogg libvorbis; do
	if brew list --versions "$pkg" >/dev/null 2>&1; then
		echo "OK: $pkg $(brew list --versions "$pkg" | awk '{print $2}')"
	else
		echo "Installing $pkg ..."
		brew install "$pkg"
	fi
done

# ------------------------------------------------------------------- build
step "Building game code (modules + QVMs)"
make -C "$GAMECODE_DIR"

step "Building engine (client, smp, dedicated)"
make -C "$ENGINE_DIR"

[ -x "$ENGINE_BUILD/openarena.arm64" ] || die "engine build did not produce openarena.arm64"
[ -f "$GAMECODE_BUILD/baseq3/vm/ui.qvm" ] || die "game code build did not produce QVMs"

# -------------------------------------------------------------------- data
# Game data (pk3) is art/content and stays unaltered and out of git.
step "Fetching game data"
mkdir -p "$CACHE"
fetch_data() {
	curl -fL --retry 3 -C - -o "$DATA_ZIP.part" "$DATA_URL"
	mv "$DATA_ZIP.part" "$DATA_ZIP"
}
if [ -f "$DATA_ZIP" ]; then
	echo "Cached: $DATA_ZIP"
else
	echo "Downloading $DATA_URL"
	fetch_data
fi
actual="$(md5 -q "$DATA_ZIP")"
if [ "$actual" != "$DATA_MD5" ]; then
	echo "Checksum mismatch ($actual), re-downloading once"
	rm -f "$DATA_ZIP"
	fetch_data
	actual="$(md5 -q "$DATA_ZIP")"
	[ "$actual" = "$DATA_MD5" ] || die "game data checksum mismatch: got $actual, want $DATA_MD5"
fi
echo "OK: md5 $actual matches upstream"

# ---------------------------------------------------------------- package
# Layout follows the historical make-macosx-ub.sh: the game data sits next to
# the binary in Contents/MacOS so the engine's default search path finds it.
step "Assembling OpenArena.app"
rm -rf "$APP"
MACOS="$APP/Contents/MacOS"
mkdir -p "$MACOS/baseoa" "$MACOS/missionpack" "$APP/Contents/Resources"

cp "$ENGINE_BUILD/openarena.arm64" "$MACOS/openarena"
cp "$ENGINE_DIR/misc/quake3.icns" "$APP/Contents/Resources/OpenArena.icns"
printf 'APPLIOOA' > "$APP/Contents/PkgInfo"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>OpenArena</string>
	<key>CFBundleDisplayName</key><string>OpenArena</string>
	<key>CFBundleIdentifier</key><string>ws.openarena.silicon-legacy</string>
	<key>CFBundleExecutable</key><string>openarena</string>
	<key>CFBundleIconFile</key><string>OpenArena.icns</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>0.8.8</string>
	<key>LSMinimumSystemVersion</key><string>11.0</string>
</dict>
</plist>
PLIST

unzip -qjo "$DATA_ZIP" 'openarena-0.8.8/baseoa/*.pk3'      -d "$MACOS/baseoa"
unzip -qjo "$DATA_ZIP" 'openarena-0.8.8/missionpack/*.pk3' -d "$MACOS/missionpack"

# Our game code, built above, shipped as a pk3: pure-server safe and it sorts
# after pak6-patch088.pk3, so it wins over the QVMs shipped in the data.
# Decision: interpreter, not native modules (roadmap.md decision 2).
# Note: NO zip -j here. The entries must keep their vm/ path or the engine
# will not find vm/<name>.qvm and falls back to the QVMs inside pak6.
(cd "$GAMECODE_BUILD/baseq3"    && zip -q "$MACOS/baseoa/z-vm.pk3"      vm/cgame.qvm vm/qagame.qvm vm/ui.qvm)
(cd "$GAMECODE_BUILD/missionpack" && zip -q "$MACOS/missionpack/z-vm.pk3" vm/cgame.qvm vm/qagame.qvm vm/ui.qvm)

echo "OK: $APP"

# ----------------------------------------------------------------- install
step "Installing to $INSTALL_DIR"
if [ -w "$INSTALL_DIR" ]; then
	rm -rf "$INSTALL_DIR/OpenArena.app"
	ditto "$APP" "$INSTALL_DIR/OpenArena.app"
else
	INSTALL_DIR="$HOME/Applications"
	mkdir -p "$INSTALL_DIR"
	rm -rf "$INSTALL_DIR/OpenArena.app"
	ditto "$APP" "$INSTALL_DIR/OpenArena.app"
fi
echo "OK: $INSTALL_DIR/OpenArena.app"

step "Done"
echo "Play: open \"$INSTALL_DIR/OpenArena.app\""
echo "Note: the game links Homebrew's sdl12-compat/libogg/libvorbis; run this"
echo "script again after a macOS or Homebrew change to rebuild and reinstall."
