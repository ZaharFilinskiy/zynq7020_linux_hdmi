/* Run on Linux: ./fb_test /dev/fb0. This overwrites the displayed framebuffer
 * with color bars; it never accesses /dev/mem or programs VDMA registers.
 * Build with the compiler produced by the same Buildroot configuration.
 */
#include <errno.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>
int main(int argc, char **argv)
{
    const char *path=argc>1 ? argv[1] : "/dev/fb0";
    const uint32_t bars[]={0xffffff,0xffff00,0x00ffff,0x00ff00,
                           0xff00ff,0xff0000,0x0000ff,0x000000};
    struct fb_var_screeninfo v;
    struct fb_fix_screeninfo f;
    unsigned x,y;
    unsigned char *mem;
    int fd=open(path,O_RDWR);
    if (fd<0) {perror(path); return 1;}
    if (ioctl(fd,FBIOGET_VSCREENINFO,&v)<0 || ioctl(fd,FBIOGET_FSCREENINFO,&f)<0) {
        perror("framebuffer info"); close(fd); return 1;
    }
    if (v.xres!=1280 || v.yres!=720 || v.bits_per_pixel!=32 ||
        v.xoffset || v.yoffset || v.red.offset!=16 || v.green.offset!=8 ||
        v.blue.offset!=0 || v.red.length!=8 || v.green.length!=8 || v.blue.length!=8 ||
        f.line_length<1280*4 || (uint64_t)f.line_length*720>f.smem_len) {
        fprintf(stderr,"Expected 1280x720 XRGB8888 framebuffer with valid stride\n");
        close(fd); return 1;
    }
    mem=mmap(NULL,f.smem_len,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
    if (mem==MAP_FAILED) {perror("mmap"); close(fd); return 1;}
    for (y=0;y<720;++y) {
        uint32_t *row=(uint32_t *)(mem+(size_t)y*f.line_length);
        for (x=0;x<1280;++x) {
            uint32_t pixel=bars[x/160];
            /* Same image as the PL generator and FSBL DDR initialization. */
            if (y>=656) pixel=((x/32)^(y/32))&1 ? 0xffffff : 0x202020;
            if (x<2 || x>=1278 || y<2 || y>=718) pixel=0xffffff;
            row[x]=pixel;
        }
    }
    munmap(mem,f.smem_len); close(fd);
    puts("Color bars written: white yellow cyan green magenta red blue black");
    return 0;
}
