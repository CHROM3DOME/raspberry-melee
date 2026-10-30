#!/bin/bash
# ==============================================================================
# RetroPie Port Launcher: Super Smash Bros. Melee (Stock Raspberry Pi Zero 2W)
# Hardware: Raspberry Pi Zero 2W (BCM2710A1 Cortex-A53 / VideoCore IV)
# Display: Standard HDMI (640x480 / 320x240)
# ==============================================================================

# Locate game installation directory (dual-path auto-detection)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "/home/pi/RetroPie/roms/ports/melee" ] && [ -f "/home/pi/RetroPie/roms/ports/melee/melee_pi" ]; then
    GAME_DIR="/home/pi/RetroPie/roms/ports/melee"
elif [ -d "/home/pi/melee_port" ] && [ -f "/home/pi/melee_port/melee_pi" ]; then
    GAME_DIR="/home/pi/melee_port"
elif [ -f "${SCRIPT_DIR}/melee_pi" ]; then
    GAME_DIR="${SCRIPT_DIR}"
elif [ -f "${SCRIPT_DIR}/melee/melee_pi" ]; then
    GAME_DIR="${SCRIPT_DIR}/melee"
else
    GAME_DIR="/home/pi/RetroPie/roms/ports/melee"
fi

cd "$GAME_DIR" || {
    echo "[Melee-Pi] Error: Could not change directory to $GAME_DIR"
    exit 1
}

# Verify required binary exists
if [ ! -f "./melee_pi" ]; then
    echo "[Melee-Pi] Error: Executable ./melee_pi not found in $GAME_DIR"
    exit 1
fi

# Verify game assets or ISO exist
if [ ! -d "./files" ] && [ ! -f "./game.iso" ] && [ ! -f "./GALE01.iso" ]; then
    echo "[Melee-Pi] Error: No game assets found in $GAME_DIR."
    echo "[Melee-Pi] Please place your legal copy of Super Smash Bros. Melee (GALE01.iso) as:"
    echo "           $GAME_DIR/game.iso"
    exit 1
fi

# Multi-core CPU scheduling and thread affinity
# Logic on Core 0/1, GLES 2.0 asynchronous render pipeline on Core 2/3
export OMP_WAIT_POLICY=PASSIVE
export GOMP_CPU_AFFINITY="2 3"
export OMP_NUM_THREADS=2
export MELEE_DUAL_CORE=1

# VideoCore IV Hardware Acceleration
export SDL_VIDEODRIVER=rpi
export SDL_AUDIODRIVER=alsa

# Launch game
exec ./melee_pi "$@"
