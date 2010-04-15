/*****************************************************************************/
/**
 *  @file          rw.c
 *
 *
 *                 Wrapper to mount root-fs readwrite  
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
 *     - 2010-04-07 gc: initial version
 */
 /****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
  struct flock fl;
  int fd;
  int count=0;
  int readwrite=-1;
  int prog_len = strlen(argv[0]);
  static const char filename[] = "/var/lock/rw_root_lock";

  if (prog_len >= 2) {
    char prog_name[3];
    prog_name[0] = argv[0][prog_len-2];
    prog_name[1] = argv[0][prog_len-1];
    prog_name[2] = '\0';

    if (!strcmp(prog_name, "rw")) {
      readwrite = 1;
    } else if (!strcmp(prog_name, "ro")) {
      readwrite = 0;
    } 
  }

  if (readwrite == -1) {
    fprintf(stderr, "program name must end with 'rw' or 'ro'\n");
    exit(1);
  }

  if (setuid(0) < 0) {
    perror("must be run as root user");
    exit(1);
  }

  memset(&fl, 0, sizeof(fl));
  fl.l_type   = F_WRLCK;  /* F_RDLCK, F_WRLCK, F_UNLCK    */
  fl.l_whence = SEEK_SET; /* SEEK_SET, SEEK_CUR, SEEK_END */
  fl.l_start  = 0;        /* Offset from l_whence         */
  fl.l_len    = 0;        /* length, 0 = to EOF           */
  fl.l_pid    = getpid(); /* our PID                      */

  if ((fd = open(filename, O_RDWR|O_CREAT, 0600)) == -1) {
    perror("open");
    exit(1);
  }

  /* Trying to get lock */
  if (fcntl(fd, F_SETLKW, &fl) == -1) {
    perror("fcntl");
    exit(1);
  }

  read(fd, &count, sizeof(count));
  if (readwrite) {
    if (count != 0) {
      readwrite = -1;
    }
    ++count;
  } else {
    if (count > 0) {
      --count;
      if (count != 0) {
        readwrite = -1;
      }
    } else {
      readwrite = -1;
    }
  }

  lseek(fd, 0, SEEK_SET);
  write(fd, &count, sizeof(count));

  fl.l_type = F_UNLCK;  /* set to unlock same region */

  if (fcntl(fd, F_SETLK, &fl) == -1) {
    perror("fcntl");
    exit(1);
  }
  close(fd);

  if (count == 0) {
    unlink(filename);
  }
  if (readwrite != -1) {
    char *prog[] = { "mount", "-oremount,ro", "/", (char *)0 };

    if (readwrite) {
      prog[1] = "-oremount,rw";
      printf("Mounting root-fs readwrite.\n");

    } else {
      printf("Mounting root-fs readonly.\n");
    }
    execve("/bin/mount", prog, NULL);
  }
}

/*
 *Local Variables:
 * mode: c
 * compile-command: "arm-linux-uclibc-gcc -o rw rw.c"
 * c-style: linux
 * End:
 */
