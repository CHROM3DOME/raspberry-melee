#!/bin/bash
# ==============================================================================
# RetroPie Port Launcher: Super Smash Bros. Melee (Raspberry Pi 4 / 400 / CM4)
# Hardware: Broadcom BCM2711 Cortex-A72 / VideoCore VI GPU
# Video: Mesa KMS/DRM (vc4-kms-v3d) Fullscreen 480p (640x480) with 4:3 Aspect
# ==============================================================================

# Locate game installation directory (dual-path auto-detection)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_NAME="melee_pi4"
[ ! -f "$SCRIPT_DIR/$BIN_NAME" ] && [ -f "$SCRIPT_DIR/melee_pi" ] && BIN_NAME="melee_pi"

if [ -d "/home/pi/RetroPie/roms/ports/melee" ] && ([ -f "/home/pi/RetroPie/roms/ports/melee/melee_pi4" ] || [ -f "/home/pi/RetroPie/roms/ports/melee/melee_pi" ]); then
    GAME_DIR="/home/pi/RetroPie/roms/ports/melee"
    [ -f "$GAME_DIR/melee_pi4" ] && BIN_NAME="melee_pi4" || BIN_NAME="melee_pi"
elif [ -d "/home/pi/melee_port" ] && ([ -f "/home/pi/melee_port/melee_pi4" ] || [ -f "/home/pi/melee_port/melee_pi" ]); then
    GAME_DIR="/home/pi/melee_port"
    [ -f "$GAME_DIR/melee_pi4" ] && BIN_NAME="melee_pi4" || BIN_NAME="melee_pi"
elif [ -f "${SCRIPT_DIR}/$BIN_NAME" ]; then
    GAME_DIR="${SCRIPT_DIR}"
elif [ -f "${SCRIPT_DIR}/melee/$BIN_NAME" ]; then
    GAME_DIR="${SCRIPT_DIR}/melee"
else
    GAME_DIR="/home/pi/RetroPie/roms/ports/melee"
fi

cd "$GAME_DIR" || {
    echo "[Melee-Pi4] Error: Could not change directory to $GAME_DIR"
    exit 1
}

# Verify binary
if [ ! -f "./$BIN_NAME" ]; then
    echo "[Melee-Pi4] Error: Executable ./$BIN_NAME not found in $GAME_DIR"
    exit 1
fi

# Verify game assets or ISO
if [ ! -d "./files" ] && [ ! -f "./game.iso" ] && [ ! -f "./GALE01.iso" ]; then
    echo "[Melee-Pi4] Error: No game assets found in $GAME_DIR."
    echo "[Melee-Pi4] Place your clean GameCube Melee ISO (GALE01) as $GAME_DIR/game.iso"
    exit 1
fi

# Mesa KMS/DRM Hardware Acceleration
export SDL_VIDEODRIVER=KMSDRM
export SDL_AUDIODRIVER=alsa

# Performance & Render Thread Tuning for Cortex-A72
export MELEE_DUAL_CORE=1
export OMP_WAIT_POLICY=PASSIVE
export GOMP_CPU_AFFINITY="1 2 3"
export OMP_NUM_THREADS=2

# Display resolution: Native GameCube 480p with aspect pillarboxing
export MELEE_RESOLUTION_WIDTH=640
export MELEE_RESOLUTION_HEIGHT=480

exec ./"$BIN_NAME" "$@"
