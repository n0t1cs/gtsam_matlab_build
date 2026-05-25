# GTSAM Build Repository

Automated build scripts for [GTSAM](https://github.com/borglab/gtsam) on Linux. Three independent scripts cover the three common usage scenarios: C++ library only, library + MATLAB toolbox, and library + Python wrapper.

**Table of Contents**

- [Repository Contents](#repository-contents)
- [What Changed (v2.3)](#what-changed-v23)
- [Common Build Configuration](#common-build-configuration)
- [Script 1 — `gtsam_build.sh` (library only)](#script-1--gtsam_buildsh-library-only)
- [Script 2 — `gtsam_matlab_build.sh` (library + MATLAB toolbox)](#script-2--gtsam_matlab_buildsh-library--matlab-toolbox)
- [Script 3 — `gtsam_python_build` (library + Python wrapper)](#script-3--gtsam_python_build-library--python-wrapper)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [System Information](#system-information)

---

## Repository Contents

| File                    | Purpose                                                              |
| ----------------------- | -------------------------------------------------------------------- |
| `gtsam_build.sh`        | Minimal GTSAM C++ build & install (no MATLAB, no Python).            |
| `gtsam_matlab_build.sh` | Full GTSAM build with MATLAB toolbox + MATLAB libstdc++ compat fix.  |
| `gtsam_python_build`    | GTSAM build with Python wrapper (`gtsam` importable from `python3`). |
| `gtsam_test.m`          | MATLAB verification test (10 tests).                                 |
| `README.md`             | This guide.                                                          |

All scripts target **GTSAM `4.2a9`** and install to `/usr/local` by default.

---

## What Changed (v2.3)

The repo previously shipped a single combined script (`gtsam_build.sh`) that always built the MATLAB toolbox. It has been split into three scoped scripts so users without MATLAB (or who only need Python bindings) do not need to edit anything out.

- **NEW** — `gtsam_build.sh` now builds only the C++ library. Intended for headless/container use (e.g. distrobox). No MATLAB or Python dependencies pulled in.
- **NEW** — `gtsam_python_build` builds and installs the Python wrapper via `pip3` (`gtwrap` is installed automatically). Runs `make python-install`.
- **RENAMED** — the previous MATLAB-aware script is now `gtsam_matlab_build.sh`. Behavior is unchanged except step numbering was condensed from 11 steps to 9 steps.
- All three scripts now configure GTSAM with `GTSAM_THROW_CHEIRALITY_EXCEPTION=OFF` so that `SmartProjectionPoseFactor` does not throw on cheirality during projection. The library-only and Python scripts additionally verify that flag is absent in the installed `config.h`.
- `GTSAM_BUILD_WITH_MARCH_NATIVE=OFF` is set everywhere to keep the binaries portable between host machines (important when building inside a container and running on the host).
- All scripts register `/usr/local/lib` in `/etc/ld.so.conf.d/gtsam.conf` and run `ldconfig`, so manual `LD_LIBRARY_PATH` exports are no longer required system-wide (only the MATLAB script still exports it in `~/.bashrc` as a safety net for MATLAB sessions).
- The library-only and Python scripts use `git fetch --all --tags` + `git checkout 4.2a9` to pin the version. The Python script additionally runs `git submodule update --init --recursive`.

---

## Common Build Configuration

All three scripts share the same defaults at the top:

```bash
HOME_FOR_GTSAM="$HOME/GTSAM"      # parent dir for the clone
GTSAM_DIR="$HOME_FOR_GTSAM/gtsam" # the upstream repo
BUILD_DIR="$GTSAM_DIR/build"      # wiped + recreated each run
INSTALL_PREFIX="/usr/local"
GTSAM_TAG="4.2a9"
```

Common CMake flags:

| Flag                                  | Value     | Reason                                          |
| ------------------------------------- | --------- | ----------------------------------------------- |
| `CMAKE_BUILD_TYPE`                    | `Release` | Optimized build.                                |
| `GTSAM_BUILD_WITH_MARCH_NATIVE`       | `OFF`     | Portable binaries.                              |
| `GTSAM_THROW_CHEIRALITY_EXCEPTION`    | `OFF`     | Don't throw on cheirality in smart factors.     |
| `GTSAM_BUILD_UNSTABLE`                | `ON` (library/python only) | Include `gtsam_unstable`.          |
| `GTSAM_BUILD_TESTS`                   | `OFF`     | Skip GTSAM's own tests to save build time.      |
| `GTSAM_BUILD_EXAMPLES_ALWAYS`         | `ON` (library/python only) | Build the example binaries.        |

Parallel build uses `nproc - 1` jobs.

---

## Script 1 — `gtsam_build.sh` (library only)

Minimal install for headless environments (no MATLAB, no Python wrapper).

### Prerequisites

```bash
cmake build-essential libboost-all-dev libtbb-dev
```

The script installs anything missing via `apt-get`.

### Run

```bash
chmod +x gtsam_build.sh
./gtsam_build.sh
```

### What it does

1. Installs missing apt packages.
2. Clones `borglab/gtsam` to `~/GTSAM/gtsam` if not present, checks out tag `4.2a9`.
3. Wipes and recreates `$BUILD_DIR`.
4. Configures CMake with `GTSAM_BUILD_PYTHON=OFF`, `GTSAM_INSTALL_MATLAB_TOOLBOX=OFF`.
5. Builds with `make -j$(nproc-1)`.
6. Installs via `sudo make install`.
7. Writes `/etc/ld.so.conf.d/gtsam.conf` and runs `ldconfig`.
8. Verifies that `GTSAM_THROW_CHEIRALITY_EXCEPTION` is **not** defined in the installed `config.h` (fails if it is).
9. Confirms `libgtsam.so` is registered in `ldconfig`.

### When to use

- Building from inside a container (distrobox, Docker) for downstream ROS/catkin packages.
- CI machines without MATLAB.
- You only need the C++ headers and libraries.

---

## Script 2 — `gtsam_matlab_build.sh` (library + MATLAB toolbox)

Full installation including the MATLAB toolbox and the MATLAB `libstdc++` compatibility fix.

### Prerequisites

```bash
cmake build-essential libboost-all-dev libtbb-dev python3-dev
```

Plus a working MATLAB installation. By default the script expects:

```bash
MATLAB_ROOT="/usr/local/MATLAB/R2025b"
MATLAB_TOOLBOX_PATH="$HOME/Documents/MATLAB"
```

Find your MATLAB root with `which matlab` and edit the variable if different (e.g. `R2024b`, `R2025a`).

### Run

```bash
chmod +x gtsam_matlab_build.sh
./gtsam_matlab_build.sh
```

### What it does (9 steps)

1. **Step 1** — Check apt prerequisites and verify `MATLAB_ROOT` and `mex` exist.
2. **Step 2** — Clone GTSAM (if missing), fetch tags, checkout `4.2a9`.
3. **Step 2.5** — Install the `gtwrap` Python module from `gtsam/wrap` (`pip3 install --break-system-packages .`, falls back to `--user`). Logs to `/tmp/gtwrap_install.log`. Imports it to confirm.
4. **Step 3** — Wipe and recreate `$BUILD_DIR`.
5. **Step 4** — Configure CMake with `GTSAM_INSTALL_MATLAB_TOOLBOX=ON`, `MATLAB_ROOT`, `MEX_COMMAND`, `GTSAM_TOOLBOX_INSTALL_PATH`. **Pauses for confirmation** before building.
6. **Step 5** — Build with `make -j$(nproc-1)`. Takes 10–30 minutes.
7. **Step 6** — `sudo make install`.
8. **Step 6.5** — Append `/usr/local/lib` to `/etc/ld.so.conf.d/gtsam.conf`, run `ldconfig`, verify `libgtsam.so.4` is registered.
9. **Step 7** — Fix MATLAB's stale `libstdc++.so.6` by backing up `$MATLAB_ROOT/sys/os/glnxa64/libstdc++.so.6` and `$MATLAB_ROOT/bin/glnxa64/libstdc++.so.6` to `.old` and symlinking the system's `/usr/lib/x86_64-linux-gnu/libstdc++.so.6` in their place. This resolves `GLIBCXX_3.4.32 not found` errors when loading the MEX wrapper.
10. **Step 8** — Append a `LD_LIBRARY_PATH` export to `~/.bashrc` guarded by a `GTSAM_LD_LIBRARY_PATH` sentinel (idempotent).
11. **Step 9** — Verify GTSAM headers, libraries, MATLAB `+gtsam` toolbox dir, and `gtsam_wrapper.mexa64` all exist.

### After it finishes

```bash
source ~/.bashrc
matlab &
```

In MATLAB:

```matlab
addpath('~/Documents/MATLAB')
savepath
gtsam_test
```

You should see all 10 tests PASS (see [Verification](#verification)).

### When to use

- You need to call GTSAM from MATLAB scripts.
- You are running MATLAB on the same host as the build (the MATLAB libstdc++ fix is host-specific).

---

## Script 3 — `gtsam_python_build` (library + Python wrapper)

Installs the GTSAM C++ library and the Python bindings so `import gtsam` works from `python3`.

### Prerequisites

```bash
cmake build-essential libboost-all-dev libtbb-dev \
python3-dev python3-pip python3-numpy
```

Plus `pyparsing` (installed automatically by the script if missing).

### Run

```bash
chmod +x gtsam_python_build
./gtsam_python_build
```

### What it does

1. Installs missing apt packages.
2. Ensures `pyparsing` is importable (`pip3 install --break-system-packages pyparsing`, fallback to `--user`).
3. Clones GTSAM, checks out `4.2a9`, runs `git submodule update --init --recursive`.
4. Installs `gtwrap` from `gtsam/wrap` via `pip3`.
5. Wipes and recreates `$BUILD_DIR`.
6. Detects Python version via `sys.version_info` and passes it as `GTSAM_PYTHON_VERSION`.
7. Configures CMake with `GTSAM_BUILD_PYTHON=ON`, `GTSAM_INSTALL_MATLAB_TOOLBOX=OFF`.
8. Builds the C++ library with `make -j$(nproc-1)`.
9. `sudo make install` for the C++ library.
10. Builds and installs the Python wrapper: `make -j python-install`.
11. Registers `/usr/local/lib` in ldconfig.
12. Verifies the cheirality flag is off in `config.h`.
13. Imports `gtsam` from Python to confirm the wrapper is on `sys.path`.

### Verify

```bash
python3 -c "import gtsam; print(gtsam.__version__ if hasattr(gtsam,'__version__') else '4.2a9')"
```

### When to use

- Python-based SLAM/factor-graph development.
- You do not need MATLAB integration.

---

## Verification

### MATLAB (after `gtsam_matlab_build.sh`)

```matlab
addpath('~/Documents/MATLAB')
gtsam_test
```

Expected output:

```
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
```

### C++ library

```bash
ls /usr/local/lib/libgtsam*
ldconfig -p | grep libgtsam
ls /usr/local/include/gtsam/config.h
```

`config.h` must **not** contain a `#define GTSAM_THROW_CHEIRALITY_EXCEPTION` line.

### Python

```bash
python3 -c "import gtsam; g = gtsam.NonlinearFactorGraph(); print('ok')"
```

---

## Troubleshooting

### `ERROR: MATLAB not found at /usr/local/MATLAB/R2025b`

Edit `MATLAB_ROOT` at the top of `gtsam_matlab_build.sh` to match `dirname $(dirname $(which matlab))`.

### `gtwrap installation failed`

```bash
cat /tmp/gtwrap_install.log
pip3 install --user ~/GTSAM/gtsam/wrap
```

### MATLAB: `libgtsam.so.4: cannot open shared object file`

The `ldconfig` step in the script should prevent this. If you still hit it:

```bash
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
matlab &
```

### MATLAB: `version 'GLIBCXX_3.4.32' not found`

Step 7 of `gtsam_matlab_build.sh` should already have replaced MATLAB's bundled `libstdc++.so.6` with a symlink to the system one. To redo it manually for `R2025b`:

```bash
sudo mv /usr/local/MATLAB/R2025b/sys/os/glnxa64/libstdc++.so.6 \
        /usr/local/MATLAB/R2025b/sys/os/glnxa64/libstdc++.so.6.old
sudo ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
           /usr/local/MATLAB/R2025b/sys/os/glnxa64/libstdc++.so.6
```

### Cheirality exception verification failed

The library-only and Python scripts exit non-zero if `GTSAM_THROW_CHEIRALITY_EXCEPTION` is still defined in the installed `config.h`. This usually means an older GTSAM install is still in `/usr/local`. Clean and re-run:

```bash
sudo rm -rf /usr/local/include/gtsam /usr/local/lib/libgtsam* /usr/local/lib/cmake/GTSAM
./gtsam_build.sh
```

### Python: `import gtsam` succeeds but `gtsam.__version__` missing

GTSAM 4.2a9 does not always expose `__version__`. The script handles this and prints `4.2a9` as a fallback.

### Re-running a build

The scripts always wipe `$BUILD_DIR` on entry, so a re-run is safe:

```bash
./gtsam_build.sh           # or gtsam_matlab_build.sh / gtsam_python_build
```

If you also want to drop the installed artifacts:

```bash
sudo rm -rf /usr/local/include/gtsam /usr/local/lib/libgtsam* \
            /usr/local/lib/cmake/GTSAM /usr/local/lib/python*/dist-packages/gtsam*
```

---

## System Information

| Component | Version Tested        |
| --------- | --------------------- |
| GTSAM     | 4.2a9                 |
| MATLAB    | R2024b, R2025a, R2025b |
| Ubuntu    | 22.04, 24.04          |
| CMake     | 3.10+                 |
| GCC       | 9+                    |
| Python    | 3.10 / 3.12           |

---

## References

- GTSAM upstream: <https://github.com/borglab/gtsam>
- API docs: <https://borglab.org/gtsam/doxygen/>
- Tutorials: <http://gtsam.org/tutorials/intro.html>

---

**Version**: 2.3
**Last Updated**: 2026-05-25
