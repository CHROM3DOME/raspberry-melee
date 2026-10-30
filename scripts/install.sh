#!/usr/bin/env bash
# ==============================================================================
# Super Smash Bros. Melee for Raspberry Pi - Interactive Installation Assistant
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================================================"
echo "    Super Smash Bros. Melee (Native Raspberry Pi Source Port Setup)             "
echo "================================================================================"
echo ""

# 1. Detect hardware
BOARD_MODEL=""
if [ -f /proc/device-tree/model ]; then
    BOARD_MODEL=$(tr -d '\0' < /proc/device-tree/model)
fi

echo "Detected Hardware: ${BOARD_MODEL:-Generic Linux / ARM}"
echo ""

# Suggest default profile based on detection
SUGGESTED=1
if echo "$BOARD_MODEL" | grep -qi "Zero 2"; then
    SUGGESTED=1
elif echo "$BOARD_MODEL" | grep -qi "Pi 4\|400\|Compute Module 4"; then
    SUGGESTED=3
fi

echo "Select hardware target profile to build:"
echo "  1) Raspberry Pi Zero 2W (Stock HDMI, standard USB/BT controllers, 60 FPS)"
echo "  2) Pi Tin Handheld (2.8\" SPI TFT LCD @ 320x240, GPIOnext GPIO input, DispmanX 10010)"
echo "  3) Raspberry Pi 4 / 400 / CM4 (Mesa KMSDRM, Cortex-A72 NEON, 480p 60 FPS, 4-Player Couch)"
echo ""
read -r -p "Enter choice [1-3] (Default: $SUGGESTED): " CHOICE
CHOICE="${CHOICE:-$SUGGESTED}"

case "$CHOICE" in
    1)
        PROFILE="Stock Raspberry Pi Zero 2W"
        PATCH_FILE="$ROOT_DIR/patches/0001-melee-pi-zero2w-stock.patch"
        BIN_NAME="melee_pi"
        CMAKE_FLAGS="-DTARGET_PI_ARM=1"
        ;;
    2)
        PROFILE="Pi Tin Handheld"
        PATCH_FILE="$ROOT_DIR/patches/0002-melee-pi-tin.patch"
        BIN_NAME="melee_pi"
        CMAKE_FLAGS="-DTARGET_PI_TIN=1"
        ;;
    3)
        PROFILE="Raspberry Pi 4 / 400 / CM4"
        PATCH_FILE="$ROOT_DIR/patches/0003-melee-pi4.patch"
        BIN_NAME="melee_pi4"
        CMAKE_FLAGS="-DTARGET_PI4=1"
        ;;
    *)
        echo "Invalid selection. Aborting."
        exit 1
        ;;
esac

echo ""
echo "Selected profile: $PROFILE"
echo "Using patch: $(basename "$PATCH_FILE")"
echo ""

# 2. Check for required build tools
echo "Checking build prerequisites..."
MISSING_PKGS=""
for pkg in git cmake gcc g++ libsdl2-dev; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS="$MISSING_PKGS $pkg"
    fi
done

if [ -n "$MISSING_PKGS" ]; then
    echo "The following build packages are missing:$MISSING_PKGS"
    read -r -p "Install them via apt? [Y/n]: " DO_APT
    DO_APT="${DO_APT:-Y}"
    if [[ "$DO_APT" =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y $MISSING_PKGS
        if [ "$CHOICE" = "3" ]; then
            sudo apt-get install -y libgles2-mesa-dev libegl1-mesa-dev libdrm-dev libgbm-dev
        else
            sudo apt-get install -y libraspberrypi-dev 2>/dev/null || true
        fi
    fi
fi

# 3. Setup workspace directory
WORK_DIR="${HOME}/melee_build"
echo ""
echo "Upstream source tree will be prepared in: $WORK_DIR"
read -r -p "Proceed with this path? [Y/n]: " DO_PATH
DO_PATH="${DO_PATH:-Y}"
if [[ ! "$DO_PATH" =~ ^[Yy]$ ]]; then
    read -r -p "Enter custom path: " WORK_DIR
fi

if [ -d "$WORK_DIR" ]; then
    echo "Directory $WORK_DIR already exists."
    read -r -p "Clean and re-clone? [y/N]: " RECLONE
    if [[ "$RECLONE" =~ ^[Yy]$ ]]; then
        rm -rf "$WORK_DIR"
    fi
fi

if [ ! -d "$WORK_DIR" ]; then
    echo "Cloning upstream melee-pc repository..."
    git clone https://github.com/999sian/melee-pc.git "$WORK_DIR"
    cd "$WORK_DIR"
    echo "Checking out verified upstream base commit (9d23d04)..."
    git checkout 9d23d04a4867000f200f7c49a37a0f3fc2c09fd2
else
    cd "$WORK_DIR"
    git reset --hard 9d23d04a4867000f200f7c49a37a0f3fc2c09fd2
    git clean -fdx
fi

# 4. Apply selected patch
echo ""
echo "Applying standalone patch: $(basename "$PATCH_FILE")..."
git apply "$PATCH_FILE"
echo "Patch applied cleanly with 0 errors!"

# 5. Build executable
echo ""
echo "Configuring build with CMake ($CMAKE_FLAGS)..."
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release $CMAKE_FLAGS

echo ""
echo "Compiling native binary using $(nproc) threads..."
cmake --build . -j"$(nproc)"

if [ ! -f "$BIN_NAME" ] && [ -f "melee_pi" ]; then
    BIN_NAME="melee_pi"
fi

if [ ! -f "$BIN_NAME" ]; then
    echo "Error: Build succeeded but target binary $BIN_NAME was not found."
    exit 1
fi
echo "Compilation successful: $(pwd)/$BIN_NAME"

# 6. Deployment to RetroPie
INSTALL_DIR="${HOME}/RetroPie/roms/ports/melee"
echo ""
echo "Default installation directory: $INSTALL_DIR"
read -r -p "Deploy binary and launchers to this location? [Y/n]: " DO_DEPLOY
DO_DEPLOY="${DO_DEPLOY:-Y}"

if [[ "$DO_DEPLOY" =~ ^[Yy]$ ]]; then
    mkdir -p "$INSTALL_DIR"
    cp "$BIN_NAME" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$BIN_NAME"

    # Install RetroPie launcher scripts
    PORTS_DIR="${HOME}/RetroPie/roms/ports"
    mkdir -p "$PORTS_DIR"
    
    if [ "$CHOICE" = "1" ]; then
        cp "$ROOT_DIR/scripts/Super Smash Bros Melee.sh" "$PORTS_DIR/"
        chmod +x "$PORTS_DIR/Super Smash Bros Melee.sh"
    elif [ "$CHOICE" = "2" ]; then
        cp "$ROOT_DIR/scripts/Super Smash Bros Melee (Pi Tin).sh" "$PORTS_DIR/"
        chmod +x "$PORTS_DIR/Super Smash Bros Melee (Pi Tin).sh"
    elif [ "$CHOICE" = "3" ]; then
        cp "$ROOT_DIR/scripts/Super Smash Bros Melee (Pi 4 480p).sh" "$PORTS_DIR/"
        chmod +x "$PORTS_DIR/Super Smash Bros Melee (Pi 4 480p).sh"
    fi

    cp "$ROOT_DIR/scripts/Super Smash Bros Melee (LAN Host).sh" "$PORTS_DIR/"
    cp "$ROOT_DIR/scripts/Super Smash Bros Melee (LAN Join).sh" "$PORTS_DIR/"
    chmod +x "$PORTS_DIR/Super Smash Bros Melee (LAN Host).sh"
    chmod +x "$PORTS_DIR/Super Smash Bros Melee (LAN Join).sh"

    echo "Launchers installed into $PORTS_DIR"
fi

# 7. Asset prompt
echo ""
echo "--------------------------------------------------------------------------------"
echo " Game Assets Notice (Intellectual Property)"
echo " Nintendo game assets are NOT included in this release."
echo " You must provide your own legitimately dumped GameCube Melee ISO (v1.02, GALE01)."
echo "--------------------------------------------------------------------------------"
read -r -p "Enter path to your legal GALE01.iso (or leave blank to supply later): " ISO_PATH
if [ -n "$ISO_PATH" ] && [ -f "$ISO_PATH" ]; then
    echo "Copying game ISO to $INSTALL_DIR/game.iso..."
    cp "$ISO_PATH" "$INSTALL_DIR/game.iso"
    echo "Game ISO copied successfully!"
else
    echo "No ISO specified. Before playing, place your GameCube Melee ISO as:"
    echo "  $INSTALL_DIR/game.iso"
fi

echo ""
echo "================================================================================"
echo " Installation Complete!"
echo " Restart EmulationStation to see Super Smash Bros. Melee in the Ports menu."
echo "================================================================================"
