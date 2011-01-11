#############################################################
#
# zeroconf
#
#############################################################
ZEROCONF_VER:=0.9
ZEROCONF_SOURCE:=zeroconf-$(ZEROCONF_VER).tar.gz
ZEROCONF_SITE:=ftp://alpha.gnu.org/gnu/goahead
ZEROCONF_DIR:=$(BUILD_DIR)/zeroconf-$(ZEROCONF_VER)
ZEROCONF_CAT:=zcat
ZEROCONF_BINARY:=$(ZEROCONF_DIR)/zeroconf
ZEROCONF_TARGET_BINARY:=$(TARGET_DIR)/sbin
#ZEROCONF_PDIR=$(PWD)/package/goahead

#ifneq ($(BR2_LARGEFILE),y)
#ZEROCONF_LARGEFILE="--disable-largefile"
#endif

$(DL_DIR)/$(ZEROCONF_SOURCE):
	 $(WGET) -P $(DL_DIR) $(ZEROCONF_SITE)/$(ZEROCONF_SOURCE)

goahead-source: $(DL_DIR)/$(ZEROCONF_SOURCE)

$(ZEROCONF_DIR)/.unpacked: $(DL_DIR)/$(ZEROCONF_SOURCE)
	$(ZEROCONF_CAT) $(DL_DIR)/$(ZEROCONF_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
#	patch -l $(ZEROCONF_DIR)/LINUX/Makefile < $(ZEROCONF_PDIR)/goahead.patch
	touch $(ZEROCONF_DIR)/.unpacked

$(ZEROCONF_DIR)/.configured: $(ZEROCONF_DIR)/.unpacked
#	(cd $(ZEROCONF_DIR); rm -rf config.cache; \
#		$(TARGET_CONFIGURE_OPTS) \
#		CFLAGS="$(TARGET_CFLAGS)" \
#		./configure \
#		--target=$(GNU_TARGET_NAME) \
#		--host=$(GNU_TARGET_NAME) \
#		--build=$(GNU_HOST_NAME) \
#		--prefix=/usr \
#		--exec-prefix=/ \
#		--bindir=/bin \
#		--sbindir=/bin \
#		--libexecdir=/usr/lib \
#		--sysconfdir=/etc \
#		--datadir=/usr/share/misc \
#		--localstatedir=/var \
#		--mandir=/usr/man \
#		--infodir=/usr/info \
#		$(DISABLE_NLS) \
#		$(ZEROCONF_LARGEFILE) \
#	);
	touch  $(ZEROCONF_DIR)/.configured

$(ZEROCONF_BINARY): $(ZEROCONF_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(ZEROCONF_DIR)

$(ZEROCONF_TARGET_BINARY): $(ZEROCONF_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(ZEROCONF_DIR)
	cp $(ZEROCONF_DIR)/zeroconf $(ZEROCONF_TARGET_BINARY)

zeroconf: uclibc $(ZEROCONF_TARGET_BINARY)

zeroconf-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(ZEROCONF_DIR) uninstall
	-$(MAKE) -C $(ZEROCONF_DIR) clean

zeroconf-dirclean:
	rm -rf $(ZEROCONF_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_ZEROCONF)),y)
TARGETS+=zeroconf
endif
