#!/bin/sh

gcc -g -c -fno-common persistent_map.c
gcc -g -c -fno-common -fno-zero-initialized-in-bss persistent_test.c

#objcopy --rename-section .bss=.persistent persistent_test.o persistent_test_2.o


#gcc -g -o persistent_test -Wl,-T,persistent.ld,-e,program_entry,-Map,persistent_test.map persistent_map.o persistent_test_2.o

gcc -g -o persistent_test -Wl,-e,program_entry,-Map,persistent_test.map persistent_map.o persistent_test.o

# Local Variables:
# mode: shell-script
# compile-command: "./weiss.sh"
# End:
