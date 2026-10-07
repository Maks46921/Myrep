#!/bin/bash
# Обёртка запуска Godot: GODOT=/путь/к/godot (по умолчанию ищем в PATH и в /home/claude/godot)
G=${GODOT:-$(command -v godot || echo /home/claude/godot/Godot_v4.3-stable_linux.x86_64)}
exec "$G" "$@"
