/* Firmware scanout initialization for SDK 2018.3 / Zynq FSBL.
 * Called BEFORE handoff, after the bitstream and PS post-configuration.
 * VDMA keeps scanning while U-Boot/Linux run; Linux simplefb writes pixels
 * to the reserved DDR region and does not reprogram this DMA channel.
 */
#include "hdmi_display.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xstatus.h"

/* AXI VDMA v6.3 direct-register MM2S offsets (PG020). */
#define CR 0x00U
#define SR 0x04U
#define PARK 0x28U
#define VSIZE 0x50U
#define HSIZE 0x54U
#define STRIDE 0x58U
#define START 0x5CU
#define RESET 0x04U
#define RUN 0x01U
#define ERRORS 0x00000FF0U
#define REG(off) (HDMI_VDMA_BASE + (off))

int HdmiDisplayInit(void)
{
    volatile u32 *fb = (volatile u32 *)HDMI_FB_BASE;
    static const u32 bars[8] = {0x00FFFFFFU,0x00FFFF00U,0x0000FFFFU,
        0x0000FF00U,0x00FF00FFU,0x00FF0000U,0x000000FFU,0x00000000U};
    u32 x, y, count, status;
    /* Give MMCM and pixel-domain reset synchronizers time to settle. */
    usleep(10000);
    Xil_Out32(REG(CR), RESET);
    for (count=0; count<10000U; ++count) {
        if (!(Xil_In32(REG(CR)) & RESET)) break;
        usleep(10);
    }
    if (count==10000U) {
        xil_printf("HDMI: VDMA reset timeout\r\n");
        return XST_FAILURE;
    }
    /* Distinct startup bars prove DDR scanout before Linux takes over.
     * HP0 is not coherent with the CPU data cache: flush before starting. */
    for (y=0; y<HDMI_HEIGHT; ++y)
        for (x=0; x<HDMI_WIDTH; ++x)
            {
            u32 pixel = bars[x/(HDMI_WIDTH/8U)];
            /* Same diagnostic picture as the archived autonomous PL build.
             * Now every pixel is stored by the ARM CPU in DDR and read by VDMA. */
            if (y >= HDMI_HEIGHT-64U)
                pixel = ((x/32U) ^ (y/32U)) & 1U ? 0x00FFFFFFU : 0x00202020U;
            if (x < 2U || x >= HDMI_WIDTH-2U || y < 2U || y >= HDMI_HEIGHT-2U)
                pixel = 0x00FFFFFFU;
            fb[y*HDMI_WIDTH+x] = pixel;
        }
    Xil_DCacheFlushRange(HDMI_FB_BASE, HDMI_FB_BYTES);
    /* One frame store in park mode, no interrupts, no external genlock.
     * VSIZE is written LAST: this commits the geometry and starts reads. */
    Xil_Out32(REG(SR), 0x00007FF0U);
    Xil_Out32(REG(PARK), 0U);
    Xil_Out32(REG(CR), RUN);
    Xil_Out32(REG(START), HDMI_FB_BASE);
    Xil_Out32(REG(STRIDE), HDMI_STRIDE);
    Xil_Out32(REG(HSIZE), HDMI_STRIDE);
    Xil_Out32(REG(VSIZE), HDMI_HEIGHT);
    usleep(40000);
    status=Xil_In32(REG(SR));
    if (status & (ERRORS | 1U)) {
        xil_printf("HDMI: VDMA failed, status=0x%08x\r\n", status);
        Xil_Out32(REG(CR), 0U);
        return XST_FAILURE;
    }
    xil_printf("HDMI: 1280x720 ~59.93 Hz, XRGB8888, framebuffer=0x%08x\r\n", HDMI_FB_BASE);
    return XST_SUCCESS;
}
