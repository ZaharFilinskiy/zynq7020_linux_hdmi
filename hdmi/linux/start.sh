#!/bin/sh
# The original root filesystem is only 51 MiB and full. Keep matching modules
# on the spacious boot partition instead of expanding or replacing rootfs.
# /mnt is mounted by the HDMI entry in /etc/inittab before rcS executes.
[ "$(uname -r)" = '6.12.70-xilinx-hdmi' ] || exit 0
if [ -d /mnt/linux-hdmi/modules/lib/modules/6.12.70-xilinx-hdmi ]; then
    mount -o bind /mnt/linux-hdmi/modules/lib/modules /lib/modules ||
        echo 'HDMI: could not bind matching kernel modules' >&2
fi
