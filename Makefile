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

BASE_DIR = .
include	$(BASE_DIR)/directories.mk

.PHONY: all
all: buildroot buildroot-soft-float u-boot kernel \
     modules_install usermode buildroot


.PHONY: buildroot
buildroot:
#	make -C $(BUILDROOT_BASE)/$(BUILDROOT_DIR) #this dosn't work WHY?
	cd $(BUILDROOT_BASE)/$(BUILDROOT_DIR); make
	cp $(BUILDROOT_BASE)/$(BUILDROOT_DIR)/rootfs-ccm2200-?p-nand.jffs2 \
	   $(TFTP_ROOT_DIR)


.PHONY: buildroot-soft-float
buildroot-soft-float:
	make -C $(BUILDROOT_BASE)/$(BUILDROOT_SOFT_FLOAT_DIR)


.PHONY: u-boot
u-boot:
	cd $(U_BOOT_BASE)/$(U_BOOT_DIR); sh build-ccm2200.sh


.PHONY: kernel
kernel:
	cd $(KERNEL_BASE)/$(KERNEL_DIR); sh build-ccm2200.sh


.PHONY: modules_install
modules_install:
	cd $(KERNEL_BASE)/$(KERNEL_DIR); sh build-ccm2200.sh modules_install


.PHONY: usermode
usermode:
	make -C usermode


.PHONY: prepare_tree
prepare_tree:
	sh prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD


# Local Variables:
# mode: makefile
# compile-command: "make"
# End:
