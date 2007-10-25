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
#WEISS_CD_DIR = $(HOME)/mnt/entwicklung/WeissEmbeddedLinux/DistriCD
# offline directory
WEISS_CD_DIR = $(HOME)/mnt/daten/WeissEmbeddedLinux_lokal/DistriCD

include	$(BASE_DIR)/directories.mk

.PHONY: all
all: buildroot buildroot-soft-float u-boot kernel \
     modules_install usermode buildroot


.PHONY: buildroot
buildroot:
#	make -C $(BUILDROOT_PATH) #this dosn't work WHY?
	cd $(BUILDROOT_PATH); make
	cp $(BUILDROOT_PATH)/rootfs-ccm2200-?p-nand.jffs2 $(TFTP_ROOT_DIR)


.PHONY: buildroot-soft-float
buildroot-soft-float:
	-make -C $(BUILDROOT_BASE)/$(BUILDROOT_SOFT_FLOAT_DIR)


.PHONY: u-boot
u-boot:
	cd $(U_BOOT_PATH); sh build-ccm2200.sh


.PHONY: kernel
kernel:
	cd $(KERNEL_PATH); sh build-ccm2200.sh


.PHONY: modules_install
modules_install:
	cd $(KERNEL_PATH); sh build-ccm2200.sh modules_install


.PHONY: usermode
usermode:
	make -C usermode


.PHONY: prepare_tree
prepare_tree:
	sh prepare_tree.sh $(WEISS_CD_DIR)


TODAY = $(shell date +%Y%m%d)

# save modified versions from working directory back to Weiss-Embedded
# Linux-CD 
.PHONY: u-boot-dist
u-boot-dist:
	cd $(U_BOOT_PATH); make distclean
	cd $(U_BOOT_BASE); tar cvzf $(WEISS_CD_DIR)/sources/u-boot/u-boot-ccm2200-$(TODAY).tar.gz $(U_BOOT_DIR)
	cd $(U_BOOT_BASE)/u-boot-git; make distclean
	cd $(U_BOOT_BASE); tar cvzf $(WEISS_CD_DIR)/sources/u-boot/u-boot-git-$(TODAY).tar.gz u-boot-git
	-cd $(U_BOOT_BASE); diff -Nrub '--exclude=*~' --exclude=.depend --exclude=.git u-boot-git $(U_BOOT_DIR) >$(WEISS_CD_DIR)/sources/u-boot/u-boot-ccm2200-$(TODAY).patch


KERNEL_ORIG = linux-orig
PATCH_FILE  = 201-weiss-ccm2200.patch
OUTPUT      = output-2.6.21-ccm2200
KERNEL_DIR  = linux-2.6.21-ccm2200
KERNEL_CD_DIR= $(WEISS_CD_DIR)/sources/kernel/2.6.21
CONFIG_CD    = $(KERNEL_CD_DIR)/kernel-config-2.6.21-ccm2200

.PHONY: kernel-dist
kernel-dist:
	cp $(KERNEL_BASE)/$(OUTPUT)/.config $(CONFIG_CD)
	# extract a kernel with all patches except Weiss CCM2200 patch!
	cd $(KERNEL_BASE) ; \
        ( \
	  \rm -rf $(KERNEL_ORIG) $(KERNEL_ACTUAL) ;\
	  # extract kernel                                      \
	  tar xjf $(KERNEL_CD_DIR)/linux-2.6.*.tar.bz2 ;\
	  mv $(KERNEL_ACTUAL) $(KERNEL_ORIG) ;\
	  cd linux-orig ;\
          \
	  # apply patches                                       \
	  for patch in $(KERNEL_CD_DIR)/[0-9]*.patch ;\
	  do \
	    if [ "$${patch##*/}" != "$(PATCH_FILE)" ] ; then \
	      echo applying patch: "$${patch##*/}" ;\
	      patch -p1 < $$patch ;\
	    fi ;\
	  done ;\
          \
#	  test -f $(KERNEL_CD_DIR)/cifs_1.44.tar.gz && tar xvzf $(KERNEL_CD_DIR)/cifs_1.44.tar.gz ;\
	)
	# create new Weiss CCM2200 patch
	-cd $(KERNEL_BASE); diff -Nrub '--exclude=*~' $(KERNEL_ORIG) $(KERNEL_DIR) >$(KERNEL_CD_DIR)/new_$(PATCH_FILE)
#	\rm -rf $(KERNEL_ORIG)



# Local Variables:
# mode: makefile
# compile-command: "make"
# End:
