#!/bin/sh
# Read-only diagnostics; run on the board over the existing serial console.
echo '=== Kernel ==='
uname -a
echo '=== Command line (expect console=tty0 as well as serial) ==='
cat /proc/cmdline
echo '=== Framebuffer ==='
cat /proc/fb
for n in /sys/class/graphics/fb*/name /sys/class/graphics/fb*/virtual_size /sys/class/graphics/fb*/bits_per_pixel; do
    [ ! -f "$n" ] || { echo "$n"; cat "$n"; }
done
echo '=== Display/reserved memory messages ==='
dmesg | grep -iE 'simple.?fb|framebuffer|fb0|reserved mem|Console:'
echo '=== Live device tree ==='
find /proc/device-tree/chosen -name '*framebuffer*' 2>/dev/null
