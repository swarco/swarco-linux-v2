#*****************************************************************************
#* 
#*  @file          Makefile
#*
#*                 Weiss-Embedded-Linux Repository
#*
#*  @par Program:  Weiss-Embedded-Linux Repository
#*
#*  @version       1.0 (\$Revision: 332 $)
#*  @author        Guido Classen
#*                 Weiss Electronic GmbH
#* 
#*  $LastChangedBy: clg9tr $  
#*  $Date: 2006-11-24 18:21:01 +0100 (Fr, 24 Nov 2006) $
#*  $URL: svn://server-i/layer-79/makefile $
#*
#*  @par Modification History:
#*   2007-01-18 gc: initial version
#*
#*  @par Makefile calls:
#*
#*  Build: 
#*   make 
#*
#*****************************************************************************

.PHONY: all
all: buildroot u-boot kernel


.PHONY: buildroot
buildroot:
	cd buildroot/buildroot-1.0/; make

.PHONY: u-boot
u-boot:
	cd u-boot/u-boot-weiss; sh weiss.sh

.PHONY: kernel
kernel:
	cd kernel/linux-2.6.12.5-ccm2200; sh weiss.sh

.PHONY: prepare_tree
prepare_tree:
	sh prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD

# Local Variables:
# mode: makefile
# compile-command: "make"
# End:
