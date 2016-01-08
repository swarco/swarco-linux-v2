/*
 * usermode/atmel_serial.c
 *
 * Copyright (C) 2016 by SWARCO Traffic Systems GmbH.
 * All rights reserved.
 *
 * @author:     Guido Classen <guido.classen@swarco.de>
 * @descr:      Userspace tool to config Atmal USART specific serial modes
 *
 * This program can switch serial mode an all Atmal AT91xxx CPUs
 * with atmel_serial USART without special kernel support.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version
 * 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 *
 *  @par Modification History:
 *     2016-01-08 gc: initial version (based on ccm2200_serial.c)
 */

#include <stdio.h>
#include <stdlib.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

/* linux kernel includes */
#include <sys/ioctl.h>
#include <linux/serial.h>


#define PAGESIZE 4096
typedef unsigned char u8;
typedef unsigned u32;

void usage(void)
{
  printf("usage: atmel_serial device info\n"
         "       atmel_serial device mode <NORMAL|RS232|RS485HW|RS485>\n");
}

static void *map_phys_addr(void *addr, int fd, unsigned length) 
{
  u8 *page_start = (u8*) ((unsigned long) addr & ~(PAGESIZE-1) );
  u32 offset = (u8*) addr - page_start;
  u32 map_len = (length + offset + PAGESIZE) & ~(PAGESIZE-1);
  u8 *map_start;

  map_start = (u8*)mmap(NULL, 
                          map_len, 
                          PROT_READ | PROT_WRITE, MAP_SHARED, 
                          fd,
                          (unsigned long) page_start);
  if (map_start == (void *) -1) {
    fprintf(stderr, "error mapping address 0x%08lx, page 0x%08lx, offset 0x%08lx, length 0x%08lx\n", 
            (unsigned long) addr, (unsigned long) page_start, 
            (unsigned long) offset, (unsigned long) map_len);
    exit(1);
  }

  return map_start + offset;
}


#define AT91_SAM9260_USART0     0xFFFB0000
#define PORT_ATMEL	49

int main(int argc, char *argv[])
{
  volatile u32 *usart0_base;
  #define USART_MODE 0x0000000f
  int i;
  int dev_mem_fd;
  struct serial_struct serinfo;
  int fd;
  int mode = -1;            /* 0==rs232 / 1=rs485 */

  if (argc < 3) {
    usage();
    return 1;
  }

  if ((fd = open(argv[1], O_RDWR|O_NONBLOCK)) < 0) {
    perror(argv[1]);
    return 1;
  }
  serinfo.reserved_char[0] = 0;
  if (ioctl(fd, TIOCGSERIAL, &serinfo) < 0) {
    perror("Cannot get serial info");
    close(fd);
    return 1;
  }

  if (serinfo.type != PORT_ATMEL) {
    fprintf(stderr, "can only work on ports with Atmel USART\n");
    return 1;
  }

  if (!strcmp(argv[2], "info")) {
  } else if (!strcmp(argv[2], "mode")) {
    if (argc < 4) {
      fprintf(stderr, "must specify mode\n");
      return 1;
    } else {
      if (!strcmp(argv[3], "RS232") || !strcmp(argv[3], "NORMAL")) {
        mode = 0;
      } else if (!strcmp(argv[3], "RS485") || !strcmp(argv[3], "RS485HW")) {
        mode = 1;
      }  else {
        fprintf(stderr, "unknown mode specified\n");
        usage();
        return 1;
      }
    }
  } else {
    fprintf(stderr, "unkown option\n");
    usage();
    return 1;
  }

  if ((dev_mem_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
    printf("could not open /dev/mem, perhaps I should run as root?\n");
    return;
  }

  usart0_base = (volatile u32 *)map_phys_addr((void*)serinfo.iomem_base,
                                           dev_mem_fd,
                                           0x4000);

  volatile u32 *us_mr = (volatile u32*)(((volatile u8*)usart0_base)+4);

  if (mode == -1) {
    const char *mode_str;
    switch (*us_mr & USART_MODE) {
    case 0: mode_str = "RS232 (Normal)"; break;
    case 1: mode_str = "RS485 (UART hardware)"; break;
    case 2: mode_str = "Hardware Handshaking"; break;
    case 3: mode_str = "Modem"; break;
    case 4: mode_str = "IS07816 Protocol: T = 0"; break;
    case 6: mode_str = "IS07816 Protocol: T = 1"; break;
    case 8: mode_str = "IrDA"; break;
    default: mode_str = "Unkown"; break;
    }
    printf("Mode: %s\nmembase %08x\n", 
           mode_str,
           serinfo.iomem_base);
  } else {
    *us_mr = (*us_mr & ~USART_MODE) | mode;
  }
  close(dev_mem_fd);

  return 0;
}




/*
 *Local Variables:
 * mode: c
 * compile-command: "arm-linux-gnueabi-gcc -o atmel_serial atmel_serial.c"
 * c-style: linux
 * End:
 */
