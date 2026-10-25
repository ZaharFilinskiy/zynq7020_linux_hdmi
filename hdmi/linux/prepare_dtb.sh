#!/bin/bash
set -euo pipefail
out=$(cd -- "$(dirname -- "$0")" && pwd)
dtc -I dtb -O dts -o "$out/board-original.dts" "$out/board-original.dtb"
# Keep all PS nodes from the actual SD image, including RTL8211E and SD wiring.
cp "$out/board-original.dts" "$out/board-hdmi.dts"
cat >> "$out/board-hdmi.dts" <<'EOF'

/* Firmware-owned VDMA scanout. Linux owns only the reserved pixel memory. */
/ {
    reserved-memory {
        #address-cells = <1>;
        #size-cells = <1>;
        ranges;
        framebuffer@18000000 {
            reg = <0x18000000 0x00400000>;
            no-map;
        };
    };
    chosen {
        #address-cells = <1>;
        #size-cells = <1>;
        ranges;
        bootargs = "console=tty0 console=ttyPS0,115200 root=/dev/mmcblk0p2 rw rootwait fbcon=map:0";
        framebuffer@18000000 {
            compatible = "simple-framebuffer";
            reg = <0x18000000 0x00384000>;
            width = <1280>;
            height = <720>;
            stride = <5120>;
            format = "x8r8g8b8";
            /* Phandle 1 is the verified PS clkc in board-original.dts. */
            clocks = <&{/amba/slcr@f8000000/clkc@100} 15>;
            status = "okay";
        };
    };
};
EOF
dtc -I dts -O dtb -o "$out/zynq-hdmi.dtb" "$out/board-hdmi.dts"
fdtget -t x "$out/zynq-hdmi.dtb" /reserved-memory/framebuffer@18000000 reg
for prop in width height stride; do
    fdtget -t u "$out/zynq-hdmi.dtb" /chosen/framebuffer@18000000 "$prop"
done
