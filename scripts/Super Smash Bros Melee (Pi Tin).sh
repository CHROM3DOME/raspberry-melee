#!/bin/bash
# ==============================================================================
# RetroPie Port Launcher: Super Smash Bros. Melee (Pi Tin Handheld)
# Hardware: Raspberry Pi Zero 2W Handheld (2.8" SPI TFT LCD 320x240 / ILI9341)
# Controls: GPIOnext GPIO Button Matrix (Direct hardware polling)
# Video: DispmanX Hardware Layer 10010 (Seamless EmulationStation overlay)
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
    echo "[Melee-PiTin] Error: Could not change directory to $GAME_DIR"
    exit 1
}

# Verify binary
if [ ! -f "./melee_pi" ]; then
    echo "[Melee-PiTin] Error: Executable ./melee_pi not found in $GAME_DIR"
    exit 1
fi

# Verify game assets or ISO
if [ ! -d "./files" ] && [ ! -f "./game.iso" ] && [ ! -f "./GALE01.iso" ]; then
    echo "[Melee-PiTin] Error: No game assets found in $GAME_DIR."
    echo "[Melee-PiTin] Place your clean GameCube Melee ISO (GALE01) as $GAME_DIR/game.iso"
    exit 1
fi

# Ensure EmulationStation is safely resumed on exit or interrupt
cleanup() {
    killall -CONT emulationstation emulationstatio 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Freeze background EmulationStation to eliminate CPU contention
killall -STOP emulationstation emulationstatio 2>/dev/null || true

# Multi-core CPU scheduling and thread affinity
export OMP_WAIT_POLICY=PASSIVE
export GOMP_CPU_AFFINITY="2 3"
export OMP_NUM_THREADS=2
export MELEE_DUAL_CORE=1

# Pi Tin Video Settings:
# Video layer 10010 renders above ES directly to LCD framebuffers
export SDL_VIDEODRIVER=rpi
export SDL_RPI_VIDEO_LAYER=10010
export SDL_AUDIODRIVER=alsa
export MELEE_PI_TIN=1

# Run game binary
./melee_pi "$@"
