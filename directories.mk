#*****************************************************************************
#* 
#*  @file          directories.mk
#*
#*                 Weiss-Embedded-Linux Repository
#*
#*  @par Program:  set makefile variable to actual directories
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
#*   2007-02-05 gc: initial version
#*
#*****************************************************************************

TFTP_ROOT_DIR	= tftp_root

BUILDROOT_BASE  = buildroot
BUILDROOT_DIR	= buildroot-2.0
BUILDROOT_SOFT_FLOAT_DIR = buildroot-1.0-soft-float
BUILDROOT_PATH  = $(BASE_DIR)/$(BUILDROOT_BASE)/$(BUILDROOT_DIR)
CH_CONFIG_DIR	= $(BASE_DIR)/$(BUILDROOT_BASE)/weiss_ch_conf


U_BOOT_BASE	= u-boot
U_BOOT_DIR	= u-boot-ccm2200
U_BOOT_PATH     = $(BASE_DIR)/$(U_BOOT_BASE)/$(U_BOOT_DIR)
KERNEL_BASE	= kernel
KERNEL_ACTUAL   = linux-2.6.21
KERNEL_DIR	= $(KERNEL_ACTUAL)-ccm2200
KERNEL_PATH     = $(BASE_DIR)/$(KERNEL_BASE)/$(KERNEL_DIR)

CROSS_CC	= arm-linux-uclibc-gcc
CROSS_STRIP	= arm-linux-uclibc-strip

PATH	       := $(PATH):$(BUILDROOT_PATH)/build_arm/staging_dir/bin/
export PATH


# Local Variables:
# mode: makefile
# compile-command: "make"
# End:
