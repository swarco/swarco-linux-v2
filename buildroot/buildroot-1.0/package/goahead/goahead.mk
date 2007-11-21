#############################################################
#
# goahead
#
#############################################################
GOAHEAD_VER:=218
GOAHEAD_SOURCE:=webs$(GOAHEAD_VER).tar.gz
GOAHEAD_SITE:=ftp://alpha.gnu.org/gnu/goahead
GOAHEAD_DIR:=$(BUILD_DIR)/ws031202
GOAHEAD_CAT:=zcat
GOAHEAD_BINARY:=$(GOAHEAD_DIR)/webs
GOAHEAD_TARGET_BINARY:=$(TARGET_DIR)/sbin/goahead
GOAHEAD_PDIR=package/goahead

#ifneq ($(BR2_LARGEFILE),y)
#GOAHEAD_LARGEFILE="--disable-largefile"
#endif

$(DL_DIR)/$(GOAHEAD_SOURCE):
	 $(WGET) -P $(DL_DIR) $(GOAHEAD_SITE)/$(GOAHEAD_SOURCE)

goahead-source: $(DL_DIR)/$(GOAHEAD_SOURCE)

$(GOAHEAD_DIR)/.unpacked: $(DL_DIR)/$(GOAHEAD_SOURCE)
	$(GOAHEAD_CAT) $(DL_DIR)/$(GOAHEAD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	patch -l $(GOAHEAD_DIR)/LINUX/Makefile < $(GOAHEAD_PDIR)/goahead.patch
	patch -l $(GOAHEAD_DIR)/LINUX/main.c < $(GOAHEAD_PDIR)/goahead_mainpage.patch
	touch $(GOAHEAD_DIR)/.unpacked

$(GOAHEAD_DIR)/.configured: $(GOAHEAD_DIR)/.unpacked
#	(cd $(GOAHEAD_DIR); rm -rf config.cache; \
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
#		$(GOAHEAD_LARGEFILE) \
#	);
	touch  $(GOAHEAD_DIR)/.configured

$(GOAHEAD_BINARY): $(GOAHEAD_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(GOAHEAD_DIR)/LINUX

$(GOAHEAD_TARGET_BINARY): $(GOAHEAD_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(GOAHEAD_DIR)/LINUX all
	(cp -R $(GOAHEAD_DIR)/web $(TARGET_DIR); \
	cp $(GOAHEAD_DIR)/LINUX/webs $(GOAHEAD_TARGET_BINARY); \
	rm -rf $(TARGET_DIR)/web/docs;)
#	rm -rf $(TARGET_DIR)/share/locale $(TARGET_DIR)/usr/info \
#		$(TARGET_DIR)/usr/man $(TARGET_DIR)/usr/share/doc
#	(cd $(TARGET_DIR)/bin; \
#	ln -snf goahead gunzip; \
#	ln -snf goahead zcat; \
#	ln -snf zdiff zcmp; \
#	ln -snf zgrep zegrep; \
#	ln -snf zgrep zfgrep;)

goahead: uclibc $(GOAHEAD_TARGET_BINARY)

goahead-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(GOAHEAD_DIR) uninstall
	-$(MAKE) -C $(GOAHEAD_DIR) clean

goahead-dirclean:
	rm -rf $(GOAHEAD_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_GOAHEAD)),y)
TARGETS+=goahead
endif
