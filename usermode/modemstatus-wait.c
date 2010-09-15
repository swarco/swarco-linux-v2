/*****************************************************************************/
/**
 *  @file          modemstatus-wait.c
 *
 *                 wait until speficified modem status signal change or
 *                 serial port events occur
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
 *     - 2010-03-08 gc: initial version
 */
 /****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>             /* memset() */
#include <errno.h>

#include <termios.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <signal.h>
#include <unistd.h>

#include <linux/serial.h>

enum ExitCode {

  EC_RING       = 1,
  EC_BREAK      = 2,

  EC_PID        = 64,
  EC_ERROR      = 255
};

void usage(void)
{
  printf("usage: modemstatus-wait [-F device] [ri] [break] [pid <pid>]\n");
  printf("or     modemstatus-wait -r [-F device]\n");
}


static void alarm_handler(int sig, siginfo_t *si, void *data)
{
  //printf("signal\n");
}

void print_status(int tty_fd)
{
  struct serial_icounter_struct icounter_new;
  int status;

  memset(&icounter_new, 0, sizeof(icounter_new));
  
  if (ioctl(tty_fd, TIOCGICOUNT, &icounter_new) != 0)
  {
    perror (" TIOCGICOUNT failed.");
    exit(EC_ERROR);
  }

  if (ioctl(tty_fd, TIOCMGET, &status) != 0) {
    perror (" TIOCMGET failed.");
    exit(EC_ERROR);
  }

  printf("status=%08x\n", status);
  printf("CTS=%d\n", (status & TIOCM_CTS) ? 1 : 0);
  printf("DSR=%d\n", (status & TIOCM_DSR) ? 1 : 0);
  printf("RI=%d\n", (status & TIOCM_RNG) ? 1 : 0);
  printf("DCD=%d\n", (status & TIOCM_CAR) ? 1 : 0);
  printf("RTS=%d\n", (status & TIOCM_RTS) ? 1 : 0);
  printf("DTR=%d\n", (status & TIOCM_DTR) ? 1 : 0);

  printf("RI_COUNT='%d'\n"
         "CD_COUNT='%d'\n"
         "CTS_COUNT='%d'\n"
         "DSR_COUNT='%d'\n",
         icounter_new.rng, icounter_new.dcd,
         icounter_new.cts, icounter_new.dsr);
  printf("RX_COUNT='%d'\n"
         "TX_COUNT='%d'\n"
         "FE_COUNT='%d'\n"
         "OVERR_COUNT='%d'\n"
         "PARITY_ERR_COUNT='%d'\n"
         "BRK_COUNT='%d'\n"
         "BUF_OVERR_COUNT='%d'\n",
         icounter_new.rx, icounter_new.tx,
         icounter_new.frame, icounter_new.overrun,
         icounter_new.parity, icounter_new.brk,
         icounter_new.buf_overrun);

}

int wait_ri = 0;
int wait_break = 0;
pid_t wait_pid = 0;               /* pid 0 is not allowed on unix systems (see man fork()) */

int tty_fd = STDIN_FILENO;

int main(int argc, char **argv)
{
  struct serial_icounter_struct icounter_old, icounter_new;

  int res = -1;
  struct sigaction act;
  int i;
  int do_print_status = 0;

  memset(&icounter_old, 0, sizeof(icounter_old));
  memset(&icounter_new, 0, sizeof(icounter_new));
  for (i=1; i<argc; ++i) {
    const char *arg = argv[i];
    if (!strcmp("-s", arg)) {
      do_print_status = 1;
    } else if (!strcmp("-F", arg)) {
      if (i == argc-1) {
        fprintf(stderr, "-F: expect argument: device name\n");
        exit(EC_ERROR);
      }
      tty_fd = open(argv[++i], O_RDONLY | O_NONBLOCK | O_NOCTTY);
      if (tty_fd == -1) {
        fprintf(stderr, "can not open device %s\n", argv[i]);
        exit(EC_ERROR);
      }
    } else if (!strcmp("ri", arg)) {
      wait_ri = 1;
    } else if (!strcmp("break", arg)) {
      wait_break = 1;
    } else if (!strcmp("pid", arg)) {
      if (i == argc-1) {
        fprintf(stderr, "pid: expect argument: device name\n");
        exit(EC_ERROR);
      }
      wait_pid = (pid_t ) strtoul(argv[++i], NULL, 10);
    }
  }

  /* print status  */
  if (do_print_status) {
    print_status(tty_fd);
    exit(0);
  }

  act.sa_sigaction = alarm_handler;
  sigemptyset(&act.sa_mask);
  act.sa_flags = SA_SIGINFO;
  sigaction(SIGALRM, &act, NULL);


  if (ioctl(tty_fd, TIOCGICOUNT, &icounter_old) != 0)
  {
    perror (" TIOCGICOUNT failed.");
    exit(EC_ERROR);
  }

  for ( ; ; )
  {
    if (wait_pid != 0) {
      /* check existence of process pid without sending a signal */
      if (kill(wait_pid, 0) == -1) {

        /* process existing, but we have no access permission */
        if (errno != EPERM) {
          printf("process %d terminated\n", wait_pid);
          exit(EC_PID);
        }
      }
    }

    if (res == 0) {

      printf("Count: RI=%6d # CD=%6d # CTS=%6d # DSR=%6d\n",
             icounter_new.rng, icounter_new.dcd,
             icounter_new.cts, icounter_new.dsr);
      printf("       RX=%6d # TX=%6d #  FE=%6d # OVERR=%4d  \n"
             "       PARITY=%2d # BRK=%5d # BUF_OVERR=%6d\n",
             icounter_new.rx, icounter_new.tx,
             icounter_new.frame, icounter_new.overrun,
             icounter_new.parity, icounter_new.brk,
             icounter_new.buf_overrun);
    }

    if (ioctl(tty_fd, TIOCGICOUNT, &icounter_new) != 0)
    {
      perror (" TIOCGICOUNT failed.");
      exit(EC_ERROR);
    }

    if (wait_ri && icounter_new.rng != icounter_old.rng) {
      printf("got ring\n");
      exit(EC_RING);
    }

    if (wait_break && icounter_new.brk != icounter_old.brk) {
      printf("got break\n");
      exit(EC_BREAK);
    }

    {
      struct itimerval new;
      new.it_interval.tv_usec = 0;
      new.it_interval.tv_sec = 0;
      new.it_value.tv_usec = 100000;
      new.it_value.tv_sec = 0;
      setitimer(ITIMER_REAL, &new, NULL);
    }

    res = ioctl(tty_fd, TIOCMIWAIT, TIOCM_RNG | TIOCM_CTS | TIOCM_DSR | TIOCM_CD);

    //printf("res: %d\n", res);
    {
      struct itimerval new;
      new.it_interval.tv_usec = 0;
      new.it_interval.tv_sec = 0;
      new.it_value.tv_usec = 0;
      new.it_value.tv_sec = 0;
      setitimer(ITIMER_REAL, &new, NULL);
    }
  }

  return 0;
}


/*
 *Local Variables:
 * mode: c
 * compile-command: "gcc -o modemstatus-wait modemstatus-wait.c"
 * c-style: linux
 * End:
 */
