# HDMI bitstream and continuous VDMA scanout have already been started by FSBL.
if fatload mmc 0:1 0x03000000 image-hdmi.ub; then
    if fatload mmc 0:1 0x02a00000 zynq-hdmi.dtb; then
        setenv bootargs console=tty0 console=ttyPS0,115200 root=/dev/mmcblk0p2 rw rootwait fbcon=map:0
        bootm 0x03000000 - 0x02a00000
    fi
fi
echo HDMI boot files could not be loaded. Restore backup_before_hdmi_20261025 to roll back.
