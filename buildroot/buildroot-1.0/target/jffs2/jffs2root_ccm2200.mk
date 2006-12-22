#*****************************************************************************
#* 
#*  @file          jffsroot_ccm2200.mk
#*
#*  Build the jffs2 root filesystem images for Weiss CCM2200
#*
#*  @version       1.0 (\$Revision: 1818 $)
#*  @author        Guido Classen <br>
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy: fom9tr $  
#*  $Date: 2006-04-28 $
#*  $URL:  $
#*
#*  @par Modification History:
#*    2006-04-27 gc: initial version (unixdef)
#*
#*  
#*****************************************************************************

CCM2200_JFFS2_IMAGE_NAND = rootfs-ccm2200-sp-nand.jffs2
CCM2200_JFFS2_IMAGE_LP_NAND = rootfs-ccm2200-lp-nand.jffs2
CCM2200_JFFS2_IMAGE_NOR  = rootfs-unc90dev.jffs2


.PHONY: ccm2200_jffs2_images ccm2200_jffs2_prepare

ccm2200_jffs2_images: ccm2200_jffs2_prepare $(CCM2200_JFFS2_IMAGE_NAND) $(CCM2200_JFFS2_IMAGE_NOR) 


ccm2200_jffs2_prepare: host-fakeroot makedevs $(STAGING_DIR)/fakeroot.env mtd-host
	-/sbin/ldconfig -r $(TARGET_DIR) 2>/dev/null
	# Use fakeroot to pretend all target binaries are owned by root
	-$(STAGING_DIR)/usr/bin/fakeroot \
		-i $(STAGING_DIR)/fakeroot.env \
		-s $(STAGING_DIR)/fakeroot.env -- \
		chown -R root:root $(TARGET_DIR)
	# Use fakeroot to pretend to create all needed device nodes
	$(STAGING_DIR)/usr/bin/fakeroot \
		-i $(STAGING_DIR)/fakeroot.env \
		-s $(STAGING_DIR)/fakeroot.env -- \
		$(STAGING_DIR)/bin/makedevs \
		-d $(TARGET_DEVICE_TABLE) \
		$(TARGET_DIR)


.PHONY: $(CCM2200_JFFS2_IMAGE_NAND)
$(CCM2200_JFFS2_IMAGE_NAND):
	# 2006-04-27 gc: build jffs2 image for CCM2200 NAND flash
	$(STAGING_DIR)/usr/bin/fakeroot \
		-i $(STAGING_DIR)/fakeroot.env \
		-s $(STAGING_DIR)/fakeroot.env -- \
		$(MKFS_JFFS2) \
	          --pad					\
		  --pagesize=0x200 			\
		  --eraseblock=0x4000 			\
	          --no-cleanmarkers 			\
		  --little-endian 			\
		  --root=$(BUILD_DIR)/root 		\
	          --output=$(CCM2200_JFFS2_IMAGE_NAND)
	$(STAGING_DIR)/usr/bin/fakeroot \
		-i $(STAGING_DIR)/fakeroot.env \
		-s $(STAGING_DIR)/fakeroot.env -- \
		$(MKFS_JFFS2) \
	          --pad					\
		  --pagesize=2048 			\
		  --eraseblock=0x20000 			\
	          --no-cleanmarkers 			\
		  --little-endian 			\
		  --root=$(BUILD_DIR)/root 		\
	          --output=$(CCM2200_JFFS2_IMAGE_LP_NAND)
	@ls -l $(CCM2200_JFFS2_IMAGE_NAND)
	@ls -l $(CCM2200_JFFS2_IMAGE_LP_NAND)


.PHONY: $(CCM2200_JFFS2_IMAGE_NOR)
$(CCM2200_JFFS2_IMAGE_NOR):
	# 2006-04-27 gc: build jffs2 image for CCM2200 NOR flash
	$(STAGING_DIR)/usr/bin/fakeroot \
		-i $(STAGING_DIR)/fakeroot.env \
		-s $(STAGING_DIR)/fakeroot.env -- \
		$(MKFS_JFFS2) \
	          --pad                                                 \
		  --eraseblock=0x10000                                  \
		  --little-endian                                       \
		  --root=$(BUILD_DIR)/root                              \
	          --output=$(CCM2200_JFFS2_IMAGE_NOR)
		@ls -l $(CCM2200_JFFS2_IMAGE_NOR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
TARGETS += ccm2200_jffs2_images


