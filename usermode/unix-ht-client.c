/*****************************************************************************/
/**
 *  @file          unix-ht-client.c
 *
 *                 Unix domain socket client
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
 *     - 2007-02-05 gc: initial version
 */
 /****************************************************************************/

#include <stdlib.h>
#include <stdio.h>

#include <sys/socket.h>
#include <sys/un.h>

#include <fcntl.h>

#include <termios.h>

static void setraw(int fd, int raw)
{
  struct termios options;
  tcgetattr(fd, &options);
  if (raw) {
    /* local options:
     *  raw input mode 
     */
    options.c_lflag &= ~ICANON & ~ISIG & ~ECHO & ~ECHOE & IEXTEN ;
    options.c_lflag |= ECHONL;
    
  } else {
    options.c_lflag |= ICANON | ECHO | ECHOE | ISIG | ECHONL | IEXTEN;
  }
  /* set changend options now */
  tcsetattr(fd, TCSANOW, &options);
  
} 

#define max(x,y) ((x) > (y) ? (x) : (y))
int forward(int fd1, int fd2)
{
  fd_set rfds;
  struct timeval tv;
  int retval;
  char buf[100];
  int length;

  for (;;) {
    FD_ZERO(&rfds);
    FD_SET(fd1, &rfds);
    FD_SET(fd2, &rfds);
    retval = select(max(fd1,fd2)+1, &rfds, NULL, NULL, NULL);
    
    if (retval == -1) {
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
  
  return 0;
}


int send_credentials(int sock)
{
  struct ucred *ucred;
  struct msghdr msg;
  struct cmsghdr *cmsg;
  /* ancillary data buffer */
  unsigned char buf[CMSG_SPACE(sizeof(struct ucred))];
  unsigned char databuf[2];
  struct iovec iovec[1];

  memset(&msg, 0, sizeof(msg));

  /* prepare an one byte long data packet, else SCM_CREDENTIALS will
   * not work on Linux
   */
  memset(databuf, 0, sizeof(databuf));
  memset(iovec, 0, sizeof(iovec));

  databuf[0] = 'x';
  iovec[0].iov_base = &databuf;
  iovec[0].iov_len  = 1;
  msg.msg_iov = iovec;
  msg.msg_iovlen = 1;

  msg.msg_control = buf;
  msg.msg_controllen = sizeof(buf);
  cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_CREDENTIALS;
  cmsg->cmsg_len = CMSG_LEN(sizeof(struct ucred));
  ucred = (struct ucred *)CMSG_DATA(cmsg);
  memset(ucred, 0, sizeof(*ucred));
  ucred->pid = getpid();
  ucred->uid = getuid();
  ucred->gid = getgid();
  /* Sum of the length of all control messages in the buffer: */
  msg.msg_controllen = cmsg->cmsg_len;

  if (sendmsg(sock, &msg, 0) == -1) {
    perror("sendmsg");
    exit(EXIT_FAILURE);
  }
}

int main()
{
  struct sockaddr_un addr;
  int local_socket = socket(PF_UNIX, SOCK_STREAM, 0);
  int buf[100];
  
  if (local_socket == -1) {
    fprintf(stderr, "error creating socket\n");
    exit(EXIT_FAILURE);
  }

  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, "/tmp/ht",
          sizeof(addr.sun_path) - 1);

  if (connect(local_socket, (struct sockaddr *) &addr,
           sizeof(struct sockaddr_un)) == -1) {
    perror("connect");
    exit(EXIT_FAILURE);
  }
  
  send_credentials(local_socket);

  memset(buf, 0, sizeof(buf));
  recv(local_socket, buf, sizeof(buf), 0);
  printf("received: %s\n", buf);

  {
    int fd=open("/dev/tty", O_RDWR | O_NONBLOCK);

    if (fd < 0) {
      perror("open /dev/tty");
      exit(EXIT_FAILURE);
    }

    setraw(fd, 1);
    forward(fd, local_socket);
    setraw(fd, 0);
  }
  close(local_socket);
  return 0;
}


/*
 *Local Variables:
 * mode: c
 * compile-command: "gcc -o unix-ht-client unix-ht-client.c"
 * c-style: linux
 * End:
 */
