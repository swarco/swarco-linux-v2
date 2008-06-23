#############################################################
#
# wuftpd
#
#############################################################
WUFTPD_VER:=2.6.2
WUFTPD_SOURCE:=wu-ftpd-$(WUFTPD_VER).tar.gz
WUFTPD_SITE:=http://
WUFTPD_PDIR:=$(BUILD_DIR)/../package/wuftpd
WUFTPD_DIR:=$(BUILD_DIR)/wu-ftpd-$(WUFTPD_VER)
WUFTPD_BINARY:=$(WUFTPD_DIR)/wuftpd
WUFTPD_TARGET_BINARY:=$(TARGET_DIR)/bin/wuftpd

$(DL_DIR)/$(WUFTPD_SOURCE):
	 $(WGET) -P $(DL_DIR) $(WUFTPD_SITE)/$(WUFTPD_SOURCE)

#wu-ftp-source: $(DL_DIR)/$(WUFTPD_SOURCE)


$(WUFTPD_DIR)/.unpacked: $(DL_DIR)/$(WUFTPD_SOURCE)
	zcat $(DL_DIR)/$(WUFTPD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(WUFTPD_DIR)/.unpacked

$(WUFTPD_DIR)/.configured: $(WUFTPD_DIR)/.unpacked
	(cd $(WUFTPD_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--sysconfdir=/etc \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr/local \
		--enable-daemon \
		--without-libcap \
	);
	#patch -p1 < $(WUFTPD_PDIR)/wu-ftpd.patch
	touch  $(WUFTPD_DIR)/.configured
#	cp $(BUILD_DIR)/../package/wuftpd/Makefile_libcap $(WUFTPD_DIR)/lib/libcap/Makefile

$(WUFTPD_BINARY): $(WUFTPD_DIR)/.configured
	$(MAKE1) -C $(WUFTPD_DIR) CC=$(TARGET_CC)  

$(WUFTPD_TARGET_BINARY):$(WUFTPD_BINARY)
	$(MAKE1) prefix=$(TARGET_DIR)/usr -C $(WUFTPD_DIR) install
	#cp $(WUFTPD_DIR)/wuftpd $(TARGET_DIR)/sbin 

wuftpd: uclibc $(WUFTPD_TARGET_BINARY)

wuftpd-clean:
	$(MAKE1) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(WUFTPD_DIR)/source uninstall
	-$(MAKE) -C $(WUFTPD_DIR) clean

wuftpd-dirclean:
	rm -rf $(WUFTPD_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_WUFTPD)),y)
TARGETS+=wuftpd
endif
