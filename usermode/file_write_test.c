/*****************************************************************************/
/**
 *  @file          file_write_test.c
 *
 *                 Test reliability of filesystem and block device
 *                 (mostly NAND-Flash) using continuouesly write access
 *                 to a temporary file
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
 *     - 2007-05-22 gc: initial version
 */
 /****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include <errno.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>


#define BLOCK_SIZE    1024
const int BLOCK_COUNT   = 1024*100;
const char TEST_FILENAME[] = "/file_write_test.tmp";

unsigned char test_block[BLOCK_SIZE];
unsigned char read_block[BLOCK_SIZE];

void generate_random_block()
{
  register unsigned char *ptr, *end;
  
  end = test_block+BLOCK_SIZE;
  for (ptr = test_block; ptr!=end; ++ptr) {
    *ptr = (unsigned char) (int) (256.0 * (rand() / (RAND_MAX + 1.0)));
  }
}

const char *timestamp_string(void)
{
  static char ts_string[22];
  struct tm *now;
  time_t t;
  
  time(&t);
  now = localtime(&t);
  snprintf(ts_string, sizeof(ts_string), 
          "%04d-%02d-%02d "
          "%02d:%02d:%02d ",
          now->tm_year + 1900,
          now->tm_mon+1,
          now->tm_mday,
          now->tm_hour,
          now->tm_min,
          now->tm_sec);
  return ts_string;

}

void error_message(const char *fmt, ...)
{
  va_list args;
  char buf[513];
  int len;

  strcpy(buf, timestamp_string());
  len = strlen(buf);
  
  va_start(args, fmt);
  len += vsnprintf(buf+len, sizeof(buf)-len, fmt, args);
  snprintf(buf+len, sizeof(buf)-len, ": %s", strerror(errno));
  puts(buf);                    /* write to stdout, not stderr!!! */
  fflush(stdout);                /* in case stdout is a file! */
}

int main(int argc, char *argv[])
{
  int fd;
  int block = 0;
  int blocks_total = 0;

  if ((fd = open(TEST_FILENAME, O_RDWR | O_CREAT | O_SYNC, 0666)) 
      == -1) {
    error_message("could not open %s", TEST_FILENAME);
    _exit(1);
  }

  /* create sparse file */
  lseek(fd, BLOCK_SIZE * BLOCK_COUNT - 1, SEEK_SET);
  write(fd, "", 1);

  error_message("file_write_test STARTED");
  /* test loop */
  for (block=0;; ++block) {
    if (block >= BLOCK_COUNT) 
      block = 0;

    ++blocks_total;
    generate_random_block();
    lseek(fd, BLOCK_SIZE * block, SEEK_SET);
    if (write(fd, test_block, BLOCK_SIZE) == -1) {
      error_message("write error at block %s", block);
    }
    lseek(fd, BLOCK_SIZE * block, SEEK_SET);
    if (read(fd, read_block, BLOCK_SIZE) == -1) {
      error_message("read error at block %s", block);
    }
    if (memcmp(read_block, test_block, BLOCK_SIZE)) {
      error_message("written data corrupt at block %s", block);
    }
    if ((block % 1000) == 999) {
      error_message("written %d blocks (%lld bytes)", blocks_total,
                    (long long) blocks_total * BLOCK_SIZE);
    }
    usleep(1000000);
  }

  close(fd);
  return 0;
}



/*
 *Local Variables:
 * mode: c
 * compile-command: "make"
 * c-style: linux
 * End:
 */
