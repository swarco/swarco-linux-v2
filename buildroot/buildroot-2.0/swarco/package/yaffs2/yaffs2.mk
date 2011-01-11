#############################################################
#
# yaffs2
#
#############################################################
YAFFS2_VER:=
YAFFS2_SOURCE:=yaffs2.tar.gz
YAFFS2_SITE:=http://
YAFFS2_DIR:=$(BUILD_DIR)/yaffs2
YAFFS2_BINARY:=$(YAFFS2_DIR)/utils/mkyaffs2image
#YAFFS2_TARGET_BINARY:=$(TARGET_DIR)/bin/yaffs2
#YAFFS2_PDIR=$(PWD)/package/yaffs2
#YAFFS2_CONFIG_H=$(YAFFS2_DIR)/source/include/config.h
#YAFFS2_HOST_TOOLS=bin/make_smbcodepage   \
#		 bin/make_unicodemap

$(DL_DIR)/$(YAFFS2_SOURCE):
	 $(WGET) -P $(DL_DIR) $(YAFFS2_SITE)/$(YAFFS2_SOURCE)

yaffs2-source: $(DL_DIR)/$(YAFFS2_SOURCE)

$(YAFFS2_DIR)/.unpacked: $(DL_DIR)/$(YAFFS2_SOURCE)
	zcat $(DL_DIR)/$(YAFFS2_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(YAFFS2_DIR)/.unpacked

$(YAFFS2_BINARY): $(YAFFS2_DIR)/.unpacked
	$(MAKE) -C $(YAFFS2_DIR)/utils  

yaffs2: uclibc $(BUILD_DIR)/yaffs2/utils/mkyaffs2image

yaffs2-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(YAFFS2_DIR)/source uninstall
	-$(MAKE) -C $(YAFFS2_DIR) clean

yaffs2-dirclean:
	rm -rf $(YAFFS2_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_YAFFS2)),y)
TARGETS+=yaffs2
endif
