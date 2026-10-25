#!/bin/bash
set -euo pipefail
work=/tmp/codex-zynq-hdmi-20261025
here=$(cd -- "$(dirname -- "$0")" && pwd)
export_dir="$here/build"
commit=51bca7333c6f97b115a5db08a16f52597601fe49
mkdir -p "$work" "$export_dir"
cd "$work"
if [ ! -s linux-xlnx.tar.gz ]; then
    curl -fL --retry 3 "https://codeload.github.com/Xilinx/linux-xlnx/tar.gz/$commit" -o linux-xlnx.tar.gz
fi
if [ ! -d "linux-xlnx-$commit" ]; then
    tar -xzf linux-xlnx.tar.gz
fi
cd "linux-xlnx-$commit"
cp "$here/kernel-original.config" .config
# Keep the board's working configuration and add a built-in firmware framebuffer.
# A distinct release suffix prevents accidentally loading old incompatible modules.
scripts/config --enable FB --enable FB_SIMPLE --enable FRAMEBUFFER_CONSOLE \
    --enable FRAMEBUFFER_CONSOLE_DETECT_PRIMARY --enable VT --enable VT_CONSOLE \
    --enable FONT_8x16 --enable LOGO --enable LOGO_LINUX_CLUT224 \
    --disable DRM_SIMPLEDRM --disable LOCALVERSION_AUTO --set-str LOCALVERSION '-xilinx-hdmi'
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- olddefconfig
cp .config "$export_dir/kernel.config"
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules
mkimage -A arm -O linux -T kernel -C none -a 0x8000 -e 0x8000 \
    -n 'Linux Zynq HDMI 720p' -d arch/arm/boot/zImage "$export_dir/image-hdmi.ub"
cp arch/arm/boot/zImage "$export_dir/zImage"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH="$work/modules" modules_install
tar -C "$work/modules" --exclude="lib/modules/*/build" --exclude="lib/modules/*/source" -czf "$export_dir/modules-hdmi.tar.gz" lib/modules
printf 'Xilinx linux-xlnx commit %s\n' "$commit" > "$export_dir/SOURCE.txt"
sha256sum "$work/linux-xlnx.tar.gz" >> "$export_dir/SOURCE.txt"
sha256sum "$export_dir"/image-hdmi.ub "$export_dir"/modules-hdmi.tar.gz > "$export_dir/SHA256SUMS.txt"
echo 'KERNEL BUILD COMPLETE'
