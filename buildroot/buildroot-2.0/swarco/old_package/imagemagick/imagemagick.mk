#############################################################
#
# imagemagick
#
#############################################################
IMAGEMAGICK_VER:=6.2.9
IMAGEMAGICK_SOURCE:=ImageMagick-$(IMAGEMAGICK_VER)-0.tar.gz
IMAGEMAGICK_SITE:=http://
IMAGEMAGICK_DIR:=$(BUILD_DIR)/ImageMagick-$(IMAGEMAGICK_VER)
IMAGEMAGICK_BINARY:=$(IMAGEMAGICK_DIR)/imagemagick
IMAGEMAGICK_TARGET_BINARY:=$(TARGET_DIR)/bin/imagemagick
IMAGEMAGICK_P_DIR:=$(BUILD_DIR)/../package/imagemagick
$(DL_DIR)/$(IMAGEMAGICK_SOURCE):
	 $(WGET) -P $(DL_DIR) $(IMAGEMAGICK_SITE)/$(IMAGEMAGICK_SOURCE)



$(IMAGEMAGICK_DIR)/.unpacked: $(DL_DIR)/$(IMAGEMAGICK_SOURCE)
	zcat $(DL_DIR)/$(IMAGEMAGICK_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	#cp $(IMAGEMAGICK_P_DIR)/errno.h $(BUILD_DIR)/staging_dir/arm-linux/sys-include
	patch $(BUILD_DIR)/staging_dir/arm-linux/sys-include/errno.h $(IMAGEMAGICK_P_DIR)/imagemagick_errno.patch
	touch $(IMAGEMAGICK_DIR)/.unpacked

$(IMAGEMAGICK_DIR)/.configured: $(IMAGEMAGICK_DIR)/.unpacked
	(cd $(IMAGEMAGICK_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		./configure \
		CFLAGS="" \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--libdir=$(TARGET_DIR)/usr/local/lib \
		--datadir=$(TARGET_DIR)/usr/local/share \
		--bindir=$(TARGET_DIR)/bin \
		--with-modules \
		--enable-shared \
		--without-magick-plus-plus \
		--disable-largefile \
		--without-mpeg \
		--without-xcf \
		--without-x \
	);
	touch  $(IMAGEMAGICK_DIR)/.configured

$(IMAGEMAGICK_BINARY): $(IMAGEMAGICK_DIR)/.configured
	$(MAKE) -C $(IMAGEMAGICK_DIR) CC=$(TARGET_CC)  

$(IMAGEMAGICK_TARGET_BINARY):$(IMAGEMAGICK_BINARY)
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(IMAGEMAGICK_DIR) install
	#cp $(IMAGEMAGICK_DIR)/utilities/.libs/* $(TARGET_DIR)/bin
	#cp $(IMAGEMAGICK_DIR)/utilities/.libs/identify $(TARGET_DIR)/bin
	#rm -rf $(TARGET_DIR)/usr/local/share/doc
	#patch -r  $(BUILD_DIR)/staging_dir/arm-linux/sys-include/errno.h #$(IMAGEMAGICK_P_DIR)/imagemagick_errno.patch

imagemagick: uclibc $(IMAGEMAGICK_TARGET_BINARY)

imagemagick-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(IMAGEMAGICK_DIR)/source uninstall
	-$(MAKE) -C $(IMAGEMAGICK_DIR) clean

imagemagick-dirclean:
	rm -rf $(IMAGEMAGICK_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_IMAGEMAGICK)),y)
TARGETS+=imagemagick
endif
