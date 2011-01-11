#############################################################
#
# proftpd
#
#############################################################
PROFTPD_VER:=1.3.0
PROFTPD_SOURCE:=proftpd-$(PROFTPD_VER).tar.gz
PROFTPD_SITE:=http://
PROFTPD_DIR:=$(BUILD_DIR)/proftpd-$(PROFTPD_VER)
PROFTPD_BINARY:=$(PROFTPD_DIR)/proftpd
PROFTPD_TARGET_BINARY:=$(TARGET_DIR)/bin/proftpd
PROFTPD_P_DIR:=$(BUILD_DIR)/../package/proftpd
$(DL_DIR)/$(PROFTPD_SOURCE):
	 $(WGET) -P $(DL_DIR) $(PROFTPD_SITE)/$(PROFTPD_SOURCE)

#wu-ftp-source: $(DL_DIR)/$(PROFTPD_SOURCE)


$(PROFTPD_DIR)/.unpacked: $(DL_DIR)/$(PROFTPD_SOURCE)
	zcat $(DL_DIR)/$(PROFTPD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	cp $(PROFTPD_P_DIR)/mod_exec.c $(PROFTPD_DIR)/modules/
	touch $(PROFTPD_DIR)/.unpacked

$(PROFTPD_DIR)/.configured: $(PROFTPD_DIR)/.unpacked
	(cd $(PROFTPD_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		ac_cv_func_setgrent_void=yes ac_cv_func_setpgrp_void=yes ./configure \
		--sysconfdir=/etc \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr/local \
		--enable-daemon \
		--without-libcap \
		--with-modules=mod_exec \
	);
	touch  $(PROFTPD_DIR)/.configured
	cp $(BUILD_DIR)/../package/proftpd/Makefile_libcap $(PROFTPD_DIR)/lib/libcap/Makefile

$(PROFTPD_BINARY): $(PROFTPD_DIR)/.configured
	$(MAKE1) -C $(PROFTPD_DIR) CC=$(TARGET_CC)  

$(PROFTPD_TARGET_BINARY):$(PROFTPD_BINARY)
	$(MAKE1) prefix=$(TARGET_DIR)/usr -C $(PROFTPD_DIR)
	cp $(PROFTPD_DIR)/proftpd $(TARGET_DIR)/sbin 

proftpd: uclibc $(PROFTPD_TARGET_BINARY)

proftpd-clean:
	$(MAKE1) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(PROFTPD_DIR)/source uninstall
	-$(MAKE) -C $(PROFTPD_DIR) clean

proftpd-dirclean:
	rm -rf $(PROFTPD_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_PROFTPD)),y)
TARGETS+=proftpd
endif
