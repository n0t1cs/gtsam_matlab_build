#!/bin/bash

# GTSAM build script (no MATLAB / no Python wrapper).
# Intended for use inside a distrobox container without MATLAB.
# Builds + installs GTSAM with GTSAM_THROW_CHEIRALITY_EXCEPTION=OFF so that
# SmartProjectionPoseFactor does not throw on cheirality during projection.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

HOME_FOR_GTSAM="$HOME/GTSAM"
GTSAM_DIR="$HOME_FOR_GTSAM/gtsam"
BUILD_DIR="$GTSAM_DIR/build"
INSTALL_PREFIX="/usr/local"
GTSAM_TAG="4.2a9"

echo -e "${GREEN}=== GTSAM build (library only) ===${NC}"

# --- Prerequisites ---
REQUIRED="cmake build-essential libboost-all-dev libtbb-dev"
MISSING=""
for pkg in $REQUIRED; do
  dpkg -l | grep -q "^ii $pkg" || MISSING="$MISSING $pkg"
done
if [ -n "$MISSING" ]; then
  echo -e "${YELLOW}Installing:$MISSING${NC}"
  sudo apt-get install -y $MISSING
fi

# --- Source ---
if [ ! -d "$GTSAM_DIR" ]; then
  echo -e "${YELLOW}Cloning GTSAM into $GTSAM_DIR${NC}"
  mkdir -p "$HOME_FOR_GTSAM"
  cd "$HOME_FOR_GTSAM"
  git clone https://github.com/borglab/gtsam.git
fi

cd "$GTSAM_DIR"
git fetch --all --tags
git checkout "$GTSAM_TAG"

# --- Clean build dir ---
if [ -d "$BUILD_DIR" ]; then rm -rf "$BUILD_DIR"; fi
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

# --- Configure ---
echo -e "${GREEN}Configuring with CMake...${NC}"
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF \
  -DGTSAM_THROW_CHEIRALITY_EXCEPTION=OFF \
  -DGTSAM_BUILD_PYTHON=OFF \
  -DGTSAM_INSTALL_MATLAB_TOOLBOX=OFF \
  -DGTSAM_BUILD_TESTS=OFF \
  -DGTSAM_BUILD_EXAMPLES_ALWAYS=ON \
  -DGTSAM_BUILD_UNSTABLE=ON \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  ..

echo -e "${GREEN}CMake configuration complete.${NC}"

# --- Build ---
NPROC=$(($(nproc) - 1))
[ $NPROC -lt 1 ] && NPROC=1
echo -e "${GREEN}Building with -j$NPROC ...${NC}"
make -j$NPROC

# --- Install ---
echo -e "${GREEN}Installing to $INSTALL_PREFIX ...${NC}"
sudo make install

# --- ldconfig ---
if ! grep -q "$INSTALL_PREFIX/lib" /etc/ld.so.conf.d/gtsam.conf 2>/dev/null; then
  sudo bash -c "echo $INSTALL_PREFIX/lib > /etc/ld.so.conf.d/gtsam.conf"
fi
sudo ldconfig

# --- Verify the cheirality flag is actually off ---
CFG_HDR="$INSTALL_PREFIX/include/gtsam/config.h"
if [ -f "$CFG_HDR" ]; then
  if grep -E "^[[:space:]]*#define[[:space:]]+GTSAM_THROW_CHEIRALITY_EXCEPTION" "$CFG_HDR" >/dev/null; then
    echo -e "${RED}WARNING: GTSAM_THROW_CHEIRALITY_EXCEPTION is still defined in $CFG_HDR${NC}"
    echo -e "${RED}         The build did not pick up the flag. Inspect config.h.in.${NC}"
    exit 1
  else
    echo -e "${GREEN}OK: GTSAM_THROW_CHEIRALITY_EXCEPTION is NOT defined in config.h${NC}"
  fi
fi

if ldconfig -p | grep -q libgtsam.so; then
  echo -e "${GREEN}OK: libgtsam registered in ldconfig${NC}"
fi

echo -e "\n${GREEN}Done. Next:${NC}"
echo "  cd ~/catkin_ws && catkin clean fuims_work && catkin build fuims_work"
