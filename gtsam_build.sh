#!/bin/bash

# GTSAM Complete Installation Script (Improved v2.2)
# Installs GTSAM library system-wide with MATLAB
# Automatically configures LD_LIBRARY_PATH for MATLAB compatibility
# Author: n0t1cs@n0t1cs-HP
# Date: October 29, 2025

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}GTSAM Complete Installation Script (v2.2)${NC}"
echo -e "${GREEN}================================================${NC}"

# Configuration
HOME_FOR_GTSAM="$HOME/GTSAM"
GTSAM_DIR="$HOME_FOR_GTSAM/gtsam"
BUILD_DIR="$GTSAM_DIR/build"
MATLAB_ROOT="/usr/local/MATLAB/R2025b" # Adjust if needed
MATLAB_TOOLBOX_PATH="$HOME/Documents/MATLAB"
INSTALL_PREFIX="/usr/local"

export PATH="$MATLAB_ROOT/bin:$PATH"

# Step 1: Check prerequisites
echo -e "\n${GREEN}[Step 1/9] Checking prerequisites...${NC}"

REQUIRED_PACKAGES="cmake build-essential libboost-all-dev libtbb-dev python3-dev"
MISSING_PACKAGES=""

for pkg in $REQUIRED_PACKAGES; do
  if ! dpkg -l | grep -q "^ii $pkg"; then
    MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
  fi
done

if [ -n "$MISSING_PACKAGES" ]; then
  echo -e "${YELLOW}Installing missing packages:$MISSING_PACKAGES${NC}"
  sudo apt-get update
  sudo apt-get install -y $MISSING_PACKAGES
else
  echo -e "${GREEN}All required packages are installed.${NC}"
fi

# Check MATLAB installation
echo "Checking MATLAB installation..."
if [ ! -d "$MATLAB_ROOT" ]; then
  echo -e "${RED}ERROR: MATLAB not found at $MATLAB_ROOT${NC}"
  echo -e "${YELLOW}Please update MATLAB_ROOT variable in this script.${NC}"
  exit 1
fi

MEX_PATH="$MATLAB_ROOT/bin/mex"
if [ ! -f "$MEX_PATH" ]; then
  echo -e "${RED}ERROR: mex compiler not found at $MEX_PATH${NC}"
  exit 1
fi

echo -e "${GREEN}MATLAB found at: $MATLAB_ROOT${NC}"

# Step 2: Verify directories
echo -e "\n${GREEN}[Step 2/9] Verifying source directories...${NC}"

if [ ! -d "$GTSAM_DIR" ]; then
  echo -e "${YELLOW}Cloning GTSAM repository...${NC}"
  cd "$HOME_FOR_GTSAM"
  git clone https://github.com/borglab/gtsam.git
fi

cd "$GTSAM_DIR"
git fetch --all --tags
git checkout 4.2a9

echo -e "${GREEN}Working directory: $(pwd)${NC}"

# Step 2.5: Install gtwrap Python module (CRITICAL!)
echo -e "\n${GREEN}[Step 2.5/9] Installing gtwrap Python module...${NC}"

cd "$GTSAM_DIR/wrap"

echo "Attempting gtwrap installation with --break-system-packages..."
pip3 install --break-system-packages . 2>&1 | tee /tmp/gtwrap_install.log || {
  echo -e "${YELLOW}--break-system-packages failed, trying with --user...${NC}"
  pip3 install --user . 2>&1 | tee /tmp/gtwrap_install.log || {
    echo -e "${RED}ERROR: gtwrap installation failed${NC}"
    exit 1
  }
}

python3 -c "import gtwrap; print('gtwrap version:', gtwrap.__version__)" || {
  echo -e "${RED}ERROR: gtwrap import failed${NC}"
  exit 1
}

echo -e "${GREEN}✓ gtwrap installed and verified${NC}"

# Step 3: Clean previous build
echo -e "\n${GREEN}[Step 3/9] Cleaning previous build...${NC}"

if [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
fi

mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

# Step 4: Configure with CMake
echo -e "\n${GREEN}[Step 4/9] Configuring GTSAM with CMake...${NC}"

cmake -DCMAKE_BUILD_TYPE=Release \
  -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF \
  -DGTSAM_INSTALL_MATLAB_TOOLBOX=ON \
  -DMATLAB_ROOT=$MATLAB_ROOT \
  -DMEX_COMMAND=$MATLAB_ROOT/bin/mex \
  -DGTSAM_TOOLBOX_INSTALL_PATH=$MATLAB_TOOLBOX_PATH \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX
  ..

echo -e "${GREEN}CMake configuration complete!${NC}"
read -p "Press enter to continue with build..."

# Step 5: Build
echo -e "\n${GREEN}[Step 5/9] Building GTSAM...${NC}"
echo -e "${YELLOW}This may take 10-30 minutes depending on your system...${NC}"

NPROC=$(($(nproc) - 1))
[ $NPROC -lt 1 ] && NPROC=1

make -j$NPROC

echo -e "${GREEN}Build complete!${NC}"

# Step 6: Install system-wide
echo -e "\n${GREEN}[Step 6/9] Installing GTSAM system-wide...${NC}"

sudo make install

echo -e "${GREEN}System-wide installation complete!${NC}"

# Step 6.5: Configure ldconfig for system-wide library discovery (NEW!)
echo -e "\n${GREEN}[Step 6.5/9] Configuring system library paths with ldconfig...${NC}"

echo "Adding $INSTALL_PREFIX/lib to ldconfig..."
sudo bash -c "echo $INSTALL_PREFIX/lib >> /etc/ld.so.conf.d/gtsam.conf"
sudo ldconfig

# Verify
if ldconfig -p | grep -q libgtsam.so.4; then
  echo -e "${GREEN}✓ libgtsam registered in ldconfig${NC}"
else
  echo -e "${YELLOW}⚠ ldconfig may need restart to take effect${NC}"
fi

# Step 7: Fix MATLAB C++ library compatibility (CRITICAL!)
echo -e "\n${GREEN}[Step 7/9] Fixing MATLAB C++ library compatibility...${NC}"

MATLAB_SYS_LIB="$MATLAB_ROOT/sys/os/glnxa64/libstdc++.so.6"
MATLAB_BIN_LIB="$MATLAB_ROOT/bin/glnxa64/libstdc++.so.6"

if [ -f "$MATLAB_SYS_LIB" ]; then
  echo "Backing up MATLAB's old libstdc++.so.6..."
  sudo mv "$MATLAB_SYS_LIB" "${MATLAB_SYS_LIB}.old"
  sudo ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 "$MATLAB_SYS_LIB"
  echo -e "${GREEN}✓ MATLAB sys/os libstdc++ fixed${NC}"
fi

if [ -f "$MATLAB_BIN_LIB" ]; then
  echo "Backing up MATLAB's old libstdc++.so.6 (bin)..."
  sudo mv "$MATLAB_BIN_LIB" "${MATLAB_BIN_LIB}.old"
  sudo ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 "$MATLAB_BIN_LIB"
  echo -e "${GREEN}✓ MATLAB bin libstdc++ fixed${NC}"
fi

# Step 8: Configure LD_LIBRARY_PATH in ~/.bashrc (NEW!)
echo -e "\n${GREEN}[Step 8/9] Configuring LD_LIBRARY_PATH...${NC}"

if grep -q "GTSAM_LD_LIBRARY_PATH" ~/.bashrc; then
  echo "LD_LIBRARY_PATH already configured"
else
  echo "" >> ~/.bashrc
  echo "# GTSAM Library Path" >> ~/.bashrc
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$INSTALL_PREFIX/lib" >> ~/.bashrc
  echo "export GTSAM_LD_LIBRARY_PATH=configured" >> ~/.bashrc
  echo -e "${GREEN}✓ Added to ~/.bashrc${NC}"
fi

echo "To apply changes, run: source ~/.bashrc"

# Step 9: Verify installation
echo -e "\n${GREEN}[Step 9/9] Verifying installation...${NC}"

if [ -d "$INSTALL_PREFIX/include/gtsam" ]; then
  echo -e "${GREEN}✓ GTSAM headers found${NC}"
fi

if ls $INSTALL_PREFIX/lib/libgtsam* 1> /dev/null 2>&1; then
  echo -e "${GREEN}✓ GTSAM libraries found${NC}"
fi

if [ -d "$MATLAB_TOOLBOX_PATH/+gtsam" ]; then
  echo -e "${GREEN}✓ MATLAB toolbox installed${NC}"
fi

if [ -f "$MATLAB_TOOLBOX_PATH/gtsam_wrapper.mexa64" ]; then
  echo -e "${GREEN}✓ MATLAB MEX wrapper compiled${NC}"
fi

# Final summary
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}GTSAM Installation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"

echo -e "\n${YELLOW}Installation Summary:${NC}"
echo " - GTSAM version: 4.2a9"
echo " - GTSAM library: $INSTALL_PREFIX/lib"
echo " - GTSAM headers: $INSTALL_PREFIX/include"
echo " - MATLAB toolbox: $MATLAB_TOOLBOX_PATH"
echo " - MEX wrapper: $MATLAB_TOOLBOX_PATH/gtsam_wrapper.mexa64"

echo -e "\n${YELLOW}IMPORTANT - Next Steps:${NC}"
echo " 1. Apply bashrc changes:"
echo "    source ~/.bashrc"
echo ""
echo " 2. Restart MATLAB (to reload libraries and C++ runtime)"
echo "    matlab &"
echo ""
echo " 3. In MATLAB, test the installation:"
echo "    import gtsam.*"
echo "    graph = gtsam.NonlinearFactorGraph();"
echo "    disp('Success!')"

echo -e "\n${YELLOW}Troubleshooting:${NC}"
echo " - MEX error 'libgtsam.so.4: not found':"
echo "   Run: export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH"
echo ""
echo " - Path warning about +gtsam:"
echo "   This is normal. Just use: addpath('~/Documents/MATLAB')"
echo ""
echo " - Verify library paths:"
echo "   ldd ~/Documents/MATLAB/gtsam_wrapper.mexa64"
echo ""
echo " - Check ldconfig:"
echo "   ldconfig -p | grep libgtsam"

echo -e "\n${GREEN}✓ Installation script finished successfully!${NC}\n"

