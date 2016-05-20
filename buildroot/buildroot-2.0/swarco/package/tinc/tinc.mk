#############################################################
#
# tinc
#
# NOTE: Uses start-stop-daemon in init script, so be sure
# to enable that within busybox
#
#############################################################
#TINC_VERSION:=1.0.28
TINC_VERSION:=1.1pre14
TINC_SOURCE:=tinc-$(TINC_VERSION).tar.gz
TINC_SITE:=http://www.tinc-vpn.org/packages/
TINC_DIR:=$(BUILD_DIR)/tinc-$(TINC_VERSION)
TINC_CAT:=$(ZCAT)
TINC_BINARY:=tinc
TINC_TARGET_BINARY:=usr/sbin/tincd


$(DL_DIR)/$(TINC_SOURCE):
	 $(WGET) -P $(DL_DIR) $(TINC_SITE)/$(TINC_SOURCE)

tinc-source: $(DL_DIR)/$(TINC_SOURCE)

$(TINC_DIR)/.unpacked: $(DL_DIR)/$(TINC_SOURCE)
	$(TINC_CAT) $(DL_DIR)/$(TINC_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
#	toolchain/patch-kernel.sh $(TINC_DIR) package/tinc/ \*$(TINC_VERSION)\*.patch
	touch $(TINC_DIR)/.unpacked

$(TINC_DIR)/.configured: $(TINC_DIR)/.unpacked
	(cd $(TINC_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		CFLAGS="-std=c99"	\
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libdir=/lib \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--mandir=/usr/man \
		--infodir=/usr/info \
		--program-prefix="" \
		--disable-readline \
	)
	sed -i -e 's/-pie//g' -e 's/-fPIE//g' $(TINC_DIR)/Makefile
	sed -i -e 's/-pie//g' -e 's/-fPIE//g' $(TINC_DIR)/src/Makefile
	touch $(TINC_DIR)/.configured

$(TINC_DIR)/$(TINC_BINARY): $(TINC_DIR)/.configured
	$(MAKE) -C $(TINC_DIR) V=1

$(TARGET_DIR)/$(TINC_TARGET_BINARY): $(TINC_DIR)/$(TINC_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(TINC_DIR) install
	mkdir -p $(TARGET_DIR)/etc/tinc
#	cp package/tinc/tinc.init $(TARGET_DIR)/etc/init.d/tinc
#	rm -rf $(TARGET_DIR)/share/locale $(TARGET_DIR)/usr/info \
#		$(TARGET_DIR)/usr/man $(TARGET_DIR)/usr/share/doc

tinc: uclibc lzo openssl  $(TARGET_DIR)/$(TINC_TARGET_BINARY)
#readline
tinc-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(TINC_DIR) uninstall
	-$(MAKE) -C $(TINC_DIR) clean

tinc-dirclean:
	rm -rf $(TINC_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_TINC),y)
TARGETS+=tinc
endif
