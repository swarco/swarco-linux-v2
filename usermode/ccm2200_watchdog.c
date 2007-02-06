/*
 * usermode/ccm2200_watchdog.c
 *
 * Copyright (C) 2007 by Weiss-Electronic GmbH.
 * All rights reserved.
 *
 * @author:     Guido Classen <guido.classen@weiss-electronic.de>
 * @descr:      Userspace tool to access CCM2200 watchdogs.
 *              This programm uses only Standard Linux features. So it can
 *              be applied to any watchdog device (Except setting LED-Mask)
 *              The CCM2200 board has two watchdog devices:
 *                /dev/ccm2200_watchdog:
 *                  external MAX6751 watchdog on CCM2200 board.
 *                  This device is active all time (it can only be disabled
 *                  by DIP-Switch 4) and has a timeout of 64 seconds.
 *                  This reduce the timeout perio to 0.5
 *                  second by setting a timeout of 1 sec.
 *                /dev/watchdog:
 *                  AT91RM9200 internal watchdog. This device can be used 
 *                  together with /dev/ccm2200_watchdog to get other timeout
 *                  periods. It's period time can be set also with this 
 *                  programm! 
 *
 * See file CREDITS for list of people who contributed to this
 * project.
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
 *     2007-02-05 gc: initial version
 */

#include <stdio.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

/* linux includes */
#include <linux/types.h>
#include <linux/ioctl.h>
#include <linux/watchdog.h>

/* this needs a include path to actual CCM2200 Linux kernel! */
#include <linux/ccm2200_gpio.h>


void usage(void)
{
  printf("usage: ccm2200_watchdog device info|timeout|trigger|led "
         "[timeout/led-mask]\n");

}

void info(int fd)
{
  struct watchdog_info info;
  int timeout = 0;
  memset(&info, 0, sizeof(info));
  if (ioctl(fd, WDIOC_GETSUPPORT, &info) == 0) {
    ioctl(fd, WDIOC_GETTIMEOUT, &timeout);
    printf("Watchdog driver: %s, Version %d, Options 0x%08x, Timeout: %d\n",
           info.identity, info.firmware_version, info.options, timeout);
  } else {
    printf("error in ioctl(), perhaps wrong device?\n");
  }

}

int main(int argc, char *argv[])
{
  int device_fd;
  int result = 0;
  if (argc < 3) {
    usage();
    return 1;
  }

  if ((device_fd = open(argv[1], O_WRONLY)) == -1) {
    printf("could not open \"%s\"\n", argv[1]);
    return 1;
  }

  if (!strcmp(argv[2], "info")) {
    info(device_fd);
  } else if (!strcmp(argv[2], "timeout")) {
    if (argc < 4) {
      printf("must specify timeout value\n");
      result = 1;
    } else {
      
      int timeout = strtoul(argv[3], NULL, 0);
      ioctl(device_fd, WDIOC_SETTIMEOUT, &timeout);
      printf("The timeout was set to %d seconds\n", timeout);
    }
  } else if (!strcmp(argv[2], "led")) {
    if (argc < 4) {
      printf("must specify LED mask\n");
      result = 1;
    } else {
      
      int led_mask = strtoul(argv[3], NULL, 0);
      ioctl(device_fd, CCM2200_WDIOC_SETLED, &led_mask);
    }
  } else if (!strcmp(argv[2], "trigger")) {
    ioctl(device_fd, WDIOC_KEEPALIVE, NULL);
  } else {
    printf("unkown option\n");
    usage();
    result = 1;
  }
  
  write(device_fd, "V", 1);     /* disable watchdog on device close */
  close(device_fd);
  return result;
}



/*
 *Local Variables:
 * mode: c
 * compile-command: "make ccm2200_watchdog"
 * c-style: linux
 * End:
 */
