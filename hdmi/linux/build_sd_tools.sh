#!/bin/bash
set -euo pipefail
out=$(cd -- "$(dirname -- "$0")" && pwd)
arm-linux-gnueabihf-gcc -O2 -static -s "$out/fb_test.c" -o "$out/build/fb_test"
mkimage -A arm -O linux -T script -C none -n 'Zynq Linux HDMI 720p' \
    -d "$out/boot-hdmi.cmd" "$out/build/boot-hdmi.scr"
