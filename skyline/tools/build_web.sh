#!/bin/bash
# Web build: export with Godot, then patch (audio fix, title, full-screen CSS, background sound stop).
# Usage: bash tools/build_web.sh
set -e
cd "$(dirname "$0")/.."
GODOT="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
mkdir -p build/web
python tools/subset_font.py
"$GODOT" --headless --path . --editor --quit-after 300 >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
python tools/patch_web.py build/web
ls -la build/web
