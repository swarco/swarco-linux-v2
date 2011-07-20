/*
 * usermode/ccm2200_watchdog.c
 *
 * Copyright (C) 2007 by Weiss-Electronic GmbH.
 * All rights reserved.
 *
 * @author:     Guido Classen <guido.classen@weiss-electronic.de>
 * @descr:      Userspace tool to config CCM2200 board specific serial modes
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
 *     2011-07-20 gc: new naming for RS485 modes using upercase letters, 
 *                    legacy modes can be accessed by old lowercase names 
 *     2007-02-05 gc: initial version
 */

#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

/* linux includes */
#include <linux/types.h>
#include <linux/ioctl.h>

/* this needs a include path to actual CCM2200 Linux kernel! */
#include <linux/ccm2200_serial.h>


void usage(void)
{
  printf("usage: ccm2200_serial device info\n"
         "       ccm2200_serial device mode <NORMAL|RS232|RS485HW|RS485INT|RS485KERN|RS485KERN_NEG|MODEM_MD|MODEM_MD_DCD> "
         "                                  [turn-on-delay turn-off-delay]\n"
         "       ccm2200_serial device rxled mask delay\n"
         "       ccm2200_serial device txled mask delay\n");
}

void info(int fd)
{
  struct ccm2200_serial_config serial_config;
  struct ccm2200_serial_led serial_led;
  memset(&serial_config, 0, sizeof(serial_config));

  if (ioctl(fd, CCM2200_SERIAL_GET_CONF, &serial_config) == 0) {
    char mode_str[50];
    mode_str[0] = '\0';
    switch (serial_config.mode) {
    case CCM2200_SERIAL_MODE_NORMAL:
      strcat(mode_str, "normal-RS232"); break;
    case CCM2200_SERIAL_MODE_RS485HW:
      strcat(mode_str, "RS485 (controlled by UART hardware)"); break;
    case CCM2200_SERIAL_MODE_RS485KERN:
      strcat(mode_str, "RS485 (controlled by kernel)"); break;
    case CCM2200_SERIAL_MODE_MODEM_MD:
      strcat(mode_str, "Multi-drop modem mode"); break;
    default:
      sprintf(mode_str, "%d", (int) serial_config.mode);             
    };
    printf("Mode: %s, turn-on-delay: %d, turn-off-delay: %d\n",
           mode_str, 
           serial_config.turn_on_delay, 
           serial_config.turn_off_delay);
  } else {
    printf("CCM2200_SERIAL_GET_CONF operation not supported by device\n");
  }

  memset(&serial_led, 0, sizeof(serial_led));
  if (ioctl(fd, CCM2200_SERIAL_GET_TX_LED, &serial_led) == 0) {
    printf("TX-LED: Mask: 0x%04x, Delay: %d\n", 
           serial_led.mask, serial_led.delay);
  } else {
    printf("CCM2200_SERIAL_GET_TX_LED operation not supported by device\n");
  } 
  memset(&serial_led, 0, sizeof(serial_led));
  if (ioctl(fd, CCM2200_SERIAL_GET_RX_LED, &serial_led) == 0) {
    printf("RX-LED: Mask: 0x%04x, Delay: %d\n", 
           serial_led.mask, serial_led.delay);
  } else {
    printf("CCM2200_SERIAL_GET_RX_LED operation not supported by device\n");
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

  if ((device_fd = open(argv[1], O_RDWR)) == -1) {
    printf("could not open \"%s\"\n", argv[1]);
    return 1;
  }

  if (!strcmp(argv[2], "info")) {
    info(device_fd);
  } else if (!strcmp(argv[2], "mode")) {
    if (argc < 4) {
      printf("must specify mode\n");
      result = 1;
    } else {
      struct ccm2200_serial_config serial_config;
      memset(&serial_config, 0, sizeof(serial_config));

      if (!strcmp(argv[3], "RS232") || !strcmp(argv[3], "NORMAL")) {
        serial_config.mode = CCM2200_SERIAL_MODE_NORMAL;
      } else if (!strcmp(argv[3], "RS485HW")) {
        serial_config.mode = CCM2200_SERIAL_MODE_RS485HW;
      } else if (!strcmp(argv[3], "RS485INT")) {
        serial_config.mode = CCM2200_SERIAL_MODE_RS485INT;
      } else if (!strcmp(argv[3], "RS485") || !strcmp(argv[3], "RS485KERN")) {
        serial_config.mode = CCM2200_SERIAL_MODE_RS485KERN;
      } else if (!strcmp(argv[3], "RS485_NEG") 
                 || !strcmp(argv[3], "RS485KERN_NEG")) {
        serial_config.mode = CCM2200_SERIAL_MODE_RS485KERN_NEG;
      } else if (!strcmp(argv[3], "MODEM_MD")) {
        serial_config.mode = CCM2200_SERIAL_MODE_MODEM_MD;
      } else if (!strcmp(argv[3], "MODEM_MD_DCD")) {
        serial_config.mode = CCM2200_SERIAL_MODE_MODEM_MD_DCD;

      /* 2011-07-20 gc: lowercase modes only legacy modes, use
       * upercase modes for new configurations!
       */
      } else if (!strcmp(argv[3], "rs232") || !strcmp(argv[3], "normal")) {
        serial_config.mode = CCM2200_SERIAL_MODE_NORMAL;
      } else if (!strcmp(argv[3], "rs485hw")) {
        serial_config.mode = CCM2200_SERIAL_MODE_RS485HW;
      } else if (!strcmp(argv[3], "rs485int")) {
        serial_config.mode = CCM2200_SERIAL_MODE_RS485INT;
      } else if (!strcmp(argv[3], "rs485") || !strcmp(argv[3], "rs485kern")) {
        /* this mode is renamed as CCM2200_SERIAL_MODE_MODEM_MD */
        serial_config.mode = CCM2200_SERIAL_MODE_MODEM_MD;
      } else if (!strcmp(argv[3], "modemmd")) {
        /* this mode is renamed as CCM2200_SERIAL_MODE_MODEM_MD_DCD */
        serial_config.mode = CCM2200_SERIAL_MODE_MODEM_MD_DCD;
      } else {
        printf("unknown mode specified\n");
        usage();
        result = 1;
        goto cleanup;
      }
      if (argc > 4) {
        serial_config.turn_on_delay = strtoul(argv[4], NULL, 0);   
      }
      if (argc > 5) {
        serial_config.turn_off_delay = strtoul(argv[5], NULL, 0);
      }
      
      if (ioctl(device_fd, CCM2200_SERIAL_SET_CONF, &serial_config) != 0) {
        printf("CCM2200_SERIAL_SET_CONF operation failed!\n");
      }
    }
  } else if (!strcmp(argv[2], "rxled") || !strcmp(argv[2], "txled")) {
    if (argc < 4) {
      printf("must specify LED mask\n");
      result = 1;
      goto cleanup;
    } else {
      struct ccm2200_serial_led serial_led;
      memset(&serial_led, 0, sizeof(serial_led));
      
      serial_led.mask = strtoul(argv[3], NULL, 0);
      if (argc > 4) {
        serial_led.delay = strtoul(argv[4], NULL, 0);
      } else {
        serial_led.delay = 0;
      }

      if (ioctl(device_fd, 
                (argv[2][0] == 'r' 
                 ? CCM2200_SERIAL_SET_RX_LED
                 : CCM2200_SERIAL_SET_TX_LED), 
                &serial_led) != 0) {
        printf("CCM2200_SERIAL_SET_RX/TX_LED operation failed!\n");
      }
    }
  } else {
    printf("unkown option\n");
    usage();
    result = 1;
  }
  
cleanup:
  close(device_fd);
  return result;
}



/*
 *Local Variables:
 * mode: c
 * compile-command: "make ccm2200_serial"
 * c-style: linux
 * End:
 */
