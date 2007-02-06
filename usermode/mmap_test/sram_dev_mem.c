/* Access SRAM using /dev/mem */

#include <stdio.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>


#define CCM2200_SRAM_PHYS               0x30000000
#define CCM2200_SRAM_SIZE               (2*1024*1024)

int main(int argc, char *argv[])
{
  int write_mode = 0;
  int dev_mem_fd;
  void *base;

  if (argc != 3) {
    printf("usage: sram_dev_mem read|write filename\n");
    return 1;
  }
  
  if (!strcmp(argv[1], "write")) {
    write_mode = 1;
  } else if (strcmp(argv[1], "read")) {
    printf("unkown command\n");
    return 1;
  }

  if ((dev_mem_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
    printf("could not open /dev/mem, perhaps I should run as root?\n");
    return -1;
  }

  base = mmap(0, CCM2200_SRAM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, 
              dev_mem_fd,
              CCM2200_SRAM_PHYS);
  if (base != (void *) -1) {
    FILE *f = fopen(argv[2], write_mode ? "r" : "w");
    if (f) {
      if (write_mode) {
        if (fread(base, 1, CCM2200_SRAM_SIZE, f) == CCM2200_SRAM_SIZE) {
          printf("%d bytes written to SRAM\n", CCM2200_SRAM_SIZE);
        } else {
          printf("reading file failed\n");
        }
      } else {
        if (fwrite(base, 1, CCM2200_SRAM_SIZE, f) == CCM2200_SRAM_SIZE) {
          printf("%d bytes read from SRAM\n", CCM2200_SRAM_SIZE);
        } else {
          printf("writing file failed\n");
        }
      }
      fclose(f);
    } else {
      printf("could not open file %s\n", argv[2]);
    }
  } else {
    printf("could not memory map /dev/mem\n");
  }
  close(dev_mem_fd);
  return 0;
}



/*
 *Local Variables:
 * mode: c
 * compile-command: "/mnt/weiss/ccm2200/buildroot/build_arm/staging_dir/bin/arm-linux-uclibc-gcc -o sram_dev_mem sram_dev_mem.c"
 * c-style: linux
 * End:
 */
