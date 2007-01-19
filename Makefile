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

TFTP_ROOT_DIR	= tftp_root

BUILDROOT_BASE  = buildroot
BUILDROOT_DIR	= buildroot-1.0
BUILDROOT_SOFT_FLOAT_DIR = buildroot-1.0-soft-float


U_BOOT_BASE	= u-boot
U_BOOT_DIR	= u-boot-weiss
KERNEL_BASE	= kernel
KERNEL_DIR	= linux-2.6.12.5-ccm2200

.PHONY: all
all: buildroot buildroot-soft-float u-boot kernel


.PHONY: buildroot
buildroot:
	make -C $(BUILDROOT_BASE)/$(BUILDROOT_DIR)
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

.PHONY: prepare_tree
prepare_tree:
	sh prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD

# Local Variables:
# mode: makefile
# compile-command: "make"
# End:
