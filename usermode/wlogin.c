/*****************************************************************************/
/** 
 *  @file          wlogin.c
 *
 *                 
 *  @par Library:  
 *                 Common
 *
 *  @version       0.0.7 (\$Revision$)
 *  @author        Markus Forster <br>
 *                 Weiss-Electronic GmbH
 *  
 *  $LastChangedBy$  
 *  $Date$
 *
 *  @par Modification History:
 *     - 2007-02-15 mf: Initial Version (Weiss Auto Logout)
 */  
 /****************************************************************************/
/* standard icludes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pty.h>
#include <termios.h>
#include <pthread.h>
#include <curses.h>
#include <utmp.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/signal.h>
#include <sys/wait.h>
#include <sys/types.h>

/* constants */
#define MAX_CHARS 4096

/* global variables */
static time_t ref_time;  /* reference time, first set
			  * if parent process is started.
			  */
static pthread_mutex_t lock;
static pthread_cond_t  cond;

struct termios store_terminal;
static int mtimeout;
static int time_to_live;
pid_t mpgpid;

void mycatch(int sig);
void *idlecounter(void *mtimeout);
int tty_raw(int fd);
void *wlogin(void *prog, int mtimeout);

void mycatch(int sig){
  tcsetattr(0, TCSAFLUSH, &store_terminal);
  exit(1);
}

/* function definitions */

int main(int argc, char *argv[]){

  /********************************************************* 
   * args are:
   * 1) program to execute
   * 2) time ins sec until autologout
   *
   *********************************************************/

  char *prog; /* program to execute */

  if( argc != 3){
    printf("\nUsage: wlogin <programm_to_execute> ");
    printf("<mtimeout_intervall_in_sec>\n\n");
    printf("Report bugs to:\n\n");
    printf("markus.forster@weiss-electronic.de\n\n");
    exit(0);
  }

  ref_time = time(&ref_time);

  prog = (char *)malloc(strlen(argv[1])*sizeof(char) + 1);

  strcpy(prog, argv[1]);
  mtimeout = strtol(argv[2],NULL,10);
  time_to_live = 0;

  signal(SIGPIPE, mycatch);
  signal(SIGKILL, mycatch);
  signal(SIGCHLD, mycatch);
  signal(SIGINT, mycatch);
  signal(SIGQUIT, mycatch);
  /**
   * start wlogin function with given login-shell 
   * and time until logout.
   **/
  wlogin(prog, mtimeout);
  free(prog);
  return 0;
}

/***********************************************************************
 *
 * checks idle time every second and terminates process if
 * idletime exeeds timeout value 
 * 
 **********************************************************************/
struct timespec retTimeVal(struct timespec *inTimeVal)
{
  struct timespec tm;
  struct timeval now;
  gettimeofday(&now, NULL);
  tm.tv_sec = now.tv_sec + 1;
  tm.tv_nsec = now.tv_usec * 1000;
  
  return tm;
}

void *idlecounter(void *mtimeout){
  time_t act_time;
  int ret;

  struct timespec tm;
  tm = retTimeVal(&tm);
  //printf("%i\n" ,tm);
  pthread_mutex_lock(&lock);

  while(1){
    fflush(0);
    //sleep(1);
    ret = pthread_cond_timedwait(&cond, &lock, &tm);
#ifdef DEBUG
    fprintf(stderr, "%i from Thread\n", ret);
#endif /* DEBUG */
    tm = retTimeVal(&tm);
    pthread_mutex_unlock(&lock);
    act_time = time(&act_time);
    time_to_live = (act_time - ref_time);
#ifdef DEBUG
    fprintf(stderr, "%i ...\n", time_to_live);
#endif /* DEBUG */
    if (time_to_live > *(int *)mtimeout){
      tcsetattr(0, TCSAFLUSH, &store_terminal);
#ifdef DEBUG
    printf("\n\nYour are automatically logged out by weiss-autologout\nWith pid : %i\n\n", mpgpid);
#endif /* DEBUG */
    /* kill all children of login shell and shell itself. */
    kill(mpgpid, SIGHUP);
    exit(351);
    }
  }
  return(0);
}

/*******************************************************************
 *
 * set terminal with filedescriptor fd into raw mode
 * 
 ******************************************************************/
int tty_raw(int fd)
{
  struct termios terminal;
  if (tcgetattr(fd, &store_terminal) < 0){
    fprintf(stderr,
	    "Terminal settings not valid.\n");
    return(-1);
  }
  terminal = store_terminal;
  
  terminal.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
  terminal.c_cflag &= ~(CSIZE | PARENB);
  terminal.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
  terminal.c_cflag |= CS8;
  
  /*
  terminal.c_lflag &= ~(ECHO|ICANON);
  terminal.c_cc[VMIN] = 1;
  terminal.c_cc[VTIME] = 0;
  */
  tcsetattr(fd, TCSAFLUSH, &terminal);
  return 0;
}

/**********************************************************************
 *
 * fork new process and exec given program in child process
 * also start timer-thread.
 *
 *********************************************************************/
void *wlogin(void *prog, int mtimeout){
  pid_t pty_pid;
  pthread_t p1;
  int status;
  int master;
  int slave;
  int n, m;
  char mbuf[MAX_CHARS];
  char  sbuf[MAX_CHARS];
  fd_set fds;
  fd_set tmp;
  int retval;
  struct termios terminal;
  

  pthread_mutex_init(&lock, NULL);
  pthread_cond_init(&cond, NULL);

  /* Create a new process on a new pty and open two file-handles */
  openpty(&master, &slave, NULL, NULL, NULL);

  FD_ZERO(&fds);
  FD_SET(STDIN_FILENO,&fds);
  FD_SET(master, &fds);
  
  tcgetattr(master, &store_terminal);
  terminal = store_terminal;
  //terminal.c_lflag &= ~(ECHO|ICANON);
  cfmakeraw(&terminal);
  terminal.c_iflag &= (OPOST|ICRNL);
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &terminal);
  
  //tty_raw(0);
  
  if ((pty_pid = fork()) < 0){
    perror("error on fork");
    exit(2);
  }
  // child
  else if (pty_pid == 0){
    login_tty(slave);
    printf("You are logged in over weiss-autologout,\nthe session will terminate after %i seconds of unactivity.\n\n", mtimeout);
    execl((char *)prog, "-sh", NULL);
    perror("can't execute given shell !\n");
    exit(33);
  }
  // parent
  else{
    mpgpid = pty_pid;
    pthread_create(&p1, NULL, idlecounter, &mtimeout);
    while((pty_pid = waitpid(-1, &status, WNOHANG)) == 0){
      tmp = fds;
      if ((retval = select(master+1, &tmp, 0, 0, 0)) == -1)
	perror("select()");
      if (retval > 0){
	if (FD_ISSET(master, &tmp)){
	  n = read(master, mbuf, sizeof(mbuf));
	  write(STDOUT_FILENO, mbuf, n);
	  if (n == 0)
	    break;
	  ref_time = time(&ref_time);
	}
	if(FD_ISSET(STDIN_FILENO, &tmp)){
	  m = read(STDIN_FILENO,sbuf,sizeof(sbuf));
	  if (m == 0)
	    break;
	  ref_time = time(&ref_time);
	  write(master, sbuf, m);
	}
      }
    }
    exit(0);
  }
  return(0);  
}

/**
 * EOF 
 * compile-command: "gcc -g -DGLIBCLINUX -D_REENTRANT wlogin.c -o wlogin -lpthread -lutil"
 */
