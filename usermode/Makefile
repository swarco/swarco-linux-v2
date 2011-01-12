#*****************************************************************************
#* 
#*  @file          Makefile
#*
#*                 SWARCO Traffic Systems Embedded-Linux
#*
#*  @par Program:  User mode utilities
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Guido Classen
#*                 SWARCO Traffic Systems GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*   2007-02-05 gc: initial version
#*
#*  @par Makefile calls:
#*
#*  Build: 
#*   make 
#*
#*****************************************************************************

BASE_DIR = $(CURDIR)/..
include	$(BASE_DIR)/directories.mk

CFLAGS		+=  -I$(KERNEL_PATH)/include
LDFLAGS         += -lpthread -lutil

PROGRAMS = ccm2200_gpio_test ccm2200_watchdog ccm2200_serial forward rw \
	   file_write_test wlogin huaweiAktBbo led_blinkd modemstatus-wait

.PHONY: all
all: $(PROGRAMS) install


.PHONY: install
install:
	cp -a $(PROGRAMS) $(CH_CONFIG_DIR)/usr/bin
	-test -e $(CH_CONFIG_DIR)/usr/bin/ro && rm $(CH_CONFIG_DIR)/usr/bin/ro
	ln -s rw $(CH_CONFIG_DIR)/usr/bin/ro 


#simple pattern rule to compile executables from just one source file!
%:	%.c
	$(CROSS_CC) -o$@ $(CFLAGS) $(LDFLAGS) $<
	$(CROSS_STRIP) $@

huaweiAktBbo:	huaweiAktBbo.c
	$(CROSS_CC) -o$@ $(CFLAGS) $(LDFLAGS) $< -lusb
	$(CROSS_STRIP) $@


.PHONY: clean
clean:
	-rm *.o
	-rm $(PROGRAMS)

# Local Variables:
# mode: makefile
# compile-command: "make"
# End:
