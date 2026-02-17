#!/bin/bash
# Kernel Build Script for OnePlus 9 Pro (SM8350)
# Optimized for LineageOS / Android 14+

# Stop on error
set -e

# --- Configuration ---
# Use current directory where script is
KERNEL_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DEFCONFIG="op9_defconfig"
OUT_DIR="${KERNEL_DIR}/out"

# --- Toolchain Check ---
# If CLANG is not in PATH, please set it here or add to your bashrc
# export PATH="$HOME/tc/bin:$PATH"

if ! command -v clang >/dev/null; then
    echo "Error: 'clang' (LLVM) not found in PATH."
    echo "Recommended: Install Android or Proton clang toolchain."
    echo "This script assumes you are running in Linux/WSL."
    exit 1
fi

echo "--- Cleaning Output Directory ---"
mkdir -p "$OUT_DIR"
# Uncomment if needed:
# make O="$OUT_DIR" mrproper

echo "--- Configuring Kernel: $DEFCONFIG ---"
# Repair include-prefix links when they are stored as plain files.
for p in "$KERNEL_DIR"/scripts/dtc/include-prefixes/*; do
    if [ -f "$p" ] && [ ! -L "$p" ]; then
        target="$(cat "$p")"
        rm -f "$p"
        ln -s "$target" "$p"
    fi
done

make O="$OUT_DIR" ARCH=arm64 "$DEFCONFIG"
make O="$OUT_DIR" ARCH=arm64 olddefconfig

echo "--- Starting Build (CPUs: $(nproc)) ---"
make O="$OUT_DIR" \
    ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    -j$(nproc) Image.gz-dtb

echo "--- Build Finished ---"
ls -lh "$OUT_DIR/arch/arm64/boot/Image.gz-dtb"
ls -lh "$OUT_DIR/arch/arm64/boot/dts/vendor/qcom/"*.dtb 2>/dev/null || true
