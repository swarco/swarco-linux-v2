#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

#define max(x,y) ((x) > (y) ? (x) : (y))
int main(int argc, char *argv[]) {
  fd_set rfds;
  struct timeval tv;
  int retval;
  char buf[100];
  int length;

  if (argc != 3) {
      fprintf(stderr, "syntax: forward device1 device2\n");
      exit(1);
  }
  int fd1 = -1, fd2 = -1;
  for (;;) {
    printf("reopen connection\n");
    while (fd1 < 0) {
      fd1 = open(argv[1], O_RDWR | O_NONBLOCK);
    }
      
    while (fd2 < 0) {
      fd2 = open(argv[2], O_RDWR | O_NONBLOCK);
    }
      
    printf("established\n");
      
      

    for (;;) {
      FD_ZERO(&rfds);
      FD_SET(fd1, &rfds);
      FD_SET(fd2, &rfds);
      retval = select(max(fd1,fd2)+1, &rfds, NULL, NULL, NULL);

      if (retval == -1) {
        perror("select()");
        break;
      }
       
      if (retval) {
        if (FD_ISSET(fd1, &rfds)) {
          length = read(fd1, buf, sizeof(buf));
          if (length <= 0) 
            break;
          if (write(fd2, buf, length) <= 0)
            break;
          write(1, buf, length);
        }
      }

      if (FD_ISSET(fd2, &rfds)) {
        length = read(fd2, buf, sizeof(buf));
        if (length <= 0) 
          break;
        if (write(fd1, buf, length) <= 0)
          break;
        write(1, buf, length);
      }
    }

    close(fd1);
    close(fd2);
    fd1 = fd2 = -1;
  }
  
  return 0;
}
