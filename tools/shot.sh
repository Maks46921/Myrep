#!/bin/bash
# tools/shot.sh CC [экран=6] [месяцев=14]  -> /tmp/shot_CC.png   (нужен xvfb-run)
# экраны: 0 Бюджет, 5 Экономика, 2 Карта, 1 Парламент, 3 Законы, 4 Правительство, 6 Население
CC=${1:-DE}; DESK=${2:-6}; MON=${3:-14}
cd "$(dirname "$0")/.."
xvfb-run -a -s "-screen 0 1700x900x24" tools/godot.sh --rendering-driver opengl3 --path . --script tests/shot.gd -- country=$CC desk=$DESK months=$MON out=/tmp/shot_$CC.png "${@:4}" 2>&1 | grep -E "saved|SCRIPT ERROR|Parse"
