/* demo for persistent mapping of uninitialized data (bss) */

#include <stdio.h>
#include <asm/page.h>           /* PAGE_SIZE */
//#define PAGE_SIZE 4096
char x = 'u';

char _start_persistent_data_section __attribute__ ((aligned (PAGE_SIZE)));
char str[255]; // = "Hello";
int n = 0;
char _end_persistent_data_section __attribute__ ((aligned (PAGE_SIZE)));

int main(int argc, char *argv[])
{
  /* enshure string is properly terminated... */
  str[sizeof(str)-1] = '\0';
  printf("n: %d\n", n);

  for (;;) {
    printf("string is: %s\n", str);
    printf("enter new string: "); fflush(stdout);
    fgets(str, sizeof(str)-1, stdin);
    n = 23;
  }
  return 0;
}



/*
 *Local Variables:
 * mode: c
 * compile-command: "weiss.sh"
 * End:
 */
