#!/bin/bash
# ==============================================================================
# RetroPie Port Launcher: Super Smash Bros. Melee (LAN Netplay Host - Player 1)
# Hardware: Raspberry Pi Zero 2W / Pi Tin / Pi 4 (Auto-Detecting)
# Network: UDP Lockstep Netplay with LAN Broadcast Beacon on Port 41000
# ==============================================================================

# Locate game installation directory (dual-path auto-detection)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_NAME="melee_pi"
[ -f "$SCRIPT_DIR/melee_pi4" ] && BIN_NAME="melee_pi4"

if [ -d "/home/pi/RetroPie/roms/ports/melee" ] && ([ -f "/home/pi/RetroPie/roms/ports/melee/melee_pi" ] || [ -f "/home/pi/RetroPie/roms/ports/melee/melee_pi4" ]); then
    GAME_DIR="/home/pi/RetroPie/roms/ports/melee"
    [ -f "$GAME_DIR/melee_pi4" ] && BIN_NAME="melee_pi4"
elif [ -d "/home/pi/melee_port" ] && ([ -f "/home/pi/melee_port/melee_pi" ] || [ -f "/home/pi/melee_port/melee_pi4" ]); then
    GAME_DIR="/home/pi/melee_port"
    [ -f "$GAME_DIR/melee_pi4" ] && BIN_NAME="melee_pi4"
elif [ -f "${SCRIPT_DIR}/$BIN_NAME" ]; then
    GAME_DIR="${SCRIPT_DIR}"
elif [ -f "${SCRIPT_DIR}/melee/$BIN_NAME" ]; then
    GAME_DIR="${SCRIPT_DIR}/melee"
else
    GAME_DIR="/home/pi/RetroPie/roms/ports/melee"
fi

cd "$GAME_DIR" || {
    echo "[Melee-LAN] Error: Could not change directory to $GAME_DIR"
    exit 1
}

# Verify binary
if [ ! -f "./$BIN_NAME" ]; then
    echo "[Melee-LAN] Error: Executable ./$BIN_NAME not found in $GAME_DIR"
    exit 1
fi

# Verify game assets or ISO
if [ ! -d "./files" ] && [ ! -f "./game.iso" ] && [ ! -f "./GALE01.iso" ]; then
    echo "[Melee-LAN] Error: No game assets found in $GAME_DIR."
    echo "[Melee-LAN] Place your clean GameCube Melee ISO (GALE01) as $GAME_DIR/game.iso"
    exit 1
fi

# Cleanup handler
cleanup() {
    killall -CONT emulationstation emulationstatio 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Video driver detection
if [ -c /dev/vchiq ] && [ "$BIN_NAME" != "melee_pi4" ]; then
    export SDL_VIDEODRIVER=rpi
    # If Pi Tin environment flag is set or fbcp is running, use layer 10010
    if pgrep -f fbcp >/dev/null 2>&1 || [ "$MELEE_PI_TIN" = "1" ]; then
        export SDL_RPI_VIDEO_LAYER=10010
    else
        export SDL_RPI_VIDEO_LAYER=10000
    fi
    killall -STOP emulationstation emulationstatio 2>/dev/null || true
else
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        export SDL_VIDEODRIVER=kmsdrm
    fi
fi

export SDL_AUDIODRIVER=alsa
export MELEE_DUAL_CORE=1
export OMP_WAIT_POLICY=PASSIVE
export GOMP_CPU_AFFINITY="2 3"
export OMP_NUM_THREADS=2

# Enable LAN Netplay Host Mode (Player 1)
export MELEE_NET_HOST=1
export MELEE_NET_PORT=41000
export MELEE_NET_DELAY=2

echo "[Melee-LAN] Starting Super Smash Bros. Melee in Host mode on UDP port 41000..." > "$GAME_DIR/melee_net.log"
exec ./"$BIN_NAME" "$@" >> "$GAME_DIR/melee_net.log" 2>&1
