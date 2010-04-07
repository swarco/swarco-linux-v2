/*****************************************************************************/
/**
 *  @file          led_blinkd.c
 *
 *                 daemon for led linux led blink,
 *                 blink times / codes can be send by shell_scripts using
 *                 a named pipe:
 *
 *                 echo 0 1000 100 100 100 >/tmp/led0 
 *
 *                 or:
 *                 echo 0 off >/tmp/led0 
 *                 echo 0 on >/tmp/led0 
 *               
 *                 first value is the led number (only 0 supported currently)
 *                 values are pairs of LED off time and LED on time in msec
 *
 *
 *  @par Program:  
 *                 Weiss Linux Usermode
 *
 *  @version       0.1 (\$Revision$)
 *  @author        Guido Classen <br>
 *                 Weiss Electronic GmbH
 *
 *  $LastChangedBy$  
 *  $Date$
 *  $URL$
 *
 *  @par Modification History:
 *     - 2010-02-26 gc: initial version
 */
 /****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int led_fd;
int blink_state = 0;
unsigned *delay_times = NULL;
unsigned *delay_ptr = NULL;
unsigned delay_entries = 0;


void set_led(void)
{
//  printf("blink %d \n", blink_state);
  if (blink_state) {
    write(led_fd, "100", 3);
  } else {
    write(led_fd, "0", 1);
  }
}

void start_blink_cycle(void)
{
  blink_state = 0;
  delay_ptr = delay_times;
}


int main(int argc, char **argv)
{
  char buf[8192];
  char *endp;
  int fd_rd, fd_wr, n;
  unsigned count=0;
  const char *fifo_name;


  if (argc != 3) {
    printf("synopsis: %s device fifo\n", argv[0]);
    exit(1);
  }

  led_fd = open(argv[1], O_RDWR, 0666);
  if(led_fd == -1) {
    perror("open : ");
    exit(1);
  }

  fifo_name = argv[2];
  unlink(fifo_name);
  if (mkfifo(fifo_name, S_IRUSR|S_IWUSR|S_IWGRP) < 0)
//  if (mknod(fifo_name, O_RDWR) < 0)
  {
    fprintf(stderr, "Could not create fifo.\n");
    exit(1);
  }
  fd_rd = open(fifo_name, O_RDONLY);
  if(fd_rd == -1) {
    perror("open : ");
    exit(1);
  }

  /* open same fifo for write, to prevent we get an EOF if first
   * client closes FIFO.
   * The EOF event can not be removed from FIFO fd, so select and read
   * don't block anymore and will always return 0 immediately
   */
  fd_wr = open(fifo_name, O_WRONLY | O_NONBLOCK);
  if(fd_wr == -1) {
    perror("open : ");
    exit(1);
  }

  for (;;) {
    fd_set file_descriptor_set;
    struct timeval timeout;
    int sel_result;
    FD_ZERO(&file_descriptor_set);
    FD_SET(fd_rd, &file_descriptor_set);
    if (delay_ptr) {
      if (delay_ptr >= delay_times + delay_entries) {
        //printf("cycle\n");
        start_blink_cycle();
      }
      //printf("next delay: %u ", *delay_ptr);
      set_led();
      timeout.tv_sec = 0;
      timeout.tv_usec = *delay_ptr * 1000;
      ++delay_ptr;
    } else {
      timeout.tv_sec = 1;
      timeout.tv_usec = 0;
    }
    sel_result = select(fd_rd+1, &file_descriptor_set, NULL, NULL, &timeout);
    if (sel_result < 0) {
      perror("select: ");
      exit(1);
    }

    /* if select timeouts toggle blink_state  */
    if (sel_result == 0 && delay_ptr) {
      blink_state = !blink_state;
    }
    if (sel_result >= 1 && FD_ISSET(fd_rd, &file_descriptor_set)) {

      n = read(fd_rd, buf, sizeof(buf));
      
//      if(n > 0) 
//        printf("%.*s\n", n, buf);
      
      count = 0;
      endp = buf;
      while (endp < buf+n) {
        if (count == 1) {
          if (!strncmp(endp, "off", 3)) {
            //printf("off\n");
            blink_state = 0;
            set_led();
          } else if (!strncmp(endp, "on", 2)) {
            //printf("on\n");
            blink_state = 1;
            set_led();
          }
        }

        if (isdigit(*endp)) {
          unsigned long t;
          t = strtoul(endp, &endp, 10);
          ++count;
        } else {
          ++endp;
        }
      }


      delay_ptr = NULL;
      if (delay_times) { 
        free(delay_times);
        delay_times = NULL;
      }
      if (count > 1) {
        delay_entries = count-1;
        delay_times = malloc(delay_entries * sizeof(unsigned));
        endp = buf;
        count = 0;
        while (endp < buf+n) {
          if (isdigit(*endp)) {
            unsigned t = strtoul(endp, &endp, 10);
            if (count != 0)
              delay_times[count-1] = t;
            count++;
          } else {
            ++endp;
          }
        }
        start_blink_cycle();
      }
    }
  }
  return 0;
}

/*
 *Local Variables:
 * mode: c
 * compile-command: "arm-linux-uclibc-gcc -o led_blinkd led_blinkd.c"
 * c-style: linux
 * End:
 */
