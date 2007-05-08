/*
 * usermode/ccm2200_gpio_test.c
 *
 * Copyright (C) 2007 by Weiss-Electronic GmbH.
 * All rights reserved.
 *
 * @author:     Guido Classen <guido.classen@weiss-electronic.de>
 * @descr:      Userspace tool to access CCM2200 digital in-/output lines
 *              and indicator LEDs
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
 *     2007-05-08 gc: support for continuous option
 *     2007-02-05 gc: initial version
 */

#include <stdio.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

/* linux includes */
#include <linux/types.h>
#include <linux/ioctl.h>

/* this needs a include path to actual CCM2200 Linux kernel! */
#include <linux/ccm2200_gpio.h>



int main(int argc, char *argv[])
{
  int device_fd;
  struct ccm2200_gpio_ioctl_data ioctl_data;
  unsigned port;
  unsigned mask = 0xffffffff;
  unsigned value = -1;
  int init = 1;
  int output = 0;
  int loop = 0;
  int continuous = 0;

  if (argc < 3) {
    printf("usage: ccm2200_gpio_test -c device in|out|led|sconf|loop "
           "[value] [mask]\n"
           "       -c continuous display\n");
    return 1;
  }

  if (!strcmp(argv[1], "-c")) {
    continuous = 1;
    ++argv;
    --argc;
  }

  if ((device_fd = open(argv[1], O_RDWR | O_SYNC)) == -1) {
    printf("could not open \"%s\"\n", argv[1]);
    return 1;
  }

  if (!strcmp(argv[2], "out")) {
    output = 1;
    port = CCM2200_GPIO_OUTPUT;
  } else if (!strcmp(argv[2], "in")) {
    output = 0;
    port = CCM2200_GPIO_INPUT;
  } else if (!strcmp(argv[2], "led")) {
    output = 1;
    port = CCM2200_GPIO_LED;
  } else if (!strcmp(argv[2], "sconf")) {
    output = 0;
    port = CCM2200_GPIO_SCONF;
  } else if (!strcmp(argv[2], "loop")) {
    output = 0;
    loop = 1;
    port = CCM2200_GPIO_INPUT;
    mask = 0xfff;
  } else {
    printf("unkown port, use in, out or led\n");
    return -1;
  }

  if (output) {
    if (argc < 4) {
      printf("must specify value for output operation\n");
      return 1;
    }
    ioctl_data.data = strtoul(argv[3], NULL, 0);
    if (argc > 4) {
      mask = strtoul(argv[4], NULL, 0);
    }
  } else {
    if (argc > 3) {
      mask = strtoul(argv[3], NULL, 0);
    }
  }

  /*   printf("dev: %d, value: 0x%08x, mask: 0x%08x\n", port, ioctl_data.data, */
  /*          mask); */

  for (;;) {
    ioctl_data.device = port;
    ioctl_data.mask   = mask;
    if (ioctl(device_fd, (output ? CCM2200_GPIO_OUT : CCM2200_GPIO_IN), 
              &ioctl_data) != 0) {
      printf("error in ioctl(), perhaps wrong device?\n");
    }
    if (output) {
      break;
    }
    if (init || value != ioctl_data.data) {
      init = 0;
      value = ioctl_data.data;

      if (loop) {
        ioctl_data.mask   = mask;
        ioctl_data.device = CCM2200_GPIO_OUTPUT;
        ioctl_data.data   = value;
        ioctl(device_fd, CCM2200_GPIO_OUT, &ioctl_data);
        ioctl_data.device = CCM2200_GPIO_LED;
        ioctl_data.data   = value;
        ioctl(device_fd, CCM2200_GPIO_OUT, &ioctl_data);
      }

      printf("0x%08x\n", value);
    }

    if (!continuous)
      break;

    usleep(50000);
  }

  
  close(device_fd);
  return 0;
}



/*
 *Local Variables:
 * mode: c
 * compile-command: "make ccm2200_gpio_test"
 * c-style: linux
 * End:
 */
