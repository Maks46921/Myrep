#!/bin/bash
# v54_1: сборка игры, которая запускается без Godot: Windows (Symphony.exe) и Linux (Symphony.x86_64), оба с встроенными данными.
# Нужны шаблоны экспорта Godot 4.3 в ~/.local/share/godot/export_templates/4.3.stable/ (windows_release_x86_64.exe, linux_release.x86_64).
#   tools/export.sh [папка=../build]
set -e
cd "$(dirname "$0")/.."
OUT=$(realpath -m "${1:-../build}")
python3 tools/i18n.py build
mkdir -p "$OUT/windows" "$OUT/linux"
tools/godot.sh --headless --path . --import >/dev/null 2>&1 || true
tools/godot.sh --headless --path . --export-release "Windows Desktop" "$OUT/windows/Symphony.exe" 2>&1 | grep -E "ERROR|completed" | grep -v rcedit || true
tools/godot.sh --headless --path . --export-release "Linux" "$OUT/linux/Symphony.x86_64" 2>&1 | grep -E "ERROR|completed" || true
# иконка в exe без rcedit: рисуем icon.svg силами Godot и перезаписываем иконки шаблона
tools/godot.sh --headless --path . --script tools/svg2png.gd -- /tmp/symphony_icon256.png >/dev/null 2>&1
python3 tools/win_icon.py "$OUT/windows/Symphony.exe" /tmp/symphony_icon256.png
ls -la "$OUT/windows" "$OUT/linux"
