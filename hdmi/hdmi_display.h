#ifndef HDMI_DISPLAY_H
#define HDMI_DISPLAY_H
#include "xil_types.h"
/* Fixed contract shared with hdmi-simplefb.dtsi and the Block Design. */
#define HDMI_FB_BASE 0x18000000U
#define HDMI_WIDTH 1280U
#define HDMI_HEIGHT 720U
#define HDMI_STRIDE (HDMI_WIDTH * 4U)
#define HDMI_FB_BYTES (HDMI_STRIDE * HDMI_HEIGHT)
#define HDMI_VDMA_BASE 0x43000000U
int HdmiDisplayInit(void);
#endif
