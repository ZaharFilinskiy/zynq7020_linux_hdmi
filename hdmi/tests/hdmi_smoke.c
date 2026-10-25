/* Standalone handoff target for BOOT_HDMI_TEST.bin. No Linux required.
 * FSBL has already filled the framebuffer and started continuous scanout.
 * Do not call ps7_init() again here: it would reset the running display.
 */
#include "xil_printf.h"
int main(void)
{
    xil_printf("HDMI smoke test: monitor should show 8 vertical color bars.\r\n");
    xil_printf("This test image contains no Linux. Restore the normal BOOT.BIN to boot Linux.\r\n");
    for (;;) __asm__ volatile ("wfi");
    return 0;
}
