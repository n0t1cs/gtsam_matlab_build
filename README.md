# GTSAM MATLAB Installation Repository

Complete guide to install GTSAM with MATLAB support. Includes automated setup script and verification test.

**Table of Contents:**
- [What You Get](#what-you-get)
- [Requirements](#requirements)
- [Step-by-Step Installation](#step-by-step-installation)
- [Using the MATLAB Test](#using-the-matlab-test)
- [Troubleshooting](#troubleshooting)

---

## What You Get

This repository automates the complete GTSAM installation:

| File | Purpose |
|------|---------|
| `gtsam_build.sh` | 11-step automated installation script |
| `gtsam_test.m` | MATLAB verification test (10 tests) |
| `README.md` | This guide |

---

## Requirements

### Check Your System
```bash
# Check Ubuntu version
lsb_release -a

# Check MATLAB is installed
which matlab
# Should show: /usr/local/MATLAB/R20XX*/bin/matlab

# Check available disk space
df -h
# Should have at least 5 GB free in /home

# Check RAM
free -h
# Should show at least 8 GB
```

---

## Step-by-Step Installation

### Step 1: Clone This Repository

```bash

# Clone the repository
git clone https://github.com/n0t1cs/gtsam_matlab_build.git
cd gtsam-matlab-installation

# List files to verify
ls -la
# You should see: gtsam_build.sh, gtsam_test.m, README.md
```

### Step 2: Open and Configure the Installation Script

The script needs to know:
- Where MATLAB is installed
- Where to install GTSAM
- Where to put the MATLAB toolbox

#### Option A: Using a Text Editor (Recommended for First Time)

```bash
# Open the script with nano editor
nano gtsam_build.sh

# Or use gedit (GUI)
gedit gtsam_build.sh

# Or use VS Code
code gtsam_build.sh
```

#### Option B: Quick Command Line

```bash
# View the configuration section
head -50 gtsam_build.sh | tail -30
```

### Step 3: Edit Configuration Variables

In the script, find this section (around line 20-30):

```bash
# Example of Configuration
HOME_FOR_GTSAM="$HOME/GTSAM"
GTSAM_DIR="$HOME_FOR_GTSAM/gtsam"
BUILD_DIR="$GTSAM_DIR/build"
MATLAB_ROOT="/usr/local/MATLAB/R2025b"
MATLAB_TOOLBOX_PATH="$HOME/Documents/MATLAB"
INSTALL_PREFIX="/usr/local"
```

**Edit these variables for your system:**

#### Find Your MATLAB Installation Path

```bash
# Find where MATLAB is installed
which matlab

# Typical paths:
# R2025b: /usr/local/MATLAB/R2025b/bin/matlab
# R2025a: /usr/local/MATLAB/R2025a/bin/matlab
# R2024b: /usr/local/MATLAB/R2024b/bin/matlab
# R2024a: /usr/local/MATLAB/R2024a/bin/matlab
```

**Update MATLAB_ROOT** to match your installation:

```bash
# If output is: /usr/local/MATLAB/R2025b/bin/matlab
# Then set: MATLAB_ROOT="/usr/local/MATLAB/R2025b"

# If output is: /usr/local/MATLAB/R2025a/bin/matlab
# Then set: MATLAB_ROOT="/usr/local/MATLAB/R2025a"
```

#### Customize Installation Paths (Optional)

The default settings are:
```bash
# Source directory (where GTSAM will be downloaded)
HOME_FOR_GTSAM="$HOME/GTSAM"

# Installation directory (where GTSAM libraries go)
INSTALL_PREFIX="/usr/local"

# MATLAB toolbox directory
MATLAB_TOOLBOX_PATH="$HOME/Documents/MATLAB"
```

To change them:
```bash
# Example: If you want to install in /opt instead of /usr/local
INSTALL_PREFIX="/opt/gtsam"

# Example: If your Documents folder is elsewhere
MATLAB_TOOLBOX_PATH="/data/MATLAB"
```

### Step 4: Save Configuration Changes

If using **nano editor**:
- Press `Ctrl + O` (save)
- Press `Enter` (confirm filename)
- Press `Ctrl + X` (exit)

If using **gedit or VS Code**:
- Press `Ctrl + S` to save

### Step 5: Make Script Executable

```bash
chmod +x gtsam_build.sh
```

### Step 6: Run the Installation Script

```bash
# Start the installation
./gtsam_build.sh

# The script will show progress like:
# ╔════════════════════════════════════════╗
# ║ GTSAM Installation (Step 1/11)        ║
# ║ Checking prerequisites...             ║
# ╚════════════════════════════════════════╝
```

**What the script does (11 steps):**

1. ✅ Checks system dependencies
2. ✅ Verifies MATLAB installation
3. ✅ Cleans previous build
4. ✅ Configures with CMake
5. ✅ Builds GTSAM (takes 10-20 min)
6. ✅ Optional testing
7. ✅ Installs system-wide (may ask for password)
8. ✅ Fixes C++ library issues
9. ✅ Configures library paths
10. ✅ Verifies installation
11. ✅ Creates startup scripts

**⏱️ Total time: 20-40 minutes** (mainly waiting for compilation)

### Step 7: Apply Configuration to Your System

After the script completes:

```bash
# Update your shell with new library paths
source ~/.bashrc

# Verify library paths are set
echo $LD_LIBRARY_PATH
# Should contain: /usr/local/lib
```

### Step 8: Verify Installation Success

```bash
# Check GTSAM libraries were installed
ls -la /usr/local/lib/libgtsam*

# Check MATLAB MEX file
ls -la ~/Documents/MATLAB/gtsam_wrapper.mexa64

# Check system knows about the library
ldconfig -p | grep libgtsam
```

---

## Using the MATLAB Test

### Step 1: Start MATLAB

```bash
matlab &
```

Wait for MATLAB to fully open (usually 10-20 seconds).

### Step 2: Add GTSAM to MATLAB Path

In the MATLAB Command Window, type:

```matlab
addpath('~/Documents/MATLAB')
savepath
```

**What this does:**
- Adds GTSAM to MATLAB's search path
- `savepath` makes it permanent (survives MATLAB restart)

### Step 3: Run the Test Script

In the MATLAB Command Window, type:

```matlab
gtsam_test
```

### Step 4: Verify All Tests Pass

If successful, you should see:

```
╔════════════════════════════════════════════════════════════════╗
║      GTSAM MATLAB Toolbox - Basic Installation Test           ║
╚════════════════════════════════════════════════════════════════╝

[Test 1] Importing gtsam namespace... ✓ PASSED
[Test 2] Creating basic GTSAM objects... ✓ PASSED
[Test 3] Creating NonlinearFactorGraph... ✓ PASSED
[Test 4] Creating Values object... ✓ PASSED
[Test 5] Creating 3D Point... ✓ PASSED
[Test 6] Creating Rotation (Rot3)... ✓ PASSED
[Test 7] Creating PriorFactor... ✓ PASSED
[Test 8] Adding factor to graph... ✓ PASSED
[Test 9] Inserting initial estimate... ✓ PASSED
[Test 10] Creating LevenbergMarquardtOptimizer... ✓ PASSED

╔════════════════════════════════════════════════════════════════╗
║                    ALL TESTS PASSED! ✓                         ║
║                                                                ║
║      GTSAM MATLAB Toolbox is correctly installed and           ║
║      ready for use!                                            ║
╚════════════════════════════════════════════════════════════════╝
```

### Step 5: Start Using GTSAM in MATLAB

Now you can use GTSAM! Example:

```matlab
% Import GTSAM
import gtsam.*

% Create a factor graph
graph = NonlinearFactorGraph();

% Create optimization variables
values = Values();

% Create a 3D pose
pose = Pose3();

% Add initial values
values.insert(0, pose);

% Create noise model
noiseModel = noiseModel.Isotropic.Sigma(6, 0.1);

% Add prior constraint
prior = PriorFactorPose3(0, pose, noiseModel);
graph.add(prior);

% Optimize
params = LevenbergMarquardtParams();
optimizer = LevenbergMarquardtOptimizer(graph, values, params);
result = optimizer.optimize();

disp('GTSAM is working!')
```

---

## Configuration Quick Reference

### Common Configuration Changes

**If MATLAB is in a different location:**
```bash
# Find MATLAB location
which matlab

# Update the script
nano gtsam_build.sh
# Change: MATLAB_ROOT="/usr/local/MATLAB/R2025b"
# To your MATLAB path
```

**If you want to install in a different directory:**
```bash
nano gtsam_build.sh
# Change: INSTALL_PREFIX="/usr/local"
# To: INSTALL_PREFIX="/opt/gtsam" or any other path
# Note: Might need sudo to install in system directories
```

**If your MATLAB Documents folder is different:**
```bash
nano gtsam_build.sh
# Change: MATLAB_TOOLBOX_PATH="$HOME/Documents/MATLAB"
# To your actual Documents location
```

---

## Troubleshooting

### Problem 1: Script says "MATLAB not found"

**Error:** `ERROR: MATLAB not found at /usr/local/MATLAB/R2025b`

**Solution:**
1. Find your MATLAB: `which matlab`
2. Edit the script: `nano gtsam_build.sh`
3. Update `MATLAB_ROOT` to correct path
4. Run script again: `./gtsam_build.sh`

### Problem 2: "gtwrap installation failed"

**Error:** `ERROR: gtwrap installation failed`

**Solution:**
```bash
# Check the error log
cat /tmp/gtwrap_install.log

# Try manual installation
pip3 install --user ~/GTSAM/gtsam/wrap
```

### Problem 3: MATLAB gtsam_test shows "cannot find libgtsam.so.4"

**Error:** `libgtsam.so.4: cannot open shared object file`

**Solution:**
```bash
# Set library path before starting MATLAB
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Or permanently add to ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
source ~/.bashrc

# Then restart MATLAB
matlab &
```

### Problem 4: MATLAB C++ error about libstdc++

**Error:** `version 'GLIBCXX_3.4.32' not found`

**Solution:** The installation script should have fixed this automatically, but if not:

```bash
# Manually fix MATLAB's C++ library
sudo mv /usr/local/MATLAB/R2025b/sys/os/glnxa64/libstdc++.so.6 \
        /usr/local/MATLAB/R2025b/sys/os/glnxa64/libstdc++.so.6.old

sudo ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
           /usr/local/MATLAB/R2025b/sys/os/glnxa64/libstdc++.so.6

# Restart MATLAB
matlab &
```

### Problem 5: gtsam_test shows some tests FAILED

**Solution:** One of the GTSAM components didn't load properly.

```bash
# Check library dependencies
ldd ~/Documents/MATLAB/gtsam_wrapper.mexa64 | grep "not found"

# If you see "not found" items, fix library paths:
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Restart MATLAB and try again
```

### Problem 6: Script asks for password (sudo)

**This is normal!** The script needs sudo to:
- Install libraries system-wide
- Modify MATLAB's C++ library
- Update system library cache

Just enter your password when prompted.

---

## Quick Command Reference

### Viewing Logs and Checking Installation

```bash
# View gtwrap installation log
cat /tmp/gtwrap_install.log

# Check if GTSAM libraries installed
ls -la /usr/local/lib/libgtsam*

# Check if MATLAB MEX file exists
ls -la ~/Documents/MATLAB/gtsam_wrapper.mexa64

# Check library dependencies
ldd ~/Documents/MATLAB/gtsam_wrapper.mexa64

# Check system library registry
ldconfig -p | grep libgtsam
```

### Re-running Installation

```bash
# Clean and start over
cd ~/GTSAM/gtsam
rm -rf build

# Run script again
cd FULL-PATH/gtsam-matlab-installation
./gtsam_build.sh
```

---

## Next Steps

After successful installation:

1. ✅ Understand GTSAM basics: http://gtsam.org/tutorials/intro.html
2. ✅ Read API documentation: https://borglab.org/gtsam/doxygen/
3. ✅ Build your own SLAM application
4. ✅ Explore example projects

---

## File Summary

| File | Lines | Purpose |
|------|-------|---------|
| `gtsam_build.sh` | 200+ | Automated 11-step installation |
| `gtsam_test.m` | 100+ | 10-test verification suite |
| `README.md` | This file | Complete setup guide |

---

## System Information

| Component | Version Tested |
|-----------|--------|
| GTSAM | 4.2a9 |
| MATLAB | R2025b |
| Ubuntu | 24.04 |
| CMake | 3.10+ |
| GCC | 9+ |

---

## Important Notes

⚠️ **Key Things to Remember:**

1. **MATLAB_ROOT** - Must match your MATLAB installation path
2. **INSTALL_PREFIX** - Default `/usr/local` works for most users
3. **MATLAB_TOOLBOX_PATH** - Default `~/Documents/MATLAB` is recommended
4. **Library paths** - Script configures these automatically
5. **Sudo password** - Script will ask for it during installation

---

## Getting Help

### Before Installing
- Check you meet all [Requirements](#requirements)
- Read through [Step-by-Step Installation](#step-by-step-installation)
- Verify system info with commands in "Check Your System"

### During Installation
- Watch the script output for errors
- Check `/tmp/gtwrap_install.log` for detailed error logs
- See [Troubleshooting](#troubleshooting) section

### After Installation
- Run `gtsam_test` in MATLAB to verify
- Check that all 10 tests PASS
- See [Using the MATLAB Test](#using-the-matlab-test)

### Still Having Issues?
- Visit: https://github.com/borglab/gtsam/issues
- Read: http://gtsam.org/tutorials/intro.html
- Check: https://borglab.org/gtsam/

---

## License

GTSAM is licensed under the **BSD 3-Clause License**.  
This repository provides installation support for GTSAM.

---

**Version**: 2.2  
**Last Updated**: October 29, 2025  

