
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>
#include <fcntl.h>

#define info(ptr)  printf(#ptr ": %08p\n", (void*)ptr);


extern char _start_persistent_data_section;
extern char _end_persistent_data_section;
extern void _start(void);
#define PAGESIZE 4096

/* 
 * void dump()
 * {
 *   int i;
 *   unsigned char *c = (void*) &__persistent_start;
 *   size_t length = (size_t)&_end - (size_t)&__persistent_start;
 *   printf("len: %d\n", length);
 *   for (i=0; i< length; ++i) {
 *     printf("%02x ", *c++);
 *   }
 *   printf("\n");
 * }
 */

void program_entry(void)
{
  int mem_fd;
  void *start = &_start_persistent_data_section;
  size_t length = (size_t)&_end_persistent_data_section 
    - (size_t)&_start_persistent_data_section;
  length = (length + PAGESIZE - 1) & ~(PAGESIZE - 1);
  //write(1, "Hello\n", 6);
  //dump();

  if (length > 0) {

    if (munmap(start, length) != 0) {
      perror("could not unmap persistent data section");
      _exit(1);
    };

    if ((mem_fd = open("persistent.mem", O_RDWR | O_CREAT | O_SYNC, 0666)) 
        == -1) {
      perror("could not open persistent.mem");
      _exit(1);
    }
    lseek(mem_fd, length, SEEK_SET);
    write(mem_fd, "", 1);

    /* 
     * if (mmap(start, length, PROT_READ | PROT_WRITE, 
     *           MAP_FIXED | MAP_PRIVATE | MAP_ANONYMOUS, -1, 0) == MAP_FAILED) {
     */
    if (mmap(start, length, PROT_READ | PROT_WRITE, 
             MAP_FIXED | MAP_SHARED, mem_fd, 0) == MAP_FAILED) {
      write(1, "Mapping FAILED\n", 15);
      perror("Mapping FAILED");
      _exit(1);
    }

  }
  //write(1, "Hello\n", 6);
  _start();
}
