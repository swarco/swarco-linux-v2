/*
 * usermode/ccm2200_serial.c
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
 *     2013-02-07 gc: added support for TIOCSRS485 and TIOCGRS485 ioctls
 *                    present in recent Linux kernels
 *     2011-07-20 gc: new naming for RS485 modes using upercase letters, 
 *                    legacy modes can be accessed by old lowercase names 
 *     2007-02-05 gc: initial version
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

/* linux includes */
#include <linux/types.h>
#include <linux/ioctl.h>

/* this needs a include path to actual CCM2200 Linux kernel! */
#include <linux/ccm2200_serial.h>

#if defined(TIOCSRS485) && defined(TIOCGRS485) && defined(SER_RS485_ENABLED) \
    && defined(SER_RS485_RTS_ON_SEND) && defined(SER_RS485_RTS_AFTER_SEND)   \
    && defined(SER_RS485_RX_DURING_TX)
#include <linux/serial.h>
#define HAVE_RS485_IOCTL
#endif

void usage(void)
{
  printf("usage: ccm2200_serial device info\n"
         "       ccm2200_serial device mode <NORMAL|RS232|RS485HW|RS485INT|RS485KERN|\n"
         "                                   RS485KERN_NEG|MODEM_MD|MODEM_MD_DCD>\n"
         "                                  [turn-on-delay turn-off-delay]\n"

#ifdef HAVE_RS485_IOCTL
         "       ccm2200_serial device rs485 [enable|^enable]\n"
         "                                   [rts_on_send|^rts_on_send]\n"
         "                                   [rts_after_send|^rts_after_send]\n"
         "                                   [rx_during_tx|^rx_during_tx]\n"
         "                                   [<delay_rts_before_send> <delay_rts_after_send>]\n"
#endif

         "       ccm2200_serial device rxled mask delay\n"
         "       ccm2200_serial device txled mask delay\n");
}

#ifdef HAVE_RS485_IOCTL
void kernel_rs485(int fd, int argc, char *argv[])
{
  struct serial_rs485 serial_rs485;
  memset(&serial_rs485, 0, sizeof(serial_rs485));

  if (argc == 3) {
    /* print info obtained using TIOCGRS485 */
    if (ioctl(fd, TIOCGRS485, &serial_rs485) == 0) {
      printf("%senabled %srts_on_send %srts_after_send %srx_during_tx\n"
             "delay_rts_before_send: %u delay_rts_after_send: %u\n",
             (serial_rs485.flags & SER_RS485_ENABLED ? "" : "^"),
             (serial_rs485.flags & SER_RS485_RTS_ON_SEND ? "" : "^"),
             (serial_rs485.flags & SER_RS485_RTS_AFTER_SEND ? "" : "^"),
             (serial_rs485.flags & SER_RS485_RX_DURING_TX ? "" : "^"),
             serial_rs485.delay_rts_before_send,
             serial_rs485.delay_rts_after_send);
    } else {
      printf("TIOCGRS485 operation not supported by device\n");
    }
  } else {
    int i;
    char *endptr;
    int set_delay_rts_before_send = 0;
    int set_delay_rts_after_send = 0;
    for (i=3; i < argc; ++i) {
      if (!strcmp("enabled", argv[i])) {
        serial_rs485.flags |= SER_RS485_ENABLED;
      } else if (!strcmp("^enabled", argv[i])) {
      } else if (!strcmp("rts_on_send", argv[i])) {
        serial_rs485.flags |= SER_RS485_RTS_ON_SEND;
      } else if (!strcmp("^rts_on_send", argv[i])) {
      } else if (!strcmp("rts_after_send", argv[i])) {
        serial_rs485.flags |= SER_RS485_RTS_AFTER_SEND;
      } else if (!strcmp("^rts_after_send", argv[i])) {
      } else if (!strcmp("rx_during_tx", argv[i])) {
        serial_rs485.flags |= SER_RS485_RX_DURING_TX;
      } else if (!strcmp("^rx_during_tx", argv[i])) {
      } else {
        endptr = NULL;
        unsigned long val = strtoul(argv[i], &endptr, 0);
        if (argv[i][0] != '\0' && endptr && *endptr == '\0'
            && !set_delay_rts_after_send) {
          if (!set_delay_rts_before_send) {
            set_delay_rts_before_send = 1;
            serial_rs485.delay_rts_before_send = val;
          } else {
            set_delay_rts_after_send = 1;
            serial_rs485.delay_rts_after_send = val;
          }
        } else {
          printf("ERROR: invalid argument %s\n", argv[i]);
          exit(1);
        }
      }
    }
    if (ioctl(fd, TIOCSRS485, &serial_rs485) != 0) {
      printf("TIOCSRS485 operation not supported by device\n");
    }


  }
}
#endif

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
      strcat(mode_str, "RS232 (Normal)"); break;
    case CCM2200_SERIAL_MODE_RS485HW:
      strcat(mode_str, "RS485 (UART hardware)"); break;
    case CCM2200_SERIAL_MODE_RS485KERN:
      strcat(mode_str, "RS485 (kernel)"); break;
    case CCM2200_SERIAL_MODE_RS485KERN_NEG:
      strcat(mode_str, "RS485 negated RTS (kernel)"); break;
    case CCM2200_SERIAL_MODE_MODEM_MD:
      strcat(mode_str, "Multi-drop modem mode"); break;
    case CCM2200_SERIAL_MODE_MODEM_MD_DCD:
      strcat(mode_str, "Multi-drop modem mode with DCD"); break;
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
#ifdef HAVE_RS485_IOCTL
  } else if (!strcmp(argv[2], "rs485")) {
    kernel_rs485(device_fd, argc, argv);
#endif
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
